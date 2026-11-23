-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

ZPerl.SetModuleRevision("$Revision:  $")

ZPerlRaidHelperTanks = {}
local MainTankCount, blizzMTanks, ctraTanks = 0, 0, 0
local MainTanks = {}
local BlizzardMainTanks = {}
local Events = {}
local XUnits = {}
local UpdateTime = 0
local XGaps = 0
local pendingTankListChange -- If in combat when tank list changes, then we'll defer it till next time we're out of combat
local conf

local GetNumGroupMembers = GetNumGroupMembers

--local new, del = ZPerl.GetReusableTable, ZPerl.FreeTable

-- Dup colors used to show which tanks have the same target
local MTdupColors = {
	{r = "0.8", g = "0.2", b = "0.2"},
	{r = "0.2", g = "0.2", b = "0.8"},
	{r = "0.8", g = "0.2", b = "0.8"},
	{r = "0.2", g = "0.8", b = "0.2"},
	{r = "0.2", g = "0.8", b = "0.8"}
}

local GAP_SPACING = 10
---@diagnostic disable: create-global
ZPERL_UNIT_HEIGHT_MIN = 17
ZPERL_UNIT_HEIGHT_MAX = 30
ZPERL_UNIT_WIDTH_MIN = 50
ZPERL_UNIT_WIDTH_MAX = 125
---@diagnostic enable: create-global

if (not ZPerl.ColorTable) then
	ZPerl.ColorTable = setmetatable({},{
		__index = function(self, class)
			local c = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or {r = 0, g = 0, b = 0}
			return format("|c00%02X%02X%02X", 255 * c.r, 255 * c.g, 255 * c.b)
		end
	})
end

-- Although your own "target" is updated immediately, any reference to ourself via our raid id is updated via the server
-- So, to cure the slow response times, we check if anything is 'me'. Only direct targets are updated immedately,
-- so we don't bother with target's target onwards.
local function SpecialCaseUnit(self)
	local id
	if (self.type == "MTT") then
		id = self:GetParent():GetAttribute("unit") -- SecureButton_GetUnit(self:GetParent())
		if (id) then
			if (ZPerl.SafeBool(UnitIsUnit("player", id), false)) then
				return "target"
			end
			return id.."target"
		end

	elseif (self.type == "MT") then
		id = self:GetAttribute("unit") -- SecureButton_GetUnit(self)
		if (id and ZPerl.SafeBool(UnitIsUnit("player", id), false)) then
			return "player"
		end
		return id
	end

	return SecureButton_GetUnit(self)
end

----------------------------
------- DISPLAY ------------
----------------------------
local function UpdateUnit(self,forcedUpdate)
	if (not self or self.hidden) then
		return
	end

	if (forcedUpdate) then
		local time = GetTime()
		if (self.update and time < self.update + 0.2) then
			-- Since we catch UNIT_HEALTH changes, we don't need to update always
			return
		end
	end

	self.update = GetTime()

	local xunit = SpecialCaseUnit(self)
	if (not xunit) then
		return
	end

	local name = UnitName(xunit)
	local grey
	-- Creature names and health are secret inside instances
	local nameReadable = ZPerl.CanAccess(name)

	self.healthBar.bg:Show()

	---@diagnostic disable-next-line: secret-comparison
	if (name and (not nameReadable or name ~= UNKNOWNOBJECT)) then
		-- Name
		self.text:SetText(name)
		self.text:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -12)

		if (nameReadable) then
			local remCount = 1
			while (string.len(name) > remCount) do
				-- GetStringWidth() can be secret even for plain text; leave the name untrimmed then
				local width = self.text:GetStringWidth()
				if (ZPerl.IsSecret(width) or width < self:GetWidth() - 2) then
					break
				end
				name = string.sub(name, 1, string.len(name) - remCount)..".."
				remCount = 3
				self.text:SetText(name)
			end
		end

		if (UnitPlayerControlled(xunit)) then
			ZPerl.ColorFriendlyUnit(self.text, xunit)
		else
			ZPerl.SetUnitNameColor(self.text, xunit)
		end

		-- Health
		local _, healthMax, missing = ZPerl.HealthSetBar(self.healthBar, xunit, true)
		---@diagnostic disable-next-line: secret-comparison
		if (ZPerl.CanAccess(healthMax) and healthMax == 0) then
			grey = true
		end

		if (UnitIsDeadOrGhost(xunit)) then
			self.healthBar.text:SetText(L["LOC_DEAD"])
			grey = true
		elseif (not ZPerl.SafeBool(UnitIsConnected(xunit), true)) then
			self.healthBar.text:SetText(L["LOC_OFFLINE"])
			grey = true
		else
			if (conf.HealerMode == 1 and ZPerl.SafeBool(UnitInRaid(xunit), false)) then
				if (conf.HealerModeType == 1 and ZPerl.CanAccess(missing)) then
					---@diagnostic disable-next-line: secret-arithmetic
					self.healthBar.text:SetFormattedText("%d/%d", -missing, healthMax)
				else
					ZPerl.SetDeficitText(self.healthBar.text, missing, "full")
				end
			else
				ZPerl.FormatPercent(self.healthBar.text, UnitHealthPercent(xunit, true, CurveConstants.ScaleTo100), "whole")
			end
		end
		if (conf.UnitHeight < 23) then
			self.healthBar.text:Hide()
		else
			self.healthBar.text:Show()
		end

		if (self.type == "MTT") then
			if (_G.BigWigsTargetMonitor) then
				_G.BigWigsTargetMonitor:TargetCheck(xunit)
			end

			ZPerl.UpdateRaidIcon(self.raidIcon, xunit)
		else
			self.raidIcon:Hide()
		end

		if ZPerl.SafeBool(UnitAffectingCombat(xunit), false) then
			self.combatIcon:Show()
		else
			self.combatIcon:Hide()
		end

		-- Indirect units can return secret flags; no icon in that case
		if ZPerl.SafeBool(UnitIsCharmed(xunit), false) and ZPerl.SafeBool(UnitIsPlayer(xunit), false) then
			self.warningIcon:Show()
		else
			self.warningIcon:Hide()
		end
	else
		self.text:SetPoint("BOTTOMRIGHT", -2, 1)

		if (self.type == "MTT") then
			local id = SecureButton_GetUnit(self:GetParent())
			name = UnitName(id)

			if (name) then
				ZPerl.ColorFriendlyUnit(self.text, id)
				self.text:SetFormattedText(L["XS_TARGET"], name)
				self.healthBar.bg:Hide()
			end
		else
			self.text:SetText(L["NO_TARGET"])
			self.text:SetTextColor(0.5, 0.5, 0.5, 1)
		end
		self.healthBar:SetMinMaxValues(0, 1)
		self.healthBar:SetValue(0)
		grey = true
		self.healthBar.text:Hide()
		self.raidIcon:Hide()
		self.combatIcon:Hide()
		self.warningIcon:Hide()
	end

	if (ZPerl.UpdateSpellRange and ZPerl.layout.rangeFinder.enabled) then
		ZPerl.UpdateSpellRange(self)
	else
		self:SetAlpha(1)
	end

	if (grey) then
		self.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
		self.healthBar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
	else
		if (ZPerl.layout and ZPerl.layout.color.classbar and UnitIsFriend("player", xunit)) then
			local bar = self.healthBar
			local _, class = UnitClass(xunit)
			if (class and ZPerl.CanAccess(class)) then
				---@diagnostic disable-next-line: secret-table-key
				local c = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
				if (c) then
					bar:SetStatusBarColor(c.r, c.g, c.b)
					if (bar.bg) then
						bar.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
					end
					return
				end
			end
		end

		ZPerl.SetSmoothBarColor(self.healthBar, xunit)
	end
end

-- UnitOnShow
local function UnitOnShow(self)
	UpdateUnit(self)
end

-- ZPerl.RaidHelper.RaidHelpShow
function ZPerl.RaidHelper.RaidHelpShow()
	conf.RaidHelper = 1
	ZPerl_RaidHelperCheck:Show() -- ZPerl.RaidHelper.EnableDisable()
	return true
end

-- ZPerl.RaidHelper.MTListUnitOnEnter
function ZPerl.RaidHelper.MTListUnitOnEnter(self)

	local x = ZPerl_RaidHelper_Frame:GetCenter()
	local a1, a2 = "ANCHOR_LEFT", "ANCHOR_TOPLEFT"
	if ( x < (GetScreenWidth() / 2)) then
		a1, a2 = "ANCHOR_RIGHT", "ANCHOR_TOPRIGHT"
	end

	if (conf.Tooltips == 1) then
		local partyid = SecureButton_GetUnit(self)

		if (partyid and UnitName(partyid) and conf.TooltipsWhich == 2) then
			GameTooltip:SetOwner(self, a1)
			GameTooltip:SetUnit(partyid)

			if (self.type == "MTT" and conf.TooltipsWhich == 2) then
				local parentID = SecureButton_GetUnit(self:GetParent())
				if (parentID) then
					ZPerl_BottomTip:SetOwner(GameTooltip, a2, 0, 10)
					ZPerl_BottomTip:SetUnit(parentID)

					ZPerl_BottomTip.NineSlice:SetCenterColor(0.1, 0.4, 0.1, 0.75)
				end
			end
		else
			if (conf.TooltipsWhich == 0) then
				GameTooltip:SetOwner(self, a1)
				GameTooltip:SetUnit(partyid)
			else
				if (self.type == "MTT") then
					partyid = SecureButton_GetUnit(self:GetParent())
				end

				GameTooltip:SetOwner(self, a1)
				GameTooltip:SetUnit(partyid)

				GameTooltip.NineSlice:SetCenterColor(0.1, 0.4, 0.1, 0.75)
			end
		end
	end
end

-- ZPerl.RaidHelper.SetupFrameSimple
function ZPerl.RaidHelper.SetupFrameSimple(self, alpha)
	if self.backdropInfo then
		self:OnBackdropLoaded()
	end
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, alpha or 0.8)
	self:SetBackdropColor(0, 0, 0, alpha or 0.8)
end

-- ZPerl.RaidHelper.HelperBarTextures
if (ZPerl.GetBarTexture) then
function ZPerl.RaidHelper.HelperBarTextures(tex)
	local function UnitTex(v, texture)
		v.healthBar.tex:SetTexture(texture)
		v.healthBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
	end

	for k,v in pairs(XUnits) do
		UnitTex(v, tex)
	end
end
end

-- UnitHasName(unit, name): the unit's name is name, ignoring case. A raid unit has no name in a party (nil) and a
-- secret one cannot be compared: neither matches.
local function UnitHasName(unit, name)
	local n = UnitName(unit)
	return n ~= nil and type(name) == "string" and ZPerl.CanAccess(n) and strlower(n) == strlower(name)
end

-- GetRaidIDByName
local function GetRaidIDByName(name)
	for i = 1, GetNumGroupMembers() do
		if (UnitHasName("raid"..i, name)) then
			return i
		end
	end
end

-- ValidateTankList
-- Check the roster for any tanks that have left the raid
local function ValidateTankList()
	for index,entry in pairs(ZPerlRaidHelperTanks) do
		local found
		for i = 1,GetNumGroupMembers() do
			if (UnitHasName("raid"..i, entry[2])) then
				found = true
				break
			end
		end

		if (not found) then
			ZPerlRaidHelperTanks[index] = nil
		end
	end
end

-- inBattlegrounds
local function inBattlegrounds()
	for i = 1,50 do
		local r = GetBattlefieldStatus(i)
		if (not r) then
			return
		end
		if (r == "active") then
			return true
		end
	end
end

-- ZPerl.RaidHelper.MTRosterChanged()
function ZPerl.RaidHelper.MTRosterChanged()
	ValidateTankList()

	--del(MainTanks, true)
	MainTanks = {}

	blizzMTanks, ctraTanks = 0, 0

	-- If conf is nothing, just return.
	if (conf == nil) then
		return
	else
		if (conf and conf.UseCTRATargets == 1) then
			for index, entry in pairs(ZPerlRaidHelperTanks) do
				local raidid = GetRaidIDByName(entry[2])
				if (raidid) then
					ctraTanks = ctraTanks + 1
					tinsert(MainTanks, {raidid, UnitName("raid"..raidid)})
				end
			end
		end
	end

	-- Blizzard defined main tanks bit. Looks a bit convoluted, but this is all so the order of the tanks is defined
	-- by they order that they were assigned. It's a reasonable assumption that the MT is promoted first. There's no
	-- guarentees of course. This is up to your raid leader, but imo it's better than the default raid ID ordering.
	if (conf and conf.UseBlizzardMTTargets == 1) then
		-- Remember old tanks
		local oldBlizzardNames = { }
		for i, n in ipairs(BlizzardMainTanks) do
			---@diagnostic disable-next-line: secret-table-key
			oldBlizzardNames[n] = true
		end

		-- Scan roster, adding any new ones, and removing found ones from old tanks list
		for i = 1, GetNumGroupMembers() do
			local unitid = "raid"..i
			if ((type(UnitGroupRolesAssigned) == "function" and ZPerl.SafeBool(UnitGroupRolesAssigned(unitid), nil) == "TANK") or GetPartyAssignment("maintank", unitid)) then
				local name = GetUnitName(unitid, true)
				local name2, realm = UnitName(unitid)
				if (not ZPerl.CanAccess(name) or not ZPerl.CanAccess(name2)) then
					name = UNKNOWN
				---@diagnostic disable-next-line: secret-comparison
				elseif (name ~= name2) then
					name = name2.."-"..realm
				end
				---@diagnostic disable-next-line: secret-comparison
				if (name ~= UNKNOWN) then
					---@diagnostic disable-next-line: secret-table-key
					if (oldBlizzardNames[name]) then
						-- We already had this tank, so leave it where it is
						---@diagnostic disable-next-line: secret-table-key
						oldBlizzardNames[name] = nil
					else
						-- New tank defined, add it to the end of the list
						tinsert(BlizzardMainTanks, name)
					end
				end
			end
		end

		-- Remove any that have been demoted
		for name in pairs(oldBlizzardNames) do
			for i = #BlizzardMainTanks,1,-1 do
				---@diagnostic disable-next-line: secret-comparison
				if (BlizzardMainTanks[i] == name) then
					tremove(BlizzardMainTanks, i)
					break
				end
			end
		end
		oldBlizzardNames = { }

		for i,name in ipairs(BlizzardMainTanks) do
			local found
			for _, info in ipairs(MainTanks) do
				---@diagnostic disable-next-line: secret-comparison
				if (name == info[2]) then
					found = true
				end
			end
			if (not found) then
				tinsert(MainTanks, {i, name})
				blizzMTanks = blizzMTanks + 1
			end
		end
	end

	if (not next(ZPerlRaidHelperTanks)) then
		-- If no defined tanks, then make a list from the warriors in raid

		if (blizzMTanks == 0 and conf.NoAutoList == 0 and not inBattlegrounds()) then
			for i = 1,GetNumGroupMembers() do
				local id = "raid"..i
				local _, class = UnitClass(id)
				---@diagnostic disable-next-line: secret-comparison
				if (ZPerl.CanAccess(class) and class == "WARRIOR") then
					tinsert(MainTanks, {i, UnitName(id)})
				end
			end
		end
	end

	MainTankCount = #MainTanks

	ZPerl.RaidHelper.MakeTankList()
end

-- ZPerl.RaidHelper.OnLoad
function ZPerl.RaidHelper.OnLoad(self)
	self:OnBackdropLoaded()
	self:RegisterForDrag("LeftButton")
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	SlashCmdList["ZPERLHELPER"] = ZPerl.RaidHelper.Slash
	SLASH_ZPERLHELPER1 = "/zphelper"

	if (ZPerl.RegisterPerlFrames) then
		ZPerl.RegisterPerlFrames(self)
	end

	ZPerl.RaidHelper.OnLoad = nil
end

-- ZPerl.RaidHelper.OnEvent
function ZPerl.RaidHelper.OnEvent(self, event, ...)
	Events[event](self, ...)
end

-- GetUnit
local function GetUnit(unit)
	for i,search in pairs(XUnits) do
		if (search.type == "MTT") then
			local partyid = SecureButton_GetUnit(search:GetParent())
			if (partyid == unit) then
				return search
			end
		end
	end
end

-- ScanForMTDups
-- Check MTs all have unique targets
local function ScanForMTDups()
	local dup = 1
	local dups = { }

	for i, unit in pairs(XUnits) do
		ZPerl.RaidHelper.SetupFrameSimple(unit, conf.Background_Transparency)
	end

	for i, t1 in pairs(MainTanks) do
		local any = false

		---@diagnostic disable-next-line: secret-argument
		if (UnitExists("raid"..t1[1].."target") and not UnitIsDeadOrGhost("raid"..t1[1])) then
			for j,t2 in pairs(MainTanks) do
				---@diagnostic disable-next-line: secret-table-key
				if (j > i and not dups["raid"..t2[1]]) then
					---@diagnostic disable-next-line: secret-argument
					if (ZPerl.SafeBool(UnitIsUnit("raid"..t1[1].."target", "raid"..t2[1].."target"), false)) then
						---@diagnostic disable-next-line: secret-table-key
						dups["raid"..t2[1]] = 1

						local unit1 = GetUnit("raid"..t1[1])
						local unit2 = GetUnit("raid"..t2[1])

						if (unit1) then
							unit1:OnBackdropLoaded()
							unit1:SetBackdropColor(MTdupColors[dup].r, MTdupColors[dup].g, MTdupColors[dup].b)
							unit1:SetBackdropBorderColor(MTdupColors[dup].r, MTdupColors[dup].g, MTdupColors[dup].b)
						end
						if (unit2) then
							unit2:OnBackdropLoaded()
							unit2:SetBackdropColor(MTdupColors[dup].r, MTdupColors[dup].g, MTdupColors[dup].b)
							unit2:SetBackdropBorderColor(MTdupColors[dup].r, MTdupColors[dup].g, MTdupColors[dup].b)
						end
						any = true
					end
				end
			end

			if (any and dup < 5) then
				dup = dup + 1
			end
		end
	end

	--del(dups)
end

 -- Updates when roles are assigned
	--added aug 30, 2012
function Events:PLAYER_ROLES_ASSIGNED()
	--check for tanks for efficiency if possible
	ZPerl.RaidHelper.MTRosterChanged()
	ZPerl.RaidHelper.EnableDisable()
end

-- MoveArrow
local function MoveArrow(unit)
	ZPerl_MyTarget:SetParent(unit)
	ZPerl_MyTarget:SetPoint("RIGHT", unit, "LEFT", 2 - (conf.MTLabels * 10), 0)
	ZPerl_MyTarget:Show()
end

-- OnUpdate
local function OnUpdate(self, elapsed)
	UpdateTime = UpdateTime + elapsed
	if (UpdateTime > 0.5) then
		-- Forced update here for anything we don't receive events for
		UpdateTime = 0
		for k, unit in pairs(XUnits) do
			if (unit.type == "MTT" or unit.type == "MTTT") then
				UpdateUnit(unit, true)
			end
		end
	end
end

-- CT_RA_IsSendingWithVersion override
-- Override this so that we get the MT list if there's only us in the raid with a CTRA version registered
local old_CT_RA_IsSendingWithVersion

-- VARIABLES_LOADED
function Events:VARIABLES_LOADED()
	self:UnregisterEvent("VARIABLES_LOADED")
	ZPerl.MigrateSavedNames("ZPerl_RaidHelper")

	if (InCombatLockdown()) then
		-- The setup sets protected attributes; the event is unregistered and does not come again, so it runs at combat end
		ZPerl.AfterCombat(Events.VARIABLES_LOADED, self)
		return
	end

	if (_G.CT_RA_IsSendingWithVersion) then
		old_CT_RA_IsSendingWithVersion = _G.CT_RA_IsSendingWithVersion
		_G.CT_RA_IsSendingWithVersion = function(version)
			if (version == 1.08) then
				return 1
			end
			return old_CT_RA_IsSendingWithVersion(version)
		end
	end

	if (type(ZPerlRaidHelperTanks) ~= "table") then
		ZPerlRaidHelperTanks = {}
	end

	ZPerl_MTTargets:UnregisterEvent("UNIT_NAME_UPDATE")	-- Fix for WoW 2.1 UNIT_NAME_UPDATE issue
	ZPerl_MTTargets:SetAttribute("template", "ZPerl_MTList_UnitTemplate")

	ZPerl.RaidHelper.Startup()
	conf = ZPerlRaidHelperDB
	ZPerl_RaidHelperCheck:Show()		-- ZPerl.RaidHelper.EnableDisable()

	ZPerl.RegisterOptionChanger(ZPerl.RaidHelper.SetFrameSizes, nil, "raidsizes")
	ZPerl.RaidHelper.SetFrameSizes()

	Events.VARIABLES_LOADED = nil
end

-- Registration
local function Registration()
	local list = {
		ZPerl.ForeverAPI.healthEvent,
		"UNIT_MAXHEALTH",
		"UNIT_TARGET",
		"UNIT_FACTION",
		"PLAYER_ENTERING_WORLD",
		"PLAYER_TARGET_CHANGED",
		"PLAYER_REGEN_ENABLED",
		"PLAYER_REGEN_DISABLED",
		"PLAYER_ROLES_ASSIGNED",
		--"CHAT_MSG_ADDON",
	}

	for i, a in pairs(list) do
		if not conf then
			return
		end
		-- Never error on an event this client does not have
		if (conf.RaidHelper == 1) then
			ZPerl.RegisterEventSafe(ZPerl_RaidHelper_Frame, a)
		else
			ZPerl.UnregisterEventSafe(ZPerl_RaidHelper_Frame, a)
		end
	end
end

-- ZPerl.RaidHelper.HelperCheckOnUpdate
function ZPerl.RaidHelper.HelperCheckOnUpdate(self)
	self:Hide()
	ZPerl.RaidHelper.EnableDisable()
end

-- ZPerl.RaidHelper.EnableDisable
function ZPerl.RaidHelper.EnableDisable()
	if (InCombatLockdown()) then
		pendingTankListChange = true
		return
	end

	if (ZPerlRaidHelperDB and conf and conf.RaidHelper == 1 and IsInRaid()) then
		if (not ZPerl_RaidHelper_Frame:IsShown()) then
			ZPerl_RaidHelper_Frame:Show()
			ZPerl_RaidHelper_Frame:SetScript("OnUpdate", OnUpdate)
		end

		if (_G.CT_RAMenu_Options and _G.CT_RA_UpdateVisibility) then
			conf.OldCTMTListHide = _G.CT_RAMenu_Options["temp"]["HideMTs"]
			_G.CT_RAMenu_Options["temp"]["HideMTs"] = true
			_G.CT_RA_UpdateVisibility(1)
		end
	else
		if (ZPerl_RaidHelper_Frame:IsShown()) then
			ZPerl_RaidHelper_Frame:Hide()
			ZPerl_RaidHelper_Frame:SetScript("OnUpdate", nil)
		end

		if (ZPerlRaidHelperDB and conf and conf.RaidHelper == 0 and _G.CT_RAMenu_Options and _G.CT_RA_UpdateVisibility) then
			if (conf.OldCTMTListHide ~= true) then
				conf.OldCTMTListHide = nil
				_G.CT_RAMenu_Options["temp"]["HideMTs"] = false
				_G.CT_RA_UpdateVisibility(1)
			end
		end
	end

	Registration()
	ZPerl.RaidHelper.MTRosterChanged()
end

-- GROUP_ROSTER_UPDATE
function Events:GROUP_ROSTER_UPDATE()
	if (not IsInRaid()) then
		--del(MainTanks, 1)
		MainTanks = { }
		--del(BlizzardMainTanks)
		BlizzardMainTanks = { }
	end
	--ZPerl_RaidHelperCheck:show()
end

-- UNIT_HEALTH
function Events:UNIT_HEALTH(unit)
	if not unit then
		return
	end

	if (strfind(unit, "^raid%d")) then
		for k, frame in pairs(XUnits) do
			local partyid = SecureButton_GetUnit(frame)
			if (partyid and ZPerl.SafeBool(UnitIsUnit(partyid, unit), false)) then
				UpdateUnit(frame)
			end
		end
	end
end

-- UNIT_MAXHEALTH
function Events:UNIT_MAXHEALTH(unit)
	if not unit then
		return
	end

	if (strfind(unit, "^raid%d")) then
		for k, frame in pairs(XUnits) do
			local partyid = SecureButton_GetUnit(frame)
			if (partyid and ZPerl.SafeBool(UnitIsUnit(partyid, unit), false)) then
				UpdateUnit(frame)
			end
		end
	end
end

-- UNIT_FACTION
function Events:UNIT_FACTION(unit)
	if not unit then
		return
	end

	if (strfind(unit, "^raid%d")) then
		for k, frame in pairs(XUnits) do
			if (frame.type == "MT") then
				local partyid = frame:GetAttribute("unit")
				if (partyid and partyid == unit) then
					if (UnitAffectingCombat(partyid)) then
						frame.combatIcon:Show()
					else
						frame.combatIcon:Hide()
					end

					-- Indirect units can return secret flags; no icon in that case
					if (ZPerl.SafeBool(UnitIsCharmed(partyid), false)) then
						frame.warningIcon:Show()
					else
						frame.warningIcon:Hide()
					end
				end
			end
		end
	end
end

-- CheckArrowPosition
local function CheckArrowPosition()
	local arrowDone
	local arrowType = "MTT"
	local arrowExtra = ""
	if (conf.ShowMT == 1) then
		arrowType = "MT"
		arrowExtra = "target"
	end

	ZPerl_MyTarget:Hide()
	ZPerl_MainAssist:Hide()
	ZPerl_MainTank:Hide()

	local maAssignment, tankAssignment
	if (GetPartyAssignment) then
		maAssignment = GetPartyAssignment("mainassist")
		tankAssignment = GetPartyAssignment("maintank")
	end

	local maDone, mtDone
	for i, unit in pairs(XUnits) do
		local xunit = SpecialCaseUnit(unit)
		if (xunit) then
			if (not arrowDone and unit.type == arrowType and ZPerl.SafeBool(UnitIsUnit("target", xunit..arrowExtra), false) and ZPerl.SafeBool(UnitExists("target"), false)) then
				MoveArrow(unit)
				arrowDone = true
			end

			if (unit.type == "MTT") then
				xunit = SpecialCaseUnit(unit:GetParent())
			end

			local name = UnitName(xunit)
			if (maAssignment and unit.type == arrowType and not maDone and name == maAssignment) then
				maDone = true
				ZPerl_MainAssist:SetParent(unit.healthBar)
				ZPerl_MainAssist:ClearAllPoints()

				if (conf.MTLabels == 1) then
					ZPerl_MainAssist:SetPoint("BOTTOMRIGHT", unit, "BOTTOMLEFT", 3, 1)
				else
					ZPerl_MainAssist:SetPoint("BOTTOMRIGHT", -1, 1)
				end
				ZPerl_MainAssist:Show()
			end

			if (tankAssignment and unit.type == arrowType and not mtDone and name == tankAssignment) then
				mtDone = true
				ZPerl_MainTank:SetParent(unit.healthBar)
				ZPerl_MainTank:ClearAllPoints()

				if (conf.MTLabels == 1) then
					ZPerl_MainTank:SetPoint("BOTTOMRIGHT", unit, "BOTTOMLEFT", 3, 1)
				else
					ZPerl_MainTank:SetPoint("BOTTOMRIGHT", -1, 1)
				end
				ZPerl_MainTank:Show()
			end
		end
	end
end

-- TargetChanged
local function TargetChanged(xunit)
	local unit, i = ZPerl_MTTargets:GetAttribute("child1"), 1
	local any
	while (unit) do
		local id = unit:GetAttribute("unit")
		if (id and ZPerl.SafeBool(UnitIsUnit(id, xunit), false)) then
			UpdateUnit(unit.target)
			UpdateUnit(unit.targettarget)
			any = true
			break
		end

		i = i + 1
		unit = ZPerl_MTTargets:GetAttribute("child"..i)
	end

	if (any) then
		ScanForMTDups()
		CheckArrowPosition()
	end
end

-- PLAYER_TARGET_CHANGED
function Events:PLAYER_TARGET_CHANGED()
	if (ZPerl_RaidHelper_Frame:IsShown()) then
		TargetChanged("player")
	end
end

-- UNIT_TARGET
function Events:UNIT_TARGET(u)
	if (ZPerl_RaidHelper_Frame:IsShown() and strmatch(u, "^raid")) then
		TargetChanged(u)
	end
end

-- DoButtons
local function DoButtons(disable)
	if (disable or InCombatLockdown()) then
		ZPerl_RaidHelper_Frame_TitleBar_CloseButton:Disable()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleShowMT:Disable()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleMTTargets:Disable()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleLabels:Disable()
		ZPerl_RaidHelper_Frame.corner:EnableMouse(false)
	else
		ZPerl_RaidHelper_Frame_TitleBar_CloseButton:Enable()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleShowMT:Enable()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleMTTargets:Enable()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleLabels:Enable()
		ZPerl_RaidHelper_Frame.corner:EnableMouse(true)
	end

	ZPerl_RaidHelper_Frame_TitleBar_ToggleShowMT:SetButtonTex()
	ZPerl_RaidHelper_Frame_TitleBar_ToggleMTTargets:SetButtonTex()
	ZPerl_RaidHelper_Frame_TitleBar_ToggleLabels:SetButtonTex()
end

-- PLAYER_REGEN_ENABLED
function Events:PLAYER_REGEN_ENABLED()
	if (pendingTankListChange) then
		ZPerl.RaidHelper.MakeTankList()
		ZPerl.RaidHelper.MTRosterChanged()
	end
	DoButtons()
	ZPerl_RaidHelperCheck:Show() -- ZPerl.RaidHelper.EnableDisable()
end
Events.PLAYER_ENTERING_WORLD = Events.PLAYER_REGEN_ENABLED

-- PLAYER_REGEN_DISABLED
function Events:PLAYER_REGEN_DISABLED()
	DoButtons(true)

end

-- The number of 'Other' colums that can be shown
local function DisplayableColumns()
	return 1 + conf.ShowMT + conf.MTTargetTargets
end

-- ZPerl.RaidHelper.SetTitle
function ZPerl.RaidHelper.SetTitle()
	if (DisplayableColumns() > 1 and conf.UnitWidth >= 70) then
		if (ctraTanks > 0 or blizzMTanks > 0) then
			ZPerl_Frame_Title:SetText(L["TITLE_MT_LONG"])
		else
			ZPerl_Frame_Title:SetText(L["TITLE_WARRIOR_LONG"])
		end
	else
		if (ctraTanks > 0 or blizzMTanks > 0) then
			ZPerl_Frame_Title:SetText(L["TITLE_MT_SHORT"])
		else
			ZPerl_Frame_Title:SetText(L["TITLE_WARRIOR_SHORT"])
		end
	end
end

local bEdge = {	bgFile = "Interface\\AddOns\\ZPerl_RaidHelper\\Images\\ZPerl_FrameBack",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 9,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

-- SetVisibility
local function SetVisibility()
	if (InCombatLockdown()) then
		pendingTankListChange = true
		return
	end

	local left = 3 + (conf.MTLabels * 10)
	ZPerl_RaidHelper_Frame:ClearAllPoints()
	ZPerl_RaidHelper_Frame_TitleBar:ClearAllPoints()
	ZPerl_MTTargets:ClearAllPoints()
	if (conf.MTListUpward == 1) then
		ZPerl_RaidHelper_Frame:SetPoint("BOTTOMLEFT", ZPerl_MTList_Anchor, "BOTTOMLEFT", 0, 0)
		ZPerl_RaidHelper_Frame_TitleBar:SetPoint("BOTTOMLEFT", 3, 3)
		ZPerl_RaidHelper_Frame_TitleBar:SetPoint("TOPRIGHT", ZPerl_RaidHelper_Frame, "BOTTOMRIGHT", -3, 13)
		ZPerl_MTTargets:SetAttribute("point", "BOTTOM")
		ZPerl_MTTargets:SetPoint("BOTTOMLEFT", left, 13)
	else
		ZPerl_RaidHelper_Frame:SetPoint("TOPLEFT", ZPerl_MTList_Anchor, "TOPLEFT", 0, 0)
		ZPerl_RaidHelper_Frame_TitleBar:SetPoint("TOPLEFT", 3, -3)
		ZPerl_RaidHelper_Frame_TitleBar:SetPoint("BOTTOMRIGHT", ZPerl_RaidHelper_Frame, "TOPRIGHT", -3, -13)
		ZPerl_MTTargets:SetAttribute("point", "TOP")
		ZPerl_MTTargets:SetPoint("TOPLEFT", left, -13)
	end

	local v, k = ZPerl_MTTargets:GetAttribute("child1"), 1
	while (v) do
		-- We don't actually hide the MT if it's not shown, just make it unclickable and no visible content
		if (conf.ShowMT == 1) then
			if (v.hidden or not v.text:IsShown() or not v.healthBar:IsShown()) then
				v.hidden = false
				v.text:Show()
				v.healthBar:Show()
				v.healthBar.text:Show()
				v:EnableMouse(true)

				v:SetBackdrop(bEdge)

				v.target:SetPoint("TOPLEFT", v, "TOPRIGHT", 0, 0)
			end
		else
			if (not v.hidden or v.text:IsShown() or v.healthBar:IsShown()) then
				v.hidden = true
				v.text:Hide()
				v.healthBar:Hide()
				v.healthBar.text:Hide()
				v.combatIcon:Hide()
				v.warningIcon:Hide()
				v.raidIcon:Hide()
				v:EnableMouse(false)

				v:SetBackdrop(nil)

				v.target:SetPoint("TOPLEFT", v, "TOPLEFT", 0, 0)
			end
		end

		UpdateUnit(v)

		if (conf.MTTargetTargets == 1) then
			v.targettarget:Show()
		else
			v.targettarget:Hide()
		end

		local label = v.label
		if (conf.MTLabels == 1) then
			local u = v:GetAttribute("unit")
			if (u) then
				local lbl
				local name = UnitName(u)
				for i, tank in pairs(MainTanks) do
					---@diagnostic disable-next-line: secret-comparison
					if (ZPerl.CanAccess(name) and tank[2] == name) then
						lbl = i
						break
					end
				end

				label:SetText(lbl)
				label:Show()
			end
		else
			label:Hide()
		end

		k = k + 1
		v = ZPerl_MTTargets:GetAttribute("child"..k)
	end
end

-- ZPerl.RaidHelper.MakeTankList
function ZPerl.RaidHelper.MakeTankList()
	if (InCombatLockdown()) then
		pendingTankListChange = true
		return
	else
		pendingTankListChange = nil
	end

	if (not ZPerlRaidHelperDB or (conf and conf.RaidHelper == 0) or not IsInRaid()) then
		ZPerl.RaidHelper.SetFrameSizes()
		return
	end

	ZPerl.RaidHelper.SetTitle()
	ZPerl_MyTarget:Hide()
	XGaps = 0

	local tanks = { }
	for i = 1, 10 do
		if (MainTanks[i]) then
			tinsert(tanks, MainTanks[i][2])
			if (#tanks >= conf.MaxMainTanks) then
				break
			end
		end
	end

	if (#tanks == 0) then
		ZPerl_RaidHelper_Frame:Hide()
	else
		ZPerl_RaidHelper_Frame:Show()
	end

	ZPerl_MTTargets:SetAttribute("nameList", table.concat(tanks, ","))
	ZPerl_MTTargets:Show()

	--del(tanks)

	if (ZPerl.NoFadeBars) then ZPerl.NoFadeBars() end

	ZPerl.RaidHelper.SetFrameSizes()
end

-- SetUnitSettings
local function SetUnitSettings(self)
	self:SetWidth(conf.UnitWidth)
	self:SetHeight(conf.UnitHeight)

	if (ZPerl.GetBarTexture) then
		local tex = ZPerl.GetBarTexture()
		self.healthBar.tex:SetTexture(tex)

		if (not ZPerl.layout or ZPerl.layout.bar.background) then
			self.healthBar.bg:SetTexture(tex)
		else
			self.healthBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
		end
	end

	self.healthBar:ClearAllPoints()
	if (conf.UnitHeight > 16) then
		self.healthBar:SetPoint("TOPLEFT", 3, -14)
		self.healthBar:SetPoint("BOTTOMRIGHT", -3, 2)
	else
		self.healthBar:SetPoint("TOPLEFT", 4, -4)
		self.healthBar:SetPoint("BOTTOMRIGHT", -4, 4)
	end

	if (ZPerl.RegisterHighlight) then
		ZPerl.RegisterHighlight(self, 3)
	else
		local tex = self:GetHighlightTexture()
		tex:SetVertexColor(0.86, 0.82, 0.41)
	end
end

-- onAttrChanged
local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value) then
			UpdateUnit(self)
			UpdateUnit(self.target)
			UpdateUnit(self.targettarget)
		end
	end
end

-- ZPerl.RaidHelper.MTListChildUnits
function ZPerl.RaidHelper.MTListChildUnits(self)
	self.type = "MT"
	self.hidden = false
	self:SetAttribute("*type1", "target")
	ZPerl.RegisterClickCastFrame(self)
	SetUnitSettings(self)

	local c1 = CreateFrame("Button", self:GetName().."Target", self, "ZPerl_MTList_UnitTemplate")
	c1.type = "MTT"
	c1:SetAttribute("useparent-unit", true)
	c1:SetAttribute("unitsuffix", "target")
	c1:SetAttribute("*type1", "target")
	ZPerl.RegisterClickCastFrame(c1)

	c1:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0)
	SetUnitSettings(c1)

	local c2 = CreateFrame("Button", self:GetName().."TargetTarget", self, "ZPerl_MTList_UnitTemplate")
	c2.type = "MTTT"
	c2:SetAttribute("useparent-unit", true)
	c2:SetAttribute("unitsuffix", "targettarget")
	c2:SetAttribute("*type1", "target")
	ZPerl.RegisterClickCastFrame(c2)

	c2:SetPoint("TOPLEFT", c1, "TOPRIGHT", 0, 0)
	SetUnitSettings(c2)

	self.target = c1
	self.targettarget = c2

	self:SetScript("OnShow", UnitOnShow)
	c1:SetScript("OnShow", UnitOnShow)
	c2:SetScript("OnShow", UnitOnShow)

	self:SetScript("OnAttributeChanged", onAttrChanged)

	self:Show()
	c1:Show()
	c2:Show()

	tinsert(XUnits, self)
	tinsert(XUnits, c1)
	tinsert(XUnits, c2)
end

-- ZPerl.RaidHelper.SetFrameSizes
function ZPerl.RaidHelper.SetFrameSizes()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.RaidHelper.SetFrameSizes)
		return
	end
	conf = ZPerlRaidHelperDB
	local tanks = MainTankCount

	if (ZPerlRaidHelperDB) then
		SetVisibility() -- Change which of MT, MTT and MTTT we can see
		ScanForMTDups()

		if (tanks > conf.MaxMainTanks) then
			tanks = conf.MaxMainTanks
		end

		ZPerl.SwitchAnchor(ZPerl_MTList_Anchor, (conf.MTListUpward == 1 and "BOTTOMLEFT") or "TOPLEFT")

		if (conf) then
			ZPerl_MTTargets:SetHeight((conf.UnitHeight * tanks) + (XGaps * GAP_SPACING))

			local ExtraWidth = (conf.MTLabels * 10)	-- 0 for off, 10 for on
			ZPerl_RaidHelper_Frame:SetWidth(DisplayableColumns() * conf.UnitWidth + 6 + ExtraWidth)

			ZPerl_RaidHelper_Frame:SetHeight((conf.UnitHeight * tanks) + (XGaps * GAP_SPACING) + 6 + ZPerl_RaidHelper_Frame_TitleBar:GetHeight())

			ZPerl.RegisterScalableFrame(ZPerl_RaidHelper_Frame, ZPerl_MTList_Anchor, nil, nil, conf.MTListUpward == 1)
		end
		ZPerl_RaidHelper_Frame_TitleBar_Pin:SetButtonTex()

		CheckArrowPosition()
	end
end

-- ZPerl.RaidHelper.MTListApplyUnitSizes
function ZPerl.RaidHelper.MTListApplyUnitSizes()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.RaidHelper.MTListApplyUnitSizes)
		return
	end
	for k,unit in pairs(XUnits) do
		unit:SetWidth(conf.UnitWidth)
		unit:SetHeight(conf.UnitHeight)
		UpdateUnit(unit)
	end
end

-- ZPerl.RaidHelper.ToggleUseCTRATargets
function ZPerl.RaidHelper.ToggleUseCTRATargets()
	if (conf.UseCTRATargets == 1) then
		conf.UseCTRATargets = 0
	else
		conf.UseCTRATargets = 1
	end

	--ZPerl.RaidHelper.MTRosterChanged()
	ZPerl_RaidHelperCheck:Show() -- ZPerl.RaidHelper.EnableDisable()
	return true
end

-- ZPerl.RaidHelper.ToggleMTTargets
function ZPerl.RaidHelper.ToggleMTTargets()
	if (conf.MTTargetTargets == 1) then
		conf.MTTargetTargets = 0
	else
		conf.MTTargetTargets = 1
	end

	ZPerl.RaidHelper.SetFrameSizes()

	ZPerl_RaidHelper_Frame_TitleBar_ToggleMTTargets:SetButtonTex()
	return true
end

-- ZPerl.RaidHelper.ToggleLabels
function ZPerl.RaidHelper.ToggleLabels()
	if (conf.MTLabels == 1) then
		conf.MTLabels = 0
	else
		conf.MTLabels = 1
	end

	ZPerl.RaidHelper.SetFrameSizes()

	ZPerl_RaidHelper_Frame_TitleBar_ToggleLabels:SetButtonTex()

	return true
end

-- ZPerl.RaidHelper.ToggleShowMT
function ZPerl.RaidHelper.ToggleShowMT()
	if (conf.ShowMT == 1) then
		conf.ShowMT = 0
	else
		conf.ShowMT = 1
	end

	ZPerl.RaidHelper.SetFrameSizes()

	ZPerl_RaidHelper_Frame_TitleBar_ToggleShowMT:SetButtonTex()

	return true
end
