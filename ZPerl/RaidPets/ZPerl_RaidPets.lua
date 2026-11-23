-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local Events = {} -- Unit events, one set per frame (element RaidPets)
local Bus = {} -- Events no frame owns (ZPerl.On)
local busOn
ZPerl.Elements.RaidPets = {events = Events}
local allFrames = {} -- Every pet frame, in creation order
local RaidPetFrameArray = {}
local conf, rconf, raidconf
ZPerl.RequestConfig(function(New)
	conf = New
	raidconf = New.raid
	rconf = New.raidpet
end, "$Revision:  $")

--local new, del, copy = ZPerl.GetReusableTable, ZPerl.FreeTable, ZPerl.CopyTable

-- Upvalues
local ipairs = ipairs
local pairs = pairs
local tinsert = tinsert
local wipe = wipe

local GetNumGroupMembers = GetNumGroupMembers
local GetRaidTargetIndex = GetRaidTargetIndex
local InCombatLockdown = InCombatLockdown
local SecureButton_GetUnit = SecureButton_GetUnit
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHealthPercent = UnitHealthPercent
local UnitIsDead = UnitIsDead
local UnitName = UnitName

local CurveConstants = CurveConstants
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local PETS = PETS

-- Secret value helpers from ZPerl.lua
local CanAccess = ZPerl.CanAccess
local CLASS_COUNT = 0
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	if k ~= "Adventurer" and k ~= "TRAVELER" then
		CLASS_COUNT = CLASS_COUNT + 1
	end
end

-- UpdateAbsorbPrediction
local function UpdateAbsorbPrediction(self)
	if raidconf.absorbs then
		ZPerl.SetExpectedAbsorbs(self)
	else
		self.expectedAbsorbs:Hide()
	end
end

-- UpdateHealPrediction
local function UpdateHealPrediction(self)
	if raidconf.healprediction then
		ZPerl.SetExpectedHealth(self)
	else
		self.expectedHealth:Hide()
	end
end

local function UpdateResurrectionStatus(self)
	if (UnitHasIncomingResurrection(self.partyid)) then
		self.resurrect:Show()
	else
		self.resurrect:Hide()
	end
end

local guids = { }
-- RaidPetUpdateGUIDs
local function RaidPetUpdateGUIDs()
	wipe(guids)
	for i = 1, GetNumGroupMembers() do
		local id = "raidpet"..i
		if (UnitExists(id)) then
			-- Never key the table with a nil or secret GUID
			local guid = UnitGUID(id)
			if (guid and CanAccess(guid)) then
				---@diagnostic disable-next-line: secret-table-key
				guids[guid] = RaidPetFrameArray[id]
			end
		end
	end
end

-- UpdateName
local function UpdateName(self)
	local partyid = SecureButton_GetUnit(self)
	if not partyid then
		self.petGUID = nil
		self.petID = nil
		self.petName = nil
		return
	end
	local name
	if partyid then
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
		local c = ZPerl.GetClassColor(class)
		self.text:SetTextColor(c.r, c.g, c.b)
	else
		self.text:SetTextColor(1, 1, 1)
	end
end

-- UpdateHealth
local function UpdateHealth(self)
	local partyid = SecureButton_GetUnit(self)
	if not partyid then
		self.healthBar:SetValue(0)
		return
	end

	ZPerl.HealthSetBar(self.healthBar, partyid)
	ZPerl.SetSmoothBarColor(self.healthBar, partyid)

	if (ZPerl.SafeBool(UnitIsDead(partyid), false)) then
		self.healthBar.text:SetText(L["LOC_DEAD"])
		self.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
		self.healthBar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
	else
		-- direct: one format for plain and secret; FormatPercent truncates a secret and adds a decimal below 10
		self.healthBar.text:SetFormattedText("%.0f%%", UnitHealthPercent(partyid, true, CurveConstants.ScaleTo100))
	end

	UpdateAbsorbPrediction(self)
	UpdateHealPrediction(self)
	UpdateResurrectionStatus(self)
end

-- The range poll of the pet frames, on the scheduler, every 0.2 s (no event covers range). Health follows
-- UNIT_HEALTH / UNIT_MAXHEALTH (element Health), the debuff highlight UNIT_AURA, a changed pet or name
-- UNIT_PET / UNIT_NAME_UPDATE (bus below).
local function PollFrames()
	if not conf.rangeFinder.enabled then
		return
	end
	for _, self in ipairs(allFrames) do
		local partyid = self:IsVisible() and (SecureButton_GetUnit(self) or self.partyid)
		if partyid then
			ZPerl.UpdateSpellRange(self, partyid, true)
		end
	end
end

ZPerl.Every(0.2, PollFrames)

-- ZPerl.RaidPets.HighlightCallback
function ZPerl.RaidPets.HighlightCallback(self, updateGUID)
	if (not updateGUID or not CanAccess(updateGUID)) then
		return
	end
	local f = guids and guids[updateGUID]
	if (f) then
		ZPerl_Highlight:SetHighlight(f, updateGUID)
	end
end


-- ZPerl.RaidPets.OnLoad
function ZPerl.RaidPets.OnLoad(self)
	self.Array = { }

	--ZPerl_Raid_GrpPets:UnregisterEvent("UNIT_NAME_UPDATE") -- Fix for WoW 2.1 UNIT_NAME_UPDATE issue


	ZPerl.RegisterOptionChanger(ZPerl.RaidPets.OptionActions, nil, "raidpets")

	ZPerl_Highlight:Register(ZPerl.RaidPets.HighlightCallback, self)

	ZPerl.RaidPets.OnLoad = nil
end

-- RaidTargetUpdate
local function RaidTargetUpdate(self)
	local icon = self.raidIcon
	if (not icon) then
		-- The texture is made on the first mark
		if (not self.partyid or not GetRaidTargetIndex(self.partyid)) then
			return
		end
		icon = self:CreateTexture(nil, "OVERLAY")
		self.raidIcon = icon
		icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		icon:SetPoint("TOPLEFT")
		icon:SetSize(13, 13)
	end
	if (self.partyid) then
		ZPerl.UpdateRaidIcon(icon, self.partyid)
	else
		icon:Hide()
	end
end

-- ZPerl.RaidPets.UpdateDisplay
function ZPerl.RaidPets.UpdateDisplayAll()
	for k, frame in pairs(RaidPetFrameArray) do
		if (frame:IsShown()) then
			ZPerl.RaidPets.UpdateDisplay(frame)
		end
	end
end

-- ZPerl.RaidPets.UpdateDisplay
function ZPerl.RaidPets.UpdateDisplay(self)
	local partyid = SecureButton_GetUnit(self)
	if not partyid then
		return
	end

	UpdateName(self)
	UpdateHealth(self)
	RaidTargetUpdate(self)

	ZPerl_Highlight:SetHighlight(self)
end

-- UNIT_HEAL_PREDICTION
function Events:UNIT_HEAL_PREDICTION(unit)
	if (raidconf.healprediction and unit == self.partyid) then
		ZPerl.SetExpectedHealth(self)
	end
end

function Events:UNIT_AURA(unit)
	if conf.highlightDebuffs.enable and unit == self.partyid then
		ZPerl.CheckDebuffs(self, unit)
	end
end

function Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		UpdateResurrectionStatus(self)
	end
end

-- VARIABLES_LOADED
function Bus.VARIABLES_LOADED()
	ZPerl.Off("VARIABLES_LOADED", Bus.VARIABLES_LOADED)

	ZPerl.SetScale(ZPerl_Raid_TitlePets, (conf.raid and conf.raid.scale) or 1)

	ZPerl.RaidPets.ChangeAttributes()
end

-- PLAYER_ENTERING_WORLD
function Bus.PLAYER_ENTERING_WORLD()
	RaidPetUpdateGUIDs()
	ZPerl.RaidPets.UpdateDisplayAll()
end

-- RAID_TARGET_UPDATE
function Bus.RAID_TARGET_UPDATE()
	for i, frame in pairs(RaidPetFrameArray) do
		RaidTargetUpdate(frame)
	end
end

-- UNIT_PET: the owner's pet changed; redraw that owner's frame
function Bus.UNIT_PET(event, unit)
	RaidPetUpdateGUIDs()
	for _, frame in pairs(RaidPetFrameArray) do
		if (frame.ownerid == unit and frame:IsShown()) then
			ZPerl.RaidPets.UpdateDisplay(frame)
		end
	end
end

-- UNIT_NAME_UPDATE: a pet's name resolved or changed
function Bus.UNIT_NAME_UPDATE(event, unit)
	local frame = RaidPetFrameArray[unit]
	if (frame and frame:IsShown()) then
		RaidPetUpdateGUIDs()
		UpdateName(frame)
	end
end

-- UNIT_ENTERED_VEHICLE
function Bus.UNIT_ENTERED_VEHICLE(event, unit)
	local guid = UnitGUID(unit)
	if (not CanAccess(guid)) then
		return
	end
	for u, frame in pairs(RaidPetFrameArray) do
		local ownerGUID = frame.ownerid and UnitGUID(frame.ownerid)
		if (ownerGUID and CanAccess(ownerGUID) and ownerGUID == guid) then
			UpdateName(frame)
		end
	end
	--TitlesUpdateFrame:Show()
end
-- The vehicle swap the 0.2 s poll used to catch as a changed GUID: not checked in game
Bus.UNIT_EXITED_VEHICLE = Bus.UNIT_ENTERED_VEHICLE

-- GROUP_ROSTER_UPDATE
function Bus.GROUP_ROSTER_UPDATE()
	--TitlesUpdateFrame:Show()
	--ZPerl.ProtectedCall(ZPerl.RaidPets.Align)
	RaidPetUpdateGUIDs()
end

-- SetFrameArray
local function SetFrameArray(self, value)
	for k, v in pairs(RaidPetFrameArray) do
		if (v == self) then
			RaidPetFrameArray[k] = nil
		end
	end

	self.partyid = value
	ZPerl.UnitFrameSetUnit(self, value)

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

			local guid = UnitGUID(self.partyid)
			if (self.petID ~= value or not CanAccess(guid) or not CanAccess(self.petGUID) or self.petGUID ~= guid) then
				ZPerl.RaidPets.UpdateDisplay(self)
			end
		else
			SetFrameArray(self)
			self.petGUID = nil
			self.petID = nil
		end
	end
end

-- Every pet frame runs the Health element and RaidPets while the module is enabled; the unit events
-- follow the frame's unit (ZPerl.UnitFrameSetUnit, from SetFrameArray).
local ELEMENTS = {"Health", "RaidPets"}
local function SetElements(self)
	for _, name in ipairs(ELEMENTS) do
		if (rconf and rconf.enable) then
			ZPerl.UnitFrameEnable(self, name)
		else
			ZPerl.UnitFrameDisable(self, name)
		end
	end
end

-- ZPerl.RaidPets.RaidPetSingleOnLoad
function ZPerl.RaidPets.RaidPetSingleOnLoad(self)
	-- The aura color highlight is for party and raid frames; this frame shows only the HoT highlight
	self.hotHighlightOnly = true
	self:OnBackdropLoaded()
	self.updateHealth = UpdateHealth
	ZPerl.UnitFrameInit(self, nil, {})
	tinsert(allFrames, self)
	SetElements(self)

	ZPerl.SetChildMembers(self)

	self.edgeFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_ThinEdge"
	self.edgeSize = 10
	self.edgeInsets = 2

	ZPerl.RegisterHighlight(self.highlight, 2)

	ZPerl.RegisterPerlFrames(self)
	--self.FlashFrames = {self}

	self:SetScript("OnAttributeChanged", onAttrChanged)
	ZPerl.RegisterClickCastFrame(self)

	self:SetScript("OnShow", ZPerl.RaidPets.UpdateDisplay)

	self:RegisterForClicks("AnyUp")
	self:SetAttribute("useparent-unit", true)
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")

end

-- initialConfigFunction
--local function initialConfigFunction(self)
	-- This is the only place we're allowed to set attributes whilst in combat
	--self:SetAttribute("unitsuffix", "pet")
	--self:SetAttribute("*type1", "target")
	--self:SetAttribute("initial-height", 30)
	--ZPerl.RaidPets.UpdateDisplay(self)
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
	--self:SetAttribute("template", "ZPerl_RaidPet_FrameTemplate")
	--self:SetAttribute("templateType", "Button")

	-- Fix Secure Header taint in combat
	local maxColumns = self:GetAttribute("maxColumns") or 1
	local unitsPerColumn = self:GetAttribute("unitsPerColumn") or petsPerColumn
	local startingIndex = self:GetAttribute("startingIndex")
	local maxUnits = maxColumns * unitsPerColumn

	self:Show()
	self:SetAttribute("startingIndex", - maxUnits + 1)
	self:SetAttribute("startingIndex", startingIndex)

	-- The header makes buttons for what its attributes allow, so the decider waits for them
	ZPerl.RaidPets.Ready = true

	--self.initialConfigFunction = initialConfigFunction
end

-- ZPerl.RaidPets.ChangeAttributes
function ZPerl.RaidPets.ChangeAttributes()
	ZPerl.ProtectedCall(SetMainHeaderAttributes, ZPerl_Raid_GrpPets)
end

-- ZPerl.RaidPets.Align()
function ZPerl.RaidPets.Align()
	if (rconf.enable and rconf.alignToRaid) then
		local counts = ZPerl.Raid.RaidGroupCounts()
		local lastUsed = 0
		if (counts) then
			for i = 1, CLASS_COUNT do
				if (counts[i] > 0) then
					lastUsed = i
				end
			end
		end

		if (lastUsed > 0) then
			local relative = _G["ZPerl_Raid_Title"..lastUsed]
			if (relative) then
				ZPerl_Raid_TitlePets:ClearAllPoints()
				ZPerl_Raid_TitlePets:SetPoint("TOPLEFT", relative, "TOPRIGHT", raidconf.spacing, 0)
			end
		end

		ZPerl_Raid_TitlePets:EnableMouse(false)
	else
		ZPerl_Raid_TitlePets:EnableMouse(true)
	end
end

-- ZPerl.RaidPets.Titles
function ZPerl.RaidPets.Titles()
	ZPerl_Raid_TitlePets.text:SetFormattedText("%s", PETS)

	ZPerl.GroupVisibilityUpdate()

	ZPerl.ProtectedCall(ZPerl.RaidPets.Align)

	---@diagnostic disable-next-line: undefined-global
	local show = ZPerl_Raid_GrpPetsUnitButton1 and ZPerl_Raid_GrpPetsUnitButton1:IsShown()
	if (ZPerl.Locked == 0 or (rconf.enable and show and conf.raid.titles)) then
		ZPerl_Raid_TitlePets.text:Show()
	else
		ZPerl_Raid_TitlePets.text:Hide()
	end

	ZPerl.RaidPets.Virtual()
end

-- ZPerl.RaidPets.Virtual
-- The black placeholder shown while frames are unlocked, sized to one column of pets
function ZPerl.RaidPets.Virtual()
	local titleFrame = ZPerl_Raid_TitlePets
	local virtualFrame = titleFrame.virtual
	if (not virtualFrame) then
		return
	end

	if (ZPerl.Locked ~= 0 or not rconf.enable) then
		virtualFrame:Hide()
		return
	end

	local rows = conf.raid.mana and 7 or 6
	local spacing = raidconf.spacing or 0
	local w, h = 80, 30.5
	local anchor = raidconf.anchor

	virtualFrame:ClearAllPoints()
	if (anchor == "LEFT") then
		virtualFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, 0)
		virtualFrame:SetHeight(h)
		virtualFrame:SetWidth(w * rows + spacing * (rows - 1))
	elseif (anchor == "BOTTOM") then
		virtualFrame:SetPoint("BOTTOMLEFT", titleFrame, "TOPLEFT", 0, 0)
		virtualFrame:SetHeight(h * rows + spacing * (rows - 1))
		virtualFrame:SetWidth(w)
	elseif (anchor == "RIGHT") then
		virtualFrame:SetPoint("TOPRIGHT", titleFrame, "BOTTOMRIGHT", 0, 0)
		virtualFrame:SetHeight(h)
		virtualFrame:SetWidth(w * rows + spacing * (rows - 1))
	else
		virtualFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, 0)
		virtualFrame:SetHeight(h * rows + spacing * (rows - 1))
		virtualFrame:SetWidth(w)
	end
	virtualFrame:OnBackdropLoaded()
	virtualFrame:SetBackdropColor(conf.color.frame.r, conf.color.frame.g, conf.color.frame.b, conf.color.frame.a)
	virtualFrame:SetBackdropBorderColor(conf.color.border.r, conf.color.border.g, conf.color.border.b, 1)
	-- Aligned to the raid, the pets follow the last group and can't be dragged on their own
	virtualFrame:EnableMouse(not rconf.alignToRaid)
	virtualFrame:Show()
end

-- ZPerl.RaidPets.OptionActions
function ZPerl.RaidPets.OptionActions()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.RaidPets.OptionActions)
		return
	end
	local d = ZPerl.Dev; if d and d.listener then d.Emit("redisplay.raidpets") end

	SetMainHeaderAttributes(ZPerl_Raid_GrpPets)

	for i, frame in ipairs(allFrames) do
		SetElements(frame)
	end

	-- The events no frame owns follow the enable option
	if ((rconf.enable and true) ~= busOn) then
		busOn = rconf.enable and true
		for event, fn in pairs(Bus) do
			if (busOn) then
				ZPerl.On(event, fn)
			else
				ZPerl.Off(event, fn)
			end
		end
	end

	ZPerl.RaidPets.Titles()
	ZPerl.SetScale(ZPerl_Raid_TitlePets, (conf.raid and conf.raid.scale) or 1)

	if (rconf.enable) then
		ZPerl_Raid_TitlePets:Show()
	else
		ZPerl_Raid_TitlePets:Hide()
	end
end
