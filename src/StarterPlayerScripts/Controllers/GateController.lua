--[[
	GateController.lua
	Client-side controller untuk Gate/Portal system.
	Mendeteksi ProximityPrompt di portal, menampilkan UI konfirmasi,
	dan mengirim request ke server.

	Alur:
	  1. Start() → scan semua portal di workspace (atau tunggu child baru)
	  2. Saat ProximityPrompt.Triggered → tampilkan GateConfirmUI
	  3. Player confirm → InvokeServer("Gate/RequestOpen", gateId)
	  4. Sukses → teleport visual feedback
	  5. Gagal → tampilkan reason dari server
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ControllersFolder = script.Parent
local BaseController = require(ControllersFolder:WaitForChild("BaseController"))
local GatesConfig = require(ReplicatedStorage.Configs.Gates)

local GateController = BaseController:Extend("GateController")

-- Cari gateId dari nama folder portal "Portal_GateId"
local function gateIdFromFolder(folder)
	local name = folder.Name -- "Portal_Gate_Duskwood"
	if name:sub(1, 7) == "Portal_" then
		return name:sub(8)
	end
	return nil
end

function GateController:Init()
	BaseController.Init(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gate")
	self._remotes = {
		RequestOpen = remotesFolder:WaitForChild("RequestOpen"),
	}

	local GateConfirmUI = require(StarterGui:WaitForChild("UI"):WaitForChild("GateConfirm"))
	self._ui = GateConfirmUI.new()
	self._activeGateId = nil
end

function GateController:Start()
	BaseController.Start(self)

	-- Wire up confirm/cancel events
	self._ui.Confirmed.Event:Connect(function(gateId)
		self:_requestOpen(gateId)
	end)

	-- Scan existing portals + listen for new ones
	self:_scanPortals()
	workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") and desc.Name == "GatePrompt" then
			self:_wirePrompt(desc)
		end
	end)
end

function GateController:_scanPortals()
	for _, folder in ipairs(workspace:GetChildren()) do
		if folder:IsA("Folder") and folder.Name:sub(1, 7) == "Portal_" then
			for _, desc in ipairs(folder:GetDescendants()) do
				if desc:IsA("ProximityPrompt") and desc.Name == "GatePrompt" then
					self:_wirePrompt(desc)
				end
			end
		end
	end
end

function GateController:_wirePrompt(prompt)
	prompt.Triggered:Connect(function(player)
		if player ~= Players.LocalPlayer then return end

		-- Cari gateId dari parent folder
		local parent = prompt.Parent
		while parent and parent ~= workspace do
			local gateId = gateIdFromFolder(parent)
			if gateId then
				self:_showConfirm(gateId)
				return
			end
			parent = parent.Parent
		end
	end)
end

function GateController:_showConfirm(gateId)
	if self._activeGateId then return end -- sudah ada dialog aktif
	self._activeGateId = gateId

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	self._ui:Show(playerGui, gateId)

	-- Auto-cancel setelah 15 detik kalau tidak ada aksi
	task.delay(15, function()
		if self._activeGateId == gateId then
			self._ui:Hide()
			self._activeGateId = nil
		end
	end)

	-- Reset active saat cancel
	self._ui.Cancelled.Event:Connect(function(cancelledId)
		if cancelledId == gateId then
			self._activeGateId = nil
		end
	end)
end

function GateController:_requestOpen(gateId)
	local ok, result = pcall(function()
		return self._remotes.RequestOpen:InvokeServer(gateId)
	end)

	if ok and result and result.success then
		self._activeGateId = nil
		-- TODO: play teleport effect (fade to white/portal color, lalu teleport)
		-- Untuk sekarang, langsung teleport via MoveTo
		self:_teleportToZone(result.destination, gateId)
	elseif ok and result then
		-- Tampilkan reason gagal
		self:_showConfirm(gateId) -- re-show dengan status error
		warn("[Gate] Gagal:", result.reason)
		-- TODO: tampilkan error di UI
	else
		warn("[Gate] Remote error:", tostring(result))
		self._activeGateId = nil
	end
end

function GateController:_teleportToZone(destination, gateId)
	-- Untuk MVP: teleport ke SpawnLocation yang sesuai dengan nama zona
	-- Di production, ini akan pakai Reserved Server / TeleportService
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Cari spawn point di workspace (untuk single-place MVP)
	local spawnPoint = workspace:FindFirstChild("Spawn_" .. destination)
	if spawnPoint and spawnPoint:IsA("BasePart") then
		hrp.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)
	else
		-- Fallback: teleport ke posisi gate tujuan (kalau ada portal di zona itu)
		for gateId2, data in pairs(GatesConfig) do
			if data.destinationZone == destination then
				-- Teleport ke posisi portal itu
				hrp.CFrame = CFrame.new(data.worldPosition + Vector3.new(0, 3, 10))
				break
			end
		end
	end
end

return GateController
