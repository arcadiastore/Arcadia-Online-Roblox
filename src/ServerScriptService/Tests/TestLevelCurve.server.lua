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

	-- ========================================
	-- BAGIAN 5: JobChangeService
	-- ========================================
	section("BAGIAN 5: JobChangeService")

	local JobChangeService = require(ServerScriptService.Services.JobChangeService)

	-- 5a. Job change tanpa class (reset profile dulu)
	DataService.ResetToTemplate(player)
	task.wait(0.2)
	data = DataService.GetProfile(player)

	local j1 = JobChangeService:TryJobChange(player)
	print(("  📊 TryJobChange tanpa class: %s (%s)"):format(tostring(j1.success), tostring(j1.reason)))
	assert_true("No class → tolak", not j1.success)

	-- 5b. Setup: pilih class Warrior (Tier 1), level up
	local CharService2 = require(ServerScriptService.Services.CharacterService)
	CharService2.RerollRace(player)
	CharService2.ConfirmRace(player, "Human")
	CharService2.SelectClass(player, "Warrior")
	LevelService:AddExp(player, 100000) -- naikkan ke Lv45
	data = DataService.GetProfile(player)
	print(("  📊 Setup: %s %s Lv%d, Tier=%d"):format(
		data.RaceId, data.ClassId, data.Level, data.ClassTier or 1))

	-- 5c. Warrior→Knight (Level15, quest required)
	local j2 = JobChangeService:TryJobChange(player)
	print(("  📊 Warrior→Knight tanpa quest: %s (%s)"):format(tostring(j2.success), tostring(j2.reason)))
	assert_true("Quest belum → tolak", not j2.success)

	-- 5d. Tambah quest, coba lagi
	if not data.CompletedQuests then data.CompletedQuests = {} end
	data.CompletedQuests["Q_JobChange_Knight"] = true
	local j3 = JobChangeService:TryJobChange(player)
	print(("  📊 Warrior→Knight + quest: %s, newClass=%s, tier=%d"):format(
		tostring(j3.success), tostring(j3.newClassId), j3.newTier or 0))
	assert_true("Knight sukses", j3.success)
	assert_eq("Class = Knight", j3.newClassId, "Knight")
	assert_eq("Tier = 2", j3.newTier, 2)

	-- 5e. Knight→Warlord (Level40, quest required)
	local j4 = JobChangeService:TryJobChange(player)
	print(("  📊 Knight→Warlord tanpa quest: %s (%s)"):format(tostring(j4.success), tostring(j4.reason)))
	assert_true("Warlord quest belum → tolak", not j4.success)

	-- 5f. Tambah quest, coba lagi
	data.CompletedQuests["Q_JobChange_Warlord"] = true
	local j5 = JobChangeService:TryJobChange(player)
	print(("  📊 Knight→Warlord + quest: %s, newClass=%s, tier=%d"):format(
		tostring(j5.success), tostring(j5.newClassId), j5.newTier or 0))
	assert_true("Warlord sukses", j5.success)
	assert_eq("Class = Warlord", j5.newClassId, "Warlord")
	assert_eq("Tier = 3", j5.newTier, 3)

	-- 5g. Warlord = tier max, tidak bisa naik lagi
	local j6 = JobChangeService:TryJobChange(player)
	print(("  📊 Warlord→lagi: %s (%s)"):format(tostring(j6.success), tostring(j6.reason)))
	assert_true("Tier max → tolak", not j6.success)
	assert_eq("Tier = 3", j6.tier, 3)

	-- 5h. Cek final data
	data = DataService.GetProfile(player)
	print(("  📊 FINAL: ClassId=%s, ClassTier=%d"):format(data.ClassId, data.ClassTier))
	assert_eq("ClassId = Warlord", data.ClassId, "Warlord")
	assert_eq("ClassTier = 3", data.ClassTier, 3)

	-- ========================================
	-- BAGIAN 6: QuestService
	-- ========================================
	section("BAGIAN 6: QuestService")

	local QuestService = require(ServerScriptService.Services.QuestService)

	-- Reset profile fresh
	DataService.ResetToTemplate(player)
	task.wait(0.2)
	-- Setup: pilih class + level up
	CharService2.RerollRace(player)
	CharService2.ConfirmRace(player, "Human")
	CharService2.SelectClass(player, "Warrior")
	LevelService:AddExp(player, 50000) -- Lv40+
	data = DataService.GetProfile(player)
	print(("  📊 Setup: Lv%d"):format(data.Level))

	-- 6a. Accept quest tidak valid
	local q1 = QuestService:AcceptQuest(player, "FakeQuest")
	print(("  📊 AcceptQuest('FakeQuest'): %s (%s)"):format(tostring(q1.success), tostring(q1.reason)))
	assert_true("FakeQuest ditolak", not q1.success)

	-- 6b. Accept quest tanpa prereq (Q_Millhaven_Intro, Lv1)
	local q2 = QuestService:AcceptQuest(player, "Q_Millhaven_Intro")
	print(("  📊 AcceptQuest('Q_Millhaven_Intro'): %s, name=%s"):format(
		tostring(q2.success), tostring(q2.questName)))
	assert_true("Intro accepted", q2.success)

	-- 6c. Accept lagi (sudah aktif)
	local q3 = QuestService:AcceptQuest(player, "Q_Millhaven_Intro")
	print(("  📊 AcceptQuest lagi: %s (%s)"):format(tostring(q3.success), tostring(q3.reason)))
	assert_true("Sudah aktif → tolak", not q3.success)

	-- 6d. ReportProgress (server-side only)
	QuestService:ReportProgress(player, "NPC_ElderAldric", 1)
	local log1 = QuestService:GetQuestLog(player)
	local introEntry = log1.questLog and log1.questLog["Q_Millhaven_Intro"]
	print(("  📊 Progress NPC_ElderAldric: %d/1"):format(
		introEntry and introEntry.progress["NPC_ElderAldric"] or 0))
	assert_true("Progress = 1", introEntry and introEntry.progress["NPC_ElderAldric"] == 1)

	-- 6e. Complete quest
	local q4 = QuestService:CompleteQuest(player, "Q_Millhaven_Intro")
	print(("  📊 CompleteQuest('Q_Millhaven_Intro'): %s, rewards=%s"):format(
		tostring(q4.success), tostring(q4.rewards and q4.rewards.exp)))
	assert_true("Intro completed", q4.success)
	assert_eq("EXP reward = 50", q4.rewards.exp, 50)

	-- 6f. Quest masuk CompletedQuests
	data = DataService.GetProfile(player)
	print(("  📊 CompletedQuests[Intro]: %s"):format(tostring(data.CompletedQuests["Q_Millhaven_Intro"])))
	assert_true("Intro di CompletedQuests", data.CompletedQuests["Q_Millhaven_Intro"])

	-- 6g. Accept quest yang butuh prereq (Q_Millhaven_WolfThreat perlu Intro)
	local q5 = QuestService:AcceptQuest(player, "Q_Millhaven_WolfThreat")
	print(("  📊 AcceptQuest('WolfThreat'): %s"):format(tostring(q5.success)))
	assert_true("WolfThreat accepted (prereq met)", q5.success)

	-- 6h. Accept quest yang butuh level lebih tinggi
	local q6 = QuestService:AcceptQuest(player, "Q_OpenGate_Duskwood")
	print(("  📊 AcceptQuest('OpenGate_Duskwood') Lv%d: %s (%s)"):format(
		data.Level, tostring(q6.success), tostring(q6.reason or "OK")))
	-- Note: OpenGate_Duskwood butuh WolfThreat selesai — belum, jadi tolak
	assert_true("OpenGate_Duskwood ditolak (prereq WolfThreat belum selesai)", not q6.success)

	-- 6i. Complete WolfThreat (kill 5 wolves)
	for i = 1, 5 do
		QuestService:ReportProgress(player, "Enemy_Wolf", 1)
	end
	local q7 = QuestService:CompleteQuest(player, "Q_Millhaven_WolfThreat")
	print(("  📊 CompleteQuest('WolfThreat'): %s, exp=%d, soft=%d"):format(
		tostring(q7.success), q7.rewards and q7.rewards.exp or 0, q7.rewards and q7.rewards.softCurrency or 0))
	assert_true("WolfThreat completed", q7.success)

	-- 6j. Sekarang baru bisa accept OpenGate_Duskwood
	local q6b = QuestService:AcceptQuest(player, "Q_OpenGate_Duskwood")
	print(("  📊 AcceptQuest('OpenGate_Duskwood') setelah WolfThreat: %s"):format(tostring(q6b.success)))
	assert_true("OpenGate_Duskwood accepted (prereq met)", q6b.success)

	-- 6j. GetAvailableQuests
	local avail = QuestService:GetAvailableQuests(player)
	print(("  📊 Available quests: %d"):format(avail.available and #avail.available or 0))
	assert_true("Has available quests", avail.success and #avail.available > 0)

	-- 6k. Daily quest (repeatable)
	local q8 = QuestService:AcceptQuest(player, "Q_Daily_WolfHunt")
	print(("  📊 AcceptQuest('Daily_WolfHunt'): %s"):format(tostring(q8.success)))
	assert_true("Daily accepted", q8.success)
	for i = 1, 10 do QuestService:ReportProgress(player, "Enemy_Wolf", 1) end
	local q9 = QuestService:CompleteQuest(player, "Q_Daily_WolfHunt")
	print(("  📊 CompleteQuest('Daily'): %s, exp=%d"):format(
		tostring(q9.success), q9.rewards and q9.rewards.exp or 0))
	assert_true("Daily completed", q9.success)

	print(("  📊 FINAL: Lv%d, CompletedQuests=%d"):format(
		data.Level, (function() local c = 0; for _ in pairs(data.CompletedQuests or {}) do c += 1 end; return c end)()))

	-- ========================================
	-- BAGIAN 7: CombatService
	-- ========================================
	section("BAGIAN 7: CombatService")

	local CombatService = require(ServerScriptService.Services.CombatService)
	local DamageFormula = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamageFormula"))

	-- 7a. Test DamageFormula (pure function)
	local testResult = DamageFormula.Calculate(
		{ STR = 20, INT = 10, LUK = 10, Level = 10 },
		{ baseDamage = 15, damageType = "Physical", element = nil },
		{ defense = 10, element = nil },
		1.0
	)
	print(("  📊 DamageFormula(STR=20, base=15, def=10): dmg=%d, crit=%s"):format(
		testResult.damage, tostring(testResult.isCrit)))
	assert_true("Damage > 0", testResult.damage > 0)

	-- 7b. Element multiplier test
	local fireVsWind = DamageFormula.CalcElementMultiplier("Fire", "Wind")
	local fireVsWater = DamageFormula.CalcElementMultiplier("Fire", "Water")
	print(("  📊 Fire→Wind: %.1fx, Fire→Water: %.1fx"):format(fireVsWind, fireVsWater))
	assert_eq("Fire strong vs Wind", fireVsWind, 1.5)
	assert_eq("Fire weak vs Water", fireVsWater, 0.5)

	-- 7c. Defense reduction test
	local defReduction = DamageFormula.CalcDefenseReduction(100)
	print(("  📊 Defense 100 → reduction: %.2f"):format(defReduction))
	assert_eq("100 def = 50% reduction", defReduction, 0.5)

	-- 7d. Spawn enemy
	local wolfId = CombatService:SpawnEnemy("Enemy_Wolf")
	print(("  📊 SpawnEnemy('Enemy_Wolf'): id=%s"):format(wolfId))
	assert_true("Wolf spawned", wolfId ~= "")

	local wolfStatus = CombatService:GetEnemyStatus(wolfId)
	print(("  📊 Wolf HP: %d/%d, alive=%s"):format(
		wolfStatus.currentHP, wolfStatus.maxHP, tostring(wolfStatus.alive)))
	assert_eq("Wolf HP = 40", wolfStatus.currentHP, 40)

	-- 7e. Setup player untuk combat
	DataService.ResetToTemplate(player)
	task.wait(0.2)
	CharService2.RerollRace(player)
	CharService2.ConfirmRace(player, "Human")
	CharService2.SelectClass(player, "Warrior")
	LevelService:AddExp(player, 1000) -- Lv~7
	CombatService:SetPlayerMana(player, 100)
	data = DataService.GetProfile(player)
	print(("  📊 Combat setup: %s %s Lv%d, STR=%d"):format(
		data.RaceId, data.ClassId, data.Level, data.Stats.STR))

	-- 7f. Attack wolf dengan SlashCombo
	local atk1ok, atk1 = pcall(function()
		return CombatService:ProcessAttack(player, wolfId, "SlashCombo")
	end)
	if not atk1ok then warn("  ❌ ProcessAttack error:", atk1) end
	if not atk1 then atk1 = { success = false, reason = "nil result" } end
	print(("  📊 SlashCombo → dmg=%d, crit=%s, enemyHP=%d, killed=%s"):format(
		atk1.damage or 0, tostring(atk1.isCrit), atk1.enemyHP or 0, tostring(atk1.killed)))
	assert_true("SlashCombo sukses", atk1.success)

	-- 7g. Skill tidak valid
	local atk2 = CombatService:ProcessAttack(player, wolfId, "FakeSkill")
	print(("  📊 FakeSkill: %s (%s)"):format(tostring(atk2.success), tostring(atk2.reason)))
	assert_true("FakeSkill ditolak", not atk2.success)

	-- 7h. Wolf one-shot! (dmg=54 > HP=40)
	if atk1.killed then
		print("  📊 Wolf one-shot! (dmg > 40 HP)")
	else
		for i = 1, 20 do
			local r = CombatService:ProcessAttack(player, wolfId, "SlashCombo")
			if r.killed then atk1 = r; break end
		end
	end
	assert_true("Wolf mati", atk1.killed)
	print(("  📊 Wolf killed! exp=%d, currency=%d"):format(
		atk1.expReward or 0, atk1.currencyReward or 0))

	-- 7i. Dead wolf → tolak
	local atkDead = CombatService:ProcessAttack(player, wolfId, "SlashCombo")
	print(("  📊 Serang wolf mati: %s (%s)"):format(tostring(atkDead.success), tostring(atkDead.reason)))
	assert_true("Dead wolf → tolak", not atkDead.success)

	-- 7j. GetAvailableSkills
	local skills = CombatService:GetAvailableSkills(player)
	print(("  📊 Available skills (Warrior Lv%d): %d"):format(
		data.Level, skills.skills and #skills.skills or 0))
	assert_true("Has skills", skills.success and #skills.skills > 0)
	local hasSlash = false
	for _, s in ipairs(skills.skills) do
		if s.id == "SlashCombo" then hasSlash = true end
	end
	assert_true("Has SlashCombo", hasSlash)

	-- 7k. Mana test — tunggu cooldown expired, pakai GateGuardian (200 HP)
	task.wait(2)
	CombatService:SetPlayerMana(player, 30)
	local guardianId = CombatService:SpawnEnemy("Enemy_GateGuardian")
	-- WarCry cost 15, SlashCombo cost 5. Total 20 < 30 → OK
	local atkWC = CombatService:ProcessAttack(player, guardianId, "WarCry")
	print(("  📊 WarCry (30 mana, cost 15): %s, reason=%s"):format(
		tostring(atkWC.success), tostring(atkWC.reason or "none")))
	assert_true("WarCry OK", atkWC.success)

	local atkSC = CombatService:ProcessAttack(player, guardianId, "SlashCombo")
	print(("  📊 SlashCombo (15 mana, cost 5): %s, reason=%s"):format(
		tostring(atkSC.success), tostring(atkSC.reason or "none")))
	assert_true("SlashCombo OK", atkSC.success)

	-- Mana = 10, WarCry cost 15 → gagal
	local atkNoMana = CombatService:ProcessAttack(player, guardianId, "WarCry")
	print(("  📊 WarCry (10 mana, cost 15): %s (%s)"):format(
		tostring(atkNoMana.success), tostring(atkNoMana.reason)))
	assert_true("WarCry ditolak (mana kurang)", not atkNoMana.success)

	-- 7l. Respawn enemy
	CombatService:ResetEnemy(wolfId)
	local wolfReset = CombatService:GetEnemyStatus(wolfId)
	print(("  📊 Wolf respawn: HP=%d/%d, alive=%s"):format(
		wolfReset.currentHP, wolfReset.maxHP, tostring(wolfReset.alive)))
	assert_true("Wolf respawned", wolfReset.alive and wolfReset.currentHP == 40)

	print(("  📊 FINAL: Combat test complete, STR=%d, Level=%d"):format(
		data.Stats.STR, data.Level))

	-- ========================================
	-- BAGIAN 8: InventoryService
	-- ========================================
	section("BAGIAN 8: InventoryService")

	local InventoryService = require(ServerScriptService.Services.InventoryService)

	-- Reset + setup
	DataService.ResetToTemplate(player)
	task.wait(0.2)
	CharService2.RerollRace(player)
	CharService2.ConfirmRace(player, "Human")
	CharService2.SelectClass(player, "Warrior")
	LevelService:AddExp(player, 2000) -- Lv~12
	data = DataService.GetProfile(player)
	print(("  📊 Setup: Lv%d, STR=%d"):format(data.Level, data.Stats.STR))

	-- 8a. Add item
	local add1 = InventoryService:AddItem(player, "IronSword", 1)
	print(("  📊 AddItem('IronSword'): %s"):format(tostring(add1.success)))
	assert_true("IronSword added", add1.success)

	local add2 = InventoryService:AddItem(player, "HealthPotion", 5)
	print(("  📊 AddItem('HealthPotion', 5): %s"):format(tostring(add2.success)))
	assert_true("HealthPotion x5 added", add2.success)

	local add3 = InventoryService:AddItem(player, "Moonpetal", 3)
	print(("  📊 AddItem('Moonpetal', 3): %s"):format(tostring(add3.success)))
	assert_true("Moonpetal x3 added", add3.success)

	-- 8b. GetInventory
	local inv1 = InventoryService:GetInventory(player)
	print(("  📊 Inventory: %d items"):format(inv1.inventory and #inv1.inventory or 0))
	assert_eq("3 item types", #inv1.inventory, 3)

	-- 8c. Equip item (IronSword di index 1)
	local eq1 = InventoryService:EquipItem(player, 1)
	print(("  📊 EquipItem(1): %s, slot=%s, item=%s"):format(
		tostring(eq1.success), tostring(eq1.slot), tostring(eq1.itemId)))
	assert_true("IronSword equipped", eq1.success)
	assert_eq("Slot = Weapon", eq1.slot, "Weapon")

	-- 8d. GetEquipment
	local equip1 = InventoryService:GetEquipment(player)
	print(("  📊 Equipment[Weapon]: %s"):format(
		tostring(equip1.equipment and equip1.equipment.Weapon and equip1.equipment.Weapon.itemId)))
	assert_true("Weapon equipped", equip1.equipment and equip1.equipment.Weapon ~= nil)

	-- 8e. Equipment stats
	local eqStats = InventoryService:GetEquipmentStats(player)
	print(("  📊 Equipment STR bonus: %d"):format(eqStats.STR or 0))
	assert_eq("STR +5 from IronSword", eqStats.STR, 5)

	-- 8f. Unequip item
	local ueq1 = InventoryService:UnequipItem(player, "Weapon")
	print(("  📊 UnequipItem('Weapon'): %s"):format(tostring(ueq1.success)))
	assert_true("Weapon unequipped", ueq1.success)

	local equip2 = InventoryService:GetEquipment(player)
	assert_true("Weapon slot nil", equip2.equipment.Weapon == nil)

	-- 8g. Re-equip (IronSword sekarang di index terakhir karena unequip masuk ke inventory)
	local inv2 = InventoryService:GetInventory(player)
	local ironIdx = nil
	for i, entry in ipairs(inv2.inventory) do
		if entry.itemId == "IronSword" then ironIdx = i; break end
	end
	print(("  📊 IronSword di index: %s"):format(tostring(ironIdx)))
	assert_true("IronSword found in inventory", ironIdx ~= nil)

	local eq2 = InventoryService:EquipItem(player, ironIdx)
	assert_true("Re-equip IronSword", eq2.success)

	-- 8h. Use consumable (HealthPotion)
	local inv3 = InventoryService:GetInventory(player)
	local potionIdx = nil
	for i, entry in ipairs(inv3.inventory) do
		if entry.itemId == "HealthPotion" then potionIdx = i; break end
	end
	print(("  📊 HealthPotion di index: %s"):format(tostring(potionIdx)))
	assert_true("Potion found", potionIdx ~= nil)

	local use1 = InventoryService:UseItem(player, potionIdx)
	print(("  📊 UseItem('HealthPotion'): %s, effects=%s"):format(
		tostring(use1.success), tostring(use1.effects and table.concat(use1.effects, ", "))))
	assert_true("Potion used", use1.success)

	-- Quantity berkurang
	local inv4 = InventoryService:GetInventory(player)
	local potionEntry = nil
	for _, entry in ipairs(inv4.inventory) do
		if entry.itemId == "HealthPotion" then potionEntry = entry; break end
	end
	print(("  📊 Potion remaining: %d"):format(potionEntry and potionEntry.quantity or 0))
	assert_eq("Potion qty = 4", potionEntry and potionEntry.quantity, 4)

	-- 8i. Remove item
	local rm1 = InventoryService:RemoveItem(player, "Moonpetal", 2)
	print(("  📊 RemoveItem('Moonpetal', 2): %s"):format(tostring(rm1.success)))
	assert_true("Moonpetal removed x2", rm1.success)

	local inv5 = InventoryService:GetInventory(player)
	local moonEntry = nil
	for _, entry in ipairs(inv5.inventory) do
		if entry.itemId == "Moonpetal" then moonEntry = entry; break end
	end
	print(("  📊 Moonpetal remaining: %d"):format(moonEntry and moonEntry.quantity or 0))
	assert_eq("Moonpetal qty = 1", moonEntry and moonEntry.quantity, 1)

	-- 8j. Item tidak valid
	local bad1 = InventoryService:AddItem(player, "FakeItem", 1)
	print(("  📊 AddItem('FakeItem'): %s (%s)"):format(tostring(bad1.success), tostring(bad1.reason)))
	assert_true("FakeItem ditolak", not bad1.success)

	-- 8k. HasItem check
	local has1 = InventoryService:HasItem(player, "HealthPotion", 1)
	local has2 = InventoryService:HasItem(player, "HealthPotion", 99)
	print(("  📊 HasItem('Potion', 1): %s, HasItem('Potion', 99): %s"):format(
		tostring(has1), tostring(has2)))
	assert_true("Has 1 potion", has1)
	assert_true("Not has 99 potion", not has2)

	print(("  📊 FINAL: Inventory test complete, Lv%d"):format(data.Level))

	-- ========================================
	-- BAGIAN 9: PartyService
	-- ========================================
	section("BAGIAN 9: PartyService")

	local PartyService = require(ServerScriptService.Services.PartyService)

	-- Reset + setup
	DataService.ResetToTemplate(player)
	task.wait(0.2)
	CharService2.RerollRace(player)
	CharService2.ConfirmRace(player, "Human")
	CharService2.SelectClass(player, "Warrior")
	data = DataService.GetProfile(player)

	-- 9a. GetPartyInfo (belum di party)
	local p1 = PartyService:GetPartyInfo(player)
	print(("  📊 GetPartyInfo (no party): inParty=%s"):format(tostring(p1.inParty)))
	assert_true("Belum di party", not p1.inParty)

	-- 9b. LeaveParty (belum di party)
	local p2 = PartyService:LeaveParty(player)
	print(("  📊 LeaveParty (no party): %s (%s)"):format(tostring(p2.success), tostring(p2.reason)))
	assert_true("Leave tanpa party → tolak", not p2.success)

	-- 9c. CreateParty
	local p3 = PartyService:CreateParty(player)
	print(("  📊 CreateParty: %s, partyId=%s, role=%s"):format(
		tostring(p3.success), tostring(p3.partyId):sub(1, 8), tostring(p3.role)))
	assert_true("Party created", p3.success)
	assert_eq("Role = Leader", p3.role, "Leader")

	-- 9d. CreateParty lagi (sudah di party)
	local p4 = PartyService:CreateParty(player)
	print(("  📊 CreateParty lagi: %s (%s)"):format(tostring(p4.success), tostring(p4.reason)))
	assert_true("Sudah di party → tolak", not p4.success)

	-- 9e. GetPartyInfo (sudah di party)
	local p5 = PartyService:GetPartyInfo(player)
	print(("  📊 GetPartyInfo: inParty=%s, members=%d, leader=%s"):format(
		tostring(p5.inParty), p5.memberCount or 0, tostring(p5.leaderId == player.UserId)))
	assert_true("In party", p5.inParty)
	assert_eq("1 member", p5.memberCount, 1)
	assert_true("Is leader", p5.leaderId == player.UserId)

	-- 9f. Kick diri sendiri → tolak
	local p6 = PartyService:KickPlayer(player, player.UserId)
	print(("  📊 Kick self: %s (%s)"):format(tostring(p6.success), tostring(p6.reason)))
	assert_true("Kick self → tolak", not p6.success)

	-- 9g. LeaveParty
	local p7 = PartyService:LeaveParty(player)
	print(("  📊 LeaveParty: %s"):format(tostring(p7.success)))
	assert_true("Left party", p7.success)

	-- 9h. Cek PartyId di profile
	data = DataService.GetProfile(player)
	print(("  📊 Profile.PartyId after leave: %s"):format(tostring(data.PartyId)))
	assert_true("PartyId nil", data.PartyId == nil)

	-- 9i. Create party lagi untuk test invite (butuh 2nd player — skip)
	-- Di production, test dengan 2 player. Untuk sekarang, test internal logic.
	local p8 = PartyService:CreateParty(player)
	assert_true("Party re-created", p8.success)

	print(("  📊 FINAL: Party test complete"))

	-- ========================================
	-- BAGIAN 10: DungeonService
	-- ========================================
	section("BAGIAN 10: DungeonService")

	local DungeonService = require(ServerScriptService.Services.DungeonService)

	-- Setup: Buat character
	DataService.ResetToTemplate(player)
	task.wait(0.2)
	CharService2.RerollRace(player)
	CharService2.ConfirmRace(player, "Human")
	CharService2.SelectClass(player, "Warrior")
	data = DataService.GetProfile(player)

	-- 10a. EnterDungeon invalid dungeonId → tolak
	local d1 = DungeonService:EnterDungeon(player, "Dungeon_Fake")
	print(("  📊 EnterDungeon (invalid): %s (%s)"):format(tostring(d1.success), tostring(d1.reason)))
	assert_true("Invalid dungeon → tolak", not d1.success)

	-- 10b. Create party
	PartyService:CreateParty(player)
	task.wait(0.1)

	-- 10c. EnterDungeon level kurang (Dungeon_SunkenCrypt butuh Lv25)
	local d2 = DungeonService:EnterDungeon(player, "Dungeon_SunkenCrypt")
	print(("  📊 EnterDungeon Lv10 (need 25): %s (%s)"):format(tostring(d2.success), tostring(d2.reason)))
	assert_true("Level kurang → tolak", not d2.success)

	-- 10d. EnterDungeon solo-friendly (CorruptedGrove butuh Lv15, partySize 1)
	-- Tapi kita level 10... masih kurang
	local d3 = DungeonService:EnterDungeon(player, "Dungeon_CorruptedGrove")
	print(("  📊 EnterDungeon Lv10 (need 15): %s (%s)"):format(tostring(d3.success), tostring(d3.reason)))
	assert_true("Level kurang → tolak", not d3.success)

	-- 10e. Level up ke Lv15 untuk CorruptedGrove
	for i = 1, 15 do
		LevelService:AddExp(player, LevelCurveConfig.CalculateRequiredExp(i))
	end
	task.wait(0.1)
	data = DataService.GetProfile(player)
	print(("  📊 Level upped to: %d"):format(data.Level))

	-- 10f. EnterDungeon CorruptedGrove (Lv15, partySize 1)
	local d4 = DungeonService:EnterDungeon(player, "Dungeon_CorruptedGrove")
	print(("  📊 EnterDungeon CorruptedGrove: %s, wave=%d/%d, name=%s"):format(
		tostring(d4.success), d4.wave or 0, d4.totalWaves or 0, tostring(d4.dungeonName)))
	assert_true("Dungeon entered", d4.success)
	assert_eq("Wave 1", d4.wave, 1)

	-- 10g. GetStatus
	local d5 = DungeonService:GetStatus(player)
	print(("  📊 GetStatus: inDungeon=%s, wave=%d, status=%s, aliveEnemies=%d"):format(
		tostring(d5.inDungeon), d5.wave or 0, tostring(d5.status), d5.aliveEnemies or 0))
	assert_true("In dungeon", d5.inDungeon)
	assert_eq("Wave 1", d5.wave, 1)
	assert_eq("Status active", d5.status, "active")

	-- 10h. DungeonId di profile
	data = DataService.GetProfile(player)
	print(("  📊 Profile.DungeonId: %s"):format(tostring(data.DungeonId)))
	assert_true("DungeonId set", data.DungeonId ~= nil)

	-- 10i. EnterDungeon lagi (sudah di dungeon) → tolak
	local d6 = DungeonService:EnterDungeon(player, "Dungeon_CorruptedGrove")
	print(("  📊 EnterDungeon lagi: %s (%s)"):format(tostring(d6.success), tostring(d6.reason)))
	assert_true("Sudah di dungeon → tolak", not d6.success)

	-- 10j. ForceLeave
	DungeonService:ForceLeave(player)
	task.wait(0.1)
	data = DataService.GetProfile(player)
	print(("  📊 ForceLeave → DungeonId: %s"):format(tostring(data.DungeonId)))
	assert_true("DungeonId cleared", data.DungeonId == nil)

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

	-- 4b. Gate_Duskwood (LevelAndQuest: Lv10 + quest)
	-- Level sudah cukup, tapi quest belum → ditolak dulu
	local g2 = GateService.TryOpenGate(player, "Gate_Duskwood")
	print(("  📊 TryOpenGate('Gate_Duskwood') tanpa quest: %s (%s)"):format(
		tostring(g2.success), tostring(g2.reason)))
	assert_true("Duskwood ditolak (no quest)", not g2.success)

	-- 4c. Tambah quest ke CompletedQuests, coba lagi
	if not data.CompletedQuests then data.CompletedQuests = {} end
	data.CompletedQuests["Q_OpenGate_Duskwood"] = true
	local g3 = GateService.TryOpenGate(player, "Gate_Duskwood")
	print(("  📊 TryOpenGate('Gate_Duskwood') + quest: %s, dest=%s"):format(
		tostring(g3.success), tostring(g3.destination)))
	assert_true("Duskwood sukses", g3.success)
	assert_eq("Dest = DuskwoodForest", g3.destination, "DuskwoodForest")

	-- 4d. Gate sudah terbuka (idempotent)
	local g4 = GateService.TryOpenGate(player, "Gate_Duskwood")
	print(("  📊 TryOpenGate lagi: %s, alreadyUnlocked=%s"):format(
		tostring(g4.success), tostring(g4.alreadyUnlocked)))
	assert_true("Already unlocked", g4.alreadyUnlocked)

	-- 4e. Gate_Frostpeak (LevelAndQuest: Lv25 + quest) — quest belum
	local g5 = GateService.TryOpenGate(player, "Gate_Frostpeak")
	print(("  📊 TryOpenGate('Gate_Frostpeak'): %s (%s)"):format(
		tostring(g5.success), tostring(g5.reason)))
	assert_true("Frostpeak ditolak (no quest)", not g5.success)

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
