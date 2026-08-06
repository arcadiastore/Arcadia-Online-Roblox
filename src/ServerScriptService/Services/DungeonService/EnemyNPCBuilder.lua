--[[
	EnemyNPCBuilder.lua
	Spawn enemy NPC model yang bisa diserang player.
	Dipakai oleh CombatService:SpawnEnemy dan DungeonService.

	Enemy NPC = R6 humanoid model dengan:
	  - Head + Body (simple box)
	  - Humanoid (HP = enemy stats)
	  - BillboardGui (name + HP bar)
	  - Color sesuai element
	  - Tag "EnemyNPC" untuk identification

	ANTI-CHEAT:
	  - HP di-set dari config, bukan dari client
	  - Damage hanya dari server (CombatService)
	  - Death detection dari Humanoid.Died
]]

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemiesConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("Enemies"))

local EnemyNPCBuilder = {}

-- Element colors
local ELEMENT_COLORS = {
	Fire = Color3.fromRGB(255, 80, 30),
	Water = Color3.fromRGB(50, 120, 255),
	Earth = Color3.fromRGB(120, 80, 40),
	Wind = Color3.fromRGB(150, 220, 150),
	Holy = Color3.fromRGB(255, 255, 180),
	Dark = Color3.fromRGB(100, 30, 120),
	None = Color3.fromRGB(150, 150, 150),
}

--- Spawn enemy NPC di posisi tertentu, return Model
function EnemyNPCBuilder:Spawn(enemyId: string, position: CFrame): Model?
	local config = EnemiesConfig[enemyId]
	if not config then
		warn("[EnemyNPCBuilder] Enemy tidak valid:", enemyId)
		return nil
	end

	-- Container model
	local model = Instance.new("Model")
	model.Name = enemyId

	-- Torso (main body)
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(4, 5, 2)
	torso.CFrame = position
	torso.Anchored = false
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = ELEMENT_COLORS[config.element] or ELEMENT_COLORS.None
	torso.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(3, 3, 3)
	head.Shape = Enum.PartType.Ball
	head.CFrame = position * CFrame.new(0, 4, 0)
	head.Anchored = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = ELEMENT_COLORS[config.element] or ELEMENT_COLORS.None
	head.Parent = model

	-- Weld head to torso
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = torso
	weld.Part1 = head
	weld.Parent = torso

	-- Eyes (dekoratif)
	for _, side in ipairs({-0.5, 0.5}) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.5, 0.5, 0.3)
		eye.Shape = Enum.PartType.Ball
		eye.CFrame = position * CFrame.new(side, 4, 1.2)
		eye.Anchored = false
		eye.Material = Enum.Material.Neon
		eye.Color = config.isBoss and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
		eye.Parent = model

		local eyeWeld = Instance.new("WeldConstraint")
		eyeWeld.Part0 = head
		eyeWeld.Part1 = eye
		eyeWeld.Parent = head
	end

	-- Arms (for non-boss)
	if not config.isBoss then
		for _, side in ipairs({-2.5, 2.5}) do
			local arm = Instance.new("Part")
			arm.Name = "Arm"
			arm.Size = Vector3.new(1, 4, 1)
			arm.CFrame = position * CFrame.new(side, 0, 0)
			arm.Anchored = false
			arm.Material = Enum.Material.SmoothPlastic
			arm.Color = ELEMENT_COLORS[config.element] or ELEMENT_COLORS.None
			arm.Parent = model

			local armWeld = Instance.new("WeldConstraint")
			armWeld.Part0 = torso
			armWeld.Part1 = arm
			armWeld.Parent = torso
		end
	else
		-- Boss: larger arms + horns
		for _, side in ipairs({-3, 3}) do
			local arm = Instance.new("Part")
			arm.Name = "Arm"
			arm.Size = Vector3.new(2, 6, 2)
			arm.CFrame = position * CFrame.new(side, -1, 0)
			arm.Anchored = false
			arm.Material = Enum.Material.SmoothPlastic
			arm.Color = ELEMENT_COLORS[config.element] or ELEMENT_COLORS.None
			arm.Parent = model

			local armWeld = Instance.new("WeldConstraint")
			armWeld.Part0 = torso
			armWeld.Part1 = arm
			armWeld.Parent = torso
		end

		-- Horns
		for _, side in ipairs({-1, 1}) do
			local horn = Instance.new("Part")
			horn.Name = "Horn"
			horn.Size = Vector3.new(0.5, 2, 0.5)
			horn.CFrame = position * CFrame.new(side * 0.8, 6, 0)
			horn.Anchored = false
			horn.Material = Enum.Material.Neon
			horn.Color = Color3.fromRGB(255, 50, 50)
			horn.Parent = model

			local hornWeld = Instance.new("WeldConstraint")
			hornWeld.Part0 = head
			hornWeld.Part1 = horn
			hornWeld.Parent = head
		end
	end

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = config.stats.HP
	humanoid.Health = config.stats.HP
	humanoid.DisplayName = config.displayName
	humanoid.HealthDisplayDistance = 50
	humanoid.NameDisplayDistance = 60
	humanoid.Parent = model

	-- Primary part
	model.PrimaryPart = torso

	-- Tag untuk identification
	local tag = Instance.new("StringValue")
	tag.Name = "EnemyTag"
	tag.Value = enemyId
	tag.Parent = model

	-- BillboardGui — HP bar + name
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyBillboard"
	billboard.Size = UDim2.new(0, 120, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 60
	billboard.Parent = head

	-- Name label
	local nameLabel = Instance.new("TextLabel")
 nameLabel.Name = "NameLabel"
 nameLabel.Size = UDim2.new(1, 0, 0, 20)
 nameLabel.Position = UDim2.new(0, 0, 0, 0)
 nameLabel.BackgroundTransparency = 1
 nameLabel.Text = config.displayName
 nameLabel.TextColor3 = config.isBoss and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
 nameLabel.TextSize = config.isBoss and 16 or 14
 nameLabel.Font = config.isBoss and Enum.Font.GothamBlack or Enum.Font.GothamBold
 nameLabel.Parent = billboard

	-- HP bar background
	local hpBG = Instance.new("Frame")
	hpBG.Name = "HP_BG"
	hpBG.Size = UDim2.new(1, 0, 0, 8)
	hpBG.Position = UDim2.new(0, 0, 0, 22)
	hpBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	hpBG.BorderSizePixel = 0
	hpBG.Parent = billboard

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0, 4)
	hpCorner.Parent = hpBG

	-- HP bar fill
	local hpFill = Instance.new("Frame")
	hpFill.Name = "HP_Fill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBG

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = hpFill

	-- Level label
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0, 15)
	levelLabel.Position = UDim2.new(0, 0, 0, 33)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv." .. config.level
	levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	levelLabel.TextSize = 12
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.Parent = billboard

	-- Update HP bar saat health berubah
	humanoid.HealthChanged:Connect(function(newHealth)
		local ratio = math.clamp(newHealth / humanoid.MaxHealth, 0, 1)
		hpFill.Size = UDim2.new(ratio, 0, 1, 0)

		-- Color gradient: hijau → kuning → merah
		if ratio > 0.5 then
			hpFill.BackgroundColor3 = Color3.fromRGB(
				math.floor(255 * (1 - ratio) * 2),
				255,
				0
			)
		else
			hpFill.BackgroundColor3 = Color3.fromRGB(
				255,
				math.floor(255 * ratio * 2),
				0
			)
		end
	end)

	-- Parent ke workspace
	model.Parent = Workspace

	return model
end

--- Hapus enemy NPC
function EnemyNPCBuilder:Destroy(model: Model)
	if model then
		model:Destroy()
	end
end

return EnemyNPCBuilder
