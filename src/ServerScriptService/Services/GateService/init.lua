--[[
	GateService.lua
	Logic server untuk Gate/Portal system (docs/01_GDD.md §11, §6).
	Server-authoritative: semua validasi syarat gate di server, client
	hanya trigger via ProximityPrompt + UI confirm.

	API publik (server-only):
	  GateService.TryOpenGate(player, gateId)     → { success, reason?, destination? }
	  GateService.GetUnlockedGates(player)          → { gateId = true, ... }
	  GateService.IsGateUnlocked(player, gateId)    → boolean

	Remotes:
	  Gate/RequestOpen  (Client→Server, Function)
	  Gate/GateOpened   (Server→Client, Event)

	Anti-exploit:
	  - gateId divalidasi ada di Config.
	  - Semua syarat dicek ulang di server (level, quest, item).
	  - Rate-limited 1s per player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("BaseService"))
local GatesConfig = require(ReplicatedStorage.Configs.Gates)
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))

local GateService = BaseService:Extend("GateService")

local DATA_SERVICE_NAME = "DataService"

local function isValidGateId(gateId: string): boolean
	return GatesConfig[gateId] ~= nil
end

local function checkRequirement(data, requirement)
	if not requirement then return true, {} end

	local missing = {}

	if requirement.type == "Level" then
		if data.Level < requirement.level then
			missing.level = { have = data.Level, need = requirement.level }
		end

	elseif requirement.type == "Quest" then
		local completed = data.CompletedQuests or {}
		if not completed[requirement.questId] then
			missing.quest = requirement.questId
		end

	elseif requirement.type == "Item" then
		local inv = data.Inventory or {}
		if not inv[requirement.itemId] or inv[requirement.itemId] <= 0 then
			missing.item = requirement.itemId
		end

	elseif requirement.type == "LevelAndQuest" then
		if data.Level < requirement.level then
			missing.level = { have = data.Level, need = requirement.level }
		end
		local completed = data.CompletedQuests or {}
		if not completed[requirement.questId] then
			missing.quest = requirement.questId
		end
	end

	return next(missing) == nil, missing
end

function GateService:Init()
	BaseService.Init(self)
end

function GateService:Start()
	BaseService.Start(self)

	self._dataService = self:GetService(DATA_SERVICE_NAME)

	local remotesFolder = ReplicatedStorage.Remotes:WaitForChild("Gate")
	local requestOpen = remotesFolder:WaitForChild("RequestOpen")
	local validator = RemoteValidator.new("Gate/RequestOpen", 1)

	requestOpen.OnServerInvoke = validator:WrapHandler(function(player, gateId)
		local ok, err = validator:Validate(player, {
			{ value = gateId, name = "gateId", type = "string", minLength = 1, maxLength = 64 },
		})
		if not ok then return { success = false, reason = err } end
		return GateService.TryOpenGate(player, gateId)
	end)
end

function GateService.TryOpenGate(player, gateId: string)
	if not isValidGateId(gateId) then
		return { success = false, reason = "Gate tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end
	if not profile.RaceId or not profile.ClassId then
		return { success = false, reason = "Selesaikan pembuatan karakter terlebih dahulu" }
	end

	local unlocked = profile.UnlockedGates or {}
	if unlocked[gateId] then
		return { success = true, destination = GatesConfig[gateId].destinationZone, alreadyUnlocked = true }
	end

	local met, missing = checkRequirement(profile, GatesConfig[gateId].requirement)
	if not met then
		return { success = false, reason = "Syarat belum terpenuhi", missing = missing }
	end

	if not profile.UnlockedGates then profile.UnlockedGates = {} end
	profile.UnlockedGates[gateId] = true

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local gf = remotes:FindFirstChild("Gate")
		if gf then
			local ev = gf:FindFirstChild("GateOpened")
			if ev then
				ev:FireClient(player, { gateId = gateId, destination = GatesConfig[gateId].destinationZone })
			end
		end
	end

	return { success = true, destination = GatesConfig[gateId].destinationZone }
end

function GateService.GetUnlockedGates(player)
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return {} end
	return profile.UnlockedGates or {}
end

function GateService.IsGateUnlocked(player, gateId: string)
	return GateService.GetUnlockedGates(player)[gateId] == true
end

return GateService
