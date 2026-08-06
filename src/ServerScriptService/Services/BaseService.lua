--[[
	BaseService.lua
	Pola dasar untuk semua Service di server. Setiap Service baru WAJIB
	mewarisi dari modul ini via `BaseService:Extend("NamaService")` untuk
	mendapatkan lifecycle terstandardisasi dan kemampuan referensi Service lain.

	Lifecycle (dipanggil oleh Main.server.lua):
	  1. Init()  — kumpulkan dependency, validasi config, JANGAN mulai koneksi
	               event/player belum. Service lain mungkin belum Init().
	  2. Start() — hubungkan event, mulai listener. Semua Service sudah Init()
	               saat Start() dipanggil, jadi aman cross-reference.

	Aturan (docs/04_AI_AGENT_RULES.md, docs/02_TDD.md §4):
	  - Satu Service = satu domain tanggung jawab.
	  - Jangan bikin circular dependency antar Service lewat Init() —
	    kalau butuh Service lain di Init(), taruh di Start() atau lazily
	    via GetService().
	  - ServiceInitOrder di Main.server.lua menentukan urutan Init() —
	    dependency wajib Init() lebih dulu dari dependent.

	Contoh pakai:
	  local BaseService = require(path.to.BaseService)
	  local CombatService = BaseService:Extend("CombatService")

	  function CombatService:Init()
	      -- require Config, siapkan state
	  end

	  function CombatService:Start()
	      -- hubungkan Remote, listen PlayerAdded, dll.
	  end

	  return CombatService
]]

local BaseService = {}
BaseService.__index = BaseService

--[[
	Buat Service baru dengan namaunik. Mengembalikan modul kosong yang
	sudah punya metode _Name, Init, Start, dan GetService.
]]
function BaseService:Extend(name: string)
	assert(type(name) == "string" and #name > 0, "BaseService:Extend — name wajib string non-kosong")

	local service = setmetatable({}, self)
	service._Name = name
	service._initialized = false
	service._started = false
	return service
end

--[[
	Dipanggil oleh Main.server.lua saat bootstrap. Isi dengan logic inisialisasi
	yang TIDAK bergantung pada event player atau Service lain yang belum Init().
	Override di turunan — base implementation cuma tandai flag.
]]
function BaseService:Init()
	assert(not self._initialized, ("%s:Init dipanggil dua kali!"):format(self._Name))
	self._initialized = true
end

--[[
	Dipanggil oleh Main.server.lua SETELAH semua Service Init(). Aman untuk
	menghubungkan event, cross-reference Service lain, mulai listener.
	Override di turunan — base implementation cuma tandai flag.
]]
function BaseService:Start()
	assert(not self._started, ("%s:Start dipanggil dua kali!"):format(self._Name))
	assert(self._initialized, ("%s:Start dipanggil sebelum Init!"):format(self._Name))
	self._started = true
end

--[[
	Akses Service lain secara lazy — hindari circular require di atas file.
	Hanya berfungsi SETELAH Main mendaftarkan semua Service via
	BaseService.RegisterService().

	  local CombatService = self:GetService("CombatService")

	JANGAN dipanggil di level atas modul (saat require) — pasti nil karena
	belum Register. Taruh di dalam Init() atau Start().
]]
function BaseService:GetService(serviceName: string)
	assert(self._registry, ("%s:GetService — registry belum siap"):format(self._Name))
	local svc = self._registry[serviceName]
	assert(svc, ("%s:GetService — Service '%s' tidak ditemukan"):format(self._Name, serviceName))
	return svc
end

-- === Registry global (dikelola Main.server.lua) ===

local registry = {} -- [name: string] = service module

--[[
	Daftarkan instance service ke registry global. Dipanggil oleh Main
	untuk setiap Service yang di-require.
]]
function BaseService.RegisterService(service)
	assert(service._Name, "RegisterService: modul bukan turunan BaseService")
	assert(not registry[service._Name],
		("RegisterService: '%s' sudah terdaftar"):format(service._Name))
	registry[service._Name] = service
end

--[[
	Akses Service lain dari luar lifecycle (mis. util/helper yang bukan
	Service tapi butuh data Service). Pemakaian langka — lebih aman pakai
	self:GetService() di dalam Service.
]]
function BaseService.GetServiceByName(serviceName: string)
	return registry[serviceName]
end

--[[
	Pasang registry ke semua Service yang sudah terdaftar (supaya
	GetService() bisa dipanggil). Dipanggil Main setelah semua Register.
]]
function BaseService.BindRegistry()
	for _, svc in pairs(registry) do
		svc._registry = registry
	end
end

return BaseService
