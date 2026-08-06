--[[
	InventoryService/init.lua
	Server-authoritative Inventory & Equipment system.

	Alur:
	  1. AddItem(player, itemId, quantity) → tambah item ke inventory
	  2. RemoveItem(player, itemId, quantity) → kurangi/hapus item
	  3. EquipItem(player, inventoryIndex) → pindah dari inventory ke equipment slot
	  4. UnequipItem(player, slot) → pindah dari equipment ke inventory
	  5. UseItem(player, inventoryIndex) → gunakan consumable

	Inventory format (profile):
	  { { itemId, quantity, instanceId }, ... }
	  instanceId = unique ID per stack (untuk equip tracking)

	Equipment format (profile):
	  { Weapon = { itemId }, Head = { itemId }, Chest = { itemId }, ... }

	ANTI-CHEAT:
	  - Semua operasi di server
	  - Validasi item exists di Items.lua
	  - Validasi class/level requirement
	  - Inventory space check (max 50 slot)
	  - Rate-limited remotes

	Dependency: DataService, Items config
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))
local ItemsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Items"))

local DATA_SERVICE_NAME = "DataService"
local REMOTE_INVENTORY = "Inventory/GetInventory"
local REMOTE_EQUIP = "Inventory/Equip"
local REMOTE_UNEQUIP = "Inventory/Unequip"
local REMOTE_USE = "Inventory/UseItem"

local MAX_INVENTORY_SLOTS = 50
local EQUIPMENT_SLOTS = { "Weapon", "Head", "Chest", "Legs", "Feet", "Shield", "Accessory" }

local InventoryService = BaseService:Extend("InventoryService")

function InventoryService:Init()
	BaseService.Init(self)
	self._name = "InventoryService"
end

function InventoryService:Start()
	BaseService.Start(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory")
	local selfRef = self

	-- Inventory/GetInventory
	local invRemote = remotesFolder:WaitForChild("GetInventory")
	invRemote.OnServerInvoke = RemoteValidator.new(REMOTE_INVENTORY, 1):WrapHandler(function(player)
		return selfRef:GetInventory(player)
	end)

	-- Inventory/Equip
	local equipRemote = remotesFolder:WaitForChild("Equip")
	equipRemote.OnServerInvoke = RemoteValidator.new(REMOTE_EQUIP, 0.5):WrapHandler(function(player, index)
		return selfRef:EquipItem(player, index)
	end)

	-- Inventory/Unequip
	local unequipRemote = remotesFolder:WaitForChild("Unequip")
	unequipRemote.OnServerInvoke = RemoteValidator.new(REMOTE_UNEQUIP, 0.5):WrapHandler(function(player, slot)
		return selfRef:UnequipItem(player, slot)
	end)

	-- Inventory/UseItem
	local useRemote = remotesFolder:WaitForChild("UseItem")
	useRemote.OnServerInvoke = RemoteValidator.new(REMOTE_USE, 0.5):WrapHandler(function(player, index)
		return selfRef:UseItem(player, index)
	end)
end

-- ==========================================
-- PUBLIC API
-- ==========================================

--- Tambah item ke inventory
function InventoryService:AddItem(player: Player, itemId: string, quantity: number?): { [string]: any }
	quantity = quantity or 1
	if quantity <= 0 then return { success = false, reason = "Quantity harus > 0" } end

	local config = ItemsConfig[itemId]
	if not config then
		return { success = false, reason = "Item tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local inv = profile.Inventory
	if not inv then profile.Inventory = {}; inv = profile.Inventory end

	-- Stackable: cari stack yang sama
	if config.stackable then
		for i, entry in ipairs(inv) do
			if entry.itemId == itemId and entry.quantity < (config.maxStack or 99) then
				local space = (config.maxStack or 99) - entry.quantity
				local toAdd = math.min(quantity, space)
				entry.quantity = entry.quantity + toAdd
				quantity = quantity - toAdd
				if quantity <= 0 then
					return { success = true, itemId = itemId, totalAdded = quantity }
				end
			end
		end
	end

	-- Buat stack baru
	while quantity > 0 do
		if #inv >= MAX_INVENTORY_SLOTS then
			return { success = false, reason = "Inventory penuh", remaining = quantity }
		end

		local maxStack = config.stackable and (config.maxStack or 99) or 1
		local toAdd = math.min(quantity, maxStack)
		table.insert(inv, {
			itemId = itemId,
			quantity = toAdd,
			instanceId = HttpService:GenerateGUID(false),
		})
		quantity = quantity - toAdd
	end

	return { success = true, itemId = itemId }
end

--- Hapus item dari inventory
function InventoryService:RemoveItem(player: Player, itemId: string, quantity: number?): { [string]: any }
	quantity = quantity or 1
	if quantity <= 0 then return { success = false, reason = "Quantity harus > 0" } end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" } end

	local inv = profile.Inventory
	if not inv then return { success = false, reason = "Inventory kosong" } end

	local removed = 0
	local i = 1
	while i <= #inv and removed < quantity do
		if inv[i].itemId == itemId then
			local toRemove = math.min(quantity - removed, inv[i].quantity)
			inv[i].quantity = inv[i].quantity - toRemove
			removed = removed + toRemove
			if inv[i].quantity <= 0 then
				table.remove(inv, i)
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end

	if removed < quantity then
		return { success = false, reason = "Item tidak cukup", removed = removed, needed = quantity }
	end

	return { success = true, itemId = itemId, removed = removed }
end

--- Equip item dari inventory
function InventoryService:EquipItem(player: Player, inventoryIndex: number): { [string]: any }
	if typeof(inventoryIndex) ~= "number" or inventoryIndex < 1 then
		return { success = false, reason = "Index tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local inv = profile.Inventory
	if not inv or not inv[inventoryIndex] then
		return { success = false, reason = "Slot inventory kosong" }
	end

	local entry = inv[inventoryIndex]
	local config = ItemsConfig[entry.itemId]
	if not config then
		return { success = false, reason = "Item config tidak ditemukan" }
	end

	-- Cek tipe equipable
	local slot = self:_getEquipSlot(config)
	if not slot then
		return { success = false, reason = "Item tidak bisa di-equip", itemType = config.type }
	end

	-- Cek level requirement
	if config.requiredLevel and profile.Level < config.requiredLevel then
		return { success = false, reason = "Level belum cukup", required = config.requiredLevel }
	end

	-- Cek class requirement
	if config.requiredClass and config.requiredClass ~= profile.ClassId then
		return { success = false, reason = "Class tidak sesuai", required = config.requiredClass }
	end

	-- Init Equipment kalau belum ada
	if not profile.Equipment then profile.Equipment = {} end

	-- Unequip yang lama (kalau ada)
	local oldEquip = profile.Equipment[slot]
	if oldEquip then
		table.insert(inv, oldEquip)
	end

	-- Pindah dari inventory ke equipment
	profile.Equipment[slot] = { itemId = entry.itemId, instanceId = entry.instanceId }
	table.remove(inv, inventoryIndex)

	return { success = true, slot = slot, itemId = entry.itemId }
end

--- Unequip item dari slot
function InventoryService:UnequipItem(player: Player, slot: string): { [string]: any }
	if typeof(slot) ~= "string" then
		return { success = false, reason = "Slot harus string" }
	end

	-- Validasi slot
	local validSlot = false
	for _, s in ipairs(EQUIPMENT_SLOTS) do
		if s == slot then validSlot = true; break end
	end
	if not validSlot then
		return { success = false, reason = "Slot tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local equip = profile.Equipment
	if not equip or not equip[slot] then
		return { success = false, reason = "Slot kosong" }
	end

	local inv = profile.Inventory
	if not inv then profile.Inventory = {}; inv = profile.Inventory end

	if #inv >= MAX_INVENTORY_SLOTS then
		return { success = false, reason = "Inventory penuh" }
	end

	-- Pindah dari equipment ke inventory
	table.insert(inv, equip[slot])
	equip[slot] = nil

	return { success = true, slot = slot }
end

--- Gunakan consumable
function InventoryService:UseItem(player: Player, inventoryIndex: number): { [string]: any }
	if typeof(inventoryIndex) ~= "number" or inventoryIndex < 1 then
		return { success = false, reason = "Index tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local inv = profile.Inventory
	if not inv or not inv[inventoryIndex] then
		return { success = false, reason = "Slot inventory kosong" }
	end

	local entry = inv[inventoryIndex]
	local config = ItemsConfig[entry.itemId]
	if not config then
		return { success = false, reason = "Item config tidak ditemukan" }
	end

	if config.type ~= "Consumable" then
		return { success = false, reason = "Item bukan consumable" }
	end

	-- Apply effect (placeholder — nanti hubungkan ke CombatService/player stats)
	local effect = config.effect or {}
	local results = {}

	if effect.healHP then
		-- TODO: hubungkan ke player HP system
		table.insert(results, "HP +" .. tostring(effect.healHP))
	end
	if effect.healMP then
		-- TODO: hubungkan ke mana system
		table.insert(results, "MP +" .. tostring(effect.healMP))
	end
	if effect.curePoison then
		table.insert(results, "Poison cured")
	end

	-- Kurangi quantity
	entry.quantity = entry.quantity - 1
	if entry.quantity <= 0 then
		table.remove(inv, inventoryIndex)
	end

	return { success = true, itemId = entry.itemId or config.id, effects = results }
end

--- Ambil inventory player
function InventoryService:GetInventory(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	return {
		success = true,
		inventory = profile.Inventory or {},
		maxSlots = MAX_INVENTORY_SLOTS,
	}
end

--- Ambil equipment player
function InventoryService:GetEquipment(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	return {
		success = true,
		equipment = profile.Equipment or {},
	}
end

--- Hitung total stat bonus dari equipment
function InventoryService:GetEquipmentStats(player: Player): { [string]: number }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return {} end

	local totalStats = { STR = 0, VIT = 0, INT = 0, AGI = 0, LUK = 0 }
	local equip = profile.Equipment or {}

	for slot, entry in pairs(equip) do
		if entry and entry.itemId then
			local config = ItemsConfig[entry.itemId]
			if config and config.stats then
				for stat, value in pairs(config.stats) do
					totalStats[stat] = (totalStats[stat] or 0) + value
				end
			end
		end
	end

	return totalStats
end

--- Cek apakah player punya item tertentu (dipakai Gate/Quest)
function InventoryService:HasItem(player: Player, itemId: string, quantity: number?): boolean
	quantity = quantity or 1
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return false end

	local inv = profile.Inventory or {}
	local total = 0
	for _, entry in ipairs(inv) do
		if entry.itemId == itemId then
			total = total + entry.quantity
		end
	end
	return total >= quantity
end

-- ==========================================
-- INTERNAL
-- ==========================================

function InventoryService:_getEquipSlot(config): string?
	local itemType = config.type
	if itemType == "Weapon" then return "Weapon" end
	if itemType == "Shield" then return "Shield" end
	if itemType == "Accessory" then return "Accessory" end
	if itemType == "Armor" then
		-- Guess slot from id/name
		local id = config.id:lower()
		if id:find("helm") or id:find("hat") or id:find("head") then return "Head" end
		if id:find("boot") or id:find("feet") then return "Feet" end
		if id:find("legging") or id:find("pants") or id:find("leg") then return "Legs" end
		return "Chest" -- default armor = chest
	end
	return nil
end

function InventoryService:OnPlayerRemoving(player)
	-- Cleanup kalau perlu
end

return InventoryService
