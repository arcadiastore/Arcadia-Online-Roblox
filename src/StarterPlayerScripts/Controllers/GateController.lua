--[[
	GateController.lua
	Client-side controller untuk Gate/Portal system.
	Listen ProximityPrompt di setiap portal → tampilkan GateConfirm UI →
	kalau player confirm, invoke Gate/RequestOpen remote.

	Anti-cheat: semua validasi syarat di server. Client hanya trigger UI.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ControllersFolder = script.Parent
local BaseController = require(ControllersFolder:WaitForChild("BaseController"))

local GateController = BaseController:Extend("GateController")

function GateController:Init()
	BaseController.Init(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Gate")
	self._requestOpen = remotesFolder:WaitForChild("RequestOpen")

	local GateConfirmUI = require(ReplicatedStorage:WaitForChild("Configs").Parent
		:WaitForChild("StarterGui") and nil or nil) -- placeholder, load below

	-- Load UI module from StarterGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local uiFolder = playerGui:WaitForChild("UI", 10)
	if uiFolder then
		local confirmModule = uiFolder:FindFirstChild("GateConfirm")
		if confirmModule then
			self._confirmUI = require(confirmModule).new()
		end
	end

	-- If UI not found in PlayerGui, try loading from StarterGui
	if not self._confirmUI then
		local StarterGui = game:GetService("StarterGui")
		local sgUi = StarterGui:WaitForChild("UI", 10)
		if sgUi then
			local confirmModule = sgUi:FindFirstChild("GateConfirm")
			if confirmModule then
				self._confirmUI = require(confirmModule).new()
			end
		end
	end

	-- Store pending gateId for confirm flow
	self._pendingGateId = nil
end

function GateController:Start()
	BaseController.Start(self)

	-- Wire up confirm UI events
	if self._confirmUI then
		self._confirmUI.Confirmed.Event:Connect(function(gateId)
			self:_onConfirm(gateId)
		end)
		self._confirmUI.Cancelled.Event:Connect(function(gateId)
			-- Do nothing, UI already hidden
		end)
	end

	-- Listen for ProximityPrompt triggers on portal bases
	-- We use workspace.DescendantAdded for dynamically spawned portals
	self:_wireExistingPrompts()
	workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") and desc.Name == "GatePrompt" then
			self:_wirePrompt(desc)
		end
	end)
end

function GateController:_wireExistingPrompts()
	local portalsFolder = workspace:FindFirstChild("GatePortals")
	if not portalsFolder then return end

	for _, portalFolder in ipairs(portalsFolder:GetChildren()) do
		local base = portalFolder:FindFirstChild("Base")
		if base then
			local prompt = base:FindFirstChild("GatePrompt")
			if prompt then
				self:_wirePrompt(prompt)
			end
		end
	end
end

function GateController:_wirePrompt(prompt)
	prompt.Triggered:Connect(function(player)
		if player ~= Players.LocalPlayer then return end

		-- Extract gateId from portal folder name: "Portal_Gate_Duskwood" → "Gate_Duskwood"
		local base = prompt.Parent
		local folder = base and base.Parent
		if not folder then return end

		local gateId = folder.Name:gsub("^Portal_", "")
		self:_showConfirm(gateId)
	end)
end

function GateController:_showConfirm(gateId)
	if not self._confirmUI then
		warn("[GateController] GateConfirmUI not loaded")
		return
	end

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	self._pendingGateId = gateId
	self._confirmUI:Show(playerGui, gateId)
end

function GateController:_onConfirm(gateId)
	local ok, result = pcall(function()
		return self._requestOpen:InvokeServer(gateId)
	end)

	if not ok then
		warn("[GateController] RequestOpen error:", result)
		return
	end

	if result and result.success then
		-- Teleport success — server handles actual teleport
		-- Client just shows feedback (could add screen flash, etc.)
		print("[GateController] Gate opened:", result.destination)
	else
		warn("[GateController] Gate denied:", result and result.reason)
		-- Show error in UI
		if self._confirmUI then
			self._confirmUI:Hide()
		end
	end

	self._pendingGateId = nil
end

return GateController
