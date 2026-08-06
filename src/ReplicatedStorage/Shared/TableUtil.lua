--[[
	TableUtil.lua
	Util murni untuk manipulasi table, dipakai client & server. Tidak boleh
	berisi logic keputusan gameplay (lihat src/ReplicatedStorage/Shared/README.md).
]]

local TableUtil = {}

-- Deep copy table biasa (bukan Instance/metatable-aware) — cukup untuk Config
-- & Player Profile (murni data table bersarang, tanpa metatable/userdata).
function TableUtil.DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = TableUtil.DeepCopy(value)
	end
	return copy
end

-- Isi field yang tidak ada di `target` dengan default dari `template`, secara
-- rekursif, TANPA menghapus/menimpa field yang sudah ada di `target`.
--
-- Dipakai sebagai JARING PENGAMAN TERAKHIR setelah migrasi resmi berjalan
-- (docs/03_DDD.md §5) — bukan pengganti migrasi versi. Migrasi tetap wajib
-- untuk perubahan skema yang disengaja; fungsi ini hanya menjaga Service lain
-- tidak crash kalau ada field yang ternyata lolos dari migrasi manapun.
function TableUtil.ReconcileDefaults(target, template)
	for key, templateValue in pairs(template) do
		if target[key] == nil then
			target[key] = TableUtil.DeepCopy(templateValue)
		elseif type(templateValue) == "table" and type(target[key]) == "table" then
			TableUtil.ReconcileDefaults(target[key], templateValue)
		end
	end
	return target
end

return TableUtil
