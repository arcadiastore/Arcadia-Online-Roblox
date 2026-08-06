--[[
	CombatService/init.lua
	Server-authoritative combat system.

	Alur:
	  1. Client kirim Combat/RequestAttack { enemyInstanceId, skillId }
	  2. Server validasi: skill ada, cooldown OK, mana cukup, target ada
	  3. Server hitung damage via DamageFormula
	  4. Server kurangi HP enemy (server-side state)
	  5. Server kirim result ke client
	  6. Kalau enemy mati → reward + quest progress

	ANTI-CHEAT:
	  - Semua damage dihitung di server
	  - Cooldown dicek di server
	  - Mana dikurangi di server
	  - Target validation di server

	Dependency: DataService, Skills config, Enemies config, DamageFormula
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))
local SkillsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Skills"))
local EnemiesConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Enemies"))
local DamageFormula = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamageFormula"))

local DATA_SERVICE_NAME = "DataService"
local QUEST_SERVICE_NAME = "QuestService"
local REMOTE_ATTACK = "Combat/RequestAttack"
local REMOTE_GET_SKILLS = "Combat/GetSkills"
local COOLDOWN_ATTACK = 0.5

local CombatService = BaseService:Extend("CombatService")

function CombatService:Init()
	BaseService.Init(self)
	self._name = "CombatService"
	-- enemyInstanceId → { configId, currentHP, maxHP, alive }
	self._activeEnemies = {}
	-- player cooldowns: { [playerId] = { [skillId] = lastUsedTick } }
	self._cooldowns = {}
	-- player mana: { [playerId] = currentMana } (placeholder, nanti dari profile)
	self._playerMana = {}
end

function CombatService:Start()
	BaseService.Start(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Combat")

	-- Combat/RequestAttack
	local attackRemote = remotesFolder:WaitForChild("RequestAttack")
	local attackValidator = RemoteValidator.new(REMOTE_ATTACK, COOLDOWN_ATTACK)
	local selfRef = self
	attackRemote.OnServerInvoke = attackValidator:WrapHandler(function(player, enemyInstanceId, skillId)
		return selfRef:ProcessAttack(player, enemyInstanceId, skillId)
	end)

	-- Combat/GetSkills
	local getSkillsRemote = remotesFolder:WaitForChild("GetSkills")
	local getSkillsValidator = RemoteValidator.new(REMOTE_GET_SKILLS, 1)
	getSkillsRemote.OnServerInvoke = getSkillsValidator:WrapHandler(function(player)
		return selfRef:GetAvailableSkills(player)
	end)
end

-- ==========================================
-- PUBLIC API
-- ==========================================

--- Spawn enemy di server (dipanggil oleh zone/NPC system)
function CombatService:SpawnEnemy(configId: string, instanceId: string?): string
	local config = EnemiesConfig[configId]
	if not config then return "" end

	local id = instanceId or (configId .. "_" .. tostring(tick()))
	self._activeEnemies[id] = {
		configId = configId,
		currentHP = config.stats.HP,
		maxHP = config.stats.HP,
		alive = true,
	}
	return id
end

--- Proses serangan player ke enemy
function CombatService:ProcessAttack(player: Player, enemyInstanceId: string, skillId: string): { [string]: any }
	-- Validasi skill
	if typeof(skillId) ~= "string" then
		return { success = false, reason = "skillId harus string" }
	end
	local skill = SkillsConfig[skillId]
	if not skill then
		return { success = false, reason = "Skill tidak valid" }
	end

	-- Validasi target
	local enemy = self._activeEnemies[enemyInstanceId]
	if not enemy or not enemy.alive then
		return { success = false, reason = "Target tidak valid atau sudah mati" }
	end

	local enemyConfig = EnemiesConfig[enemy.configId]
	if not enemyConfig then
		return { success = false, reason = "Config enemy tidak ditemukan" }
	end

	-- Cek cooldown skill
	if not self:_checkCooldown(player, skillId, skill.cooldown or 0) then
		return { success = false, reason = "Cooldown aktif" }
	end

	-- Cek mana
	local manaCost = skill.manaCost or 0
	if manaCost > 0 then
		local currentMana = self:_getMana(player)
		if currentMana < manaCost then
			return { success = false, reason = "Mana tidak cukup", current = currentMana, required = manaCost }
		end
		self:_setMana(player, currentMana - manaCost)
	end

	-- Set cooldown
	self:_setCooldown(player, skillId)

	-- Ambil stats attacker dari profile
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local attackerStats = {
		STR = profile.Stats.STR or 5,
		INT = profile.Stats.INT or 5,
		LUK = profile.Stats.LUK or 5,
		Level = profile.Level or 1,
	}

	local enemyStats = {
		defense = enemyConfig.defense or 0,
		element = enemyConfig.element,
	}

	-- Hitung damage
	local result = DamageFormula.Calculate(attackerStats, skill, enemyStats, 1.0)
	local dmg = result.damage

	-- Apply damage ke enemy
	enemy.currentHP = math.max(0, enemy.currentHP - dmg)

	-- Cek mati
	local killed = false
	if enemy.currentHP <= 0 then
		enemy.alive = false
		killed = true

		-- Beri reward
		self:_giveReward(player, enemyConfig, profile)

		-- Report quest progress
		self:_reportQuestProgress(player, enemy.configId)
	end

	return {
		success = true,
		damage = dmg,
		isCrit = result.isCrit,
		elementMultiplier = result.elementMultiplier,
		enemyHP = enemy.currentHP,
		enemyMaxHP = enemy.maxHP,
		killed = killed,
		expReward = killed and enemyConfig.expReward or 0,
		currencyReward = killed and enemyConfig.softCurrencyReward or 0,
	}
end

--- Ambil daftar skill yang bisa dipakai player
function CombatService:GetAvailableSkills(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local available = {}
	for skillId, skill in pairs(SkillsConfig) do
		local classOk = not skill.requiredClass or skill.requiredClass == profile.ClassId
		local levelOk = not skill.levelRequired or profile.Level >= skill.levelRequired
		if classOk and levelOk then
			table.insert(available, {
				id = skillId,
				displayName = skill.displayName,
				description = skill.description,
				damageType = skill.damageType,
				targetType = skill.targetType,
				element = skill.element,
				baseDamage = skill.baseDamage,
				baseHeal = skill.baseHeal,
				manaCost = skill.manaCost,
				cooldown = skill.cooldown,
			})
		end
	end

	return { success = true, skills = available }
end

--- Ambil status enemy (untuk UI)
function CombatService:GetEnemyStatus(enemyInstanceId: string): { [string]: any }?
	local enemy = self._activeEnemies[enemyInstanceId]
	if not enemy then return nil end

	local config = EnemiesConfig[enemy.configId]
	return {
		configId = enemy.configId,
		displayName = config and config.displayName or "Unknown",
		currentHP = enemy.currentHP,
		maxHP = enemy.maxHP,
		alive = enemy.alive,
		level = config and config.level or 0,
		element = config and config.element,
	}
end

--- Reset enemy (untuk respawn / testing)
function CombatService:ResetEnemy(enemyInstanceId: string)
	local enemy = self._activeEnemies[enemyInstanceId]
	if not enemy then return end

	local config = EnemiesConfig[enemy.configId]
	if config then
		enemy.currentHP = config.stats.HP
		enemy.alive = true
	end
end

--- Set mana player (untuk testing / init)
function CombatService:SetPlayerMana(player: Player, amount: number)
	if not self._playerMana then self._playerMana = {} end
	self._playerMana[player.UserId] = amount
end

-- ==========================================
-- INTERNAL
-- ==========================================

function CombatService:_checkCooldown(player: Player, skillId: string, cooldown: number): boolean
	local cd = self._cooldowns[player.UserId]
	if not cd then return true end
	local last = cd[skillId]
	if not last then return true end
	return (tick() - last) >= cooldown
end

function CombatService:_setCooldown(player: Player, skillId: string)
	if not self._cooldowns[player.UserId] then
		self._cooldowns[player.UserId] = {}
	end
	self._cooldowns[player.UserId][skillId] = tick()
end

function CombatService:_getMana(player: Player): number
	return (self._playerMana and self._playerMana[player.UserId]) or 100
end

function CombatService:_setMana(player: Player, amount: number)
	if not self._playerMana then self._playerMana = {} end
	self._playerMana[player.UserId] = amount
end

function CombatService:_giveReward(player: Player, enemyConfig, profile)
	local exp = enemyConfig.expReward or 0
	if exp > 0 then
		local levelSvc = BaseService.GetServiceByName("LevelService")
		if levelSvc then levelSvc:AddExp(player, exp) end
	end

	local currency = enemyConfig.softCurrencyReward or 0
	if currency > 0 then
		if not profile.Currency then profile.Currency = { Soft = 0, Premium = 0 } end
		profile.Currency.Soft = (profile.Currency.Soft or 0) + currency
	end
end

function CombatService:_reportQuestProgress(player: Player, enemyConfigId: string)
	local questSvc = BaseService.GetServiceByName(QUEST_SERVICE_NAME)
	if questSvc and questSvc.ReportProgress then
		questSvc:ReportProgress(player, enemyConfigId, 1)
	end
end

function CombatService:OnPlayerRemoving(player)
	if self._cooldowns then self._cooldowns[player.UserId] = nil end
	if self._playerMana then self._playerMana[player.UserId] = nil end
end

return CombatService
