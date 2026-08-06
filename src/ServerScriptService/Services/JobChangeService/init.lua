--[[
	JobChangeService/init.lua
	Server-side Job Change system — naikkan kelas dari Tier 1→2→3.

	Alur:
	  1. Player panggil TryJobChange()
	  2. Service cek: sudah punya ClassId? bukan Tier 3?
	  3. Ambil class config → lihat jobChange.nextClassId
	  4. Cek syarat: Level >= requiredLevel
	  5. Cek Quest: CompletedQuests[requiredQuestId]
	  6. Update ClassId, ClassTier
	  7. Return sukses + info class baru

	Remote: Character/JobChange (Function, rate-limited 2s)
	Dependency: DataService, Classes config
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent:WaitForChild("BaseController"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("RemoteValidator"))
local ClassesConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Classes"))

local DATA_SERVICE_NAME = "DataService"
local REMOTE_NAME = "Character/JobChange"
local COOLDOWN_SECONDS = 2

local JobChangeService = BaseService:Extend("JobChangeService")

function JobChangeService:Init()
	BaseService.Init(self)
	RemoteValidator.new(REMOTE_NAME)
end

function JobChangeService:Start()
	BaseService.Start(self)

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	if not ds then
		warn("[JobChangeService] DataService not found!")
		return
	end

	ds:BindRemoteEvent(REMOTE_NAME, function(player)
		if self:_isOnCooldown(player) then
			return { success = false, reason = "Cooldown aktif" }
		end
		self:_setCooldown(player)
		return self:TryJobChange(player)
	end)
end

-- ==========================================
-- PUBLIC API (direct call)
-- ==========================================

function JobChangeService.TryJobChange(player: Player): { [string]: any }
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

	-- === SUKSES ===
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

-- ==========================================
-- INTERNAL: Cooldown
-- ==========================================

function JobChangeService:_isOnCooldown(player): boolean
	local cd = self._cooldowns and self._cooldowns[player.UserId]
	if not cd then return false end
	return (tick() - cd) < COOLDOWN_SECONDS
end

function JobChangeService:_setCooldown(player)
	if not self._cooldowns then self._cooldowns = {} end
	self._cooldowns[player.UserId] = tick()
end

function JobChangeService:OnPlayerRemoving(player)
	if self._cooldowns then
		self._cooldowns[player.UserId] = nil
	end
end

return JobChangeService
