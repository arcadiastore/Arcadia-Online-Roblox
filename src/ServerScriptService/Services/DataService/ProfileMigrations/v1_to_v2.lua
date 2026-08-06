--[[
	v1_to_v2.lua
	Migrasi SchemaVersion 1 -> 2: menambah field ProfessionId & ProfessionExp
	(profesi non-combat Craftsman, docs/01_GDD.md §8.4) ke Player Profile
	lama yang belum punya field ini. Lihat docs/03_DDD.md §5 poin 0 & 1-3 —
	ini adalah migrasi resmi pertama yang benar-benar dijalankan, dibuat
	bersamaan dengan implementasi Profile system (sebelum ini belum ada satu
	pun data pemain di production).

	Dipanggil oleh ProfileMigrations/init.lua saat Data.SchemaVersion pemain
	yang di-load < 2. JANGAN hapus/timpa field lain milik pemain.
]]

return function(data)
	if data.ProfessionId == nil then
		data.ProfessionId = nil -- eksplisit: belum ambil profesi (nil bermakna, bukan field yang lupa diisi)
	end
	if data.ProfessionExp == nil then
		data.ProfessionExp = 0
	end
	data.SchemaVersion = 2
	return data
end
