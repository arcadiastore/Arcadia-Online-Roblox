--[[
	ProfileTemplate.lua
	Nilai default untuk Player Profile BARU (pemain yang belum pernah punya
	data). Sumber kebenaran struktur skema ada di docs/03_DDD.md §4. Ini
	dipakai oleh ProfileStore (ServerStorage/Private/ProfileStore.lua) lewat
	DataService — jangan hardcode default profile di Service manapun.

	SchemaVersion = 2 (skema §4 versi sekarang, sudah termasuk ProfessionId/
	ProfessionExp dari desain Craftsman). Field baru wajib naik SchemaVersion
	+ migrasi resmi (docs/03_DDD.md §5) begitu ada data pemain di production,
	JANGAN edit langsung field di sini tanpa itu.

	RaceId/ClassId sengaja nil (bukan "Human"/"Warrior") — ini SchemaVersion
	baseline untuk pemain yang BELUM menyelesaikan character creation
	(sistem itu sendiri masih ⬜ di progress tracker). Kalau desainnya
	ternyata "semua pemain baru otomatis Human/Warrior tanpa character
	creation", ini perlu dikoreksi eksplisit oleh pemilik project — dicatat
	sebagai asumsi di 05_PROGRESS_TRACKER.md sesi ini.
]]

return {
	SchemaVersion = 2,
	Level = 1,
	Exp = 0,
	RaceId = nil,
	ClassId = nil,
	ClassTier = 1,
	ProfessionId = nil,
	ProfessionExp = 0,
	Stats = { STR = 5, VIT = 5, INT = 5, AGI = 5, LUK = 5 },
	UnspentCombatPoints = 0,
	Currency = { Soft = 0, Premium = 0 },
	Inventory = {},
	Equipment = {},
	QuestLog = {},
	CompletedQuests = {}, -- [questId] = true — dipakai GateService cek syarat gate
	PartyId = nil,
	UnlockedGates = {},
	Achievements = {},
	Settings = {},
}
