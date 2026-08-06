--[[
	DungeonService/init.lua
	Server-authoritative Dungeon system (MVP: in-server instance).

	Alur:
	  1. Leader panggil EnterDungeon(dungeonId)
	  2. Server validasi: party exists, level OK, party size OK
	  3. Spawn wave pertama → combat → clear → wave berikutnya
	  4. Boss wave → kill boss → dungeon complete
	  5. Distribute rewards ke semua party member

	Instance disimpan di memory (_instances), tidak persisten.
	Untuk production: gunakan Reserved Server / TeleportService.

	Wave system:
	  - Tiap wave spawn N enemy via CombatService:SpawnEnemy
	  - Service track enemies yang hidup
	  - Semua mati → spawn wave berikutnya
	  - Wave terakhir = boss
	  - Boss mati → complete → rewards

	ANTI-CHEAT:
	  - Semua operasi di server
	  - Hanya party leader yang bisa start
	  - Level & party size validation
	  - Time limit enforcement

	Dependency: DataService, PartyService, CombatService, Dungeons config, Enemies config
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))
local DungeonsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Dungeons"))
local EnemiesConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Enemies"))

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
	-- instanceId → { configId, partyId, wave, enemies = { instanceId }, startedAt, status }
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

	-- === SUKSES: Buat instance ===
	local instanceId = dungeonId .. "_" .. tostring(os.time())
	self._instances[instanceId] = {
		configId = dungeonId,
		partyId = partyInfo.partyId,
		wave = 0,
		activeEnemies = {},
		startedAt = os.time(),
		status = "active", -- active, completed, failed
		completedAt = nil,
	}

	-- Set DungeonId di semua member profile
	for _, member in ipairs(partyInfo.members) do
		local memberPlayer = member.userId and
			(game:GetService("Players"):GetPlayerByUserId(member.userId))
		if memberPlayer then
			local memberProfile = ds and ds.WaitForProfile(memberPlayer, 10)
			if memberProfile then
				memberProfile.DungeonId = instanceId
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

--- Report enemy killed (dipanggil oleh CombatService)
function DungeonService:ReportEnemyKilled(instanceId: string, enemyInstanceId: string)
	local instance = self._instances[instanceId]
	if not instance or instance.status ~= "active" then return end

	-- Hapus dari activeEnemies
	for i, eid in ipairs(instance.activeEnemies) do
		if eid == enemyInstanceId then
			table.remove(instance.activeEnemies, i)
			break
		end
	end

	-- Semua wave clear?
	if #instance.activeEnemies == 0 then
		local config = DungeonsConfig[instance.configId]
		if not config then return end

		if instance.wave >= #config.waves then
			-- Boss mati → dungeon complete!
			self:_completeDungeon(instanceId)
		else
			-- Spawn wave berikutnya
			task.wait(2) -- delay antar wave
			self:_spawnNextWave(instanceId)
		end
	end
end

--- Force keluar dungeon
function DungeonService:ForceLeave(player: Player)
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return end
	profile.DungeonId = nil
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

	local combatSvc = BaseService.GetServiceByName(COMBAT_SERVICE_NAME)
	if not combatSvc then return end

	instance.activeEnemies = {}
	for _, enemyData in ipairs(waveData.enemies) do
		for i = 1, enemyData.count do
			local eid = combatSvc:SpawnEnemy(enemyData.enemyId)
			if eid then
				table.insert(instance.activeEnemies, eid)
			end
		end
	end
end

function DungeonService:_countAliveEnemies(instanceId: string): number
	local instance = self._instances[instanceId]
	if not instance then return 0 end

	local combatSvc = BaseService.GetServiceByName(COMBAT_SERVICE_NAME)
	if not combatSvc then return #instance.activeEnemies end

	local count = 0
	for _, eid in ipairs(instance.activeEnemies) do
		local status = combatSvc:GetEnemyStatus(eid)
		if status and status.alive then
			count = count + 1
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

	-- Cari party leader untuk dapat party members
	local leaderPlayer = nil
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		local prof = ds and ds.WaitForProfile(plr, 10)
		if prof and prof.DungeonId == instanceId then
			leaderPlayer = plr
			break
		end
	end

	if not leaderPlayer then return end
	local members = partySvc and partySvc:GetPartyMembers(leaderPlayer) or { leaderPlayer }

	-- Distribute rewards ke semua member
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
		end
	end
end

function DungeonService:OnPlayerRemoving(player)
	-- Auto-remove dari dungeon saat disconnect
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if profile and profile.DungeonId then
		profile.DungeonId = nil
	end
end

return DungeonService
