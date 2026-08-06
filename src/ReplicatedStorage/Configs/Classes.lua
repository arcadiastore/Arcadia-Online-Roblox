--[[
	Classes.lua
	Sumber kebenaran data Kelas & Job Tier. Lihat docs/01_GDD.md §8.2 untuk
	rasionalisasi desain, dan docs/03_DDD.md untuk skema entry.

	tier            = 1 (starting class), 2, atau 3 (job change lanjutan).
	jobChange       = nil kalau ini tier akhir (Tier 3). Kalau ada, berisi
	                  nextClassId + syarat naik ke tier berikutnya.
	skillIds        = placeholder, diisi setelah Skills.lua digarap — jangan
	                  hardcode nama skill di Service, tetap require dari sini.
	requiredQuestId = placeholder id, quest job change-nya sendiri didesain
	                  belakangan di Configs/Quests.lua.
]]

return {
	-- === Melee Physical DPS ===
	Warrior = {
		displayName = "Warrior", tier = 1, role = "MeleeDPS",
		weaponTypes = { "Sword", "Axe" },
		skillIds = {},
		jobChange = { nextClassId = "Knight", requiredLevel = 15, requiredQuestId = "Q_JobChange_Knight" },
	},
	Knight = {
		displayName = "Knight", tier = 2, role = "MeleeDPS",
		weaponTypes = { "Sword", "Axe" },
		skillIds = {},
		jobChange = { nextClassId = "Warlord", requiredLevel = 40, requiredQuestId = "Q_JobChange_Warlord" },
	},
	Warlord = {
		displayName = "Warlord", tier = 3, role = "MeleeDPS",
		weaponTypes = { "Sword", "Axe" },
		skillIds = {},
		jobChange = nil,
	},

	-- === Melee Physical DPS (Stealth/Crit) ===
	Assassin = {
		displayName = "Assassin", tier = 1, role = "MeleeDPS",
		weaponTypes = { "Dagger", "DualBlade" },
		skillIds = {},
		jobChange = { nextClassId = "Shadowblade", requiredLevel = 15, requiredQuestId = "Q_JobChange_Shadowblade" },
	},
	Shadowblade = {
		displayName = "Shadowblade", tier = 2, role = "MeleeDPS",
		weaponTypes = { "Dagger", "DualBlade" },
		skillIds = {},
		jobChange = { nextClassId = "Nightstalker", requiredLevel = 40, requiredQuestId = "Q_JobChange_Nightstalker" },
	},
	Nightstalker = {
		displayName = "Nightstalker", tier = 3, role = "MeleeDPS",
		weaponTypes = { "Dagger", "DualBlade" },
		skillIds = {},
		jobChange = nil,
	},

	-- === Tank ===
	Defender = {
		displayName = "Defender", tier = 1, role = "Tank",
		weaponTypes = { "Shield", "Mace" },
		skillIds = {},
		jobChange = { nextClassId = "Guardian", requiredLevel = 15, requiredQuestId = "Q_JobChange_Guardian" },
	},
	Guardian = {
		displayName = "Guardian", tier = 2, role = "Tank",
		weaponTypes = { "Shield", "Mace" },
		skillIds = {},
		jobChange = { nextClassId = "Sentinel", requiredLevel = 40, requiredQuestId = "Q_JobChange_Sentinel" },
	},
	Sentinel = {
		displayName = "Sentinel", tier = 3, role = "Tank",
		weaponTypes = { "Shield", "Mace" },
		skillIds = {},
		jobChange = nil,
	},

	-- === Magic DPS ===
	Mage = {
		displayName = "Mage", tier = 1, role = "MagicDPS",
		weaponTypes = { "Staff", "Wand" },
		skillIds = {},
		jobChange = { nextClassId = "Elementalist", requiredLevel = 15, requiredQuestId = "Q_JobChange_Elementalist" },
	},
	Elementalist = {
		displayName = "Elementalist", tier = 2, role = "MagicDPS",
		weaponTypes = { "Staff", "Wand" },
		skillIds = {},
		jobChange = { nextClassId = "Archmage", requiredLevel = 40, requiredQuestId = "Q_JobChange_Archmage" },
	},
	Archmage = {
		displayName = "Archmage", tier = 3, role = "MagicDPS",
		weaponTypes = { "Staff", "Wand" },
		skillIds = {},
		jobChange = nil,
	},

	-- === Support / Healer ===
	Healer = {
		displayName = "Healer", tier = 1, role = "Support",
		weaponTypes = { "Staff", "Rod" },
		skillIds = {},
		jobChange = { nextClassId = "Priest", requiredLevel = 15, requiredQuestId = "Q_JobChange_Priest" },
	},
	Priest = {
		displayName = "Priest", tier = 2, role = "Support",
		weaponTypes = { "Staff", "Rod" },
		skillIds = {},
		jobChange = { nextClassId = "HighPriest", requiredLevel = 40, requiredQuestId = "Q_JobChange_HighPriest" },
	},
	HighPriest = {
		displayName = "High Priest", tier = 3, role = "Support",
		weaponTypes = { "Staff", "Rod" },
		skillIds = {},
		jobChange = nil,
	},

	-- === Ranged Physical DPS ===
	Archer = {
		displayName = "Archer", tier = 1, role = "RangedDPS",
		weaponTypes = { "Bow" },
		skillIds = {},
		jobChange = { nextClassId = "Ranger", requiredLevel = 15, requiredQuestId = "Q_JobChange_Ranger" },
	},
	Ranger = {
		displayName = "Ranger", tier = 2, role = "RangedDPS",
		weaponTypes = { "Bow" },
		skillIds = {},
		jobChange = { nextClassId = "Deadeye", requiredLevel = 40, requiredQuestId = "Q_JobChange_Deadeye" },
	},
	Deadeye = {
		displayName = "Deadeye", tier = 3, role = "RangedDPS",
		weaponTypes = { "Bow" },
		skillIds = {},
		jobChange = nil,
	},
}
