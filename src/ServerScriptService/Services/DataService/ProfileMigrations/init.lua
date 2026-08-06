--[[
	ProfileMigrations/init.lua
	Registry migrasi Player Profile, dipanggil DataService setelah profile
	di-load dari DataStore dan sebelum dipakai Service lain. Urutan
	dijalankan berurutan dari SchemaVersion data saat ini sampai
	targetVersion (SchemaVersion ProfileTemplate saat ini) — lihat
	docs/03_DDD.md §5.

	JANGAN menghapus entri lama dari daftar ini meskipun sudah lama, selama
	masih mungkin ada data pemain lama yang belum pernah migrasi lewat versi
	tersebut (mis. pemain yang sudah lama tidak main).
]]

local migrations = {
	[1] = require(script.v1_to_v2), -- migrasi dari versi 1 -> 2
}

local ProfileMigrations = {}

-- data          : table Player Profile mentah dari DataStore (dimodifikasi in-place & dikembalikan)
-- targetVersion : SchemaVersion tujuan (ProfileTemplate.SchemaVersion saat ini)
function ProfileMigrations.Apply(data, targetVersion)
	assert(type(data) == "table", "ProfileMigrations.Apply: data harus table")
	data.SchemaVersion = data.SchemaVersion or 1

	local safety = 0
	while data.SchemaVersion < targetVersion do
		local migrate = migrations[data.SchemaVersion]
		if not migrate then
			warn(("[ProfileMigrations] Tidak ada migrasi terdaftar dari SchemaVersion %d -> berhenti di versi ini."):format(data.SchemaVersion))
			break
		end
		data = migrate(data)

		safety += 1
		if safety > 50 then
			warn("[ProfileMigrations] Terlalu banyak langkah migrasi berurutan, kemungkinan loop tak berhenti — dihentikan paksa.")
			break
		end
	end

	return data
end

return ProfileMigrations
