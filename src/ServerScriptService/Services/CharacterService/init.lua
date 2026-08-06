--[[
	CharacterService.lua
	Service pembuatan karakter: pilih Ras (dengan RNG reroll) dan Kelas awal
	(Tier 1). Wajib diselesaikan sebelum pemain bisa melakukan aktivitas lain
	(RaceId/ClassId masih nil di ProfileTemplate — lihat docs/03_DDD.md §4).

	Dipanggil oleh: Main.server.lua (bootstrap).
	Mewarisi BaseService.

	Remotes:
	  Character/RerollRace    (RemoteFunction) → { raceId, displayName, rarity, statBonus, elementAffinity }
	  Character/ConfirmRace   (RemoteFunction) → { success, reason? }
	  Character/SelectClass   (RemoteFunction) → { success, reason? }
	  Character/CreationStatus(RemoteFunction) → { hasRace, hasClass }

	Anti-exploit (docs/06_CODING_STANDARDS.md §3):
	  - Reroll dihitung di server (client tidak bisa manipulasi bobot/RNG).
	  - Race/Class ID divalidasi terhadap Config sebelum disimpan.
	  - Player tidak bisa mengubah Ras/Kelas setelah dikonfirmasi (kecuali
	    ada mekanik resmi di kemudian hari — bukan scope sesi ini).
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

-- === Util RNG berbobot (server-only, client tidak bisa manipulasi) ===

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
	-- Fallback (seharusnya tidak tercapai kalau weight > 0)
	return weightedPool[#weightedPool].id
end

-- Validasi bahwa raceId ada di Config
local function isValidRace(raceId: string): boolean
	return RacesConfig[raceId] ~= nil
end

-- Validasi bahwa classId ada di Config dan Tier 1 (starting class)
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

	-- === Remote: RerollRace ===
	local rerollRemote = remotesFolder:WaitForChild("RerollRace")
	local rerollValidator = RemoteValidator.new("Character/RerollRace", 0.5) -- 0.5s debounce

	rerollRemote.OnServerInvoke = rerollValidator:WrapHandler(function(player)
		local data = dataService.WaitForProfile(player, 10)
		if not data then
			return { success = false, reason = "Profile belum siap" }
		end

		-- Sudah punya ras — tidak boleh reroll lagi
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
	end)

	-- === Remote: ConfirmRace ===
	local confirmRaceRemote = remotesFolder:WaitForChild("ConfirmRace")
	local confirmRaceValidator = RemoteValidator.new("Character/ConfirmRace", 1)

	confirmRaceRemote.OnServerInvoke = confirmRaceValidator:WrapHandler(function(player, raceId)
		-- Validasi tipe argumen
		local ok, err = confirmRaceValidator:Validate(player, {
			{ value = raceId, name = "raceId", type = "string", minLength = 1, maxLength = 64 },
		})
		if not ok then
			return { success = false, reason = err }
		end

		local data = dataService.WaitForProfile(player, 10)
		if not data then
			return { success = false, reason = "Profile belum siap" }
		end

		-- Sudah punya ras — tidak boleh ubah lagi
		if data.RaceId then
			return { success = false, reason = "Sudah memilih ras" }
		end

		-- Validasi raceId terhadap Config
		if not isValidRace(raceId) then
			return { success = false, reason = "Ras tidak valid" }
		end

		-- Simpan pilihan ras
		data.RaceId = raceId

		-- Terapkan stat bonus ras ke Stats pemain
		local raceData = RacesConfig[raceId]
		for stat, bonus in pairs(raceData.statBonus) do
			if data.Stats[stat] ~= nil then
				data.Stats[stat] = data.Stats[stat] + bonus
			end
		end

		return { success = true }
	end)

	-- === Remote: SelectClass ===
	local selectClassRemote = remotesFolder:WaitForChild("SelectClass")
	local selectClassValidator = RemoteValidator.new("Character/SelectClass", 1)

	selectClassRemote.OnServerInvoke = selectClassValidator:WrapHandler(function(player, classId)
		local ok, err = selectClassValidator:Validate(player, {
			{ value = classId, name = "classId", type = "string", minLength = 1, maxLength = 64 },
		})
		if not ok then
			return { success = false, reason = err }
		end

		local data = dataService.WaitForProfile(player, 10)
		if not data then
			return { success = false, reason = "Profile belum siap" }
		end

		-- Sudah punya kelas — tidak boleh ubah lagi
		if data.ClassId then
			return { success = false, reason = "Sudah memilih kelas" }
		end

		-- Harus sudah pilih ras dulu
		if not data.RaceId then
			return { success = false, reason = "Pilih ras terlebih dahulu" }
		end

		-- Validasi classId: harus ada di Config dan Tier 1
		if not isValidStartingClass(classId) then
			return { success = false, reason = "Kelas tidak valid atau bukan starting class" }
		end

		data.ClassId = classId
		return { success = true }
	end)

	-- === Remote: CreationStatus ===
	local statusRemote = remotesFolder:WaitForChild("CreationStatus")
	local statusValidator = RemoteValidator.new("Character/CreationStatus", 1)

	statusRemote.OnServerInvoke = statusValidator:WrapHandler(function(player)
		local data = dataService.WaitForProfile(player, 10)
		if not data then
			return { hasRace = false, hasClass = false }
		end
		return {
			hasRace = data.RaceId ~= nil,
			hasClass = data.ClassId ~= nil,
		}
	end)
end

return CharacterService
