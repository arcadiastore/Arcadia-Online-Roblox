--[[
	Enemies.lua
	Definisi musuh — HP, stat, elemen, drop table, zona.
	Lihat docs/01_GDD.md §10, docs/03_DDD.md §3.

	dropTableId → referensi ke LootTable (belum diimplementasi)
]]

return {
	-- === Millhaven (starter zone, Lv 1–10) ===
	Enemy_Wolf = {
		id = "Enemy_Wolf",
		displayName = "Wolf",
		level = 2,
		zone = "Millhaven",
		element = nil,
		stats = { HP = 40, STR = 5, VIT = 3, INT = 0, AGI = 8, LUK = 2 },
		defense = 2,
		expReward = 15,
		softCurrencyReward = 5,
		dropTableId = "Loot_Wolf",
	},

	Enemy_Slime = {
		id = "Enemy_Slime",
		displayName = "Slime",
		level = 1,
		zone = "Millhaven",
		element = "Water",
		stats = { HP = 25, STR = 3, VIT = 5, INT = 0, AGI = 2, LUK = 1 },
		defense = 1,
		expReward = 10,
		softCurrencyReward = 3,
		dropTableId = "Loot_Slime",
	},

	Enemy_Goblin = {
		id = "Enemy_Goblin",
		displayName = "Goblin",
		level = 4,
		zone = "Millhaven",
		element = nil,
		stats = { HP = 60, STR = 8, VIT = 4, INT = 2, AGI = 6, LUK = 3 },
		defense = 4,
		expReward = 25,
		softCurrencyReward = 10,
		dropTableId = "Loot_Goblin",
	},

	Enemy_GateGuardian = {
		id = "Enemy_GateGuardian",
		displayName = "Gate Guardian",
		level = 8,
		zone = "Millhaven",
		element = "Earth",
		stats = { HP = 200, STR = 18, VIT = 15, INT = 5, AGI = 8, LUK = 5 },
		defense = 12,
		expReward = 100,
		softCurrencyReward = 30,
		dropTableId = "Loot_GateGuardian",
	},

	Enemy_TrialChampion = {
		id = "Enemy_TrialChampion",
		displayName = "Trial Champion",
		level = 15,
		zone = "Millhaven",
		element = nil,
		stats = { HP = 500, STR = 30, VIT = 25, INT = 10, AGI = 15, LUK = 10 },
		defense = 20,
		expReward = 200,
		softCurrencyReward = 60,
		dropTableId = "Loot_TrialChampion",
	},

	-- === Duskwood Forest (Lv 10–25) ===
	Enemy_CorruptedWolf = {
		id = "Enemy_CorruptedWolf",
		displayName = "Corrupted Wolf",
		level = 12,
		zone = "DuskwoodForest",
		element = "Dark",
		stats = { HP = 120, STR = 15, VIT = 8, INT = 3, AGI = 12, LUK = 5 },
		defense = 8,
		expReward = 45,
		softCurrencyReward = 15,
		dropTableId = "Loot_CorruptedWolf",
	},

	Enemy_ShadowWraith = {
		id = "Enemy_ShadowWraith",
		displayName = "Shadow Wraith",
		level = 18,
		zone = "DuskwoodForest",
		element = "Dark",
		stats = { HP = 200, STR = 12, VIT = 10, INT = 25, AGI = 18, LUK = 8 },
		defense = 10,
		expReward = 70,
		softCurrencyReward = 25,
		dropTableId = "Loot_ShadowWraith",
	},

	Enemy_FrostSentinel = {
		id = "Enemy_FrostSentinel",
		displayName = "Frost Sentinel",
		level = 20,
		zone = "DuskwoodForest",
		element = "Water",
		stats = { HP = 350, STR = 20, VIT = 20, INT = 15, AGI = 10, LUK = 8 },
		defense = 18,
		expReward = 120,
		softCurrencyReward = 40,
		dropTableId = "Loot_FrostSentinel",
	},

	Enemy_ArenaChampion = {
		id = "Enemy_ArenaChampion",
		displayName = "Arena Champion",
		level = 40,
		zone = "DuskwoodForest",
		element = nil,
		stats = { HP = 1500, STR = 60, VIT = 50, INT = 20, AGI = 35, LUK = 20 },
		defense = 40,
		expReward = 500,
		softCurrencyReward = 150,
		dropTableId = "Loot_ArenaChampion",
	},

	-- === Frostpeak Mountains (Lv 25–45) ===
	Enemy_IceElemental = {
		id = "Enemy_IceElemental",
		displayName = "Ice Elemental",
		level = 28,
		zone = "FrostpeakMountains",
		element = "Water",
		stats = { HP = 300, STR = 15, VIT = 25, INT = 35, AGI = 12, LUK = 10 },
		defense = 22,
		expReward = 100,
		softCurrencyReward = 35,
		dropTableId = "Loot_IceElemental",
	},

	Enemy_FrostGiant = {
		id = "Enemy_FrostGiant",
		displayName = "Frost Giant",
		level = 35,
		zone = "FrostpeakMountains",
		element = "Earth",
		stats = { HP = 800, STR = 45, VIT = 40, INT = 10, AGI = 8, LUK = 12 },
		defense = 35,
		expReward = 200,
		softCurrencyReward = 70,
		dropTableId = "Loot_FrostGiant",
	},

	Enemy_ArcaneConstruct = {
		id = "Enemy_ArcaneConstruct",
		displayName = "Arcane Construct",
		level = 40,
		zone = "FrostpeakMountains",
		element = "Wind",
		stats = { HP = 1200, STR = 30, VIT = 35, INT = 55, AGI = 20, LUK = 15 },
		defense = 30,
		expReward = 400,
		softCurrencyReward = 120,
		dropTableId = "Loot_ArcaneConstruct",
	},

	-- === DUNGEON BOSSES ===
	Enemy_DungeonBoss_CryptLord = {
		id = "Enemy_DungeonBoss_CryptLord",
		displayName = "Crypt Lord",
		level = 30,
		zone = "DuskwoodForest",
		element = "Dark",
		stats = { HP = 3000, STR = 50, VIT = 45, INT = 30, AGI = 25, LUK = 20 },
		defense = 35,
		expReward = 500,
		softCurrencyReward = 150,
		dropTableId = "Loot_CryptLord",
		isBoss = true,
	},

	Enemy_DungeonBoss_FrostWyrm = {
		id = "Enemy_DungeonBoss_FrostWyrm",
		displayName = "Frost Wyrm",
		level = 35,
		zone = "FrostpeakMountains",
		element = "Water",
		stats = { HP = 4500, STR = 60, VIT = 55, INT = 40, AGI = 20, LUK = 25 },
		defense = 45,
		expReward = 800,
		softCurrencyReward = 250,
		dropTableId = "Loot_FrostWyrm",
		isBoss = true,
	},

	Enemy_DungeonBoss_CorruptedTreant = {
		id = "Enemy_DungeonBoss_CorruptedTreant",
		displayName = "Corrupted Treant",
		level = 20,
		zone = "DuskwoodForest",
		element = "Dark",
		stats = { HP = 1800, STR = 35, VIT = 40, INT = 20, AGI = 10, LUK = 15 },
		defense = 25,
		expReward = 300,
		softCurrencyReward = 80,
		dropTableId = "Loot_CorruptedTreant",
		isBoss = true,
	},
}
