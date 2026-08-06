--[[
	Elements.lua
	Element Chart — sumber kebenaran relasi kuat/lemah antar elemen.
	Lihat docs/01_GDD.md §9 untuk rasionalisasi desain.

	CombatService WAJIB require() modul ini untuk menentukan multiplier damage,
	bukan menulis ulang relasi ini di dalam logic combat.
]]

return {
	Fire  = { strongAgainst = { "Wind" },  weakAgainst = { "Water" } },
	Water = { strongAgainst = { "Fire" },  weakAgainst = { "Earth" } },
	Earth = { strongAgainst = { "Water" }, weakAgainst = { "Wind" } },
	Wind  = { strongAgainst = { "Earth" }, weakAgainst = { "Fire" } },
	Light = { strongAgainst = { "Dark" },  weakAgainst = { "Dark" } },
	Dark  = { strongAgainst = { "Light" }, weakAgainst = { "Light" } },
}
