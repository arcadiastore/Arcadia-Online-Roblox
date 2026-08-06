--[[
	DungeonService/init.lua
	Server-authoritative Dungeon system.

	Alur:
	  1. Leader panggil EnterDungeon(dungeonId)
	  2. Server validasi: party exists, level OK, party size OK
	  3. Build dungeon zone 3D → teleport semua party member ke zone
	  4. Spawn wave pertama (enemy NPC models)
	  5. Player serang enemy → CombatService hitung damage → enemy mati
	  6. Semua wave clear → distribute rewards → teleport balik
	  7. Leave/timeout → teleport balik

	Instance disimpan di memory (_instances), tidak persisten.

	ANTI-CHEAT:
	  - Semua operasi di server
	  - Hanya party leader yang bisa start
	  - Level & party size validation
	  - Time limit enforcement

	Dependency: DataService, PartyService, CombatService, Dungeons config, Enemies config
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))
local DungeonsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Dungeons"))
local EnemiesConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Enemies"))
local DungeonZoneBuilder = require(script:WaitForChild("DungeonZoneBuilder"))
local EnemyNPCBuilder = require(script:WaitForChild("EnemyNPCBuilder"))

local DATA_SERVICE_NAME = "DataService"
local PARTY_SERVICE_NAME = "PartyService"
local COMBAT_SERVICE_NAME = "CombatService"
local LEVEL_SERVICE_NAME = "LevelService"

local REMOTE_ENTER = "Dungeon/Enter"
local REMOTE_STATUS = "Dungeon/GetStatus"
local COOLDOWN_ENTER = 3

local DungeonService = BaseService:Extend("DungeonService")

function DungeonService:Init()
	BaseService.Init(self)
	self._name = "DungeonService"
	-- instanceId → { configId, partyId, wave, enemyNPCs = {Model}, startedAt, status, playerSpawns = {CFrame} }
	self._instances = {}
end

function DungeonService:Start()
	BaseService.Start(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Dungeon")
	local selfRef = self

	remotesFolder:WaitForChild("Enter").OnServerInvoke =
		RemoteValidator.new(REMOTE_ENTER, COOLDOWN_ENTER):WrapHandler(function(player, dungeonId)
			return selfRef:EnterDungeon(player, dungeonId)
		end)

	remotesFolder:WaitForChild("GetStatus").OnServerInvoke =
		RemoteValidator.new(REMOTE_STATUS, 1):WrapHandler(function(player)
			return selfRef:GetStatus(player)
		end)
end

-- ==========================================
-- PUBLIC API
-- ==========================================

--- Masuk dungeon (leader initiate)
function DungeonService:EnterDungeon(player: Player, dungeonId: string): { [string]: any }
	if typeof(dungeonId) ~= "string" then
		return { success = false, reason = "dungeonId harus string" }
	end

	local config = DungeonsConfig[dungeonId]
	if not config then
		return { success = false, reason = "Dungeon tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end

	-- Sudah di dungeon?
	if profile.DungeonId then
		return { success = false, reason = "Sudah di dungeon" }
	end

	-- Cek level
	local req = config.requirements or {}
	if req.requiredLevel and profile.Level < req.requiredLevel then
		return { success = false, reason = "Level belum cukup", required = req.requiredLevel }
	end

	-- Cek party
	local partySvc = BaseService.GetServiceByName(PARTY_SERVICE_NAME)
	local partyInfo = partySvc and partySvc:GetPartyInfo(player)
	if not partyInfo or not partyInfo.inParty then
		return { success = false, reason = "Harus di party" }
	end

	-- Cek party size
	local partySize = partyInfo.memberCount or 1
	local minSize = req.requiredPartySize or 1
	if partySize < minSize then
		return { success = false, reason = "Party kurang", current = partySize, required = minSize }
	end

	-- Cek leader
	if partyInfo.leaderId ~= player.UserId then
		return { success = false, reason = "Hanya leader yang bisa masuk dungeon" }
	end

	-- Cek quest requirement
	if req.requiredQuestId then
		local completed = profile.CompletedQuests or {}
		if not completed[req.requiredQuestId] then
			return { success = false, reason = "Quest belum selesai", requiredQuestId = req.requiredQuestId }
		end
	end

	-- Cek item requirement
	if req.requiredItemId then
		local invSvc = BaseService.GetServiceByName("InventoryService")
		if invSvc and not invSvc:HasItem(player, req.requiredItemId) then
			return { success = false, reason = "Butuh item: " .. req.requiredItemId }
		end
	end

	-- === SUKSES: Build zone + teleport ===
	local instanceId = dungeonId .. "_" .. tostring(os.time())
	
	-- Build dungeon zone 3D
	DungeonZoneBuilder:BuildZone(dungeonId)
	local playerSpawn = DungeonZoneBuilder:GetPlayerSpawn(dungeonId)

	-- Simpan instance
	self._instances[instanceId] = {
		configId = dungeonId,
		partyId = partyInfo.partyId,
		wave = 0,
		enemyNPCs = {},
		startedAt = os.time(),
		status = "active",
		completedAt = nil,
	}

	-- Set DungeonId + teleport semua member
	for _, member in ipairs(partyInfo.members) do
		local memberPlayer = Players:GetPlayerByUserId(member.userId)
		if memberPlayer then
			local memberProfile = ds and ds.WaitForProfile(memberPlayer, 10)
			if memberProfile then
				memberProfile.DungeonId = instanceId
			end

			-- Teleport ke dungeon zone
			local char = memberPlayer.Character
			if char then
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if rootPart then
					rootPart.CFrame = playerSpawn + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
				end
			end
		end
	end

	-- Spawn wave pertama
	self:_spawnNextWave(instanceId)

	local instance = self._instances[instanceId]
	return {
		success = true,
		instanceId = instanceId,
		dungeonName = config.displayName,
		wave = instance.wave,
		totalWaves = #config.waves,
	}
end

--- Status dungeon saat ini
function DungeonService:GetStatus(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end

	local instanceId = profile.DungeonId
	if not instanceId then
		return { success = true, inDungeon = false }
	end

	local instance = self._instances[instanceId]
	if not instance then
		profile.DungeonId = nil
		return { success = true, inDungeon = false }
	end

	local config = DungeonsConfig[instance.configId]

	-- Cek time limit
	local elapsed = os.time() - instance.startedAt
	local timeLimit = config and config.timeLimit or 600
	if elapsed > timeLimit and instance.status == "active" then
		instance.status = "failed"
		self:_cleanupInstance(instanceId)
	end

	return {
		success = true,
		inDungeon = true,
		dungeonId = instance.configId,
		dungeonName = config and config.displayName or "Unknown",
		wave = instance.wave,
		totalWaves = config and #config.waves or 0,
		status = instance.status,
		elapsed = elapsed,
		timeLimit = timeLimit,
		aliveEnemies = self:_countAliveEnemies(instanceId),
	}
end

--- Force keluar dungeon
function DungeonService:ForceLeave(player: Player)
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return end
	if profile.DungeonId then
		self:_teleportToSpawn(player)
		profile.DungeonId = nil
	end
end

-- ==========================================
-- INTERNAL
-- ==========================================

function DungeonService:_spawnNextWave(instanceId: string)
	local instance = self._instances[instanceId]
	if not instance then return end

	local config = DungeonsConfig[instance.configId]
	if not config then return end

	instance.wave = instance.wave + 1
	local waveData = config.waves[instance.wave]
	if not waveData then return end

	-- Clear old enemy NPCs
	for _, npc in ipairs(instance.enemyNPCs) do
		EnemyNPCBuilder:Destroy(npc)
	end
	instance.enemyNPCs = {}

	-- Spawn enemy NPCs
	for _, enemyData in ipairs(waveData.enemies) do
		for i = 1, enemyData.count do
			local spawnCF = DungeonZoneBuilder:GetEnemySpawn(instance.configId)
			local npc = EnemyNPCBuilder:Spawn(enemyData.enemyId, spawnCF)
			if npc then
				table.insert(instance.enemyNPCs, npc)

				-- Detect death
				local humanoid = npc:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Died:Connect(function()
						self:_onEnemyDied(instanceId, npc)
					end)
				end
			end
		end
	end
end

function DungeonService:_onEnemyDied(instanceId: string, npc: Model)
	local instance = self._instances[instanceId]
	if not instance or instance.status ~= "active" then return end

	-- Hapus dari list
	for i, enemyNPC in ipairs(instance.enemyNPCs) do
		if enemyNPC == npc then
			table.remove(instance.enemyNPCs, i)
			break
		end
	end

	-- Delay sebelum destroy (biar death animation jalan)
	task.delay(2, function()
		EnemyNPCBuilder:Destroy(npc)
	end)

	-- Semua wave clear?
	if self:_countAliveEnemies(instanceId) == 0 then
		local config = DungeonsConfig[instance.configId]
		if not config then return end

		if instance.wave >= #config.waves then
			-- Boss mati → dungeon complete!
			self:_completeDungeon(instanceId)
		else
			-- Spawn wave berikutnya
			task.wait(3) -- delay antar wave
			self:_spawnNextWave(instanceId)
		end
	end
end

function DungeonService:_countAliveEnemies(instanceId: string): number
	local instance = self._instances[instanceId]
	if not instance then return 0 end

	local count = 0
	for _, npc in ipairs(instance.enemyNPCs) do
		if npc and npc.Parent then
			local humanoid = npc:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				count = count + 1
			end
		end
	end
	return count
end

function DungeonService:_completeDungeon(instanceId: string)
	local instance = self._instances[instanceId]
	if not instance then return end

	instance.status = "completed"
	instance.completedAt = os.time()

	local config = DungeonsConfig[instance.configId]
	if not config then return end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local partySvc = BaseService.GetServiceByName(PARTY_SERVICE_NAME)
	local levelSvc = BaseService.GetServiceByName(LEVEL_SERVICE_NAME)
	local invSvc = BaseService.GetServiceByName("InventoryService")

	-- Cari party leader
	local leaderPlayer = nil
	for _, plr in ipairs(Players:GetPlayers()) do
		local prof = ds and ds.WaitForProfile(plr, 10)
		if prof and prof.DungeonId == instanceId then
			leaderPlayer = plr
			break
		end
	end

	if not leaderPlayer then return end
	local members = partySvc and partySvc:GetPartyMembers(leaderPlayer) or { leaderPlayer }

	-- Distribute rewards + teleport balik
	for _, member in ipairs(members) do
		local memberProfile = ds and ds.WaitForProfile(member, 10)
		if memberProfile then
			-- EXP
			if config.rewards.exp and config.rewards.exp > 0 and levelSvc then
				levelSvc:AddExp(member, config.rewards.exp)
			end

			-- Currency
			if config.rewards.softCurrency and config.rewards.softCurrency > 0 then
				if not memberProfile.Currency then memberProfile.Currency = { Soft = 0, Premium = 0 } end
				memberProfile.Currency.Soft = (memberProfile.Currency.Soft or 0) + config.rewards.softCurrency
			end

			-- Items (drop rate check)
			if config.rewards.items and invSvc then
				for _, itemData in ipairs(config.rewards.items) do
					if math.random() <= (itemData.dropRate or 1.0) then
						invSvc:AddItem(member, itemData.itemId, itemData.quantity)
					end
				end
			end

			-- Clear dungeon reference
			memberProfile.DungeonId = nil

			-- Teleport balik ke spawn utama (Millhaven)
			self:_teleportToSpawn(member)
		end
	end

	-- Cleanup zone
	task.wait(5)
	DungeonZoneBuilder:DestroyZone(instance.configId)
	self._instances[instanceId] = nil
end

function DungeonService:_cleanupInstance(instanceId: string)
	local instance = self._instances[instanceId]
	if not instance then return end

	-- Destroy all enemy NPCs
	for _, npc in ipairs(instance.enemyNPCs) do
		EnemyNPCBuilder:Destroy(npc)
	end

	-- Teleport semua player balik
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	for _, plr in ipairs(Players:GetPlayers()) do
		local prof = ds and ds.WaitForProfile(plr, 10)
		if prof and prof.DungeonId == instanceId then
			prof.DungeonId = nil
			self:_teleportToSpawn(plr)
		end
	end

	-- Destroy zone
	DungeonZoneBuilder:DestroyZone(instance.configId)
	self._instances[instanceId] = nil
end

function DungeonService:_teleportToSpawn(player: Player)
	-- Teleport ke Millhaven spawn (0, 5, 0)
	local char = player.Character
	if char then
		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if rootPart then
			rootPart.CFrame = CFrame.new(0, 5, 0) -- Millhaven center
		end
	end
end

function DungeonService:OnPlayerRemoving(player)
	-- Auto-leave saat disconnect
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if profile and profile.DungeonId then
		profile.DungeonId = nil
	end
end

return DungeonService
