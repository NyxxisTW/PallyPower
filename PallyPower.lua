local initalized = false

BINDING_HEADER_PALLYPOWER_HEADER = "Pally Power"
BINDING_NAME_TOGGLE = "Toggle Buff Bar"
BINDING_NAME_REPORT = "Report Assignments"

AllPallys = {}

PallyPower_Assignments = {}

PallyPower = {}

PP_Options = {
	ScaleMain = 1,		-- corner of main window docked to
	ScaleBar = 1,		-- corner menu window is docked from
	ScanFreq = 10,
	ScanPerFrame = 1,
	FiveMin = false,
	LeaderWarning = true,
	LeaderWarningMask = {
		Raid = PALLYPOWER_OPTIONS_LEADER_WARNING_DEFAULT_RAID,
		Party = PALLYPOWER_OPTIONS_LEADER_WARNING_DEFAULT_PARTY,
	},
	BlessingSpam = false,
	SalvationOnWarriors = true,
	WisdomOnMelees = true,
	MightOnCasters = true,
	MightOnHunters = true,
	MAssignPets = true,
	WarlockPets = false
}

PP_NextScan = PP_Options.ScanFreq

LastCast = {}
LastCastOn = {}
PP_Symbols = 0

Assignment = {}

CurrentBuffs = {}

PP_PREFIX = "PLPWR"

local PPSM_Excluded = {}

local function PP_UpdateBlessingIcons()
	if (PP_Options and PP_Options.FiveMin) then
		BlessingIcon = {
			[0] = "Interface\\Icons\\Spell_Holy_SealOfWisdom",					-- Wisdom
			[1] = "Interface\\Icons\\Spell_Holy_FistOfJustice",					-- Might
			[2] = "Interface\\Icons\\Spell_Holy_SealOfSalvation",				-- Salvation
			[3] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02",				-- Light
			[4] = "Interface\\Icons\\Spell_Magic_MageArmor",					-- Kings
			[5] = "Interface\\Icons\\Spell_Nature_LightningShield"				-- Sanctuary
		}
	else
		BlessingIcon = {
			[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom",		-- Wisdom
			[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings",		-- Might
			[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation",	-- Salvation
			[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight",		-- Light
			[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings",		-- Kings
			[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary"		-- Sanctuary
		}
	end
end
PP_UpdateBlessingIcons()

BuffIcon = {
	-- greater blessings
	[0] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom",		-- Wisdom
	[1] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofKings",		-- Might
	[2] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSalvation",	-- Salvation
	[3] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofLight",		-- Light
	[4] = "Interface\\Icons\\Spell_Magic_GreaterBlessingofKings",		-- Kings
	[5] = "Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary",	-- Sanctuary
	-- lesser blessings
	[6] = "Interface\\Icons\\Spell_Holy_SealOfWisdom",					-- Wisdom
	[7] = "Interface\\Icons\\Spell_Holy_FistOfJustice",					-- Might
	[8] = "Interface\\Icons\\Spell_Holy_SealOfSalvation",				-- Salvation
	[9] = "Interface\\Icons\\Spell_Holy_PrayerOfHealing02",				-- Light
	[10] = "Interface\\Icons\\Spell_Magic_MageArmor",					-- Kings
	[11] = "Interface\\Icons\\Spell_Nature_LightningShield"				-- Sanctuary
}

PallyPower_ClassTexture = {
	[0] = "Interface\\AddOns\\PallyPower\\Icons\\Warrior",
	[1] = "Interface\\AddOns\\PallyPower\\Icons\\Rogue",
	[2] = "Interface\\AddOns\\PallyPower\\Icons\\Priest",
	[3] = "Interface\\AddOns\\PallyPower\\Icons\\Druid",
	[4] = "Interface\\AddOns\\PallyPower\\Icons\\Paladin",
	[5] = "Interface\\AddOns\\PallyPower\\Icons\\Hunter",
	[6] = "Interface\\AddOns\\PallyPower\\Icons\\Mage",
	[7] = "Interface\\AddOns\\PallyPower\\Icons\\Warlock",
	[8] = "Interface\\AddOns\\PallyPower\\Icons\\Shaman",
	[9] = "Interface\\Icons\\Ability_hunter_beasttraining"
}

local START_COLOR = '\124CFF'
local END_COLOR = '\124r'
local PP_COLOR = "F48CBA"

local function Print(msg, r, g, b, a)
	DEFAULT_CHAT_FRAME:AddMessage(START_COLOR..PP_COLOR.."[Pally Power]: "..END_COLOR..tostring(msg), r, g, b, a)
end


function PallyPower_Report()
	local groupType
	if (GetNumRaidMembers() > 0) then
		groupType = "RAID"
	else
		groupType = "PARTY"
	end
	SendChatMessage(PallyPower_Assignments1, groupType)
	for name in AllPallys do
		local blessings
		local list = {
			[0] = 0,
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 0,
			[5] = 0,
		}
		for id = 0, 9 do
			local bid = PallyPower_Assignments[name][id]
			if (bid >= 0) then
				list[bid] = list[bid] + 1
			end
		end
		for id = 0, 5 do
			if (list[id] > 0) then
				if (blessings) then
					blessings = blessings..", "
				else
					blessings = ""
				end
				blessings = blessings..PallyPower_BlessingID[id]
			end
		end
		if (not blessings) then
			blessings = "Nothing"
		end
		SendChatMessage(name..": "..blessings, groupType)
	end
	SendChatMessage(PallyPower_Assignments2, groupType)
end

function PallyPower_GetBuffDuration()
	if (PP_Options.FiveMin) then
		return 60 * 5
	end
	return 60 * 15
end

function PallyPower_GetNumMAssign()
	-- used in loops indexed from 0
	if (PP_Options.MAssignPets) then
		return 9
	end
	return 8
end

function PallyPower_FormatTime(time)
	if (not time or time < 0) then
		return ""
	end
	mins = floor(time / 60)
	secs = time - (mins * 60)
	return string.format("%d:%02d", mins, secs)
end
  
function PallyPowerGrid_Update()
	if (not initalized) then PallyPower_ScanSpells() end
	-- Pally 1 is always myself
	local i = 1
	local numPallys = 0
	local name, skills
	if (PallyPowerFrame:IsVisible()) then
		PallyPowerFrame:SetScale(PP_Options.ScaleMain)
		for name, skills in AllPallys do
			getglobal("PallyPowerFramePlayer"..i.."Name"):SetText(name)
			getglobal("PallyPowerFramePlayer"..i.."Symbols"):SetText(skills["symbols"])
			getglobal("PallyPowerFramePlayer"..i.."Symbols"):SetTextColor(1,1,0.5)
			if (PallyPower_CanControl(name)) then
				getglobal("PallyPowerFramePlayer"..i.."Name"):SetTextColor(1,1,1)
			elseif (PallyPower_CheckRaidLeader(name)) then
				getglobal("PallyPowerFramePlayer"..i.."Name"):SetTextColor(0,1,0)
			else
				getglobal("PallyPowerFramePlayer"..i.."Name"):SetTextColor(1,0,0)
			end
			for id = 0, 5 do
				if (skills[id]) then
					getglobal("PallyPowerFramePlayer"..i.."Icon"..id):Show()
					getglobal("PallyPowerFramePlayer"..i.."Skill"..id):Show()
					local txt = skills[id]["rank"]
					if (skills[id]["talent"] + 0 > 0) then
						txt = txt.."+"..skills[id]["talent"]
					end
					getglobal("PallyPowerFramePlayer"..i.."Skill"..id):SetText(txt)
				else
					getglobal("PallyPowerFramePlayer"..i.."Icon"..id):Hide()
					getglobal("PallyPowerFramePlayer"..i.."Skill"..id):Hide()
				end
			end
			for id = 0, 9 do
				if (PallyPower_Assignments[name]) then
					getglobal("PallyPowerFramePlayer"..i.."Class"..id.."Icon"):SetTexture(BlessingIcon[PallyPower_Assignments[name][id]])
				else
					getglobal("PallyPowerFramePlayer"..i.."Class"..id.."Icon"):SetTexture(nil)
				end
			end
			i = i + 1
			numPallys = numPallys + 1
		end
		PallyPowerFrame:SetHeight(14 + 24 + 56 + (numPallys * 56) + 22 ) -- 14 from border, 24 from Title, 56 from space for class icons, 56 per paladin, 22 for Buttons at bottom
		for i = 1, 12 do
			if (i <= numPallys) then
				getglobal("PallyPowerFramePlayer"..i):Show()
			else
				getglobal("PallyPowerFramePlayer"..i):Hide()
			end
		end
	end
end

function PallyPower_UpdateUI()
	if (not initalized) then PallyPower_ScanSpells() end
	-- Buff Bar
	PallyPowerBuffBar:SetScale(PP_Options.ScaleBar)
	if (not PP_IsPally) then
		PallyPowerBuffBar:Hide()
	else
		PallyPowerBuffBar:Show()
		PallyPowerBuffBarTitleText:SetText(format(PallyPower_BuffBarTitle, PP_Symbols))
		BuffNum = 1
		if (PallyPower_Assignments[UnitName("player")]) then
			local assign = PallyPower_Assignments[UnitName("player")]
			for class = 0, 9 do
				if (assign[class] and assign[class] ~= -1) then
					getglobal("PallyPowerBuffBarBuff"..BuffNum.."ClassIcon"):SetTexture(PallyPower_ClassTexture[class])
					getglobal("PallyPowerBuffBarBuff"..BuffNum.."BuffIcon"):SetTexture(BlessingIcon[assign[class]])
					local btn = getglobal("PallyPowerBuffBarBuff"..BuffNum)
					btn.classID = class
					btn.buffID = assign[class]
					btn.need = {}
					btn.have = {}
					btn.range = {}
					btn.dead = {}
					-- Calculate number of people who need buff.
					local nneed = 0
					local ndead = 0
					local nhave = 0
					if (CurrentBuffs[class]) then
						for member, stats in CurrentBuffs[class] do
							if (stats["visible"]) then
								if (string.find(BlessingIcon[assign[class]], "Salvation") and PPSM_Excluded[UnitName(member)] == true) then
									if (UnitIsDeadOrGhost(member)) then
										ndead = ndead + 1
									else
										nhave = nhave + 1
									end
									--nppsm = nppsm + 1
								elseif (not stats[assign[class]]) then
									if (UnitIsDeadOrGhost(member)) then
										ndead = ndead + 1
										tinsert(btn.dead, stats["name"])
									else
										nneed = nneed + 1
										tinsert(btn.need, stats["name"])
									end
								else
									tinsert(btn.have, stats["name"])
									nhave = nhave + 1
								end
							else
								tinsert(btn.range, stats["name"])
								nhave = nhave + 1
							end
						end
					end
					if (ndead > 0) then
						getglobal("PallyPowerBuffBarBuff"..BuffNum.."Text"):SetText(nneed.." ("..ndead..")")
					else
						getglobal("PallyPowerBuffBarBuff"..BuffNum.."Text"):SetText(nneed)
					end		  
					getglobal("PallyPowerBuffBarBuff"..BuffNum.."Time"):SetText(PallyPower_FormatTime(LastCast[assign[class]..class]))

					if (nneed > 0 or nhave > 0) then
						BuffNum = BuffNum + 1
						if (nhave == 0) then
							btn:SetBackdropColor(1.0, 0.0, 0.0, 0.5)
						elseif (nneed > 0) then
							btn:SetBackdropColor(1.0, 1.0, 0.5, 0.5)
						else
							btn:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
						end
						btn:Show()
					end
				end
			end
		end
		for rest = BuffNum, 10 do
			local btn = getglobal("PallyPowerBuffBarBuff"..rest)
			btn:Hide()
		end
		PallyPowerBuffBar:SetHeight(30 + (34 * (BuffNum-1)))
	end
end


function PallyPower_ScanSpells()
	local RankInfo = {}
	local i = 1
	while true do
		local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
		local spellTexture = GetSpellTexture(i, BOOKTYPE_SPELL)
		if (not spellName) then
			do break end
		end
		if (not spellRank or spellRank == "") then
			spellRank = PallyPower_Rank1
		end
		local _, _, bless = string.find(spellName, PallyPower_BlessingSpellSearch)
		local greater = string.find(spellName, PallyPower_GreaterBlessingSpellSearch)
		if (bless and (not PP_Options.FiveMin or not greater)) then
			for id, name in PallyPower_BlessingID do
				if (name == bless) then
					local _, _, rank = string.find(spellRank, PallyPower_RankSearch)
					if (not (RankInfo[id] and spellRank < RankInfo[id]["rank"])) then
						RankInfo[id] = {}
						RankInfo[id]["rank"] = rank
						RankInfo[id]["id"] = i
						RankInfo[id]["name"] = name
						RankInfo[id]["talent"] = 0
						RankInfo[id]["greater"] = greater
					end
				end
			end
		end
		i = i + 1
	end
	local numTabs = GetNumTalentTabs()
	for t = 1, numTabs do
		local numTalents = GetNumTalents(t)
		for i = 1, numTalents do
			nameTalent, icon, iconx, icony, currRank, maxRank = GetTalentInfo(t, i)
			local _, _, bless = string.find(nameTalent, PallyPower_BlessingTalentSearch)
			local greater = string.find(nameTalent, PallyPower_GreaterBlessingSpellSearch)
			if (bless and (not PP_Options.FiveMin or not greater)) then
				initalized = true
				for id, name in PallyPower_BlessingID do
					if (name == bless) then
						if (RankInfo[id]) then
							RankInfo[id]["talent"] = currRank
						end
					end
				end
			end
		end
	end
	_, class = UnitClass("player")
	if (class == "PALADIN") then
		AllPallys[UnitName("player")] = RankInfo
		if (initalized) then
			PallyPower_SendSelf()
		end
		PP_IsPally = true
	else
		PP_IsPally = nil
		initalized = true
	end
	PallyPower_ScanInventory()
end

function PallyPower_Refresh()
	AllPallys = {}
	PP_UpdateBlessingIcons()
	PallyPower_ScanSpells()
	PallyPower_SendSelf()
	PallyPower_RequestSend()
	PallyPower_UpdateUI()
end

function PallyPower_SendMessage(msg)
	if (GetNumRaidMembers() == 0) then
		SendAddonMessage(PP_PREFIX, msg, "PARTY", UnitName("player"))
	else
		SendAddonMessage(PP_PREFIX, msg, "RAID", UnitName("player"))
	end
end

function PallyPower_Clear(fromupdate, who)
	if (not who) then
		who = UnitName("player")
	end
	for name, skills in PallyPower_Assignments do
		if (PallyPower_CheckRaidLeader(who) or name == who) then
			for class, id in PallyPower_Assignments[name] do
				PallyPower_Assignments[name][class] = -1
			end
		end
	end
	PallyPower_UpdateUI()
	if (not fromupdate) then
		PallyPower_SendMessage("CLEAR")
	end
end

function PallyPower_RequestSend()
	PallyPower_SendMessage("REQ")
end

function PallyPower_SendSelf()
	if (not initalized) then
		PallyPower_ScanSpells()
	end
	if (not AllPallys[UnitName("player")]) then
		return
	end
	msg = "SELF "
	local RankInfo = AllPallys[UnitName("player")]
	for id = 0, 5 do
		if (not RankInfo[id]) then
			msg = msg.."nn"
		elseif (not RankInfo[id]["greater"]) then
			msg = msg.."nn"
		else
			msg = msg..RankInfo[id]["rank"]
			msg = msg..RankInfo[id]["talent"]
		end
	end
	msg = msg.."@"
	for id = 0, 9 do
		if (not PallyPower_Assignments[UnitName("player")]) or
			not PallyPower_Assignments[UnitName("player")][id] or
			PallyPower_Assignments[UnitName("player")][id] == -1
			then
			msg = msg.."n"
		else
			msg = msg..PallyPower_Assignments[UnitName("player")][id]
		end
	end
	PallyPower_SendMessage(msg)
	PallyPower_SendMessage("SYMCOUNT "..PP_Symbols)
end

function PallyPower_ParseMessage(sender, msg)
	if (string.sub(msg, 1, 5) == "SALV ") then
		local value = string.sub(msg, 6, 6)
		local exName = string.sub(msg, 8)
		PPSM_Excluded[exName] = (value == "1")
	end
	if (sender == UnitName("player")) then
		return
	end
	if (msg == "REQ") then
		PallyPower_SendSelf()
	end
	if (string.find(msg, "^SELF")) then
		PallyPower_Assignments[sender] = {}
		AllPallys[sender] = {}
		_, _, numbers, assign = string.find(msg, "SELF ([0-9n]*)@?([0-9n]*)")
		for id = 0, 5 do
			rank = string.sub(numbers, id * 2 + 1, id * 2 + 1)
			talent = string.sub(numbers, id * 2 + 2, id * 2 + 2)
			if (rank ~= "n") then
				AllPallys[sender][id] = {}
				AllPallys[sender][id]["rank"] = rank
				AllPallys[sender][id]["talent"] = talent
			end
		end
		if (assign) then
			for id = 0, 9 do
				tmp = string.sub(assign, id + 1, id + 1)
				if (tmp == "n" or tmp == "") then
					tmp = -1
				end
				PallyPower_Assignments[sender][id] = tmp + 0
			end
		end
		PallyPower_UpdateUI()
	end
	if (string.find(msg, "^ASSIGN")) then
		_, _, name, class, skill = string.find(msg, "^ASSIGN (.*) (.*) (.*)")
		if (name ~= sender and not PallyPower_CheckRaidLeader(sender)) then
			return false
		end
		if (not PallyPower_Assignments[name]) then
			PallyPower_Assignments[name] = {}
		end
		class = class + 0
		skill = skill + 0
		PallyPower_Assignments[name][class] = skill
		PallyPower_UpdateUI()
	end
	if (string.find(msg, "^MASSIGN")) then
		_, _, name, skill = string.find(msg, "^MASSIGN (.*) (.*)")
		if (name ~= sender and not PallyPower_CheckRaidLeader(sender)) then
			return false
		end
		if (not PallyPower_Assignments[name]) then
			PallyPower_Assignments[name] = {}
		end
		skill = skill + 0
		for class = 0, 9 do
			PallyPower_Assignments[name][class] = skill
		end
		PallyPower_UpdateUI()
	end
	if (string.find(msg, "^SYMCOUNT ([0-9]*)")) then
		_, _, count = string.find(msg, "^SYMCOUNT ([0-9]*)")
		if (AllPallys[sender]) then
			AllPallys[sender]["symbols"] = count
		else
			PallyPower_SendMessage("REQ")
		end
	end
	if (string.find(msg, "^CLEAR")) then
		PallyPower_Clear(true, sender)
	end
end


function PallyPower_ShowCredits()
   GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
   GameTooltip:SetText(PallyPower_Credits1, 1, 1, 1)
   GameTooltip:AddLine(PallyPower_Credits2, 1, 1, 1)
   GameTooltip:AddLine(PallyPower_Credits3)
   GameTooltip:AddLine(PallyPower_Credits4, 0, 1, 0)
   GameTooltip:AddLine(PallyPower_Credits5)
   GameTooltip:Show()
end

function PallyPower_ShowLeaderWarningLegend()
	GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
	GameTooltip:SetText("Legend:")
	GameTooltip:AddLine("1 - left mark", 1, 1, 1)
	GameTooltip:AddLine("2 - right mark", 1, 1, 1)
	GameTooltip:AddLine("4 - text", 1, 1, 1)
	GameTooltip:AddLine("8 - sound", 1, 1, 1)
	GameTooltip:Show()
end

function PallyPowerFrame_MouseDown(arg1)
	if ((not PallyPowerFrame.isLocked or PallyPowerFrame.isLocked == 0) and arg1 == "LeftButton") then
		PallyPowerFrame:StartMoving()
		PallyPowerFrame.isMoving = true
	end
end

function PallyPowerFrame_MouseUp()
	if (PallyPowerFrame.isMoving) then
		PallyPowerFrame:StopMovingOrSizing()
		PallyPowerFrame.isMoving = false
	end
end

function PallyPowerBuffBar_MouseDown(arg1)
	if ((not PallyPowerBuffBar.isLocked or PallyPowerBuffBar.isLocked == 0) and arg1 == "LeftButton") then
		PallyPowerBuffBar:StartMoving()
		PallyPowerBuffBar.isMoving = true
		PallyPowerBuffBar.startPosX = PallyPowerBuffBar:GetLeft()
		PallyPowerBuffBar.startPosY = PallyPowerBuffBar:GetTop()
	end
end

function PallyPowerBuffBar_MouseUp()
	if (PallyPowerBuffBar.isMoving) then
		PallyPowerBuffBar:StopMovingOrSizing()
		PallyPowerBuffBar.isMoving = false
	end
	if (abs(PallyPowerBuffBar.startPosX - PallyPowerBuffBar:GetLeft()) < 2 and
		abs(PallyPowerBuffBar.startPosY - PallyPowerBuffBar:GetTop()) < 2)
	then
		if (PallyPowerBuffBarTitleMarkLeft:IsShown() or PallyPowerBuffBarTitleMarkRight:IsShown()) then
			PallyPowerBuffBarTitleMarkLeft:Hide()
			PallyPowerBuffBarTitleMarkRight:Hide()
			PallyPower_RequestSend()
			PallyPower_ScanRaid()
			PallyPower_UpdateUI()
		end
		PallyPowerFrame:Show()
		PallyPower_UpdateUI()
	end
end

function PallyPowerGridButton_OnLoad(btn)
end

function PallyPowerGridButton_OnClick(btn, mouseBtn)
	_,_, pnum, class = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)")
	pnum = pnum + 0
	class = class + 0
	pname = getglobal("PallyPowerFramePlayer"..pnum.."Name"):GetText()
	if (not PallyPower_CanControl(pname)) then
		return false
	end
	if (mouseBtn == "RightButton") then
		PallyPower_Assignments[pname][class] = -1
		PallyPower_UpdateUI()
		PallyPower_SendMessage("ASSIGN "..pname.." "..class.." -1")
	else
		PallyPower_PerformCycle(pname, class)
	end
end

function PallyPowerGridButton_OnLeave(btn)
end

function PallyPowerGridButton_OnEnter(btn)
end

function PallyPower_PerformCycleBackwards(name, class)
	shift = IsShiftKeyDown()
	if (shift) then
		class = 4 -- force pala (all buff possible) when shift wheeling
	end
	if (not PallyPower_Assignments[name][class]) then
		cur = 6
	else
		cur = PallyPower_Assignments[name][class]
		if (cur == -1) then
			cur = 6
		end
	end
	PallyPower_Assignments[name][class] = -1
	for test = cur - 1, -1, -1 do
		cur = test
		if (PallyPower_CanBuff(name, test) and (PallyPower_NeedsBuff(class, test) or shift)) then
			do break end
		end
	end
	if (shift) then
		for test = 0, PallyPower_GetNumMAssign() do
			PallyPower_Assignments[name][test] = cur
		end
		PallyPower_SendMessage("MASSIGN "..name.." "..cur)
		if (not PP_Options.MAssignPets) then
			PallyPower_SendMessage("ASSIGN "..name.." 9 "..PallyPower_Assignments[name][9])
		end
	else
		PallyPower_Assignments[name][class] = cur
		PallyPower_SendMessage("ASSIGN "..name.." "..class.." "..cur)
	end
	PallyPower_UpdateUI()
end

function PallyPower_PerformCycle(name, class)
	shift = IsShiftKeyDown()
	if (shift) then
		class = 4 -- force pala (all buff possible) when shift wheeling
	end
	if (not PallyPower_Assignments[name][class]) then
		cur = -1
	else
		cur = PallyPower_Assignments[name][class]
	end
	PallyPower_Assignments[name][class] = -1
	for test = cur + 1, 6 do
		if (PallyPower_CanBuff(name, test) and (PallyPower_NeedsBuff(class, test) or shift)) then
			cur = test
			do break end
		end
	end
	if (cur == 6) then
		cur = -1
	end
	if (shift) then
		for test = 0, PallyPower_GetNumMAssign() do
			PallyPower_Assignments[name][test] = cur
		end
		PallyPower_SendMessage("MASSIGN "..name.." "..cur)
		if (not PP_Options.MAssignPets) then
			PallyPower_SendMessage("ASSIGN "..name.." 9 "..PallyPower_Assignments[name][9])
		end
	else
		PallyPower_Assignments[name][class] = cur
		PallyPower_SendMessage("ASSIGN "..name.." "..class.." "..cur)
	end
	PallyPower_UpdateUI()
end

function PallyPower_CanBuff(name, test)
	if (test == 6) then 
		return true
	end
	if (not AllPallys[name][test] or AllPallys[name][test]["rank"] == 0) then
		return false
	end
	return true
end

function PallyPower_NeedsBuff(class, test)
	if (test == 6 or test == -1) then 
		return true
	end
	if (not PP_Options.SalvationOnWarriors) then
		if (class == 0 and test == 2) then
			return false
		end
	end
	if (not PP_Options.WisdomOnMelees) then
		if ((class == 0 or class == 1 or class == 9) and test == 0) then
			return false
		end
	end
	if (not PP_Options.MightOnCasters) then
		if ((class == 2 or class == 6 or class == 7) and test == 1) then
			return false
		end
	end
	if (not PP_Options.MightOnHunters) then
		if (class == 5 and test == 1) then
			return false
		end
	end
	for name, skills in PallyPower_Assignments do
		if (AllPallys[name] and skills[class] and skills[class] == test) then
			return false
		end
	end
	return true
end

function PallyPower_CheckRaidLeader(nick)
	if (GetNumRaidMembers() == 0) then
		for i = 1, GetNumPartyMembers(), 1 do
			if (nick == UnitName("party"..i) and UnitIsPartyLeader("party"..i)) then 
				return true 
			end
		end
		return false
	end
	for i = 1, GetNumRaidMembers(), 1 do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead = GetRaidRosterInfo(i)
		if (rank >= 1 and name == nick) then
			return true
		end
	end
	return false
end

function PallyPower_CanControl(name)
	return (IsPartyLeader() or IsRaidLeader() or IsRaidOfficer() or (name == UnitName("player")))
end

function PallyPower_ScanInventory()
	if (not PP_IsPally) then return end
	oldcount = PP_Symbols
	PP_Symbols = 0
	for bag = 0, 4 do
		local bagslots = GetContainerNumSlots(bag)
		if (bagslots) then
			for slot = 1, bagslots do
				local link = GetContainerItemLink(bag, slot)
				if (link and string.find(link, PallyPower_Symbol)) then
					local _, count, locked = GetContainerItemInfo(bag, slot)
					PP_Symbols = PP_Symbols + count
				end
			end
		end
	end
	if (PP_Symbols ~= oldcount) then
		PallyPower_SendMessage("SYMCOUNT "..PP_Symbols)
	end
	AllPallys[UnitName("player")]["symbols"] = PP_Symbols
end

function PallyPower_Mod(a, b)
	return a - math.floor(a / b) * b
end

function PallyPower_BitAnd(a, b)
	local result = 0
	local bitval = 1
	while a > 0 and b > 0 do
		if ((PallyPower_Mod(a, 2) == 1) and (PallyPower_Mod(b, 2) == 1)) then
			result = result + bitval
		end
		bitval = bitval * 2
		a = math.floor(a / 2)
		b = math.floor(b / 2)
	end
	return result
end

local function GetPlayerRaidRole(numRaidMembers)
	local playerRole = -1
	local playerName = UnitName("player")
	for i = 1, numRaidMembers do
		if (playerName == UnitName("raid"..i)) then
			_, playerRole = GetRaidRosterInfo(i)
			break
		end
	end
	return playerRole
end

function PallyPower_ScanLeaderWarning()
	local numRaidMembers = GetNumRaidMembers()
	local numPartyMembers = GetNumPartyMembers()

	if ((not PP_Options.LeaderWarningMask) or
		(type(PP_Options.LeaderWarningMask ~= "table")) or
		(not PP_Options.LeaderWarningMask.Raid) or
		(not PP_Options.LeaderWarningMask.Party))
	then
		PP_Options.LeaderWarningMask = {
			Raid = PALLYPOWER_OPTIONS_LEADER_WARNING_DEFAULT_RAID,
			Party = PALLYPOWER_OPTIONS_LEADER_WARNING_DEFAULT_PARTY,
		}
	end

	if (numRaidMembers > 0) then
		if ((PP_Options.LeaderWarningMask.Raid <= 0) or (PP_Options.LeaderWarningMask.Raid > 15)) then
			return
		end
		local numPaladins = 0
		if (GetPlayerRaidRole(numRaidMembers) > 0) then
			for i = 1, numRaidMembers do
				if (UnitClass("raid"..i) == "Paladin") then
					numPaladins = numPaladins + 1
				end
			end

			if ((PP_NumPaladins_Old ~= nil) and (numPaladins ~= PP_NumPaladins_Old)) then
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Raid, 1) ~= 0) then
					PallyPowerBuffBarTitleMarkLeft:Show()
				end
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Raid, 2) ~= 0) then
					PallyPowerBuffBarTitleMarkRight:Show()
				end
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Raid, 4) ~= 0) then
					Print("Paladin roster update!")
				end
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Raid, 8) ~= 0) then
					PlaySound("RaidWarning", "master")
				end
			end
		end
		PP_NumPaladins_Old = numPaladins

	elseif (numPartyMembers > 0) then
		if ((PP_Options.LeaderWarningMask.Party <= 0) or (PP_Options.LeaderWarningMask.Party > 15)) then
			return
		end
		local numPaladins
		if (PP_IsPally) then numPaladins = 1 else numPaladins = 0 end
		for i = 1, numPartyMembers do
			if (UnitClass("party"..i) == "Paladin") then
				numPaladins = numPaladins + 1
			end

			if ((PP_NumPaladins_Old ~= nil) and (numPaladins ~= PP_NumPaladins_Old)) then
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Party, 1) ~= 0) then
					PallyPowerBuffBarTitleMarkLeft:Show()
				end
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Party, 2) ~= 0) then
					PallyPowerBuffBarTitleMarkRight:Show()
				end
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Party, 4) ~= 0) then
					Print("Paladin roster update!")
				end
				if (PallyPower_BitAnd(PP_Options.LeaderWarningMask.Party, 8) ~= 0) then
					PlaySound("RaidWarning", "master")
				end
			end
		end
		PP_NumPaladins_Old = numPaladins
	else
		PP_NumPaladins_Old = 1
	end
end

PP_ScanInfo = nil

function PallyPower_ScanRaid()
	if (not PP_IsPally) then
		return false
	end
	PallyPower_ScanLeaderWarning()
	if (not PP_ScanInfo) then
		PP_Scanners = {}
		PP_ScanInfo = {}
		if (GetNumRaidMembers() > 0) then
			for i = 1, GetNumRaidMembers() do
				tinsert(PP_Scanners, "raid"..i)
			end
		else
			tinsert(PP_Scanners, "player")
			for i = 1, GetNumPartyMembers() do
				tinsert(PP_Scanners, "party"..i)
			end
		end
	end
	local tests = PP_Options.ScanPerFrame
	if (not tests) then
		tests = 1
	end
	while PP_Scanners[1] do
		unit = PP_Scanners[1]
		local name = UnitName(unit)
		local class = UnitClass(unit)
		if (name and class) then
			local cid = PallyPower_GetClassID(class)
			--	hunters (5) and warlocks (7)
			if (cid == 5 or (cid == 7 and PP_Options.WarlockPets)) then
				local petId = "raidpet"..string.sub(unit, 5)
				local petName = UnitName(petId)
				if (petName) then
					local classID = 9
					if (not PP_ScanInfo[classID]) then
						PP_ScanInfo[classID] = {}
					end

					PP_ScanInfo[classID][petId] = {}
					PP_ScanInfo[classID][petId]["name"] = petName
					PP_ScanInfo[classID][petId]["visible"] = UnitIsVisible(petId)

					local j = 1
					while UnitBuff(petId, j, true) do
						local buffIcon, _ = UnitBuff(petId, j, true)
						local txtID = PallyPower_GetBuffTextureID(buffIcon)
						if (txtID > 5) then
							txtID = txtID - 6
						end
						PP_ScanInfo[classID][petId][txtID] = true
						j = j + 1
					end
				end
			end

			if (not PP_ScanInfo[cid]) then
				PP_ScanInfo[cid] = {}
			end
			PP_ScanInfo[cid][unit] = {}	
			PP_ScanInfo[cid][unit]["name"] = name
			PP_ScanInfo[cid][unit]["visible"] = UnitIsVisible(unit)
			
			local j = 1
			while UnitBuff(unit, j, true) do
				local buffIcon, _ = UnitBuff(unit, j, true)
				local txtID = PallyPower_GetBuffTextureID(buffIcon)
				if (txtID > 5) then
					txtID = txtID - 6
				end
				PP_ScanInfo[cid][unit][txtID] = true
				j = j + 1
			end
		end
		tremove(PP_Scanners, 1)
		tests = tests - 1
		if (tests <= 0) then
			return false
		end
	end
	CurrentBuffs = PP_ScanInfo
	PP_ScanInfo = nil
	PP_NextScan = PP_Options.ScanFreq
	PallyPower_ScanInventory()
	return true
end

function PallyPower_GetClassID(class)
	for id, name in PallyPower_ClassID do
		if (name == class) then 
			return id
		end
	end
	return -1
end

function PallyPower_GetBuffTextureID(text)
	for id, name in BuffIcon do
		if (name == text) then
			return id
		end
	end
	return -2
end

function PallyPowerBuffButton_OnLoad(btn)
	this:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
end

function PallyPowerBuffButton_OnClick(btn, mousebtn)
	local targetingFriend = UnitIsFriend("player", "target")
	if (targetingFriend) then ClearTarget() end
	local scStatus = GetCVar("autoSelfCast")
	SetCVar("autoSelfCast", 0)
	local spell = AllPallys[UnitName("player")][btn.buffID]["id"]
	CastSpell(spell, BOOKTYPE_SPELL)
	local RecentCast = false
	if (LastCast[btn.buffID..btn.classID] and LastCast[btn.buffID..btn.classID] > PallyPower_GetBuffDuration() - 30) then
		RecentCast = true
	end
	for unit, stats in CurrentBuffs[btn.classID] do
		if (SpellCanTargetUnit(unit) and (not (RecentCast and string.find(table.concat(LastCastOn[btn.classID], " "), unit)) or PP_Options.BlessingSpam)) then
			SpellTargetUnit(unit)
			PP_NextScan = 1
			LastCast[btn.buffID..btn.classID] = PallyPower_GetBuffDuration()
			if (not RecentCast) then
				LastCastOn[btn.classID] = {}
			end
			tinsert(LastCastOn[btn.classID], unit)
			PallyPower_ShowFeedback(format(PallyPower_Casting, PallyPower_BlessingID[btn.buffID], PallyPower_ClassID[btn.classID], UnitName(unit)), 0.0, 1.0, 0.0)
			if (targetingFriend) then TargetLastTarget() end
			SetCVar("autoSelfCast", scStatus)
			return
		end
	end
	SpellStopTargeting()
	if (targetingFriend) then TargetLastTarget() end
	PallyPower_ShowFeedback(format(PallyPower_CouldntFind, PallyPower_BlessingID[btn.buffID], PallyPower_ClassID[btn.classID]), 0.0, 1.0, 0.0)
	SetCVar("autoSelfCast", scStatus)
end

function PallyPowerBuffButton_OnEnter(btn)
	GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
	GameTooltip:SetText(PallyPower_ClassID[btn.classID]..PallyPower_BuffFrameText..PallyPower_BlessingID[btn.buffID], 1, 1, 1)
	GameTooltip:AddLine(PallyPower_Have..table.concat(btn.have, ", "), 0.5, 1, 0.5)
	GameTooltip:AddLine(PallyPower_Need..table.concat(btn.need, ", "), 1, 0.5, 0.5)
	GameTooltip:AddLine(PallyPower_NotHere..table.concat(btn.range, ", "), 0.5, 0.5, 1)
	GameTooltip:AddLine(PallyPower_Dead..table.concat(btn.dead, ", "), 1, 0, 0)
	GameTooltip:Show()
end

function PallyPowerBuffButton_OnLeave(btn)
	GameTooltip:Hide()
end

--[[ MainFrame and MenuFrame Scaling ]]--

function PallyPower_StartScaling(arg1)
	if (arg1 == "LeftButton") then
		this:LockHighlight()
		PallyPower.FrameToScale = this:GetParent()
		PallyPower.ScalingWidth = this:GetParent():GetWidth() * PallyPower.FrameToScale:GetParent():GetEffectiveScale()
		PallyPower.ScalingHeight = this:GetParent():GetHeight() * PallyPower.FrameToScale:GetParent():GetEffectiveScale()
		PallyPower_ScalingFrame:Show()
	end
end

function PallyPower_StopScaling(arg1)
	if (arg1 == "LeftButton") then
		PallyPower_ScalingFrame:Hide()
		PallyPower.FrameToScale = nil
		this:UnlockHighlight()
	end
end

local function really_setpoint(frame, point, relativeTo, relativePoint, xoff, yoff)
	frame:SetPoint(point, relativeTo, relativePoint, xoff, yoff)
end

function PallyPower_ScaleFrame(scale)
	local frame = PallyPower.FrameToScale
	local oldscale = frame:GetScale() or 1
	local framex = (frame:GetLeft() or PallyPowerPerOptions.XPos) * oldscale
	local framey = (frame:GetTop() or PallyPowerPerOptions.YPos) * oldscale
  
	frame:SetScale(scale)
	if (frame:GetName() == "PallyPowerFrame") then
		really_setpoint(PallyPowerFrame, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
		PP_Options.ScaleMain = scale
	end
	if (frame:GetName() == "PallyPowerBuffBar") then
		really_setpoint(PallyPowerBuffBar, "TOPLEFT", "UIParent", "BOTTOMLEFT", framex / scale, framey / scale)
		PP_Options.ScaleBar = scale
	end
end

function PallyPower_ScalingFrame_OnUpdate(arg1)
	if (not PallyPower.ScalingTime) then
		PallyPower.ScalingTime = 0
	end
	PallyPower.ScalingTime = PallyPower.ScalingTime + arg1
	if (PallyPower.ScalingTime > 0.25) then
		PallyPower.ScalingTime = 0
		local frame = PallyPower.FrameToScale
		local oldscale = frame:GetEffectiveScale()
		local framex, framey, cursorx, cursory = frame:GetLeft() * oldscale, frame:GetTop() * oldscale, GetCursorPosition()
		if (PallyPower.ScalingWidth>PallyPower.ScalingHeight) then
			if ((cursorx - framex) > 32) then
				local newscale = (cursorx - framex) / PallyPower.ScalingWidth
				PallyPower_ScaleFrame(newscale)
			end
		elseif ((framey - cursory) > 32) then
			local newscale = (framey - cursory) / PallyPower.ScalingHeight
			PallyPower_ScaleFrame(newscale)
		end
	end
end

function PallyPower_Options()
	--PallyPowerFrame:Hide()
	PallyPower_OptionsFrame:Show()
end

function PallyPower_ShowFeedback(msg, r, g, b, a)
	if (PP_Options.ChatFeedback) then
		Print(msg, r, g, b, a)
	else
		UIErrorsFrame:AddMessage(msg, r, g, b, a)
	end
end

function PallyPowerGridButton_OnMouseWheel(btn, arg1)
	_, _, pnum, class = string.find(btn:GetName(), "PallyPowerFramePlayer(.+)Class(.+)")
	pnum = pnum + 0
	class = class + 0
	pname = getglobal("PallyPowerFramePlayer"..pnum.."Name"):GetText()
	if (not PallyPower_CanControl(pname)) then
		return false
	end
	if (arg1 == -1) then -- mouse wheel down
		PallyPower_PerformCycle(pname, class)
	else
		PallyPower_PerformCycleBackwards(pname, class)
	end
end

function PallyPower_BarToggle()
	if ((GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) or (not PP_IsPally)) then
		PallyPower_ShowFeedback(" Not in raid or not a paladin", 0.5, 1, 1, 1)
	elseif (PallyPowerBuffBar:IsVisible()) then
		PallyPowerBuffBar:Hide()
		PallyPower_ShowFeedback(" Bar hidden", 0.5, 1, 1, 1)
	else
		
		PallyPowerBuffBar:Show()
		PallyPower_ShowFeedback(" Bar visible", 0.5, 1, 1, 1)
	end
end


function PallyPower_OnUpdate(tdiff)
	if (not PP_Options.ScanFreq) then
		PP_Options.ScanFreq = 10
		PP_Options.ScanPerFrame = 1
	end
	PP_NextScan = PP_NextScan - tdiff
	if (PP_NextScan < 0 and PP_IsPally) then
		if (PallyPower_ScanRaid()) then PallyPower_UpdateUI() end
	end
	for i, k in LastCast do
		LastCast[i] = k - tdiff
	end
end

function PallyPower_OnEvent(event)
	if (event == "VARIABLES_LOADED") then
		PallyPower_SendMessage("PPSM")
	elseif (event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD") then
		PP_UpdateBlessingIcons()
		PallyPower_ScanSpells()
	elseif (event == "PLAYER_ENTERING_WORLD" and (not PallyPower_Assignments[UnitName("player")])) then
		PallyPower_Assignments[UnitName("player")] = {}
	elseif (event == "CHAT_MSG_ADDON" and arg1 == PP_PREFIX and (arg3 == "PARTY" or arg3 == "RAID")) then
		PallyPower_ParseMessage(arg4, arg2)
	elseif (event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" and PP_NextScan > 1) then
		PP_NextScan = 1
	elseif (event == "PLAYER_LOGIN") then
		PallyPower_UpdateUI()
	elseif (event == "PARTY_MEMBERS_CHANGED") then
		PallyPower_ScanRaid()
		PallyPower_UpdateUI()
	end
end

function PallyPower_SlashCommandHandler(msg)
	if (msg == "report") then
		PallyPower_Report()
		return
	end
	if (msg == "show") then
		if (not PP_IsPally and UnitClass("player") ~= "Paladin") then
			DEFAULT_CHAT_FRAME:AddMessage("You are not a paladin.", 1, 0, 0)
			return
		end
		PallyPowerBuffBar:Show()
		return
	end
	if (msg == "hide") then
		PallyPowerBuffBar:Hide()
		return
	end
	if (msg == "center") then
		if (not PP_IsPally and UnitClass("player") ~= "Paladin") then
			DEFAULT_CHAT_FRAME:AddMessage("You are not a paladin.", 1, 0, 0)
			return
		end
		PP_Options.ScaleMain = 1.0
		PallyPowerFrame:SetScale(PP_Options.ScaleMain)
		local px = GetScreenWidth() / 2 - 55 * PP_Options.ScaleMain
		local py = GetScreenHeight() / -2 + 20 * PP_Options.ScaleMain
		PallyPowerBuffBar:SetPoint("TOPLEFT", px, py)
		PallyPowerBuffBar:Show()
		return
	end
	if (msg == "ispally") then
		DEFAULT_CHAT_FRAME:AddMessage(tostring(PP_IsPally))
		return
	end
	if (msg == "forcepally") then
		PP_IsPally = true
		return
	end
	if (msg == "forcenopally") then
		PP_IsPally = false
		return
	end

	if (PallyPowerFrame:IsVisible()) then
		PallyPowerFrame:Hide()
	else
		PallyPowerFrame:Show()
	end
	PallyPower_UpdateUI()
end


function PallyPower_OnLoad()
	tinsert(UISpecialFrames, PallyPowerFrame:GetName())
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("SPELLS_CHANGED")
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	this:RegisterEvent("CHAT_MSG_ADDON")
	this:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH")
	this:RegisterEvent("PLAYER_LOGIN")
	this:RegisterEvent("PARTY_MEMBERS_CHANGED")
	this:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
	this:SetScale(1)
	SlashCmdList["PALLYPOWER"] = PallyPower_SlashCommandHandler
end