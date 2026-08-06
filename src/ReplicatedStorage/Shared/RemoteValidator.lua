--[[
	RemoteValidator.lua
	Util validasi argumen remote dari client — dipakai di semua
	RemoteHandlers yang menerima input dari client (docs/02_TDD.md §7,
	docs/06_CODING_STANDARDS.md §3).

	Setiap Service yang punya Remote WAJIB memvalidasi argumen sebelum
	memproses. Modul ini menyediakan helper standar supaya validasi
	konsisten dan tidak perlu ditulis ulang tiap Service.

	Anti-exploit checklist (docs/06_CODING_STANDARDS.md §3):
	  [x] Validasi tipe
	  [x] Validasi batas nilai
	  [x] Rate limiting server-side (debounce per-player)
	  [x] Wrapping error handler (jangan bocorkan stack trace ke client)

	Contoh pakai di RemoteHandlers.lua:
	  local RemoteValidator = require(ReplicatedStorage.Shared.RemoteValidator)
	  local validator = RemoteValidator.new("Combat/RequestAttack")

	  remote.OnServerInvoke = function(player, targetId, skillId)
	      local ok, err = validator:Validate(player, {
	          { value = targetId, name = "targetId",  type = "string", minLength = 1, maxLength = 64 },
	          { value = skillId,  name = "skillId",   type = "string", minLength = 1, maxLength = 64 },
	      })
	      if not ok then return { error = err } end

	      -- lanjut logic...
	  end
]]

local Players = game:GetService("Players")

local RemoteValidator = {}
RemoteValidator.__index = RemoteValidator

--[[
	Buat validator baru untuk satu remote.
	  remoteName — nama remote (untuk logging, mis. "Combat/RequestAttack").
	  rateLimitSeconds — (opsional) debounce per-player. 0 atau nil = tanpa rate limit.
	  maxCallsPerWindow — (opsional) jumlah panggilan maksimum dalam window.
	  windowSeconds — (opsional) durasi window untuk maxCallsPerWindow (default 1 detik).
]]
function RemoteValidator.new(remoteName: string, rateLimitSeconds: number?)
	local self = setmetatable({}, RemoteValidator)
	self._name = remoteName
	self._rateLimitSeconds = rateLimitSeconds or 0
	self._lastCallAt = {} -- [UserId] = os.clock()
	return self
end

--[[
	Validasi satu argumen terhadap aturan. Mengembalikan (true) atau
	(false, errorMessage).

	Aturan per argumen (table):
	  name   — nama field (untuk pesan error)
	  value  — nilai yang divalidasi
	  type   — typeof yang diharapkan ("string", "number", "boolean", "table", "Instance")

	Untuk type "string":
	  minLength, maxLength — panjang string (opsional)

	Untuk type "number":
	  min, max — rentang inklusif (opsional)
	  integer  — true kalau harus bilangan bulat (opsional)
]]
local function validateOne(rule)
	local value = rule.value
	local expectedType = rule.type
	local name = rule.name or "arg"

	-- Tipe
	if typeof(value) ~= expectedType then
		return false, ("%s: tipe salah (harus %s, dapat %s)"):format(name, expectedType, typeof(value))
	end

	-- String checks
	if expectedType == "string" then
		if rule.minLength and #value < rule.minLength then
			return false, ("%s: terlalu pendek (min %d)"):format(name, rule.minLength)
		end
		if rule.maxLength and #value > rule.maxLength then
			return false, ("%s: terlalu panjang (max %d)"):format(name, rule.maxLength)
		end
	end

	-- Number checks
	if expectedType == "number" then
		if rule.min ~= nil and value < rule.min then
			return false, ("%s: terlalu kecil (min %s)"):format(name, tostring(rule.min))
		end
		if rule.max ~= nil and value > rule.max then
			return false, ("%s: terlalu besar (max %s)"):format(name, tostring(rule.max))
		end
		if rule.integer and value ~= math.floor(value) then
			return false, ("%s: harus bilangan bulat"):format(name)
		end
	end

	-- Table checks
	if expectedType == "table" then
		if rule.maxEntries and #value > rule.maxEntries then
			return false, ("%s: terlalu banyak entri (max %d)"):format(name, rule.maxEntries)
		end
	end

	return true, nil
end

--[[
	Validasi argumen dari client + rate limiting.
	  player   — objek Player dari OnServerInvoke
	  rules    — array of { name, value, type, ... } (lihat validateOne)

	Mengembalikan:
	  true                   — semua valid
	  false, errorMessage    — ada yang gagal (pesan aman untuk log, bukan stack trace)
]]
function RemoteValidator:Validate(player, rules)
	-- Rate limit per-player
	if self._rateLimitSeconds > 0 then
		local now = os.clock()
		local last = self._lastCallAt[player.UserId]
		if last and (now - last) < self._rateLimitSeconds then
			return false, ("rate-limited (min %.1fs antar panggilan)"):format(self._rateLimitSeconds)
		end
		self._lastCallAt[player.UserId] = now
	end

	-- Validasi tipe + batas nilai
	for _, rule in ipairs(rules) do
		local ok, err = validateOne(rule)
		if not ok then
			return false, err
		end
	end

	return true, nil
end

--[[
	Wrapper untuk OnServerInvoke yang otomatis menangkap error dan
	mengembalikan response aman ke client (tidak bocorkan stack trace).

	  validator  — instance RemoteValidator
	  handler    — fungsi (player, ...) -> result

	Contoh:
	  remote.OnServerInvoke = validator:WrapHandler(function(player, targetId, skillId)
	      -- logic, return result
	  end)
]]
function RemoteValidator:WrapHandler(handler)
	local validator = self
	return function(player, ...)
		local ok, result = pcall(handler, player, ...)
		if not ok then
			warn(("[RemoteValidator:%s] error dari %s: %s"):format(
				validator._name, player.Name, tostring(result)))
			return { error = "Internal server error" }
		end
		return result
	end
end

--[[
	Hapus tracking rate-limit untuk player yang sudah leave.
	Dipanggil dari PlayerRemoving.
]]
function RemoteValidator:CleanupPlayer(player)
	self._lastCallAt[player.UserId] = nil
end

return RemoteValidator
