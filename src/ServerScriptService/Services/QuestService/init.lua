--[[
	QuestService/init.lua
	Server-side Quest system — accept, progress, complete quests.

	Alur:
	  1. AcceptQuest(player, questId) → validasi prerequisites → tambah ke QuestLog
	  2. ReportProgress(player, targetId, amount) → update semua quest yang butuh targetId
	  3. CompleteQuest(player, questId) → cek semua objectives terpenuhi → beri reward

	Objective types: Kill, Collect, Talk, Explore, GateOpen
	Semua objective disimpan sebagai { [targetId] = currentCount }

	Remotes:
	  - Quest/GetLog (Function) → ambil quest log player
	  - Quest/Accept (Function) → terima quest
	  - Quest/Complete (Function) → selesaikan quest & ambil reward

	ANTI-CHEAT:
	  - AcceptQuest: cek prerequisites di server
	  - ReportProgress: HANYA bisa dipanggil oleh Service lain (server-side),
	    BUKAN dari client langsung
	  - CompleteQuest: cek semua objective terpenuhi di server

	Dependency: DataService, Quests config, LevelService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))
local QuestsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Quests"))

local DATA_SERVICE_NAME = "DataService"
local LEVEL_SERVICE_NAME = "LevelService"

local REMOTE_GET_LOG = "Quest/GetLog"
local REMOTE_ACCEPT = "Quest/Accept"
local REMOTE_COMPLETE = "Quest/Complete"

local COOLDOWN_ACCEPT = 1
local COOLDOWN_COMPLETE = 1

local QuestService = BaseService:Extend("QuestService")

function QuestService:Init()
	BaseService.Init(self)
	self._name = "QuestService"
end

function QuestService:Start()
	BaseService.Start(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Quest")

	-- Quest/GetLog
	local getLogRemote = remotesFolder:WaitForChild("GetLog")
	local getLogValidator = RemoteValidator.new(REMOTE_GET_LOG, 1)
	local selfRef = self
	getLogRemote.OnServerInvoke = getLogValidator:WrapHandler(function(player)
		return selfRef:GetQuestLog(player)
	end)

	-- Quest/Accept
	local acceptRemote = remotesFolder:WaitForChild("Accept")
	local acceptValidator = RemoteValidator.new(REMOTE_ACCEPT, COOLDOWN_ACCEPT)
	acceptRemote.OnServerInvoke = acceptValidator:WrapHandler(function(player, questId)
		return selfRef:AcceptQuest(player, questId)
	end)

	-- Quest/Complete
	local completeRemote = remotesFolder:WaitForChild("Complete")
	local completeValidator = RemoteValidator.new(REMOTE_COMPLETE, COOLDOWN_COMPLETE)
	completeRemote.OnServerInvoke = completeValidator:WrapHandler(function(player, questId)
		return selfRef:CompleteQuest(player, questId)
	end)
end

-- ==========================================
-- PUBLIC API
-- ==========================================

--- Ambil quest log player
function QuestService:GetQuestLog(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	return { success = true, questLog = profile.QuestLog or {} }
end

--- Terima quest baru
function QuestService:AcceptQuest(player: Player, questId: string): { [string]: any }
	if typeof(questId) ~= "string" then
		return { success = false, reason = "questId harus string" }
	end

	local quest = QuestsConfig[questId]
	if not quest then
		return { success = false, reason = "Quest tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	-- Init QuestLog kalau belum ada
	if not profile.QuestLog then profile.QuestLog = {} end

	-- Sudah aktif?
	if profile.QuestLog[questId] then
		return { success = false, reason = "Quest sudah aktif" }
	end

	-- Sudah selesai (non-repeatable)?
	if not quest.repeatable and profile.CompletedQuests and profile.CompletedQuests[questId] then
		return { success = false, reason = "Quest sudah selesai" }
	end

	-- Cek prerequisites
	local prereq = quest.prerequisites or {}
	if prereq.requiredLevel and profile.Level < prereq.requiredLevel then
		return {
			success = false,
			reason = "Level belum cukup",
			requiredLevel = prereq.requiredLevel,
		}
	end
	if prereq.requiredQuestId then
		local completed = profile.CompletedQuests or {}
		if not completed[prereq.requiredQuestId] then
			return {
				success = false,
				reason = "Quest prasyarat belum selesai",
				requiredQuestId = prereq.requiredQuestId,
			}
		end
	end

	-- Tambahkan ke QuestLog
	local progress = {}
	for _, obj in ipairs(quest.objectives or {}) do
		progress[obj.targetId] = 0
	end

	profile.QuestLog[questId] = {
		status = "active",
		progress = progress,
		acceptedAt = os.time(),
	}

	return { success = true, questId = questId, questName = quest.displayName }
end

--- Laporkan progress (HANYA dari server-side Service lain, BUKAN dari client)
function QuestService:ReportProgress(player: Player, targetId: string, amount: number?)
	if typeof(targetId) ~= "string" then return end
	if amount ~= nil and typeof(amount) ~= "number" then return end
	amount = amount or 1

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return end

	local questLog = profile.QuestLog
	if not questLog then return end

	for questId, entry in pairs(questLog) do
		if entry.status == "active" and entry.progress then
			local quest = QuestsConfig[questId]
			if quest then
				for _, obj in ipairs(quest.objectives or {}) do
					if obj.targetId == targetId then
						local current = entry.progress[targetId] or 0
						local maxCount = obj.targetCount
						if current < maxCount then
							entry.progress[targetId] = math.min(current + amount, maxCount)
						end
					end
				end
			end
		end
	end
end

--- Selesaikan quest & ambil reward
function QuestService:CompleteQuest(player: Player, questId: string): { [string]: any }
	if typeof(questId) ~= "string" then
		return { success = false, reason = "questId harus string" }
	end

	local quest = QuestsConfig[questId]
	if not quest then
		return { success = false, reason = "Quest tidak valid" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local questLog = profile.QuestLog or {}
	local entry = questLog[questId]
	if not entry or entry.status ~= "active" then
		return { success = false, reason = "Quest tidak aktif" }
	end

	-- Cek semua objective terpenuhi
	for _, obj in ipairs(quest.objectives or {}) do
		local current = entry.progress[obj.targetId] or 0
		if current < obj.targetCount then
			return {
				success = false,
				reason = "Objective belum selesai",
				targetId = obj.targetId,
				current = current,
				required = obj.targetCount,
			}
		end
	end

	-- === SUKSES: Beri reward ===
	local rewards = quest.rewards or {}

	-- EXP
	if rewards.exp and rewards.exp > 0 then
		local levelSvc = BaseService.GetServiceByName(LEVEL_SERVICE_NAME)
		if levelSvc then
			levelSvc:AddExp(player, rewards.exp)
		end
	end

	-- Soft Currency
	if rewards.softCurrency and rewards.softCurrency > 0 then
		if not profile.Currency then profile.Currency = { Soft = 0, Premium = 0 } end
		profile.Currency.Soft = (profile.Currency.Soft or 0) + rewards.softCurrency
	end

	-- Items
	if rewards.items then
		if not profile.Inventory then profile.Inventory = {} end
		for _, itemData in ipairs(rewards.items) do
			table.insert(profile.Inventory, {
				itemId = itemData.itemId,
				quantity = itemData.quantity or 1,
			})
		end
	end

	-- Mark selesai
	entry.status = "completed"

	-- Tambahkan ke CompletedQuests
	if not profile.CompletedQuests then profile.CompletedQuests = {} end
	if quest.repeatable == false or quest.repeatable == nil then
		profile.CompletedQuests[questId] = true
	else
		-- Repeatable: increment count
		local count = profile.CompletedQuests[questId] or 0
		if type(count) == "boolean" then count = 1 end
		profile.CompletedQuests[questId] = count + 1
	end

	-- Hapus dari QuestLog (sudah selesai)
	profile.QuestLog[questId] = nil

	return {
		success = true,
		questId = questId,
		rewards = rewards,
	}
end

--- Ambil daftar quest yang bisa diterima player
function QuestService:GetAvailableQuests(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	local available = {}
	for questId, quest in pairs(QuestsConfig) do
		local prereq = quest.prerequisites or {}
		local meetsLevel = not prereq.requiredLevel or profile.Level >= prereq.requiredLevel
		local meetsQuest = not prereq.requiredQuestId or
			(profile.CompletedQuests and profile.CompletedQuests[prereq.requiredQuestId])
		local notActive = not (profile.QuestLog and profile.QuestLog[questId])
		local notCompleted = quest.repeatable or
			not (profile.CompletedQuests and profile.CompletedQuests[questId])

		if meetsLevel and meetsQuest and notActive and notCompleted then
			table.insert(available, {
				questId = questId,
				displayName = quest.displayName,
				description = quest.description,
				type = quest.type,
				objectives = quest.objectives,
				rewards = quest.rewards,
			})
		end
	end

	return { success = true, available = available }
end

return QuestService
