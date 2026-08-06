--[[
	MainController.client.lua
	Bootstrap SATU-SATUNYA untuk StarterPlayerScripts — panggil Init() lalu
	Start() semua Controller secara berurutan. Mirror Main.server.lua di sisi
	client (docs/02_TDD.md §4).

	URUTAN PENTING: Controller yang jadi dependency wajib Init() dulu.
	Untuk saat ini (MVP awal) belum ada Controller aktif — tambahkan di sini
	seiring implementasi (lihat docs/05_PROGRESS_TRACKER.md).
]]

local StarterPlayerScripts = script.Parent
local ControllersFolder = StarterPlayerScripts:WaitForChild("Controllers")

local BaseController = require(ControllersFolder:WaitForChild("BaseController"))

-- === Daftar Controller (urutkan sesuai dependency) ===
-- Tambahkan entry baru di sini saat Controller pertama diimplementasi.
-- Contoh:
--   local CombatController = require(ControllersFolder:WaitForChild("CombatController"))
--   local controllers = { CombatController }
local controllers = {}

-- === Phase 1: Register semua Controller ===
for _, ctrl in ipairs(controllers) do
	BaseController.RegisterController(ctrl)
end

-- Pasang registry ke semua Controller (supaya GetController() bisa dipakai)
BaseController.BindRegistry()

-- === Phase 2: Init semua Controller ===
for _, ctrl in ipairs(controllers) do
	ctrl:Init()
end

-- === Phase 3: Start semua Controller ===
for _, ctrl in ipairs(controllers) do
	ctrl:Start()
end
