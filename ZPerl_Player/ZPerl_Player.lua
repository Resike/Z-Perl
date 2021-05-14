-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local XPerl_Player_Events = { }
local isOutOfControl
local playerClass, playerName
local conf, pconf
XPerl_RequestConfig(function(new)
	conf = new
	pconf = conf.player
	if (XPerl_Player) then
		XPerl_Player.conf = conf.player
	end
end, "$Revision: @file-revision@ $")

local perc1F = "%.1f"..PERCENT_SYMBOL
local percD = "%.0f"..PERCENT_SYMBOL

--[===[@debug@
local function d(...)
	ChatFrame1:AddMessage(format(...))
end
--@end-debug@]===]

local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

local format = format

local GetDifficultyColor = GetDifficultyColor or GetQuestDifficultyColor
local GetNumGroupMembers = GetNumGroupMembers
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitHealth = UnitHealth
local UnitIsAFK = UnitIsAFK
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGhost = UnitIsGhost
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local XPerl_Player_InitCP

local XPerl_Player_InitDK
local XPerl_Player_InitMage
local XPerl_Player_InitWarlock
local XPerl_Player_InitPaladin
local XPerl_Player_InitMonk
--local XPerl_Player_InitMoonkin

local XPerl_PlayerStatus_OnUpdate
local XPerl_Player_HighlightCallback


----------------------
-- Loading Function --
----------------------
function XPerl_Player_OnLoad(self)
	XPerl_SetChildMembers(self)
	self.partyid = "player"

	XPerl_BlizzFrameDisable(PlayerFrame)

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	self.portraitFrame:SetAttribute("*type1", "target")
	self.portraitFrame:SetAttribute("type2", "togglemenu")
	self.portraitFrame:SetAttribute("unit", self.partyid)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self.nameFrame:SetAttribute("unit", self.partyid)
	self.statsFrame:SetAttribute("*type1", "target")
	self.statsFrame:SetAttribute("type2", "togglemenu")
	self.statsFrame:SetAttribute("unit", self.partyid)
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
	self:SetAttribute("unit", self.partyid)

	self.state = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")

	--RegisterAttributeDriver(self.nameFrame, "unit", "[vehicleui] vehicle; player")
	RegisterAttributeDriver(self, "unit", "[vehicleui] vehicle; player")

	XPerl_RegisterClickCastFrame(self.portraitFrame)
	XPerl_RegisterClickCastFrame(self.nameFrame)
	XPerl_RegisterClickCastFrame(self.statsFrame)
	XPerl_RegisterClickCastFrame(self)

	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_ALIVE")

	if (HealBot_Options_EnablePlayerFrame) then
		HealBot_Options_EnablePlayerFrame = function() end
	end

	self:SetScript("OnUpdate", XPerl_Player_OnUpdate)
	self:SetScript("OnEvent", XPerl_Player_OnEvent)
	self:SetScript("OnShow", XPerl_Unit_UpdatePortrait)
	self.time = 0

	self.Power = 0
	self.nameFrame.pvp.time = 0

	--[[self.nameFrame.pvp:SetScript("OnUpdate", function(self, elapsed)
		self.time = self.time + elapsed
		if (self.time >= 0.2) then
			self.time = 0
			if (IsPVPTimerRunning()) then
				local timeLeft = GetPVPTimer()
				if (timeLeft > 0 and timeLeft < 300000) then -- 5 * 60 * 1000
					timeLeft = floor(timeLeft / 1000)
					self.timer:Show()
					self.timer:SetFormattedText("%d:%02d", timeLeft / 60, timeLeft % 60)
					return
				end
			end
			self.timer:Hide()
		end
	end)]]

	self.nameFrame.pvptimer:SetScript("OnUpdate", XPerl_Player_UpdatePVPTimerOnUpdate)

	XPerl_Player_InitCP(self)
	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		XPerl_Player_DruidBarUpdate(self)
	end

	XPerl_Player_InitDK(self)
	XPerl_Player_InitMage(self)
	XPerl_Player_InitPaladin(self)
	XPerl_Player_InitMonk(self)
	XPerl_Player_InitWarlock(self)

	XPerl_RegisterHighlight(self.highlight, 3)

	local perlframes = {self.nameFrame, self.statsFrame, self.levelFrame, self.portraitFrame, self.groupFrame}
	self.FlashFrames = {self.portraitFrame, self.nameFrame,self.levelFrame, self.statsFrame}
	-- Only Add deathknight to the flash frame list
	-- This resolves an issue with the backdrop being added constantly to the other special frames.
	--[[local _, class = UnitClass("player")
	if (class == "DEATHKNIGHT") then
		table.insert(self.FlashFrames, self.runes)
		table.insert(perlframes, self.runes)
	end]]

	XPerl_RegisterPerlFrames(self, perlframes)--, self.runes

	XPerl_RegisterOptionChanger(XPerl_Player_Set_Bits, self)
	XPerl_Highlight:Register(XPerl_Player_HighlightCallback, self)
	--self.IgnoreHighlightStates = {AGGRO = true}

	if (XPerlDB) then
		self.conf = XPerlDB.player
	end

	XPerl_Player_OnLoad = nil
end

-- XPerl_Player_HighlightCallback(updateName)
function XPerl_Player_HighlightCallback(self, updateGUID)
	if (updateGUID == UnitGUID("player")) then
		XPerl_Highlight:SetHighlight(self, updateGUID)
	end
end

-- UpdateAssignedRoles
local function UpdateAssignedRoles(self)
	local unit = self.partyid
	local icon = self.nameFrame.roleIcon
	local isTank, isHealer, isDamage
	if (not IsClassic and instanceType == "party") then
		-- No point getting it otherwise, as they can be wrong. Usually the values you had
		-- from previous instance if you're running more than one with the same people

		-- According to http://forums.worldofwarcraft.com/thread.html?topicId=26560499864
		-- this is the new way to check for roles
		local role = UnitGroupRolesAssigned(unit)
		isTank = false
		isHealer = false
		isDamage = false
		if role == "TANK" then
			isTank = true
		elseif role == "HEALER" then
			isHealer = true
		elseif role == "DAMAGER" then
			isDamage = true
		end
	end

	-- role icons option check by playerlin
	if (conf and conf.xperlOldroleicons) then
		if isTank then
			icon:SetTexture("Interface\\GroupFrame\\UI-Group-MainTankIcon")
			icon:Show()
		elseif isHealer then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleHealer_old")
			icon:Show()
		elseif isDamage then
			icon:SetTexture("Interface\\GroupFrame\\UI-Group-MainAssistIcon")
			icon:Show()
		else
			icon:Hide()
		end
	else
		if isTank then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleTank")
			icon:Show()
		elseif isHealer then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleHealer")
			icon:Show()
		elseif isDamage then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleDamage")
			icon:Show()
		else
			icon:Hide()
		end
	end
end

-------------------------
-- The Update Function --
-------------------------

local function XPerl_Player_CombatFlash(self, elapsed, argNew, argGreen)
	if (XPerl_CombatFlashSet(self, elapsed, argNew, argGreen)) then
		XPerl_CombatFlashSetFrames(self)
	end
end

-- XPerl_Player_UpdateManaType
local function XPerl_Player_UpdateManaType(self)
	XPerl_SetManaBarType(self)
end

-- XPerl_Player_UpdateLeader()
local function XPerl_Player_UpdateLeader(self)
	local nf = self.nameFrame

	-- Loot Master
	local method, pindex, rindex, ml
	if (UnitInParty("party1") or UnitInRaid("player")) then
		method, pindex, rindex = GetLootMethod()

		if (method == "master") then
			if (rindex ~= nil) then
				ml = UnitIsUnit("raid"..rindex, "player")
			elseif (pindex and (pindex == 0)) then
				ml = true
			end
		end
	end

	if (ml) then
		nf.masterIcon:Show()
	else
		nf.masterIcon:Hide()
	end

	-- Leader
	if (UnitIsGroupLeader("player")) then
		nf.leaderIcon:Show()
	else
		nf.leaderIcon:Hide()
	end

	if (UnitIsGroupAssistant("player")) then
		nf.assistIcon:Show()
	else
		nf.assistIcon:Hide()
	end

	--UpdateAssignedRoles(self)

	if (pconf and pconf.partyNumber and IsInRaid()) then
		for i = 1, GetNumGroupMembers() do
			local _, _, subgroup = GetRaidRosterInfo(i)
			if (UnitIsUnit("raid"..i, "player")) then
				if (pconf.withName) then
					nf.group:SetFormattedText(XPERL_RAID_GROUPSHORT, subgroup)
					nf.group:Show()
					self.groupFrame:Hide()
					return
				else
					self.groupFrame.text:SetFormattedText(XPERL_RAID_GROUP, subgroup)
					self.groupFrame:Show()
					nf.group:Hide()
					return
				end
			end
		end
	end

	nf.group:Hide()
	self.groupFrame:Hide()
end

local function XPerl_Player_UpdateRaidTarget(self)
	XPerl_Update_RaidIcon(self.nameFrame.raidIcon, self.partyid)
end

-- XPerl_Player_UpdateCombat
local function XPerl_Player_UpdateCombat(self)
	local nf = self.nameFrame
	if (UnitAffectingCombat("player")) then
		nf.text:SetTextColor(1, 0, 0)
		nf.combatIcon:SetTexCoord(0.49, 1, 0, 0.49)
		nf.combatIcon:Show()
	else
		if (self.partyid ~= "player") then
			local c = conf.colour.reaction.none
			nf.text:SetTextColor(c.r, c.g, c.b, conf.transparency.text)
		else
			XPerl_ColourFriendlyUnit(nf.text, self.partyid)
		end

		if (IsResting()) then
			nf.combatIcon:SetTexCoord(0, 0.49, 0, 0.49)
			nf.combatIcon:Show()
		else
			nf.combatIcon:Hide()
		end
	end
end

-- XPerl_Player_UpdateName()
local function XPerl_Player_UpdateName(self)
	playerName = UnitName(self.partyid)
	self.nameFrame.text:SetText(playerName)
	XPerl_Player_UpdateCombat(self)
end

-- XPerl_Player_UpdateClass
local function XPerl_Player_UpdateClass(self)
	local _, class = UnitClass(self.partyid)
	playerClass = class
	playerName = UnitName(self.partyid)
	local l, r, t, b = XPerl_ClassPos(playerClass)
	self.classFrame.tex:SetTexCoord(l, r, t, b)

	if (pconf.classIcon) then
		self.classFrame:Show()
	else
		self.classFrame:Hide()
	end
end

-- XPerl_Player_UpdateRep
local function XPerl_Player_UpdateRep(self)
	if (pconf and pconf.repBar) then
		local rb = self.statsFrame.repBar
		if (rb) then
			local name, reaction, min, max, value, factionID = GetWatchedFactionInfo()
			local color
			local perc

			--[[if not min or not max or not value then
				return
			end]]

			if max == 43000 then
				max = 42000
			end

			if (factionID == 1733 or factionID == 1736 or factionID == 1737 or factionID == 1738 or factionID == 1739 or factionID == 1740 or factionID == 1741) and min == 20000 and max == 21000 and value == 20000 then
				min = 21000
				value = 21000
			end

			if name then
				color = FACTION_BAR_COLORS[reaction]
				if min > 0 and max > 0 and value > 0 and min ~= max and min ~= value then
					value = value - min
					max = max - min
				end
				min = 0
				if value > 0 and max > 0 then
					perc = (value * 100) / max
				else
					perc = 100
				end
			else
				name = XPERL_LOC_NONEWATCHED
				value = 0
				max = 1
				min = 0
				color = FACTION_BAR_COLORS[4]
				perc = 0
			end

			rb:SetMinMaxValues(min, max)
			rb:SetValue(value)

			rb:SetStatusBarColor(color.r, color.g, color.b, 1)
			rb.bg:SetVertexColor(color.r, color.g, color.b, 0.25)

			if perc < 0 then
				perc = 0
			elseif perc > 100 then
				perc = 100
			end

			rb.tex:SetTexCoord(0, perc / 100, 0, 1)

			if max == 1 then
				rb.text:SetText(name)
			else
				rb.text:SetFormattedText("%d/%d", value, max)
			end

			if perc < 100 then
				rb.percent:SetFormattedText(perc1F, perc)
			else
				rb.percent:SetFormattedText(percD, perc)
			end
		end
	end
end

-- XPerl_Player_UpdateXP
local function XPerl_Player_UpdateXP(self)
	if (pconf.xpBar) then
		local xpBar = self.statsFrame.xpBar
		if (xpBar) then
			local restBar = self.statsFrame.xpRestBar
			local playerxp = UnitXP("player")
			local playerxpmax = UnitXPMax("player")
			local playerxprest = GetXPExhaustion() or 0
			xpBar:SetMinMaxValues(0, playerxpmax)
			restBar:SetMinMaxValues(0, playerxpmax)
			xpBar:SetValue(playerxp)

			local color
			local w = xpBar:GetRight() - xpBar:GetLeft()
			for mode = 1, 3 do
				local suffix
				if (playerxprest > 0) then
					if (mode == 1) then
						suffix = format(" +%d", playerxprest)
					elseif (mode == 2) then
						if (playerxprest >= 1000000) then
							suffix = format(" +%.1fM", playerxprest / 1000000)
						else
							suffix = format(" +%.1fK", playerxprest / 1000)
						end
					else
						if (playerxprest >= 1000000) then
							suffix = format(" +%dM", playerxprest / 1000000)
						else
							suffix = format(" +%dK", playerxprest / 1000)
						end
					end

					color = {r = 0.3, g = 0.3, b = 1}
				else
					color = {r = 0.6, g = 0, b = 0.6}
				end

				if (pconf.xpDeficit) then
					XPerl_SetValuedText(xpBar.text, playerxp - playerxpmax, playerxpmax, suffix)
				else
					XPerl_SetValuedText(xpBar.text, playerxp, playerxpmax, suffix)
				end
				if (xpBar.text:GetStringWidth() + 20 <= w) then
					break
				end
			end

			xpBar:SetStatusBarColor(color.r, color.g, color.b, 1)
			xpBar.bg:SetVertexColor(color.r, color.g, color.b, 0.25)
			local x = playerxp / playerxpmax
			if x > 1 then
				x = 1
			end
			xpBar.tex:SetTexCoord(0, x, 0, 1)

			restBar:SetValue(playerxp + playerxprest)
			restBar:SetStatusBarColor(color.r, color.g, color.b, 0.5)
			local y = (playerxp + playerxprest) / playerxpmax
			if y > 1 then
				y = 1
			end
			restBar.tex:SetTexCoord(0, y, 0, 1)
			restBar.bg:SetVertexColor(color.r, color.g, color.b, 0.25)
			xpBar.percent:SetFormattedText(percD, (playerxp * 100) / playerxpmax)
		end
	end
end

-- XPerl_Player_UpdatePVPTimer
function XPerl_Player_UpdatePVPTimerOnUpdate(self, elapsed)
	self.time = (self.time or 0) + elapsed
	if self.time >= 0.5 then
		local timeLeft = GetPVPTimer()

		if timeLeft > 0 then
			timeLeft = floor(timeLeft / 1000)
			self.text:SetFormattedText("%d:%02d", timeLeft / 60, timeLeft % 60)
		end

		self.time = 0
	end
end

-- XPerl_Player_UpdatePVPTimer
local function XPerl_Player_UpdatePVPTimer(self)
	if pconf.pvpIcon and IsPVPTimerRunning() then
		self.nameFrame.pvptimer:Show()
	else
		self.nameFrame.pvptimer:Hide()
		self.nameFrame.pvptimer.text:SetText("")
	end
end

-- XPerl_Player_UpdatePVP
local function XPerl_Player_UpdatePVP(self)
	-- PVP Status settings
	--local nf = self.nameFrame
	if (UnitAffectingCombat(self.partyid)) then
		self.nameFrame.text:SetTextColor(1, 0, 0)
	else
		XPerl_ColourFriendlyUnit(self.nameFrame.text, "player")
	end

	local pvpIcon = self.nameFrame.pvp

	local factionGroup, factionName = UnitFactionGroup("player")

	if pconf.pvpIcon and UnitIsPVPFreeForAll("player") then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		pvpIcon:Show()
	elseif pconf.pvpIcon and factionGroup and factionGroup ~= "Neutral" and UnitIsPVP("player") then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)

		if not IsClassic and UnitIsMercenary("player") then
			if factionGroup == "Horde" then
				pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
			elseif factionGroup == "Alliance" then
				pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
			end
		end

		pvpIcon:Show()
	else
		pvpIcon:Hide()
	end

	XPerl_Player_UpdatePVPTimer(self)

	--[[local pvp = pconf.pvpIcon and ((UnitIsPVPFreeForAll("player") and "FFA") or (UnitIsPVP("player") and (UnitFactionGroup("player") ~= "Neutral") and UnitFactionGroup("player")))
	if (pvp) then
		nf.pvp.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		nf.pvp:Show()
	else
		nf.pvp:Hide()
	end]]
end

-- CreateBar(self, name)
local function CreateBar(self, name)
	local f = CreateFrame("StatusBar", self.statsFrame:GetName()..name, self.statsFrame, "XPerlStatusBar")
	f:SetPoint("TOPLEFT", self.statsFrame.manaBar, "BOTTOMLEFT", 0, 0)
	f:SetHeight(10)
	self.statsFrame[name] = f
	f:SetWidth(112)
	return f
end

-- MakeDruidBar()
local function MakeDruidBar(self)
	local f = CreateBar(self, "druidBar")
	local c = conf.colour.bar.mana
	f:SetStatusBarColor(c.r, c.g, c.b)
	f.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
	MakeDruidBar = nil
end

-- XPerl_Player_DruidBarUpdate
local function XPerl_Player_DruidBarUpdate(self)
	local druidBar = self.statsFrame.druidBar
	if (pconf.noDruidBar) then
		if (druidBar) then
			druidBar:Hide()
			XPerl_StatsFrameSetup(self, {self.statsFrame.xpBar, self.statsFrame.repBar})
			--[[if (XPerl_Player_Buffs_Position) then
				XPerl_Player_Buffs_Position(self)
			end]]
		end
		return
	elseif (not druidBar) then
		if (MakeDruidBar) then
			MakeDruidBar(self)
			druidBar = self.statsFrame.druidBar
		end
	end

	local maxMana = UnitPowerMax("player", 0)
	if maxMana == 0 then
		maxMana = nil
	end
	local currMana = UnitPower("player", 0)

	druidBar:SetMinMaxValues(0, maxMana or 1)
	druidBar:SetValue(currMana or 0)
	druidBar.text:SetFormattedText("%d/%d", ceil(currMana or 0), maxMana or 1)
	druidBar.percent:SetFormattedText(percD, (currMana or 0) * 100 / (maxMana or 1))

	--local druidBarExtra
	if ((playerClass == "DRUID" or playerClass == "PRIEST") and UnitPowerType(self.partyid) > 0) or (playerClass == "SHAMAN" and not IsClassic and GetSpecialization() == 1 and GetShapeshiftForm() == 0) then -- Shaman's UnitPowerType is buggy
		if (pconf.values) then
			druidBar.text:Show()
		else
			druidBar.text:Hide()
		end
		if (pconf.percent) then
			druidBar.percent:Show()
		else
			druidBar.percent:Hide()
		end
		druidBar:Show()
		--druidBar:SetHeight(10)
		--druidBarExtra = 1
	else
		--druidBar.percent:Hide()
		--druidBar.text:Hide()
		druidBar:Hide()
		--druidBar:SetHeight(1)
		--druidBarExtra = 0
	end

	--[[if druidBarExtra == 1 then
		ComboPointPlayerFrame:SetPoint("TOPLEFT", self.runes, "CENTER", -35, 18 - 5)
	else
		ComboPointPlayerFrame:SetPoint("TOPLEFT", self.runes, "CENTER", -35, 18)
	end]]

	-- Highlight update
	--[[if (druidBarExtra) then
		self.highlight:SetPoint("TOPLEFT", self.levelFrame, "TOPLEFT", 0, 0)
		self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
	else
		self.highlight:SetPoint("BOTTOMLEFT", self.classFrame, "BOTTOMLEFT", -2, -2)
		self.highlight:SetPoint("TOPRIGHT", self.nameFrame, "TOPRIGHT", 0, 0)
	end]]

	--[[local h = 40 + ((druidBarExtra + (pconf.repBar and 1 or 0) + (pconf.xpBar and 1 or 0)) * 10)
	if InCombatLockdown() then
		XPerl_ProtectedCall(XPerl_Player_DruidBarUpdate, self)
	else
		if (pconf.extendPortrait) then
			self.portraitFrame:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
		else
			self.portraitFrame:SetHeight(62)
		end
	end
	if (InCombatLockdown() and pconf.showRunes) then
		XPerl_ProtectedCall(XPerl_Player_DruidBarUpdate, self)
	else
		self.statsFrame:SetHeight(h)
	end]]

	XPerl_StatsFrameSetup(self, {druidBar, self.statsFrame.xpBar, self.statsFrame.repBar})
	--[[if (XPerl_Player_Buffs_Position) then
		XPerl_Player_Buffs_Position(self)
	end]]
end

-- XPerl_Player_UpdateMana
local function XPerl_Player_UpdateMana(self)
	local mb = self.statsFrame.manaBar
	local pType = XPerl_GetDisplayedPowerType(self.partyid)
	local playermana = UnitPower(self.partyid, pType)
	local playermanamax = UnitPowerMax(self.partyid, pType)

	mb:SetMinMaxValues(0, playermanamax)
	mb:SetValue(playermana)

	-- Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
	local percent
	if playermana > 0 and playermanamax == 0 then -- We have current mana but max mana failed.
		playermanamax = playermana -- Make max mana at least equal to current health
		percent = 100 -- And percent 100% cause a number divided by itself is 1, duh.
	elseif playermana == 0 and playermanamax == 0 then -- Probably doesn't use mana or is oom?
		percent = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
	else
		percent = playermana / playermanamax -- Everything is dandy, so just do it right way.
	end
	-- end division by 0 check

	--mb.text:SetFormattedText("%d/%d", playermana, playermanamax)
	XPerl_SetValuedText(mb.text, playermana, playermanamax)

	if (pType >= 1 or UnitPowerMax(self.partyid, pType) < 1) then
		mb.percent:SetText(playermana)
	else
		mb.percent:SetFormattedText(percD, percent * 100)
	end

	mb.tex:SetTexCoord(0, max(0, (percent)), 0, 1)

	if (not self.statsFrame.greyMana) then
		if (pconf.values) then
			mb.text:Show()
		end
		if (pconf.percent) then
			mb.percent:Show()
		end
	end

	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		XPerl_Player_DruidBarUpdate(self)
	end
end

-- XPerl_Player_UpdateHealPrediction
local function XPerl_Player_UpdateHealPrediction(self)
	if pconf.healprediction then
		XPerl_SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

-- XPerl_Player_UpdateAbsorbPrediction
local function XPerl_Player_UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

local function XPerl_Player_UpdateResurrectionStatus(self)
	if (UnitHasIncomingResurrection(self.partyid)) then
		if pconf.portrait then
			self.portraitFrame.resurrect:Show()
		else
			self.statsFrame.resurrect:Show()
		end
	else
		if pconf.portrait then
			self.portraitFrame.resurrect:Hide()
		else
			self.statsFrame.resurrect:Hide()
		end
	end
end

local feignDeath = GetSpellInfo(5384)
local spiritOfRedemption = GetSpellInfo(27827)

-- XPerl_Player_UpdateHealth
local function XPerl_Player_UpdateHealth(self)
	local partyid = self.partyid
	local sf = self.statsFrame
	local hb = sf.healthBar
	local playerhealth, playerhealthmax = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid)), UnitHealthMax(partyid)

	self.afk = UnitIsAFK(partyid) and conf.showAFK == 1

	XPerl_SetHealthBar(self, playerhealth, playerhealthmax)
	XPerl_Player_UpdateAbsorbPrediction(self)
	XPerl_Player_UpdateHealPrediction(self)
	XPerl_Player_UpdateResurrectionStatus(self)

	local greyMsg
	if (UnitIsDead(partyid)) then
		greyMsg = XPERL_LOC_DEAD
	elseif (UnitIsGhost(partyid)) then
		greyMsg = XPERL_LOC_GHOST
	elseif (UnitIsAFK("player") and conf.showAFK) then
		greyMsg = CHAT_MSG_AFK
	--[[elseif (conf.showFD and UnitBuff(partyid, feignDeath)) then
		greyMsg = XPERL_LOC_FEIGNDEATHSHORT
	elseif (UnitBuff(partyid, spiritOfRedemption)) then
		greyMsg = XPERL_LOC_DEAD--]]
	end

	if (greyMsg) then
		if (pconf.percent) then
			hb.percent:SetText(greyMsg)
			hb.percent:Show()
		else
			hb.text:SetText(greyMsg)
			hb.text:Show()
		end

		sf:SetGrey()
	else
		if (sf.greyMana) then
			if (not pconf.values) then
				hb.text:Hide()
			end

			sf.greyMana = nil
			XPerl_Player_UpdateManaType(self)
		end
	end

	XPerl_PlayerStatus_OnUpdate(self, playerhealth, playerhealthmax)
end

-- XPerl_Player_UpdateLevel
local function XPerl_Player_UpdateLevel(self)
	local color = GetDifficultyColor(UnitLevel(self.partyid))
	self.levelFrame.text:SetTextColor(color.r, color.g, color.b, conf.transparency.text)

	self.levelFrame.text:SetText(UnitLevel(self.partyid))
end


-- XPerl_PlayerStatus_OnUpdate
function XPerl_PlayerStatus_OnUpdate(self, val, max)
	if (pconf.fullScreen.enable) then
		local testLow = pconf.fullScreen.lowHP / 100
		local testHigh = pconf.fullScreen.highHP / 100

		if (val and max and val > 0 and max > 0) then
			local test = val / max

			if ( test <= testLow and not XPerl_LowHealthFrame.frameFlash and not UnitIsDeadOrGhost("player")) then
				XPerl_FrameFlash(XPerl_LowHealthFrame)
			elseif ( (test >= testHigh and XPerl_LowHealthFrame.frameFlash) or UnitIsDeadOrGhost("player") ) then
				XPerl_FrameFlashStop(XPerl_LowHealthFrame, "out")
			end
			return
		else
			if (not UnitOnTaxi("player")) then
				if (isOutOfControl and not XPerl_OutOfControlFrame.frameFlash and not UnitOnTaxi("player")) then
					XPerl_FrameFlash(XPerl_OutOfControlFrame)
				elseif (not isOutOfControl and XPerl_OutOfControlFrame.frameFlash) then
					XPerl_FrameFlashStop(XPerl_OutOfControlFrame, "out")
				end
				return
			end
		end
	end

	if (XPerl_LowHealthFrame.frameFlash) then
		XPerl_FrameFlashStop(XPerl_LowHealthFrame)
	end
	if (XPerl_OutOfControlFrame.frameFlash) then
		XPerl_FrameFlashStop(XPerl_OutOfControlFrame)
	end
end

-- XPerl_Player_OnUpdate
function XPerl_Player_OnUpdate(self, elapsed)
	if pconf.hitIndicator and pconf.portrait then
		CombatFeedback_OnUpdate(self, elapsed)
	end

	local partyid = self.partyid
	local newAFK = UnitIsAFK(partyid)

	if (conf.showAFK and newAFK ~= self.afk) then
		XPerl_Player_UpdateHealth(self)
	end

	if (self.PlayerFlash) then
		XPerl_Player_CombatFlash(self, elapsed, false)
	end

	--XPerl_Player_UpdateMana(self)

	--[[if (IsResting() and UnitLevel("player") < 85) then
		self.restingDelay = (self.restingDelay or 2) - elapsed
		if (self.restingDelay <= 0) then
			self.restingDelay = 2
			XPerl_Player_UpdateXP(self)
		end
	end]]--

	-- Attempt to fix "not-updating bug", suggested by Taylla @ Curse (why was this code in onupdate function twice? identicle code, twice)
	--[[if (self.updateAFK) then
		self.updateAFK = nil
		XPerl_Player_UpdateHealth(self)
	end]]--
end

-- XPerl_Player_UpdateBuffs
local function XPerl_Player_UpdateBuffs(self)
	-- TODO: create a highlight handler for the player too
	if (conf.highlightDebuffs.enable) then
		XPerl_CheckDebuffs(self, self.partyid)
	end

	if (playerClass == "DRUID") then
		XPerl_Player_UpdateMana(self)
	end

	if (pconf.fullScreen.enable) then
		if (isOutOfControl and not UnitOnTaxi("player")) then
			XPerl_PlayerStatus_OnUpdate(self)
		end
	end
end

-- XPerl_Player_UpdateDisplay
function XPerl_Player_UpdateDisplay(self)
	XPerl_Player_UpdateXP(self)
	XPerl_Player_UpdateRep(self)
	XPerl_Player_UpdateManaType(self)
	XPerl_Player_UpdateLevel(self)
	XPerl_Player_UpdateName(self)
	XPerl_Player_UpdateClass(self)
	XPerl_Player_UpdatePVP(self)
	XPerl_Player_UpdateCombat(self)
	XPerl_Player_UpdateLeader(self)
	XPerl_Player_UpdateRaidTarget(self)
	XPerl_Player_UpdateMana(self)
	XPerl_Player_UpdateHealth(self)
	XPerl_Player_UpdateBuffs(self)
	XPerl_Unit_UpdatePortrait(self)
end

-- EVENTS AND STUFF

-------------------
-- Event Handler --
-------------------
function XPerl_Player_OnEvent(self, event, unitID, ...)
	if string.find(event, "^UNIT_") then
		if (unitID == "player" or unitID == "vehicle") then
			if event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
				XPerl_Player_Events[event](self, unitID, ...)
			else
				XPerl_Player_Events[event](self, ...)
			end
		end
	else
		XPerl_Player_Events[event](self, event, unitID, ...)
	end
end

function XPerl_Player_Events:PLAYER_ALIVE()
	XPerl_Player_UpdateDisplay(self)
end


-- PLAYER_ENTERING_WORLD
function XPerl_Player_Events:PLAYER_ENTERING_WORLD(event, initialLogin, reloadingUI)
	self.updateAFK = true

	if (not IsClassic and UnitHasVehicleUI("player")) then
		self.partyid = "vehicle"
		self:SetAttribute("unit", "vehicle")
		if (XPerl_ArcaneBar_SetUnit) then
			XPerl_ArcaneBar_SetUnit(self.nameFrame, "vehicle")
		end
	else
		self.partyid = "player"
		self:SetAttribute("unit", "player")
		if (XPerl_ArcaneBar_SetUnit) then
			XPerl_ArcaneBar_SetUnit(self.nameFrame, "player")
		end
	end

	if (initialLogin or reloadingUI) and not InCombatLockdown() then
		self.state:SetFrameRef("ZPerlPlayer", self)
		self.state:SetFrameRef("ZPerlPlayerPortrait", self.portraitFrame)
		self.state:SetFrameRef("ZPerlPlayerStats", self.statsFrame)

		local class, classFileName, classID = UnitClass("player")

		self.state:SetAttribute("playerClass", classFileName)
		if not IsClassic then
			self.state:SetAttribute("playerSpec", GetSpecialization())
		end
		self.state:SetAttribute("extendedPortrait", pconf.extendPortrait)
		self.state:SetAttribute("druidBarOff", pconf.noDruidBar)
		self.state:SetAttribute("xpBar", pconf.xpBar)
		self.state:SetAttribute("repBar", pconf.repBar)
		self.state:SetAttribute("special", pconf.showRunes)
		self.state:SetAttribute("docked", pconf.dockRunes)

		self.state:Execute([[
			frame = self:GetFrameRef("ZPerlPlayer")
			portrait = self:GetFrameRef("ZPerlPlayerPortrait")
			stats = self:GetFrameRef("ZPerlPlayerStats")
		]])

		self.state:SetAttribute("_onstate-petbattleupdate", [[
			if newstate == "inpetbattle" then
				frame:Hide()
			else
				local buffs = self:GetFrameRef("ZPerlPlayerBuffs")

				local class = self:GetAttribute("playerClass")
				local spec = self:GetAttribute("playerSpec")
				local extend = self:GetAttribute("extendedPortrait")
				local bar = self:GetAttribute("druidBarOff")
				local xp = self:GetAttribute("xpBar")
				local rep = self:GetAttribute("repBar")
				local special = self:GetAttribute("spec")
				local docked = self:GetAttribute("docked")
				local above = self:GetAttribute("buffsAbove")

				local offset = 10 * ((bar and 0 or 1) + (xp and 1 or 0) + (rep and 1 or 0))
				local buffoffset = 13.5 * ((bar and 0 or 1) + (xp and 1 or 0) + (rep and 1 or 0))

				if class == "DRUID" then
					if spec == 1 then
						if newstate == 1 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						elseif newstate == 2 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0 - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
									end
								else
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									end
								end
							end
						elseif newstate == 3 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						elseif newstate == 4 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						else
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						end
					elseif spec == 2 or spec == 3 or spec == 4 then
						if newstate == 1 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						elseif newstate == 2 then
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0 - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
									end
								else
									if special and docked then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset - 28)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									end
								end
							end
						elseif newstate == 3 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						else
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						end
					end
				elseif class == "PRIEST" then
					if spec == 1 or spec == 2 then
						if extend then
							frame:SetHeight(62 + offset)
							portrait:SetHeight(62 + offset)
						else
							frame:SetHeight(62)
							portrait:SetHeight(62)
						end
						if bar then
							stats:SetHeight(40 + offset)
						else
							stats:SetHeight(40 + offset - 10)
						end
						if not above and buffs then
							if extend then
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
							else
								if bar then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
								end
							end
						end
					elseif spec == 3 then
						if extend then
							frame:SetHeight(62 + offset)
							portrait:SetHeight(62 + offset)
						else
							frame:SetHeight(62)
							portrait:SetHeight(62)
						end
						stats:SetHeight(40 + offset)
						if not above and buffs then
							if extend then
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
							else
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
							end
						end
					end
				elseif class == "SHAMAN" then
					if spec == 1 then
						if newstate == 1 then
							if extend then
								if bar then
									frame:SetHeight(62 + offset)
									portrait:SetHeight(62 + offset)
								else
									frame:SetHeight(62 + offset - 10)
									portrait:SetHeight(62 + offset - 10)
								end
							else
								if bar then
									frame:SetHeight(62)
									portrait:SetHeight(62)
								else
									frame:SetHeight(62)
									portrait:SetHeight(62)
								end
							end
							if bar then
								stats:SetHeight(40 + offset)
							else
								stats:SetHeight(40 + offset - 10)
							end
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									if bar then
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
									else
										buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
									end
								end
							end
						else
							if extend then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62)
								portrait:SetHeight(62)
							end
							stats:SetHeight(40 + offset)
							if not above and buffs then
								if extend then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								end
							end
						end
					elseif spec == 2 or spec == 3 then
						if extend then
							if bar then
								frame:SetHeight(62 + offset)
								portrait:SetHeight(62 + offset)
							else
								frame:SetHeight(62 + offset - 10)
								portrait:SetHeight(62 + offset - 10)
							end
						else
							frame:SetHeight(62)
							portrait:SetHeight(62)
						end
						if bar then
							stats:SetHeight(40 + offset)
						else
							stats:SetHeight(40 + offset - 10)
						end
						if not above and buffs then
							if extend then
								buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 0)
							else
								if bar then
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset)
								else
									buffs:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, -buffoffset + 13.5)
								end
							end
						end
					end
				end

				frame:Show()
			end
		]])

		RegisterStateDriver(self.state, "petbattleupdate", "[petbattle] inpetbattle; [stance:0] 0; [stance:1] 1; [stance:2] 2; [stance:3] 3; [stance:4] 4; none")
	end

	XPerl_Player_UpdateDisplay(self)

	--C_Timer.After(0.1, function() XPerl_Player_Set_Bits(self) end)
end

-- UNIT_COMBAT
function XPerl_Player_Events:UNIT_COMBAT(action, descriptor, damage, damageType)
	if (pconf.hitIndicator and pconf.portrait) then
		CombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
	end

	if (action == "HEAL") then
		XPerl_Player_CombatFlash(self, 0, true, true)
	elseif (damage and damage > 0) then
		XPerl_Player_CombatFlash(self, 0, true)
	end
end

-- UNIT_PORTRAIT_UPDATE
function XPerl_Player_Events:UNIT_PORTRAIT_UPDATE()
	XPerl_Unit_UpdatePortrait(self, true)
end

-- VARIABLES_LOADED
function XPerl_Player_Events:VARIABLES_LOADED()

	self.doubleCheckAFK = 2 -- Check during 2nd UPDATE_FACTION, which are the last guarenteed events to come after logging in
	self:UnregisterEvent("VARIABLES_LOADED")

	local events = {
		"PLAYER_ENTERING_WORLD",
		"PARTY_LEADER_CHANGED",
		"PARTY_LOOT_METHOD_CHANGED",
		"GROUP_ROSTER_UPDATE",
		"PLAYER_UPDATE_RESTING",
		"PLAYER_REGEN_ENABLED",
		"PLAYER_REGEN_DISABLED",
		"PLAYER_ENTER_COMBAT",
		"PLAYER_LEAVE_COMBAT",
		"PLAYER_DEAD",
		"PLAYER_SPECIALIZATION_CHANGED",
		"UPDATE_FACTION",
		"UNIT_AURA",
		"PLAYER_CONTROL_LOST",
		"PLAYER_CONTROL_GAINED",
		"UNIT_COMBAT",
		"UNIT_POWER_FREQUENT",
		"UNIT_MAXPOWER",
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		"UNIT_LEVEL",
		"UNIT_DISPLAYPOWER",
		"UNIT_NAME_UPDATE",
		"UNIT_FACTION",
		"UNIT_PORTRAIT_UPDATE",
		"UNIT_FLAGS",
		"PLAYER_FLAGS_CHANGED",
		"UNIT_ENTERED_VEHICLE",
		"UNIT_EXITING_VEHICLE",
		--[["UNIT_PET",]]
		"PLAYER_TALENT_UPDATE",
		"RAID_TARGET_UPDATE",
		"UPDATE_SHAPESHIFT_FORM",
		"UPDATE_EXHAUSTION",
		--"PET_BATTLE_OPENING_START",
		--"PET_BATTLE_CLOSE",
		"INCOMING_RESURRECT_CHANGED",
	}

	for i, event in pairs(events) do
		if string.find(event, "^UNIT_") or string.find(event, "^INCOMING") then
			if pcall(self.RegisterUnitEvent, self, event, "player", "vehicle") then
				self:RegisterUnitEvent(event, "player", "vehicle")
			end
		else
			if pcall(self.RegisterEvent, self, event) then
				self:RegisterEvent(event)
			end
		end
	end

	--XPerl_Player_UpdateDisplay(self)

	XPerl_Player_Events.VARIABLES_LOADED = nil
end

--[[function XPerl_Player_Events:PET_BATTLE_OPENING_START()
	if (self) then
		self:Hide()
	end
end

function XPerl_Player_Events:PET_BATTLE_CLOSE()
	if (self) then
		self:Show()
	end
end]]

function XPerl_Player_Events:UPDATE_EXHAUSTION()
	XPerl_Player_UpdateXP(self)
end

-- PARTY_LOOT_METHOD_CHANGED
function XPerl_Player_Events:PARTY_LOOT_METHOD_CHANGED()
	XPerl_Player_UpdateLeader(self)
end

-- PARTY_LEADER_CHANGED
function XPerl_Player_Events:PARTY_LEADER_CHANGED()
	XPerl_Player_UpdateLeader(self)
end

-- GROUP_ROSTER_UPDATE
function XPerl_Player_Events:GROUP_ROSTER_UPDATE()
	XPerl_Player_UpdateLeader(self)
end

-- UNIT_HEALTH_FREQUENT
function XPerl_Player_Events:UNIT_HEALTH_FREQUENT()
	XPerl_Player_UpdateHealth(self)
end

-- UNIT_HEALTH
function XPerl_Player_Events:UNIT_HEALTH()
	XPerl_Player_UpdateHealth(self)
end

-- UNIT_MAXHEALTH
function XPerl_Player_Events:UNIT_MAXHEALTH()
	XPerl_Player_UpdateHealth(self)
end

-- PLAYER_DEAD
function XPerl_Player_Events:PLAYER_DEAD()
	XPerl_Player_UpdateHealth(self)
end

-- UNIT_POWER_FREQUENT
function XPerl_Player_Events:UNIT_POWER_FREQUENT(powerType)
	XPerl_Player_UpdateMana(self)

	if powerType == "COMBO_POINTS" then
		if XPerl_Target_UpdateCombo then
			XPerl_Target_UpdateCombo(XPerl_Target)
		end

		if conf.target.combo.blizzard then
			if XPerl_Target_ComboFrame_Update then
				XPerl_Target_ComboFrame_Update()
			end
		end
	end
end

-- UNIT_MAXPOWER
function XPerl_Player_Events:UNIT_MAXPOWER()
	XPerl_Player_UpdateMana(self)
end

-- UNIT_DISPLAYPOWER
function XPerl_Player_Events:UNIT_DISPLAYPOWER()
	XPerl_Player_UpdateManaType(self)
	XPerl_Player_UpdateMana(self)
end

-- UNIT_NAME_UPDATE
function XPerl_Player_Events:UNIT_NAME_UPDATE()
	XPerl_Player_UpdateName(self)
end

-- UNIT_LEVEL
function XPerl_Player_Events:UNIT_LEVEL()
	XPerl_Player_UpdateLevel(self)
	XPerl_Player_UpdateXP(self)
end

-- PLAYER_XP_UPDATE
function XPerl_Player_Events:PLAYER_XP_UPDATE()
	XPerl_Player_UpdateXP(self)
end

-- UPDATE_FACTION
function XPerl_Player_Events:UPDATE_FACTION()
	XPerl_Player_UpdateRep(self)

	if (self.doubleCheckAFK) then
		if (conf and pconf) then
			self.doubleCheckAFK = self.doubleCheckAFK - 1
			if (self.doubleCheckAFK <= 0) then
				XPerl_Player_UpdateHealth(self)
				self.doubleCheckAFK = nil
			end
		end
	end
end

-- UNIT_FACTION
function XPerl_Player_Events:UNIT_FACTION()
	XPerl_Player_UpdateHealth(self)
	XPerl_Player_UpdatePVP(self)
	XPerl_Player_UpdateCombat(self)
end
XPerl_Player_Events.UNIT_FLAGS = XPerl_Player_Events.UNIT_FACTION

function XPerl_Player_Events:PLAYER_FLAGS_CHANGED()
	XPerl_Player_UpdateHealth(self)
	XPerl_Player_UpdatePVPTimer(self)
end

-- RAID_TARGET_UPDATE
function XPerl_Player_Events:RAID_TARGET_UPDATE()
	XPerl_Player_UpdateRaidTarget(XPerl_Player)
end

-- PLAYER_TALENT_UPDATE
function XPerl_Player_Events:PLAYER_TALENT_UPDATE()
	XPerl_Player_UpdateMana(self)

	if (playerClass == "MONK") then
		if (XPerl_Player_Buffs_Position) then
			XPerl_Player_Buffs_Position(self)
		end
	end
end

-- UPDATE_SHAPESHIFT_FORM
function XPerl_Player_Events:UPDATE_SHAPESHIFT_FORM()
	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		XPerl_Player_DruidBarUpdate(self)
	end

	--[[if playerClass ~= "DRUID" then
		return
	end

	XPerl_Unit_UpdatePortrait(self, true)]]
end

-- PLAYER_ENTER_COMBAT, PLAYER_LEAVE_COMBAT
function XPerl_Player_Events:PLAYER_ENTER_COMBAT()
	XPerl_Player_UpdateCombat(self)
end
XPerl_Player_Events.PLAYER_LEAVE_COMBAT = XPerl_Player_Events.PLAYER_ENTER_COMBAT

-- PLAYER_REGEN_ENABLED
function XPerl_Player_Events:PLAYER_REGEN_ENABLED()
	XPerl_Player_UpdateCombat(self)

	if (self:GetAttribute("unit") ~= self.partyid) then
		self:SetAttribute("unit", self.partyid)
		XPerl_Player_UpdateDisplay(self)
	end
end

-- PLAYER_REGEN_DISABLED
function XPerl_Player_Events:PLAYER_REGEN_DISABLED()
	XPerl_Player_UpdateCombat(self)
end

function XPerl_Player_Events:PLAYER_UPDATE_RESTING()
	XPerl_Player_UpdateCombat(self)
	XPerl_Player_UpdateXP(self)
end

function XPerl_Player_Events:PLAYER_SPECIALIZATION_CHANGED()
	if not InCombatLockdown() then
		if not IsClassic then
			self.state:SetAttribute("playerSpec", GetSpecialization())
		end
		XPerl_Player_Set_Bits(self)

		--[[if ((playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST")) then
			C_Timer.After(0.1, function() XPerl_Player_Set_Bits(self) end)
		end--]]
	end

	if XPerl_Player_Buffs_Position then
		XPerl_Player_Buffs_Position(XPerl_Player)
	end
end

function XPerl_Player_Events:UNIT_AURA()
	XPerl_Player_UpdateBuffs(self)

	--[[if conf.showFD then
		local _, class = UnitClass(self.partyid)
		if (class == "HUNTER") then
			local feigning = UnitBuff(self.partyid, feignDeath)
			if (feigning ~= self.feigning) then
				self.feigning = feigning
				XPerl_Player_UpdateHealth(self)
			end
		end
	end--]]
end

-- PLAYER_CONTROL_LOST
function XPerl_Player_Events:PLAYER_CONTROL_LOST()
	if (pconf.fullScreen.enable and not UnitOnTaxi("player")) then
		isOutOfControl = true
	end
end

-- PLAYER_CONTROL_GAINED
function XPerl_Player_Events:PLAYER_CONTROL_GAINED()
	isOutOfControl = nil
	if (pconf.fullScreen.enable) then
		XPerl_PlayerStatus_OnUpdate(self)
	end
end

-- UNIT_ENTERED_VEHICLE
function XPerl_Player_Events:UNIT_ENTERED_VEHICLE(showVehicle)
	if (showVehicle) then
		self.partyid = "vehicle"
		if (XPerl_ArcaneBar_SetUnit) then
			XPerl_ArcaneBar_SetUnit(self.nameFrame, "vehicle")
		end
		--[[if (not InCombatLockdown()) then
			self:SetAttribute("unit", "vehicle")
		end]]
		XPerl_Player_UpdateDisplay(self)
		--XPerl_SetUnitNameColor(self.nameFrame.text, self.partyid)
	end
end

-- UNIT_EXITING_VEHICLE
function XPerl_Player_Events:UNIT_EXITING_VEHICLE()
	if (self.partyid ~= "player") then
		self.partyid = "player"
		if (XPerl_ArcaneBar_SetUnit) then
			XPerl_ArcaneBar_SetUnit(self.nameFrame, "player")
		end
		--[[if (not InCombatLockdown()) then
			self:SetAttribute("unit", "player")
		end]]
		XPerl_Player_UpdateDisplay(self)
	end
end

-- UNIT_PET
function XPerl_Player_Events:UNIT_PET()
	self.partyid = (not IsClassic and UnitHasVehicleUI("player")) and "pet" or "player"
	XPerl_Player_UpdateDisplay(self)
end

function XPerl_Player_Events:UNIT_HEAL_PREDICTION(unit)
	if (pconf.healprediction and unit == self.partyid) then
		XPerl_SetExpectedHealth(self)
	end
end

function XPerl_Player_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if (pconf.absorbs and unit == self.partyid) then
		XPerl_SetExpectedAbsorbs(self)
	end
end

function XPerl_Player_Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		XPerl_Player_UpdateResurrectionStatus(self)
	end
end

-- XPerl_Player_SetWidth
function XPerl_Player_SetWidth(self)
	pconf.size.width = max(0, pconf.size.width or 0)
	if (pconf.percent) then
		self.nameFrame:SetWidth(160 + pconf.size.width)
		self.statsFrame:SetWidth(160 + pconf.size.width)
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()

		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.percent:Show()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.percent:Show()
		end
	else
		self.nameFrame:SetWidth(128 + pconf.size.width)
		self.statsFrame:SetWidth(128 + pconf.size.width)
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.percent:Hide()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.percent:Hide()
		end
	end

	local h = 40 + ((((self.statsFrame.druidBar and self.statsFrame.druidBar:IsShown()) and 1 or 0) + (pconf.repBar and 1 or 0) + (pconf.xpBar and 1 or 0)) * 10)
	self.statsFrame:SetHeight(h)

	self:SetWidth(128 + (pconf.portrait and 1 or 0) * 62 + (pconf.percent and 1 or 0) * 32 + pconf.size.width)
	self:SetScale(pconf.scale)

	XPerl_StatsFrameSetup(self, {self.statsFrame.druidBar, self.statsFrame.xpBar, self.statsFrame.repBar})
	if (XPerl_Player_Buffs_Position) then
		XPerl_Player_Buffs_Position(self)
	end

	XPerl_Player_UpdateHealth(self)
	XPerl_Player_UpdateMana(self)
	XPerl_Player_UpdateXP(self)

	XPerl_SavePosition(self, true)
	XPerl_RestorePosition(self)
end

-- MakeXPBar
local function MakeXPBar(self)
	local f = CreateBar(self, "xpBar")
	local f2 = CreateBar(self, "xpRestBar")

	f2:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	f2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

	MakeXPBar = nil
end

-- XPerl_Player_SetTotems
function XPerl_Player_SetTotems(self, ...)
	if (pconf.totems and pconf.totems.enable) then
		TotemFrame:SetParent(XPerl_Player)
		TotemFrame:ClearAllPoints()
		TotemFrame:SetPoint("TOP", XPerl_Player, "BOTTOM", pconf.totems.offsetX, pconf.totems.offsetY)
	else
		TotemFrame:SetParent(PlayerFrame)
		TotemFrame:ClearAllPoints()
		TotemFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 99, 38)
	end
end

-- XPerl_Player_Set_Bits()
function XPerl_Player_Set_Bits(self)
	if (XPerl_ArcaneBar_RegisterFrame and not self.nameFrame.castBar) then
		XPerl_ArcaneBar_RegisterFrame(self.nameFrame, (not IsClassic and UnitHasVehicleUI("player")) and "vehicle" or "player")
	end

	if not InCombatLockdown() then
		self.state:SetAttribute("extendedPortrait", pconf.extendPortrait)
		self.state:SetAttribute("druidBarOff", pconf.noDruidBar)
		self.state:SetAttribute("xpBar", pconf.xpBar)
		self.state:SetAttribute("repBar", pconf.repBar)
		self.state:SetAttribute("spec", pconf.showRunes)
		self.state:SetAttribute("specDock", pconf.dockRunes)
	end

	if (pconf.level) then
		self.levelFrame:Show()
	else
		self.levelFrame:Hide()
	end

	XPerl_Player_UpdateClass(self)

	if (pconf.repBar) then
		if (not self.statsFrame.repBar) then
			CreateBar(self, "repBar")
		end

		self.statsFrame.repBar:Show()
	else
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar:Hide()
		end
	end

	if (pconf.xpBar) then
		if (not self.statsFrame.xpBar) then
			MakeXPBar(self)
		end

		self.statsFrame.xpBar:Show()
		self.statsFrame.xpRestBar:Show()

		self:RegisterEvent("PLAYER_XP_UPDATE")
	else
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar:Hide()
			self.statsFrame.xpRestBar:Hide()
		end

		self:UnregisterEvent("PLAYER_XP_UPDATE")
	end

	if (pconf.values) then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
		if (self.statsFrame.druidBar) then
			self.statsFrame.druidBar.text:Show()
		end
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.text:Show()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.text:Show()
		end
	else
		self.statsFrame.healthBar.text:Hide()
		self.statsFrame.manaBar.text:Hide()
		if (self.statsFrame.druidBar) then
			self.statsFrame.druidBar.text:Hide()
		end
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.text:Hide()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.text:Hide()
		end
	end

	XPerl_Register_Prediction(self, pconf, function (guid)
		if guid == UnitGUID("player") then
			return "player"
		elseif guid == UnitGUID("vehicle") then
			return "vehicle"
		end
	end, "player", "vehicle")

	if (playerClass == "DRUID") or (playerClass == "SHAMAN") or (playerClass == "PRIEST") then
		XPerl_Player_DruidBarUpdate(self)
	end

	if not InCombatLockdown() then
		if (pconf.portrait) then
			self.portraitFrame:Show()
			self.portraitFrame:SetWidth(62)
			self.statsFrame.resurrect:Hide()
		else
			self.portraitFrame:Hide()
			self.portraitFrame:SetWidth(3)
		end

		XPerl_Player_SetWidth(self)

		local h1 = self.nameFrame:GetHeight() + self.statsFrame:GetHeight() - 2
		local h2 = self.portraitFrame:GetHeight()
		XPerl_SwitchAnchor(self, "TOPLEFT")
		self:SetHeight(max(h1, h2))

		if (pconf.extendPortrait --[[or (self.runes and pconf.showRunes and pconf.dockRunes)]]) then
			local druidBarExtra
			if (UnitPowerType(self.partyid) > 0 and not pconf.noDruidBar) and ((playerClass == "DRUID") or (playerClass == "PRIEST") or (playerClass == "SHAMAN" and not IsClassic and GetSpecialization() == 1 and GetShapeshiftForm() == 0)) then
				druidBarExtra = 1
			else
				druidBarExtra = 0
			end

			self:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
			self.portraitFrame:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
		else
			self:SetHeight(62)
			self.portraitFrame:SetHeight(62)
		end
	end

	if (self.runes) then
		if (pconf.showRunes) then
			self.runes:Show()
		else
			self.runes:Hide()
		end
	end

	--[[self.highlight:ClearAllPoints()
	if (not pconf.level and not pconf.classIcon and (not ZPerlConfigHelper or ZPerlConfigHelper.ShowTargetCounters == 0)) then
		self.highlight:SetPoint("TOPLEFT", self.portraitFrame, "TOPLEFT", 0, 0)
	else
		self.highlight:SetPoint("TOPLEFT", self.levelFrame, "TOPLEFT", 0, 0)
	end
	self.highlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)]]

	if (playerClass == "SHAMAN" or playerClass == "DRUID" or playerClass == "MAGE" or playerClass == "MONK" or playerClass == "PRIEST" or playerClass == "WARRIOR" or playerClass == "WARLOCK") then
		if (not pconf.totems) then
			pconf.totems = {
				enable = true,
				offsetX = 0,
				offsetY = 0
			}
		end

		if (not IsClassic and not self.totemHooked) then
			hooksecurefunc("TotemFrame_Update", XPerl_Player_SetTotems)
			self.totemHooked = true
		end
	end

	self:SetAlpha(conf.transparency.frame)

	self.buffOptMix = nil
	XPerl_Player_UpdateDisplay(self)

	if (XPerl_Player_BuffSetup) then
		if (self.buffFrame) then
			self.buffOptMix = nil
			XPerl_Player_BuffSetup(XPerl_Player)
		end
	end

	if (XPerl_Voice) then
		XPerl_Voice:Register(self)
	end

	--UpdateAssignedRoles(self)
end

local function MakeMoveable(frame)
	frame:SetMovable(true)
	frame:SetUserPlaced(true)
	frame:RegisterForDrag("LeftButton")

	frame:SetScript("OnDragStart", function(self)
		if (not pconf.dockRunes) then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		if (not pconf.dockRunes) then
			self:StopMovingOrSizing()
			XPerl_SavePosition(self)
		end
	end)
end

-- XPerl_Player_InitCP
function XPerl_Player_InitCP(self)
	local _, class = UnitClass("player")
	if (class == "DRUID") or (class == "ROGUE") then
		if not ComboPointPlayerFrame then
			return
		end

		self.runes = CreateFrame("Frame", "XPerl_Runes", self)
		self.runes:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 0, 2)
		self.runes:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, -22)
		self.runes.child = ComboPointPlayerFrame
		self.runes.unit = "player"

		if pconf.lockRunes then
			local moving
			hooksecurefunc(ComboPointPlayerFrame, "SetPoint", function(self)
				if moving then
					return
				end
				if not pconf.showRunes then
					return
				end
				if not pconf.lockRunes then
					return
				end
				moving = true
				self:SetMovable(true)
				--self:SetUserPlaced(true)
				self:ClearAllPoints()
				self:SetPoint("TOP", XPerl_Player.runes, "TOP", 0, 2)
				self:SetMovable(false)
				moving = nil
			end)
		end

		ComboPointPlayerFrame:SetParent(self.runes)
		ComboPointPlayerFrame:ClearAllPoints()
		ComboPointPlayerFrame:SetPoint("TOP", self.runes, "TOP", 0, 2)
	end
end

-- XPerl_Player_InitWarlock
function XPerl_Player_InitWarlock(self)
	local _, class = UnitClass("player")
	if (class == "WARLOCK" ) then

		if not WarlockPowerFrame then
			return
		end

		self.runes = CreateFrame("Frame", "XPerl_Runes", self)
		self.runes:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 0, 2)
		self.runes:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, -22)
		self.runes.child = WarlockPowerFrame
		self.runes.unit = "player"

		if pconf.lockRunes then
			local moving
			hooksecurefunc(WarlockPowerFrame, "SetPoint", function(self)
				if moving then
					return
				end
				if not pconf.showRunes then
					return
				end
				if not pconf.lockRunes then
					return
				end
				moving = true
				self:SetMovable(true)
				--self:SetUserPlaced(true)
				self:ClearAllPoints()
				self:SetPoint("TOP", XPerl_Player.runes, "TOP", 0, 0)
				self:SetMovable(false)
				moving = nil
			end)
		end

		WarlockPowerFrame:SetParent(self.runes)
		WarlockPowerFrame:ClearAllPoints()
		WarlockPowerFrame:SetPoint("TOP", self.runes, "TOP", 0, 0)
	end
end

-- XPerl_Player_InitPaladin
function XPerl_Player_InitPaladin(self)
	local _, class = UnitClass("player")
	if (class == "PALADIN") then

		if not PaladinPowerBarFrame then
			return
		end

		self.runes = CreateFrame("Frame", "XPerl_Runes", self)
		self.runes:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 0, 2)
		self.runes:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, -22)
		self.runes.child = PaladinPowerBarFrame
		self.runes.unit = "player"

		if pconf.lockRunes then
			local moving
			hooksecurefunc(PaladinPowerBarFrame, "SetPoint", function(self)
				if moving then
					return
				end
				if not pconf.showRunes then
					return
				end
				if not pconf.lockRunes then
					return
				end
				moving = true
				self:SetMovable(true)
				--self:SetUserPlaced(true)
				self:ClearAllPoints()
				self:SetPoint("TOP", XPerl_Player.runes, "TOP", 0, 6)
				self:SetMovable(false)
				moving = nil
			end)
		end

		PaladinPowerBarFrame:SetParent(self.runes)
		PaladinPowerBarFrame:ClearAllPoints()
		PaladinPowerBarFrame:SetPoint("TOP", self.runes, "TOP", 0, 6)
	end
end

-- XPerl_Player_InitMonk
function XPerl_Player_InitMonk(self)
	local _, class = UnitClass("player")
	if (class == "MONK") then
		self.runes = CreateFrame("Frame", "XPerl_Runes", self)
		self.runes:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 0, 2)
		self.runes:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, -22)
		self.runes.child = MonkHarmonyBarFrame
		self.runes.child2 = MonkStaggerBar
		self.runes.unit = "player"

		if pconf.lockRunes then
			local moving
			hooksecurefunc(MonkHarmonyBarFrame, "SetPoint", function(self)
				if moving then
					return
				end
				if not pconf.showRunes then
					return
				end
				if not pconf.lockRunes then
					return
				end
				moving = true
				self:SetMovable(true)
				--self:SetUserPlaced(true)
				self:ClearAllPoints()
				self:SetPoint("TOP", XPerl_Player.runes, "TOP", 0, 18)
				self:SetMovable(false)
				moving = nil
			end)
		end

		MonkHarmonyBarFrame:SetParent(self.runes)
		MonkHarmonyBarFrame:SetFrameLevel(0)
		MonkHarmonyBarFrame:ClearAllPoints()
		MonkHarmonyBarFrame:SetPoint("TOP", self.runes, "TOP", 0, 18)

		if pconf.lockRunes then
			local moving
			hooksecurefunc(MonkStaggerBar, "SetPoint", function(self)
				if moving then
					return
				end
				if not pconf.showRunes then
					return
				end
				if not pconf.lockRunes then
					return
				end
				moving = true
				self:SetMovable(true)
				--self:SetUserPlaced(true)
				self:ClearAllPoints()
				self:SetPoint("TOP", XPerl_Player.runes, "TOP", 0, 0)
				self:SetMovable(false)
				moving = nil
			end)
		end

		MonkStaggerBar:SetParent(self.runes)
		MonkStaggerBar:ClearAllPoints()
		MonkStaggerBar:SetPoint("TOP", self.runes, "TOP", 0, 0)
		MonkStaggerBar:SetScript("OnMouseUp", nil)

		MonkStaggerBar:HookScript("OnShow", function(self)
			if XPerl_Player_Buffs_Position then
				XPerl_Player_Buffs_Position(XPerl_Player)
			end
		end)
		MonkStaggerBar:HookScript("OnHide", function(self)
			if XPerl_Player_Buffs_Position then
				XPerl_Player_Buffs_Position(XPerl_Player)
			end
		end)
	end
end

--XPerl_Player_InitMage
function XPerl_Player_InitMage(self)
	local _, class = UnitClass("player")
	if (class == "MAGE") then

		if not MageArcaneChargesFrame then
			return
		end

		self.runes = CreateFrame("Frame", "XPerl_Runes", self)
		self.runes:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 0, 2)
		self.runes:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, -22)
		self.runes.child = MageArcaneChargesFrame
		self.runes.unit = "player"

		if pconf.lockRunes then
			local moving
			hooksecurefunc(MageArcaneChargesFrame, "SetPoint", function(self)
				if moving then
					return
				end
				if not pconf.showRunes then
					return
				end
				if not pconf.lockRunes then
					return
				end
				moving = true
				self:SetMovable(true)
				--self:SetUserPlaced(true)
				self:ClearAllPoints()
				self:SetPoint("TOP", XPerl_Player.runes, "TOP", 0, 0)
				self:SetMovable(false)
				moving = nil
			end)
		end

		MageArcaneChargesFrame:SetParent(self.runes)
		MageArcaneChargesFrame:ClearAllPoints()
		MageArcaneChargesFrame:SetPoint("TOP", self.runes, "TOP", 0, 0)
	end
end

--XPerl_Player_InitDK
function XPerl_Player_InitDK(self)
	local _, class = UnitClass("player")
	if (class == "DEATHKNIGHT") then

		if not RuneFrame then
			return
		end

		self.runes = CreateFrame("Frame", "XPerl_Runes", self)
		self.runes:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 0, 2)
		self.runes:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, -22)
		self.runes.child = RuneFrame
		self.runes.unit = "player"

		if pconf.lockRunes then
			local moving
			hooksecurefunc(RuneFrame, "SetPoint", function(self)
				if moving then
					return
				end
				if not pconf.showRunes then
					return
				end
				if not pconf.lockRunes then
					return
				end
				moving = true
				self:SetMovable(true)
				--self:SetUserPlaced(true)
				self:ClearAllPoints()
				self:SetPoint("TOP", XPerl_Player.runes, "TOP", 3, 0)
				self:SetMovable(false)
				moving = nil
			end)
		end

		RuneFrame:SetParent(self.runes)
		RuneFrame:ClearAllPoints()
		RuneFrame:SetPoint("TOP", self.runes, "TOP", 3, 0)
	end
end
