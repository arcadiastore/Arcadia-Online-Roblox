--[[
	PartyService/init.lua
	Server-authoritative Party system.

	Alur:
	  1. CreateParty(player) → buat party baru, player jadi leader
	  2. InvitePlayer(player, targetPlayerId) → kirim invite
	  3. AcceptInvite(player, partyId) → join party
	  4. LeaveParty(player) → keluar dari party
	  5. KickPlayer(player, targetPlayerId) → kick member (leader only)
	  6. DissolveParty(player) → bubar party (leader only)
	  7. GetPartyInfo(player) → info party saat ini

	Data structure (server memory, bukan di profile):
	  _parties[partyId] = {
		partyId, leaderId, members = { userId, ... },
		createdAt, dungeonId = nil, shareExp = true
	  }

	  Profile hanya simpan: PartyId = string? (referensi)

	MAX_PARTY_SIZE = 4

	ANTI-CHEAT:
	  - Semua operasi di server
	  - Leader validation untuk kick/dissolve
	  - Invite expiration (60 detik)
	  - Rate-limited remotes

	Dependency: DataService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local BaseService = require(script.Parent:WaitForChild("BaseService"))
local RemoteValidator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteValidator"))

local DATA_SERVICE_NAME = "DataService"
local REMOTE_CREATE = "Party/Create"
local REMOTE_INVITE = "Party/Invite"
local REMOTE_ACCEPT = "Party/Accept"
local REMOTE_LEAVE = "Party/Leave"
local REMOTE_KICK = "Party/Kick"
local REMOTE_INFO = "Party/GetInfo"

local MAX_PARTY_SIZE = 4
local INVITE_EXPIRY = 60 -- detik

local PartyService = BaseService:Extend("PartyService")

function PartyService:Init()
	BaseService.Init(self)
	self._name = "PartyService"
	self._parties = {}    -- partyId → party data
	self._invites = {}    -- userId → { partyId, invitedAt }
end

function PartyService:Start()
	BaseService.Start(self)

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Party")
	local selfRef = self

	remotesFolder:WaitForChild("Create").OnServerInvoke =
		RemoteValidator.new(REMOTE_CREATE, 1):WrapHandler(function(player)
			return selfRef:CreateParty(player)
		end)

	remotesFolder:WaitForChild("Invite").OnServerInvoke =
		RemoteValidator.new(REMOTE_INVITE, 1):WrapHandler(function(player, targetUserId)
			return selfRef:InvitePlayer(player, targetUserId)
		end)

	remotesFolder:WaitForChild("Accept").OnServerInvoke =
		RemoteValidator.new(REMOTE_ACCEPT, 1):WrapHandler(function(player)
			return selfRef:AcceptInvite(player)
		end)

	remotesFolder:WaitForChild("Leave").OnServerInvoke =
		RemoteValidator.new(REMOTE_LEAVE, 1):WrapHandler(function(player)
			return selfRef:LeaveParty(player)
		end)

	remotesFolder:WaitForChild("Kick").OnServerInvoke =
		RemoteValidator.new(REMOTE_KICK, 1):WrapHandler(function(player, targetUserId)
			return selfRef:KickPlayer(player, targetUserId)
		end)

	remotesFolder:WaitForChild("GetInfo").OnServerInvoke =
		RemoteValidator.new(REMOTE_INFO, 1):WrapHandler(function(player)
			return selfRef:GetPartyInfo(player)
		end)
end

-- ==========================================
-- PUBLIC API
-- ==========================================

--- Buat party baru
function PartyService:CreateParty(player: Player): { [string]: any }
	local userId = player.UserId

	-- Sudah di party?
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end

	if profile.PartyId then
		return { success = false, reason = "Sudah di party" }
	end

	local partyId = HttpService:GenerateGUID(false)
	self._parties[partyId] = {
		partyId = partyId,
		leaderId = userId,
		members = { userId },
		createdAt = os.time(),
		dungeonId = nil,
		shareExp = true,
	}

	profile.PartyId = partyId

	return { success = true, partyId = partyId, role = "Leader" }
end

--- Invite player ke party
function PartyService:InvitePlayer(player: Player, targetUserId: number): { [string]: any }
	if typeof(targetUserId) ~= "number" then
		return { success = false, reason = "targetUserId harus number" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end

	local partyId = profile.PartyId
	if not partyId then
		return { success = false, reason = "Kamu belum di party" }
	end

	local party = self._parties[partyId]
	if not party then
		return { success = false, reason = "Party tidak ditemukan" }
	end

	-- Hanya leader yang bisa invite
	if party.leaderId ~= player.UserId then
		return { success = false, reason = "Hanya leader yang bisa invite" }
	end

	-- Cek party penuh
	if #party.members >= MAX_PARTY_SIZE then
		return { success = false, reason = "Party sudah penuh" }
	end

	-- Cek target online
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if not targetPlayer then
		return { success = false, reason = "Player tidak online" }
	end

	-- Cek target sudah di party
	local targetProfile = ds and ds.WaitForProfile(targetPlayer, 10)
	if targetProfile and targetProfile.PartyId then
		return { success = false, reason = "Player sudah di party" }
	end

	-- Kirim invite
	self._invites[targetUserId] = {
		partyId = partyId,
		invitedAt = os.time(),
		invitedBy = player.UserId,
	}

	return { success = true, targetUserId = targetUserId }
end

--- Terima invite
function PartyService:AcceptInvite(player: Player): { [string]: any }
	local userId = player.UserId
	local invite = self._invites[userId]

	if not invite then
		return { success = false, reason = "Tidak ada invite" }
	end

	-- Cek expired
	if (os.time() - invite.invitedAt) > INVITE_EXPIRY then
		self._invites[userId] = nil
		return { success = false, reason = "Invite sudah expired" }
	end

	local party = self._parties[invite.partyId]
	if not party then
		self._invites[userId] = nil
		return { success = false, reason = "Party tidak ditemukan" }
	end

	-- Cek party penuh
	if #party.members >= MAX_PARTY_SIZE then
		self._invites[userId] = nil
		return { success = false, reason = "Party sudah penuh" }
	end

	-- Sudah di party lain?
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end
	if profile.PartyId then
		return { success = false, reason = "Sudah di party lain" }
	end

	-- Join party
	table.insert(party.members, userId)
	profile.PartyId = party.partyId
	self._invites[userId] = nil

	return { success = true, partyId = party.partyId, role = "Member" }
end

--- Keluar dari party
function PartyService:LeaveParty(player: Player): { [string]: any }
	local userId = player.UserId

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end

	local partyId = profile.PartyId
	if not partyId then
		return { success = false, reason = "Tidak di party" }
	end

	local party = self._parties[partyId]
	if not party then
		profile.PartyId = nil
		return { success = true }
	end

	-- Hapus dari members
	for i, memberId in ipairs(party.members) do
		if memberId == userId then
			table.remove(party.members, i)
			break
		end
	end

	profile.PartyId = nil

	-- Kalau leader keluar → pindahkan leadership atau bubar
	if party.leaderId == userId then
		if #party.members > 0 then
			party.leaderId = party.members[1]
			-- Update leader profile
			local newLeader = Players:GetPlayerByUserId(party.leaderId)
			if newLeader then
				local newProfile = ds and ds.WaitForProfile(newLeader, 10)
				if newProfile then
					-- Profile sudah benar (PartyId tetap)
				end
			end
		else
			-- Party kosong → bubar
			self._parties[partyId] = nil
		end
	end

	return { success = true }
end

--- Kick member (leader only)
function PartyService:KickPlayer(player: Player, targetUserId: number): { [string]: any }
	if typeof(targetUserId) ~= "number" then
		return { success = false, reason = "targetUserId harus number" }
	end

	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end

	local partyId = profile.PartyId
	if not partyId then return { success = false, reason = "Tidak di party" } end

	local party = self._parties[partyId]
	if not party then return { success = false, reason = "Party tidak ditemukan" } end

	if party.leaderId ~= player.UserId then
		return { success = false, reason = "Hanya leader yang bisa kick" }
	end

	if targetUserId == player.UserId then
		return { success = false, reason = "Tidak bisa kick diri sendiri" }
	end

	-- Cari dan hapus target
	local found = false
	for i, memberId in ipairs(party.members) do
		if memberId == targetUserId then
			table.remove(party.members, i)
			found = true
			break
		end
	end

	if not found then
		return { success = false, reason = "Player tidak di party ini" }
	end

	-- Update target profile
	local targetPlayer = Players:GetPlayerByUserId(targetUserId)
	if targetPlayer then
		local targetProfile = ds and ds.WaitForProfile(targetPlayer, 10)
		if targetProfile then
			targetProfile.PartyId = nil
		end
	end

	return { success = true, kickedUserId = targetUserId }
end

--- Info party saat ini
function PartyService:GetPartyInfo(player: Player): { [string]: any }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile then return { success = false, reason = "Profile belum siap" } end

	local partyId = profile.PartyId
	if not partyId then
		return { success = true, inParty = false }
	end

	local party = self._parties[partyId]
	if not party then
		profile.PartyId = nil
		return { success = true, inParty = false }
	end

	-- Build member info
	local members = {}
	for _, memberId in ipairs(party.members) do
		local memberPlayer = Players:GetPlayerByUserId(memberId)
		local memberName = memberPlayer and memberPlayer.Name or ("User_" .. memberId)
		table.insert(members, {
			userId = memberId,
			name = memberName,
			isLeader = memberId == party.leaderId,
		})
	end

	return {
		success = true,
		inParty = true,
		partyId = partyId,
		leaderId = party.leaderId,
		members = members,
		memberCount = #party.members,
		maxSize = MAX_PARTY_SIZE,
		dungeonId = party.dungeonId,
	}
end

--- Cek apakah dua player di party sama
function PartyService:AreInSameParty(player1: Player, player2: Player): boolean
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local p1 = ds and ds.WaitForProfile(player1, 10)
	local p2 = ds and ds.WaitForProfile(player2, 10)
	if not p1 or not p2 then return false end
	return p1.PartyId ~= nil and p1.PartyId == p2.PartyId
end

--- Ambil semua member di party yang sama
function PartyService:GetPartyMembers(player: Player): { Player }
	local ds = BaseService.GetServiceByName(DATA_SERVICE_NAME)
	local profile = ds and ds.WaitForProfile(player, 10)
	if not profile or not profile.PartyId then return { player } end

	local party = self._parties[profile.PartyId]
	if not party then return { player } end

	local result = {}
	for _, memberId in ipairs(party.members) do
		local p = Players:GetPlayerByUserId(memberId)
		if p then table.insert(result, p) end
	end
	return result
end

function PartyService:OnPlayerRemoving(player)
	-- Auto-leave party saat player disconnect
	local userId = player.UserId
	for partyId, party in pairs(self._parties) do
		for i, memberId in ipairs(party.members) do
			if memberId == userId then
				table.remove(party.members, i)
				if party.leaderId == userId then
					if #party.members > 0 then
						party.leaderId = party.members[1]
					else
						self._parties[partyId] = nil
					end
				end
				break
			end
		end
	end
	self._invites[userId] = nil
end

return PartyService
