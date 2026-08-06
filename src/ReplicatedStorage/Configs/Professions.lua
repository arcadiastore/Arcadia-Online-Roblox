--[[
	Professions.lua
	Sumber kebenaran data Profesi non-combat (mis. Craftsman) — terpisah dari
	Classes.lua (Kelas combat / Job Tier). Lihat docs/01_GDD.md §8.4 untuk
	rasionalisasi desain, dan docs/03_DDD.md §2-3 untuk skema entry.

	Profession entry:
		ranks      = urutan rank profesi (bukan character level), tiap rank
		             punya requiredExp (ProfessionExp di Player Profile) yang
		             membuka tier resep lebih tinggi.
		recipeIds  = placeholder, diisi setelah resep didesain lengkap.

	Recipe entry:
		professionId   = profesi mana yang bisa pakai resep ini.
		requiredRank   = rank minimum (field id di ranks profesi terkait).
		materials      = { { itemId, quantity }, ... } — itemId wajib merujuk
		                 entry di Items.lua dengan type = "Material".
		resultItemId   = itemId hasil crafting (merujuk Items.lua).

	JANGAN taruh angka/nama sistem ini langsung di dalam Service — semua
	logic wajib require() modul ini (aturan anti-hardcode, docs/06_CODING_STANDARDS.md §2).
]]

return {
	-- === Profesi ===
	Craftsman = {
		id = "Craftsman",
		displayName = "Craftsman",
		ranks = {
			{ id = "Apprentice", displayName = "Apprentice Craftsman", requiredExp = 0 },
			{ id = "Journeyman", displayName = "Journeyman Craftsman", requiredExp = 500 },
			{ id = "Master",     displayName = "Master Craftsman",     requiredExp = 2000 },
		},
		recipeIds = {}, -- placeholder, isi setelah resep & Items.lua (Material) didesain
	},

	-- === Resep (diisi belakangan, lihat docs/03_DDD.md §3 untuk contoh skema) ===
}
