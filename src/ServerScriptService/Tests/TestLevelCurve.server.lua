--[[
	TestLevelCurve.server.lua (v5 — fresh reset + full flow)
	Play Solo, cek Output. Reset data ke fresh state sebelum test.

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

print("\n" .. string.rep("=", 60))
print(("BAGIAN 1: %d passed, %d failed"):format(passed, failed))
if failed == 0 then print("🎉 LevelCurve ALL PASS!") end
print(string.rep("=", 60))

-- ============================================================
-- BAGIAN 2 & 3: CharacterService + LevelService (fresh test)
-- ============================================================
task.spawn(function()
	local player = Players.PlayerAdded:Wait()
	print(("\n\n🎮 Player '%s' joined"):format(player.Name))

	local DataService = require(ServerScriptService.Services.DataService)
	local CharacterService = require(ServerScriptService.Services.CharacterService)
	local LevelService = require(ServerScriptService.Services.LevelService)

	-- Tunggu profile
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

	-- ========================================
	-- RESET ke fresh state (persist ke DataStore)
	-- ========================================
	section("RESET: Profile ke fresh state")
	print(("  Sebelum: Lv%d, Race=%s, Class=%s, STR=%d, CP=%d, EXP=%d"):format(
		data.Level, tostring(data.RaceId), tostring(data.ClassId),
		data.Stats.STR, data.UnspentCombatPoints, data.Exp))

	local ok = DataService.ResetToTemplate(player)
	assert_true("ResetToTemplate sukses", ok)

	-- Re-read data setelah reset
	task.wait(0.2)
	data = DataService.GetProfile(player)
	print(("  Sesudah: Lv%d, Race=%s, Class=%s, STR=%d, CP=%d, EXP=%d"):format(
		data.Level, tostring(data.RaceId), tostring(data.ClassId),
		data.Stats.STR, data.UnspentCombatPoints, data.Exp))
	assert_true("RaceId nil", data.RaceId == nil)
	assert_true("ClassId nil", data.ClassId == nil)
	assert_true("Level 1", data.Level == 1)

	-- ========================================
	-- BAGIAN 2: Character Creation (full flow)
	-- ========================================
	section("BAGIAN 2: Character Creation")

	-- 2a. Sebelum pilih ras, SelectClass harus ditolak
	local rejectClass = CharacterService.SelectClass(player, "Warrior")
	print(("  📊 SelectClass sebelum Race: %s (%s)"):format(
		tostring(rejectClass.success), tostring(rejectClass.reason)))
	assert_true("SelectClass ditolak tanpa Race", not rejectClass.success)

	-- 2b. RerollRace
	local r1 = CharacterService.RerollRace(player)
	print(("  📊 Reroll: %s (%s, bonus=%s)"):format(
		tostring(r1.raceId), tostring(r1.rarity),
		r1.statBonus and tostring(r1.statBonus.STR) or "?"))
	assert_true("Reroll sukses", r1.success)
	assert_true("RaceId masih nil", data.RaceId == nil) -- reroll tidak mengubah profile

	-- 2c. ConfirmRace (tolak raceId invalid)
	local badRace = CharacterService.ConfirmRace(player, "FakeRace123")
	print(("  📊 ConfirmRace('FakeRace123'): %s (%s)"):format(
		tostring(badRace.success), tostring(badRace.reason)))
	assert_true("FakeRace ditolak", not badRace.success)

	-- 2d. ConfirmRace (pakai race hasil reroll)
	local raceToPick = r1.raceId or "Human"
	local r2 = CharacterService.ConfirmRace(player, raceToPick)
	print(("  📊 ConfirmRace('%s'): %s"):format(raceToPick, tostring(r2.success)))
	assert_true("ConfirmRace sukses", r2.success)

	local raceBonus = RacesConfig[raceToPick].statBonus
	local expectedSTR = 5 + (raceBonus.STR or 0)
	print(("  📊 STR sesudah: %d (base 5 + race %d)"):format(
		data.Stats.STR, raceBonus.STR or 0))
	assert_eq("STR sesudah confirm", data.Stats.STR, expectedSTR)

	-- 2e. ConfirmRace lagi harus ditolak (idempotensi)
	local r2b = CharacterService.ConfirmRace(player, "Human")
	print(("  📊 ConfirmRace lagi: %s (%s)"):format(
		tostring(r2b.success), tostring(r2b.reason)))
	assert_true("ConfirmRace idempotent", not r2b.success)

	-- 2f. RerollRace lagi harus ditolak (sudah punya race)
	local r1b = CharacterService.RerollRace(player)
	print(("  📊 RerollRace lagi: %s (%s)"):format(
		tostring(r1b.success), tostring(r1b.reason)))
	assert_true("RerollRace idempotent", not r1b.success)

	-- 2g. SelectClass (tolak class invalid)
	local badClass = CharacterService.SelectClass(player, "FakeClass")
	print(("  📊 SelectClass('FakeClass'): %s (%s)"):format(
		tostring(badClass.success), tostring(badClass.reason)))
	assert_true("FakeClass ditolak", not badClass.success)

	-- 2h. SelectClass (tolak Tier 2)
	local tier2Class = CharacterService.SelectClass(player, "Knight")
	print(("  📊 SelectClass('Knight' T2): %s (%s)"):format(
		tostring(tier2Class.success), tostring(tier2Class.reason)))
	assert_true("Tier 2 ditolak", not tier2Class.success)

	-- 2i. SelectClass (Warrior)
	local r3 = CharacterService.SelectClass(player, "Warrior")
	print(("  📊 SelectClass('Warrior'): %s"):format(tostring(r3.success)))
	assert_true("SelectClass sukses", r3.success)

	-- 2j. SelectClass lagi harus ditolak (idempotensi)
	local r3b = CharacterService.SelectClass(player, "Mage")
	print(("  📊 SelectClass lagi: %s (%s)"):format(
		tostring(r3b.success), tostring(r3b.reason)))
	assert_true("SelectClass idempotent", not r3b.success)

	-- 2k. CreationStatus
	local status = CharacterService.GetCreationStatus(player)
	print(("  📊 Status: hasRace=%s, hasClass=%s"):format(
		tostring(status.hasRace), tostring(status.hasClass)))
	assert_true("Status hasRace", status.hasRace)
	assert_true("Status hasClass", status.hasClass)

	print(("  📊 FINAL creation: Race=%s, Class=%s, STR=%d"):format(
		tostring(data.RaceId), tostring(data.ClassId), data.Stats.STR))

	-- ========================================
	-- BAGIAN 3: LevelService (fresh from Lv1)
	-- ========================================
	section("BAGIAN 3: LevelService (from Lv1)")

	print(("  📊 Start: Lv%d, EXP=%d, STR=%d, CP=%d"):format(
		data.Level, data.Exp, data.Stats.STR, data.UnspentCombatPoints))

	-- 3a. AddExp kecil (tidak cukup level-up)
	local r4 = LevelService:AddExp(player, 1)
	print(("  📊 +1 EXP → Lv%d, EXP=%d, gained=%d"):format(
		r4.newLevel, r4.newExp, r4.levelsGained))
	assert_eq("Belum level-up", r4.levelsGained, 0)

	-- 3b. AddExp cukup untuk 1 level-up
	local need = LevelCurve.GetRequiredExp(1) -- EXP needed lv1→2
	local r5 = LevelService:AddExp(player, need)
	print(("  📊 +%d EXP → Lv%d, EXP=%d, gained=%d"):format(
		need, r5.newLevel, r5.newExp, r5.levelsGained))
	assert_true("Level 1→2", r5.levelsGained >= 1)
	assert_true("STR naik", data.Stats.STR > expectedSTR)

	local strAtLv2 = data.Stats.STR
	print(("  📊 STR di Lv%d: %d"):format(data.Level, data.Stats.STR))

	-- 3c. Multiple level-up sekaligus
	local r6 = LevelService:AddExp(player, 50000)
	print(("  📊 +50000 EXP → Lv%d, gained=%d, EXP=%d"):format(
		r6.newLevel, r6.levelsGained, r6.newExp))
	assert_true("Multiple level-up", r6.levelsGained >= 1)

	local cpAfter = LevelService:GetUnspentPoints(player)
	print(("  📊 UnspentCP setelah level-up: %d"):format(cpAfter))
	assert_true("CP > 0", cpAfter > 0)

	-- 3d. AllocateCP
	local a1 = LevelService.AllocateCP(player, "STR")
	print(("  📊 AllocateCP('STR'): %s, sisa=%s"):format(
		tostring(a1.success), tostring(a1.unspentPoints)))
	assert_true("AllocateCP sukses", a1.success)
	assert_true("CP berkurang", a1.unspentPoints < cpAfter)

	-- 3e. AllocateCP invalid
	local a2 = LevelService.AllocateCP(player, "INVALID")
	print(("  📊 AllocateCP('INVALID'): %s (%s)"):format(
		tostring(a2.success), tostring(a2.reason)))
	assert_true("INVALID ditolak", not a2.success)

	-- Final
	print(("\n  📊 FINAL: Lv%d, Race=%s, Class=%s, STR=%d, CP=%d, EXP=%d"):format(
		data.Level, tostring(data.RaceId), tostring(data.ClassId),
		data.Stats.STR, data.UnspentCombatPoints, data.Exp))

	-- ========================================
	-- BAGIAN 4: GateService test (butuh Lv10+)
	-- ========================================
	section("BAGIAN 4: GateService")

	local GateService = require(ServerScriptService.Services.GateService)

	-- Pastikan level cukup untuk Gate_Duskwood
	if data.Level < 10 then
		LevelService:AddExp(player, 50000) -- naikkan ke Lv40+
		data = DataService.GetProfile(player)
		print(("  📊 Level-up ke Lv%d untuk gate test"):format(data.Level))
	end

	-- 4a. Gate tidak valid
	local g1 = GateService.TryOpenGate(player, "FakeGate")
	print(("  📊 TryOpenGate('FakeGate'): %s (%s)"):format(tostring(g1.success), tostring(g1.reason)))
	assert_true("FakeGate ditolak", not g1.success)

	-- 4b. Gate dengan syarat level terpenuhi (Duskwood perlu Lv10)
	local g2 = GateService.TryOpenGate(player, "Gate_Duskwood")
	print(("  📊 TryOpenGate('Gate_Duskwood'): %s, dest=%s"):format(
		tostring(g2.success), tostring(g2.destination)))
	assert_true("Gate_Duskwood sukses", g2.success)
	assert_eq("Dest = DuskwoodForest", g2.destination, "DuskwoodForest")

	-- 4c. Gate sudah terbuka (idempotent)
	local g3 = GateService.TryOpenGate(player, "Gate_Duskwood")
	print(("  📊 TryOpenGate lagi: %s, alreadyUnlocked=%s"):format(
		tostring(g3.success), tostring(g3.alreadyUnlocked)))
	assert_true("Already unlocked", g3.alreadyUnlocked)

	-- 4d. Gate dengan syarat quest (belum punya quest → ditolak)
	local g4 = GateService.TryOpenGate(player, "Gate_Frostpeak")
	print(("  📊 TryOpenGate('Gate_Frostpeak'): %s (%s)"):format(
		tostring(g4.success), tostring(g4.reason)))
	assert_true("Frostpeak ditolak (no quest)", not g4.success)

	-- 4e. GetUnlockedGates
	local unlocked = GateService.GetUnlockedGates(player)
	print(("  📊 Unlocked gates: %d"):format(unlocked and (function() local c = 0; for _ in pairs(unlocked) do c += 1 end; return c end)() or 0))
	assert_true("Duskwood unlocked", unlocked and unlocked.Gate_Duskwood)

	-- 4f. IsGateUnlocked
	assert_true("IsGateUnlocked Duskwood", GateService.IsGateUnlocked(player, "Gate_Duskwood"))
	assert_true("IsGateUnlocked Frostpeak = false", not GateService.IsGateUnlocked(player, "Gate_Frostpeak"))

	print(("  📊 FINAL: Lv%d, UnlockedGates: Duskwood=%s"):format(
		data.Level, tostring(unlocked.Gate_Duskwood ~= nil)))

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

	-- Cleanup: reset ke template supaya saat player leave, Release() simpan
	-- data fresh (bukan data test Lv42). DeleteStoredData TIDAK dipakai karena
	-- Release() akan save ulang setelah delete.
	DataService.ResetToTemplate(player)
	print("\n🧹 Profile di-reset ke template — next join = fresh profile")
end)
