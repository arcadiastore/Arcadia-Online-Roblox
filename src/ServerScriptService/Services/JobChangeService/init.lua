--[[
	JobChangeService/init.lua
	Server-side Job Change system — naikkan kelas dari Tier 1→2→3.

	Remote: Character/JobChange (Function, rate-limited 2s)
	Dependency: DataService, Classes config
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))
local ClassesConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Classes"))

local DATA_SERVICE_NAME = "DataService"
local REMOTE_NAME = "Character/JobChange"

local JobChangeService = BaseService:Extend("JobChangeService")

function JobChangeService:Init()
	BaseService.Init(self)
end

function JobChangeService:Start()
	BaseService.Start(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Character")
	local jobChangeRemote = remotesFolder:WaitForChild("JobChange")
	local validator = RemoteValidator.new(REMOTE_NAME, 2)

	local self_ref = self
	jobChangeRemote.OnServerInvoke = validator:WrapHandler(function(player)
		return self_ref:TryJobChange(player)
	end)
end

-- ==========================================
-- PUBLIC API (direct call)
-- ==========================================

function JobChangeService:TryJobChange(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then
		return { success = false, reason = "Profile belum siap" }
	end

	if not profile.ClassId then
		return { success = false, reason = "Pilih kelas terlebih dahulu" }
	end

	local currentClass = ClassesConfig[profile.ClassId]
	if not currentClass then
		return { success = false, reason = "Class tidak valid: " .. tostring(profile.ClassId) }
	end

	if not currentClass.jobChange then
		return { success = false, reason = "Sudah di tier maksimum", tier = currentClass.tier }
	end

	local nextClassId = currentClass.jobChange.nextClassId
	local reqLevel = currentClass.jobChange.requiredLevel or 1
	local reqQuestId = currentClass.jobChange.requiredQuestId

	if profile.Level < reqLevel then
		return {
			success = false,
			reason = "Level belum cukup",
			currentLevel = profile.Level,
			requiredLevel = reqLevel,
		}
	end

	if reqQuestId then
		local completedQuests = profile.CompletedQuests or {}
		if not completedQuests[reqQuestId] then
			return {
				success = false,
				reason = "Quest belum selesai",
				requiredQuestId = reqQuestId,
			}
		end
	end

	local nextClass = ClassesConfig[nextClassId]
	if not nextClass then
		return { success = false, reason = "Class tujuan tidak valid: " .. tostring(nextClassId) }
	end

	local previousClassId = profile.ClassId
	profile.ClassId = nextClassId
	profile.ClassTier = nextClass.tier

	return {
		success = true,
		newClassId = nextClassId,
		newTier = nextClass.tier,
		previousClassId = previousClassId,
	}
end

return JobChangeService
