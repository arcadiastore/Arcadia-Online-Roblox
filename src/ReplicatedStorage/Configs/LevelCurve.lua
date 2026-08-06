--[[
	LevelCurve.lua
	Sumber kebenaran untuk progression level: EXP per level, base stat per
	level, Combat Points per level, dan level cap. Dipakai oleh LevelService
	(belum diimplementasi), CombatService, dan CharacterService.

	Filosofi desain (docs/01_GDD.md §2, §4):
	  - Slow-paced: level awal cepat (tutorial feel), level atas butuh grind
	    bermakna. EXP curve pakai polinomial kuadratik supaya scaling halus.
	  - Level cap 50 untuk MVP (Fase 1–3 di GDD §19). Bisa dinaikkan nanti
	    tanpa mengubah formula — cukup tambah level baru.
	  - Combat Points: 3 per level, dialokasikan manual ke stat → build
	    variety (GDD §8.3). Total CP di level 50 = 147.
	  - Base stats: naik +2 per level ke semua stat (konsisten, tidak
	    memihak role tertentu — variasi build datang dari Ras + CP + Gear).

	Contoh pakai di Service:
	  local LevelCurve = require(ReplicatedStorage.Configs.LevelCurve)
	  local expNeeded = LevelCurve.GetRequiredExp(10)  -- EXP dari lv9 ke lv10
	  local baseStats = LevelCurve.GetBaseStats(25)     -- base stat di lv25
	  local cpGain    = LevelCurve.GetCombatPointsGain(30) -- CP didapat saat naik ke lv30

	JANGAN taruh angka/nama sistem ini langsung di dalam Service — semua
	logic wajib require() modul ini (aturan anti-hardcode, docs/06_CODING_STANDARDS.md §2).
]]

local LevelCurve = {}

-- === Konfigurasi inti (ubah di sini kalau perlu tuning) ===

LevelCurve.MaxLevel = 50

-- EXP yang dibutuhkan untuk naik DARI level L KE level L+1.
-- Formula: base + (level^2 * scalingFactor) → kuadratik, lambat di awal,
-- makin curam di atas. Tuning factor supaya:
--   Lv 1→2  =  100 EXP  (cepat, tutorial feel)
--   Lv 10→11 =  400 EXP  (mulai grind ringan)
--   Lv 25→26 = 1525 EXP  (grind bermakna)
--   Lv 49→50 = 4900 EXP  (butuh dedikasi)
--
-- Formula: math.floor(base + level^2 * factor)
LevelCurve.ExpBase = 0          -- offset konstan
LevelCurve.ExpScalingFactor = 2 -- multiplier level^2

-- Base stats untuk SEMUA ras di level tertentu. Ras memberi bonus TERPISAH
-- di atas base ini (lihat Configs/Races.lua statBonus). Naik flat +2 per
-- level ke semua stat (5 stat × 2 = 10 stat point per level otomatis).
--
-- Level 1 base: {5,5,5,5,5}  (ProfileTemplate.lua)
-- Level 50 base: {103,103,103,103,103}  (5 + 49×2)
LevelCurve.BaseStatPerLevel = 2  -- tambah per stat per level naik

-- Combat Points yang didapat setiap naik level. Dialokasikan manual oleh
-- pemain ke stat pilihan (GDD §8.3). 3 per level → total 147 di lv50.
LevelCurve.CombatPointsPerLevel = 3

-- === Fungsi helper (dipakai Service, bukan hardcode di logic) ===

--[[
	Mengembalikan EXP yang dibutuhkan untuk naik DARI level `fromLevel` KE
	`fromLevel + 1`. Return 0 jika fromLevel >= MaxLevel (sudah cap).
	Contoh: GetRequiredExp(1) = EXP untuk naik dari lv1 ke lv2.
]]
function LevelCurve.GetRequiredExp(fromLevel: number): number
	if fromLevel >= LevelCurve.MaxLevel then
		return 0
	end
	return math.floor(LevelCurve.ExpBase + fromLevel ^ 2 * LevelCurve.ExpScalingFactor)
end

--[[
	Mengembalikan total kumulatif EXP yang dibutuhkan untuk mencapai
	`targetLevel` dari level 1. Return 0 jika targetLevel <= 1.
	Dipakai untuk progress bar / persentase.
]]
function LevelCurve.GetTotalExpToLevel(targetLevel: number): number
	if targetLevel <= 1 then
		return 0
	end
	local total = 0
	for lv = 1, targetLevel - 1 do
		total += LevelCurve.GetRequiredExp(lv)
	end
	return total
end

--[[
	Mengembalikan base stats table untuk level tertentu. Ras bonus TIDAK
	termasuk di sini — itu ditambah CharacterService dari Configs/Races.lua.

	Base stat level 1 = {5,5,5,5,5} (sesuai ProfileTemplate.lua).
	Naik +BaseStatPerLevel per stat per level di atas 1.
]]
function LevelCurve.GetBaseStats(level: number): { STR: number, VIT: number, INT: number, AGI: number, LUK: number }
	local gain = (level - 1) * LevelCurve.BaseStatPerLevel
	return {
		STR = 5 + gain,
		VIT = 5 + gain,
		INT = 5 + gain,
		AGI = 5 + gain,
		LUK = 5 + gain,
	}
end

--[[
	Mengembalikan Combat Points yang didapat saat naik KE `newLevel`.
	Dipakai saat player naik level — tambahkan ini ke profile.UnspentCombatPoints.
	0 jika newLevel <= 1 (level 1 tidak dapat CP).
]]
function LevelCurve.GetCombatPointsGain(newLevel: number): number
	if newLevel <= 1 then
		return 0
	end
	return LevelCurve.CombatPointsPerLevel
end

--[[
	Mengembalikan level berdasarkan total EXP yang dimiliki pemain.
	Dipakai untuk menentukan level pemain dari accumulated EXP.
	Return level saat ini (bukan baru) — mis. kalau totalExp cukup untuk
	mencapai lv5, return 4 (pemain masih di lv4, butuh lagi untuk lv5).
]]
function LevelCurve.GetLevelFromTotalExp(totalExp: number): number
	local accumulated = 0
	for lv = 1, LevelCurve.MaxLevel - 1 do
		accumulated += LevelCurve.GetRequiredExp(lv)
		if totalExp < accumulated then
			return lv
		end
	end
	return LevelCurve.MaxLevel
end

return LevelCurve
