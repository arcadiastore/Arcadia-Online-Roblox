--[[
	Races.lua
	Sumber kebenaran data Ras. Lihat docs/01_GDD.md §8.1 untuk rasionalisasi
	desain, dan docs/03_DDD.md untuk skema entry.

	statBonus  = modifier tambahan di atas base stat (semua ras pakai base sama).
	weight     = bobot RNG saat reroll ras (dipakai RaceService, bukan di sini).
	elementAffinity = elemen bawaan yang dapat bonus damage kecil (opsional, nil kalau tidak ada).
]]

return {
	Human = {
		displayName = "Human",
		rarity = "Common",
		weight = 40,
		statBonus = { STR = 2, VIT = 2, INT = 2, AGI = 2, LUK = 2 },
		elementAffinity = nil,
	},
	Elf = {
		displayName = "Elf",
		rarity = "Common",
		weight = 25,
		statBonus = { STR = -2, VIT = -2, INT = 6, AGI = 6, LUK = 2 },
		elementAffinity = nil,
	},
	Dwarf = {
		displayName = "Dwarf",
		rarity = "Common",
		weight = 25,
		statBonus = { STR = 6, VIT = 6, INT = -2, AGI = -4, LUK = 0 },
		elementAffinity = nil,
	},
	Angel = {
		displayName = "Angel",
		rarity = "Rare",
		weight = 5,
		statBonus = { STR = -3, VIT = 2, INT = 5, AGI = 1, LUK = 5 },
		elementAffinity = "Light",
	},
	Evil = {
		displayName = "Evil",
		rarity = "Rare",
		weight = 5,
		statBonus = { STR = 5, VIT = 3, INT = 4, AGI = -2, LUK = -4 },
		elementAffinity = "Dark",
	},
}
