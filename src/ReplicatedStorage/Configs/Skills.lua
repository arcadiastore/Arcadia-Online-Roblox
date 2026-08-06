--[[
	Skills.lua
	Definisi skill — sumber kebenaran untuk CombatService.
	Lihat docs/01_GDD.md §9, docs/03_DDD.md §3.

	damageType:
	  - "Physical" → scale dari STR
	  - "Magical"  → scale dari INT

	targetType:
	  - "Single" → 1 target
	  - "AoE"    → semua musuh di radius

	cooldown dalam detik.
	manaCost dikurangi dari player saat cast.
]]

return {
	-- === Warrior / Knight / Warlord ===
	SlashCombo = {
		id = "SlashCombo",
		displayName = "Slash Combo",
		description = "Quick 2-hit slash combo.",
		damageType = "Physical",
		targetType = "Single",
		element = nil,        -- neutral
		baseDamage = 15,
		manaCost = 5,
		cooldown = 1.5,
		requiredClass = nil,  -- bisa dipakai semua (basic attack)
		levelRequired = 1,
	},

	WarCry = {
		id = "WarCry",
		displayName = "War Cry",
		description = "Battle shout that deals AoE damage and reduces enemy DEF.",
		damageType = "Physical",
		targetType = "AoE",
		element = nil,
		baseDamage = 25,
		manaCost = 15,
		cooldown = 8,
		requiredClass = "Warrior",
		levelRequired = 3,
	},

	ShieldBash = {
		id = "ShieldBash",
		displayName = "Shield Bash",
		description = "Bash with shield, chance to stun.",
		damageType = "Physical",
		targetType = "Single",
		element = nil,
		baseDamage = 30,
		manaCost = 10,
		cooldown = 5,
		requiredClass = "Knight",
		levelRequired = 15,
	},

	WarlordStrike = {
		id = "WarlordStrike",
		displayName = "Warlord Strike",
		description = "Devastating overhead strike.",
		damageType = "Physical",
		targetType = "Single",
		element = nil,
		baseDamage = 80,
		manaCost = 25,
		cooldown = 10,
		requiredClass = "Warlord",
		levelRequired = 40,
	},

	-- === Assassin / Shadowblade / Nightstalker ===
	Backstab = {
		id = "Backstab",
		displayName = "Backstab",
		description = "Strike from behind, high crit chance.",
		damageType = "Physical",
		targetType = "Single",
		element = nil,
		baseDamage = 20,
		manaCost = 8,
		cooldown = 3,
		requiredClass = "Assassin",
		levelRequired = 1,
	},

	ShadowStep = {
		id = "ShadowStep",
		displayName = "Shadow Step",
		description = "Teleport strike with dark energy.",
		damageType = "Physical",
		targetType = "Single",
		element = "Dark",
		baseDamage = 40,
		manaCost = 18,
		cooldown = 8,
		requiredClass = "Shadowblade",
		levelRequired = 15,
	},

	Nightblade = {
		id = "Nightblade",
		description = "Dual-wield dark slash.",
		displayName = "Nightblade",
		damageType = "Physical",
		targetType = "AoE",
		element = "Dark",
		baseDamage = 65,
		manaCost = 30,
		cooldown = 12,
		requiredClass = "Nightstalker",
		levelRequired = 40,
	},

	-- === Mage / Elementalist / Archmage ===
	Fireball = {
		id = "Fireball",
		displayName = "Fireball",
		description = "Hurls a ball of fire.",
		damageType = "Magical",
		targetType = "Single",
		element = "Fire",
		baseDamage = 22,
		manaCost = 10,
		cooldown = 2,
		requiredClass = "Mage",
		levelRequired = 1,
	},

	IceSpear = {
		id = "IceSpear",
		displayName = "Ice Spear",
		description = "Piercing ice projectile.",
		damageType = "Magical",
		targetType = "Single",
		element = "Water",
		baseDamage = 18,
		manaCost = 8,
		cooldown = 1.5,
		requiredClass = "Mage",
		levelRequired = 1,
	},

	ElementalBurst = {
		id = "ElementalBurst",
		displayName = "Elemental Burst",
		description = "AoE explosion of chosen element.",
		damageType = "Magical",
		targetType = "AoE",
		element = "Fire",
		baseDamage = 50,
		manaCost = 25,
		cooldown = 10,
		requiredClass = "Elementalist",
		levelRequired = 15,
	},

	ArcaneStorm = {
		id = "ArcaneStorm",
		displayName = "Arcane Storm",
		description = "Devastating arcane AoE.",
		damageType = "Magical",
		targetType = "AoE",
		element = nil,
		baseDamage = 100,
		manaCost = 40,
		cooldown = 15,
		requiredClass = "Archmage",
		levelRequired = 40,
	},

	-- === Healer / Priest / High Priest ===
	HolyLight = {
		id = "HolyLight",
		displayName = "Holy Light",
		description = "Healing light (heals ally, damages undead).",
		damageType = "Magical",
		targetType = "Single",
		element = "Light",
		baseDamage = 0,   -- heal, bukan damage
		baseHeal = 25,
		manaCost = 12,
		cooldown = 3,
		requiredClass = "Healer",
		levelRequired = 1,
	},

	Smite = {
		id = "Smite",
		displayName = "Smite",
		description = "Holy smite against enemies.",
		damageType = "Magical",
		targetType = "Single",
		element = "Light",
		baseDamage = 20,
		manaCost = 8,
		cooldown = 2,
		requiredClass = "Healer",
		levelRequired = 1,
	},

	DivineJudgment = {
		id = "DivineJudgment",
		displayName = "Divine Judgment",
		description = "Call down divine lightning.",
		damageType = "Magical",
		targetType = "AoE",
		element = "Light",
		baseDamage = 75,
		manaCost = 35,
		cooldown = 12,
		requiredClass = "HighPriest",
		levelRequired = 40,
	},

	-- === Archer / Ranger / Deadeye ===
	QuickShot = {
		id = "QuickShot",
		displayName = "Quick Shot",
		description = "Fast arrow shot.",
		damageType = "Physical",
		targetType = "Single",
		element = nil,
		baseDamage = 12,
		manaCost = 4,
		cooldown = 1,
		requiredClass = "Archer",
		levelRequired = 1,
	},

	ArrowRain = {
		id = "ArrowRain",
		displayName = "Arrow Rain",
		description = "Rain of arrows on area.",
		damageType = "Physical",
		targetType = "AoE",
		element = nil,
		baseDamage = 35,
		manaCost = 20,
		cooldown = 8,
		requiredClass = "Ranger",
		levelRequired = 15,
	},

	DeadEye = {
		id = "DeadEye",
		displayName = "Dead Eye",
		description = "Perfectly aimed shot, always crits.",
		damageType = "Physical",
		targetType = "Single",
		element = nil,
		baseDamage = 90,
		manaCost = 30,
		cooldown = 15,
		requiredClass = "Deadeye",
		levelRequired = 40,
	},

	-- === Defender / Guardian / Sentinel ===
	Taunt = {
		id = "Taunt",
		displayName = "Taunt",
		description = "Taunt enemies to attack you.",
		damageType = "Physical",
		targetType = "AoE",
		element = nil,
		baseDamage = 8,
		manaCost = 5,
		cooldown = 4,
		requiredClass = "Defender",
		levelRequired = 1,
	},

	FortressSlam = {
		id = "FortressSlam",
		displayName = "Fortress Slam",
		description = "Slam the ground, AoE damage + slow.",
		damageType = "Physical",
		targetType = "AoE",
		element = "Earth",
		baseDamage = 45,
		manaCost = 20,
		cooldown = 10,
		requiredClass = "Guardian",
		levelRequired = 15,
	},

	SentinelWrath = {
		id = "SentinelWrath",
		displayName = "Sentinel's Wrath",
		description = "Unleash stored damage as AoE burst.",
		damageType = "Physical",
		targetType = "AoE",
		element = "Earth",
		baseDamage = 85,
		manaCost = 35,
		cooldown = 15,
		requiredClass = "Sentinel",
		levelRequired = 40,
	},
}
