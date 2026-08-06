--[[
	Quests.lua
	Sumber kebenaran data Quest. Lihat docs/01_GDD.md §13, docs/03_DDD.md §3.

	type:
	  - "Kill"    → targetId = enemyId, targetCount = jumlah
	  - "Collect"  → targetId = itemId, targetCount = jumlah
	  - "Talk"     → targetId = npcId, targetCount = 1
	  - "Explore"  → targetId = zoneId, targetCount = 1
	  - "GateOpen" → targetId = gateId, targetCount = 1

	prerequisites:
	  - requiredLevel = number
	  - requiredQuestId = string (quest yang harus sudah selesai)

	rewards:
	  - exp = number
	  - softCurrency = number
	  - items = { { itemId, quantity } }

	repeatable:
	  - false = one-time quest
	  - "daily" = bisa diulang setelah reset harian
	  - "always" = bisa diulang terus
]]

return {
	-- ========================================
	-- MAIN QUEST: Millhaven (starting zone)
	-- ========================================
	Q_Millhaven_Intro = {
		id = "Q_Millhaven_Intro",
		displayName = "Welcome to Millhaven",
		description = "Talk to Elder Aldric at the town center.",
		type = "Talk",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 1 },
		objectives = { { targetId = "NPC_ElderAldric", targetCount = 1 } },
		rewards = { exp = 50, softCurrency = 10 },
		repeatable = false,
	},

	Q_Millhaven_WolfThreat = {
		id = "Q_Millhaven_WolfThreat",
		displayName = "The Wolf Threat",
		description = "Defeat 5 wolves threatening Millhaven's outskirts.",
		type = "Kill",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 1, requiredQuestId = "Q_Millhaven_Intro" },
		objectives = { { targetId = "Enemy_Wolf", targetCount = 5 } },
		rewards = { exp = 100, softCurrency = 25 },
		repeatable = false,
	},

	Q_Millhaven_HerbGather = {
		id = "Q_Millhaven_HerbGather",
		displayName = "Healing Herbs",
		description = "Collect 3 Moonpetal herbs for the village healer.",
		type = "Collect",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 1, requiredQuestId = "Q_Millhaven_Intro" },
		objectives = { { targetId = "Item_Moonpetal", targetCount = 3 } },
		rewards = { exp = 75, softCurrency = 15, items = { { itemId = "Item_HealthPotion", quantity = 2 } } },
		repeatable = false,
	},

	-- ========================================
	-- MAIN QUEST: Gate Unlock
	-- ========================================
	Q_OpenGate_Duskwood = {
		id = "Q_OpenGate_Duskwood",
		displayName = "Path to Duskwood",
		description = "Prove your worth by completing trials to unlock the Duskwood Gate.",
		type = "Kill",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 8, requiredQuestId = "Q_Millhaven_WolfThreat" },
		objectives = { { targetId = "Enemy_GateGuardian", targetCount = 1 } },
		rewards = { exp = 200, softCurrency = 50 },
		repeatable = false,
	},

	Q_OpenGate_Frostpeak = {
		id = "Q_OpenGate_Frostpeak",
		displayName = "Frozen Passage",
		description = "Defeat the Frost Sentinel to unlock the Frostpeak Gate.",
		type = "Kill",
		zone = "DuskwoodForest",
		prerequisites = { requiredLevel = 20 },
		objectives = { { targetId = "Enemy_FrostSentinel", targetCount = 1 } },
		rewards = { exp = 500, softCurrency = 100 },
		repeatable = false,
	},

	-- ========================================
	-- JOB CHANGE QUESTS
	-- ========================================
	Q_JobChange_Knight = {
		id = "Q_JobChange_Knight",
		displayName = "Trial of the Knight",
		description = "Complete the warrior's trial to advance to Knight.",
		type = "Kill",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 15 },
		objectives = { { targetId = "Enemy_TrialChampion", targetCount = 1 } },
		rewards = { exp = 300, softCurrency = 75 },
		repeatable = false,
	},

	Q_JobChange_Shadowblade = {
		id = "Q_JobChange_Shadowblade",
		displayName = "Shadow's Embrace",
		description = "Prove your stealth by passing the Shadow trial.",
		type = "Explore",
		zone = "DuskwoodForest",
		prerequisites = { requiredLevel = 15 },
		objectives = { { targetId = "Zone_ShadowTrial", targetCount = 1 } },
		rewards = { exp = 300, softCurrency = 75 },
		repeatable = false,
	},

	Q_JobChange_Guardian = {
		id = "Q_JobChange_Guardian",
		displayName = "Shield of the Realm",
		description = "Protect the village from the raid to earn Guardian rank.",
		type = "Kill",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 15 },
		objectives = { { targetId = "Enemy_RaidLeader", targetCount = 1 } },
		rewards = { exp = 300, softCurrency = 75 },
		repeatable = false,
	},

	Q_JobChange_Elementalist = {
		id = "Q_JobChange_Elementalist",
		displayName = "Elemental Convergence",
		description = "Attune to the elemental shrine to become an Elementalist.",
		type = "Explore",
		zone = "DuskwoodForest",
		prerequisites = { requiredLevel = 15 },
		objectives = { { targetId = "Zone_ElementalShrine", targetCount = 1 } },
		rewards = { exp = 300, softCurrency = 75 },
		repeatable = false,
	},

	Q_JobChange_Cleric = {
		id = "Q_JobChange_Cleric",
		displayName = "Divine Calling",
		description = "Receive the blessing at the Temple of Light.",
		type = "Talk",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 15 },
		objectives = { { targetId = "NPC_HighPriestess", targetCount = 1 } },
		rewards = { exp = 300, softCurrency = 75 },
		repeatable = false,
	},

	Q_JobChange_Ranger = {
		id = "Q_JobChange_Ranger",
		displayName = "Wilderness Tracker",
		description = "Track and eliminate the alpha predator in the wilds.",
		type = "Kill",
		zone = "DuskwoodForest",
		prerequisites = { requiredLevel = 15 },
		objectives = { { targetId = "Enemy_AlphaWolf", targetCount = 1 } },
		rewards = { exp = 300, softCurrency = 75 },
		repeatable = false,
	},

	-- ========================================
	-- TIER 3 JOB CHANGE QUESTS
	-- ========================================
	Q_JobChange_Warlord = {
		id = "Q_JobChange_Warlord",
		displayName = "Rise of the Warlord",
		description = "Conquer the arena champion to achieve Warlord status.",
		type = "Kill",
		zone = "DuskwoodForest",
		prerequisites = { requiredLevel = 40 },
		objectives = { { targetId = "Enemy_ArenaChampion", targetCount = 1 } },
		rewards = { exp = 800, softCurrency = 200 },
		repeatable = false,
	},

	Q_JobChange_Nightstalker = {
		id = "Q_JobChange_Nightstalker",
		displayName = "Night's Edge",
		description = "Assassinate the shadow lord to become Nightstalker.",
		type = "Kill",
		zone = "DuskwoodForest",
		prerequisites = { requiredLevel = 40 },
		objectives = { { targetId = "Enemy_ShadowLord", targetCount = 1 } },
		rewards = { exp = 800, softCurrency = 200 },
		repeatable = false,
	},

	Q_JobChange_Sentinel = {
		id = "Q_JobChange_Sentinel",
		displayName = "Last Stand",
		description = "Hold the fortress against the siege to earn Sentinel rank.",
		type = "Kill",
		zone = "FrostpeakMountains",
		prerequisites = { requiredLevel = 40 },
		objectives = { { targetId = "Enemy_SiegeCommander", targetCount = 1 } },
		rewards = { exp = 800, softCurrency = 200 },
		repeatable = false,
	},

	Q_JobChange_Archmage = {
		id = "Q_JobChange_Archmage",
		displayName = "Arcane Ascension",
		description = "Defeat the arcane construct to ascend to Archmage.",
		type = "Kill",
		zone = "FrostpeakMountains",
		prerequisites = { requiredLevel = 40 },
		objectives = { { targetId = "Enemy_ArcaneConstruct", targetCount = 1 } },
		rewards = { exp = 800, softCurrency = 200 },
		repeatable = false,
	},

	Q_JobChange_Oracle = {
		id = "Q_JobChange_Oracle",
		displayName = "Sight Beyond",
		description = "Meditate at the Oracle's Sanctum to receive divine sight.",
		type = "Explore",
		zone = "FrostpeakMountains",
		prerequisites = { requiredLevel = 40 },
		objectives = { { targetId = "Zone_OracleSanctum", targetCount = 1 } },
		rewards = { exp = 800, softCurrency = 200 },
		repeatable = false,
	},

	Q_JobChange_Warden = {
		id = "Q_JobChange_Warden",
		displayName = "Nature's Wrath",
		description = "Cleanse the corrupted grove to become Warden.",
		type = "Kill",
		zone = "DuskwoodForest",
		prerequisites = { requiredLevel = 40 },
		objectives = { { targetId = "Enemy_CorruptedTreant", targetCount = 1 } },
		rewards = { exp = 800, softCurrency = 200 },
		repeatable = false,
	},

	-- ========================================
	-- SIDE QUESTS (repeatable grinding)
	-- ========================================
	Q_Daily_WolfHunt = {
		id = "Q_Daily_WolfHunt",
		displayName = "Daily: Wolf Patrol",
		description = "Cull the wolf population. Kill 10 wolves.",
		type = "Kill",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 3 },
		objectives = { { targetId = "Enemy_Wolf", targetCount = 10 } },
		rewards = { exp = 80, softCurrency = 20 },
		repeatable = "daily",
	},

	Q_Daily_HerbRun = {
		id = "Q_Daily_HerbRun",
		displayName = "Daily: Herb Collection",
		description = "Gather 5 herbs for the village stockpile.",
		type = "Collect",
		zone = "Millhaven",
		prerequisites = { requiredLevel = 3 },
		objectives = { { targetId = "Item_Moonpetal", targetCount = 5 } },
		rewards = { exp = 60, softCurrency = 15 },
		repeatable = "daily",
	},
}
