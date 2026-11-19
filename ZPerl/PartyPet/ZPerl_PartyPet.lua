-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local Events = { } -- unit events, one set per frame (element PartyPet)
local Bus = { } -- events no frame owns (ZPerl.On)
ZPerl.Elements.PartyPet = {events = Events}
local EnableEvents
local conf, pconf, petconf
local PartyPetFrames = { }
local AllPetFrames = {}
ZPerl.RequestConfig(function(New)
	conf = New
	pconf = New.party
	petconf = New.partypet
	for _, v in ipairs(AllPetFrames) do -- every frame: one without a unit keeps its table too
		v.conf = petconf
	end
end, "$Revision:  $")

--local new, del, copy = ZPerl.GetReusableTable, ZPerl.FreeTable, ZPerl.CopyTable


-- Upvalues
local ipairs = ipairs
local pairs = pairs
local tinsert = tinsert
local wipe = wipe

local GetNumSubgroupMembers = GetNumSubgroupMembers
local RegisterUnitWatch = RegisterUnitWatch
local UnitAffectingCombat = UnitAffectingCombat
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHealthPercent = UnitHealthPercent
local UnitIsCharmed = UnitIsCharmed
local UnitIsDead = UnitIsDead
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitName = UnitName
local UnregisterUnitWatch = UnregisterUnitWatch

local CurveConstants = CurveConstants

-- secret value helpers from ZPerl.lua
local CanAccess = ZPerl.CanAccess
local SafeBool = ZPerl.SafeBool

----------------------
-- Loading Function --
----------------------
function ZPerl.PartyPet.OnLoadEvents(self)
	for event, fn in pairs(Bus) do
		ZPerl.On(event, fn)
	end

	ZPerl.RegisterOptionChanger(ZPerl.PartyPet.SetBits, nil, "partypet")

	ZPerl_Highlight:Register(ZPerl.PartyPet.HighlightCallback, self)

	ZPerl.PartyPet.SetBits()

	ZPerl.PartyPet.OnLoadEvents = nil
end

local guids = { }
-- UpdateGUIDs
local function UpdateGUIDs()
	--del(guids)
	--guids = new()
	wipe(guids)
	-- never key the table with a nil or secret GUID
	if pconf.showPlayer then
		local guid = UnitGUID("player")
		if (guid and CanAccess(guid)) then
			guids[guid] = PartyPetFrames["pet"]
		end
	end
	for i = 1, GetNumSubgroupMembers() do
		local id = "partypet"..i
		if (UnitExists(id)) then
			local guid = UnitGUID(id)
			if (guid and CanAccess(guid)) then
				---@diagnostic disable-next-line: secret-table-key
				guids[guid] = PartyPetFrames[id]
			end
		end
	end
end

function ZPerl.PartyPet.SetFrame(id, unit, owner)
	if not _G["ZPerl_partypet"..id].__unitEvents then
		return -- its OnLoad has not run yet (the party frames' OnLoad ran first)
	end
	PartyPetFrames[unit] = _G["ZPerl_partypet"..id]
	PartyPetFrames[unit].partyid = unit
	PartyPetFrames[unit].ownerid = owner
	ZPerl.UnitFrameSetUnit(PartyPetFrames[unit], unit)
end

function ZPerl.PartyPet.ClearFrame(unit)
	if not PartyPetFrames[unit] then
		return
	end

	PartyPetFrames[unit].partyid = nil
	PartyPetFrames[unit].ownerid = nil
	ZPerl.UnitFrameSetUnit(PartyPetFrames[unit], nil)
	PartyPetFrames[unit] = nil
end

-- ZPerl.PartyPet.HighlightCallback
function ZPerl.PartyPet.HighlightCallback(self, updateGUID)
	if (not updateGUID or not CanAccess(updateGUID)) then
		return
	end
	local f = guids and guids[updateGUID]
	if (f) then
		ZPerl_Highlight:SetHighlight(f, updateGUID)
	end
end


-- ZPerl.PartyPet.OnLoad
function ZPerl.PartyPet.OnLoad(self)
	ZPerl.SetChildMembers(self)
	-- the aura color highlight is for party and raid frames; this frame shows only the HoT highlight
	self.hotHighlightOnly = true
	-- the frame is a child of its owner's party frame, whose range fader sets that frame's alpha: the pet runs its
	-- own range fade, so it must not also fade with its owner (or take the frame transparency twice)
	if (self.SetIgnoreParentAlpha) then
		self:SetIgnoreParentAlpha(true)
	end

	tinsert(AllPetFrames, self)

	if self:GetParent():GetParent():GetAttribute("showPlayer") then
		if self:GetID() == 1 then
			self.partyid = "pet"
			self.ownerid = "player"
		else
			self.partyid = "partypet"..self:GetID() - 1
			self.ownerid = "party"..self:GetID() - 1
		end
	else
		self.partyid = "partypet"..self:GetID()
		self.ownerid = "party"..self:GetID()
	end
	EnableEvents(self)

	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")

	self:SetAttribute("useparent-unit", true)
	self:SetAttribute("unitsuffix", "pet")
	self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("unitsuffix", "pet")

	ZPerl.RegisterClickCastFrame(self.nameFrame)
	ZPerl.RegisterClickCastFrame(self)

	ZPerl.RegisterHighlight(self.highlight, 2)
	ZPerl.RegisterPerlFrames(self, {self.nameFrame, self.statsFrame})

	self.FlashFrames = {self.nameFrame, self.statsFrame}

	self:SetScript("OnShow", function(self)
		if not self.conf then
			self.conf = conf.partypet
		end
		--CheckVisiblity()
		ZPerl.PartyPet.UpdateDisplay(self)
		if (self.perlOwner) then
			ZPerl.Party.PlaceAuras(self.perlOwner)
		end
	end)

	if (ZPerl.layout) then
		self.conf = conf.partypet
	end

	ZPerl.PartyPet.SetBits1(self)
end

-- ZPerl_Party_Pet_CheckPet
-- returns true if full update required (frame shown)

-- UpdateName
local function UpdateName(self)
	if not self.partyid then
		self.petName = nil
		return
	end

	self.petName = UnitName(self.partyid)

	if not petconf.name then
		return
	end

	local unitName = UnitName(self.partyid)
	if unitName then
		self.nameFrame.text:SetText(unitName)
		if (SafeBool(UnitIsPVP(self.ownerid), false)) then
			self.nameFrame.text:SetTextColor(0, 1, 0)
		else
			self.nameFrame.text:SetTextColor(0.5, 0.5, 1)
		end
	end
end

-- UpdateAbsorbPrediction
local function UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		ZPerl.SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

-- UpdateHealPrediction
local function UpdateHealPrediction(self)
	if pconf.healprediction then
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

-- UpdateHealth
local function UpdateHealth(self)
	local partyid = self.partyid
	if not partyid then
		return
	end

	local _, hpMax, missing = ZPerl.HealthSetBar(self.statsFrame.healthBar, partyid, true)
	ZPerl.ColorHealthBar(self, partyid)

	UpdateAbsorbPrediction(self)
	UpdateHealPrediction(self)
	UpdateResurrectionStatus(self)

	local text = self.statsFrame.healthBar.text
	if (SafeBool(UnitIsDead(partyid), false)) then
		self.statsFrame:SetGrey()
		text:SetText(L["LOC_DEAD"])
	else
		if (pconf.healerMode.enable) then
			if (pconf.healerMode.type == 1) then
				ZPerl.SetDeficitPair(text, missing, hpMax, "full")
			else
				ZPerl.SetDeficitText(text, missing, "full")
			end
		else
			-- direct: one format for plain and secret; FormatPercent truncates a secret and adds a decimal below 10
			text:SetFormattedText("%.0f%%", UnitHealthPercent(partyid, true, CurveConstants.ScaleTo100))
		end

		text:Show()

		if (self.statsFrame.greyMana) then
			self.statsFrame.greyMana = nil
			ZPerl.SetManaBarType(self)
		end
	end
end

-- UpdateMana
local powerStyle = {percent = "%.0f%%", inText = true, clampMax = true}
local function UpdateMana(self)
	if (self.partyid) then
		ZPerl.PowerUpdate(self, powerStyle)
	end
end

-- ZPerl.PartyPet.UpdateDisplayAll
function ZPerl.PartyPet.UpdateDisplayAll()
	for k, frame in pairs(PartyPetFrames) do
		if (frame:IsShown()) then
			ZPerl.PartyPet.UpdateDisplay(frame)
		end
	end
end

-- ZPerl.PartyPet.UpdateDisplay
function ZPerl.PartyPet.UpdateDisplay(self)
	local partyid = self.partyid
	if not partyid then
		self.guid = nil
		return
	end

	self.guid = UnitGUID(partyid)

	UpdateName(self)
	UpdateHealth(self)
	ZPerl.UnitUpdateLevel(self)
	ZPerl.SetManaBarType(self)
	UpdateMana(self)
	ZPerl.PartyPet.UpdateCombat(self)
	ZPerl.AurasRebuild(self)
	ZPerl.AurasUpdate(self)
	ZPerl.CheckDebuffs(self, partyid)
	ZPerl.UpdateSpellRange(self, self.partyid)

	self.guid = UnitGUID(partyid)
end

--------------------
-- Click Handlers --
--------------------

-- UpdateControl
local function UpdateControl(self)
	local partyid = self.partyid
	-- indirect units can return secret flags; no icon in that case
	if partyid and SafeBool(UnitIsVisible(partyid), false) and SafeBool(UnitIsCharmed(partyid), false) and SafeBool(UnitIsPlayer(partyid), false) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- ZPerl.PartyPet.UpdateCombat
function ZPerl.PartyPet.UpdateCombat(self)
	local partyid = self.partyid
	if (partyid and UnitIsVisible(partyid) and UnitAffectingCombat(partyid)) then
		self.nameFrame.level:Hide()
		self.nameFrame.combatIcon:Show()
	else
		self.nameFrame.combatIcon:Hide()
		if (petconf.level) then
			self.nameFrame.level:Show()
		end
	end
	UpdateControl(self)
end

-- CombatFlash
local function CombatFlash(self, elapsed, argNew, argGreen)
	if (ZPerl.CombatFlashSet(self, elapsed, argNew, argGreen)) then
		ZPerl.CombatFlashSetFrames(self)
	end
end

-- OnUpdate: the combat flash only; the polls are on the scheduler below.
local function OnUpdate(self, elapsed)
	if not self:IsShown() or not self.partyid then
		return
	end

	if (self.PlayerFlash) then
		CombatFlash(self, elapsed, false)
	end
	ZPerl.OnUpdateIdle(self)
end

-- The range poll of the pet frames, on the scheduler, every 0.2 s (no event covers range). Health and auras
-- follow UNIT_HEALTH / UNIT_MAXHEALTH / UNIT_AURA (elements Health, Auras), a changed pet or name
-- UNIT_PET / UNIT_NAME_UPDATE (below).
local function PollFrames()
	if not conf.rangeFinder.enabled then
		return
	end
	for _, self in ipairs(AllPetFrames) do
		local partyid = self.partyid
		if partyid and self:IsVisible() then
			ZPerl.UpdateSpellRange(self, partyid)
		end
	end
end

ZPerl.Every(0.2, PollFrames)

-------------------
-- Event Handler --
-------------------

-- EnableEvents: called by OnLoad. The unit events follow the frame's unit (ZPerl.UnitFrameSetUnit,
-- from ZPerl.PartyPet.SetFrame / _ClearFrame, which the Party frames call).
EnableEvents = function(self)
	self.updateHealth = UpdateHealth
	self.updatePower = UpdateMana
	self.updatePowerType = ZPerl.SetManaBarType
	self.auraDebuffsNeedBuffs = true
	ZPerl.UnitFrameInit(self, {self.partyid}, {"Health", "Power", "PartyPet", "Auras"})
end

-- PARTY_MEMBER_ENABLE / PARTY_MEMBER_DISABLE carry the owner unit; the frames are keyed by pet unit
function Bus.PARTY_MEMBER_ENABLE(event, unit)
	local pet = string.gsub(unit, "(%a+)(%d+)", "%1pet%2")
	local frame = PartyPetFrames[pet]
	if frame then
		local owner
		local unitID = frame.partyid
		if unitID == "pet" or unitID == "playerpet" then
			owner = "player"
		else
			owner = string.gsub(unitID, "(%a+)pet(%d+)", "%1%2")
		end

		if owner ~= "player" then
			if not SafeBool(UnitIsUnit(owner, unit), true) then
				return
			end
		else
			return
		end

		ZPerl.PartyPet.UpdateDisplay(frame)
	end
end
Bus.PARTY_MEMBER_DISABLE = Bus.PARTY_MEMBER_ENABLE

-- UNIT_COMBAT
function Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end
	-- set first: the flash and hit text animate even when a later line raises on a secret amount
	self:SetScript("OnUpdate", OnUpdate)

	if (action == "HEAL") then
		CombatFlash(self, 0, true, true)
	elseif (ZPerl.IsHit(action, damage)) then
		CombatFlash(self, 0, true)
	end
end

-- PLAYER_ENTERING_WORLD
function Bus.PLAYER_ENTERING_WORLD()
	UpdateGUIDs()
	ZPerl.PartyPet.UpdateDisplayAll()
end
-- Full refresh of every shown frame on purpose: a roster change moves members, and so their pets,
-- between unit tokens, UNIT_PET puts a different pet (or none) on a token, a secret GUID cannot be compared, and UpdateDisplay is the only path that
-- re-applies name, class color, auras and debuff highlight together. At most 5 frames per burst.
Bus.GROUP_ROSTER_UPDATE = Bus.PLAYER_ENTERING_WORLD
Bus.UNIT_PET = Bus.PLAYER_ENTERING_WORLD
-- a vehicle swap changed the GUID the 0.2 s poll used to catch: not checked in game
Bus.UNIT_ENTERED_VEHICLE = Bus.PLAYER_ENTERING_WORLD
Bus.UNIT_EXITED_VEHICLE = Bus.PLAYER_ENTERING_WORLD

-- UNIT_FLAGS
function Events:UNIT_FLAGS()
	ZPerl.PartyPet.UpdateCombat(self)
end

-- UNIT_NAME_UPDATE
function Events:UNIT_NAME_UPDATE()
	UpdateGUIDs()
	UpdateName(self)
end

-- UNIT_FACTION
function Events:UNIT_FACTION()
	UpdateName(self)
	ZPerl.PartyPet.UpdateCombat(self)
end

-- UNIT_LEVEL
function Events:UNIT_LEVEL()
	ZPerl.UnitUpdateLevel(self)
end

-- UNIT_AURA
function Events:UNIT_AURA()
	ZPerl.CheckDebuffs(self, self.partyid)
end

function Events:UNIT_HEAL_PREDICTION(unit)
	if pconf.healprediction and unit == self.partyid then
		ZPerl.SetExpectedHealth(self)
	end
end

function Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if pconf.absorbs then
		ZPerl.SetExpectedAbsorbs(self)
	end
end

function Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		UpdateResurrectionStatus(self)
	end
end


-- EnableDisable
local function EnableDisable(self)
	if (petconf.enable) then
		RegisterUnitWatch(self)
	else
		UnregisterUnitWatch(self)
		self:Hide()
	end
end

-- ApplyLayout: the protected part of Set_Bits1; reads the config when it runs
local function ApplyLayout(self)
	if (not self:GetParent()) then
		self:SetParent(_G["ZPerl_party"..self:GetID()])
	end

	if (petconf.name) then
		self.nameFrame:Show()
		self.nameFrame:SetHeight(20)
	else
		self.nameFrame:Hide()
		self.nameFrame:SetHeight(4)
	end

	self:SetHeight(petconf.mana and 50 or 40)
	ZPerl.SetScale(self, petconf.scale)
	-- a RIGHT aura block of the member frame sits past this frame
	local member = _G["ZPerl_party"..self:GetID()]
	if (member and member.buffContainer) then
		ZPerl.AurasPlace(member)
	end
end

-- ZPerl.PartyPet.SetBits1
function ZPerl.PartyPet.SetBits1(self)
	ZPerl.AfterCombatFor(ApplyLayout, self)

	if (petconf.mana) then
		self.statsFrame:SetHeight(33)
		self.statsFrame.manaBar:Show()
		if (petconf.percent) then
			self.statsFrame.manaBar.text:Show()
		else
			self.statsFrame.manaBar.text:Hide()
		end
	else
		self.statsFrame:SetHeight(23)
		self.statsFrame.manaBar:Hide()
	end

	if (petconf.level) then
		self.nameFrame.level:Show()
	else
		self.nameFrame.level:Hide()
	end

	ZPerl.StatsFrameSetup(self)

	if (self:IsShown()) then
		ZPerl.PartyPet.UpdateDisplay(self)
	end

	ZPerl.AfterCombatFor(EnableDisable, self)
end

-- ZPerl.PartyPet.SetBits
function ZPerl.PartyPet.SetBits()
	local d = ZPerl.Dev; if d and d.listener then d.Emit("redisplay.partypet") end
	for k, v in pairs(AllPetFrames) do
		ZPerl.PartyPet.SetBits1(v)
	end
end
