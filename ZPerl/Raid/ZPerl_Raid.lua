-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local Events = { } -- unit events, one set per frame (element Raid)
local Bus = { } -- events no frame owns (ZPerl.On)
ZPerl.Elements.Raid = {events = Events}
local allFrames = { } -- every raid frame, in creation order
local RaidGroupCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local FrameArray = { }		-- List of raid frames indexed by raid ID
local RaidPositions = { }	-- Back-matching of unit names to raid ID
-- State and functions shared with ZPerl_RaidEvents.lua and ZPerl_RaidLayout.lua, loaded after this file
local Shared = {Events = Events, Bus = Bus, allFrames = allFrames, RaidGroupCounts = RaidGroupCounts, FrameArray = FrameArray, RaidPositions = RaidPositions, ResArray = { }, CLASS_COUNT = 0}
ZPerl.Raid.Shared = Shared
--local buffUpdates = { }		-- Queue for buff updates after a roster change
local percD = "%d"..PERCENT_SYMBOL
local perc1F = "%.1f"..PERCENT_SYMBOL

local conf, rconf
ZPerl.RequestConfig(function(newConf)
	conf = newConf
	rconf = conf.raid
	for _, f in ipairs(allFrames) do
		f.conf = rconf
	end
end, "$Revision:  $")

--[===[@debug@
local function d(...)
	ChatFrame1:AddMessage(format(...))
end
--@end-debug@]===]

--local new, del, copy = ZPerl.GetReusableTable, ZPerl.FreeTable, ZPerl.CopyTable

-- Upvalues
local _G = _G

local pairs = pairs
local tinsert = tinsert
local type = type

local GetTime = GetTime
local SecureButton_GetUnit = SecureButton_GetUnit
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHealthPercent = UnitHealthPercent
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGhost = UnitIsGhost
local UnitName = UnitName

local CurveConstants = CurveConstants
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE

local ColorFriendlyUnit = ZPerl.ColorFriendlyUnit
local ColorHealthBar = ZPerl.ColorHealthBar

-- secret value helpers from ZPerl.lua
local CanAccess = ZPerl.CanAccess

-- RaidUnitName(unit) - "Name-Realm" for a raid unit, nil while the name is secret
local function RaidUnitName(unit)
	local name, realm = UnitName(unit)
	if (not CanAccess(name)) then
		return nil
	end
	---@diagnostic disable-next-line: secret-comparison
	if (realm and CanAccess(realm) and realm ~= "") then
		name = name.."-"..realm
	end
	return name
end
local GetPowerPercent = ZPerl.GetPowerPercent
local SafeBool = ZPerl.SafeBool

--local feignDeath = (C_Spell and C_Spell.GetSpellInfo(5384)) and C_Spell.GetSpellInfo(5384).name or GetSpellInfo(5384)
--local spiritOfRedemption = (C_Spell and C_Spell.GetSpellInfo(27827)) and C_Spell.GetSpellInfo(27827).name or GetSpellInfo(27827)


-- TODO - Watch for:	 ERR_FRIEND_OFFLINE_S = "%s has gone offline."

---@diagnostic disable-next-line: create-global
ZPERL_RAIDGRP_PREFIX = "ZPerl_Raid_Grp"

-- Hold some raid roster information (AFK, DND etc.)
-- Is also stored between sessions to maintain timers and flags
ZPerlRoster = { }

-- Uses some variables from FrameXML\RaidFrame.lua:
-- MAX_RAID_MEMBERS = 40
-- NUM_RAID_GROUPS = 8
-- MEMBERS_PER_RAID_GROUP = 5

for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	if k ~= "Adventurer" and k ~= "TRAVELER" then
		Shared.CLASS_COUNT = Shared.CLASS_COUNT + 1
	end
end



----------------------
-- Loading Function --
----------------------

local raidHeaders = { }
Shared.raidHeaders = raidHeaders

-- ZPerl.Raid.OnLoad
function ZPerl.Raid.OnLoad(self)
	for event, fn in pairs(Bus) do
		ZPerl.On(event, fn)
	end

	for i = 1, Shared.CLASS_COUNT do
		--_G["ZPerl_Raid_Grp"..i]:UnregisterEvent("UNIT_NAME_UPDATE")
		tinsert(raidHeaders, _G[ZPERL_RAIDGRP_PREFIX..i])
	end

	self.Array = { }

	-- the header attributes (group filter, sort, anchor, spacing) are set at PLAYER_ENTERING_WORLD and by the options window,
	-- not by ZPerl.OptionActions: an applier of the settings panel only
	ZPerl.RegisterApplier("raidheaders", ZPerl.Raid.ChangeAttributes)
	ZPerl.RegisterApplier("raidgap", function() ZPerl.Raid.SetGap(rconf.gap) end)
	-- the gap spaces groups by their width, so a width change re-runs it (as the old window did)
	ZPerl.RegisterApplier("raidwidth", function() ZPerl.Raid.SetWidth() ZPerl.Raid.SetGap(rconf.gap or 0) end)

	ZPerl.RegisterOptionChanger(function()
		if (Shared.raidLoaded) then
			ZPerl.Raid.RaidTitles()
		end

		ZPerl.Raid.SetBits(ZPerl_Raid_Frame)

		if (Shared.raidLoaded) then
			Shared.SkipHighlightUpdate = true
			ZPerl.Raid.UpdateDisplayAll()
			Shared.SkipHighlightUpdate = nil
		end
	end, nil, "raid")

	ZPerl.Raid.OnLoad = nil
end

-- ZPerl.Raid.HeaderOnLoad
function ZPerl.Raid.HeaderOnLoad(self)
	self:RegisterForDrag("LeftButton")
	self.text = _G[self:GetName().."TitleText"]
	self.virtual = _G[self:GetName().."Virtual"]
	ZPerl.RegisterUnitText(self.text)
end

-- ApplyHeight: protected; reads the config when it runs
local function ApplyHeight(self)
	self:SetHeight(rconf.mana and 43 or 38)
end

-- Setup1RaidFrame
local function Setup1RaidFrame(self)
	ZPerl.AfterCombatFor(ApplyHeight, self)
	if (rconf.mana) then
		self.statsFrame:SetHeight(26)
		self.statsFrame.manaBar:Show()
	else
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
	ZPerl.UnitFrameSetUnit(self, value)

	if (value) then
		FrameArray[value] = self
	end
end

-- UpdateName
local function UpdateName(self)
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
		-- full "First Last" (or "First-Realm") display name;
		-- lastGUID/lastID above are what onAttrChanged-style comparisons use
		self.nameFrame.text:SetText(ZPerl.UnitFullName(partyid))

		if (self.pet) then
			local color = conf.color.reaction.none
			self.nameFrame.text:SetTextColor(color.r, color.g, color.b)
		else
			ColorFriendlyUnit(self.nameFrame.text, partyid)
		end
	end
end

-- CheckFlags
-- Returns one reused table: the callers (ShowFlags) read it at once and keep nothing, and this runs on
-- every UNIT_HEALTH of a raid member, so a table per call is avoided.
local flagBlue, flagGreen = {r = 0, g = 0.5, b = 1}, {r = 0, g = 1, b = 0.5}
local flagOut = {}
local function setFlag(text, bgcolor)
	flagOut.flag, flagOut.bgcolor = text, bgcolor
	return flagOut
end

local function CheckFlags(partyid)
	local unitName = RaidUnitName(partyid)
	local resser

	for i, name in pairs(Shared.ResArray) do
		if (name == unitName) then
			resser = i
			break
		end
	end

	if (resser) then
		-- Verify they're dead..
		if (UnitIsDeadOrGhost(partyid)) then
			return setFlag(resser..L["RAID_RESSING"], flagBlue)
		end

		Shared.ResArray[resser] = nil
	end

	---@diagnostic disable-next-line: secret-table-key
	local unitInfo = ZPerlRoster[unitName]
	if (unitInfo and unitInfo.ressed) then
		if (UnitIsDead(partyid)) then
			if (unitInfo.ressed == 2) then
				return setFlag(L["LOC_SS_AVAILABLE"], flagGreen)
			elseif (unitInfo.ressed == 3) then
				return setFlag(L["LOC_ACCEPTEDRES"], flagBlue)
			else
				return setFlag(L["LOC_RESURRECTED"], flagBlue)
			end
		else
			unitInfo.ressed = nil
			ZPerl.Raid.UpdateManaType(FrameArray[partyid], true)
		end
	elseif (unitInfo and unitInfo.afk) then
		-- AFK status can be secret for any unit, not just
		-- indirect ones (confirmed: Player/
		-- Target/Party's own UnitIsAFK calls).
		if (SafeBool(UnitIsAFK(partyid), false)) then
			if (conf.showAFK) then
				return setFlag(L["RAID_AFK"])
			end
		else
			unitInfo.afk = nil
		end
	else
		if (SafeBool(UnitIsAFK(partyid), false)) then
			if (conf.showAFK) then
				return setFlag(L["RAID_AFK"])
			end
		end
	end
end

-- ZPerl.Raid.UpdateManaType
function ZPerl.Raid.UpdateManaType(self, skipFlags)
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
			flags = CheckFlags(partyid)
		end
		if (not flags) then
			ZPerl.SetManaBarType(self)
		end
	end
end

-- ShowFlags
local function ShowFlags(self, flags)
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

-- UpdateAbsorbPrediction
local function UpdateAbsorbPrediction(self)
	if rconf.absorbs then
		ZPerl.SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

-- UpdateHealPrediction
local function UpdateHealPrediction(self)
	if rconf.healprediction then
		ZPerl.SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

local function UpdateResurrectionStatus(self)
	if (UnitHasIncomingResurrection(self.partyid)) then
		self.statsFrame.resurrect:Show()
	else
		self.statsFrame.resurrect:Hide()
	end
end

-- UpdateHealthText: the one text of the bar shows the deficit, the values or the percent
local function UpdateHealthText(self, partyid, health, healthmax, missing)
	local fs = self.statsFrame.healthBar.text
	-- the two %d texts stay: one format for plain and secret values; the formatters would print -0 as 0
	if (rconf.healerMode.enable) then
		fs:SetFormattedText("-%d", missing)
	elseif (rconf.values) then
		fs:SetFormattedText("%d/%d", health, healthmax)
	else
		ZPerl.FormatPercent(fs, UnitHealthPercent(partyid, true, CurveConstants.ScaleTo100), rconf.precisionPercent)
	end
end


-- UpdateHealth
local function UpdateHealth(self)
	local partyid = self.partyid
	if (not partyid) then
		return
	end

	local health, healthmax, missing = ZPerl.HealthUpdateBar(self)

	if (not rconf.percent) then
		if (self.statsFrame.healthBar.text:IsShown()) then
			self.statsFrame.healthBar.text:Hide()
		end
	end

	UpdateAbsorbPrediction(self)
	UpdateHealPrediction(self)
	UpdateResurrectionStatus(self)

	local name = RaidUnitName(partyid)
	---@diagnostic disable-next-line: secret-table-key
	local myRoster = name and ZPerlRoster[name]
	if (UnitExists(partyid) and UnitIsConnected(partyid)) then
		--self.disco = nil
		local flags = CheckFlags(partyid)
		if (flags) then
			ShowFlags(self, flags)

			if (UnitIsDeadOrGhost(partyid)) then
				self.dead = true
				UpdateName(self)
			end
			return
		elseif (UnitIsDead(partyid)) then
			self.dead = true
			ShowFlags(self, L["LOC_DEAD"])
			UpdateName(self)
		elseif (UnitIsGhost(partyid)) then
			self.dead = true
			ShowFlags(self, L["LOC_GHOST"])
			UpdateName(self)
		else
			if (self.dead or (myRoster and (myRoster.ressed))) then
				ZPerl.Raid.UpdateManaType(self, true)
			end
			self.dead = nil

			ColorHealthBar(self, partyid)
			UpdateHealthText(self, partyid, health, healthmax, missing)

			if (self.statsFrame.greyMana) then
				self.statsFrame.greyMana = nil
				if (myRoster) then
					myRoster.resCount = nil
					myRoster.ressed = nil
				end
				ZPerl.Raid.UpdateManaType(self, true)
			end
		end
	else
		--self.disco = true
		self.dead = nil
		ShowFlags(self, L["LOC_OFFLINE"])

		if (name and myRoster and not myRoster.offline) then
			myRoster.offline = GetTime()
			myRoster.afk = nil
			myRoster.dnd = nil
		end
	end
end

-- UpdateMana
local function UpdateMana(self)
	if (rconf.mana) then
		local partyid = self.partyid
		if (not partyid) then
			return
		end

		local pType = ZPerl.GetDisplayedPowerType(partyid)
		local mana, manamax = ZPerl.PowerSetBar(self.statsFrame.manaBar, partyid, pType)

		if (rconf.manaPercent and pType == 0 and not self.pet) then
			if (rconf.values) then -- TODO rconf.manavalues
				self.statsFrame.manaBar.text:SetFormattedText("%d/%d", mana, manamax)
			else
				-- percent from the client (UnitPower is always secret)
				local pmanaPct100 = GetPowerPercent(partyid, pType)

				if rconf.precisionManaPercent then
					self.statsFrame.manaBar.text:SetFormattedText(perc1F, pmanaPct100)
				else
					self.statsFrame.manaBar.text:SetFormattedText(percD, pmanaPct100)
				end
			end
		else
			self.statsFrame.manaBar.text:SetText("")
		end
	end
end

-- onAttrChanged
-- Rebuild hides the containers it reconfigures; Update shows them, without waiting for a UNIT_AURA
local function rebuildAuras(frame)
	ZPerl.AurasRebuild(frame)
	ZPerl.AurasUpdate(frame)
end

local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value) then
			SetFrameArray(self, value)
			-- Update only: a unit change leaves the options as they were. Update builds the containers
			-- when there are none or one is pending, and showContainer moves a built one to the new unit.
			ZPerl.AurasUpdate(self)
			local guid = UnitGUID(value)
			if (self.lastID ~= value or not CanAccess(guid) or self.lastGUID ~= guid) then
				ZPerl.Raid.UpdateDisplay(self)
			end
		else
			--buffUpdates[self] = nil
			SetFrameArray(self)
			-- an option change while unitless skips this frame: rebuild when it gets a unit again
			self.auraContainerPending = self.buffContainer and true or nil
			self.lastID = nil
			self.lastGUID = nil
		end
	end
end

-- ZPerl.Raid.SingleOnLoad
function ZPerl.Raid.SingleOnLoad(self)
	Shared.widthStale = true
	ZPerl.SetChildMembers(self)
	tinsert(allFrames, self)
	Shared.EnableEvents(self)

	self.edgeFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_ThinEdge"
	self.edgeSize = 10
	self.edgeInsets = 2

	ZPerl.RegisterHighlight(self.highlight, 2)

	ZPerl.RegisterPerlFrames(self, {self.nameFrame, self.statsFrame})
	self.FlashFrames = {self.nameFrame, self.statsFrame}

	self:SetScript("OnAttributeChanged", onAttrChanged)

	ZPerl.RegisterClickCastFrame(self)
	ZPerl.RegisterClickCastFrame(self.nameFrame)

	Setup1RaidFrame(self)

	self:RegisterForClicks("AnyUp")
	self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
end

-- The functions of this file that ZPerl_RaidEvents.lua and ZPerl_RaidLayout.lua call
Shared.UpdateName = UpdateName
Shared.CheckFlags = CheckFlags
Shared.ShowFlags = ShowFlags
Shared.UpdateResurrectionStatus = UpdateResurrectionStatus
Shared.UpdateHealth = UpdateHealth
Shared.UpdateMana = UpdateMana
Shared.rebuildAuras = rebuildAuras
Shared.Setup1RaidFrame = Setup1RaidFrame
Shared.RaidUnitName = RaidUnitName
