--[[
	ProfileStore.lua  (ServerStorage/Private — SERVER-ONLY, jangan require dari client)

	Engine DataStore ber-session-lock, dibangun sendiri (pure Luau, TANPA
	dependency eksternal — lihat docs/02_TDD.md §11 untuk alasan keputusan
	ini, karena project belum punya Wally/dependency manager terpasang).
	Mengimplementasikan pola yang diwajibkan docs/02_TDD.md §6:
	  - Session locking (cegah 2 server nulis ke profil yang sama sekaligus)
	  - Auto-retry dengan backoff untuk request DataStore yang gagal/throttled
	  - Auto-save berkala + save saat player leave & server shutdown

	JANGAN require modul ini langsung dari Service selain DataService —
	semua akses data pemain wajib lewat DataService.GetProfile() (satu jalur
	resmi, docs/06_CODING_STANDARDS.md §3).

	Known limitation (dicatat untuk review manusia):
	  - Tidak ada MessagingService cross-server "release segera" — kalau
	    server crash tanpa sempat Profile:Release(), server lain harus
	    menunggu SessionLockTimeoutSeconds sebelum boleh mencuri lock.
	    Cukup untuk MVP single-place; perlu direview ulang kalau nanti pakai
	    Reserved Server/dungeon instance terpisah yang sering churn.

	API:
	  ProfileStore.New(dataStoreName, template) -> Store
	  Store:LoadProfileAsync(key) -> Profile | nil, errorReason
	    errorReason: "SessionLocked" | "DataStoreError" | "AlreadyActiveInThisServer"
	  Profile.Data      -- table data pemain (BOLEH dimodifikasi Service lain)
	  Profile:Save()    -- paksa save sekarang (jarang perlu dipanggil manual, ada autosave)
	  Profile:Release() -- save akhir + lepas lock + stop autosave (WAJIB
	                        dipanggil saat player leave / server shutdown)
	  Profile:IsActive() -> boolean
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Shared.TableUtil)
local DataConstants = require(ReplicatedStorage.Shared.DataConstants)

local ProfileStore = {}
ProfileStore.__index = ProfileStore

local Profile = {}
Profile.__index = Profile

-- === Util retry (auto-retry + backoff linear sederhana) ===
local function attemptAsync(fn, maxAttempts, baseDelaySeconds)
	local lastError = "Unknown error"
	for attempt = 1, maxAttempts do
		local ok, resultOrErr = pcall(fn)
		if ok then
			return true, resultOrErr
		end
		lastError = resultOrErr
		if attempt < maxAttempts then
			task.wait(baseDelaySeconds * attempt)
		end
	end
	return false, lastError
end

-- === ProfileStore ===

function ProfileStore.New(dataStoreName, template)
	assert(type(dataStoreName) == "string", "ProfileStore.New: dataStoreName harus string")
	assert(type(template) == "table" and type(template.SchemaVersion) == "number",
		"ProfileStore.New: template harus table dengan field SchemaVersion")

	local self = setmetatable({}, ProfileStore)
	self._dataStore = DataStoreService:GetDataStore(dataStoreName)
	self._template = template
	self._activeProfiles = {} -- [key: string] = Profile
	return self
end

-- Load (atau buat baru kalau belum ada) profil dengan session lock.
-- Mengembalikan Profile kalau sukses, atau (nil, reasonString) kalau gagal.
function ProfileStore:LoadProfileAsync(key)
	assert(type(key) == "string", "LoadProfileAsync: key harus string")

	if self._activeProfiles[key] then
		return nil, "AlreadyActiveInThisServer"
	end

	local dataStore = self._dataStore
	local template = self._template

	for lockAttempt = 1, DataConstants.LoadLockRetryAttempts do
		local acquiredEntry = nil
		local lockedByOther = false

		local ok = attemptAsync(function()
			dataStore:UpdateAsync(key, function(oldEntry)
				local now = os.time()
				local lock = oldEntry and oldEntry.SessionLock

				local lockIsStale = (lock == nil)
					or lock.Released == true
					or (now - lock.UpdatedAt) >= DataConstants.SessionLockTimeoutSeconds

				if lock ~= nil and not lockIsStale then
					-- Masih dipegang server lain yang sepertinya aktif — jangan tulis apa pun,
					-- batalkan UpdateAsync (return nil membatalkan write di Roblox DataStore).
					lockedByOther = true
					return nil
				end

				local entry = oldEntry or { Data = TableUtil.DeepCopy(template) }
				entry.Data = entry.Data or TableUtil.DeepCopy(template)
				entry.Data.SchemaVersion = entry.Data.SchemaVersion or 1
				entry.SessionLock = {
					PlaceId = game.PlaceId,
					JobId = game.JobId,
					UpdatedAt = now,
					Released = false,
				}

				acquiredEntry = entry
				return entry
			end)
		end, DataConstants.MaxRetryAttempts, DataConstants.RetryBaseDelaySeconds)

		if not ok then
			return nil, "DataStoreError"
		end

		if acquiredEntry ~= nil then
			local profile = setmetatable({
				Data = acquiredEntry.Data,
				_store = self,
				_key = key,
				_active = true,
			}, Profile)

			self._activeProfiles[key] = profile
			profile:_startAutoSave()
			return profile
		end

		if lockedByOther and lockAttempt < DataConstants.LoadLockRetryAttempts then
			task.wait(DataConstants.LoadLockRetryDelaySeconds)
		end
	end

	return nil, "SessionLocked"
end

function ProfileStore:GetActiveProfile(key)
	return self._activeProfiles[key]
end

-- === Profile ===

function Profile:IsActive()
	return self._active == true
end

-- Simpan Data saat ini ke DataStore & perpanjang kepemilikan lock. Aman
-- dipanggil berkali-kali. Kalau lock ternyata sudah dicuri server lain
-- (harusnya tidak terjadi selama SessionLockTimeoutSeconds dihormati),
-- profile ini otomatis dinonaktifkan supaya tidak menimpa data server lain.
function Profile:Save()
	if not self._active then
		return false, "ProfileNotActive"
	end

	local store = self._store
	local key = self._key
	local dataSnapshot = TableUtil.DeepCopy(self.Data)
	local stolen = false

	local ok, err = attemptAsync(function()
		store._dataStore:UpdateAsync(key, function(oldEntry)
			local lock = oldEntry and oldEntry.SessionLock
			if lock ~= nil and lock.JobId ~= game.JobId then
				stolen = true
				return nil -- batalkan write, jangan timpa data server lain
			end
			return {
				Data = dataSnapshot,
				SessionLock = {
					PlaceId = game.PlaceId,
					JobId = game.JobId,
					UpdatedAt = os.time(),
					Released = false,
				},
			}
		end)
	end, DataConstants.MaxRetryAttempts, DataConstants.RetryBaseDelaySeconds)

	if stolen then
		warn(("[ProfileStore] Lock profil '%s' sudah dicuri server lain — menonaktifkan sesi ini di server sekarang untuk cegah data race."):format(key))
		self._active = false
		store._activeProfiles[key] = nil
		return false, "LockStolen"
	end

	if not ok then
		warn(("[ProfileStore] Gagal menyimpan profil '%s': %s"):format(key, tostring(err)))
	end
	return ok
end

-- Save akhir + lepas lock supaya server lain bisa langsung load tanpa nunggu
-- timeout. WAJIB dipanggil saat player leave & saat server shutdown
-- (game:BindToClose) — lihat DataService.lua.
function Profile:Release()
	if not self._active then
		return
	end
	self._active = false

	local store = self._store
	local key = self._key
	local dataSnapshot = TableUtil.DeepCopy(self.Data)

	attemptAsync(function()
		store._dataStore:UpdateAsync(key, function(oldEntry)
			local lock = oldEntry and oldEntry.SessionLock
			if lock ~= nil and lock.JobId ~= game.JobId then
				return nil -- sudah dicuri server lain, jangan sentuh data mereka
			end
			return {
				Data = dataSnapshot,
				SessionLock = {
					PlaceId = game.PlaceId,
					JobId = game.JobId,
					UpdatedAt = os.time(),
					Released = true, -- tandai bebas, server lain tidak perlu nunggu timeout
				},
			}
		end)
	end, DataConstants.MaxRetryAttempts, DataConstants.RetryBaseDelaySeconds)

	store._activeProfiles[key] = nil
end

function Profile:_startAutoSave()
	task.spawn(function()
		while self._active do
			task.wait(DataConstants.AutoSaveIntervalSeconds)
			if self._active then
				self:Save()
			end
		end
	end)
end

return ProfileStore
