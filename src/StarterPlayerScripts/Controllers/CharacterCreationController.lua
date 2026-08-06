--[[
	CharacterCreationController.lua
	Menghubungkan UI CharacterCreation (StarterGui/UI/CharacterCreation) ke
	Remote Character/* (docs/02_TDD.md §4). Satu Controller = satu domain UI
	(docs/04_AI_AGENT_RULES.md) — tidak ada keputusan gameplay di sini, semua
	RNG/validasi ras & kelas tetap di CharacterService server-side.

	Alur:
	  1. Start() → panggil CreationStatus. Kalau hasClass sudah true, tidak
	     perlu tampilkan apa-apa (karakter sudah selesai dibuat).
	  2. Kalau hasRace true tapi hasClass false → langsung buka Step 2 (Class),
	     race sudah dikonfirmasi sebelumnya jadi tidak perlu reveal ulang.
	  3. Kalau belum ada race sama sekali → mount UI, panggil RerollRace utk
	     roll pertama, tampilkan.
	  4. Reroll → panggil ulang RerollRace, update tampilan.
	  5. Confirm Race → panggil ConfirmRace(raceId yang lagi ditampilkan).
	     Sukses → pindah ke Step 2. Gagal → tampilkan reason dari server.
	  6. Select Class (klik card) → hanya update seleksi visual (belum kirim
	     remote, biar player bisa ganti-ganti pilihan dulu).
	  7. Begin Journey → panggil SelectClass(classId terpilih). Sukses → outro
	     & destroy UI. Gagal → tampilkan reason dari server.
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

	local status = self._remotes.CreationStatus:InvokeServer()
	if status and status.hasClass then
		-- Karakter sudah lengkap (race + class) — tidak perlu tampilkan UI.
		return
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	self._ui:Mount(playerGui)

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
	local result = self._remotes.RerollRace:InvokeServer()
	self._ui:SetRaceLoading(false)

	if not result or not result.success then
		self._ui:ShowRaceError((result and result.reason) or "Gagal roll ras, coba lagi.")
		return
	end

	self._ui:ShowRaceReveal(result)
end

function CharacterCreationController:_confirmRace(raceId)
	self._ui:SetRaceLoading(true)
	local result = self._remotes.ConfirmRace:InvokeServer(raceId)
	self._ui:SetRaceLoading(false)

	if not result or not result.success then
		self._ui:ShowRaceError((result and result.reason) or "Gagal konfirmasi ras.")
		return
	end

	self._ui:GoToClassStep()
end

function CharacterCreationController:_selectClass(classId)
	self._ui:SetClassLoading(true)
	local result = self._remotes.SelectClass:InvokeServer(classId)
	self._ui:SetClassLoading(false)

	if not result or not result.success then
		self._ui:ShowClassError((result and result.reason) or "Gagal pilih kelas.")
		return
	end

	self._ui:PlayOutro()
end

return CharacterCreationController
