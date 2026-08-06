--[[
	GateConfirm/init.lua
	UI konfirmasi gate/portal. Muncul saat pemain mendekati portal
	(dipicu oleh ProximityPrompt). Menampilkan:
	  - Nama gate
	  - Zona tujuan
	  - Syarat (level, quest, item) — hijau/merah
	  - Tombol Confirm / Cancel

	Dipakai oleh: StarterPlayerScripts/Controllers/GateController.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GatesConfig = require(ReplicatedStorage.Configs.Gates)

local GateConfirmUI = {}
GateConfirmUI.__index = GateConfirmUI

local PALETTE = {
	Overlay = Color3.fromRGB(8, 9, 18),
 Panel = Color3.fromRGB(20, 22, 38),
	Portal = Color3.fromRGB(124, 92, 255),
 Gold = Color3.fromRGB(232, 186, 94),
	TextPrimary = Color3.fromRGB(240, 238, 250),
	TextMuted = Color3.fromRGB(146, 148, 172),
	Positive = Color3.fromRGB(110, 224, 148),
 Negative = Color3.fromRGB(232, 108, 108),
	PanelLight = Color3.fromRGB(28, 31, 52),
}

local FONT_TITLE = Enum.Font.GothamBlack
local FONT_HEADING = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.Gotham

local function tween(instance, props, duration)
	local t = TweenService:Create(instance, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function GateConfirmUI.new()
	local self = setmetatable({}, GateConfirmUI)
	self._gui = nil
	self.Confirmed = Instance.new("BindableEvent")
	self.Cancelled = Instance.new("BindableEvent")
	return self
end

function GateConfirmUI:Show(playerGui, gateId)
	if self._gui then self._gui:Destroy() end

	local gateData = GatesConfig[gateId]
	if not gateData then return end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GateConfirmGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 60
	screenGui.Parent = playerGui
	self._gui = screenGui

	-- Overlay (semi-transparent)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = PALETTE.Overlay
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Card
	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0, 360, 0, 280)
	card.BackgroundColor3 = PALETTE.Panel
	card.Parent = overlay
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = PALETTE.Portal
	stroke.Thickness = 1.5
	stroke.Transparency = 0.2
	stroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 24)
	pad.PaddingRight = UDim.new(0, 24)
	pad.PaddingTop = UDim.new(0, 20)
	pad.PaddingBottom = UDim.new(0, 20)
	pad.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = card

	-- Title
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Font = FONT_TITLE
	title.Text = gateData.displayName
	title.TextColor3 = PALETTE.Gold
	title.TextSize = 22
	title.Size = UDim2.new(1, 0, 0, 30)
	title.LayoutOrder = 1
	title.Parent = card

	-- Destination
	local dest = Instance.new("TextLabel")
	dest.BackgroundTransparency = 1
	dest.Font = FONT_BODY
	dest.Text = "✦ " .. gateData.destinationZone
	dest.TextColor3 = PALETTE.Portal
	dest.TextSize = 15
	dest.Size = UDim2.new(1, 0, 0, 20)
	dest.LayoutOrder = 2
	dest.Parent = card

	-- Separator
	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = PALETTE.PanelLight
	sep.BorderSizePixel = 0
 sep.Size = UDim2.new(0.8, 0, 0, 1)
 sep.LayoutOrder = 3
	sep.Parent = card

	-- Requirements
	local req = gateData.requirement
	if req then
		local reqTitle = Instance.new("TextLabel")
		reqTitle.BackgroundTransparency = 1
		reqTitle.Font = FONT_HEADING
		reqTitle.Text = "Requirements:"
		reqTitle.TextColor3 = PALETTE.TextMuted
		reqTitle.TextSize = 12
		reqTitle.Size = UDim2.new(1, 0, 0, 16)
		reqTitle.LayoutOrder = 4
		reqTitle.TextXAlignment = Enum.TextXAlignment.Left
		reqTitle.Parent = card

		if req.type == "Level" or req.type == "LevelAndQuest" then
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Font = FONT_BODY
			lbl.Text = "  • Level " .. req.level
			lbl.TextColor3 = PALETTE.TextPrimary
			lbl.TextSize = 13
			lbl.Size = UDim2.new(1, 0, 0, 18)
			lbl.LayoutOrder = 5
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = card
		end

		if req.type == "Quest" or req.type == "LevelAndQuest" then
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Font = FONT_BODY
			lbl.Text = "  • Quest: " .. (req.questId or "?")
			lbl.TextColor3 = PALETTE.TextPrimary
			lbl.TextSize = 13
			lbl.Size = UDim2.new(1, 0, 0, 18)
			lbl.LayoutOrder = 6
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = card
		end

		if req.type == "Item" then
			local lbl = Instance.new("TextLabel")
			lbl.BackgroundTransparency = 1
			lbl.Font = FONT_BODY
			lbl.Text = "  • Item: " .. (req.itemId or "?")
			lbl.TextColor3 = PALETTE.TextPrimary
			lbl.TextSize = 13
			lbl.Size = UDim2.new(1, 0, 0, 18)
			lbl.LayoutOrder = 7
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Parent = card
		end
	end

	-- Buttons
	local btnRow = Instance.new("Frame")
	btnRow.BackgroundTransparency = 1
	btnRow.Size = UDim2.new(1, 0, 0, 40)
	btnRow.LayoutOrder = 10
	btnRow.Parent = card
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.Padding = UDim.new(0, 12)
	btnLayout.Parent = btnRow

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.AutoButtonColor = false
	confirmBtn.Font = FONT_HEADING
	confirmBtn.Text = "Enter Gate  ✦"
	confirmBtn.TextColor3 = Color3.fromRGB(30, 22, 8)
	confirmBtn.TextSize = 14
	confirmBtn.BackgroundColor3 = PALETTE.Gold
	confirmBtn.Size = UDim2.new(0, 140, 0, 40)
	confirmBtn.Parent = btnRow
	Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 10)

	confirmBtn.MouseButton1Click:Connect(function()
		self:Hide()
		self.Confirmed:Fire(gateId)
	end)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.AutoButtonColor = false
	cancelBtn.Font = FONT_HEADING
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = PALETTE.TextPrimary
	cancelBtn.TextSize = 14
	cancelBtn.BackgroundColor3 = PALETTE.PanelLight
	cancelBtn.Size = UDim2.new(0, 100, 0, 40)
	cancelBtn.Parent = btnRow
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 10)

	cancelBtn.MouseButton1Click:Connect(function()
		self:Hide()
		self.Cancelled:Fire(gateId)
	end)

	-- Animate in
	card.Size = UDim2.new(0, 0, 0, 0)
	tween(card, { Size = UDim2.new(0, 360, 0, 280) }, 0.25)
end

function GateConfirmUI:Hide()
	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
end

return GateConfirmUI
