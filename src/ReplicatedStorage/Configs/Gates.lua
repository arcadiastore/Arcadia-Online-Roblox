--[[
	Gates.lua
	Sumber kebenaran data Gate/Portal. Lihat docs/01_GDD.md §6 dan §11.

	requirement.type: "Level" | "Quest" | "Item" | "LevelAndQuest"

	worldPosition: Vector3 posisi portal di workspace (akan dipakai oleh
	  GatePortalBuilder.server.lua untuk spawn model 3D).
	destinationSpawn: string nama SpawnLocation di zona tujuan.
]]

return {
	Gate_Duskwood = {
		displayName = "Gate of Duskwood",
		destinationZone = "DuskwoodForest",
		requirement = { type = "LevelAndQuest", level = 10, questId = "Q_OpenGate_Duskwood" },
		worldPosition = Vector3.new(0, 3, -120),
		spawnRotation = 0,
	},
	Gate_Frostpeak = {
		displayName = "Gate of Frostpeak",
		destinationZone = "FrostpeakMountains",
		requirement = { type = "LevelAndQuest", level = 25, questId = "Q_OpenGate_Frostpeak" },
		worldPosition = Vector3.new(120, 3, 0),
		spawnRotation = 90,
	},
	Gate_SunkenCrypt = {
		displayName = "Gate of the Sunken Crypt",
		destinationZone = "SunkenCrypt",
		requirement = { type = "Item", itemId = "SunkenCryptKey" },
		worldPosition = Vector3.new(0, 3, 120),
		spawnRotation = 180,
	},
	Gate_ShatteredSanctum = {
		displayName = "Gate of the Shattered Sanctum",
		destinationZone = "ShatteredSanctum",
		requirement = { type = "Quest", questId = "Q_AllMainGatesCleared" },
		worldPosition = Vector3.new(-120, 3, 0),
		spawnRotation = 270,
	},
}
