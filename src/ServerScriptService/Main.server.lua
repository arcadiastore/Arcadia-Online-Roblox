--[[
	Main.server.lua
	Bootstrap SATU-SATUNYA untuk ServerScriptService — daftarkan, Init(),
	lalu Start() semua Service secara berurutan. URUTAN PENTING: dependency
	wajib Init() sebelum dependent (docs/02_TDD.md §4).

	JANGAN taruh logic gameplay di file ini, hanya wiring startup.
	Lihat docs/05_PROGRESS_TRACKER.md untuk status tiap sistem.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ServicesFolder = ServerScriptService:WaitForChild("Services")

local BaseService = require(ServicesFolder:WaitForChild("BaseService"))

-- === Daftar Service (urutkan sesuai dependency) ===
-- DataService wajib pertama (semua Service lain butuh data pemain via DataService.GetProfile).
-- Tambahkan entry baru di sini saat Service baru diimplementasi.
local DataService = require(ServicesFolder:WaitForChild("DataService"))
local CharacterService = require(ServicesFolder:WaitForChild("CharacterService"))
local LevelService = require(ServicesFolder:WaitForChild("LevelService"))
local GateService = require(ServicesFolder:WaitForChild("GateService"))
local JobChangeService = require(ServicesFolder:WaitForChild("JobChangeService"))
local QuestService = require(ServicesFolder:WaitForChild("QuestService"))
local CombatService = require(ServicesFolder:WaitForChild("CombatService"))
local InventoryService = require(ServicesFolder:WaitForChild("InventoryService"))
local PartyService = require(ServicesFolder:WaitForChild("PartyService"))

local services = {
	DataService,
	CharacterService,
	LevelService,
	GateService,
	JobChangeService,
	QuestService,
	CombatService,
	InventoryService,
	PartyService,
}

-- === Phase 1: Register semua Service ===
for _, svc in ipairs(services) do
	BaseService.RegisterService(svc)
end

-- Pasang registry ke semua Service (supaya GetService() bisa dipakai)
BaseService.BindRegistry()

-- === Phase 2: Init semua Service ===
for _, svc in ipairs(services) do
	svc:Init()
end

-- === Phase 3: Start semua Service ===
for _, svc in ipairs(services) do
	svc:Start()
end
