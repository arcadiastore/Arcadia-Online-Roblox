--[[
	Gates.lua
	Sumber kebenaran data Gate/Portal. Lihat docs/01_GDD.md §6 dan §11.

	requirement.type: "Level" | "Quest" | "Item" | "LevelAndQuest" (kombinasi
	dicek oleh GateService — field ini hanya data, bukan logic).
]]

return {
	Gate_Duskwood = {
		displayName = "Gate of Duskwood",
		destinationZone = "DuskwoodForest",
		requirement = { type = "LevelAndQuest", level = 10, questId = "Q_OpenGate_Duskwood" },
	},
	Gate_Frostpeak = {
		displayName = "Gate of Frostpeak",
		destinationZone = "FrostpeakMountains",
		requirement = { type = "LevelAndQuest", level = 25, questId = "Q_OpenGate_Frostpeak" },
	},
	Gate_SunkenCrypt = {
		displayName = "Gate of the Sunken Crypt",
		destinationZone = "SunkenCrypt",
		requirement = { type = "Item", itemId = "SunkenCryptKey" },
	},
	Gate_ShatteredSanctum = {
		displayName = "Gate of the Shattered Sanctum",
		destinationZone = "ShatteredSanctum",
		requirement = { type = "Quest", questId = "Q_AllMainGatesCleared" },
	},
}
