--[[
	DamageFormula.lua
	Pure function — hitung damage antara attacker dan enemy.
	Tidak ada dependency Roblox API — bisa dites tanpa Studio.

	Rumus:
	  Physical: (baseDmg + STR * 1.5) * classMultiplier * elementMultiplier
	  Magical:  (baseDmg + INT * 1.5) * classMultiplier * elementMultiplier

	  Defense reduction: dmg * (100 / (100 + defense))
	  Critical: if random < critRate then dmg *= 1.5

	  critRate dari LUK: base 5% + LUK * 0.5% (max 50%)
	  classMultiplier dari Classes.lua weaponTypes (placeholder: 1.0)
	  elementMultiplier dari Elements.lua: 1.5 strong, 0.5 weak, 1.0 neutral

	ANTI-CHEAT: Semua parameter dihitung di server.
]]

local ElementsConfig = require(script.Parent:WaitForChild("Elements"))

local DamageFormula = {}

--- Hitung crit rate dari LUK (0.0 – 0.5)
function DamageFormula.CalcCritRate(luk: number): number
	local base = 0.05           -- 5% base
	local perPoint = 0.005      -- 0.5% per LUK
	local maxRate = 0.50        -- cap 50%
	return math.min(base + luk * perPoint, maxRate)
end

--- Hitung element multiplier
function DamageFormula.CalcElementMultiplier(atkElement: string?, defElement: string?): number
	if not atkElement or not defElement then return 1.0 end

	local elementData = ElementsConfig[atkElement]
	if not elementData then return 1.0 end

	for _, strong in ipairs(elementData.strongAgainst or {}) do
		if strong == defElement then return 1.5 end
	end
	for _, weak in ipairs(elementData.weakAgainst or {}) do
		if weak == defElement then return 0.5 end
	end

	return 1.0
end

--- Hitung defense reduction multiplier
function DamageFormula.CalcDefenseReduction(defense: number): number
	return 100 / (100 + defense)
end

--- Hitung damage final
-- @param attackerStats { STR, INT, LUK, Level }
-- @param skill { baseDamage, damageType, element }
-- @param enemyStats { defense, element }
-- @param classMultiplier number (default 1.0)
-- @return { damage, isCrit, elementMultiplier }
function DamageFormula.Calculate(
	attackerStats: { [string]: number },
	skill: { [string]: any },
	enemyStats: { [string]: any },
	classMultiplier: number?
): { [string]: any }
	classMultiplier = classMultiplier or 1.0

	local baseDmg = skill.baseDamage or 0
	local scalingStat = 0

	if skill.damageType == "Physical" then
		scalingStat = (attackerStats.STR or 0) * 1.5
	elseif skill.damageType == "Magical" then
		scalingStat = (attackerStats.INT or 0) * 1.5
	end

	-- Base damage sebelum multiplier
	local rawDmg = baseDmg + scalingStat

	-- Class multiplier
	rawDmg = rawDmg * classMultiplier

	-- Element multiplier
	local elemMult = DamageFormula.CalcElementMultiplier(skill.element, enemyStats.element)
	rawDmg = rawDmg * elemMult

	-- Defense reduction
	local defMult = DamageFormula.CalcDefenseReduction(enemyStats.defense or 0)
	rawDmg = rawDmg * defMult

	-- Critical hit
	local critRate = DamageFormula.CalcCritRate(attackerStats.LUK or 0)
	local isCrit = math.random() < critRate
	if isCrit then
		rawDmg = rawDmg * 1.5
	end

	-- Floor + minimum 1
	local finalDmg = math.max(1, math.floor(rawDmg))

	return {
		damage = finalDmg,
		isCrit = isCrit,
		elementMultiplier = elemMult,
		defenseReduction = defMult,
	}
end

return DamageFormula
