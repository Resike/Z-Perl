-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local XPerl_Raid_Events = { }
local RaidGroupCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local myGroup
local FrameArray = { }		-- List of raid frames indexed by raid ID
local RaidPositions = { }	-- Back-matching of unit names to raid ID
local ResArray = { }		-- List of currently active resserections in progress
--local buffUpdates = { }		-- Queue for buff updates after a roster change
local raidLoaded
local rosterUpdated
local percD = "%d"..PERCENT_SYMBOL
local perc1F = "%.1f"..PERCENT_SYMBOL
local fullyInitiallized
local SkipHighlightUpdate

--local taintFrames = { }

local conf, rconf, cconf
XPerl_RequestConfig(function(newConf)
	conf = newConf
	rconf = conf.raid
	cconf = conf.custom
end, "$Revision: @file-revision@ $")

--[[if type(RegisterAddonMessagePrefix) == "function" then
	RegisterAddonMessagePrefix("CTRA")
end--]]

--[===[@debug@
local function d(...)
	ChatFrame1:AddMessage(format(...))
end
--@end-debug@]===]

--local new, del, copy = XPerl_GetReusableTable, XPerl_FreeTable, XPerl_CopyTable

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsWrathClassic = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

local format = format
local strsub = strsub

local GetNumGroupMembers = GetNumGroupMembers
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGhost = UnitIsGhost
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local XPerl_UnitBuff = XPerl_UnitBuff
local XPerl_UnitDebuff = XPerl_UnitDebuff
local XPerl_CheckDebuffs = XPerl_CheckDebuffs
local XPerl_ColourFriendlyUnit = XPerl_ColourFriendlyUnit
local XPerl_ColourHealthBar = XPerl_ColourHealthBar


-- TODO - Watch for:	 ERR_FRIEND_OFFLINE_S = "%s has gone offline."

XPERL_RAIDGRP_PREFIX = "XPerl_Raid_Grp"

-- Hold some raid roster information (AFK, DND etc.)
-- Is also stored between sessions to maintain timers and flags
ZPerl_Roster = { }

-- Uses some variables from FrameXML\RaidFrame.lua:
-- MAX_RAID_MEMBERS = 40
-- NUM_RAID_GROUPS = 8
-- MEMBERS_PER_RAID_GROUP = 5

local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local CLASS_COUNT = 0
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	if k ~= "Adventurer" then
		CLASS_COUNT = CLASS_COUNT + 1
	end
end

local resSpells
if IsClassic then
	resSpells = {
		[GetSpellInfo(2006)] = true,			-- Resurrection
		[GetSpellInfo(2008)] = true,			-- Ancestral Spirit
		[GetSpellInfo(20484)] = true,			-- Rebirth
		[GetSpellInfo(7328)] = true,			-- Redemption
		--[GetSpellInfo(50769)] = true,			-- Revive
		--[GetSpellInfo(83968)] = true,			-- Mass Resurrection
		--[GetSpellInfo(115178)] = true,			-- Resuscitate
	}
else
	resSpells = {
		[GetSpellInfo(2006)] = true,			-- Resurrection
		[GetSpellInfo(2008)] = true,			-- Ancestral Spirit
		[GetSpellInfo(20484)] = true,			-- Rebirth
		[GetSpellInfo(7328)] = true,			-- Redemption
		[GetSpellInfo(50769)] = true,			-- Revive
		--[GetSpellInfo(83968)] = true,			-- Mass Resurrection
		[GetSpellInfo(115178)] = true,			-- Resuscitate
	}
end

local hotSpells = XPERL_HIGHLIGHT_SPELLS.hotSpells

----------------------
-- Loading Function --
----------------------

local raidHeaders = { }

-- XPerl_Raid_OnLoad
function XPerl_Raid_OnLoad(self)
	local events = {
		--"CHAT_MSG_ADDON",
		"PLAYER_ENTERING_WORLD",
		"VARIABLES_LOADED",
		"COMPACT_UNIT_FRAME_PROFILES_LOADED",
		"GROUP_ROSTER_UPDATE",
		"UNIT_FLAGS",
		"UNIT_AURA",
		"UNIT_POWER_FREQUENT",
		"UNIT_MAXPOWER",
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		"UNIT_NAME_UPDATE",
		"PLAYER_FLAGS_CHANGED",
		"UNIT_COMBAT",
		"READY_CHECK",
		"READY_CHECK_CONFIRM",
		"READY_CHECK_FINISHED",
		"RAID_TARGET_UPDATE",
		"PLAYER_LOGIN",
		"ROLE_CHANGED_INFORM",
		"PET_BATTLE_OPENING_START",
		"PET_BATTLE_CLOSE",
		"UNIT_CONNECTION",
		"UNIT_SPELLCAST_START",
		"UNIT_SPELLCAST_STOP",
		"UNIT_SPELLCAST_FAILED",
		"UNIT_SPELLCAST_INTERRUPTED",
		--"PLAYER_REGEN_ENABLED",
		"INCOMING_RESURRECT_CHANGED",
	}

	local CastbarEventHandler = function(event, ...)
		return XPerl_Raid_OnEvent(self, event, ...)
	end
	for i, event in pairs(events) do
		if pcall(self.RegisterEvent, self, event) then
			self:RegisterEvent(event)
		end
	end

	self:SetScript("OnEvent", XPerl_Raid_OnEvent)

	for i = 1, CLASS_COUNT do
		--_G["XPerl_Raid_Grp"..i]:UnregisterEvent("UNIT_NAME_UPDATE")
		tinsert(raidHeaders, _G[XPERL_RAIDGRP_PREFIX..i])
	end

	if not IsClassic then
		self.state = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
		self.state:SetFrameRef("ZPerlRaidHeader1", _G[XPERL_RAIDGRP_PREFIX..1])
		self.state:SetFrameRef("ZPerlRaidHeader2", _G[XPERL_RAIDGRP_PREFIX..2])
		self.state:SetFrameRef("ZPerlRaidHeader3", _G[XPERL_RAIDGRP_PREFIX..3])
		self.state:SetFrameRef("ZPerlRaidHeader4", _G[XPERL_RAIDGRP_PREFIX..4])
		self.state:SetFrameRef("ZPerlRaidHeader5", _G[XPERL_RAIDGRP_PREFIX..5])
		self.state:SetFrameRef("ZPerlRaidHeader6", _G[XPERL_RAIDGRP_PREFIX..6])
		self.state:SetFrameRef("ZPerlRaidHeader7", _G[XPERL_RAIDGRP_PREFIX..7])
		self.state:SetFrameRef("ZPerlRaidHeader8", _G[XPERL_RAIDGRP_PREFIX..8])
		self.state:SetFrameRef("ZPerlRaidHeader9", _G[XPERL_RAIDGRP_PREFIX..9])
		self.state:SetFrameRef("ZPerlRaidHeader10", _G[XPERL_RAIDGRP_PREFIX..10])
		self.state:SetFrameRef("ZPerlRaidHeader11", _G[XPERL_RAIDGRP_PREFIX..11])
		self.state:SetFrameRef("ZPerlRaidHeader12", _G[XPERL_RAIDGRP_PREFIX..12])
		self.state:SetFrameRef("ZPerlRaidHeader13", _G[XPERL_RAIDGRP_PREFIX..13])

		self.state:SetAttribute("partySmallRaid", XPerlDB.party.smallRaid)
		self.state:SetAttribute("raidEnabled", XPerlDB.raid.enable)

		self.state:SetAttribute("_onstate-groupupdate", [[
			--print(newstate)

			if newstate == "hide" then
				self:GetFrameRef("ZPerlRaidHeader1"):Hide()
				self:GetFrameRef("ZPerlRaidHeader2"):Hide()
				self:GetFrameRef("ZPerlRaidHeader3"):Hide()
				self:GetFrameRef("ZPerlRaidHeader4"):Hide()
				self:GetFrameRef("ZPerlRaidHeader5"):Hide()
				self:GetFrameRef("ZPerlRaidHeader6"):Hide()
				self:GetFrameRef("ZPerlRaidHeader7"):Hide()
				self:GetFrameRef("ZPerlRaidHeader8"):Hide()
				self:GetFrameRef("ZPerlRaidHeader9"):Hide()
				self:GetFrameRef("ZPerlRaidHeader10"):Hide()
				self:GetFrameRef("ZPerlRaidHeader11"):Hide()
				self:GetFrameRef("ZPerlRaidHeader12"):Hide()
				self:GetFrameRef("ZPerlRaidHeader13"):Hide()
			elseif self:GetAttribute('partySmallRaid') or not self:GetAttribute('raidEnabled') then
				return
			else
				self:GetFrameRef("ZPerlRaidHeader1"):Show()
				self:GetFrameRef("ZPerlRaidHeader2"):Show()
				self:GetFrameRef("ZPerlRaidHeader3"):Show()
				self:GetFrameRef("ZPerlRaidHeader4"):Show()
				self:GetFrameRef("ZPerlRaidHeader5"):Show()
				self:GetFrameRef("ZPerlRaidHeader6"):Show()
				self:GetFrameRef("ZPerlRaidHeader7"):Show()
				self:GetFrameRef("ZPerlRaidHeader8"):Show()
				self:GetFrameRef("ZPerlRaidHeader9"):Show()
				self:GetFrameRef("ZPerlRaidHeader10"):Show()
				self:GetFrameRef("ZPerlRaidHeader11"):Show()
				self:GetFrameRef("ZPerlRaidHeader12"):Show()
				self:GetFrameRef("ZPerlRaidHeader13"):Show()
			end
		]])
		RegisterStateDriver(self.state, "groupupdate", "[petbattle] hide; show")
	end

	self.Array = { }

	--[[if (rconf.enable) then
		--CompactRaidFrameManager:SetParent(self)
		if CompactUnitFrameProfiles then
			CompactUnitFrameProfiles:UnregisterAllEvents()
		end
		if CompactRaidFrameManager then
			CompactRaidFrameManager:UnregisterAllEvents()
			CompactRaidFrameContainer:UnregisterAllEvents()
		end
	end]]

	--[[if CompactRaidFrameManager then
		if rconf.enable then
			local function hideRaid()
				CompactRaidFrameManager:UnregisterAllEvents()
				CompactRaidFrameContainer:UnregisterAllEvents()
				if InCombatLockdown() then
					return
				end

				CompactRaidFrameManager:Hide()
				local shown = CompactRaidFrameManager_GetSetting("IsShown")
				if shown and shown ~= "0" then
					CompactRaidFrameManager_SetSetting("IsShown", "0")
				end
			end

			hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
				hideRaid()
			end)

			hideRaid()
			CompactRaidFrameContainer:HookScript("OnShow", hideRaid)
			CompactRaidFrameManager:HookScript("OnShow", hideRaid)
		end
	end]]

	XPerl_RegisterOptionChanger(function()
		if (raidLoaded) then
			XPerl_RaidTitles()
		end

		XPerl_Raid_Set_Bits(XPerl_Raid_Frame)

		if (raidLoaded) then
			SkipHighlightUpdate = true
			XPerl_Raid_UpdateDisplayAll()
			SkipHighlightUpdate = nil
		end
	end, "Raid")

	XPerl_Raid_OnLoad = nil
end

-- XPerl_Raid_HeaderOnLoad
function XPerl_Raid_HeaderOnLoad(self)
	self:RegisterForDrag("LeftButton")
	self.text = _G[self:GetName().."TitleText"]
	self.virtual = _G[self:GetName().."Virtual"]
	XPerl_RegisterUnitText(self.text)
	--XPerl_SavePosition(self, true)
end

-- CreateManaBar
--[[local function CreateManaBar(self)
	local sf = self.statsFrame
	sf.manaBar = CreateFrame("StatusBar", sf:GetName().."manaBar", sf, "XPerlRaidStatusBar")
	sf.manaBar:SetScale(0.7)
	sf.manaBar:SetWidth(70)
	sf.manaBar:SetPoint("TOPLEFT", sf.healthBar, "BOTTOMLEFT", 0, 0)
	sf.manaBar:SetPoint("BOTTOMRIGHT", sf.healthBar, "BOTTOMRIGHT", 0, -7)
	sf.manaBar:SetStatusBarColor(0, 0, 1)
end]]

-- Setup1RaidFrame
local function Setup1RaidFrame(self)
	if (rconf.mana) then
		--[[if (not self.statsFrame.manaBar) then
			CreateManaBar(self)
		end]]
		if not InCombatLockdown() then
			self:SetHeight(43)
		end
		self.statsFrame:SetHeight(26)
		self.statsFrame.manaBar:Show()
	else
		if not InCombatLockdown() then
			self:SetHeight(38)
		end
		self.statsFrame:SetHeight(21)
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar:Hide()
		end
	end

	if (rconf.percent) then
		self.statsFrame.healthBar.text:Show()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Show()
		end
	else
		self.statsFrame.healthBar.text:Hide()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Hide()
		end
	end

	if (XPerl_Voice) then
		XPerl_Voice:Register(self, true)
	end
end

-- SetFrameArray
local function SetFrameArray(self, value)
	for k, v in pairs(FrameArray) do
		if (v == self) then
			FrameArray[k] = nil
			break
		end
	end

	self.partyid = value

	if (value) then
		FrameArray[value] = self
	end
end

-- XPerl_Raid_UpdateName
local function XPerl_Raid_UpdateName(self)
	local partyid = self:GetAttribute("unit")
	if (not partyid) then
		partyid = SecureButton_GetUnit(self)
		if (not partyid) then
			self.lastGUID, self.lastID = nil, nil
			return
		end
	end

	local name = UnitName(partyid)
	local guid = UnitGUID(partyid)
	self.lastGUID, self.lastID = guid, partyid -- These stored, so we can at least make a small effort in reducing workload on attribute changes.

	if (name) then
		self.nameFrame.text:SetText(name)

		if (self.pet) then
			local color = conf.ColourReactionNone
			self.nameFrame.text:SetTextColor(color.r, color.g, color.b)
		else
			XPerl_ColourFriendlyUnit(self.nameFrame.text, partyid)
		end
	end
end

-- XPerl_Raid_CheckFlags
local function XPerl_Raid_CheckFlags(partyid)
	local unitName, realm = UnitName(partyid)
	if realm and realm ~= "" then
		unitName = unitName.."-"..realm
	end
	local resser

	for i, name in pairs(ResArray) do
		if (name == unitName) then
			resser = i
			break
		end
	end

	if (resser) then
		-- Verify they're dead..
		if (UnitIsDeadOrGhost(partyid)) then
			return {flag = resser..XPERL_RAID_RESSING, bgcolor = {r = 0, g = 0.5, b = 1}}
		end

		ResArray[resser] = nil
	end

	local unitInfo = ZPerl_Roster[unitName]
	if (unitInfo and unitInfo.ressed) then
		if (UnitIsDead(partyid)) then
			if (unitInfo.ressed == 2) then
				return {flag = XPERL_LOC_SS_AVAILABLE, bgcolor = {r = 0, g = 1, b = 0.5}}
			elseif (unitInfo.ressed == 3) then
				return {flag = XPERL_LOC_ACCEPTEDRES, bgcolor = {r = 0, g = 0.5, b = 1}}
			else
				return {flag = XPERL_LOC_RESURRECTED, bgcolor = {r = 0, g = 0.5, b = 1}}
			end
		else
			unitInfo.ressed = nil
			XPerl_Raid_UpdateManaType(FrameArray[partyid], true)
		end
	elseif (unitInfo and unitInfo.afk) then
		if (UnitIsAFK(partyid)) then
			if (conf.showAFK) then
				return {flag = XPERL_RAID_AFK}
			end
		else
			unitInfo.afk = nil
		end
	else
		if (UnitIsAFK(partyid)) then
			if (conf.showAFK) then
				return {flag = XPERL_RAID_AFK}
			end
		end
	end
end

-- XPerl_Raid_UpdateManaType
function XPerl_Raid_UpdateManaType(self, skipFlags)
	if (rconf.mana) then
		local partyid = self:GetAttribute("unit")
		if (not partyid) then
			partyid = SecureButton_GetUnit(self)
			if (not partyid) then
				return
			end
			return
		end

		local flags
		if (not skipFlags) then
			flags = XPerl_Raid_CheckFlags(partyid)
		end
		if (not flags) then
			XPerl_SetManaBarType(self)
		end
	end
end

-- XPerl_Raid_ShowFlags
local function XPerl_Raid_ShowFlags(self, flags)
	local r, g, b
	local flag
	if (type(flags) == "string") then
		flag = flags
		flags = nil
	else
		flag = flags.flag
	end

	if (flags and flags.bgcolor) then
		r, g, b = flags.bgcolor.r, flags.bgcolor.g, flags.bgcolor.b
	else
		r, g, b = 0.5, 0.5, 0.5
	end

	self.statsFrame:SetGrey(r, g, b)

	if (flags and flags.color) then
		r, g, b = flags.color.r, flags.color.g, flags.color.b
	else
		r, g, b = 1, 1, 1
	end

	self.statsFrame.healthBar.text:SetText(flag)
	self.statsFrame.healthBar.text:SetTextColor(r, g, b)
	self.statsFrame.healthBar.text:Show()
	--del(flags)
end

-- XPerl_Raid_UpdateAbsorbPrediction
local function XPerl_Raid_UpdateAbsorbPrediction(self)
	if rconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

-- XPerl_Raid_UpdateHealPrediction
local function XPerl_Raid_UpdateHealPrediction(self)
	if rconf.healprediction then
		XPerl_SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

-- XPerl_Raid_UpdateHotsPrediction
local function XPerl_Raid_UpdateHotsPrediction(self)
	if not IsWrathClassic then
		return
	end
	if rconf.hotPrediction then
		XPerl_SetExpectedHots(self)
	else
		self.statsFrame.expectedHots:Hide()
	end
end

local function XPerl_Raid_UpdateResurrectionStatus(self)
	if (UnitHasIncomingResurrection(self.partyid)) then
		self.statsFrame.resurrect:Show()
	else
		self.statsFrame.resurrect:Hide()
	end
end

local feignDeath = GetSpellInfo(5384)
local spiritOfRedemption = GetSpellInfo(27827)

-- XPerl_Raid_UpdateHealth
local function XPerl_Raid_UpdateHealth(self)
	local partyid = self.partyid
	if (not partyid) then
		return
	end

	local health = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid))
	local healthmax = UnitHealthMax(partyid)

	--[[if (health > healthmax) then
		-- New glitch with 1.12.1
		if (UnitIsDeadOrGhost(partyid)) then
			health = 0
		else
			health = healthmax
		end
	end--]]

	self.statsFrame.healthBar:SetMinMaxValues(0, healthmax)
	if (conf.bar.inverse) then
		self.statsFrame.healthBar:SetValue(healthmax - health)
	else
		self.statsFrame.healthBar:SetValue(health)
	end

	if (not rconf.percent) then
		if (self.statsFrame.healthBar.text:IsShown()) then
			self.statsFrame.healthBar.text:Hide()
		end
	end

	XPerl_Raid_UpdateAbsorbPrediction(self)
	XPerl_Raid_UpdateHealPrediction(self)
	XPerl_Raid_UpdateHotsPrediction(self)
	XPerl_Raid_UpdateResurrectionStatus(self)

	local name, realm = UnitName(partyid)
	if realm and realm ~= "" then
		name = name.."-"..realm
	end
	local myRoster = ZPerl_Roster[name]
	if (name and UnitIsConnected(partyid)) then
		--self.disco = nil
		--[[if (self.feigning and not UnitBuff(partyid, feignDeath)) then
			self.feigning = nil
		end]]

		local flags = XPerl_Raid_CheckFlags(partyid)
		if (flags) then
			XPerl_Raid_ShowFlags(self, flags)

			if (UnitIsDeadOrGhost(partyid)) then
				self.dead = true
				XPerl_Raid_UpdateName(self)
			end
			return
		--[[elseif (UnitBuff(partyid, feignDeath) and conf.showFD) then
			XPerl_NoFadeBars(true)
			self.statsFrame.healthBar.text:SetText(XPERL_LOC_FEIGNDEATH)
			self.statsFrame:SetGrey()
			XPerl_NoFadeBars()
		elseif (UnitBuff(partyid, spiritOfRedemption)) then
			self.dead = true
			XPerl_Raid_ShowFlags(self, XPERL_LOC_DEAD)
			XPerl_Raid_UpdateName(self)--]]
		elseif (UnitIsDead(partyid)) then
			self.dead = true
			XPerl_Raid_ShowFlags(self, XPERL_LOC_DEAD)
			XPerl_Raid_UpdateName(self)
		elseif (UnitIsGhost(partyid)) then
			self.dead = true
			XPerl_Raid_ShowFlags(self, XPERL_LOC_GHOST)
			XPerl_Raid_UpdateName(self)
		else
			if (self.dead or (myRoster and (--[[(UnitBuff(partyid, feignDeath) and conf.showFD) or --]]myRoster.ressed))) then
				XPerl_Raid_UpdateManaType(self, true)
			end
			self.dead = nil

			-- Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
			local percentHp
			if health > 0 and healthmax == 0 then -- We have current hp but max hp failed.
				healthmax = health -- Make max hp at least equal to current health
				percentHp = 1 -- And percent 100% cause a number divided by itself is 1, duh.
			elseif health == 0 and healthmax == 0 then -- Probably dead target
				percentHp = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
			else
				percentHp = health / healthmax -- Everything is dandy, so just do it right way.
			end
			--end division by 0 check
			if (rconf.healerMode.enable) then
				self.statsFrame.healthBar.text:SetText(-(healthmax - health))
			else
				if rconf.values then
					self.statsFrame.healthBar.text:SetFormattedText("%d/%d", health, healthmax)
				elseif rconf.precisionPercent then
					self.statsFrame.healthBar.text:SetFormattedText(perc1F, percentHp == 1 and 100 or percentHp * 100 + 0.05)
				else
					local show = percentHp * 100
					if show < 10 then
						self.statsFrame.healthBar.text:SetFormattedText(perc1F or "%.1f%%", percentHp == 1 and 100 or percentHp * 100 + 0.05)
					else
						self.statsFrame.healthBar.text:SetFormattedText(percD or "%d%%", percentHp == 1 and 100 or percentHp * 100 + 0.5)
					end
				end
			end

			-- XPerl_SetSmoothBarColor(self.statsFrame.healthBar, percentHp)
			XPerl_ColourHealthBar(self, percentHp, partyid)

			if (self.statsFrame.greyMana) then
				self.statsFrame.greyMana = nil
				if (myRoster) then
					myRoster.resCount = nil
					myRoster.ressed = nil
				end
				XPerl_Raid_UpdateManaType(self, true)
			end
		end
	else
		--self.disco = true
		self.dead = nil
		XPerl_Raid_ShowFlags(self, XPERL_LOC_OFFLINE)

		if (name and myRoster and not myRoster.offline) then
			myRoster.offline = GetTime()
			myRoster.afk = nil
			myRoster.dnd = nil
		end
	end
end

-- XPerl_Raid_UpdateMana
local function XPerl_Raid_UpdateMana(self)
	if (rconf.mana) then
		--[[if (not self.statsFrame.manaBar) then
			CreateManaBar(self)
		end]]

		local partyid = self.partyid
		if (not partyid) then
			return
		end

		local pType = XPerl_GetDisplayedPowerType(partyid)

		local mana = UnitPower(partyid, pType)
		local manamax = UnitPowerMax(partyid, pType)

		if (rconf.manaPercent and XPerl_GetDisplayedPowerType(partyid) == 0 and not self.pet) then
			if (rconf.values) then -- TODO rconf.manavalues
				self.statsFrame.manaBar.text:SetFormattedText("%d/%d", mana, manamax)
			else
				--Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
				local pmanaPct
				if mana > 0 and manamax == 0 then -- We have current mana but max mana failed.
					manamax = mana -- Make max mana at least equal to current health
					pmanaPct = 1 -- And percent 100% cause a number divided by itself is 1, duh.
				elseif mana == 0 and manamax == 0 then--Probably doesn't use mana or is oom?
					pmanaPct = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
				else
					pmanaPct = mana / manamax -- Everything is dandy, so just do it right way.
				end
				-- end division by 0 check

				if rconf.precisionManaPercent then
					self.statsFrame.manaBar.text:SetFormattedText(perc1F, pmanaPct * 100)
				else
					self.statsFrame.manaBar.text:SetFormattedText(percD, pmanaPct * 100)
				end
			end
		else
			self.statsFrame.manaBar.text:SetText("")
		end

		self.statsFrame.manaBar:SetMinMaxValues(0, manamax)
		self.statsFrame.manaBar:SetValue(mana)
	end
end

-- onAttrChanged
local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value) then
			SetFrameArray(self, value)
			if (self.lastID ~= value or self.lastGUID ~= UnitGUID(value)) then
				XPerl_Raid_UpdateDisplay(self)
			end
		else
			--buffUpdates[self] = nil
			SetFrameArray(self)
			self.lastID = nil
			self.lastGUID = nil
		end
	end
end

-- XPerl_Raid_Single_OnLoad
function XPerl_Raid_Single_OnLoad(self)
	XPerl_SetChildMembers(self)

	self.edgeFile = "Interface\\AddOns\\ZPerl\\Images\\XPerl_ThinEdge"
	self.edgeSize = 10
	self.edgeInsets = 2

	XPerl_RegisterHighlight(self.highlight, 2)

	XPerl_RegisterPerlFrames(self, {self.nameFrame, self.statsFrame})
	self.FlashFrames = {self.nameFrame, self.statsFrame}

	self:SetScript("OnAttributeChanged", onAttrChanged)

	XPerl_RegisterClickCastFrame(self)
	XPerl_RegisterClickCastFrame(self.nameFrame)

	Setup1RaidFrame(self)

	self:RegisterForClicks("AnyUp")
	self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
end

-- XPerl_Raid_CombatFlash
local function XPerl_Raid_CombatFlash(self, elapsed, argNew, argGreen)
	if (XPerl_CombatFlashSet(self, elapsed, argNew, argGreen)) then
		XPerl_CombatFlashSetFrames(self)
	end
end

-- XPerl_GetRaidPosition
function XPerl_GetRaidPosition(findName)
	return RaidPositions[findName]
end

-- XPerl_Raid_GetUnitFrameByName
function XPerl_Raid_GetUnitFrameByName(findName)
	-- Used by teamspeak module
	local id = RaidPositions[findName]
	if (id) then
		return FrameArray[id]
	end
end

-- XPerl_Raid_GetUnitFrameByUnit
function XPerl_Raid_GetUnitFrameByUnit(unit)
	return FrameArray[unit]
end

-- XPerl_Raid_GetFrameArray
function XPerl_Raid_GetFrameArray()
	return FrameArray
end

-- UpdateUnitByName
local function UpdateUnitByName(name, flagsOnly)
	local id = RaidPositions[name]
	if (id) then
		local frame = FrameArray[id]
		if (frame and frame:IsShown()) then
			if (flagsOnly) then
				XPerl_Raid_UpdateHealth(frame)
			else
				XPerl_Raid_UpdateDisplay(frame)
			end
		end
	end
end

-- XPerl_Raid_HighlightCallback(updateName)
local function XPerl_Raid_HighlightCallback(self, guid)
	if not guid then
		return
	end

	local f = XPerl_Raid_GetUnitFrameByGUID(guid)
	if (f) then
		XPerl_Highlight:SetHighlight(f, guid)
	end
end

local buffIconCount = 0
local function GetBuffButton(self, buffnum, createIfAbsent)
	local button = self.buffFrame.buff and self.buffFrame.buff[buffnum]

	if (not button and createIfAbsent) then
		buffIconCount = buffIconCount + 1
		button = CreateFrame("Button", "XPerlRBuff"..buffIconCount, self.buffFrame, "XPerl_BuffTemplate")
		button:SetID(buffnum)

		if (not self.buffFrame.buff) then
			self.buffFrame.buff = { }
		end
		self.buffFrame.buff[buffnum] = button

		button:SetHeight(10)
		button:SetWidth(10)

		button.icon:SetTexCoord(0.078125, 0.921875, 0.078125, 0.921875)

		button:SetScript("OnEnter", XPerl_Raid_SetBuffTooltip)
		button:SetScript("OnLeave", function()
			XPerl_PlayerTipHide()
		end)
	end

	return button
end

-- GetShowCast
local function GetShowCast(self)
	if (rconf.buffs.enable) then
		return "b", (rconf.buffs.castable == 1) and "HELPFUL|RAID" or "HELPFUL"
	elseif (rconf.debuffs.enable) then
		return "d", (rconf.buffs.castable == 1) and "HARMFUL|RAID" or "HARMFUL"
	end
end

-- UpdateBuffs
local function UpdateBuffs(self)
	local partyid = self.partyid
	if not partyid then
		return
	end

	local bf = self.buffFrame

	if (conf.highlightDebuffs.enable) then
		XPerl_CheckDebuffs(self, partyid)
	end
	XPerl_ColourFriendlyUnit(self.nameFrame.text, partyid)

	local buffCount = 0
	local maxBuff = 8 - ((abs(1 - (rconf.mana and 1 or 0)) * 2) * (rconf.buffs.right and 1 or 0))

	local show, cureCast = GetShowCast(self)
	self.debuffsForced = nil
	if (show) then
		if (show == "b") then
			if (rconf.buffs.untilDebuffed) then
				local name, buff = XPerl_UnitDebuff(partyid, 1, cureCast, true)
				if (name) then
					self.debuffsForced = true
					show = "d"
				end
			end
		end

		for buffnum = 1, maxBuff do
			local name, buff
			if (show == "b") then
				name, buff = XPerl_UnitBuff(partyid, buffnum, cureCast, true)
			else
				name, buff = XPerl_UnitDebuff(partyid, buffnum, cureCast, true)
			end
			local button = GetBuffButton(self, buffnum, buff)	-- 'buff' flags whether to create icon
			if (button) then
				if (buff) then
					buffCount = buffCount + 1

					button.icon:SetTexture(buff)
					if (not button:IsShown()) then
						button:Show()
					end
				else
					if (button:IsShown()) then
						button:Hide()
					end
				end
			end
		end
		for buffnum = maxBuff + 1, 8 do
			local button = bf.buff and bf.buff[buffnum]
			if (button) then
				if (button:IsShown()) then
					button:Hide()
				end
			end
		end
	end

	if (buffCount > 0) then
		bf:ClearAllPoints()
		if (not bf:IsShown()) then
			bf:Show()
		end
		local id = self:GetID()

		if (rconf.buffs.right) then
			bf:SetPoint("BOTTOMLEFT", self.statsFrame, "BOTTOMRIGHT", -1, 1)

			if (rconf.buffs.inside) then
				if (buffCount > 3 + (rconf.mana and 1 or 0)) then
					self.statsFrame:SetWidth(60 + rconf.size.width)
				else
					self.statsFrame:SetWidth(70 + rconf.size.width)
				end
			else
				self.statsFrame:SetWidth(80 + rconf.size.width)
			end

			bf.buff[1]:ClearAllPoints()
			bf.buff[1]:SetPoint("BOTTOMLEFT", 0, 0)
			for i = 2, buffCount do
				if (i > buffCount) then
					break
				end

				local buffI = bf.buff[i]
				buffI:ClearAllPoints()

				if (i == 4 + (rconf.mana and 1 or 0)) then
					if (rconf.buffs.inside) then
						buffI:SetPoint("BOTTOMLEFT", 0, 0)
						bf.buff[1]:SetPoint("BOTTOMLEFT", buffI, "BOTTOMRIGHT", 0, 0)
					else
						buffI:SetPoint("BOTTOMLEFT", bf.buff[i-(4 - abs(1 - (rconf.mana and 1 or 0)))], "BOTTOMRIGHT", 0, 0)
					end
				else
					buffI:SetPoint("BOTTOMLEFT", bf.buff[i - 1], "TOPLEFT", 0, 0)
				end
			end
		else
			self.statsFrame:SetWidth(80 + rconf.size.width)

			bf:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 0, 1)

			local prevBuff
			for i = 1, buffCount do
				local buff = bf.buff[i]
				buff:ClearAllPoints()
				if (prevBuff) then
					buff:SetPoint("TOPLEFT", prevBuff, "TOPRIGHT", 0, 0)
				else
					buff:SetPoint("TOPLEFT", 0, 0)
				end
				prevBuff = buff
			end
		end
	else
		self.statsFrame:SetWidth(80 + rconf.size.width)
		if (bf:IsShown()) then
			bf:Hide()
		end
	end

	--[[if conf.showFD then
		local _, class = UnitClass(partyid)
		if class == "HUNTER" then
			local feigning = UnitBuff(partyid, feignDeath)
			if feigning ~= self.feigning then
				self.feigning = feigning
				XPerl_Raid_UpdateHealth(self)
			end
		end
	end--]]
end

------------------
-- Buffs stuffs --
------------------

-- XPerl_Raid_UpdateCombat
local function XPerl_Raid_UpdateCombat(self)
	local partyid = self.partyid
	if not partyid then
		return
	end
	if UnitExists(partyid) and UnitAffectingCombat(partyid) then
		self.nameFrame.combatIcon:Show()
	else
		self.nameFrame.combatIcon:Hide()
	end
	if UnitIsVisible(partyid) and UnitIsCharmed(partyid) and UnitIsPlayer(partyid) and (not IsClassic and not UnitUsingVehicle(partyid) or true) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- XPerl_Raid_UpdatePlayerFlags(self)
local function XPerl_Raid_UpdatePlayerFlags(self, partyid, ...)
	if (not partyid) then
		partyid = self:GetAttribute("unit")
	end

	local f = FrameArray[partyid]
	if f then
		self = f

		local unitName, realm = UnitName(partyid)
		if realm and realm ~= "" then
			unitName = unitName.."-"..realm
		end
		if (unitName) then
			local unitInfo = ZPerl_Roster[unitName]
			if (unitInfo) then
				local change
				if (UnitIsAFK(partyid)) then
					if (not unitInfo.afk) then
						change = true
						unitInfo.afk = GetTime()
						unitInfo.dnd = nil
					end
				elseif (UnitIsDND(partyid)) then
					if (not unitInfo.dnd) then
						change = true
						unitInfo.dnd = GetTime()
						unitInfo.afk = nil
					end
				else
					if (unitInfo.afk or unitInfo.dnd) then
						unitInfo.afk, unitInfo.dnd = nil, nil
						change = true
					end
				end

				if (change) then
					local flags = XPerl_Raid_CheckFlags(partyid)
					if (flags) then
						XPerl_Raid_ShowFlags(self, flags)
					else
						XPerl_Raid_UpdateMana(self)
						XPerl_Raid_UpdateHealth(self)
					end
				end
			end
		end
	end
end

-- XPerl_Raid_OnUpdate
function XPerl_Raid_OnUpdate(self, elapsed)
	if (rosterUpdated) then
		rosterUpdated = nil
		if InCombatLockdown() then
			XPerl_OutOfCombatQueue[XPerl_Raid_Position] = self
		else
			XPerl_Raid_Position(self)
		end
		if ZPerl_Custom and rconf.enable and cconf.enable then
			ZPerl_Custom:UpdateUnits()
		end
		if (not IsInRaid() or (not IsInGroup() and rconf.inParty)) then
			ResArray = { }
			ZPerl_Roster = { }
			--buffUpdates = { }
			return
		end
	end

	--local updateHighlights, someUpdate
	--local enemyUnitList
	-- Throttling this will fuck up the animations, and create FPS decreases over time
	--self.time = self.time + elapsed
	--if (self.time >= 0.2) then
		--self.time = 0
		--someUpdate = true
		for i, frame in pairs(FrameArray) do
			if (frame:IsShown()) then
				if (conf.combatFlash and frame.PlayerFlash) then
					XPerl_Raid_CombatFlash(frame, elapsed, false)
				end

				--[[if (someUpdate) then
					local unit = frame.partyid -- frame:GetAttribute("unit")
					if (unit) then
						local name = UnitName(unit)
						if (name) then
							local myRoster = ZPerl_Roster[name]
							if (myRoster) then
								if (frame.statsFrame.greyMana) then
									if (myRoster.offline and UnitIsConnected(unit)) then
										XPerl_Raid_UpdateHealth(frame)
									end
								else
									if (not myRoster.offline and not UnitIsConnected(unit)) then
										XPerl_Raid_UpdateHealth(frame)
									end
								end
							end
						end

						XPerl_UpdateSpellRange(frame, unit, true)
					end
				end]]--
				if conf.rangeFinder.enabled then
					self.time = elapsed + (self.time or 0)
					if self.time > 0.2 then
						self.time = 0
						if (frame.partyid) then
							XPerl_UpdateSpellRange(frame, frame.partyid, true)
						end
					end
				end
			end
		end

		-- What the hell is this?
		--[[local i = 1
		for k, v in pairs(buffUpdates) do
			UpdateBuffs(k)
			buffUpdates[k] = nil
			i = i + 1
			if (i > 5) then
				break
			end
		end]]
	--end
	fullyInitiallized = true
end

-- XPerl_Raid_RaidTargetUpdate
local function XPerl_Raid_RaidTargetUpdate(self)
	local icon = self.nameFrame.raidIcon
	local raidIcon = GetRaidTargetIndex(self.partyid)

	if (raidIcon) then
		if (not icon) then
			icon = self.nameFrame:CreateTexture(nil, "OVERLAY")
			self.nameFrame.raidIcon = icon
			icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
			icon:SetPoint("LEFT")
			icon:SetWidth(16)
			icon:SetHeight(16)
		else
			icon:Show()
		end
		SetRaidTargetIconTexture(icon, raidIcon)
	elseif (icon) then
		icon:Hide()
	end
end

local function SetRoleIconTexture(texture, role)
	if not rconf.role_icons then
		return false
	end
	if (conf.xperlOldroleicons) then
		if role == "TANK" then
			texture:SetTexture("Interface\\GroupFrame\\UI-Group-MainTankIcon")
		elseif role == "HEALER" then
			texture:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleHealer_old")
		elseif role == "DAMAGER" then
			texture:SetTexture("Interface\\GroupFrame\\UI-Group-MainAssistIcon")
		else
			return false
		end
	else
		if role == "TANK" then
			texture:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleTank")
		elseif role == "HEALER" then
			texture:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleHealer")
		elseif role == "DAMAGER" then
			texture:SetTexture("Interface\\AddOns\\ZPerl\\Images\\XPerl_RoleDamage")
		else
			return false
		end
	end
	return true
end

-- XPerl_Raid_RoleUpdate
local function XPerl_Raid_RoleUpdate(self, role)
	if not self then
		return
	end
	local icon = self.nameFrame.roleIcon or nil

	if (role) then
		if (not icon) then
			icon = self.nameFrame:CreateTexture(nil, "OVERLAY")
			self.nameFrame.roleIcon = icon
			icon:SetPoint("RIGHT", 7, 7)
			icon:SetWidth(16)
			icon:SetHeight(16)
		end

		if (SetRoleIconTexture(icon, role)) then
			icon:Show()
		else
			icon:Hide()
		end
	end
end

-------------------------
-- The Update Function --
-------------------------
function XPerl_Raid_UpdateDisplayAll()
	for k, frame in pairs(FrameArray) do
		if (frame:IsShown()) then
			XPerl_Raid_UpdateDisplay(frame)
		end
	end
end

-- XPerl_Raid_UpdateDisplay
function XPerl_Raid_UpdateDisplay(self)
	-- Health must be updated after mana, since ctra flag checks are done here.
	if (rconf.mana) then
		XPerl_Raid_UpdateManaType(self)
		XPerl_Raid_UpdateMana(self)
	end
	if not IsVanillaClassic then
		XPerl_Raid_RoleUpdate(self, UnitGroupRolesAssigned(self.partyid))
	end
	XPerl_Raid_UpdatePlayerFlags(self)
	XPerl_Raid_UpdateHealth(self)
	XPerl_Raid_UpdateName(self)
	XPerl_Raid_UpdateCombat(self)
	XPerl_Unit_UpdateReadyState(self)
	XPerl_Raid_RaidTargetUpdate(self)

	--buffUpdates[self] = true -- UpdateBuffs(self)

	if (not SkipHighlightUpdate) then
		XPerl_Highlight:SetHighlight(self)
	end

	if (XPerl_Voice) then
		XPerl_Voice:UpdateVoice(self)
	end
end

-- HideShowRaid
function XPerl_Raid_HideShowRaid()
	local singleGroup
	if (XPerl_Party_SingleGroup) then
		if (conf.party.smallRaid and fullyInitiallized) then
			singleGroup = XPerl_Party_SingleGroup()
		end
	end

	local enable = rconf.enable
	if (enable) then
		local _, instanceType = IsInInstance()
		if (instanceType == "pvp") then
			enable = not rconf.notInBG
		end
	end

	for i = 1, CLASS_COUNT do
		if (rconf.group[i] and enable and (i < 9 or rconf.sortByClass) and not singleGroup) then
			if not IsClassic and not C_PetBattles.IsInBattle() then
				if (not raidHeaders[i]:IsShown()) then
					raidHeaders[i]:Show()
				end
			else
				if (not raidHeaders[i]:IsShown()) then
					raidHeaders[i]:Show()
				end
			end
		else
			if (raidHeaders[i]:IsShown()) then
				raidHeaders[i]:Hide()
			end
		end
	end

	if (XPerl_RaidPets_Align) then
		XPerl_ProtectedCall(XPerl_RaidPets_Align)
	end
end

-------------------
-- Event Handler --
-------------------

-- XPerl_Raid_OnEvent
function XPerl_Raid_OnEvent(self, event, unit, ...)
	local func = XPerl_Raid_Events[event]
	if (func) then
		if (strfind(event, "^UNIT_")) then
			local f = FrameArray[unit]
			if (f) then
				func(f, unit, ...)
			end
		else
			func(self, unit, ...)
		end
	end
end

local function DisableCompactRaidFrames()
	if not CompactUnitFrameProfiles or not CompactUnitFrameProfiles.selectedProfile then
		return
	end
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate2Players", false)
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate3Players", false)
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate5Players", false)
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate10Players", false)
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate15Players", false)
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate40Players", false)
	if IsClassic then
		SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate20Players", false)
	else
		SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivate25Players", false)
		SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivateSpec1", false)
		SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivateSpec2", false)
	end
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivatePvP", false)
	SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "autoActivatePvE", false)
	--CompactUnitFrameProfiles_ApplyCurrentSettings()
	--CompactUnitFrameProfiles_UpdateCurrentPanel()
	CompactUnitFrameProfiles_SaveChanges(CompactUnitFrameProfiles)
	if not InCombatLockdown() then
		SetCVar("useCompactPartyFrames", 0)
		CompactUnitFrameProfilesRaidStylePartyFrames:SetChecked(false)
		CompactRaidFrameManager_SetSetting("IsShown", false)
	end
end

-- COMPACT_UNIT_FRAME_PROFILES_LOADED
function XPerl_Raid_Events:COMPACT_UNIT_FRAME_PROFILES_LOADED()
	if not rconf.disableDefault then
		return
	end
	if IsClassic then
		DisableCompactRaidFrames()
	end
	if CompactRaidFrameManager then
		CompactRaidFrameManager:UnregisterAllEvents()
		hooksecurefunc(CompactRaidFrameManager, "Show", function(self)
			self:Hide()
		end)
		CompactRaidFrameManager:Hide()
	end

	if CompactRaidFrameContainer then
		CompactRaidFrameContainer:UnregisterAllEvents()
		hooksecurefunc(CompactRaidFrameContainer, "Show", function(self)
			self:Hide()
		end)
		CompactRaidFrameContainer:Hide()
	end
end

-- VARIABLES_LOADED
function XPerl_Raid_Events:VARIABLES_LOADED()
	self:UnregisterEvent("VARIABLES_LOADED")

	if (not IsInRaid() or (not IsInGroup() and rconf.inParty)) then
		ResArray = { }
		ZPerl_Roster = { }
	else
		local myRoster = ZPerl_Roster[UnitName("player")]
		if (myRoster) then
			myRoster.afk, myRoster.dnd, myRoster.ressed, myRoster.resCount = nil, nil, nil, nil
		end
	end

	XPerl_Highlight:Register(XPerl_Raid_HighlightCallback, self)

	XPerl_Raid_Events.VARIABLES_LOADED = nil
end

function XPerl_Raid_Events:PET_BATTLE_OPENING_START()
	if (self) then
		XPerl_Raid_HideShowRaid()
	end
end

function XPerl_Raid_Events:PET_BATTLE_CLOSE()
	if (self) then
		XPerl_Raid_HideShowRaid()
	end
end

-- XPerl_Raid_Events:PLAYER_ENTERING_WORLDsmall()
--[[function XPerl_Raid_Events:PLAYER_ENTERING_WORLDsmall()
	-- Force a re-draw. Events not processed for anything that happens during
	-- the small time you zone. Some display anomolies can occur from this
	XPerl_Raid_UpdateDisplayAll()

	if (IsInInstance()) then
		ZPerl_CustomHighlight = true
		LoadAddOn("ZPerl_CustomHighlight")
	end
end]]

--[[function XPerl_Raid_Events:PLAYER_REGEN_ENABLED()
	-- Update all raid frame that would have tained
	local tainted
	if #taintFrames > 0 then
		tainted = true
	end
	for i = 1, #taintFrames do
		taintable(taintFrames[i])
	end
	taintFrames = { }
	if tainted then
		XPerl_Raid_ChangeAttributes()
		XPerl_Raid_Position()
		XPerl_Raid_Set_Bits(XPerl_Raid_Frame)
		XPerl_Raid_UpdateDisplayAll()
		if (XPerl_RaidPets_OptionActions) then
			XPerl_RaidPets_OptionActions()
		end
	end
end]]


function XPerl_Raid_Events:UNIT_CONNECTION()
	--Update players health when their connection state changes.
	XPerl_Raid_UpdateHealth(self)
end

-- PLAYER_ENTERING_WORLD
function XPerl_Raid_Events:PLAYER_ENTERING_WORLD()
	--self:UnregisterEvent("PLAYER_ENTERING_WORLD")

	--XPerl_Raid_ChangeAttributes()
	--XPerl_RaidTitles()

	XPerl_Raid_ChangeAttributes()
	XPerl_Raid_Position()
	XPerl_Raid_Set_Bits(XPerl_Raid_Frame)

	raidLoaded = true
	rosterUpdated = nil

	if (IsInRaid() or (IsInGroup() and rconf.inParty)) then
		XPerl_Raid_Frame:Show()
	end

	if not ZPerl_Custom and rconf.enable then
		LoadAddOn("ZPerl_CustomHighlight")
	end

	XPerl_Raid_UpdateDisplayAll()

	--XPerl_Raid_Events.PLAYER_ENTERING_WORLD = XPerl_Raid_Events.PLAYER_ENTERING_WORLDsmall
	--XPerl_Raid_Events.PLAYER_ENTERING_WORLDsmall = nil
end

local rosterGuids
-- XPerl_Raid_GetUnitFrameByGUID
function XPerl_Raid_GetUnitFrameByGUID(guid)
	local unitid = rosterGuids and rosterGuids[guid]
	if (unitid) then
		return FrameArray[unitid]
	end
end

local function BuildGuidMap()
	if (IsInRaid()) then
		rosterGuids = { }
		for i = 1, GetNumGroupMembers() do
			local guid = UnitGUID("raid"..i)
			if (guid) then
				rosterGuids[guid] = "raid"..i
			end
		end
	elseif (IsInGroup()) then
		rosterGuids = { }
		for i = 1, GetNumGroupMembers() do
			local guid = UnitGUID("player")
			if (guid) then
				rosterGuids[guid] = "player"
			end
			local guid = UnitGUID("party"..i - 1)
			if (guid) then
				rosterGuids[guid] = "party"..i - 1
			end
		end
	else
		rosterGuids = { }
	end
end

-- GROUP_ROSTER_UPDATE
function XPerl_Raid_Events:GROUP_ROSTER_UPDATE()
	rosterUpdated = true -- Many roster updates can occur during 1 video frame, so we'll check everything at end of last one
	BuildGuidMap()
	if (IsInRaid() or (IsInGroup() and rconf.inParty)) then
		XPerl_Raid_Frame:Show()
		if not IsVanillaClassic then
			if (rconf.raid_role) then
				for i, frame in pairs(FrameArray) do
					if (frame.partyid) then
						XPerl_Raid_RoleUpdate(self, UnitGroupRolesAssigned(self.partyid))
					end
				end
			end
		end
	end
end

-- PLAYER_LOGIN
function XPerl_Raid_Events:PLAYER_LOGIN()
	BuildGuidMap()
end

-- UNIT_FLAGS
function XPerl_Raid_Events:UNIT_FLAGS(unit, ...)
	XPerl_Raid_UpdateCombat(self)
	XPerl_Raid_UpdatePlayerFlags(self, unit, ...)
end

function XPerl_Raid_Events:PLAYER_FLAGS_CHANGED(unit, ...)
	XPerl_Raid_UpdatePlayerFlags(self, unit, ...)
end

-- UNIT_FACTION
function XPerl_Raid_Events:UNIT_FACTION()
	XPerl_Raid_UpdateCombat(self)
	XPerl_Raid_UpdateName(self)
end

-- UNIT_COMBAT
function XPerl_Raid_Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end

	if (action == "HEAL") then
		XPerl_Raid_CombatFlash(self, 0, true, true)
	elseif (damage and damage > 0) then
		XPerl_Raid_CombatFlash(self, 0, true)
	end
end

-- UNIT_HEALTH_FREQUENT
function XPerl_Raid_Events:UNIT_HEALTH_FREQUENT()
	XPerl_Raid_UpdateHealth(self)
	XPerl_Raid_UpdateCombat(self)
end

-- UNIT_HEALTH
function XPerl_Raid_Events:UNIT_HEALTH()
	XPerl_Raid_UpdateHealth(self)
	XPerl_Raid_UpdateCombat(self)
end

-- UNIT_MAXHEALTH
function XPerl_Raid_Events:UNIT_MAXHEALTH()
	XPerl_Raid_UpdateHealth(self)
	XPerl_Raid_UpdateCombat(self)
end

-- UNIT_DISPLAYPOWER
function XPerl_Raid_Events:UNIT_DISPLAYPOWER()
	XPerl_Raid_UpdateManaType(self)
	XPerl_Raid_UpdateMana(self)
end

-- UNIT_POWER_FREQUENT
function XPerl_Raid_Events:UNIT_POWER_FREQUENT()
	if (rconf.mana) then
		XPerl_Raid_UpdateMana(self)
	end
end

XPerl_Raid_Events.UNIT_MAXPOWER = XPerl_Raid_Events.UNIT_POWER_FREQUENT

-- UNIT_NAME_UPDATE
function XPerl_Raid_Events:UNIT_NAME_UPDATE()
	XPerl_Raid_UpdateName(self)
	XPerl_Raid_UpdateHealth(self) -- Added 16th May 2007 - Seems they now fire name update to indicate some change in state.
end

-- UNIT_AURA
function XPerl_Raid_Events:UNIT_AURA()
	if (not conf.highlightDebuffs.enable and not conf.highlight.enable and not rconf.buffs.enable and not rconf.debuffs.enable) then
		return
	end
	UpdateBuffs(self)
end

-- READY_CHECK
function XPerl_Raid_Events:READY_CHECK(a, b, c)
	for i, frame in pairs(FrameArray) do
		if (frame.partyid) then
			XPerl_Unit_UpdateReadyState(frame)
		end
	end
end

function XPerl_Raid_Events:INCOMING_RESURRECT_CHANGED(unit)
	for i, frame in pairs(FrameArray) do
		if (frame.partyid and unit == frame.partyid) then
			XPerl_Raid_UpdateResurrectionStatus(frame)
		end
	end
end


XPerl_Raid_Events.READY_CHECK_CONFIRM = XPerl_Raid_Events.READY_CHECK
XPerl_Raid_Events.READY_CHECK_FINISHED = XPerl_Raid_Events.READY_CHECK

-- RAID_TARGET_UPDATE
function XPerl_Raid_Events:RAID_TARGET_UPDATE()
	for i, frame in pairs(FrameArray) do
		if (frame.partyid) then
			XPerl_Raid_RaidTargetUpdate(frame)
		end
	end
end

-- ROLE_CHANGED_INFORM
-- targetUnit is the player whose role is being changed
-- sourceUnit is the player who initiated the change
-- oldRole is a role currently assigned to the player - NONE, TANK, HEALER, DAMAGER
-- newRole is a role being assigned to the player
-- UnitGroupRolesAssigned function will return the oldRole if used in this event
function XPerl_Raid_Events:ROLE_CHANGED_INFORM(targetUnit, sourceUnit, oldRole, newRole)
	local id = RaidPositions[targetUnit]
	if (rconf.role_icons) then
		if (id) then
			XPerl_Raid_RoleUpdate(FrameArray[id], newRole)
		end
	end
end

-- SetRes
local function SetResStatus(resserName, resTargetName, ignoreCounter)
	local resEnd

	if (resTargetName) then
		ResArray[resserName] = resTargetName
	else
		resEnd = true

		for i, name in pairs(ResArray) do
			if (i == resserName) then
				resTargetName = name
				break
			end
		end

		ResArray[resserName] = nil
	end

	if (resTargetName) then
		local myRoster = ZPerl_Roster[resTargetName]
		if (myRoster) then
			if (resEnd and not ignoreCounter) then
				myRoster.ressed = 1
				myRoster.resCount = (myRoster.resCount or 0) + 1
			end
			UpdateUnitByName(resTargetName, true)
		end
	end
end

-- UNIT_SPELLCAST_START
function XPerl_Raid_Events:UNIT_SPELLCAST_START(unit, lineGUID, spellID)
	local unitName, realm = UnitName(unit)
	if realm and realm ~= "" then
		unitName = unitName.."-"..realm
	end
	if (ResArray[unitName]) then
		-- Flagged as ressing, finish their old cast
		SetResStatus(unitName)
	end

	local name, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
	if (resSpells[name]) then
		local u = unit.."target"
		local unitTargetName, realm = UnitName(u)
		if realm and realm ~= "" then
			unitTargetName = unitTargetName.."-"..realm
		end
		if (UnitExists(u) and UnitIsDead(u)) then
			SetResStatus(unitName, unitTargetName)
		end
	end
end

-- UNIT_SPELLCAST_STOP
function XPerl_Raid_Events:UNIT_SPELLCAST_STOP(unit)
	if unit then
		local unitName, realm = UnitName(unit)
		if realm and realm ~= "" then
			unitName = unitName.."-"..realm
		end
		SetResStatus(unitName)
	end
end

-- UNIT_SPELLCAST_FAILED
function XPerl_Raid_Events:UNIT_SPELLCAST_FAILED(unit)
	if unit then
		local unitName, realm = UnitName(unit)
		if realm and realm ~= "" then
			unitName = unitName.."-"..realm
		end
		SetResStatus(unitName, nil, true)
	end
end

XPerl_Raid_Events.UNIT_SPELLCAST_INTERRUPTED = XPerl_Raid_Events.UNIT_SPELLCAST_FAILED


function XPerl_Raid_Events:UNIT_HEAL_PREDICTION(unit)
	if rconf.healprediction and unit == self.partyid then
		XPerl_SetExpectedHealth(self)
	end
	if not IsWrathClassic then
		return
	end
	if rconf.hotPrediction and unit == self.partyid then
		XPerl_SetExpectedHots(self)
	end
end

function XPerl_Raid_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if rconf.absorbs and unit == self.partyid then
		XPerl_SetExpectedAbsorbs(self)
	end
end

-- Direct string matches can be done via table lookup
local QuickFuncs = {
	--AFK	= function(m)	m.afk = GetTime() m.dnd = nil end,
	--UNAFK	= function(m)	m.afk = nil end,
	--DND	= function(m)	m.dnd = GetTime() m.afk = nil end,
	--UNDND	= function(m)	m.dnd = nil end,
	RESNO = function(m, n)
		SetResStatus(n)
	end,
	RESSED = function(m)
		m.ressed = 1
	end,
	CANRES = function(m)
		m.ressed = 2
	end,
	NORESSED = function(m)
		if (m.ressed) then
			m.ressed = 3
		else
			m.ressed = nil
		end
		m.resCount = nil
	end,
	SR	= XPerl_SendModules
}

-- DurabilityCheck(msg, author)
-- Quick DUR check for those people who don't have CTRA installed
-- No, I'm not going to replace either mod
local XPerl_DurabilityCheck
do
	local tip
	function XPerl_DurabilityCheck(author)
		local durPattern = gsub(DURABILITY_TEMPLATE, "(%%%d-$-d)", "(%%d+)")
		local cur, max, broken = 0, 0, 0
		if (not tip) then
			tip = CreateFrame("GameTooltip", "XPerlDurCheckTooltip")
		end

		tip:SetOwner(XPerl_Raid_Frame, "ANCHOR_RIGHT")
		tip:ClearAllPoints()
		tip:SetPoint("TOP", UIParent, "BOTTOM", -200, 0)
		for i = 1, 18 do
			if (GetInventoryItemBroken("player", i)) then
				broken = broken + 1
			end

			tip:SetInventoryItem("player", i)

			for j = 1, tip:NumLines() do
				local line = _G[tip:GetName().."TextLeft"..j]
				if (line) then
					local text = line:GetText()
					if (text) then
						local imin, imax = strmatch(text, durPattern)
						if (imin and imax) then
							imin, imax = tonumber(imin), tonumber(imax)
							cur = cur + imin
							max = max + imax
							break
						end
					end
				end
			end
		end

		tip:Hide()

		SendAddonMessage("CTRA", format("DUR %s %s %s %s", cur, max, broken, author), "RAID")
	end
end

-- XPerl_ItemCheckCount
local function XPerl_ItemCheckCount(itemName, author)
	local count = GetItemCount(itemName)
	if (count and count > 0) then
		SendAddonMessage("CTRA", "ITM "..count.." "..itemName.." "..author, "RAID")
	end
end

-- XPerl_ResistsCheck
local function XPerl_ResistsCheck(unitName)
	local str = ""
	for i = 2, 6 do
		local _, total = UnitResistance("player", i)
		str = str.." "..total
	end
	SendAddonMessage("CTRA", format("RST%s %s", str, unitName), "RAID")
end

-- ProcessCTRAMessage
local function ProcessCTRAMessage(unitName, msg)
	local myRoster = ZPerl_Roster[unitName]

	if (not myRoster) then
		return
	end

	local update = true

	local func = QuickFuncs[msg]
	if (func) then
		func(myRoster, unitName)
	else
		if (strsub(msg, 1, 4) == "RES ") then
			SetResStatus(unitName, strsub(msg, 5))
			return

		elseif (strsub(msg, 1, 3) == "CD ") then
			local num, cooldown = strmatch(msg, "^CD (%d+) (%d+)$")
			if ( num == "1" ) then
				myRoster.Rebirth = GetTime() + tonumber(cooldown) * 60
			elseif ( num == "2" ) then
				myRoster.Reincarnation = GetTime() + tonumber(cooldown) * 60
			elseif ( num == "3" ) then
				myRoster.Soulstone = GetTime() + tonumber(cooldown) * 60
			end
			update = nil
		elseif (strsub(msg, 1, 2) == "V ") then
			myRoster.version = strsub(msg, 3)
			update = nil
		elseif (msg == "DURC") then
			if (not CT_RA_VersionNumber) then
				XPerl_DurabilityCheck(unitName)
			end
		elseif (msg == "RSTC") then
			if (not CT_RA_VersionNumber) then
				XPerl_ResistsCheck(unitName)
			end
		elseif (strsub(msg, 1, 4) == "ITMC") then
			if (not CT_RA_VersionNumber) then
				local itemName = strmatch(msg, "^ITMC (.+)$")
				if (itemName) then
					XPerl_ItemCheckCount(itemName, unitName)
				end
			end
		else
			update = nil
		end
	end

	if (update) then
		UpdateUnitByName(unitName, true)
	end
end

-- XPerl_Raid_Events:CHAT_MSG_RAID
-- Check for AFK/DND flags in chat
--function XPerl_Raid_Events:CHAT_MSG_RAID()
--	local myRoster = ZPerl_Roster[arg4]
--	if (myRoster) then
--		if (arg6 == "AFK") then
--			if (not myRoster.afk) then
--				myRoster.afk = GetTime()
--				myRoster.dnd = nil
--			end
--		elseif (arg6 == "DND") then
--			if (not myRoster.dnd) then
--				myRoster.dnd = GetTime()
--				myRoster.afk = nil
--			end
--		else
--			myRoster.dnd, myRoster.afk = nil, nil
--		end
--	end
--end
--XPerl_Raid_Events.CHAT_MSG_RAID_LEADER = XPerl_Raid_Events.CHAT_MSG_RAID
--XPerl_Raid_Events.CHAT_MSG_PARTY = XPerl_Raid_Events.CHAT_MSG_RAID

-- XPerl_ParseCTRA
function XPerl_ParseCTRA(sender, msg, func)
	--local arr = new(strsplit("#", msg))
	local arr = {strsplit("#", msg)}
	for i, subMsg in pairs(arr) do
		func(sender, subMsg)
	end
	--del(arr)
end

-- CHAT_MSG_ADDON
function XPerl_Raid_Events:CHAT_MSG_ADDON(prefix, msg, channel, sender)
	if (channel == "RAID") then
		if (prefix == "CTRA") then
			XPerl_ParseCTRA(sender, msg, ProcessCTRAMessage)
		end
	end
end

-- SetRaidRoster
function SetRaidRoster()
	--local NewRoster = new()
	local NewRoster = { }

	--del(RaidPositions)
	--RaidPositions = new()
	RaidPositions = { }

	--del(RaidGroupCounts)
	--RaidGroupCounts = new(0,0,0,0,0,0,0,0,0,0,0)
	RaidGroupCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

	local player
	for i = 1, GetNumGroupMembers() do
		local name, _, group, _, class, fileName = GetRaidRosterInfo(i)

		if (name and (IsInRaid() or (IsInGroup() and rconf.inParty))) then
			local unit
			if IsInRaid() then
				unit = "raid"..i
			else
				if name == UnitName("player") then
					unit = "player"
					player = true
				else
					if player then
						unit = "party"..i - 1
					else
						unit = "party"..i
					end
				end
			end
			RaidPositions[name] = unit

			if (IsInRaid() and UnitIsUnit(unit, "player")) then
				myGroup = group
			else
				myGroup = nil
			end

			if (rconf.sortByClass) then
				for j = 1, CLASS_COUNT do
					if (rconf.class[j].name == fileName and rconf.class[j].enable) then
						RaidGroupCounts[j] = RaidGroupCounts[j] + 1
						break
					end
				end
			else
				RaidGroupCounts[group] = RaidGroupCounts[group] + 1
			end

			local r = ZPerl_Roster[name]
			if (r) then
				NewRoster[name] = r
				ZPerl_Roster[name] = nil
				r.afk = UnitIsAFK(unit) and GetTime() or nil
				r.dnd = UnitIsDND(unit) and GetTime() or nil
			else
				--NewRoster = new()
				NewRoster[name] = { }
			end
		end
	end

	if (IsInRaid() or (IsInGroup() and rconf.inParty)) then
		XPerl_Raid_Frame:Show()
	else
		XPerl_Raid_Frame:Hide()
	end

	--del(ZPerl_Roster, true)
	ZPerl_Roster = NewRoster

	if (XPerl_RaidPets_Align) then
		XPerl_ProtectedCall(XPerl_RaidPets_Align)
	end
end

-- XPerl_RaidGroupCounts()
function XPerl_RaidGroupCounts()
	return RaidGroupCounts
end

-- XPerl_Raid_Position
function XPerl_Raid_Position(self)
	SetRaidRoster()
	XPerl_RaidTitles()
	-- if (conf.party.smallRaid and fullyInitiallized) and not InCombatLockdown()) then
	if (conf.party.smallRaid and fullyInitiallized) then
		XPerl_Raid_HideShowRaid()
	end
end

--------------------
-- Click Handlers --
--------------------

-- XPerl_ScaleRaid
function XPerl_ScaleRaid()
	for frame = 1, 13 do
		local f = _G["XPerl_Raid_Title"..frame]
		if (f) then
			f:SetScale(rconf.scale)
		end
	end
end

-- XPerl_Raid_SetWidth
function XPerl_Raid_SetWidth()
	if (InCombatLockdown()) then
		XPerl_OutOfCombatQueue[XPerl_Raid_SetWidth] = true
		return
	end
	for i = 1, 13 do
		local f = _G["XPerl_Raid_Title"..i]
		if (f) then
			f:SetWidth(80 + rconf.size.width)
			f.virtual:SetWidth(80 + rconf.size.width)
		end
		for j = 1, 40 do
			local f = _G["XPerl_Raid_Grp"..i.."UnitButton"..j]
			if (f) then
				f:SetWidth(80 + rconf.size.width)
				f.nameFrame:SetWidth(80 + rconf.size.width)
				f.statsFrame:SetWidth(80 + rconf.size.width)
			end
		end
	end
end

-- XPerl_RaidTitles
function XPerl_RaidTitles()
	XPerl_Raid_SetWidth()
	local singleGroup
	if (XPerl_Party_SingleGroup) then
		if (conf.party.smallRaid and fullyInitiallized) then
			singleGroup = XPerl_Party_SingleGroup()
		end
	end

	local c
	for i = 1, CLASS_COUNT do
		local confClass = rconf.class[i].name
		local frame = _G["XPerl_Raid_Title"..i]
		local titleFrame = frame.text
		local virtualFrame = frame.virtual

		if (not rconf.sortByClass and IsInRaid() and myGroup and myGroup == i) then
			c = HIGHLIGHT_FONT_COLOR
		else
			c = NORMAL_FONT_COLOR
		end
		titleFrame:SetTextColor(c.r, c.g, c.b)

		if (rconf.sortByClass) then
			if (LOCALIZED_CLASS_NAMES_MALE[confClass]) then
				titleFrame:SetText(LOCALIZED_CLASS_NAMES_MALE[confClass])
			else
				titleFrame:SetText(localGroups[confClass])
			end
		else
			titleFrame:SetFormattedText(XPERL_RAID_GROUP, i)
		end

		local enable = rconf.enable
		if (enable) then
			local _, instanceType = IsInInstance()
			if (instanceType == "pvp") then
				enable = not rconf.notInBG
			end
		end

		if (XPerlLocked == 0 or (RaidGroupCounts[i] > 0 and enable and rconf.group[i] and not singleGroup)) then
			if (XPerlLocked == 0 or rconf.titles) then
				if rconf.enable then
					if (not titleFrame:IsShown()) then
						titleFrame:Show()
					end
				else
					titleFrame:Hide()
				end
			else
				if (titleFrame:IsShown()) then
					titleFrame:Hide()
				end
			end

			if (XPerlLocked == 0) then
				local rows = conf.sortByClass and RaidGroupCounts[i] or 5
				virtualFrame:ClearAllPoints()
				if (rconf.anchor == "TOP") then
					virtualFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
					virtualFrame:SetHeight(((rconf.mana and 1 or 0) * rows + 38) * rows + (rconf.spacing * (rows - 1)))
					virtualFrame:SetWidth(80 + rconf.size.width)
				elseif (rconf.anchor == "LEFT") then
					virtualFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
					virtualFrame:SetHeight((rconf.mana and 1 or 0) * 5 + 38)
					virtualFrame:SetWidth(80 * rows + (rconf.spacing * (rows - 1)) + rconf.size.width)
				elseif (rconf.anchor == "BOTTOM") then
					virtualFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
					virtualFrame:SetHeight(((rconf.mana and 1 or 0) * rows + 38) * rows + (rconf.spacing * (rows - 1)))
					virtualFrame:SetWidth(80 + rconf.size.width)
				elseif (rconf.anchor == "RIGHT") then
					virtualFrame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)
					virtualFrame:SetHeight((rconf.mana and 1 or 0) * 5 + 38)
					virtualFrame:SetWidth(80 * rows + (rconf.spacing * (rows - 1)) + rconf.size.width)
				end
				virtualFrame:OnBackdropLoaded()
				virtualFrame:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
				virtualFrame:SetBackdropBorderColor(conf.colour.border.r, conf.colour.border.g, conf.colour.border.b, 1)
				if rconf.group[i] then
					if rconf.enable then
						virtualFrame:Show()
					else
						virtualFrame:Hide()
					end
					--[[if rconf.titles then
						titleFrame:Show()
					else
						titleFrame:Hide()
					end]]
				else
					virtualFrame:Hide()
					titleFrame:Hide()
				end
			else
				virtualFrame:Hide()
			end
		else
			if (virtualFrame:IsShown()) then
				virtualFrame:Hide()
			end
			if (titleFrame:IsShown()) then
				titleFrame:Hide()
			end
		end
	end

	XPerl_ProtectedCall(XPerl_EnableRaidMouse)

	--[[if (XPerl_RaidPets_Align) then
		XPerl_ProtectedCall(XPerl_RaidPets_Align)
	end]]
end

-- XPerl_EnableRaidMouse()
function XPerl_EnableRaidMouse()
	for i = 1, 13 do
		local frame = _G["XPerl_Raid_Title"..i]
		if (XPerlLocked == 0) then
			frame:EnableMouse(true)
		else
			frame:EnableMouse(false)
		end
	end
end

-- XPerl_Raid_SetBuffTooltip
function XPerl_Raid_SetBuffTooltip(self)
	if (conf.tooltip.enableBuffs and XPerl_TooltipModiferPressed(true)) then
		if (not conf.tooltip.hideInCombat or not InCombatLockdown()) then
			local parentUnit = self:GetParent():GetParent()
			local partyid = SecureButton_GetUnit(parentUnit)
			if (not partyid) then
				return
			end

			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 30, 0)

			local show, cureCast = GetShowCast(parentUnit)
			if (parentUnit.debuffsForced) then
				show = "d"
			end
			if (show == "b") then
				XPerl_TooltipSetUnitBuff(GameTooltip, partyid, self:GetID(), cureCast, true)
			elseif (show == "d") then
				XPerl_TooltipSetUnitDebuff(GameTooltip, partyid, self:GetID(), cureCast, true)
			end
		end
	end
end

------- XPerl_ToggleRaidBuffs -------
-- Raid Buff Key Binding function --
function XPerl_ToggleRaidBuffs(castable)
	if (castable) then
		if (rconf.buffs.castable == 1) then
			rconf.buffs.castable = 0
			XPerl_Notice(XPERL_KEY_NOTICE_RAID_BUFFANY)
		else
			rconf.buffs.castable = 1
			XPerl_Notice(XPERL_KEY_NOTICE_RAID_BUFFCURECAST)
		end
	else
		if (rconf.buffs.enable) then
			rconf.buffs.enable = nil
			rconf.debuffs.enable = 1
			XPerl_Notice(XPERL_KEY_NOTICE_RAID_DEBUFFS)

		elseif (rconf.debuffs.enable) then
			rconf.buffs.enable = nil
			rconf.debuffs.enable = nil
			XPerl_Notice(XPERL_KEY_NOTICE_RAID_NOBUFFS)
		else
			rconf.buffs.enable = 1
			rconf.debuffs.enable = nil
			XPerl_Notice(XPERL_KEY_NOTICE_RAID_BUFFS)
		end
	end

	for k, v in pairs(FrameArray) do
		if (v:IsShown()) then
			XPerl_Raid_UpdateDisplay(v)
		end
	end
end

-- XPerl_ToggleRaidSort
function XPerl_ToggleRaidSort(New)
	if (not XPerl_Options or not XPerl_Options:IsShown()) then
		if (not InCombatLockdown()) then
			if (New) then
				conf.sortByClass = New == 1
			else
				if (conf.sortByClass) then
					conf.sortByClass = nil
				else
					conf.sortByClass = 1
				end
			end
			XPerl_Raid_ChangeAttributes()
			XPerl_Raid_Position()
			XPerl_Raid_Set_Bits(XPerl_Raid_Frame)
			XPerl_Raid_UpdateDisplayAll()
			if (XPerl_RaidPets_OptionActions) then
				XPerl_RaidPets_OptionActions()
			end
		end
	end
end

-- GetCombatRezzerList()
local normalRezzers = {
	PRIEST = true,
	SHAMAN = true,
	PALADIN = true,
	MONK = true
}

local function SortCooldown(a, b)
	return a.cd < b.cd
end

local function GetCombatRezzerList()
	local anyCombat = 0
	local anyAlive = 0
	for i = 1, GetNumGroupMembers() do
		local unit = "raid"..i
		local _, class = UnitClass(unit)
		if (normalRezzers[class]) then
			if (UnitAffectingCombat(unit)) then
				anyCombat = anyCombat + 1
			end
			if (not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit)) then
				anyAlive = anyAlive + 1
			end
		end
	end

	-- We only need to know about battle rezzers if any normal rezzers are in combat
	if (anyCombat > 0 or anyAlive < 3) then
		local ret = { }
		local t = GetTime()

		for i = 1, GetNumGroupMembers() do
			local raidid = "raid"..i
			if (not UnitIsDeadOrGhost(raidid) and UnitIsVisible(raidid)) then
				local name, _, _, _, _, fileName = GetRaidRosterInfo(i)

				local good
				if (not UnitAffectingCombat(raidid)) then
					if (fileName == "PRIEST" or fileName == "SHAMAN" or fileName == "PALADIN" or fileName == "MONK") then
						tinsert(ret, {["name"] = name, class = fileName, cd = 0})
					end
				else
					if (fileName == "DRUID") then
						local myRoster = ZPerl_Roster[name]

						if (myRoster) then
							if (myRoster.Rebirth and myRoster.Rebirth - t <= 0) then
								myRoster.Rebirth = nil -- Check for expired cooldown
							end
							if (myRoster.Rebirth) then
								if (myRoster.Rebirth - t < 120) then
									tinsert(ret, {["name"] = name, class = fileName, cd = myRoster.Rebirth - t})
								end
							else
								tinsert(ret, {["name"] = name, class = fileName, cd = 0})
							end
						end
					end
				end
			end
		end

		if (#ret > 0) then
			sort(ret, SortCooldown)

			local list = ""
			for k,v in ipairs(ret) do
				local name = XPerlColourTable[v.class]..v.name.."|r"

				if (v.cd > 0) then
					name = name.." (in "..SecondsToTime(v.cd)..")"
				end

				if (list == "") then
					list = name
				else
					list = list..", "..name
				end
			end
			--del(ret)
			return list
		else
			--del(ret)
			return "|c00FF0000"..NONE.."|r"
		end
	end

	if (anyAlive == 0) then
		return "|c00FF0000"..NONE.."|r"
	elseif (anyCombat == 0) then
		return "|c00FFFFFF"..ALL.."|r"
	end
end

-- XPerl_RaidTipExtra
function XPerl_RaidTipExtra(unitid)
	if (UnitInRaid(unitid)) then
		local unitName, realm = UnitName(unitid)
		if realm and realm ~= "" then
			unitName = unitName.."-"..realm
		end

		for i = 1, GetNumGroupMembers() do
			local name = GetRaidRosterInfo(i)
			if (name == unitName) then
				break
			end
		end

		local stats = ZPerl_Roster[unitName]
		if (stats) then
			local t = GetTime()

			if (stats.version) then
				GameTooltip:AddLine("CTRA "..stats.version, 1, 1, 1)
			end

			if (stats.offline and UnitIsConnected(unitid)) then
				stats.offline = nil
			end
			if (stats.afk and not UnitIsAFK(unitid)) then
				stats.afk = nil
			end
			if (stats.dnd and not UnitIsDND(unitid)) then
				stats.dnd = nil
			end

			if (stats.offline) then
				GameTooltip:AddLine(format(XPERL_RAID_TOOLTIP_OFFLINE, SecondsToTime(t - stats.offline)))

			elseif (stats.afk) then
				GameTooltip:AddLine(format(XPERL_RAID_TOOLTIP_AFK, SecondsToTime(t - stats.afk)))

			elseif (stats.dnd) then
				GameTooltip:AddLine(format(XPERL_RAID_TOOLTIP_DND, SecondsToTime(t - stats.dnd)))

			elseif (stats.fd) then
				if (not UnitIsDead(unitid)) then
					stats.fd = nil
				else
					local x = stats.fd + 360 - t
					if (x > 0) then
						GameTooltip:AddLine(format(XPERL_RAID_TOOLTIP_DYING, SecondsToTime(x)))
					end
				end
			end

			if (stats.Rebirth) then
				if (stats.Rebirth - t > 0) then
					GameTooltip:AddLine(format(XPERL_RAID_TOOLTIP_REBIRTH, SecondsToTime(stats.Rebirth - t)))
				else
					stats.Rebirth = nil
				end

			elseif (stats.Reincarnation) then
				if (stats.Reincarnation - t > 0) then
					GameTooltip:AddLine(format(XPERL_RAID_TOOLTIP_ANKH, SecondsToTime(stats.Reincarnation - t)))
				else
					stats.Reincarnation = nil
				end

			elseif (stats.Soulstone) then
				if (stats.Soulstone - t > 0) then
					GameTooltip:AddLine(format(XPERL_RAID_TOOLTIP_SOULSTONE, SecondsToTime(stats.Soulstone - t)))
				else
					stats.Soulstone = nil
				end
			end

			if (UnitIsDeadOrGhost(unitid) --[[and not UnitBuff(unitid, feignDeath)--]]) then
				if (stats.resCount) then
					GameTooltip:AddLine(XPERL_LOC_RESURRECTED.." x"..stats.resCount)
				end

				local Rezzers = GetCombatRezzerList()
				if (Rezzers) then
					GameTooltip:AddLine(XPERL_RAID_RESSER_AVAIL..Rezzers, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
				end
			end
		end

		GameTooltip:Show()
	end
end

-- SetMainHeaderAttributes
local function SetMainHeaderAttributes(self)
	self:Hide()

	if (rconf.sortAlpha) then
		self:SetAttribute("sortMethod", "NAME")
	else
		self:SetAttribute("sortMethod", nil)
	end

	self:SetAttribute("showParty", rconf.inParty)
	self:SetAttribute("showPlayer", rconf.inParty)
	self:SetAttribute("showRaid", true)

	if rconf.anchor ~= "BOTTOM" then
		self:SetAttribute("point", rconf.anchor)
	end
	self:SetAttribute("minWidth", 80)
	self:SetAttribute("minHeight", 10)
	local titleFrame = self:GetParent()
	self:ClearAllPoints()
	if (rconf.anchor == "TOP") then
		self:SetPoint("TOP", titleFrame, "BOTTOM", 0, 0)
		self:SetAttribute("xOffset", 0)
		self:SetAttribute("yOffset", -rconf.spacing)
	elseif (rconf.anchor == "LEFT") then
		self:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, 0)
		self:SetAttribute("xOffset", rconf.spacing)
		self:SetAttribute("yOffset", 0)
	elseif (rconf.anchor == "BOTTOM") then
		self:SetPoint("BOTTOM", titleFrame, "TOP", 0, 0)
		self:SetAttribute("xOffset", 0)
		self:SetAttribute("yOffset", rconf.spacing)
	elseif (rconf.anchor == "RIGHT") then
		self:SetPoint("TOPRIGHT", titleFrame, "BOTTOMRIGHT", 0, 0)
		self:SetAttribute("xOffset", -rconf.spacing)
		self:SetAttribute("yOffset", 0)
	end
end

local function DefaultRaidClasses()
	if IsRetail then
		return {
			{enable = true, name = "WARRIOR"},
			{enable = true, name = "DEATHKNIGHT"},
			{enable = true, name = "ROGUE"},
			{enable = true, name = "HUNTER"},
			{enable = true, name = "MAGE"},
			{enable = true, name = "WARLOCK"},
			{enable = true, name = "PRIEST"},
			{enable = true, name = "DRUID"},
			{enable = true, name = "SHAMAN"},
			{enable = true, name = "PALADIN"},
			{enable = true, name = "MONK"},
			{enable = true, name = "DEMONHUNTER"},
			{enable = true, name = "EVOKER"}
		}
	elseif IsWrathClassic then
		return {
			{enable = true, name = "WARRIOR"},
			{enable = true, name = "DEATHKNIGHT"},
			{enable = true, name = "ROGUE"},
			{enable = true, name = "HUNTER"},
			{enable = true, name = "MAGE"},
			{enable = true, name = "WARLOCK"},
			{enable = true, name = "PRIEST"},
			{enable = true, name = "DRUID"},
			{enable = true, name = "SHAMAN"},
			{enable = true, name = "PALADIN"},
		}
	else
		return {
			{enable = true, name = "WARRIOR"},
			{enable = true, name = "ROGUE"},
			{enable = true, name = "HUNTER"},
			{enable = true, name = "MAGE"},
			{enable = true, name = "WARLOCK"},
			{enable = true, name = "PRIEST"},
			{enable = true, name = "DRUID"},
			{enable = true, name = "SHAMAN"},
			{enable = true, name = "PALADIN"},
		}
	end
end

local function GroupFilter(n)
	if (rconf.sortByClass) then
		if (not rconf.class[n]) then
			rconf.class = DefaultRaidClasses()
		end
		if (rconf.class[n].enable) then
			return rconf.class[n].name
		end
		return ""
	else
		local f
		if (rconf.group[n]) then
			f = tostring(n)
		end

		local invalid
		for i = 1, CLASS_COUNT do
			if (not rconf.class[i]) then
				invalid = true
			end
		end
		if (invalid) then
			rconf.class = DefaultRaidClasses()
		end

		for i = 1, CLASS_COUNT do
			if (rconf.class[i].enable) then
				if (not f) then
					f = rconf.class[i].name
				else
					f = f..","..rconf.class[i].name
				end
			end
		end
		return f
	end
end

-- XPerl_Raid_SetAttributes
function XPerl_Raid_ChangeAttributes()
	if (InCombatLockdown()) then
		XPerl_OutOfCombatQueue[XPerl_Raid_ChangeAttributes] = true
		return
	end

	rconf.anchor = (rconf and rconf.anchor) or "TOP"

	for i = 1, rconf.sortByClass and CLASS_COUNT or (IsVanillaClassic and 9 or (IsWrathClassic and 10 or 13)) do
		local groupHeader = raidHeaders[i]

		-- Hide this when we change attributes, so the whole re-calc is only done once, instead of for every attribute change
		groupHeader:Hide()

		if rconf.sortByRole then
			groupHeader:SetAttribute("groupBy", "ASSIGNEDROLE")
			groupHeader:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
			groupHeader:SetAttribute("startingIndex", (i - 1) * 5 + 1)
			groupHeader:SetAttribute("unitsPerColumn", 5)
			groupHeader:SetAttribute("strictFiltering", nil)
			groupHeader:SetAttribute("groupFilter", nil)
			--groupHeader:SetAttribute("useparent-toggleForVehicle", true)
			--groupHeader:SetAttribute("useparent-allowVehicleTarget", true)
			--groupHeader:SetAttribute("useparent-unitsuffix", true)
			--groupHeader:SetAttribute("toggleForVehicle", true)
			--groupHeader:SetAttribute("allowVehicleTarget", true)
		else
			groupHeader:SetAttribute("strictFiltering", not rconf.sortByClass)
			groupHeader:SetAttribute("groupFilter", GroupFilter(i))
			groupHeader:SetAttribute("groupBy", nil)
			groupHeader:SetAttribute("groupingOrder", nil)
			groupHeader:SetAttribute("startingIndex", 1)
			groupHeader:SetAttribute("unitsPerColumn", nil)
			--groupHeader:SetAttribute("useparent-toggleForVehicle", true)
			--groupHeader:SetAttribute("useparent-allowVehicleTarget", true)
			--groupHeader:SetAttribute("useparent-unitsuffix", true)
			--groupHeader:SetAttribute("toggleForVehicle", true)
			--groupHeader:SetAttribute("allowVehicleTarget", true)
		end

		-- Fix Secure Header taint in combat
		local maxColumns = groupHeader:GetAttribute("maxColumns") or 1
		local unitsPerColumn = groupHeader:GetAttribute("unitsPerColumn") or 5
		local startingIndex = groupHeader:GetAttribute("startingIndex") or 1
		local maxUnits = maxColumns * unitsPerColumn

		groupHeader:Show()
		groupHeader:SetAttribute("startingIndex", - maxUnits + 1)
		groupHeader:SetAttribute("startingIndex", startingIndex)

		SetMainHeaderAttributes(groupHeader)
	end

	XPerl_Raid_HideShowRaid()
end



-- XPerl_Raid_Set_Bits
function XPerl_Raid_Set_Bits(self)
	if (InCombatLockdown()) then
		XPerl_OutOfCombatQueue[XPerl_Raid_Set_Bits] = self
		return
	end
	if (raidLoaded) then
		XPerl_ProtectedCall(XPerl_Raid_HideShowRaid)
	end

	SkipHighlightUpdate = nil

	XPerl_ScaleRaid()
	XPerl_Raid_SetWidth()

	for i = 1, 13 do
		XPerl_SavePosition(_G["XPerl_Raid_Title"..i], true)
	end

	for i, frame in pairs(FrameArray) do
		Setup1RaidFrame(frame)
	end

	local manaEvents = {"UNIT_DISPLAYPOWER", "UNIT_POWER_FREQUENT", "UNIT_MAXPOWER"}
	for i, event in pairs(manaEvents) do
		if (rconf.mana) then
			self:RegisterEvent(event)
		else
			self:UnregisterEvent(event)
		end
	end

	SkipHighlightUpdate = nil

	XPerl_Register_Prediction(self, rconf, function(guid)
		local frame = XPerl_Raid_GetUnitFrameByGUID(guid)
		if frame then
			return frame.partyid
		end
	end)

	if (IsInRaid() or (IsInGroup() and rconf.inParty)) then
		XPerl_Raid_Frame:Show()
	end
end
