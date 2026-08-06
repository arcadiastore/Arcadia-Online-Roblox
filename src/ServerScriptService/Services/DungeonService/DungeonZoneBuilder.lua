--[[
	DungeonZoneBuilder.server.lua
	Spawn zona dungeon 3D — arena pertempuran dengan portal keluar.
	Dipanggil oleh DungeonService saat party masuk dungeon.

	Layout tiap dungeon:
	  - Floor part (arena)
	  - Walls (invisible barrier)
	  - Spawn points untuk enemies
	  - Exit portal (ProximityPrompt → keluar dungeon)
	  - Ambient lighting (fog, color)

	Dependency: DungeonService
]]

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DungeonsConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Dungeons"))

local DungeonZoneBuilder = {}

-- Zone positions (jauh dari map utama)
local ZONE_POSITIONS = {
	Dungeon_CorruptedGrove = Vector3.new(0, 0, -500),
	Dungeon_SunkenCrypt = Vector3.new(0, 0, -700),
	Dungeon_FrostpeakCavern = Vector3.new(0, 0, -900),
}

local ZONE_SIZE = Vector3.new(80, 1, 80)
local WALL_HEIGHT = 20
local SPAWN_RADIUS = 30

--- Build dungeon zone dan return spawn CFrame + enemy spawn points
function DungeonZoneBuilder:BuildZone(dungeonId: string): Model?
	local config = DungeonsConfig[dungeonId]
	if not config then return nil end

	local centerPos = ZONE_POSITIONS[dungeonId] or Vector3.new(0, 0, -500)

	-- Container
	local zone = Instance.new("Model")
	zone.Name = "DungeonZone_" .. dungeonId

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = ZONE_SIZE
	floor.Position = centerPos
	floor.Anchored = true
	floor.Material = Enum.Material.Rock
	floor.Color = Color3.fromRGB(40, 35, 30)
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.Parent = zone

	-- Walls (invisible barrier)
	local wallPositions = {
		{ centerPos + Vector3.new(0, WALL_HEIGHT/2, ZONE_SIZE.Z/2), Vector3.new(ZONE_SIZE.X, WALL_HEIGHT, 1) },
		{ centerPos + Vector3.new(0, WALL_HEIGHT/2, -ZONE_SIZE.Z/2), Vector3.new(ZONE_SIZE.X, WALL_HEIGHT, 1) },
		{ centerPos + Vector3.new(ZONE_SIZE.X/2, WALL_HEIGHT/2, 0), Vector3.new(1, WALL_HEIGHT, ZONE_SIZE.Z) },
		{ centerPos + Vector3.new(-ZONE_SIZE.X/2, WALL_HEIGHT/2, 0), Vector3.new(1, WALL_HEIGHT, ZONE_SIZE.Z) },
	}

	for _, wallData in ipairs(wallPositions) do
		local wall = Instance.new("Part")
		wall.Name = "Wall"
		wall.Size = wallData[2]
		wall.Position = wallData[1]
		wall.Anchored = true
		wall.Transparency = 1
		wall.CanCollide = true
		wall.Parent = zone
	end

	-- Ceiling (invisible, prevent escape)
	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(ZONE_SIZE.X, 1, ZONE_SIZE.Z)
	ceiling.Position = centerPos + Vector3.new(0, WALL_HEIGHT, 0)
	ceiling.Anchored = true
	ceiling.Transparency = 1
	ceiling.CanCollide = true
	ceiling.Parent = zone

	-- Exit portal (di tepi arena)
	local exitPos = centerPos + Vector3.new(0, 3, ZONE_SIZE.Z/2 - 5)
	local exitPortal = Instance.new("Part")
	exitPortal.Name = "ExitPortal"
	exitPortal.Size = Vector3.new(6, 8, 2)
	exitPortal.Position = exitPos
	exitPortal.Anchored = true
	exitPortal.Material = Enum.Material.Neon
	exitPortal.Color = Color3.fromRGB(255, 200, 50)
	exitPortal.Transparency = 0.3
	exitPortal.CanCollide = false
	exitPortal.Parent = zone

	local exitPrompt = Instance.new("ProximityPrompt")
	exitPrompt.ActionText = "Exit Dungeon"
	exitPrompt.ObjectText = config.displayName or "Dungeon"
	exitPrompt.HoldDuration = 1
	exitPrompt.MaxActivationDistance = 8
	exitPrompt.Parent = exitPortal

	-- Ambient light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(180, 150, 100)
	light.Brightness = 1.5
	light.Range = 100
	light.Parent = exitPortal

	-- Decorative pillars
	for i = 1, 4 do
		local angle = (i - 1) * (math.pi / 2)
		local pillarPos = centerPos + Vector3.new(
			math.cos(angle) * (ZONE_SIZE.X/2 - 5),
			5,
			math.sin(angle) * (ZONE_SIZE.Z/2 - 5)
		)

		local pillar = Instance.new("Part")
		pillar.Name = "Pillar_" .. i
		pillar.Size = Vector3.new(3, 10, 3)
		pillar.Position = pillarPos
		pillar.Anchored = true
		pillar.Material = Enum.Material.Slate
		pillar.Color = Color3.fromRGB(60, 55, 50)
		pillar.Parent = zone
	end

	zone.Parent = Workspace
	return zone
end

--- Ambil spawn CFrame untuk player (tengah arena)
function DungeonZoneBuilder:GetPlayerSpawn(dungeonId: string): CFrame
	local centerPos = ZONE_POSITIONS[dungeonId] or Vector3.new(0, 0, -500)
	return CFrame.new(centerPos + Vector3.new(0, 3, 0))
end

--- Ambil spawn CFrame untuk enemy (acak dalam arena)
function DungeonZoneBuilder:GetEnemySpawn(dungeonId: string): CFrame
	local centerPos = ZONE_POSITIONS[dungeonId] or Vector3.new(0, 0, -500)
	local offsetX = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	local offsetZ = math.random(-SPAWN_RADIUS, SPAWN_RADIUS)
	return CFrame.new(centerPos + Vector3.new(offsetX, 3, offsetZ))
end

--- Hapus zone
function DungeonZoneBuilder:DestroyZone(dungeonId: string)
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj.Name == "DungeonZone_" .. dungeonId then
			obj:Destroy()
		end
	end
end

return DungeonZoneBuilder
