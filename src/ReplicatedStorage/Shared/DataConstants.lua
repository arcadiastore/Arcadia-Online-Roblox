--[[
	DataConstants.lua
	Konstanta non-rahasia terkait sistem DataStore/Profile (nama store, key
	prefix, interval autosave, dsb.) — BUKAN data balance game, jadi tempatnya
	di Shared, bukan Configs (lihat src/ReplicatedStorage/Shared/README.md).
	Nilai di sini murni "wiring" teknis, bukan sesuatu yang didesain di GDD.
]]

return {
	-- Ganti ProfileStoreName HANYA untuk migrasi "keras" (wipe total semua
	-- data, mis. rombak skema besar-besaran) — kalau hanya menambah/mengubah
	-- field, pakai SchemaVersion + Migrations (docs/03_DDD.md §5), JANGAN
	-- ganti nama store. Perubahan nama store wajib dicatat di docs/02_TDD.md §11.
	ProfileStoreName = "PlayerProfile_v1",
	ProfileKeyPrefix = "Player_",

	-- Session lock & retry (docs/02_TDD.md §6)
	AutoSaveIntervalSeconds = 60,
	SessionLockTimeoutSeconds = 30, -- lock server lain dianggap basi (kemungkinan crash) setelah sekian detik
	MaxRetryAttempts = 5,
	RetryBaseDelaySeconds = 1,
	LoadLockRetryAttempts = 6, -- percobaan menunggu server lain melepas lock sebelum LoadProfileAsync menyerah
	LoadLockRetryDelaySeconds = 5,

	-- Remote Data/GetProfile
	GetProfileMinIntervalSeconds = 2, -- rate limit per-player (docs/06_CODING_STANDARDS.md §3)
}
