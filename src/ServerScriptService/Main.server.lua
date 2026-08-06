--[[
	Main.server.lua
	Bootstrap SATU-SATUNYA untuk ServerScriptService — panggil Init() semua
	Service di sini, urutan penting kalau ada dependency antar Service.
	JANGAN taruh logic gameplay di file ini, hanya wiring startup.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local DataService = require(ServerScriptService.Services.DataService)
DataService.Init()

-- Service berikutnya (Combat, Quest, Inventory, dst.) di-require & di-Init()
-- di sini juga, ditambahkan seiring diimplementasikan — lihat
-- docs/05_PROGRESS_TRACKER.md untuk status tiap sistem.
