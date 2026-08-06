--[[
	Items.lua
	Skeleton config module — belum diisi data desain final.

	Skema & contoh entry: lihat docs/03_DDD.md §3 (termasuk §3.1 "Konvensi
	Aset Visual" untuk field meshId/textureId/iconId di bawah).
	Isi tabel di bawah setelah konten terkait difinalisasi di docs/01_GDD.md.
	JANGAN taruh angka/nama sistem ini langsung di dalam Service — semua
	logic wajib require() modul ini (aturan anti-hardcode, docs/06_CODING_STANDARDS.md §2).

	Field aset visual per item (opsional untuk item non-fisik seperti currency):
		meshId    = "rbxassetid://..." -- model 3D (MeshPart), upload manual
		            dari Roblox Studio, hasil AI generator (Roblox Studio
		            Cube, Meshy, Sloyd, dsb — lihat diskusi desain), atau
		            artist. Placeholder "rbxassetid://0" kalau belum ada.
		textureId = "rbxassetid://..." -- texture terpisah, nil kalau mesh
		            sudah datang dengan material ter-bake.
		iconId    = "rbxassetid://..." -- ikon 2D untuk UI (inventory/hotbar/
		            shop), wajib diisi untuk item yang tampil di UI.
]]

return {
	-- contoh: Id = { field = value, meshId = "rbxassetid://0", textureId = "rbxassetid://0", iconId = "rbxassetid://0" },
}
