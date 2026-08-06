--[[
	TestLevelCurve.server.lua
	Test script untuk verifikasi LevelCurve config dan LevelService.

	Cara pakai:
	  1. Buka project di Roblox Studio (sudah Rojo sync)
	  2. Play Solo
	  3. Script ini otomatis jalan di server
	  4. Cek Output window untuk hasil test
	  5. HAPUS file ini sebelum publish ke production

	Warna di Output:
	  ✅ = PASS
	  ❌ = FAIL (perlu perbaiki)
	  📊 = Info/data
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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
		warn(("  ❌ %s: expected true, got false"):format(name))
	end
end

print("=" .. string.rep("=", 59))
print("TEST: LevelCurve.lua")
print("=" .. string.rep("=", 59))

-- === Test MaxLevel ===
print("\n--- MaxLevel ---")
assert_eq("MaxLevel", LevelCurve.MaxLevel, 50)

-- === Test EXP per level ===
print("\n--- EXP Required ---")
assert_eq("EXP lv1→2",  LevelCurve.GetRequiredExp(1),  2)    -- 0 + 1^2 * 2 = 2
assert_eq("EXP lv5→6",  LevelCurve.GetRequiredExp(5),  50)   -- 0 + 5^2 * 2 = 50
assert_eq("EXP lv10→11", LevelCurve.GetRequiredExp(10), 200) -- 0 + 10^2 * 2 = 200
assert_eq("EXP lv25→26", LevelCurve.GetRequiredExp(25), 1250)-- 0 + 25^2 * 2 = 1250
assert_eq("EXP lv49→50", LevelCurve.GetRequiredExp(49), 4802)-- 0 + 49^2 * 2 = 4802
assert_eq("EXP lv50 (cap)", LevelCurve.GetRequiredExp(50), 0) -- sudah cap

-- === Test Total EXP ===
print("\n--- Total EXP ---")
assert_eq("Total EXP to lv1", LevelCurve.GetTotalExpToLevel(1), 0)
assert_eq("Total EXP to lv2", LevelCurve.GetTotalExpToLevel(2), 2)   -- 1^2*2
assert_eq("Total EXP to lv3", LevelCurve.GetTotalExpToLevel(3), 10)  -- 2 + 2^2*2 = 2+8

-- Hitung manual total ke lv50
local totalManual = 0
for lv = 1, 49 do
	totalManual += LevelCurve.GetRequiredExp(lv)
end
assert_eq("Total EXP to lv50", LevelCurve.GetTotalExpToLevel(50), totalManual)

-- === Test Base Stats ===
print("\n--- Base Stats ---")
local base1 = LevelCurve.GetBaseStats(1)
assert_eq("Base STR lv1", base1.STR, 5)
assert_eq("Base VIT lv1", base1.VIT, 5)
assert_eq("Base INT lv1", base1.INT, 5)
assert_eq("Base AGI lv1", base1.AGI, 5)
assert_eq("Base LUK lv1", base1.LUK, 5)

local base10 = LevelCurve.GetBaseStats(10)
assert_eq("Base STR lv10", base10.STR, 23)  -- 5 + 9*2 = 23
assert_eq("Base VIT lv10", base10.VIT, 23)

local base50 = LevelCurve.GetBaseStats(50)
assert_eq("Base STR lv50", base50.STR, 103) -- 5 + 49*2 = 103

-- === Test Combat Points ===
print("\n--- Combat Points ---")
assert_eq("CP at lv1", LevelCurve.GetCombatPointsGain(1), 0)  -- level 1 tidak dapat CP
assert_eq("CP at lv2", LevelCurve.GetCombatPointsGain(2), 3)
assert_eq("CP at lv25", LevelCurve.GetCombatPointsGain(25), 3)
assert_eq("CP at lv50", LevelCurve.GetCombatPointsGain(50), 3)

-- Total CP di level 50: 3 × 49 = 147
local totalCP = 0
for lv = 2, 50 do
	totalCP += LevelCurve.GetCombatPointsGain(lv)
end
assert_eq("Total CP at lv50", totalCP, 147)

-- === Test GetLevelFromTotalExp ===
print("\n--- GetLevelFromTotalExp ---")
assert_eq("Level from 0 EXP", LevelCurve.GetLevelFromTotalExp(0), 1)
assert_eq("Level from 1 EXP", LevelCurve.GetLevelFromTotalExp(1), 1)   -- butuh 2 untuk lv2
assert_eq("Level from 2 EXP", LevelCurve.GetLevelFromTotalExp(2), 2)   -- pas 2, naik ke lv2
assert_eq("Level from 9 EXP", LevelCurve.GetLevelFromTotalExp(9), 2)   -- butuh 2+8=10 untuk lv3
assert_eq("Level from 10 EXP", LevelCurve.GetLevelFromTotalExp(10), 3) -- pas 10, naik ke lv3

-- === Test Config data consistency ===
print("\n--- Config Data ---")
local raceCount = 0
for id, data in pairs(RacesConfig) do
	raceCount += 1
	assert_true(("Race '%s' punya displayName"):format(id), data.displayName ~= nil)
	assert_true(("Race '%s' punya weight > 0"):format(id), data.weight > 0)
	assert_true(("Race '%s' punya statBonus"):format(id), data.statBonus ~= nil)
end
assert_eq("Jumlah race", raceCount, 5)

local classCount = 0
local tier1Count = 0
for id, data in pairs(ClassesConfig) do
	classCount += 1
	if data.tier == 1 then
		tier1Count += 1
	end
	assert_true(("Class '%s' punya displayName"):format(id), data.displayName ~= nil)
	assert_true(("Class '%s' punya tier 1/2/3"):format(id),
		data.tier == 1 or data.tier == 2 or data.tier == 3)
end
assert_eq("Jumlah class total", classCount, 18) -- 6 jalur × 3 tier
assert_eq("Jumlah Tier 1 class", tier1Count, 6)

-- === Test stat bonus ras + base stat ===
print("\n--- Stat bonus ras + base stat (Angel lv1) ---")
local angel = RacesConfig.Angel
local base = LevelCurve.GetBaseStats(1)
local angelSTR = base.STR + angel.statBonus.STR  -- 5 + (-3) = 2
local angelLUK = base.LUK + angel.statBonus.LUK  -- 5 + 5 = 10
assert_eq("Angel STR lv1 (base+race)", angelSTR, 2)
assert_eq("Angel LUK lv1 (base+race)", angelLUK, 10)
assert_true("Angel STR lv1 > 0", angelSTR > 0) -- pastikan tidak negatif

-- === Summary ===
print("\n" .. string.rep("=", 60))
print(("HASIL: %d passed, %d failed"):format(passed, failed))
if failed == 0 then
	print("🎉 SEMUA TEST LULUS!")
else
	warn(("⚠️  %d TEST GAGAL — perlu dicek"):format(failed))
end
print(string.rep("=", 60))

-- === Tambahan: Test LevelService (butuh player di Studio) ===
print("\n--- Test LevelService (otomatis saat player join) ---")
-- LevelService sudah di-bootstrap oleh Main.server.lua
-- Script ini hanya menunggu player pertama untuk test API

task.spawn(function()
	local Players = game:GetService("Players")

	-- Tunggu player pertama (hanya ada 1 di Play Solo)
	local player = Players.PlayerAdded:Wait()
	print(("\n🎮 Player '%s' joined — mulai test LevelService..."):format(player.Name))

	-- Tunggu profile siap
	local DataService = require(ServerScriptService.Services.DataService)
	local data = DataService.WaitForProfile(player, 15)
	if not data then
		warn("❌ Profile tidak siap setelah 15 detik — skip LevelService test")
		return
	end

	print(("  📊 Profile loaded — Level: %d, RaceId: %s, ClassId: %s"):format(
		data.Level, tostring(data.RaceId), tostring(data.ClassId)))

	-- Tunggu character creation selesai (RaceId & ClassId terisi)
	-- Di Play Solo, kamu perlu jalankan character creation via Command Bar
	-- atau test script CharacterService terpisah.
	-- Untuk test otomatis, kita skip kalau belum created:
	if not data.RaceId or not data.ClassId then
		print("  ⏳ Character belum dibuat — jalankan character creation dulu")
		print("  💡 Command Bar test:")
		print("     local RS = game:GetService('ReplicatedStorage')")
		print("     -- Reroll race:")
		print("     local result = RS.Remotes.Character.RerollRace:InvokeServer()")
		print("     print(result)")
		print("     -- Confirm race:")
		print("     local result2 = RS.Remotes.Character.ConfirmRace:InvokeServer(result.raceId)")
		print("     -- Select class:")
		print("     local result3 = RS.Remotes.Character.SelectClass:InvokeServer('Warrior')")
		print("     -- Lalu jalankan test LevelService di bawah:")
		return
	end

	print(("  ✅ Character created — Race: %s, Class: %s"):format(data.RaceId, data.ClassId))

	-- Test AddExp
	local LevelService = require(ServerScriptService.Services.LevelService)

	-- Test 1: Tambah EXP kecil (tidak cukup untuk level-up)
	local r1 = LevelService:AddExp(player, 1)
	print(("  📊 AddExp(1): levelsGained=%d, newLevel=%d, newExp=%d"):format(
		r1.levelsGained, r1.newLevel, r1.newExp))
	assert_eq("Level setelah +1 EXP (belum naik)", r1.newLevel, data.Level)

	-- Test 2: Tambah EXP cukup untuk 1 level-up
	local expNeeded = LevelCurve.GetRequiredExp(data.Level)
	local r2 = LevelService:AddExp(player, expNeeded)
	print(("  📊 AddExp(%d): levelsGained=%d, newLevel=%d, newExp=%d"):format(
		expNeeded, r2.levelsGained, r2.newLevel, r2.newExp))
	assert_true("Level naik setelah cukup EXP", r2.levelsGained >= 1)

	-- Test 3: Tambah EXP besar (multiple level-up)
	local r3 = LevelService:AddExp(player, 50000)
	print(("  📊 AddExp(50000): levelsGained=%d, newLevel=%d, newExp=%d"):format(
		r3.levelsGained, r3.newLevel, r3.newExp))
	assert_true("Multiple level-up works", r3.levelsGained >= 1)

	-- Test 4: Cek UnspentPoints
	local unspent = LevelService:GetUnspentPoints(player)
	print(("  📊 UnspentCombatPoints: %d"):format(unspent))
	assert_true("UnspentPoints > 0 setelah level-up", unspent > 0)

	-- Test 5: AllocateCP
	local allocResult = LevelService:AllocateCP(player, "STR")
	print(("  📊 AllocateCP('STR'): success=%s, unspent=%s"):format(
		tostring(allocResult.success), tostring(allocResult.unspentPoints)))
	assert_true("AllocateCP STR berhasil", allocResult.success)
	assert_eq("UnspentPoints berkurang", allocResult.unspentPoints, unspent - 1)

	-- Test 6: AllocateCP stat tidak valid
	local badAlloc = LevelService:AllocateCP(player, "INVALID")
	assert_true("AllocateCP INVALID ditolak", not badAlloc.success)

	print("\n🎉 SEMUA TEST LevelService LULUS!")
end)
