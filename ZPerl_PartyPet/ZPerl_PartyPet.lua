-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local XPerl_Party_Pet_Events = { }
local conf, pconf, petconf
XPerl_PartyPetFrames = { }
local PartyPetFrames = XPerl_PartyPetFrames
XPerl_RequestConfig(function(New)
	conf = New
	pconf = New.party
	petconf = New.partypet
	for k, v in pairs(PartyPetFrames) do
		v.conf = pconf
	end
end, "$Revision: @file-revision@ $")

--local new, del, copy = XPerl_GetReusableTable, XPerl_FreeTable, XPerl_CopyTable

local AllPetFrames = {}

local IsClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local UnitName = UnitName
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitIsGhost = UnitIsGhost
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

----------------------
-- Loading Function --
----------------------
function XPerl_Party_Pet_OnLoadEvents(self)
	self.time = 0

	local events = {
		"UNIT_COMBAT",
		"UNIT_FACTION",
		"UNIT_AURA",
		"UNIT_FLAGS",
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		"PLAYER_ENTERING_WORLD",
		"PET_BATTLE_OPENING_START",
		"PET_BATTLE_CLOSE",
		"INCOMING_RESURRECT_CHANGED",
	}

	for i, event in pairs(events) do
		if pcall(self.RegisterEvent, self, event) then
			self:RegisterEvent(event)
		end
	end

	-- Set here to reduce amount of function calls made
	self:SetScript("OnEvent", XPerl_Party_Pet_OnEvent)
	self:SetScript("OnUpdate", XPerl_Party_Pet_OnUpdate)

	XPerl_RegisterOptionChanger(XPerl_Party_Pet_Set_Bits, "PartyPet")

	XPerl_Highlight:Register(XPerl_Party_Pet_HighlightCallback, self)

	XPerl_Party_Pet_OnLoadEvents = nil
end

local guids
-- XPerl_Party_Pet_UpdateGUIDs
function XPerl_Party_Pet_UpdateGUIDs()
	--del(guids)
	--guids = new()
	guids = { }
	for i = 1, GetNumSubgroupMembers() do
		local id = "partypet"..i
		if (UnitExists(id)) then
			guids[UnitGUID(id)] = PartyPetFrames[id]
		end
	end
end

-- XPerl_Party_Pet_GetUnitFrameByGUID
function XPerl_Party_Pet_GetUnitFrameByGUID(guid)
	return guids and guids[guid]
end

-- XPerl_Party_Pet_HighlightCallback
function XPerl_Party_Pet_HighlightCallback(self, updateGUID)
	local f = guids and guids[updateGUID]
	if (f) then
		XPerl_Highlight:SetHighlight(f, updateGUID)
	end
end


-- XPerl_Party_Pet_GetUnitFrameByUnit
function XPerl_Party_Pet_GetUnitFrameByUnit(unitid)
	return PartyPetFrames[unitid]
end

-- CheckVisiblity()
--[[local function CheckVisiblity()
	local on
	for i, frame in pairs(PartyPetFrames) do
		if (frame:IsShown()) then
			on = true
		end
	end

	if (on) then
		XPerl_Party_Pet_EventFrame:Show()
	else
		XPerl_Party_Pet_EventFrame:Hide()
	end
end]]

-- XPerl_Party_Pet_OnLoad
function XPerl_Party_Pet_OnLoad(self)
	XPerl_SetChildMembers(self)

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

	local BuffOnUpdate, DebuffOnUpdate, BuffUpdateTooltip, DebuffUpdateTooltip
	BuffUpdateTooltip = XPerl_Unit_SetBuffTooltip
	DebuffUpdateTooltip = XPerl_Unit_SetDeBuffTooltip

	if (self:GetID() > 1) then
		self.buffSetup = XPerl_partypet1.buffSetup
	else
		self.buffSetup = {
			buffScripts = {
				OnEnter = XPerl_Unit_SetBuffTooltip,
				OnUpdate = BuffOnUpdate,
				OnLeave = XPerl_PlayerTipHide,
			},
			debuffScripts = {
				OnEnter = XPerl_Unit_SetDeBuffTooltip,
				OnUpdate = DebuffOnUpdate,
				OnLeave = XPerl_PlayerTipHide,
			},
			updateTooltipBuff = BuffUpdateTooltip,
			updateTooltipDebuff = DebuffUpdateTooltip,
			debuffParent = true,
			debuffSizeMod = 0,
			debuffAnchor1 = function(self, b)
				local relation = self.buffFrame.buff and self.buffFrame.buff[1]
				if (not relation) then
					relation = XPerl_GetBuffButton(self, 1, 0, true)
				end
				if (relation) then
					if (pconf.flip) then
						b:SetPoint("TOPRIGHT", relation, "BOTTOMRIGHT", 0, 0)
					else
						b:SetPoint("TOPLEFT", relation, "BOTTOMLEFT", 0, 0)
					end
				else
					if (pconf.flip) then
						b:SetPoint("TOPRIGHT", 0, -14)
					else
						b:SetPoint("TOPLEFT", 0, -14)
					end
				end
			end,
			buffAnchor1 = function(self, b)
				if (pconf.flip) then
					b:SetPoint("TOPRIGHT", 0, 0)
				else
					b:SetPoint("TOPLEFT", 0, 0)
				end
			end,
		}
	end

	--XPerl_SecureUnitButton_OnLoad(self, nil, nil, nil, XPerl_ShowGenericMenu)
	--XPerl_SecureUnitButton_OnLoad(self.nameFrame, nil, nil, nil, XPerl_ShowGenericMenu)

	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")


	self:SetAttribute("useparent-unit", true)
	self:SetAttribute("unitsuffix", "pet")
	self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("unitsuffix", "pet")

	XPerl_RegisterClickCastFrame(self.nameFrame)
	XPerl_RegisterClickCastFrame(self)

	XPerl_RegisterHighlight(self.highlight, 2)
	XPerl_RegisterPerlFrames(self, {self.nameFrame, self.statsFrame})

	self.FlashFrames = {self.nameFrame, self.statsFrame}

	self:SetScript("OnShow", function(self)
		self.conf = conf.partypet
		--CheckVisiblity()
		XPerl_Party_Pet_UpdateDisplay(self)
		XPerl_Party_SetDebuffLocation(self:GetParent())
	end)
	self:SetScript("OnHide", function(self)
		--CheckVisiblity()
		XPerl_Party_SetDebuffLocation(self:GetParent())
	end)

	self.time = 0

	if (XPerlDB) then
		self.conf = conf.partypet
	end

	XPerl_Party_Pet_Set_Bits1(self)
end

-- XPerl_Party_Pet_CheckPet
-- returns true if full update required (frame shown)

-- XPerl_Party_Pet_UpdateName
local function XPerl_Party_Pet_UpdateName(self)
	if not self.partyid then
		return
	end

	local Partypetname = UnitName(self.partyid)
	if (Partypetname ~= nil) then
		self.nameFrame.text:SetText(Partypetname)
		if (UnitIsPVP(self.ownerid)) then
			self.nameFrame.text:SetTextColor(0, 1, 0)
		else
			self.nameFrame.text:SetTextColor(0.5, 0.5, 1)
		end
	end
end

-- XPerl_Party_Pet_UpdateAbsorbPrediction
local function XPerl_Party_Pet_UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

-- XPerl_Party_Pet_UpdateHealPrediction
local function XPerl_Party_Pet_UpdateHealPrediction(self)
	if pconf.healprediction then
		XPerl_SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

local function XPerl_Party_Pet_UpdateResurrectionStatus(self)
	if (UnitHasIncomingResurrection(self.partyid)) then
		self.statsFrame.resurrect:Show()
	else
		self.statsFrame.resurrect:Hide()
	end
end

-- XPerl_Party_Pet_UpdateHealth
local function XPerl_Party_Pet_UpdateHealth(self)
	local partyid = self.partyid
	if not partyid then
		return
	end

	local health = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid))
	local healthmax = UnitHealthMax(partyid)

	-- PTR region fix
	if not healthmax or healthmax <= 0 then
		if health > 0 then
			healthmax = health
		else
			healthmax = 1
		end
	end

	local healthPct
	if UnitIsDeadOrGhost(partyid) or (health == 0 and healthmax == 0) then -- Probably dead target
		healthPct = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
	elseif health > 0 and healthmax == 0 then -- We have current ho but max hp failed.
		healthmax = health -- Make max hp at least equal to current health
		healthPct = 100 -- And percent 100% cause a number divided by itself is 1, duh.
	else
		healthPct = health / healthmax -- Everything is dandy, so just do it right way.
	end
	--local phealthPct = format("%3.0f", healthPct * 100)

	self.statsFrame.healthBar:SetMinMaxValues(0, healthmax)
	self.statsFrame.healthBar:SetValue(health)
	XPerl_ColourHealthBar(self, healthPct)

	XPerl_Party_Pet_UpdateAbsorbPrediction(self)
	XPerl_Party_Pet_UpdateHealPrediction(self)
	XPerl_Party_Pet_UpdateResurrectionStatus(self)

	if (UnitIsDead(partyid)) then
		self.statsFrame:SetGrey()
		self.statsFrame.healthBar.text:SetText(XPERL_LOC_DEAD)
	else
		if (pconf.healerMode.enable) then
			if (pconf.healerMode.type == 1) then
				self.statsFrame.healthBar.text:SetFormattedText("%d/%d", health - healthmax, healthmax)
			else
				self.statsFrame.healthBar.text:SetText(health - healthmax)
			end
		else
			self.statsFrame.healthBar.text:SetFormattedText("%.0f%%", (100 * (health / healthmax)))
		end

		self.statsFrame.healthBar.text:Show()

		if (self.statsFrame.greyMana) then
			self.statsFrame.greyMana = nil
			XPerl_SetManaBarType(self)
		end
	end
end

-- XPerl_Party_Pet_UpdateMana
local function XPerl_Party_Pet_UpdateMana(self)
	local partyid = self.partyid
	if not partyid then
		return
	end

	local Partypetmana = UnitPower(partyid)
	local Partypetmanamax = UnitPowerMax(partyid)

	-- PTR region fix
	if not Partypetmanamax or Partypetmanamax <= 0 then
		if Partypetmanamax > 0 then
			Partypetmanamax = Partypetmana
		else
			Partypetmanamax = 1
		end
	end

	self.statsFrame.manaBar:SetMinMaxValues(0, Partypetmanamax)
	self.statsFrame.manaBar:SetValue(Partypetmana)

	pmanaPct = (Partypetmana * 100.0) / Partypetmanamax
	pmanaPct =  format("%3.0f", pmanaPct)
	if (XPerl_GetDisplayedPowerType(partyid) >= 1) then
		self.statsFrame.manaBar.text:SetText(Partypetmana)
	else
		self.statsFrame.manaBar.text:SetFormattedText("%.0f%%", (100 * (Partypetmana / Partypetmanamax)))
	end
end

--------------------
-- Buff Functions --
--------------------

-- XPerl_Party_Pet_Buff_UpdateAll
function XPerl_Party_Pet_Buff_UpdateAll(self)
	local partyid = self.partyid
	if not partyid then
		return
	end

	if (petconf.buffs.enable) then
		if (UnitExists(partyid)) then
			self.buffFrame:Show()
			if (XPerlDB) then
				if (not self.conf) then
					self.conf = conf.partypet
				end

				XPerl_Unit_UpdateBuffs(self, nil, nil, petconf.buffs.castble, petconf.debuffs.curable)
			end
		else
			self.buffFrame:Hide()
		end
	else
		self.buffFrame:Hide()
	end

	XPerl_CheckDebuffs(self, partyid)
end

-- XPerl_Party_Pet_UpdateDisplayAll
function XPerl_Party_Pet_UpdateDisplayAll()
	for k, frame in pairs(PartyPetFrames) do
		if (frame:IsShown()) then
			XPerl_Party_Pet_UpdateDisplay(frame)
		end
	end
end

-- XPerl_Party_Pet_UpdateDisplay
function XPerl_Party_Pet_UpdateDisplay(self)
	if not self.partyid then
		return
	end

	XPerl_Party_Pet_UpdateName(self)
	XPerl_Party_Pet_UpdateHealth(self)
	XPerl_Unit_UpdateLevel(self)
	XPerl_SetManaBarType(self)
	XPerl_Party_Pet_UpdateMana(self)
	XPerl_Party_Pet_UpdateCombat(self)
	XPerl_Party_Pet_Buff_UpdateAll(self)
	XPerl_UpdateSpellRange(self)
end

--------------------
-- Click Handlers --
--------------------

-- XPerl_Party_Pet_Update_Control
local function XPerl_Party_Pet_Update_Control(self)
	local partyid = self.partyid
	if (partyid and UnitIsVisible(partyid) and UnitIsCharmed(partyid) and (not IsClassic and not UnitUsingVehicle(self.ownerid))) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- XPerl_Party_Pet_UpdateCombat
function XPerl_Party_Pet_UpdateCombat(self)
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
	XPerl_Party_Pet_Update_Control(self)
end

-- XPerl_Party_Pet_CombatFlash
local function XPerl_Party_Pet_CombatFlash(self, elapsed, argNew, argGreen)
	if (XPerl_CombatFlashSet (self, elapsed, argNew, argGreen)) then
		XPerl_CombatFlashSetFrames(self)
	end
end

-- XPerl_Party_Pet_OnUpdate
function XPerl_Party_Pet_OnUpdate(self, elapsed)
	for unit, frame in pairs(PartyPetFrames) do
		if (frame:IsShown()) then
			--[[local visible = UnitIsVisible(unit)
			if frame.visible ~= visible then
				XPerl_Party_Pet_UpdateDisplay(frame)
				frame.visible = visible
			end]]

			if (conf.combatFlash and frame.PlayerFlash) then
				XPerl_Party_Pet_CombatFlash(frame, elapsed, false)
			end

			if conf.rangeFinder.enabled then
				frame.time = frame.time + elapsed
				if (frame.time > 0.2) then
					frame.time = 0
					XPerl_UpdateSpellRange(frame, nil, false)
				end
			end
		end
	end
end

-------------------
-- Event Handler --
-------------------

-- XPerl_Party_Pet_OnEvent
function XPerl_Party_Pet_OnEvent(self, event, unit, ...)
	local func = XPerl_Party_Pet_Events[event]
	if func then
		if (strfind(event, "^UNIT_") or strfind(event, "^INCOMING_")) then
			local f = PartyPetFrames[unit]
			if f then
				if event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "INCOMING_RESURRECT_CHANGED" then
					if not UnitIsUnit(f.partyid, unit) then
						return
					end

					func(f, unit, ...)
				else
					if not UnitIsUnit(f.partyid, unit) then
						return
					end

					func(f, ...)
				end
			end
		elseif event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE" then
			local pet = string.gsub(unit, "(%a+)(%d+)", "%1pet%2")
			local f = PartyPetFrames[pet]
			if f then
				local unitID = f.partyid
				if unitID == "pet" or unitID == "playerpet" then
					owner = "player"
				else
					owner = string.gsub(unitID, "(%a+)pet(%d+)", "%1%2")
				end

				if owner ~= "player" then
					if not UnitIsUnit(owner, unit) then
						return
					end
				else
					return
				end

				func(f, unit, ...)
			end
		else
			func(unit, ...)
		end
	end
end

-- UNIT_COMBAT
function XPerl_Party_Pet_Events:UNIT_COMBAT(...)
	local action, descriptor, damage, damageType = ...

	if (action == "HEAL") then
		XPerl_Party_Pet_CombatFlash(self, 0, true, true)
	elseif (damage and damage > 0) then
		XPerl_Party_Pet_CombatFlash(self, 0, true)
	end
end

function XPerl_Party_Pet_Events:PET_BATTLE_OPENING_START()
	if (self) then
		self:Hide()
	end
end

function XPerl_Party_Pet_Events:PET_BATTLE_CLOSE()
	if (self) then
		self:Show()
	end
end

-- PLAYER_ENTERING_WORLD
function XPerl_Party_Pet_Events:PLAYER_ENTERING_WORLD()
	XPerl_Party_Pet_UpdateGUIDs()
	XPerl_Party_Pet_UpdateDisplayAll()
end
XPerl_Party_Pet_Events.GROUP_ROSTER_UPDATE = XPerl_Party_Pet_Events.PLAYER_ENTERING_WORLD
XPerl_Party_Pet_Events.UNIT_PET = XPerl_Party_Pet_Events.PLAYER_ENTERING_WORLD

-- UNIT_FLAGS
function XPerl_Party_Pet_Events:UNIT_FLAGS()
	XPerl_Party_Pet_UpdateCombat(self)
end

-- UNIT_NAME_UPDATE
function XPerl_Party_Pet_Events:UNIT_NAME_UPDATE()
	XPerl_Party_Pet_UpdateGUIDs()
	XPerl_Party_Pet_UpdateName(self)
end

-- UNIT_FACTION
function XPerl_Party_Pet_Events:UNIT_FACTION()
	XPerl_Party_Pet_UpdateName(self)
	XPerl_Party_Pet_UpdateCombat(self)
end

-- UNIT_LEVEL
function XPerl_Party_Pet_Events:UNIT_LEVEL()
	XPerl_Unit_UpdateLevel(self)
end

-- UNIT_HEALTH_FREQUENT
function XPerl_Party_Pet_Events:UNIT_HEALTH_FREQUENT()
	XPerl_Party_Pet_UpdateHealth(self)
end

-- UNIT_HEALTH
function XPerl_Party_Pet_Events:UNIT_HEALTH()
	XPerl_Party_Pet_UpdateHealth(self)
end

-- UNIT_MAXHEALTH
function XPerl_Party_Pet_Events:UNIT_MAXHEALTH()
	XPerl_Party_Pet_UpdateHealth(self)
end

-- UNIT_AURA
function XPerl_Party_Pet_Events:UNIT_AURA()
	XPerl_Party_Pet_Buff_UpdateAll(self)
end

-- UNIT_DISPLAYPOWER
function XPerl_Party_Pet_Events:UNIT_DISPLAYPOWER()
	XPerl_SetManaBarType(self)
end

-- UNIT_MANA
function XPerl_Party_Pet_Events:UNIT_MANA()
	XPerl_Party_Pet_UpdateMana(self)
end

XPerl_Party_Pet_Events.UNIT_POWER_FREQUENT = XPerl_Party_Pet_Events.UNIT_MANA
XPerl_Party_Pet_Events.UNIT_MAXPOWER = XPerl_Party_Pet_Events.UNIT_MANA

function XPerl_Party_Pet_Events:PARTY_MEMBER_ENABLE(unit)
	XPerl_Party_Pet_UpdateDisplay(self)
end

function XPerl_Party_Pet_Events:PARTY_MEMBER_DISABLE(unit)
	XPerl_Party_Pet_UpdateDisplay(self)
end

function XPerl_Party_Pet_Events:UNIT_HEAL_PREDICTION(unit)
	if pconf.healprediction then
		XPerl_SetExpectedHealth(self)
	end
end

function XPerl_Party_Pet_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if pconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	end
end

function XPerl_Party_Pet_Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		XPerl_Party_Pet_UpdateResurrectionStatus(self)
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

-- XPerl_Party_Pet_Set_Bits1
function XPerl_Party_Pet_Set_Bits1(self)
	if (not self:GetParent()) then
		self:SetParent(_G["XPerl_party"..self:GetID()])
	end

	if (petconf.name) then
		self.nameFrame:Show()
		self.nameFrame:SetHeight(20)
	else
		self.nameFrame:Hide()
		self.nameFrame:SetHeight(4)
	end

	if (petconf.mana) then
		self:SetHeight(50)
		self.statsFrame:SetHeight(33)
		self.statsFrame.manaBar:Show()
		if (petconf.percent) then
			self.statsFrame.manaBar.text:Show()
		else
			self.statsFrame.manaBar.text:Hide()
		end
	else
		self:SetHeight(40)
		self.statsFrame:SetHeight(23)
		self.statsFrame.manaBar:Hide()
	end

	if (petconf.level) then
		self.nameFrame.level:Show()
	else
		self.nameFrame.level:Hide()
	end

	self:SetScale(petconf.scale)

	XPerl_StatsFrameSetup(self)

	if (self:IsShown()) then
		XPerl_Party_Pet_UpdateDisplay(self)
	end

	local function SetAllBuffs(self, buffs)
		local prevAnchor
		if (pconf.flip) then
			prevAnchor = "TOPRIGHT"
		else
			prevAnchor = "TOPLEFT"
		end
		if (buffs) then
			local prev = self
			for k, v in pairs(buffs) do
				v:ClearAllPoints()
				if (pconf.flip) then
					v:SetPoint("TOPRIGHT", prev, prevAnchor, 0, 0)
				else
					v:SetPoint("TOPLEFT", prev, prevAnchor, 0, 0)
				end
				prev = v
				if (pconf.flip) then
					prevAnchor = "TOPLEFT"
				else
					prevAnchor = "TOPRIGHT"
				end
			end
		end
	end

	SetAllBuffs(self.buffFrame, self.buffFrame.debuff)
	SetAllBuffs(self.buffFrame, self.buffFrame.buff)
	local b = self.buffFrame.buff and self.buffFrame.buff[1]
	local d = self.buffFrame.debuff and self.buffFrame.debuff[1]
	if (b and d) then
		if (pconf.flip) then
			d:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, 0)
		else
			d:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, 0)
		end
	end

	XPerl_ProtectedCall(EnableDisable, self)
end

-- XPerl_Party_Pet_Set_Bits
function XPerl_Party_Pet_Set_Bits()
	for k, v in pairs(AllPetFrames) do
		XPerl_Party_Pet_Set_Bits1(v)
	end

	local function RegisterEvents(self, enable, events)
		for k, v in pairs(events) do
			if (enable) then
				self:RegisterEvent(v)
			else
				self:UnregisterEvent(v)
			end
		end
	end

	RegisterEvents(XPerl_Party_Pet_EventFrame, petconf.mana, {"UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_MANA", "UNIT_DISPLAYPOWER"})
	RegisterEvents(XPerl_Party_Pet_EventFrame, petconf.name, {"UNIT_NAME_UPDATE"})
	RegisterEvents(XPerl_Party_Pet_EventFrame, petconf.name and petconf.level, {"UNIT_LEVEL"})

	XPerl_Party_Pet_EventFrame:RegisterEvent("PARTY_MEMBER_ENABLE")
	XPerl_Party_Pet_EventFrame:RegisterEvent("PARTY_MEMBER_DISABLE")

	XPerl_Register_Prediction(self, pconf, function(guid)
		local frame = XPerl_Party_Pet_GetUnitFrameByGUID(guid)
		if frame then
			return frame.partyid
		end
	end)
end
