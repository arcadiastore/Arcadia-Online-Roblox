--[[
	BaseController.lua
	Pola dasar untuk semua Controller di client (StarterPlayerScripts/Controllers).
	Setiap Controller baru WAJIB mewarisi dari modul ini via
	`BaseController:Extend("NamaController")`.

	Mirror server-side BaseService — lifecycle Init/Start terstandardisasi.

	Lifecycle (dipanggil oleh MainController.client.lua):
	  1. Init()  — kumpulkan dependency (require UI module, Config, dst.).
	               JANGAN hubungkan event UI / user input belum.
	  2. Start() — hubungkan event UI, mulai listen RemoteEvent. Semua
	               Controller sudah Init() saat Start() dipanggil.

	Aturan (docs/02_TDD.md §4, docs/04_AI_AGENT_RULES.md):
	  - Satu Controller = satu domain UI/input.
	  - Client HANYA untuk input & presentasi visual — tidak ada logic
	    keputusan gameplay di sini (damage, loot, currency dihitung server).

	Contoh pakai:
	  local BaseController = require(path.to.BaseController)
	  local CombatController = BaseController:Extend("CombatController")

	  function CombatController:Init()
	      self._combatFolder = ReplicatedStorage.Remotes:WaitForChild("Combat")
	  end

	  function CombatController:Start()
	      -- hubungkan tombol serang, listen damage feedback dari server
	  end

	  return CombatController
]]

local BaseController = {}
BaseController.__index = BaseController

--[[
	Buat Controller baru dengan nama unik.
]]
function BaseController:Extend(name: string)
	assert(type(name) == "string" and #name > 0, "BaseController:Extend — name wajib string non-kosong")

	local controller = setmetatable({}, self)
	controller._Name = name
	controller._initialized = false
	controller._started = false
	return controller
end

--[[
	Dipanggil oleh MainController.client.lua saat bootstrap. Isi dengan
	require dependency, cache reference UI element, dst. JANGAN hubungkan
	event user input di sini.
]]
function BaseController:Init()
	assert(not self._initialized, ("%s:Init dipanggil dua kali!"):format(self._Name))
	self._initialized = true
end

--[[
	Dipanggil oleh MainController.client.lua SETELAH semua Controller Init().
	Aman untuk hubungkan event UI, mulai listener RemoteEvent, dll.
]]
function BaseController:Start()
	assert(not self._started, ("%s:Start dipanggil dua kali!"):format(self._Name))
	assert(self._initialized, ("%s:Start dipanggil sebelum Init!"):format(self._Name))
	self._started = true
end

--[[
	Akses Controller lain secara lazy. Mirror GetService() di BaseService.
	Hanya berfungsi SETELAH MainController.RegisterController() dipanggil.
]]
function BaseController:GetController(controllerName: string)
	assert(self._registry, ("%s:GetController — registry belum siap"):format(self._Name))
	local ctrl = self._registry[controllerName]
	assert(ctrl, ("%s:GetController — Controller '%s' tidak ditemukan"):format(self._Name, controllerName))
	return ctrl
end

-- === Registry global (dikelola MainController.client.lua) ===

local registry = {}

function BaseController.RegisterController(controller)
	assert(controller._Name, "RegisterController: modul bukan turunan BaseController")
	assert(not registry[controller._Name],
		("RegisterController: '%s' sudah terdaftar"):format(controller._Name))
	registry[controller._Name] = controller
end

function BaseController.BindRegistry()
	for _, ctrl in pairs(registry) do
		ctrl._registry = registry
	end
end

return BaseController
