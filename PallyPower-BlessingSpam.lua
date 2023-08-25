local function GetDefaultSpamBlessing()
    local spell, rank
    _,_,_,_,rank = GetTalentInfo(3, 8)
    if (rank > 0) then
        spell = "Greater Blessing of Kings"
    else
        spell = "Greater Blessing of Might"
    end
    return spell
end

function PallyPower_BlessingSpam(autoSelfCast)
	if (BlessingSpamCasting) then return end
    if (autoSelfCast == nil) then autoSelfCast = GetCVar("autoSelfCast") end
	BlessingSpamCasting = true
	local RAID, PARTY, groupdType = 1, 2
	local spell = GetDefaultSpamBlessing()
	local numMembers = GetNumRaidMembers()

	if (not BlessingSpamSpell) then
		local i = 1
		while true do
			local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
			if (spellName == spell) then
				BlessingSpamSpell = i
				break
			end
			i = i + 1
		end
	end

	if (numMembers < 1) then
		numMembers = GetNumPartyMembers()
		if (numMembers < 1) then
			SetCVar("autoSelfCast", 0)
			CastSpell(BlessingSpamSpell, BOOKTYPE_SPELL)
			if (SpellCanTargetUnit("player")) then
				if (UnitAffectingCombat("player")) then
					SpellTargetUnit("player")
				end
			end
			SpellStopTargeting()
			SetCVar("autoSelfCast", autoSelfCast)
			BlessingSpamCasting = false
			return
		else
			groupType = PARTY
		end
	else
		groupdType = RAID
	end

	local roster = {
		["Paladin"] = {},
		["Priest"] = {},
		["Rogue"] = {},
		["Hunter"] = {},
		["Druid"] = {},
		["Mage"] = {},
		["Warlock"] = {},
		["Shaman"] = {},
		["Warrior"] = {},
	}
	local class = "Paladin"
	local unit, unitClass, pet
	if (groupdType == RAID) then
		for i = 1, GetNumRaidMembers() do
			unit = "raid"..i
			if (UnitAffectingCombat(unit)) then
				unitClass = UnitClass(unit)
				tinsert(roster[unitClass], unit)
				if (table.getn(roster[unitClass]) > table.getn(roster[class])) then
					class = unitClass
				end
				pet = "raidpet"..i
				if (unitClass == "Hunter" and UnitName(pet)) then
					tinsert(roster["Warrior"], pet)
					if (table.getn(roster["Warrior"]) > table.getn(roster[class])) then
						class = "Warrior"
					end
				end
			end
		end
	elseif (groupType == PARTY) then
		tinsert(roster[UnitClass("PLAYER")], "PLAYER")
		for i = 1, GetNumPartyMembers() do
			unit = "party"..i
			if (UnitAffectingCombat(unit)) then
				unitClass = UnitClass(unit)
				tinsert(roster[unitClass], unit)
				if (table.getn(roster[unitClass]) > table.getn(roster[class])) then
					class = unitClass
				end
				pet = "partypet"..i
				if (unitClass == "Hunter" and UnitName(pet)) then
					tinsert(roster["Warrior"], pet)
					if (table.getn(roster["Warrior"]) > table.getn(roster[class])) then
						class = "Warrior"
					end
				end
			end
		end
	end
	if (table.getn(roster[class]) == 0) then
		BlessingSpamCasting = false
		return
	end

	local targetingFriend = UnitIsFriend("player", "target")
	if (targetingFriend) then ClearTarget() end

	unit = roster[class][math.random(1, table.getn(roster[class]))]
	SetCVar("autoSelfCast", 0)
	CastSpell(BlessingSpamSpell, BOOKTYPE_SPELL)
	local tries = 0
	local maxRand = table.getn(roster[class])
	local maxTries = maxRand * 2
	while (not SpellCanTargetUnit(unit)) do
		unit = roster[class][math.random(1, maxRand)]
		tries = tries + 1
		if (tries == maxTries) then
			SetCVar("autoSelfCast", autoSelfCast)
			BlessingSpamCasting = false
			return
		end
	end
	SpellTargetUnit(unit)
	SetCVar("autoSelfCast", autoSelfCast)
	if (targetingFriend) then TargetLastTarget() end
	BlessingSpamCasting = false
end