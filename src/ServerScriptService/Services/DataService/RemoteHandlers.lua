--[[
	RemoteHandlers.lua (DataService)
	Wiring RemoteFunction Data/GetProfile -> lihat docs/02_TDD.md §5.

	Checklist anti-exploit docs/06_CODING_STANDARDS.md §3:
	  - Tidak ada argumen dari client untuk fungsi ini (tidak ada yang perlu
	    divalidasi tipe/batas nilai selain identitas `player` bawaan Roblox).
	  - Hanya mengembalikan data milik `player` yang memanggil sendiri
	    (tidak menerima parameter userId lain sama sekali).
	  - Rate-limited per player (GetProfileMinIntervalSeconds) supaya tidak
	    bisa dispam.
	  - Deep copy sebelum dikirim — client tidak pernah dapat reference ke
	    table Data server asli.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Shared.TableUtil)
local DataConstants = require(ReplicatedStorage.Shared.DataConstants)

local RemoteHandlers = {}

function RemoteHandlers.Setup(DataService)
	local remotesFolder = ReplicatedStorage.Remotes:WaitForChild("Data")
	local getProfileRemote = remotesFolder:WaitForChild("GetProfile")

	local lastCallAt = {} -- [UserId: number] = os.clock() saat panggilan terakhir

	Players.PlayerRemoving:Connect(function(player)
		lastCallAt[player.UserId] = nil
	end)

	getProfileRemote.OnServerInvoke = function(player)
		local now = os.clock()
		local last = lastCallAt[player.UserId]
		if last and (now - last) < DataConstants.GetProfileMinIntervalSeconds then
			return nil -- rate-limited, tolak diam-diam
		end
		lastCallAt[player.UserId] = now

		local data = DataService.WaitForProfile(player, 10)
		if data == nil then
			return nil
		end

		return TableUtil.DeepCopy(data)
	end
end

return RemoteHandlers
