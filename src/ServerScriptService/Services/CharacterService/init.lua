--[[
	CharacterService.lua
	Service pembuatan karakter: pilih Ras (dengan RNG reroll) dan Kelas awal
	(Tier 1). Wajib diselesaikan sebelum pemain bisa melakukan aktivitas lain
	(RaceId/ClassId masih nil di ProfileTemplate — lihat docs/03_DDD.md §4).

	Dipanggil oleh: Main.server.lua (bootstrap).
	Mewarisi BaseService.

	API publik (server-only, bisa dipanggil Service lain / test):
	  CharacterService.RerollRace(player)            → { success, raceId?, ... }
	  CharacterService.ConfirmRace(player, raceId)    → { success, reason? }
	  CharacterService.SelectClass(player, classId)   → { success, reason? }
	  CharacterService.GetCreationStatus(player)      → { hasRace, hasClass }

	Remotes (client→server, wrapper di atas API):
	  Character/RerollRace, ConfirmRace, SelectClass, CreationStatus

	Anti-exploit (docs/06_CODING_STANDARDS.md §3):
	  - Reroll dihitung di server (client tidak bisa manipulasi bobot/RNG).
	  - Race/Class ID divalidasi terhadap Config sebelum disimpan.
	  - Player tidak bisa mengubah Ras/Kelas setelah dikonfirmasi.
	  - Rate-limited per remote via RemoteValidator.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BaseService = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("BaseService"))
local RacesConfig = require(ReplicatedStorage.Configs.Races)
local ClassesConfig = require(ReplicatedStorage.Configs.Classes)
local RemoteValidator = require(ReplicatedStorage.Shared.RemoteValidator)

local CharacterService = BaseService:Extend("CharacterService")

local DATA_SERVICE_NAME = "DataService"

-- === Util RNG berbobot (server-only) ===

local function buildWeightedPool()
	local pool = {}
	local totalWeight = 0
	for raceId, data in pairs(RacesConfig) do
		totalWeight += data.weight
		table.insert(pool, { id = raceId, cumulative = totalWeight })
	end
	return pool, totalWeight
end

local weightedPool, totalWeight = buildWeightedPool()

local function rollRandomRace()
	local roll = math.random() * totalWeight
	for _, entry in ipairs(weightedPool) do
		if roll <= entry.cumulative then
			return entry.id
		end
	end
	return weightedPool[#weightedPool].id
end

local function isValidRace(raceId: string): boolean
	return RacesConfig[raceId] ~= nil
end

local function isValidStartingClass(classId: string): boolean
	local classData = ClassesConfig[classId]
	return classData ~= nil and classData.tier == 1
end

function CharacterService:Init()
	BaseService.Init(self)
end

function CharacterService:Start()
	BaseService.Start(self)

	local dataService = self:GetService(DATA_SERVICE_NAME)
	local remotesFolder = ReplicatedStorage.Remotes:WaitForChild("Character")

	-- === Remote wrappers (pakai API langsung di bawah) ===

	local rerollRemote = remotesFolder:WaitForChild("RerollRace")
	local rerollValidator = RemoteValidator.new("Character/RerollRace", 0.5)
	rerollRemote.OnServerInvoke = rerollValidator:WrapHandler(function(player)
		return CharacterService.RerollRace(player)
	end)

	local confirmRaceRemote = remotesFolder:WaitForChild("ConfirmRace")
	local confirmRaceValidator = RemoteValidator.new("Character/ConfirmRace", 1)
	confirmRaceRemote.OnServerInvoke = confirmRaceValidator:WrapHandler(function(player, raceId)
		local ok, err = confirmRaceValidator:Validate(player, {
			{ value = raceId, name = "raceId", type = "string", minLength = 1, maxLength = 64 },
		})
		if not ok then return { success = false, reason = err } end
		return CharacterService.ConfirmRace(player, raceId)
	end)

	local selectClassRemote = remotesFolder:WaitForChild("SelectClass")
	local selectClassValidator = RemoteValidator.new("Character/SelectClass", 1)
	selectClassRemote.OnServerInvoke = selectClassValidator:WrapHandler(function(player, classId)
		local ok, err = selectClassValidator:Validate(player, {
			{ value = classId, name = "classId", type = "string", minLength = 1, maxLength = 64 },
		})
		if not ok then return { success = false, reason = err } end
		return CharacterService.SelectClass(player, classId)
	end)

	local statusRemote = remotesFolder:WaitForChild("CreationStatus")
	local statusValidator = RemoteValidator.new("Character/CreationStatus", 1)
	statusRemote.OnServerInvoke = statusValidator:WrapHandler(function(player)
		return CharacterService.GetCreationStatus(player)
	end)
end

-- === API publik (server-only) ===

function CharacterService.RerollRace(player)
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local data = ds and ds.WaitForProfile(player, 10)
	if not data then
		return { success = false, reason = "Profile belum siap" }
	end
	if data.RaceId then
		return { success = false, reason = "Sudah memilih ras" }
	end

	local raceId = rollRandomRace()
	local raceData = RacesConfig[raceId]
	return {
		success = true,
		raceId = raceId,
		displayName = raceData.displayName,
		rarity = raceData.rarity,
		statBonus = raceData.statBonus,
		elementAffinity = raceData.elementAffinity,
	}
end

function CharacterService.ConfirmRace(player, raceId)
	if type(raceId) ~= "string" or #raceId == 0 then
		return { success = false, reason = "raceId tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local data = ds and ds.WaitForProfile(player, 10)
	if not data then
		return { success = false, reason = "Profile belum siap" }
	end
	if data.RaceId then
		return { success = false, reason = "Sudah memilih ras" }
	end
	if not isValidRace(raceId) then
		return { success = false, reason = "Ras tidak valid" }
	end

	data.RaceId = raceId
	local raceData = RacesConfig[raceId]
	for stat, bonus in pairs(raceData.statBonus) do
		if data.Stats[stat] ~= nil then
			data.Stats[stat] += bonus
		end
	end
	return { success = true }
end

function CharacterService.SelectClass(player, classId)
	if type(classId) ~= "string" or #classId == 0 then
		return { success = false, reason = "classId tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local data = ds and ds.WaitForProfile(player, 10)
	if not data then
		return { success = false, reason = "Profile belum siap" }
	end
	if data.ClassId then
		return { success = false, reason = "Sudah memilih kelas" }
	end
	if not data.RaceId then
		return { success = false, reason = "Pilih ras terlebih dahulu" }
	end
	if not isValidStartingClass(classId) then
		return { success = false, reason = "Kelas tidak valid atau bukan starting class" }
	end

	data.ClassId = classId
	return { success = true }
end

function CharacterService.GetCreationStatus(player)
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local data = ds and ds.WaitForProfile(player, 10)
	if not data then
		return { hasRace = false, hasClass = false }
	end
	return {
		hasRace = data.RaceId ~= nil,
		hasClass = data.ClassId ~= nil,
	}
end

return CharacterService
