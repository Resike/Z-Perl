-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local XPerl_RaidPets_Events = {}
local RaidPetFrameArray = {}
local conf, rconf, raidconf
XPerl_RequestConfig(function(New)
	conf = New
	raidconf = New.raid
	rconf = New.raidpet
end, "$Revision: @file-revision@ $")

--local new, del, copy = XPerl_GetReusableTable, XPerl_FreeTable, XPerl_CopyTable

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

local pairs = pairs
local strfind = strfind

local CreateFrame = CreateFrame
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidTargetIndex = GetRaidTargetIndex
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInVehicle = UnitInVehicle
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGhost = UnitIsGhost
local UnitIsUnit = UnitIsUnit
local UnitName = UnitName

local SecureButton_GetUnit = SecureButton_GetUnit

local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local CLASS_COUNT = 0
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	if k ~= "Adventurer" then
		CLASS_COUNT = CLASS_COUNT + 1
	end
end

--local taintFrames = {}

-- XPerl_RaidPets_OnEvent
local function XPerl_RaidPets_OnEvent(self, event, unit, ...)
	local func = XPerl_RaidPets_Events[event]
	if (func) then
		if (strfind(event, "^UNIT_") and event ~= "UNIT_ENTERED_VEHICLE") or strfind(event, "^INCOMING_") then
			local f = RaidPetFrameArray[unit]
			if (f) then
				if event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "INCOMING_RESURRECT_CHANGED" then
					func(f, unit, ...)
				else
					func(f, ...)
				end
			end
		else
			func(self, unit, ...)
		end
	end
end

-- XPerl_RaidPets_UpdateAbsorbPrediction
local function XPerl_RaidPets_UpdateAbsorbPrediction(self)
	if raidconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	else
		self.expectedAbsorbs:Hide()
	end
end

-- XPerl_RaidPets_UpdateHealPrediction
local function XPerl_RaidPets_UpdateHealPrediction(self)
	if raidconf.healprediction then
		XPerl_SetExpectedHealth(self)
	else
		self.expectedHealth:Hide()
	end
end

local function XPerl_RaidPets_UpdateResurrectionStatus(self)
	if (UnitHasIncomingResurrection(self.partyid)) then
		self.resurrect:Show()
	else
		self.resurrect:Hide()
	end
end

local guids
-- XPerl_RaidPet_UpdateGUIDs
local function XPerl_RaidPet_UpdateGUIDs()
	--del(guids)
	guids = { }
	for i = 1, GetNumGroupMembers() do
		local id = "raidpet"..i
		if (UnitExists(id)) then
			guids[UnitGUID(id)] = RaidPetFrameArray[id]
		end
	end
end

-- XPerl_RaidPets_UpdateName
local function XPerl_RaidPets_UpdateName(self)
	local partyid = SecureButton_GetUnit(self)
	if not partyid then
		self.petGUID = nil
		self.petID = nil
		self.petName = nil
		return
	end
	local name
	if (self.ownerid and not IsVanillaClassic and (UnitInVehicle(self.ownerid) or UnitHasVehicleUI(self.ownerid))) then
		name = UnitName(self.ownerid)
		if (name) then
			self.text:SetFormattedText("<%s>", name)
		end
	end
	if (not name and partyid) then
		name = UnitName(partyid)
		if name then
			self.text:SetFormattedText("%s", name)
		end
	end

	self.petGUID = UnitGUID(partyid)
	self.petID = partyid
	self.petName = name
	self:SetAlpha(conf.transparency.frame)

	if (self.ownerid) then
		local _, class = UnitClass(self.ownerid)
		local c = XPerl_GetClassColour(class)
		self.text:SetTextColor(c.r, c.g, c.b)
	else
		self.text:SetTextColor(1, 1, 1)
	end
end

-- XPerl_RaidPets_UpdateHealth
local function XPerl_RaidPets_UpdateHealth(self)
	local partyid = SecureButton_GetUnit(self)
	if not partyid then
		self.pethp = 0
		self.pethpmax = 0
		self.healthBar:SetValue(0)
		XPerl_SetSmoothBarColor(self.healthBar, 0)
		return
	end

	local health = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid))
	local healthmax = UnitHealthMax(partyid)

	self.pethp = health
	self.pethpmax = healthmax

	-- PTR region fix
	if not healthmax or healthmax <= 0 then
		if healthmax > 0 then
			healthmax = health
		else
			healthmax = 1
		end
	end

	if (health > healthmax) then
		-- New glitch with 1.12.1
		if (UnitIsDeadOrGhost(partyid)) then
			health = 0
		else
			health = healthmax
		end
	end

	self.healthBar:SetMinMaxValues(0, healthmax)
	if (conf.bar.inverse) then
		self.healthBar:SetValue(healthmax - health)
	else
		self.healthBar:SetValue(health)
	end
	XPerl_SetSmoothBarColor(self.healthBar, health / healthmax)

	if (UnitIsDead(partyid)) then
		self.healthBar.text:SetText(XPERL_LOC_DEAD)
		self.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
		self.healthBar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
	else
		if (healthmax == 0) then
			self.healthBar.text:SetText("")
		else
			self.healthBar.text:SetFormattedText("%.0f%%", health / healthmax * 100)
		end
	end

	XPerl_RaidPets_UpdateAbsorbPrediction(self)
	XPerl_RaidPets_UpdateHealPrediction(self)
	XPerl_RaidPets_UpdateResurrectionStatus(self)
end

-- XPerl_RaidPets_OnUpdate
local function XPerl_RaidPets_OnUpdate(self, elapsed)
	if not self:IsShown() then
		return
	end
	local partyid = SecureButton_GetUnit(self) or self.partyid
	if not partyid then
		return
	end

	if conf.rangeFinder.enabled then
		self.rangeTime = elapsed + (self.rangeTime or 0)
		if (self.rangeTime > 0.2) then
			XPerl_UpdateSpellRange(self, partyid, true)
			self.rangeTime = 0
		end
	end

	if IsClassic then
		local newGuid = UnitGUID(partyid)
		local newName = UnitName(partyid)
		local newHP = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or XPerl_Unit_GetHealth(self))
		local newHPMax = UnitHealthMax(partyid)

		if (newGuid ~= self.petGUID) then
			XPerl_RaidPets_UpdateDisplay(self)
			return
		else
			self.time = elapsed + (self.time or 0)
			if self.time >= 0.5 then
				if conf.highlightDebuffs.enable then
					XPerl_CheckDebuffs(self, partyid)
				end
				--XPerl_Highlight:SetHighlight(self, UnitGUID(partyid))
				self.time = 0
			end
		end

		if newName ~= self.petName then
			XPerl_RaidPet_UpdateGUIDs()
			XPerl_RaidPets_UpdateName(self)
		end

		if (newHP ~= self.pethp or newHPMax ~= self.pethpmax) then
			XPerl_RaidPets_UpdateHealth(self)
		end

	end
end

-- XPerl_Raid_Pet_GetUnitFrameByGUID
function XPerl_Raid_Pet_GetUnitFrameByGUID(guid)
	return guids and guids[guid]
end

-- XPerl_RaidPets_HighlightCallback
function XPerl_RaidPets_HighlightCallback(self, updateGUID)
	local f = guids and guids[updateGUID]
	if (f) then
		XPerl_Highlight:SetHighlight(f, updateGUID)
	end
end


-- XPerl_Raid_Pet_GetUnitFrameByUnit
function XPerl_Raid_Pet_GetUnitFrameByUnit(unitid)
	for k, v in pairs(RaidPetFrameArray) do
		if (v.partyid and UnitIsUnit(v.partyid, unitid)) then
			return v
		end
	end
end

-- XPerl_RaidPets_OnLoad
function XPerl_RaidPets_OnLoad(self)
	self.state = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
	self.state:SetFrameRef("ZPerlRaidPetsHeader", XPerl_Raid_GrpPets)

	self.state:SetAttribute("_onstate-groupupdate", [[
		--print(newstate)

		if newstate == "hide" then
			self:GetFrameRef("ZPerlRaidPetsHeader"):Hide()
		else
			self:GetFrameRef("ZPerlRaidPetsHeader"):Show()
		end
	]])
	RegisterStateDriver(self.state, "groupupdate", "[petbattle] hide; show")

	self.Array = { }

	--XPerl_Raid_GrpPets:UnregisterEvent("UNIT_NAME_UPDATE") -- Fix for WoW 2.1 UNIT_NAME_UPDATE issue

	self:SetScript("OnEvent", XPerl_RaidPets_OnEvent)
	--self:SetScript("OnUpdate", XPerl_RaidPets_OnUpdate)

	XPerl_RegisterOptionChanger(XPerl_RaidPets_OptionActions)

	XPerl_Highlight:Register(XPerl_RaidPets_HighlightCallback, self)

	XPerl_RaidPets_OnLoad = nil
end

-- XPerl_RaidPets_RaidTargetUpdate
local function XPerl_RaidPets_RaidTargetUpdate(self)
	local icon = self.raidIcon
	local raidIcon
	if self.partyid then
		raidIcon = GetRaidTargetIndex(self.partyid)
	end

	if (raidIcon) then
		if (not icon) then
			icon = self:CreateTexture(nil, "OVERLAY")
			self.raidIcon = icon
			icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
			icon:SetPoint("TOPLEFT")
			icon:SetWidth(13)
			icon:SetHeight(13)
		else
			icon:Show()
		end
		SetRaidTargetIconTexture(icon, raidIcon)
	elseif (icon) then
		icon:Hide()
	end
end

-- XPerl_RaidPets_UpdateDisplay
function XPerl_RaidPets_UpdateDisplayAll()
	for k, frame in pairs(RaidPetFrameArray) do
		if (frame:IsShown()) then
			XPerl_RaidPets_UpdateDisplay(frame)
		end
	end
end

-- XPerl_RaidPets_UpdateDisplay
function XPerl_RaidPets_UpdateDisplay(self)
	local partyid = SecureButton_GetUnit(self)
	if not partyid then
		return
	end

	XPerl_RaidPets_UpdateName(self)
	XPerl_RaidPets_UpdateHealth(self)
	XPerl_RaidPets_RaidTargetUpdate(self)

	XPerl_Highlight:SetHighlight(self)
	--[[local unit = SecureButton_GetUnit(self)
	if (unit) then
		XPerl_Highlight:SetHighlight(self, UnitGUID(unit))
	end]]
end

-- UNIT_HEAL_PREDICTION
function XPerl_RaidPets_Events:UNIT_HEAL_PREDICTION(unit)
	if (raidconf.healprediction and unit == self.partyid) then
		XPerl_SetExpectedHealth(self)
	end
end

-- UNIT_HEAL_PREDICTION
function XPerl_RaidPets_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if (raidconf.absorbs and unit == self.partyid) then
		XPerl_SetExpectedAbsorbs(self)
	end
end

function XPerl_RaidPets_Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		XPerl_RaidPets_UpdateResurrectionStatus(self)
	end
end

-- VARIABLES_LOADED
function XPerl_RaidPets_Events:VARIABLES_LOADED()
	self:UnregisterEvent("VARIABLES_LOADED")

	XPerl_Raid_TitlePets:SetScale((conf.raid and conf.raid.scale) or 0.8)

	XPerl_RaidPets_ChangeAttributes()

	XPerl_RaidPets_Events.VARIABLES_LOADED = nil
end

--[[local TitlesUpdateFrame = CreateFrame("Frame")
TitlesUpdateFrame:SetScript("OnUpdate", function(self)
	XPerl_RaidPets_Titles()
	self:Hide()
end)
TitlesUpdateFrame:Hide()]]

function XPerl_RaidPets_Events:PET_BATTLE_OPENING_START()
	if (self) then
		XPerl_RaidPets_HideShow()
	end
end

function XPerl_RaidPets_Events:PET_BATTLE_CLOSE()
	if (self) then
		XPerl_RaidPets_HideShow()
	end
end

-- PLAYER_ENTERING_WORLD
function XPerl_RaidPets_Events:PLAYER_ENTERING_WORLD()
	XPerl_RaidPet_UpdateGUIDs()
	XPerl_RaidPets_UpdateDisplayAll()
	--TitlesUpdateFrame:Show()
end

--[[local function taintable(self)
	if not self or type(self) == "number" then
		return
	end
	self:RegisterForClicks("AnyUp")
	self:SetAttribute("useparent-unit", true)
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")

	XPerl_RegisterClickCastFrame(self)
end]]

-- PLAYER_REGEN_ENABLED
--[[function XPerl_RaidPets_Events:PLAYER_REGEN_ENABLED()
	-- Update all pet frame that would have tained
	local tainted
	if #taintFrames > 0 then
		tainted = true
	end
	for i = 1, #taintFrames do
		taintable(taintFrames[i])
		taintFrames[i] = nil
	end
	if tainted then
		XPerl_RaidPets_ChangeAttributes()
		if (XPerl_RaidPets_OptionActions) then
			XPerl_RaidPets_OptionActions()
		end
	end
end]]

-- RAID_TARGET_UPDATE
function XPerl_RaidPets_Events:RAID_TARGET_UPDATE()
	for i, frame in pairs(RaidPetFrameArray) do
		XPerl_RaidPets_RaidTargetUpdate(frame)
	end
end

-- UNIT_PET
function XPerl_RaidPets_Events:UNIT_PET()
	XPerl_RaidPet_UpdateGUIDs()
end

-- UNIT_ENTERED_VEHICLE
function XPerl_RaidPets_Events:UNIT_ENTERED_VEHICLE(unit)
	local guid = UnitGUID(unit)
	for u, frame in pairs(RaidPetFrameArray) do
		if (frame.ownerid and UnitGUID(frame.ownerid) == guid) then
			XPerl_RaidPets_UpdateName(frame)
		end
	end
	--TitlesUpdateFrame:Show()
end

-- UNIT_EXITED_VEHICLE
function XPerl_RaidPets_Events:UNIT_EXITED_VEHICLE(unit)
	--TitlesUpdateFrame:Show()
end

-- GROUP_ROSTER_UPDATE
function XPerl_RaidPets_Events:GROUP_ROSTER_UPDATE()
	--TitlesUpdateFrame:Show()
	--XPerl_ProtectedCall(XPerl_RaidPets_Align)
	XPerl_RaidPet_UpdateGUIDs()
end

-- UNIT_HEALTH_FREQUENT
function XPerl_RaidPets_Events:UNIT_HEALTH_FREQUENT()
	XPerl_RaidPets_UpdateHealth(self)
end

-- UNIT_HEALTH
function XPerl_RaidPets_Events:UNIT_HEALTH()
	XPerl_RaidPets_UpdateHealth(self)
end

-- UNIT_HEALTHMAX
function XPerl_RaidPets_Events:UNIT_HEALTHMAX()
	XPerl_RaidPets_UpdateHealth(self)
end

-- UNIT_NAME_UPDATE
function XPerl_RaidPets_Events:UNIT_NAME_UPDATE()
	XPerl_RaidPet_UpdateGUIDs()
	XPerl_RaidPets_UpdateName(self)
end

function XPerl_RaidPets_Events:UNIT_AURA()
	XPerl_CheckDebuffs(self, SecureButton_GetUnit(self))
end

-- SetFrameArray
local function SetFrameArray(self, value)
	for k, v in pairs(RaidPetFrameArray) do
		if (v == self) then
			RaidPetFrameArray[k] = nil
		end
	end

	self.partyid = value

	if (value) then
		RaidPetFrameArray[value] = self
	end
end

-- onAttrChanged
local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value) then
			SetFrameArray(self, value)		-- "raidpet"..strmatch(value, "^raid(%d+)"))
			self.ownerid = value:gsub("(%a+)pet(%d+)", "%1%2")

			if (self.petGUID ~= UnitGUID(self.partyid) or self.petID ~= value) then
				XPerl_RaidPets_UpdateDisplay(self)
			end
		else
			SetFrameArray(self)
			self.petGUID = nil
			self.petID = nil
		end
	end
end

-- XPerl_RaidPet_Single_OnLoad
function XPerl_RaidPet_Single_OnLoad(self)
	self:OnBackdropLoaded()

	XPerl_SetChildMembers(self)

	self.edgeFile = "Interface\\Addons\\ZPerl\\Images\\XPerl_ThinEdge"
	self.edgeSize = 10
	self.edgeInsets = 2

	XPerl_RegisterHighlight(self.highlight, 2)

	XPerl_RegisterPerlFrames(self)
	--self.FlashFrames = {self}

	self:SetScript("OnAttributeChanged", onAttrChanged)
	XPerl_RegisterClickCastFrame(self)

	self:SetScript("OnShow", XPerl_RaidPets_UpdateDisplay)

	self:RegisterForClicks("AnyUp")
	self:SetAttribute("useparent-unit", true)
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")

	XPerl_RaidPets_SetBits1(self)

	--[[if (InCombatLockdown()) then
		tinsert(taintFrames, self)
		return
	else
		taintable(self)
	end]]
end

-- initialConfigFunction
--local function initialConfigFunction(self)
	-- This is the only place we're allowed to set attributes whilst in combat
	--self:SetAttribute("unitsuffix", "pet")
	--self:SetAttribute("*type1", "target")
	--self:SetAttribute("initial-height", 30)
	--XPerl_RaidPets_UpdateDisplay(self)
--end

-- SetMainHeaderAttributes
local function SetMainHeaderAttributes(self)
	self:Hide()

	local petsPerColumn
	if conf.raid.mana then
		petsPerColumn = 7
	else
		petsPerColumn = 6
	end

	self:SetAttribute("showParty", raidconf.inParty)

	self:SetAttribute("filterOnPet", true)
	self:SetAttribute("unitsPerColumn", petsPerColumn) -- Don't grow taller than a standard raid group
	self:SetAttribute("maxColumns", 8)
	self:SetAttribute("columnAnchorPoint", "LEFT")

	self:SetAttribute("point", conf.raid.anchor)
	self:SetAttribute("minWidth", 80)
	self:SetAttribute("minHeight", 30.5)
	local titleFrame = self:GetParent()
	self:ClearAllPoints()
	if (conf.raid.anchor == "TOP") then
		self:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, 0)
		self:SetAttribute("xOffset", 0)
		self:SetAttribute("yOffset", -conf.raid.spacing)
	elseif (conf.raid.anchor == "LEFT") then
		self:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, 0)
		self:SetAttribute("xOffset", conf.raid.spacing)
		self:SetAttribute("yOffset", 0)
	elseif (conf.raid.anchor == "BOTTOM") then
		self:SetPoint("BOTTOMLEFT", titleFrame, "TOPLEFT", 0, 0)
		self:SetAttribute("xOffset", 0)
		self:SetAttribute("yOffset", conf.raid.spacing)
	elseif (conf.raid.anchor == "RIGHT") then
		self:SetPoint("TOPRIGHT", titleFrame, "BOTTOMRIGHT", 0, 0)
		self:SetAttribute("xOffset", -conf.raid.spacing)
		self:SetAttribute("yOffset", 0)
	end
	--self:SetAttribute("template", "XPerl_RaidPet_FrameTemplate")
	--self:SetAttribute("templateType", "Button")

	-- Fix Secure Header taint in combat
	local maxColumns = self:GetAttribute("maxColumns") or 1
	local unitsPerColumn = self:GetAttribute("unitsPerColumn") or petsPerColumn
	local startingIndex = self:GetAttribute("startingIndex")
	local maxUnits = maxColumns * unitsPerColumn

	self:Show()
	self:SetAttribute("startingIndex", - maxUnits + 1)
	self:SetAttribute("startingIndex", startingIndex)

	--self.initialConfigFunction = initialConfigFunction
end

-- XPerl_RaidPets_ChangeAttributes
function XPerl_RaidPets_ChangeAttributes()
	XPerl_ProtectedCall(SetMainHeaderAttributes, XPerl_Raid_GrpPets)
end

-- XPerl_RaidPets_HideShow
function XPerl_RaidPets_HideShow()
	local singleGroup
	if (XPerl_Party_SingleGroup) then
		if (conf.party.smallRaid) then
			singleGroup = XPerl_Party_SingleGroup()
		end
	end

	if not IsClassic then
		local on = ((IsInRaid() and rconf.enable) or (IsInGroup() and XPerl_Raid_GrpPets:GetAttribute("showParty") and rconf.enable))
		local events = {
			IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
			"UNIT_MAXHEALTH",
			"UNIT_NAME_UPDATE",
			"UNIT_AURA",
		}

		for i, event in pairs(events) do
			if (on) then
				XPerl_RaidPets_Frame:RegisterEvent(event)
			else
				XPerl_RaidPets_Frame:UnregisterEvent(event)
			end
		end
	end

	if (rconf.enable and not singleGroup) then
		XPerl_Raid_GrpPets:Show()
		XPerl_RaidPets_Frame:Show()
		if (IsInRaid()) then
			XPerl_Raid_TitlePets:Show()
		end
	else
		XPerl_RaidPets_Frame:Hide()
		XPerl_Raid_TitlePets:Hide()
		XPerl_Raid_GrpPets:Hide()
	end

	XPerl_ProtectedCall(XPerl_RaidPets_Align)
end

-- XPerl_RaidPets_Align()
function XPerl_RaidPets_Align()
	if (rconf.enable and rconf.alignToRaid) then
		local counts = XPerl_RaidGroupCounts()
		local lastUsed = 0
		if (counts) then
			for i = 1, CLASS_COUNT do
				if (counts[i] > 0) then
					lastUsed = i
				end
			end
		end

		if (lastUsed > 0) then
			local relative = _G["XPerl_Raid_Title"..lastUsed]
			if (relative) then
				XPerl_Raid_TitlePets:ClearAllPoints()
				XPerl_Raid_TitlePets:SetPoint("TOPLEFT", relative, "TOPRIGHT", raidconf.spacing, 0)
				XPerl_Raid_TitlePets:SetUserPlaced(true)
			end
		end

		XPerl_Raid_TitlePets:EnableMouse(false)
	else
		XPerl_Raid_TitlePets:EnableMouse(true)
	end
end

-- XPerl_RaidPets_Titles
function XPerl_RaidPets_Titles()
	XPerl_Raid_TitlePets.text:SetFormattedText("%s", PETS)

	XPerl_ProtectedCall(XPerl_RaidPets_HideShow)

	XPerl_ProtectedCall(XPerl_RaidPets_Align)

	local show = XPerl_Raid_GrpPetsUnitButton1 and XPerl_Raid_GrpPetsUnitButton1:IsShown()
	if (XPerlLocked == 0 or (rconf.enable and show and conf.raid.titles)) then
		XPerl_Raid_TitlePets.text:Show()
	else
		XPerl_Raid_TitlePets.text:Hide()
	end
end

function XPerl_RaidPets_SetBits1(self)
	if IsClassic or conf.rangeFinder.enabled then
		if not self:GetScript("OnUpdate") then
			self:SetScript("OnUpdate", XPerl_RaidPets_OnUpdate)
		end
	else
		if self:GetScript("OnUpdate") then
			self:SetScript("OnUpdate", nil)
		end
	end
end

-- XPerl_RaidPets_OptionActions
function XPerl_RaidPets_OptionActions()
	if (InCombatLockdown()) then
		XPerl_OutOfCombatQueue[XPerl_RaidPets_OptionActions] = true
		return
	end

	SetMainHeaderAttributes(XPerl_Raid_GrpPets)

	for k, frame in pairs(RaidPetFrameArray) do
		XPerl_RaidPets_SetBits1(frame)
	end

	local events = {
		"PLAYER_ENTERING_WORLD",
		--"PLAYER_REGEN_ENABLED",
		"RAID_TARGET_UPDATE",
		"VARIABLES_LOADED",
		"GROUP_ROSTER_UPDATE",
		"UNIT_PET",
		"UNIT_ENTERED_VEHICLE",
		"UNIT_EXITED_VEHICLE",
		"PET_BATTLE_OPENING_START",
		"PET_BATTLE_CLOSE",
		"INCOMING_RESURRECT_CHANGED",
	}

	for i, event in pairs(events) do
		if (rconf.enable) then
			if pcall(XPerl_RaidPets_Frame.RegisterEvent, XPerl_RaidPets_Frame, event) then
				XPerl_RaidPets_Frame:RegisterEvent(event)
			end
		else
			if pcall(XPerl_RaidPets_Frame.UnregisterEvent, XPerl_RaidPets_Frame, event) then
				XPerl_RaidPets_Frame:UnregisterEvent(event)
			end
		end
	end

	XPerl_Register_Prediction(XPerl_RaidPets_Frame, raidconf, function(guid)
		local frame = XPerl_Raid_Pet_GetUnitFrameByGUID(guid)
		if frame then
			return frame.partyid
		end
	end)

	XPerl_RaidPets_Titles()
	XPerl_Raid_TitlePets:SetScale((conf.raid and conf.raid.scale) or 0.8)

	if (rconf.enable) then
		XPerl_Raid_TitlePets:Show()
	else
		XPerl_Raid_TitlePets:Hide()
	end
end
