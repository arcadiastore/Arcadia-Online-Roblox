--[[
	DataService.lua
	Service resmi untuk load/save/akses Player Profile (docs/03_DDD.md §4,
	docs/02_TDD.md §6). Ini SATU-SATUNYA titik masuk resmi untuk baca/tulis
	data pemain — Service lain (Combat, Quest, Inventory, dst. — belum
	diimplementasi) WAJIB lewat DataService.GetProfile(player), jangan akses
	ProfileStore/DataStore langsung (docs/06_CODING_STANDARDS.md §3: "semua
	item/currency yang bertambah tercatat via satu jalur Service resmi").

	Dipanggil oleh: src/ServerScriptService/Main.server.lua (bootstrap).
	Mewarisi BaseService (lifecycle Init/Start, inter-service reference).

	API publik (server-only):
	  DataService.GetProfile(player)                    -> table Data | nil (nil = belum siap/gagal load)
	  DataService.WaitForProfile(player, timeoutSeconds) -> table Data | nil
	  DataService.IsLoaded(player)                       -> boolean
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local BaseService = require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("BaseService"))
local ProfileStore = require(ServerStorage.Private.ProfileStore)
local ProfileTemplate = require(ReplicatedStorage.Configs.ProfileTemplate)
local ProfileMigrations = require(script.ProfileMigrations)
local RemoteHandlers = require(script.RemoteHandlers)
local TableUtil = require(ReplicatedStorage.Shared.TableUtil)
local DataConstants = require(ReplicatedStorage.Shared.DataConstants)

local DataService = BaseService:Extend("DataService")

local store = ProfileStore.New(DataConstants.ProfileStoreName, ProfileTemplate)

local playerProfiles = {} -- [UserId: number] = Profile (dari ProfileStore)
local pendingLeave = {} -- [UserId: number] = true, kalau player leave sebelum load selesai

local function profileKeyFor(userId)
	return DataConstants.ProfileKeyPrefix .. tostring(userId)
end

local function onPlayerAdded(player)
	local key = profileKeyFor(player.UserId)

	local profile, failReason = store:LoadProfileAsync(key)

	if pendingLeave[player.UserId] then
		-- Player sudah leave sebelum load selesai — langsung release, jangan
		-- biarkan nyangkut sebagai active profile di server ini.
		pendingLeave[player.UserId] = nil
		if profile then
			profile:Release()
		end
		return
	end

	if not profile then
		warn(("[DataService] Gagal load profil %s (UserId %d): %s — kick demi keamanan data."):format(
			player.Name, player.UserId, tostring(failReason)))
		player:Kick("Gagal memuat data pemain kamu. Silakan coba masuk lagi dalam beberapa saat.")
		return
	end

	profile.Data = ProfileMigrations.Apply(profile.Data, ProfileTemplate.SchemaVersion)
	TableUtil.ReconcileDefaults(profile.Data, ProfileTemplate)

	playerProfiles[player.UserId] = profile
end

local function onPlayerRemoving(player)
	local profile = playerProfiles[player.UserId]
	if profile then
		playerProfiles[player.UserId] = nil
		profile:Release()
	else
		-- Load kemungkinan belum selesai saat player leave secepat ini.
		pendingLeave[player.UserId] = true
	end
end

-- Mengembalikan table Data pemain (reference langsung — Service lain BOLEH
-- memodifikasi ini, itu memang jalurnya). nil kalau belum siap/gagal load.
function DataService.GetProfile(player)
	local profile = playerProfiles[player.UserId]
	return profile and profile.Data or nil
end

function DataService.IsLoaded(player)
	return playerProfiles[player.UserId] ~= nil
end

-- Nunggu sampai profil siap (dipakai RemoteHandlers/Service lain yang bisa
-- race dengan proses load awal). timeoutSeconds default 10.
function DataService.WaitForProfile(player, timeoutSeconds)
	timeoutSeconds = timeoutSeconds or 10
	local start = os.clock()
	while DataService.GetProfile(player) == nil do
		if not player.Parent then
			return nil -- player sudah leave
		end
		if os.clock() - start >= timeoutSeconds then
			return nil
		end
		task.wait(0.25)
	end
	return DataService.GetProfile(player)
end

--[[
	Override BaseService:Init — siapkan state internal, JANGAN hubungkan
	event player atau remote belum. Service lain mungkin belum Init().
]]
function DataService:Init()
	BaseService.Init(self) -- tandai flag _initialized
	-- store & state sudah diinisialisasi di level modul (atas), cukup.
end

--[[
	Override BaseService:Start — hubungkan event player, BindToClose, dan
	remote. Semua Service sudah Init() saat ini dipanggil.
]]
function DataService:Start()
	BaseService.Start(self) -- tandai flag _started

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Player yang sudah join sebelum script ini Connect (edge case saat
	-- development/hot-reload di Studio).
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		if #Players:GetPlayers() == 0 then
			return
		end

		local pending = 0
		for _, profile in pairs(playerProfiles) do
			pending += 1
			task.spawn(function()
				profile:Release()
				pending -= 1
			end)
		end

		local start = os.clock()
		while pending > 0 and os.clock() - start < 25 do
			task.wait(0.1)
		end
	end)

	RemoteHandlers.Setup(DataService)
end

return DataService
