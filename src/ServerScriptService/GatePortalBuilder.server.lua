--[[
	GatePortalBuilder.server.lua
	Spawn model 3D portal/gate di workspace berdasarkan posisi di
	Configs/Gates.lua. Dijalankan sekali saat server start.

	Portal terdiri dari:
	  - Base (anchor, hitbox untuk ProximityPrompt)
	  - Ring (arrangement part membentuk lingkaran, emissive glow)
	  - Inner surface (translucent, efek swirl)
	  - PointLight (ambient glow)
	  - ParticleEmitter (sparkle/aura)
	  - ProximityPrompt (interaksi pemain)

	HAPUS script ini kalau portal 3D dibuat manual di Studio.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GatesConfig = require(ReplicatedStorage.Configs.Gates)

local PORTAL_RADIUS = 6      -- radius lingkaran portal
local PORTAL_HEIGHT = 10     -- tinggi portal
local RING_SEGMENTS = 20     -- jumlah part pembentuk ring
local RING_THICKNESS = 0.6   -- ketebalan ring part

local PALETTE = {
	Portal = Color3.fromRGB(124, 92, 255),
	Glow = Color3.fromRGB(160, 130, 255),
	Surface = Color3.fromRGB(100, 70, 220),
}

local function createPortal(gateId, gateData)
	local pos = gateData.worldPosition
	if not pos then return end

	-- Folder untuk portal ini
	local folder = Instance.new("Folder")
	folder.Name = "Portal_" .. gateId
	folder.Parent = workspace

	-- Base part (anchor, collision group)
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Anchored = true
	base.CanCollide = false
	base.Transparency = 1
	base.Size = Vector3.new(PORTAL_RADIUS * 2 + 2, PORTAL_HEIGHT, PORTAL_RADIUS * 2 + 2)
	base.Position = pos + Vector3.new(0, PORTAL_HEIGHT / 2, 0)
	base.Parent = folder

	-- Ring parts (lingkaran dari part kecil)
	for i = 1, RING_SEGMENTS do
		local angle = (i - 1) / RING_SEGMENTS * math.pi * 2
		local x = math.cos(angle) * PORTAL_RADIUS
		local z = math.sin(angle) * PORTAL_RADIUS

		local segment = Instance.new("Part")
		segment.Name = "Ring_" .. i
		segment.Anchored = true
		segment.CanCollide = false
		segment.Material = Enum.Material.Neon
		segment.Color = PALETTE.Portal
		segment.Size = Vector3.new(RING_THICKNESS, RING_THICKNESS, (2 * math.pi * PORTAL_RADIUS) / RING_SEGMENTS + 0.1)
		segment.CFrame = CFrame.new(pos + Vector3.new(x, PORTAL_HEIGHT / 2, z))
			* CFrame.Angles(0, -angle + math.pi / 2, 0)
		segment.Parent = folder
	end

	-- Inner surface (translucent fill)
	local inner = Instance.new("Part")
	inner.Name = "InnerSurface"
	inner.Anchored = true
	inner.CanCollide = false
	inner.Material = Enum.Material.ForceField
	inner.Color = PALETTE.Surface
	inner.Transparency = 0.4
	inner.Size = Vector3.new(PORTAL_RADIUS * 1.7, PORTAL_HEIGHT - 1, 0.2)
	inner.Position = pos + Vector3.new(0, PORTAL_HEIGHT / 2, 0)
	inner.Orientation = Vector3.new(0, 0, 0)
	inner.Parent = folder

	-- Rotasi inner surface mengikuti spawnRotation
	if gateData.spawnRotation then
		inner.CFrame = CFrame.new(pos + Vector3.new(0, PORTAL_HEIGHT / 2, 0))
			* CFrame.Angles(0, math.rad(gateData.spawnRotation), 0)
	end

	-- PointLight
	local light = Instance.new("PointLight")
	light.Name = "PortalLight"
	light.Color = PALETTE.Glow
	light.Brightness = 2
	light.Range = 20
	light.Parent = base

	-- ParticleEmitter di base
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "PortalParticles"
	particles.Color = ColorSequence.new(PALETTE.Portal, PALETTE.Glow)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(1.5, 3)
	particles.Rate = 30
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.RotSpeed = NumberRange.new(-90, 90)
	particles.EmissionDirection = Enum.NormalId.Top
	particles.Parent = base

	-- Gate name label (BillboardGui di atas portal)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GateLabel"
	billboard.Size = UDim2.new(8, 0, 1.5, 0)
	billboard.StudsOffset = Vector3.new(0, PORTAL_HEIGHT / 2 + 1.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = base

	local nameLabel = Instance.new("TextLabel")
 nameLabel.BackgroundTransparency = 1
 nameLabel.Font = Enum.Font.GothamBlack
 nameLabel.Text = gateData.displayName or gateId
 nameLabel.TextColor3 = Color3.fromRGB(232, 186, 94) -- Gold
	nameLabel.TextSize = 18
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.3
 nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
 nameLabel.Position = UDim2.new(0, 0, 0, 0)
 nameLabel.Parent = billboard

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Approach to interact"
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	statusLabel.TextSize = 12
	statusLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	statusLabel.TextStrokeTransparency = 0.5
	statusLabel.Size = UDim2.new(1, 0, 0.4, 0)
	statusLabel.Position = UDim2.new(0, 0, 0.6, 0)
	statusLabel.Parent = billboard

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GatePrompt"
	prompt.ActionText = "Enter Gate"
	prompt.ObjectText = gateData.displayName or gateId
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = base

	return folder
end

-- === Build semua portal ===
local portalsFolder = Instance.new("Folder")
portalsFolder.Name = "GatePortals"
portalsFolder.Parent = workspace

for gateId, gateData in pairs(GatesConfig) do
	createPortal(gateId, gateData)
end

-- === Buat spawn points untuk tiap zona ===
-- "Spawn_Millhaven" = starting zone (default spawn)
-- Lainnya = tujuan teleport gate
local spawnData = {
	{ name = "Spawn_Millhaven", pos = Vector3.new(0, 3, 0) },
}

-- Tambah spawn untuk setiap zona tujuan gate
for _, gateData in pairs(GatesConfig) do
	local zone = gateData.destinationZone
	local pos = gateData.worldPosition + Vector3.new(0, 0, 15) -- depan portal
	table.insert(spawnData, { name = "Spawn_" .. zone, pos = pos })
end

for _, sp in ipairs(spawnData) do
	local part = Instance.new("Part")
	part.Name = sp.name
	part.Anchored = true
	part.CanCollide = true
	part.Size = Vector3.new(10, 1, 10)
	part.Position = sp.pos
	part.Color = Color3.fromRGB(40, 42, 60)
	part.Material = Enum.Material.Slate
	part.Parent = workspace

	-- Label BillboardGui
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(10, 0, 1.5, 0)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = false
	bb.Parent = part

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = sp.name:gsub("Spawn_", "")
	lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
	lbl.TextSize = 14
	lbl.TextStrokeTransparency = 0.3
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.Parent = bb
end

print("[GatePortalBuilder] Portals & spawn points created!")
