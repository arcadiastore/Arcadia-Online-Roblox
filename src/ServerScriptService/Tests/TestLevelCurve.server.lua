--[[
	TestLevelCurve.server.lua (v4 — full otomatis)
	Tinggal Play Solo, cek Output.

	HAPUS file ini sebelum publish ke production.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local LevelCurve = require(ReplicatedStorage.Configs.LevelCurve)
local RacesConfig = require(ReplicatedStorage.Configs.Races)
local ClassesConfig = require(ReplicatedStorage.Configs.Classes)

local passed = 0
local failed = 0

local function assert_eq(name, actual, expected)
	if actual == expected then
		passed += 1
		print(("  ✅ %s = %s"):format(name, tostring(actual)))
	else
		failed += 1
		warn(("  ❌ %s: expected %s, got %s"):format(name, tostring(expected), tostring(actual)))
	end
end

local function assert_true(name, condition)
	if condition then
		passed += 1
		print(("  ✅ %s"):format(name))
	else
		failed += 1
		warn(("  ❌ %s: FAIL"):format(name))
	end
end

local function section(title)
	print("\n" .. string.rep("-", 50))
	print(title)
	print(string.rep("-", 50))
end

-- ============================================================
-- BAGIAN 1: LevelCurve Config (langsung jalan)
-- ============================================================
print("\n" .. string.rep("=", 60))
print("BAGIAN 1: LevelCurve.lua")
print(string.rep("=", 60))

section("MaxLevel")
assert_eq("MaxLevel", LevelCurve.MaxLevel, 50)

section("EXP Required")
assert_eq("lv1→2", LevelCurve.GetRequiredExp(1), 2)
assert_eq("lv5→6", LevelCurve.GetRequiredExp(5), 50)
assert_eq("lv10→11", LevelCurve.GetRequiredExp(10), 200)
assert_eq("lv25→26", LevelCurve.GetRequiredExp(25), 1250)
assert_eq("lv49→50", LevelCurve.GetRequiredExp(49), 4802)
assert_eq("lv50 cap", LevelCurve.GetRequiredExp(50), 0)

section("Total EXP")
assert_eq("to lv2", LevelCurve.GetTotalExpToLevel(2), 2)
assert_eq("to lv3", LevelCurve.GetTotalExpToLevel(3), 10)
local totalManual = 0
for lv = 1, 49 do totalManual += LevelCurve.GetRequiredExp(lv) end
assert_eq("to lv50", LevelCurve.GetTotalExpToLevel(50), totalManual)

section("Base Stats")
assert_eq("STR lv1", LevelCurve.GetBaseStats(1).STR, 5)
assert_eq("STR lv10", LevelCurve.GetBaseStats(10).STR, 23)
assert_eq("STR lv50", LevelCurve.GetBaseStats(50).STR, 103)

section("Combat Points")
assert_eq("CP lv1", LevelCurve.GetCombatPointsGain(1), 0)
assert_eq("CP lv2", LevelCurve.GetCombatPointsGain(2), 3)
local totalCP = 0
for lv = 2, 50 do totalCP += LevelCurve.GetCombatPointsGain(lv) end
assert_eq("Total CP", totalCP, 147)

section("GetLevelFromTotalExp")
assert_eq("0 exp", LevelCurve.GetLevelFromTotalExp(0), 1)
assert_eq("2 exp", LevelCurve.GetLevelFromTotalExp(2), 2)
assert_eq("10 exp", LevelCurve.GetLevelFromTotalExp(10), 3)

section("Config Data")
local rc = 0
for _ in pairs(RacesConfig) do rc += 1 end
assert_eq("Races", rc, 5)
local cc, t1c = 0, 0
for _, d in pairs(ClassesConfig) do cc += 1; if d.tier == 1 then t1c += 1 end end
assert_eq("Classes", cc, 18)
assert_eq("Tier1", t1c, 6)

section("Race + Base combo")
assert_eq("Angel STR lv1", LevelCurve.GetBaseStats(1).STR + RacesConfig.Angel.statBonus.STR, 2)
assert_true("Angel STR > 0", LevelCurve.GetBaseStats(1).STR + RacesConfig.Angel.statBonus.STR > 0)

-- Summary bagian 1
print("\n" .. string.rep("=", 60))
print(("BAGIAN 1: %d passed, %d failed"):format(passed, failed))
if failed == 0 then print("🎉 LevelCurve ALL PASS!") end
print(string.rep("=", 60))

-- ============================================================
-- BAGIAN 2 & 3: CharacterService + LevelService (tunggu player)
-- ============================================================
task.spawn(function()
	local player = Players.PlayerAdded:Wait()
	print(("\n\n🎮 Player '%s' joined"):format(player.Name))

	local DataService = require(ServerScriptService.Services.DataService)
	local CharacterService = require(ServerScriptService.Services.CharacterService)
	local LevelService = require(ServerScriptService.Services.LevelService)

	local data = nil
	for i = 1, 30 do
		data = DataService.GetProfile(player)
		if data then break end
		task.wait(1)
		if i % 5 == 0 then print(("  ⏳ Profile loading... %ds"):format(i)) end
	end

	if not data then
		warn("❌ Profile tidak siap setelah 30 detik!")
		warn("   Cek: Game Settings → Security → Enable Studio Access to API Services")
		return
	end

	print(("  ✅ Profile: Lv%d, Race=%s, Class=%s, STR=%d, CP=%d"):format(
		data.Level, tostring(data.RaceId), tostring(data.ClassId),
		data.Stats.STR, data.UnspentCombatPoints))

	-- === Character creation (kalau belum) ===
	if not data.RaceId or not data.ClassId then
		section("BAGIAN 2: Character Creation (auto)")

		local r1 = CharacterService.RerollRace(player)
		print(("  📊 Reroll: %s (%s)"):format(tostring(r1.raceId), tostring(r1.rarity)))
		assert_true("Reroll sukses", r1.success)

		if r1.success then
			local r2 = CharacterService.ConfirmRace(player, r1.raceId)
			print(("  📊 ConfirmRace: %s"):format(tostring(r2.success)))
			assert_true("ConfirmRace sukses", r2.success)
		end

		local r3 = CharacterService.SelectClass(player, "Warrior")
		print(("  📊 SelectClass: %s"):format(tostring(r3.success)))
		assert_true("SelectClass sukses", r3.success)

		task.wait(0.5)
		data = DataService.GetProfile(player)
		print(("  📊 Setelah creation: Race=%s, Class=%s, STR=%d"):format(
			tostring(data.RaceId), tostring(data.ClassId), data.Stats.STR))
	else
		print(("  ℹ️  Sudah ada: %s/%s — skip creation"):format(
			tostring(data.RaceId), tostring(data.ClassId)))
	end

	-- === LevelService tests ===
	section("BAGIAN 3: LevelService")

	local isMaxLevel = data.Level >= LevelCurve.MaxLevel

	if isMaxLevel then
		print(("  ℹ️  Player sudah Lv%d (max) — skip level-up test"):format(data.Level))
		print("  ℹ️  (Reset data player di DataStore untuk test level-up)")

		-- Test EXP overflow di max level
		local oldExp = data.Exp
		local r1 = LevelService:AddExp(player, 100)
		print(("  📊 AddExp(100) di max level: gained=%d, Lv%d, EXP=%d"):format(
			r1.levelsGained, r1.newLevel, r1.newExp))
		assert_eq("Level tetap max", r1.newLevel, LevelCurve.MaxLevel)
		assert_true("EXP tetap naik", r1.newExp > oldExp)
	else
		print(("  📊 Start: Lv%d, EXP=%d"):format(data.Level, data.Exp))

		-- AddExp kecil
		local r1 = LevelService:AddExp(player, 1)
		print(("  📊 +1 EXP → Lv%d, EXP=%d"):format(r1.newLevel, r1.newExp))

		-- AddExp cukup untuk level-up
		local need = LevelCurve.GetRequiredExp(data.Level)
		local r2 = LevelService:AddExp(player, need + 100)
		print(("  📊 +%d EXP → gained=%d, Lv%d"):format(need + 100, r2.levelsGained, r2.newLevel))
		assert_true("Level naik", r2.levelsGained >= 1)

		-- Multiple level-up
		local r3 = LevelService:AddExp(player, 50000)
		print(("  📊 +50000 → gained=%d, Lv%d"):format(r3.levelsGained, r3.newLevel))
		assert_true("Multiple level-up", r3.levelsGained >= 1)
	end

	-- AllocateCP (selalu test, mau max level atau tidak)
	local cp = LevelService:GetUnspentPoints(player)
	print(("  📊 UnspentCP: %d"):format(cp))

	if cp > 0 then
		local a1 = LevelService.AllocateCP(player, "STR")
		print(("  📊 AllocateCP('STR'): %s, sisa=%s"):format(
			tostring(a1.success), tostring(a1.unspentPoints)))
		assert_true("AllocateCP sukses", a1.success)
		assert_true("CP berkurang", a1.unspentPoints < cp)
	else
		print("  ℹ️  CP = 0 — skip AllocateCP test (butuh level-up dulu)")
	end

	local a2 = LevelService.AllocateCP(player, "INVALID")
	print(("  📊 AllocateCP('INVALID'): %s (%s)"):format(
		tostring(a2.success), tostring(a2.reason)))
	assert_true("INVALID ditolak", not a2.success)

	-- Final
	print(("\n  📊 FINAL: Lv%d, STR=%d, CP=%d, EXP=%d"):format(
		data.Level, data.Stats.STR, data.UnspentCombatPoints, data.Exp))

	-- ============================================================
	-- SUMMARY
	-- ============================================================
	print("\n" .. string.rep("=", 60))
	print(("TOTAL: %d passed, %d failed"):format(passed, failed))
	if failed == 0 then
		print("🎉🎉🎉 SEMUA TEST LULUS!")
	else
		warn(("⚠️  %d GAGAL"):format(failed))
	end
	print(string.rep("=", 60))
end)
