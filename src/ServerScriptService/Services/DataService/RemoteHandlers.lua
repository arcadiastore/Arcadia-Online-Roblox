--[[
	RemoteHandlers.lua (DataService)
	Wiring RemoteFunction Data/GetProfile — lihat docs/02_TDD.md §5.

	Sekarang menggunakan RemoteValidator (Shared) untuk rate limiting standar,
	bukan implementasi sendiri. Konsisten dengan pola yang dipakai semua
	Service lain (docs/06_CODING_STANDARDS.md §3).

	Checklist anti-exploit docs/06_CODING_STANDARDS.md §3:
	  [x] Tidak ada argumen dari client (tidak ada yang perlu divalidasi
	      tipe/batas nilai selain identitas `player` bawaan Roblox).
	  [x] Hanya mengembalikan data milik `player` yang memanggil sendiri.
	  [x] Rate-limited per player (via RemoteValidator, GetProfileMinIntervalSeconds).
	  [x] Deep copy sebelum dikirim — client tidak pernah dapat reference
	      ke table Data server asli.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Shared.TableUtil)
local DataConstants = require(ReplicatedStorage.Shared.DataConstants)
local RemoteValidator = require(ReplicatedStorage.Shared.RemoteValidator)

local RemoteHandlers = {}

function RemoteHandlers.Setup(DataService)
	local remotesFolder = ReplicatedStorage.Remotes:WaitForChild("Data")
	local getProfileRemote = remotesFolder:WaitForChild("GetProfile")

	local validator = RemoteValidator.new("Data/GetProfile", DataConstants.GetProfileMinIntervalSeconds)

	getProfileRemote.OnServerInvoke = validator:WrapHandler(function(player)
		local data = DataService.WaitForProfile(player, 10)
		if data == nil then
			return nil
		end
		return TableUtil.DeepCopy(data)
	end)
end

return RemoteHandlers
