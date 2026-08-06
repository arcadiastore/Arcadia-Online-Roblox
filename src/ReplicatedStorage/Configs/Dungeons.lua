--[[
	Dungeons.lua
	Definisi dungeon — sumber kebenaran untuk DungeonService.
	Lihat docs/01_GDD.md §11.

	type:
	  - "Normal"  → standar dungeon
	  - "Boss"    → boss raid

	waves: daftar wave, tiap wave punya list enemy
	  - enemyId → referensi ke Enemies.lua
	  - count   → jumlah musuh

	rewards:
	  - exp
	  - softCurrency
	  - items → { { itemId, quantity, dropRate (0.0–1.0) } }

	requirements:
	  - requiredLevel
	  - requiredPartySize (min berapa player)
	  - requiredItemId (opsional, key item)
	  - requiredQuestId (opsional)
]]

return {
	Dungeon_SunkenCrypt = {
		id = "Dungeon_SunkenCrypt",
		displayName = "The Sunken Crypt",
		description = "An ancient crypt corrupted by dark forces. Defeat the Crypt Lord to cleanse it.",
		type = "Normal",
		zone = "DuskwoodForest",
		enemyElement = "Dark",
		requirements = {
			requiredLevel = 10,
			requiredPartySize = 1,
		},
		waves = {
			{ enemies = { { enemyId = "Enemy_ShadowWraith", count = 3 } } },
			{ enemies = { { enemyId = "Enemy_CorruptedWolf", count = 4 }, { enemyId = "Enemy_ShadowWraith", count = 1 } } },
			{ enemies = { { enemyId = "Enemy_ShadowWraith", count = 2 }, { enemyId = "Enemy_CorruptedWolf", count = 2 } } },
			{ enemies = { { enemyId = "Enemy_DungeonBoss_CryptLord", count = 1 } } }, -- boss wave
		},
		rewards = {
			exp = 800,
			softCurrency = 200,
			items = {
				{ itemId = "DarkEssence", quantity = 3, dropRate = 1.0 },
				{ itemId = "KnightBlade", quantity = 1, dropRate = 0.3 },
			},
		},
		timeLimit = 600, -- 10 menit
	},

	Dungeon_FrostpeakCavern = {
		id = "Dungeon_FrostpeakCavern",
		displayName = "Frostpeak Cavern",
		description = "A frozen cave system overrun by ice elementals. Reach the heart of the cavern.",
		type = "Normal",
		zone = "FrostpeakMountains",
		enemyElement = "Water",
		requirements = {
			requiredLevel = 15,
			requiredPartySize = 1,
		},
		waves = {
			{ enemies = { { enemyId = "Enemy_IceElemental", count = 3 } } },
			{ enemies = { { enemyId = "Enemy_IceElemental", count = 2 }, { enemyId = "Enemy_FrostGiant", count = 1 } } },
			{ enemies = { { enemyId = "Enemy_FrostGiant", count = 2 } } },
			{ enemies = { { enemyId = "Enemy_DungeonBoss_FrostWyrm", count = 1 } } },
		},
		rewards = {
			exp = 1200,
			softCurrency = 350,
			items = {
				{ itemId = "SapphireAmulet", quantity = 1, dropRate = 0.5 },
				{ itemId = "ManaPotion", quantity = 5, dropRate = 1.0 },
			},
		},
		timeLimit = 600,
	},

	Dungeon_CorruptedGrove = {
		id = "Dungeon_CorruptedGrove",
		displayName = "The Corrupted Grove",
		description = "A once-beautiful grove now twisted by Corruption. Cleanse the heart tree.",
		type = "Normal",
		zone = "DuskwoodForest",
		enemyElement = "Dark",
		requirements = {
			requiredLevel = 5,
			requiredPartySize = 1, -- solo-friendly
		},
		waves = {
			{ enemies = { { enemyId = "Enemy_CorruptedWolf", count = 3 } } },
			{ enemies = { { enemyId = "Enemy_CorruptedWolf", count = 2 }, { enemyId = "Enemy_Goblin", count = 2 } } },
			{ enemies = { { enemyId = "Enemy_DungeonBoss_CorruptedTreant", count = 1 } } },
		},
		rewards = {
			exp = 400,
			softCurrency = 100,
			items = {
				{ itemId = "Moonpetal", quantity = 5, dropRate = 1.0 },
				{ itemId = "HealthPotion", quantity = 3, dropRate = 1.0 },
			},
		},
		timeLimit = 420, -- 7 menit
	},
}
