--[[
	DungeonController.lua
	Client-side Dungeon controller — lobby UI + status panel.

	Flow:
	  1. DungeonLobbyScreen → daftar dungeon, requirements, tombol Enter
	  2. EnterDungeon → server validasi → masuk dungeon
	  3. DungeonStatusScreen → wave progress, alive enemies, timer
	  4. Complete → rewards popup
	  5. Leave → keluar dungeon

	Architecture: BaseController pattern (Init → Start)

	Dependency: BaseController, ReplicatedStorage.Remotes.Dungeon
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BaseController = require(script.Parent:WaitForChild("BaseController"))

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

local DungeonController = BaseController:Extend("DungeonController")

function DungeonController:Init()
	BaseController.Init(self)

	-- Remotes
	local remotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Dungeon")
	self._remoteEnter = remotes:WaitForChild("Enter")
	self._remoteStatus = remotes:WaitForChild("GetStatus")
	self._remoteLeave = remotes:WaitForChild("Leave")

	-- State
	self._inDungeon = false
	self._currentStatus = nil

	-- Buat UI
	self:_buildLobbyUI()
	self:_buildStatusUI()
	self:_buildRewardsUI()
end

function DungeonController:Start()
	BaseController.Start(self)

	-- Poll status saat di dungeon
	task.spawn(function()
		while true do
			task.wait(2)
			if self._inDungeon then
				local ok, result = pcall(function()
					return self._remoteStatus:InvokeServer()
				end)
				if ok and result and result.success then
					self:_updateStatus(result)
				end
			end
		end
	end)

	-- Hubungkan lobby buttons
	self:_connectLobbyButtons()

	-- Leave button
	self._leaveBtn.Activated:Connect(function()
		print("[DungeonController] Leave clicked")
		local ok, result = pcall(function()
			return self._remoteLeave:InvokeServer()
		end)
		print("[DungeonController] Leave result:", ok, result)
		self._statusScreen.Enabled = false
		self._inDungeon = false
	end)

	-- Hotkey: L buka/tutup lobby
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.L then
			self._lobbyScreen.Enabled = not self._lobbyScreen.Enabled
			print("[DungeonController] Lobby toggled:", self._lobbyScreen.Enabled)
		end
	end)
end

-- ==========================================
-- LOBBY UI
-- ==========================================

function DungeonController:_buildLobbyUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "DungeonLobbyScreen"
	screen.ResetOnSpawn = false
	screen.Enabled = false
	screen.Parent = PLAYER_GUI
	self._lobbyScreen = screen

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel = 0
	bg.Parent = screen

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 500, 0, 450)
	panel.Position = UDim2.new(0.5, -250, 0.5, -225)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	panel.BorderSizePixel = 0
	panel.Parent = bg
	self:_addCorner(panel, 12)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
	title.BackgroundTransparency = 0.1
	title.BorderSizePixel = 0
	title.Text = "⚔️ DUNGEON LIST"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 22
	title.Font = Enum.Font.GothamBlack
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -45, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.BackgroundTransparency = 0.2
	closeBtn.BorderSizePixel = 0
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.Parent = panel
	self:_addCorner(closeBtn, 8)

	closeBtn.Activated:Connect(function()
		screen.Enabled = false
	end)

	-- Dungeon cards container
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "DungeonList"
	scroll.Size = UDim2.new(1, -20, 1, -60)
	scroll.Position = UDim2.new(0, 10, 0, 55)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 20)
	scroll.BorderSizePixel = 0
	scroll.Parent = panel
	self._dungeonList = scroll

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	-- Dungeon cards (data-driven)
	local dungeons = {
		{ id = "Dungeon_CorruptedGrove", name = "🌳 Corrupted Grove", req = "Lv15 | Solo", level = 15 },
		{ id = "Dungeon_SunkenCrypt", name = "⚰️ Sunken Crypt", req = "Lv25 | Party 2+", level = 25 },
		{ id = "Dungeon_FrostpeakCavern", name = "❄️ Frostpeak Cavern", req = "Lv30 | Party 2+", level = 30 },
	}

	self._dungeonButtons = {}
	for i, dungeon in ipairs(dungeons) do
		local card = Instance.new("Frame")
		card.Name = "Card_" .. dungeon.id
		card.Size = UDim2.new(1, -10, 0, 70)
		card.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = scroll
		self:_addCorner(card, 8)

		local nameLabel = Instance.new("TextLabel")
	 nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, -10, 0, 30)
		nameLabel.Position = UDim2.new(0, 10, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = dungeon.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
		nameLabel.TextSize = 18
		nameLabel.Font = Enum.Font.GothamBlack
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local reqLabel = Instance.new("TextLabel")
		reqLabel.Name = "Req"
		reqLabel.Size = UDim2.new(1, -10, 0, 20)
		reqLabel.Position = UDim2.new(0, 10, 0, 35)
		reqLabel.BackgroundTransparency = 1
		reqLabel.Text = dungeon.req
		reqLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
		reqLabel.TextSize = 13
		reqLabel.Font = Enum.Font.Gotham
		reqLabel.TextXAlignment = Enum.TextXAlignment.Left
		reqLabel.Parent = card

		local enterBtn = Instance.new("TextButton")
		enterBtn.Name = "Enter"
		enterBtn.Size = UDim2.new(0, 80, 0, 35)
		enterBtn.Position = UDim2.new(1, -90, 0.5, -17)
		enterBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 60)
		enterBtn.BorderSizePixel = 0
		enterBtn.Text = "ENTER"
		enterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		enterBtn.TextSize = 14
		enterBtn.Font = Enum.Font.GothamBlack
		enterBtn.Parent = card
		self:_addCorner(enterBtn, 6)

		self._dungeonButtons[dungeon.id] = enterBtn
	end

	-- Content size
	scroll.CanvasSize = UDim2.new(0, 0, 0, (#dungeons * 78) + 10)
end

function DungeonController:_connectLobbyButtons()
	for dungeonId, btn in pairs(self._dungeonButtons) do
		btn.Activated:Connect(function()
			btn.Text = "..."
			btn.Active = false

			print("[DungeonController] Requesting enter:", dungeonId)

			local ok, result = pcall(function()
				return self._remoteEnter:InvokeServer(dungeonId)
			end)

			print("[DungeonController] Result:", ok, result)

			if ok and result and result.success then
				self._lobbyScreen.Enabled = false
				self:_onDungeonEntered(result)
			else
				btn.Text = "ENTER"
				btn.Active = true
				local reason = "Gagal masuk dungeon"
				if not ok then
					reason = "Error: " .. tostring(result)
				elseif result and result.reason then
					reason = result.reason
				end
				self:_showToast(reason, Color3.fromRGB(200, 60, 60))
			end
		end)
	end
end

-- ==========================================
-- STATUS UI
-- ==========================================

function DungeonController:_buildStatusUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "DungeonStatusScreen"
	screen.ResetOnSpawn = false
	screen.Enabled = false
	screen.Parent = PLAYER_GUI
	self._statusScreen = screen

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 280, 0, 180)
	panel.Position = UDim2.new(0.5, -140, 0, 20)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = screen
	self:_addCorner(panel, 10)
	self._statusPanel = panel

	-- Dungeon name
	local dungeonName = Instance.new("TextLabel")
	dungeonName.Name = "DungeonName"
	dungeonName.Size = UDim2.new(1, 0, 0, 30)
	dungeonName.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
	dungeonName.BackgroundTransparency = 0.2
	dungeonName.BorderSizePixel = 0
	dungeonName.Text = "DUNGEON"
	dungeonName.TextColor3 = Color3.fromRGB(255, 220, 100)
	dungeonName.TextSize = 16
	dungeonName.Font = Enum.Font.GothamBlack
	dungeonName.Parent = panel
	self._dungeonNameLabel = dungeonName

	-- Wave
	local waveLabel = Instance.new("TextLabel")
	waveLabel.Name = "Wave"
	waveLabel.Size = UDim2.new(1, 0, 0, 25)
	waveLabel.Position = UDim2.new(0, 0, 0, 35)
	waveLabel.BackgroundTransparency = 1
	waveLabel.Text = "Wave: 0/0"
	waveLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	waveLabel.TextSize = 16
	waveLabel.Font = Enum.Font.GothamBold
	waveLabel.Parent = panel
	self._waveLabel = waveLabel

	-- Enemies alive
	local enemyLabel = Instance.new("TextLabel")
	enemyLabel.Name = "Enemies"
	enemyLabel.Size = UDim2.new(1, 0, 0, 25)
	enemyLabel.Position = UDim2.new(0, 0, 0, 65)
	enemyLabel.BackgroundTransparency = 1
	enemyLabel.Text = "Enemies: 0"
	enemyLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	enemyLabel.TextSize = 16
	enemyLabel.Font = Enum.Font.GothamBold
	enemyLabel.Parent = panel
	self._enemyLabel = enemyLabel

	-- Timer
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(1, 0, 0, 25)
	timerLabel.Position = UDim2.new(0, 0, 0, 95)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "Time: 0:00"
	timerLabel.TextColor3 = Color3.fromRGB(170, 255, 170)
	timerLabel.TextSize = 16
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Parent = panel
	self._timerLabel = timerLabel

	-- Status
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(1, 0, 0, 25)
	statusLabel.Position = UDim2.new(0, 0, 0, 125)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Status: Active"
	statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	statusLabel.TextSize = 16
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Parent = panel
	self._statusLabel = statusLabel

	-- Leave button
	local leaveBtn = Instance.new("TextButton")
	leaveBtn.Name = "Leave"
	leaveBtn.Size = UDim2.new(0, 120, 0, 30)
	leaveBtn.Position = UDim2.new(0.5, -60, 1, -35)
	leaveBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	leaveBtn.BorderSizePixel = 0
	leaveBtn.Text = "LEAVE"
	leaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	leaveBtn.TextSize = 14
	leaveBtn.Font = Enum.Font.GothamBlack
	leaveBtn.Parent = panel
	self:_addCorner(leaveBtn, 6)
	self._leaveBtn = leaveBtn
end

-- ==========================================
-- REWARDS UI
-- ==========================================

function DungeonController:_buildRewardsUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "DungeonRewardsScreen"
	screen.ResetOnSpawn = false
	screen.Enabled = false
	screen.Parent = PLAYER_GUI
	self._rewardsScreen = screen

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	bg.BackgroundTransparency = 0.4
	bg.BorderSizePixel = 0
	bg.Parent = screen

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 350, 0, 300)
	panel.Position = UDim2.new(0.5, -175, 0.5, -150)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	panel.BorderSizePixel = 0
	panel.Parent = bg
	self:_addCorner(panel, 12)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundColor3 = Color3.fromRGB(80, 130, 60)
	title.BackgroundTransparency = 0.1
	title.BorderSizePixel = 0
	title.Text = "🎉 DUNGEON COMPLETE!"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBlack
	title.Parent = panel

	local rewardsText = Instance.new("TextLabel")
	rewardsText.Name = "Rewards"
	rewardsText.Size = UDim2.new(1, -20, 1, -110)
	rewardsText.Position = UDim2.new(0, 10, 0, 55)
	rewardsText.BackgroundTransparency = 1
	rewardsText.Text = ""
	rewardsText.TextColor3 = Color3.fromRGB(255, 255, 255)
	rewardsText.TextSize = 16
	rewardsText.Font = Enum.Font.Gotham
	rewardsText.TextWrapped = true
	rewardsText.TextYAlignment = Enum.TextYAlignment.Top
	rewardsText.TextXAlignment = Enum.TextXAlignment.Left
	rewardsText.Parent = panel
	self._rewardsText = rewardsText

	local okBtn = Instance.new("TextButton")
	okBtn.Name = "OK"
	okBtn.Size = UDim2.new(0, 120, 0, 35)
	okBtn.Position = UDim2.new(0.5, -60, 1, -45)
	okBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 60)
	okBtn.BorderSizePixel = 0
	okBtn.Text = "OK"
	okBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	okBtn.TextSize = 16
	okBtn.Font = Enum.Font.GothamBlack
	okBtn.Parent = panel
	self:_addCorner(okBtn, 8)

	okBtn.Activated:Connect(function()
		screen.Enabled = false
		self._inDungeon = false
		self._statusScreen.Enabled = false
	end)
end

-- ==========================================
-- HANDLERS
-- ==========================================

function DungeonController:_onDungeonEntered(result)
	self._inDungeon = true
	self._statusScreen.Enabled = true

	self._dungeonNameLabel.Text = result.dungeonName or "DUNGEON"
	self._waveLabel.Text = ("Wave: %d/%d"):format(result.wave or 1, result.totalWaves or 0)
	self._enemyLabel.Text = "Enemies: ..."
	self._timerLabel.Text = "Time: 0:00"
	self._statusLabel.Text = "Status: Active"
	self._statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)

	self._currentStatus = result
end

function DungeonController:_updateStatus(result)
	self._currentStatus = result

	self._waveLabel.Text = ("Wave: %d/%d"):format(result.wave or 0, result.totalWaves or 0)
	self._enemyLabel.Text = ("Enemies: %d"):format(result.aliveEnemies or 0)

	-- Timer
	local elapsed = result.elapsed or 0
	local mins = math.floor(elapsed / 60)
	local secs = elapsed % 60
	self._timerLabel.Text = ("Time: %d:%02d"):format(mins, secs)

	-- Status
	if result.status == "completed" then
		self._statusLabel.Text = "✅ COMPLETED!"
		self._statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		self._inDungeon = false
		-- Tampilkan rewards
		task.wait(1)
		self:_showRewards(result)
	elseif result.status == "failed" then
		self._statusLabel.Text = "❌ FAILED (TIME UP)"
		self._statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		self._inDungeon = false
	else
		self._statusLabel.Text = "Status: Active"
		self._statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	end
end

function DungeonController:_showRewards(result)
	self._rewardsScreen.Enabled = true

	local config = result.config or {}
	local lines = {}
	table.insert(lines, "🏆 Dungeon Cleared!")
	table.insert(lines, "")

	if config.rewards then
		if config.rewards.exp then
			table.insert(lines, ("  ✦ EXP: +%d"):format(config.rewards.exp))
		end
		if config.rewards.softCurrency then
			table.insert(lines, ("  ✦ Gold: +%d"):format(config.rewards.softCurrency))
		end
		if config.rewards.items then
			for _, item in ipairs(config.rewards.items) do
				table.insert(lines, ("  ✦ %s ×%d"):format(item.itemId, item.quantity))
			end
		end
	end

	self._rewardsText.Text = table.concat(lines, "\n")
end

-- ==========================================
-- HELPERS
-- ==========================================

function DungeonController:_showToast(text, color)
	-- Toast notification sederhana
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(0, 300, 0, 40)
	toast.Position = UDim2.new(0.5, -150, 0.8, 0)
	toast.BackgroundColor3 = color or Color3.fromRGB(200, 60, 60)
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel = 0
	toast.Text = text
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.TextSize = 16
	toast.Font = Enum.Font.GothamBold
	toast.Parent = PLAYER_GUI:FindFirstChild("DungeonStatusScreen") or PLAYER_GUI
	self:_addCorner(toast, 8)

	-- Fade out
	task.spawn(function()
		task.wait(2)
		for i = 0, 10 do
			toast.BackgroundTransparency = 0.1 + (i * 0.09)
			toast.TextTransparency = i * 0.1
			task.wait(0.05)
		end
		toast:Destroy()
	end)
end

function DungeonController:_addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
end

return DungeonController
