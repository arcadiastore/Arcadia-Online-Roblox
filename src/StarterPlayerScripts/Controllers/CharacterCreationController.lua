--[[
	CharacterCreationController.lua
	Menghubungkan UI CharacterCreation ke Remote Character/*.

	Alur:
	  1. Start() → CreationStatus. Kalau hasClass = true → skip.
	  2. Kalau hasRace true → SkipToClassStep.
	  3. Kalau belum → mount UI, RerollRace pertama.
	  4. Reroll → RerollRace, update tampilan.
	  5. Confirm Race → ConfirmRace → class step.
	  6. Select Class → SelectClass → outro.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local ControllersFolder = script.Parent
local BaseController = require(ControllersFolder:WaitForChild("BaseController"))

local CharacterCreationController = BaseController:Extend("CharacterCreationController")

function CharacterCreationController:Init()
	BaseController.Init(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Character")
	self._remotes = {
		RerollRace = remotesFolder:WaitForChild("RerollRace"),
		ConfirmRace = remotesFolder:WaitForChild("ConfirmRace"),
		SelectClass = remotesFolder:WaitForChild("SelectClass"),
		CreationStatus = remotesFolder:WaitForChild("CreationStatus"),
	}

	local CharacterCreationUI = require(StarterGui:WaitForChild("UI"):WaitForChild("CharacterCreation"))
	self._ui = CharacterCreationUI.new()
end

function CharacterCreationController:Start()
	BaseController.Start(self)

	local ok, result = pcall(function()
		return self._remotes.CreationStatus:InvokeServer()
	end)
	local status = ok and result or nil

	if status and status.hasClass then
		return -- Karakter sudah lengkap
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local mountOk, mountErr = pcall(function()
		self._ui:Mount(playerGui)
	end)
	if not mountOk then
		warn("[CharacterCreation] Mount gagal:", mountErr)
		return
	end

	if status and status.hasRace then
		self._ui:SkipToClassStep()
	else
		self:_requestReroll()
	end

	self._ui.RerollRequested.Event:Connect(function()
		self:_requestReroll()
	end)
	self._ui.ConfirmRaceRequested.Event:Connect(function(raceId)
		self:_confirmRace(raceId)
	end)
	self._ui.BeginJourneyRequested.Event:Connect(function(classId)
		self:_selectClass(classId)
	end)
end

function CharacterCreationController:_requestReroll()
	self._ui:SetRaceLoading(true)
	local ok, result = pcall(function()
		return self._remotes.RerollRace:InvokeServer()
	end)
	self._ui:SetRaceLoading(false)

	if not ok or not result or not result.success then
		self._ui:ShowRaceError((result and result.reason) or "Gagal roll ras, coba lagi.")
		return
	end
	self._ui:ShowRaceReveal(result)
end

function CharacterCreationController:_confirmRace(raceId)
	self._ui:SetRaceLoading(true)
	local ok, result = pcall(function()
		return self._remotes.ConfirmRace:InvokeServer(raceId)
	end)
	self._ui:SetRaceLoading(false)

	if not ok or not result or not result.success then
		self._ui:ShowRaceError((result and result.reason) or "Gagal konfirmasi ras.")
		return
	end
	self._ui:GoToClassStep()
end

function CharacterCreationController:_selectClass(classId)
	self._ui:SetClassLoading(true)
	local ok, result = pcall(function()
		return self._remotes.SelectClass:InvokeServer(classId)
	end)
	self._ui:SetClassLoading(false)

	if not ok or not result or not result.success then
		self._ui:ShowClassError((result and result.reason) or "Gagal pilih kelas.")
		return
	end
	self._ui:PlayOutro()
end

return CharacterCreationController
