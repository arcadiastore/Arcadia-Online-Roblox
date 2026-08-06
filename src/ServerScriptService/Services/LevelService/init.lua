--[[
	LevelService.lua
	Service leveling & EXP: proses gain EXP, level-up, alokasi Combat Points,
	dan expose API untuk Service lain (CombatService, QuestService, dst.)
	memberi EXP ke pemain.

	Dipanggil oleh: Main.server.lua (bootstrap).
	Mewarisi BaseService.

	API publik (server-only, dipanggil Service lain):
	  LevelService.AddExp(player, amount)
	    — tambah EXP, proses level-up otomatis jika threshold tercapai.
	    — amount wajib > 0 (kalau <= 0, abaikan tanpa error).
	    — return: { levelsGained, newLevel, newExp }

	  LevelService.GetLevel(player) -> number
	  LevelService.GetRequiredExpForNextLevel(player) -> number | 0 (sudah cap)
	  LevelService.GetProgressPercent(player) -> number (0–100)

	  LevelService.AllocateCombatPoint(player, statName) -> { success, reason? }
	    — alokasi 1 UnspentCombatPoints ke stat tertentu (STR/VIT/INT/AGI/LUK).

	  LevelService.GetUnspentPoints(player) -> number

	Remotes:
	  Level/LevelUp    (RemoteEvent, server→client) — notifikasi level-up
	    payload: { newLevel, combatPointsGained, baseStats }
	  Level/AllocateCP (RemoteFunction, client→server) — alokasi CP
	    payload: statName (string)
	    return: { success, reason?, unspentPoints? }

	Anti-exploit (docs/06_CODING_STANDARDS.md §3):
	  - AddExp HANYA bisa dipanggil dari server-side Service lain, BUKAN
	    dari client (tidak ada remote AddExp). Client tidak bisa inject EXP.
	  - AllocateCP divalidasi: statName harus salah satu dari 5 stat, harus
	    punya UnspentCombatPoints > 0.
	  - Rate limit AllocateCP (0.2s debounce, mencegah spam click).
	  - Semua perhitungan EXP/level di server.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("BaseService"))
local LevelCurve = require(ReplicatedStorage.Configs.LevelCurve)
local RemoteValidator = require(ReplicatedStorage.Shared.RemoteValidator)

local LevelService = BaseService:Extend("LevelService")

local DATA_SERVICE_NAME = "DataService"

-- Stat yang valid untuk alokasi CP (hardcode kecil, karena ini enum tetap
-- — kalau suatu hari stat bertambah, cukup edit di sini + ProfileTemplate).
local VALID_STATS = {
	STR = true,
	VIT = true,
	INT = true,
	AGI = true,
	LUK = true,
}

-- === Level-up internal (dipanggil dari AddExp) ===

local function processLevelUps(player, data)
	local levelsGained = 0
	local totalCPGained = 0

	while data.Level < LevelCurve.MaxLevel do
		local required = LevelCurve.GetRequiredExp(data.Level)
		if required <= 0 or data.Exp < required then
			break
		end

		data.Exp -= required
		data.Level += 1
		levelsGained += 1

		-- Combat Points
		local cpGain = LevelCurve.GetCombatPointsGain(data.Level)
		if cpGain > 0 then
			data.UnspentCombatPoints += cpGain
			totalCPGained += cpGain
		end
	end

	-- Recalculate base stats setelah level-up (base naik, tapi stat bonus
	-- ras TIDAK diubah — CharacterService sudah menambahkannya sekali saat
	-- ConfirmRace). Base baru = LevelCurve.GetBaseStats(level), lalu tambah
	-- ras bonus dari data awal.
	-- Cara aman: hitung ulang base, lalu tambah CP-allocated points.
	-- Tapi karena CP dialokasikan langsung ke data.Stats (bukan tracked
	-- terpisah), kita pakai pendekatan: kurangi old base, tambah new base.
	if levelsGained > 0 then
		local oldLevel = data.Level - levelsGained
		local oldBase = LevelCurve.GetBaseStats(oldLevel)
		local newBase = LevelCurve.GetBaseStats(data.Level)

		for stat, newVal in pairs(newBase) do
			if data.Stats[stat] ~= nil then
				-- Kurangi base lama, tambah base baru → net gain = levelsGained * BaseStatPerLevel
				data.Stats[stat] = data.Stats[stat] - oldBase[stat] + newVal
			end
		end
	end

	return levelsGained, totalCPGained
end

function LevelService:Init()
	BaseService.Init(self)
end

function LevelService:Start()
	BaseService.Start(self)

	local dataService = self:GetService(DATA_SERVICE_NAME)

	-- === Remote: LevelUp (server→client notification) ===
	local levelRemotes = ReplicatedStorage.Remotes:WaitForChild("Level")
	local levelUpEvent = levelRemotes:WaitForChild("LevelUp")

	-- === Remote: AllocateCP (client→server) ===
	local allocateRemote = levelRemotes:WaitForChild("AllocateCP")
	local allocateValidator = RemoteValidator.new("Level/AllocateCP", 0.2)

	allocateRemote.OnServerInvoke = allocateValidator:WrapHandler(function(player, statName)
		local ok, err = allocateValidator:Validate(player, {
			{ value = statName, name = "statName", type = "string", minLength = 1, maxLength = 10 },
		})
		if not ok then
			return { success = false, reason = err }
		end
		return LevelService.AllocateCP(player, statName)
	end)

	-- === Simpan reference ke levelUpEvent untuk dipakai di AddExp ===
	self._levelUpEvent = levelUpEvent
	self._dataService = dataService
end

--[[
	Tambah EXP ke pemain. Dipanggil oleh Service lain (CombatService saat
	kill musuh, QuestService saat quest selesai, dst.).
	amount wajib > 0.

	return: { levelsGained = number, newLevel = number, newExp = number }
]]
function LevelService:AddExp(player, amount: number)
	assert(type(amount) == "number" and amount > 0, "LevelService:AddExp — amount harus > 0")

	local data = self._dataService.GetProfile(player)
	if not data then
		return { levelsGained = 0, newLevel = 0, newExp = 0 }
	end

	-- Harus sudah selesai character creation
	if not data.RaceId or not data.ClassId then
		return { levelsGained = 0, newLevel = data.Level, newExp = data.Exp }
	end

	-- Cap EXP: kalau sudah MaxLevel, EXP tetap naik tapi level tidak
	if data.Level >= LevelCurve.MaxLevel then
		data.Exp += amount
		return { levelsGained = 0, newLevel = data.Level, newExp = data.Exp }
	end

	data.Exp += amount

	local levelsGained, cpGained = processLevelUps(player, data)

	-- Kirim notifikasi level-up ke client
	if levelsGained > 0 and self._levelUpEvent then
		local baseStats = LevelCurve.GetBaseStats(data.Level)
		self._levelUpEvent:FireClient(player, {
			newLevel = data.Level,
			combatPointsGained = cpGained,
			baseStats = baseStats,
		})
	end

	return {
		levelsGained = levelsGained,
		newLevel = data.Level,
		newExp = data.Exp,
	}
end

--[[
	Mengembalikan level pemain saat ini. 0 jika profile belum siap.
]]
function LevelService:GetLevel(player): number
	local data = self._dataService.GetProfile(player)
	return data and data.Level or 0
end

--[[
	EXP yang dibutuhkan untuk naik ke level berikutnya. 0 jika sudah cap.
]]
function LevelService:GetRequiredExpForNextLevel(player): number
	local data = self._dataService.GetProfile(player)
	if not data then return 0 end
	return LevelCurve.GetRequiredExp(data.Level)
end

--[[
	Persentase progress ke level berikutnya (0–100). 100 jika sudah cap.
]]
function LevelService:GetProgressPercent(player): number
	local data = self._dataService.GetProfile(player)
	if not data then return 0 end
	if data.Level >= LevelCurve.MaxLevel then return 100 end
	local required = LevelCurve.GetRequiredExp(data.Level)
	if required <= 0 then return 100 end
	return math.clamp(data.Exp / required * 100, 0, 100)
end

--[[
	Combat Points yang belum dialokasikan.
]]
function LevelService:GetUnspentPoints(player): number
	local data = self._dataService.GetProfile(player)
	return data and data.UnspentCombatPoints or 0
end

--[[
	Alokasi 1 Combat Point ke stat tertentu. Bisa dipanggil dari remote
	(client→server) atau dari Service/test lain (server-only).

	  statName: "STR" | "VIT" | "INT" | "AGI" | "LUK"

	return: { success, reason?, unspentPoints? }
]]
function LevelService.AllocateCP(player, statName: string)
	if not VALID_STATS[statName] then
		return { success = false, reason = "Stat tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local data = ds and ds.WaitForProfile(player, 10)
	if not data then
		return { success = false, reason = "Profile belum siap" }
	end
	if not data.RaceId or not data.ClassId then
		return { success = false, reason = "Selesaikan pembuatan karakter terlebih dahulu" }
	end
	if data.UnspentCombatPoints <= 0 then
		return { success = false, reason = "Tidak ada Combat Points tersisa" }
	end

	data.UnspentCombatPoints -= 1
	data.Stats[statName] += 1

	return { success = true, unspentPoints = data.UnspentCombatPoints }
end

return LevelService
