--[[
	CharacterCreation/init.lua
	UI presentasi untuk alur pembuatan karakter (Race reveal+reroll → Class
	select). MURNI presentasi & input — tidak ada keputusan gameplay di sini
	(RNG ras, validasi, dsb. semua di CharacterService server-side).

	Dipakai oleh: StarterPlayerScripts/Controllers/CharacterCreationController.lua
	Kontrak data mengikuti ServerScriptService/Services/CharacterService/init.lua:
	  RerollRace  -> { success, raceId, displayName, rarity, statBonus, elementAffinity }
	  ConfirmRace -> { success, reason? }
	  SelectClass -> { success, reason? }
	  CreationStatus -> { hasRace, hasClass }

	Teks nama Ras/Kelas SELALU diambil dari Configs/Races & Configs/Classes
	(displayName), bukan ditulis literal di sini — lihat docs/06_CODING_STANDARDS.md §2.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RacesConfig = require(ReplicatedStorage.Configs.Races)
local ClassesConfig = require(ReplicatedStorage.Configs.Classes)

local CharacterCreationUI = {}
CharacterCreationUI.__index = CharacterCreationUI

-- === Tema visual (Portal / Arcadia) ===

local PALETTE = {
	Void = Color3.fromRGB(8, 9, 18),
	Panel = Color3.fromRGB(20, 22, 38),
	PanelLight = Color3.fromRGB(28, 31, 52),
	Portal = Color3.fromRGB(124, 92, 255),
	Gold = Color3.fromRGB(232, 186, 94),
	TextPrimary = Color3.fromRGB(240, 238, 250),
	TextMuted = Color3.fromRGB(146, 148, 172),
	Common = Color3.fromRGB(163, 172, 199),
	Rare = Color3.fromRGB(255, 201, 92),
	Positive = Color3.fromRGB(110, 224, 148),
	Negative = Color3.fromRGB(232, 108, 108),
	Neutral = Color3.fromRGB(150, 152, 170),
	Danger = Color3.fromRGB(235, 96, 96),
}

-- Warna orb per Ras — murni presentasi (bukan data gameplay), tidak overlap
-- dengan Configs/Races.lua yang tetap jadi source of truth data ras.
local RACE_ORB_COLOR = {
	Human = Color3.fromRGB(196, 150, 96),
	Elf = Color3.fromRGB(108, 214, 148),
	Dwarf = Color3.fromRGB(200, 132, 76),
	Angel = Color3.fromRGB(255, 236, 178),
	Evil = Color3.fromRGB(168, 62, 214),
}

local ROLE_LABEL = {
	MeleeDPS = "Melee DPS",
	Tank = "Tank",
	MagicDPS = "Magic DPS",
	Support = "Support",
	RangedDPS = "Ranged DPS",
}

local ROLE_ICON = {
	MeleeDPS = "⚔",
	Tank = "🛡",
	MagicDPS = "✦",
	Support = "✚",
	RangedDPS = "➹",
}

local STAT_ORDER = { "STR", "VIT", "INT", "AGI", "LUK" }

local FONT_TITLE = Enum.Font.GothamBlack
local FONT_HEADING = Enum.Font.GothamBold
local FONT_BODY = Enum.Font.Gotham

-- === Util kecil ===

local function tween(instance, props, duration, style)
	local info = TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local t = TweenService:Create(instance, info, props)
	t:Play()
	return t
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or PALETTE.Portal
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function pad(parent, x, y)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, x)
	p.PaddingRight = UDim.new(0, x)
	p.PaddingTop = UDim.new(0, y)
	p.PaddingBottom = UDim.new(0, y)
	p.Parent = parent
	return p
end

local function newLabel(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = props.Font or FONT_BODY
	l.Text = props.Text or ""
	l.TextColor3 = props.TextColor3 or PALETTE.TextPrimary
	l.TextSize = props.TextSize or 16
	l.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
	l.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
	l.Size = props.Size or UDim2.new(1, 0, 0, 24)
	if props.Position then l.Position = props.Position end
	if props.AnchorPoint then l.AnchorPoint = props.AnchorPoint end
	l.TextWrapped = props.TextWrapped
	l.RichText = props.RichText
	l.LayoutOrder = props.LayoutOrder or 0
	l.Parent = props.Parent
	return l
end

local function newButton(props)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Font = props.Font or FONT_HEADING
	b.Text = props.Text or ""
	b.TextColor3 = props.TextColor3 or PALETTE.TextPrimary
	b.TextSize = props.TextSize or 16
	b.BackgroundColor3 = props.BackgroundColor3 or PALETTE.PanelLight
	b.BackgroundTransparency = props.BackgroundTransparency or 0
	b.Size = props.Size or UDim2.new(0, 160, 0, 44)
	b.LayoutOrder = props.LayoutOrder or 0
	b.Parent = props.Parent
	corner(b, props.Radius or 10)
	return b
end

-- Hover/press feedback generik untuk tombol.
local function wireButtonFeedback(button, baseColor, hoverColor)
	button.MouseEnter:Connect(function()
		if button.Active == false then return end
		tween(button, { BackgroundColor3 = hoverColor }, 0.12)
	end)
	button.MouseLeave:Connect(function()
		if button.Active == false then return end
		tween(button, { BackgroundColor3 = baseColor }, 0.15)
	end)
end

-- === Konstruksi ===

function CharacterCreationUI.new()
	local self = setmetatable({}, CharacterCreationUI)

	self._gui = nil
	self._selectedClassId = nil
	self._currentRaceId = nil
	self._classButtons = {}

	self.RerollRequested = Instance.new("BindableEvent")
	self.ConfirmRaceRequested = Instance.new("BindableEvent")
	self.ClassSelected = Instance.new("BindableEvent")
	self.BeginJourneyRequested = Instance.new("BindableEvent")

	return self
end

function CharacterCreationUI:Mount(playerGui)
	if self._gui then
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CharacterCreationGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui
	self._gui = screenGui

	-- Root: menutup seluruh layar (pembuatan karakter wajib sebelum aktivitas lain)
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = PALETTE.Void
	root.BorderSizePixel = 0
	root.Parent = screenGui
	self._root = root

	local bgGradient = Instance.new("UIGradient")
	bgGradient.Rotation = 90
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 12, 26)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 12)),
	})
	bgGradient.Parent = root

	-- Ambient portal glow di belakang judul (dibuat dari Frame bundar, bukan asset gambar)
	local glow = Instance.new("Frame")
	glow.Name = "PortalGlow"
	glow.AnchorPoint = Vector2.new(0.5, 0)
	glow.Position = UDim2.new(0.5, 0, 0, -180)
	glow.Size = UDim2.new(0, 620, 0, 620)
	glow.BackgroundColor3 = PALETTE.Portal
	glow.BackgroundTransparency = 0.88
	glow.BorderSizePixel = 0
	glow.ZIndex = 0
	glow.Parent = root
	corner(glow, 310)

	-- === Header ===
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 110)
	header.Position = UDim2.new(0, 0, 0, 28)
	header.Parent = root

	newLabel({
		Parent = header,
		Text = "A R C A D I A   O N L I N E",
		Font = FONT_TITLE,
		TextSize = 34,
		TextColor3 = PALETTE.Gold,
		Size = UDim2.new(1, 0, 0, 44),
	})

	self._stepLabel = newLabel({
		Parent = header,
		Text = "Step 1 — The Portal Reveals Your Origin",
		Font = FONT_BODY,
		TextSize = 16,
		TextColor3 = PALETTE.TextMuted,
		Size = UDim2.new(1, 0, 0, 26),
		Position = UDim2.new(0, 0, 0, 48),
	})

	-- Step dots
	local dotsHolder = Instance.new("Frame")
	dotsHolder.BackgroundTransparency = 1
	dotsHolder.Size = UDim2.new(0, 60, 0, 10)
	dotsHolder.Position = UDim2.new(0.5, 0, 0, 84)
	dotsHolder.AnchorPoint = Vector2.new(0.5, 0)
	dotsHolder.Parent = header
	local dotsLayout = Instance.new("UIListLayout")
	dotsLayout.FillDirection = Enum.FillDirection.Horizontal
	dotsLayout.Padding = UDim.new(0, 10)
	dotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dotsLayout.Parent = dotsHolder

	self._dot1 = Instance.new("Frame")
	self._dot1.Size = UDim2.new(0, 22, 0, 6)
	self._dot1.BackgroundColor3 = PALETTE.Gold
	self._dot1.BorderSizePixel = 0
	self._dot1.Parent = dotsHolder
	corner(self._dot1, 3)

	self._dot2 = Instance.new("Frame")
	self._dot2.Size = UDim2.new(0, 22, 0, 6)
	self._dot2.BackgroundColor3 = PALETTE.PanelLight
	self._dot2.BorderSizePixel = 0
	self._dot2.Parent = dotsHolder
	corner(self._dot2, 3)

	-- === Pages container ===
	local pages = Instance.new("Frame")
	pages.Name = "Pages"
	pages.BackgroundTransparency = 1
	pages.Size = UDim2.new(1, 0, 1, -170)
	pages.Position = UDim2.new(0, 0, 0, 160)
	pages.Parent = root
	self._pages = pages

	self:_buildRacePage(pages)
	self:_buildClassPage(pages)

	self._classPage.Visible = false

	return self
end

-- === Halaman 1: Race Reveal ===

function CharacterCreationUI:_buildRacePage(parent)
	local page = Instance.new("Frame")
	page.Name = "RacePage"
	page.BackgroundTransparency = 1
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Parent = parent
	self._racePage = page

	local card = Instance.new("Frame")
	card.Name = "RevealCard"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, 0)
	card.Size = UDim2.new(0, 420, 0, 470)
	card.BackgroundColor3 = PALETTE.Panel
	card.Parent = page
	corner(card, 20)
	local cardStroke = stroke(card, PALETTE.Common, 1.5, 0.35)
	self._raceCardStroke = cardStroke
	pad(card, 28, 24)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = card

	self._rarityTag = newLabel({
		Parent = card,
		Text = "COMMON",
		Font = FONT_HEADING,
		TextSize = 13,
		TextColor3 = PALETTE.Common,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 1,
	})

	local orbHolder = Instance.new("Frame")
	orbHolder.BackgroundTransparency = 1
	orbHolder.Size = UDim2.new(0, 120, 0, 120)
	orbHolder.LayoutOrder = 2
	orbHolder.Parent = card

	self._orb = Instance.new("Frame")
	self._orb.AnchorPoint = Vector2.new(0.5, 0.5)
	self._orb.Position = UDim2.new(0.5, 0, 0.5, 0)
	self._orb.Size = UDim2.new(1, 0, 1, 0)
	self._orb.BackgroundColor3 = RACE_ORB_COLOR.Human
	self._orb.Parent = orbHolder
	corner(self._orb, 60)
	self._orbStroke = stroke(self._orb, PALETTE.Gold, 3, 0.2)
	local orbGradient = Instance.new("UIGradient")
	orbGradient.Rotation = 90
	orbGradient.Parent = self._orb

	self._orbInitial = newLabel({
		Parent = self._orb,
		Text = "H",
		Font = FONT_TITLE,
		TextSize = 44,
		TextColor3 = Color3.fromRGB(20, 18, 16),
		Size = UDim2.new(1, 0, 1, 0),
	})

	self._raceName = newLabel({
		Parent = card,
		Text = "—",
		Font = FONT_TITLE,
		TextSize = 26,
		TextColor3 = PALETTE.TextPrimary,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 3,
	})

	self._affinityTag = newLabel({
		Parent = card,
		Text = "",
		Font = FONT_BODY,
		TextSize = 13,
		TextColor3 = PALETTE.TextMuted,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 4,
	})

	-- Stat row
	local statRow = Instance.new("Frame")
	statRow.BackgroundTransparency = 1
	statRow.Size = UDim2.new(1, 0, 0, 64)
	statRow.LayoutOrder = 5
	statRow.Parent = card
	local statLayout = Instance.new("UIListLayout")
	statLayout.FillDirection = Enum.FillDirection.Horizontal
	statLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statLayout.Padding = UDim.new(0, 8)
	statLayout.Parent = statRow

	self._statPills = {}
	for _, statId in ipairs(STAT_ORDER) do
		local pill = Instance.new("Frame")
		pill.Size = UDim2.new(0, 62, 0, 64)
		pill.BackgroundColor3 = PALETTE.PanelLight
		pill.Parent = statRow
		corner(pill, 10)

		newLabel({
			Parent = pill,
			Text = statId,
			Font = FONT_BODY,
			TextSize = 12,
			TextColor3 = PALETTE.TextMuted,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 0, 8),
		})

		local valueLabel = newLabel({
			Parent = pill,
			Text = "+0",
			Font = FONT_HEADING,
			TextSize = 16,
			TextColor3 = PALETTE.Neutral,
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 28),
		})
		self._statPills[statId] = valueLabel
	end

	self._raceNotice = newLabel({
		Parent = card,
		Text = "",
		Font = FONT_BODY,
		TextSize = 13,
		TextColor3 = PALETTE.Danger,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 6,
		TextWrapped = true,
	})

	-- Tombol
	local buttonRow = Instance.new("Frame")
	buttonRow.BackgroundTransparency = 1
	buttonRow.Size = UDim2.new(1, 0, 0, 48)
	buttonRow.LayoutOrder = 7
	buttonRow.Parent = card
	local btnLayout = Instance.new("UIListLayout")
	btnLayout.FillDirection = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.Padding = UDim.new(0, 12)
	btnLayout.Parent = buttonRow

	self._rerollButton = newButton({
		Parent = buttonRow,
		Text = "🎲  Reroll",
		Size = UDim2.new(0, 150, 0, 48),
		BackgroundColor3 = PALETTE.PanelLight,
		TextColor3 = PALETTE.TextPrimary,
		TextSize = 15,
	})
	stroke(self._rerollButton, PALETTE.Common, 1, 0.4)
	wireButtonFeedback(self._rerollButton, PALETTE.PanelLight, Color3.fromRGB(40, 44, 68))
	self._rerollButton.MouseButton1Click:Connect(function()
		self.RerollRequested:Fire()
	end)

	self._confirmRaceButton = newButton({
		Parent = buttonRow,
		Text = "Confirm Race  ✓",
		Size = UDim2.new(0, 190, 0, 48),
		BackgroundColor3 = PALETTE.Gold,
		TextColor3 = Color3.fromRGB(30, 22, 8),
		TextSize = 15,
	})
	wireButtonFeedback(self._confirmRaceButton, PALETTE.Gold, Color3.fromRGB(250, 205, 120))
	self._confirmRaceButton.MouseButton1Click:Connect(function()
		if self._currentRaceId then
			self.ConfirmRaceRequested:Fire(self._currentRaceId)
		end
	end)
end

-- === Halaman 2: Class Select ===

function CharacterCreationUI:_buildClassPage(parent)
	local page = Instance.new("Frame")
	page.Name = "ClassPage"
	page.BackgroundTransparency = 1
	page.Size = UDim2.new(1, 0, 1, 0)
	page.Parent = parent
	self._classPage = page

	local subtitle = newLabel({
		Parent = page,
		Text = "Choose the path your Hero will walk",
		Font = FONT_BODY,
		TextSize = 15,
		TextColor3 = PALETTE.TextMuted,
		Size = UDim2.new(1, 0, 0, 22),
	})
	subtitle.Position = UDim2.new(0, 0, 0, 0)

	local grid = Instance.new("Frame")
	grid.Name = "ClassGrid"
	grid.AnchorPoint = Vector2.new(0.5, 0)
	grid.Position = UDim2.new(0.5, 0, 0, 34)
	grid.Size = UDim2.new(0, 700, 0, 300)
	grid.BackgroundTransparency = 1
	grid.Parent = page

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 224, 0, 140)
	gridLayout.CellPadding = UDim2.new(0, 14, 0, 14)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = grid

	-- Kumpulkan Tier 1 (starting class) dari Configs/Classes.lua — urut nama biar stabil
	local tier1Ids = {}
	for classId, data in pairs(ClassesConfig) do
		if data.tier == 1 then
			table.insert(tier1Ids, classId)
		end
	end
	table.sort(tier1Ids)

	for i, classId in ipairs(tier1Ids) do
		self:_createClassCard(grid, classId, ClassesConfig[classId], i)
	end

	self._classNotice = newLabel({
		Parent = page,
		Text = "",
		Font = FONT_BODY,
		TextSize = 13,
		TextColor3 = PALETTE.Danger,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.new(0, 0, 0, 344),
	})

	self._beginButton = newButton({
		Parent = page,
		Text = "Begin Journey  ✦",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 372),
		Size = UDim2.new(0, 260, 0, 52),
		BackgroundColor3 = PALETTE.Gold,
		TextColor3 = Color3.fromRGB(30, 22, 8),
		TextSize = 16,
	})
	self._beginButton.Position = UDim2.new(0.5, 0, 0, 372)
	self._beginButton.AnchorPoint = Vector2.new(0.5, 0)
	self:_setBeginEnabled(false)
	self._beginButton.MouseButton1Click:Connect(function()
		if self._selectedClassId then
			self.BeginJourneyRequested:Fire(self._selectedClassId)
		end
	end)
end

function CharacterCreationUI:_createClassCard(parent, classId, data, order)
	local card = newButton({
		Parent = parent,
		Text = "",
		Size = UDim2.new(0, 224, 0, 140),
		BackgroundColor3 = PALETTE.Panel,
		Radius = 14,
	})
	card.LayoutOrder = order
	local cardStroke = stroke(card, PALETTE.Common, 1.25, 0.45)
	pad(card, 16, 14)

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.Parent = card

	local icon = ROLE_ICON[data.role] or "★"
	newLabel({
		Parent = card,
		Text = icon .. "  " .. data.displayName,
		Font = FONT_HEADING,
		TextSize = 18,
		TextColor3 = PALETTE.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 24),
	})

	newLabel({
		Parent = card,
		Text = ROLE_LABEL[data.role] or data.role,
		Font = FONT_BODY,
		TextSize = 13,
		TextColor3 = PALETTE.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 18),
	})

	newLabel({
		Parent = card,
		Text = "Weapon: " .. table.concat(data.weaponTypes, " / "),
		Font = FONT_BODY,
		TextSize = 12,
		TextColor3 = PALETTE.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 30),
		TextWrapped = true,
	})

	newLabel({
		Parent = card,
		Text = "Tier 1 · Starting Class",
		Font = FONT_BODY,
		TextSize = 11,
		TextColor3 = PALETTE.Neutral,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 16),
	})

	wireButtonFeedback(card, PALETTE.Panel, PALETTE.PanelLight)

	card.MouseButton1Click:Connect(function()
		self:_selectClassCard(classId)
		self.ClassSelected:Fire(classId)
	end)

	self._classButtons[classId] = { button = card, stroke = cardStroke }
end

function CharacterCreationUI:_selectClassCard(classId)
	self._selectedClassId = classId
	for id, entry in pairs(self._classButtons) do
		if id == classId then
			entry.stroke.Color = PALETTE.Gold
			entry.stroke.Thickness = 2
			entry.stroke.Transparency = 0
			tween(entry.button, { BackgroundColor3 = Color3.fromRGB(38, 33, 18) }, 0.15)
		else
			entry.stroke.Color = PALETTE.Common
			entry.stroke.Thickness = 1.25
			entry.stroke.Transparency = 0.45
			tween(entry.button, { BackgroundColor3 = PALETTE.Panel }, 0.15)
		end
	end
	self:_setBeginEnabled(true)
end

function CharacterCreationUI:_setBeginEnabled(enabled)
	self._beginButton.Active = enabled
	self._beginButton.AutoButtonColor = false
	tween(self._beginButton, {
		BackgroundColor3 = enabled and PALETTE.Gold or PALETTE.PanelLight,
	}, 0.15)
	self._beginButton.TextColor3 = enabled and Color3.fromRGB(30, 22, 8) or PALETTE.TextMuted
end

-- === API publik dipakai Controller ===

-- Tampilkan hasil roll ras (dari RerollRace remote). Termasuk animasi reveal.
function CharacterCreationUI:ShowRaceReveal(raceInfo)
	self._currentRaceId = raceInfo.raceId
	self._raceNotice.Text = ""

	local isRare = raceInfo.rarity == "Rare"
	self._rarityTag.Text = string.upper(raceInfo.rarity or "COMMON")
	self._rarityTag.TextColor3 = isRare and PALETTE.Rare or PALETTE.Common

	self._raceName.Text = raceInfo.displayName or raceInfo.raceId
	self._orbInitial.Text = string.sub(raceInfo.displayName or "?", 1, 1)

	local orbColor = RACE_ORB_COLOR[raceInfo.raceId] or PALETTE.Portal
	tween(self._orb, { BackgroundColor3 = orbColor }, 0.25)
	tween(self._orbStroke, { Color = isRare and PALETTE.Rare or PALETTE.Common }, 0.25)
	tween(self._raceCardStroke, {
		Color = isRare and PALETTE.Rare or PALETTE.Common,
		Transparency = isRare and 0.05 or 0.35,
	}, 0.25)

	if raceInfo.elementAffinity then
		self._affinityTag.Text = "✦ " .. raceInfo.elementAffinity .. " Affinity"
	else
		self._affinityTag.Text = ""
	end

	for _, statId in ipairs(STAT_ORDER) do
		local bonus = (raceInfo.statBonus and raceInfo.statBonus[statId]) or 0
		local pill = self._statPills[statId]
		pill.Text = (bonus >= 0 and "+" or "") .. tostring(bonus)
		if bonus > 0 then
			pill.TextColor3 = PALETTE.Positive
		elseif bonus < 0 then
			pill.TextColor3 = PALETTE.Negative
		else
			pill.TextColor3 = PALETTE.Neutral
		end
	end

	-- Reveal pop animation
	self._orb.Size = UDim2.new(0.7, 0, 0.7, 0)
	tween(self._orb, { Size = UDim2.new(1, 0, 1, 0) }, 0.25, Enum.EasingStyle.Back)

	if isRare then
		local original = self._orbStroke.Thickness
		self._orbStroke.Thickness = 6
		tween(self._orbStroke, { Thickness = original }, 0.4)
	end
end

function CharacterCreationUI:SetRaceLoading(isLoading)
	self._rerollButton.Active = not isLoading
	self._confirmRaceButton.Active = not isLoading
	self._rerollButton.Text = isLoading and "Rolling…" or "🎲  Reroll"
end

function CharacterCreationUI:ShowRaceError(message)
	self._raceNotice.Text = message or ""
end

function CharacterCreationUI:ShowClassError(message)
	self._classNotice.Text = message or ""
end

function CharacterCreationUI:SetClassLoading(isLoading)
	self._beginButton.Active = not isLoading and self._selectedClassId ~= nil
	for _, entry in pairs(self._classButtons) do
		entry.button.Active = not isLoading
	end
end

-- Pindah dari Race page ke Class page (dipanggil setelah ConfirmRace sukses).
function CharacterCreationUI:GoToClassStep()
	self._stepLabel.Text = "Step 2 — Choose Your Class"
	tween(self._dot1, { BackgroundColor3 = PALETTE.PanelLight }, 0.2)
	tween(self._dot2, { BackgroundColor3 = PALETTE.Gold }, 0.2)

	self._racePage.Visible = false
	self._classPage.Visible = true
	self._classPage.Position = UDim2.new(0, 0, 0, 12)
	tween(self._classPage, { Position = UDim2.new(0, 0, 0, 0) }, 0.22, Enum.EasingStyle.Quad)
end

-- Langsung buka di step Class (dipakai kalau CreationStatus bilang hasRace = true).
function CharacterCreationUI:SkipToClassStep()
	self._stepLabel.Text = "Step 2 — Choose Your Class"
	self._dot1.BackgroundColor3 = PALETTE.PanelLight
	self._dot2.BackgroundColor3 = PALETTE.Gold
	self._racePage.Visible = false
	self._classPage.Visible = true
end

-- Karakter selesai dibuat — tutup UI dengan fade.
function CharacterCreationUI:PlayOutro(onComplete)
	local t = tween(self._root, { BackgroundTransparency = 1 }, 0.4)
	for _, child in ipairs(self._root:GetDescendants()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			tween(child, { TextTransparency = 1 }, 0.3)
		end
		if child:IsA("Frame") then
			pcall(function()
				tween(child, { BackgroundTransparency = 1 }, 0.3)
			end)
		end
	end
	task.delay(0.42, function()
		if onComplete then
			onComplete()
		end
		self:Destroy()
	end)
end

function CharacterCreationUI:Destroy()
	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
end

return CharacterCreationUI
