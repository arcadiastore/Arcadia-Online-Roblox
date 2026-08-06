--[[
	CharacterCreationController.lua (v2 — with debug prints)
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
	print("[CCC] Init — remotes siap")

	local CharacterCreationUI = require(StarterGui:WaitForChild("UI"):WaitForChild("CharacterCreation"))
	self._ui = CharacterCreationUI.new()
	print("[CCC] Init — UI module loaded")
end

function CharacterCreationController:Start()
	BaseController.Start(self)

	print("[CCC] Start — cek CreationStatus...")
	local ok, result = pcall(function()
		return self._remotes.CreationStatus:InvokeServer()
	end)

	local status = ok and result or nil
	print("[CCC] CreationStatus:", ok, status and ("hasRace=" .. tostring(status.hasRace) .. " hasClass=" .. tostring(status.hasClass)) or "nil/error")

	if status and status.hasClass then
		print("[CCC] Karakter sudah lengkap — skip UI")
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	print("[CCC] Mounting UI...")
	local mountOk, mountErr = pcall(function()
		self._ui:Mount(playerGui)
	end)
	if not mountOk then
		warn("[CCC] Mount GAGAL:", mountErr)
		return
	end
	print("[CCC] UI mounted —", self._gui and "OK" or "no _gui ref")

	if status and status.hasRace then
		print("[CCC] Sudah punya race, skip ke class step")
		self._ui:SkipToClassStep()
	else
		print("[CCC] Requesting reroll...")
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
	print("[CCC] Start selesai — event connected")
end

function CharacterCreationController:_requestReroll()
	print("[CCC] RerollRace: InvokeServer...")
	self._ui:SetRaceLoading(true)
	local ok, result = pcall(function()
		return self._remotes.RerollRace:InvokeServer()
	end)
	self._ui:SetRaceLoading(false)

	print("[CCC] RerollRace:", ok, result and result.success, result and result.raceId)

	if not ok or not result or not result.success then
		local reason = (result and result.reason) or (not ok and "remote error") or "unknown"
		warn("[CCC] RerollRace gagal:", reason)
		self._ui:ShowRaceError("Gagal roll ras: " .. reason)
		return
	end

	self._ui:ShowRaceReveal(result)
	print("[CCC] ShowRaceReveal:", result.raceId)
end

function CharacterCreationController:_confirmRace(raceId)
	print("[CCC] ConfirmRace:", raceId)
	self._ui:SetRaceLoading(true)
	local ok, result = pcall(function()
		return self._remotes.ConfirmRace:InvokeServer(raceId)
	end)
	self._ui:SetRaceLoading(false)

	if not ok or not result or not result.success then
		local reason = (result and result.reason) or (not ok and "remote error") or "unknown"
		warn("[CCC] ConfirmRace gagal:", reason)
		self._ui:ShowRaceError("Gagal konfirmasi: " .. reason)
		return
	end

	self._ui:GoToClassStep()
	print("[CCC] ConfirmRace sukses → class step")
end

function CharacterCreationController:_selectClass(classId)
	print("[CCC] SelectClass:", classId)
	self._ui:SetClassLoading(true)
	local ok, result = pcall(function()
		return self._remotes.SelectClass:InvokeServer(classId)
	end)
	self._ui:SetClassLoading(false)

	if not ok or not result or not result.success then
		local reason = (result and result.reason) or (not ok and "remote error") or "unknown"
		warn("[CCC] SelectClass gagal:", reason)
		self._ui:ShowClassError("Gagal pilih kelas: " .. reason)
		return
	end

	self._ui:PlayOutro()
	print("[CCC] SelectClass sukses → outro")
end

return CharacterCreationController
