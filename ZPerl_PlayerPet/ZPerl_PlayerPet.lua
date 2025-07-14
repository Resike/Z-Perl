-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local XPerl_Player_Pet_Events = {}
local conf, pconf
XPerl_RequestConfig(function(new)
	conf = new
	pconf = new.pet
	if XPerl_Player_Pet then
		XPerl_Player_Pet.conf = pconf
	end
end, "$Revision: @file-revision@ $")

local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC
local IsPandaClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

-- Upvalues
local _G = _G
local format = format
local max = max
local pairs = pairs
local pcall = pcall
local string = string
local tonumber = tonumber

local CreateFrame = CreateFrame
local GetPetHappiness = GetPetHappiness
local InCombatLockdown = InCombatLockdown
local RegisterAttributeDriver = RegisterAttributeDriver
local RegisterStateDriver = RegisterStateDriver
local RegisterUnitWatch = RegisterUnitWatch
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInVehicle = UnitInVehicle
local UnitIsCharmed = UnitIsCharmed
local UnitIsDead = UnitIsDead
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnregisterUnitWatch = UnregisterUnitWatch

local CombatFeedback_Initialize = CombatFeedback_Initialize
local CombatFeedback_OnCombatEvent = CombatFeedback_OnCombatEvent
local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate

local XPerl_Player_Pet_HighlightCallback

-- XPerl_Player_Pet_OnLoad
function XPerl_Player_Pet_OnLoad(self)
	XPerl_SetChildMembers(self)
	self.partyid = "pet"

	XPerl_BlizzFrameDisable(PetFrame)

	local BuffOnUpdate, DebuffOnUpdate, BuffUpdateTooltip, DebuffUpdateTooltip
	BuffUpdateTooltip = XPerl_Unit_SetBuffTooltip
	DebuffUpdateTooltip = XPerl_Unit_SetDeBuffTooltip

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
		debuffSizeMod = 0.3,
		debuffAnchor1 = function(self, b)
			local buff1 = XPerl_GetBuffButton(self, 1, 0, true)
			if pconf.buffs.above then
				b:SetPoint("BOTTOMLEFT", buff1, "TOPLEFT", 0, 0)
			else
				b:SetPoint("TOPLEFT", buff1, "BOTTOMLEFT", 0, 0)
			end
			self.buffSetup.debuffAnchor1 = nil
		end,
		buffAnchor1 = function(self, b)
			if pconf.buffs.above then
				b:SetPoint("BOTTOMLEFT", 0, 0)
			else
				b:SetPoint("TOPLEFT", 0, 0)
			end
			self.buffSetup.buffAnchor1 = nil
		end,
	}

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	--XPerl_SecureUnitButton_OnLoad(self, "pet", nil, PetFrameDropDown, XPerl_ShowGenericMenu)			--PetFrame.menu)
	--XPerl_SecureUnitButton_OnLoad(self.nameFrame, "pet", nil, PetFrameDropDown, XPerl_ShowGenericMenu)	--PetFrame.menu)

	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self.nameFrame:SetAttribute("unit", self.partyid)
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
	self:SetAttribute("unit", self.partyid)

	self.state = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")

	self.state:SetFrameRef("ZPerlPlayerPet", self)

	self.state:Execute([[
		frame = self:GetFrameRef("ZPerlPlayerPet")
	]])

	self.state:SetAttribute("_onstate-petbattleupdate", [[
		if newstate == "inpetbattle" then
			frame:Hide()
		else
			frame:Show()
		end
	]])

	RegisterStateDriver(self.state, "petbattleupdate", "[petbattle] inpetbattle; none")

	--RegisterAttributeDriver(self.nameFrame, "unit", "[vehicleui] player; pet")
	RegisterAttributeDriver(self, "unit", "[vehicleui] player; pet")

	XPerl_RegisterClickCastFrame(self.nameFrame)
	XPerl_RegisterClickCastFrame(self)

	--RegisterUnitWatch(self)
	local events = {
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		"UNIT_LEVEL",
		"UNIT_POWER_FREQUENT",
		"UNIT_MAXPOWER",
		"UNIT_DISPLAYPOWER",
		"UNIT_NAME_UPDATE",
		"UNIT_FACTION",
		"UNIT_PORTRAIT_UPDATE",
		"UNIT_FLAGS",
		"UNIT_AURA",
		"UNIT_PET",
		"UNIT_HAPPINESS",
		"PET_ATTACK_START",
		"UNIT_COMBAT",
		"VARIABLES_LOADED",
		--"PLAYER_REGEN_ENABLED",
		"PLAYER_ENTERING_WORLD",
		"UNIT_ENTERED_VEHICLE",
		"UNIT_EXITING_VEHICLE",
		"UNIT_THREAT_LIST_UPDATE",
		"PLAYER_TARGET_CHANGED",
		"UNIT_TARGET",
		--"PET_BATTLE_OPENING_START",
		--"PET_BATTLE_CLOSE"
		"INCOMING_RESURRECT_CHANGED",
	}
	local _, classFileName = UnitClass("player")
	for i, event in pairs(events) do
		if string.find(event, "^UNIT_") or string.find(event, "^INCOMING") then
			if event == "UNIT_THREAT_LIST_UPDATE" then
				if pcall(self.RegisterUnitEvent, self, event, "target") then
					self:RegisterUnitEvent(event, "target")
				end
			elseif event == "UNIT_PET" or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITING_VEHICLE" then
				if pcall(self.RegisterUnitEvent, self, event, "player") then
					self:RegisterUnitEvent(event, "player")
				end
			elseif event == "UNIT_TARGET" then
				if pcall(self.RegisterUnitEvent, self, event, "pet") then
					self:RegisterUnitEvent(event, "pet")
				end
			elseif IsVanillaClassic and event == "UNIT_HAPPINESS" and classFileName == "HUNTER" then
				if pcall(self.RegisterUnitEvent, self, event, "pet") then
					self:RegisterUnitEvent(event, "pet")
				end
			else
				if pcall(self.RegisterUnitEvent, self, event, "pet", "player") then
					self:RegisterUnitEvent(event, "pet", "player")
				end
			end
		else
			if pcall(self.RegisterEvent, self, event) then
				self:RegisterEvent(event)
			end
		end
	end

	self.time = 0

	-- Set here to reduce amount of function calls made
	self:SetScript("OnEvent", XPerl_Player_Pet_OnEvent)
	self:SetScript("OnUpdate", XPerl_Player_Pet_OnUpdate)
	--[[if (FOM_FeedButton) then
		self:SetScript("OnShow", function(self)
			XPerl_Unit_UpdatePortrait(self)
			XPerl_ProtectedCall(Set_FOM_FeedButton)
		end)
	else
		self:SetScript("OnShow", XPerl_Unit_UpdatePortrait)
	end]]
	self:SetScript("OnShow", XPerl_Unit_UpdatePortrait)

	if XPerl_ArcaneBar_RegisterFrame then
		XPerl_ArcaneBar_RegisterFrame(self.nameFrame, (not IsVanillaClassic and UnitHasVehicleUI("player")) and "player" or "pet")
	end

	XPerl_RegisterHighlight(self.highlight, 2)
	XPerl_RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.portraitFrame, self.levelFrame})
	self.FlashFrames = {self.nameFrame, self.levelFrame, self.statsFrame, self.portraitFrame}

	XPerl_RegisterOptionChanger(XPerl_Player_Pet_Set_Bits, self)

	XPerl_Highlight:Register(XPerl_Player_Pet_HighlightCallback, self)

	if XPerlDB then
		self.conf = XPerlDB.pet
	end

	self.GetBuffSpacing = function(self)
		local w = self.statsFrame:GetWidth()
		if self.portraitFrame and self.portraitFrame:IsShown() then
			w = w - 2 + self.portraitFrame:GetWidth()
		end
		if not self.buffSpacing then
			--self.buffSpacing = XPerl_GetReusableTable()
			self.buffSpacing = { }
		end
		self.buffSpacing.rowWidth = w
		self.buffSpacing.smallRowHeight = 0
		self.buffSpacing.smallRowWidth = w
	end
	XPerl_Player_Pet_OnLoad = nil
end

-- XPerl_Player_Pet_HighlightCallback
function XPerl_Player_Pet_HighlightCallback(self, updateGUID)
	if updateGUID == UnitGUID("pet") then
		XPerl_Highlight:SetHighlight(self, updateGUID)
	end
end

-- XPerl_Player_Pet_UpdateName
local function XPerl_Player_Pet_UpdateName(self)
	local partyid = self.partyid
	local petname = UnitName(partyid)

	if petname == UNKNOWN then
		self.nameFrame.text:SetText("")
	else
		self.nameFrame.text:SetText(petname)
	end

	if partyid == "pet" then
		local c = conf.colour.reaction.none
		self.nameFrame.text:SetTextColor(c.r, c.g, c.b, conf.transparency.text)
	elseif not UnitIsFriend("player", "pet") then		-- Pet or you charmed
		local c = conf.colour.reaction.enemy
		self.nameFrame.text:SetTextColor(c.r, c.g, c.b, conf.transparency.text)
	else
		XPerl_ColourFriendlyUnit(self.nameFrame.text, partyid)
	end
end

-- XPerl_Player_Pet_UpdateLevel
local function XPerl_Player_Pet_UpdateLevel(self)
	XPerl_Unit_UpdateLevel(self)
end

-- XPerl_Player_Pet_UpdateAbsorbPrediction
local function XPerl_Player_Pet_UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

-- XPerl_Player_Pet_UpdateHotsPrediction
local function XPerl_Player_Pet_UpdateHotsPrediction(self)
	if pconf.absorbs then
		XPerl_SetExpectedHots(self)
	else
		self.statsFrame.expectedHots:Hide()
	end
end

-- XPerl_Player_Pet_UpdateHealPrediction
local function XPerl_Player_Pet_UpdateHealPrediction(self)
	if pconf.healprediction then
		XPerl_SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

local function XPerl_Player_Pet_UpdateResurrectionStatus(self)
	if UnitHasIncomingResurrection(self.partyid) then
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

-- XPerl_Player_Pet_UpdateHealth
local function XPerl_Player_Pet_UpdateHealth(self)
	local partyid = self.partyid
	local pethealth = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid))
	local pethealthmax = UnitHealthMax(partyid)

	XPerl_SetHealthBar(self, pethealth, pethealthmax)

	XPerl_Player_Pet_UpdateAbsorbPrediction(self)
	XPerl_Player_Pet_UpdateHotsPrediction(self)
	XPerl_Player_Pet_UpdateHealPrediction(self)
	XPerl_Player_Pet_UpdateResurrectionStatus(self)

	if UnitIsDead(partyid) then
		self.statsFrame.healthBar.text:SetText(XPERL_LOC_DEAD)
		self.statsFrame.manaBar.text:Hide()
	end
end

-- XPerl_Player_Pet_UpdateMana()
local function XPerl_Player_Pet_UpdateMana(self)
	local partyid = self.partyid
	local petmana = UnitPower(partyid)
	local petmanamax = UnitPowerMax(partyid)

	self.statsFrame.manaBar:SetMinMaxValues(0, petmanamax)
	self.statsFrame.manaBar:SetValue(petmana)

	self.statsFrame.manaBar.text:SetFormattedText("%d/%d", petmana, petmanamax)

	if pconf.values then
		self.statsFrame.manaBar.text:Show()
	end
end

-- XPerl_Player_Pet_CombatFlash
local function XPerl_Player_Pet_CombatFlash(self, elapsed, argNew, argGreen)
	if XPerl_CombatFlashSet(self, elapsed, argNew, argGreen) then
		XPerl_CombatFlashSetFrames(self)
	end
end

-- XPerl_Player_Pet_OnUpdate
function XPerl_Player_Pet_OnUpdate(self, elapsed)
	if pconf.hitIndicator and pconf.portrait then
		CombatFeedback_OnUpdate(self, elapsed)
	end
	if self.PlayerFlash then
		XPerl_Player_Pet_CombatFlash(self, elapsed, false)
	end
end

--------------------
-- Buff Functions --
--------------------
local function XPerl_Player_Pet_Buff_UpdateAll(self)
	local partyid = self.partyid
	if UnitExists(partyid) then
		XPerl_Unit_UpdateBuffs(self)
		XPerl_Unit_BuffPositions(self, self.buffFrame.buff, self.buffFrame.debuff, self.conf.buffs.size, self.conf.debuffs.size)
		XPerl_CheckDebuffs(self, partyid)
	end
end

---------------
-- Happiness --
---------------
local function XPerl_Player_Pet_SetHappiness(self)
	if not IsVanillaClassic then
		return
	end

	local happiness, damagePercentage, loyaltyRate = GetPetHappiness()
	if not happiness then
		happiness = 3
	end

	local icon = self.happyFrame.icon
	icon.tex:SetTexCoord(0.5625 - (0.1875 * happiness), 0.75 - (0.1875 * happiness), 0, 0.359375)

	if pconf.happiness.enable and (not pconf.happiness.onlyWhenSad or happiness < 3) then
		self.happyFrame:Show()

		icon.tooltip = _G[("PET_HAPPINESS"..happiness)]
		icon.tooltipDamage = format(PET_DAMAGE_PERCENTAGE, damagePercentage)
		if loyaltyRate < 0 then
			icon.tooltipLoyalty = LOSING_LOYALTY
		elseif (loyaltyRate > 0) then
			icon.tooltipLoyalty = GAINING_LOYALTY
		else
			icon.tooltipLoyalty = nil
		end

		if pconf.happiness.flashWhenSad and happiness < 3 then
			XPerl_FrameFlash(self.happyFrame)
		else
			XPerl_FrameFlashStop(self.happyFrame)
		end
	else
		XPerl_FrameFlashStop(self.happyFrame)
		self.happyFrame:Hide()
	end
end

-- XPerl_Player_Pet_Update_Control
local function XPerl_Player_Pet_Update_Control(self)
	if UnitIsCharmed(self.partyid) and UnitIsPlayer(self.partyid) and (not IsVanillaClassic and not UnitInVehicle("player") or true) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- XPerl_Player_Pet_UpdateCombat
local function XPerl_Player_Pet_UpdateCombat(self)
	local partyid = self.partyid
	if UnitExists(partyid) then
		if (UnitAffectingCombat(partyid)) then
			self.nameFrame.combatIcon:Show()
		else
			self.nameFrame.combatIcon:Hide()
		end
		XPerl_Player_Pet_Update_Control(self)
	end
end

-- XPerl_Player_Pet_UpdateDisplay
function XPerl_Player_Pet_UpdateDisplay(self)
	local unit = self:GetAttribute("unit")
	if unit ~= self.partyid then
		self.portraitFrame:SetAlpha(0)
		self.nameFrame:SetAlpha(0)
		self.statsFrame:SetAlpha(0)
		self.levelFrame:SetAlpha(0)
		self.buffFrame:SetAlpha(0)
		self.debuffFrame:SetAlpha(0)
	else
		self.portraitFrame:SetAlpha(1)
		self.nameFrame:SetAlpha(1)
		self.statsFrame:SetAlpha(1)
		self.levelFrame:SetAlpha(1)
		self.buffFrame:SetAlpha(1)
		self.debuffFrame:SetAlpha(1)
	end
	XPerl_Unit_UpdatePortrait(self)
	XPerl_Player_Pet_UpdateName(self)
	XPerl_Player_Pet_UpdateHealth(self)
	XPerl_SetManaBarType(self)
	if XPerl_Player_Pet_SetHappiness then
		XPerl_Player_Pet_SetHappiness(self)
	end
	XPerl_Player_Pet_UpdateMana(self)
	XPerl_Player_Pet_UpdateLevel(self)
	XPerl_Player_Pet_Buff_UpdateAll(self)
	XPerl_Player_Pet_UpdateCombat(self)
end

-------------------
-- Event Handler --
-------------------
function XPerl_Player_Pet_OnEvent(self, event, unit, ...)
	if string.find(event, "^UNIT_") then
		if unit == "pet" or unit == "player" then
			if event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" or event == "UNIT_COMBAT"  then
				XPerl_Player_Pet_Events[event](self, unit, ...)
			else
				XPerl_Player_Pet_Events[event](self, ...)
			end
		end
	else
		XPerl_Player_Pet_Events[event](self, event, unit, ...)
	end
end

-- VARIABLES_LOADED
function XPerl_Player_Pet_Events:VARIABLES_LOADED()
	local _, classFileName = UnitClass("player")
	if not classFileName == "HUNTER" then
		XPerl_Player_Pet_Events.UNIT_HAPPINESS = nil
		XPerl_Player_Pet_SetHappiness = nil
	end

	XPerl_Player_Pet_Events.VARIABLES_LOADED = nil
end

-- UNIT_AURA
function XPerl_Player_Pet_Events:UNIT_AURA()
	XPerl_Player_Pet_Buff_UpdateAll(self)
end

-- UNIT_PET
function XPerl_Player_Pet_Events:UNIT_PET()
	if conf then		-- DK can issue very early UNIT_PET, long before PEW. We refresh on entering world regardless
		--self.partyid = UnitHasVehicleUI("player") and "player" or "pet"
		XPerl_Player_Pet_UpdateDisplay(self)
	end
end

--[[function XPerl_Player_Pet_Events:PET_BATTLE_OPENING_START()
	if (UnitExists("pet")) then
		UnregisterUnitWatch(self)
		self:Hide()
	end
end

function XPerl_Player_Pet_Events:PET_BATTLE_CLOSE()
	if (UnitExists("pet")) then
		if not InCombatLockdown() then
			RegisterUnitWatch(self)
		end
		XPerl_ProtectedCall(Show, self)
	end
end]]

XPerl_Player_Pet_Events.PET_STABLE_SHOW = XPerl_Player_Pet_Events.UNIT_PET

-- UNIT_NAME_UPDATE
function XPerl_Player_Pet_Events:UNIT_NAME_UPDATE()
	XPerl_Player_Pet_UpdateName(self)
end

-- UNIT_PORTRAIT_UPDATE
function XPerl_Player_Pet_Events:UNIT_PORTRAIT_UPDATE()
	XPerl_Unit_UpdatePortrait(self, true)
end

-- UNIT_HEALTH_FREQUENT
function XPerl_Player_Pet_Events:UNIT_HEALTH_FREQUENT()
	XPerl_Player_Pet_UpdateHealth(self)
end

-- UNIT_HEALTH
function XPerl_Player_Pet_Events:UNIT_HEALTH()
	XPerl_Player_Pet_UpdateHealth(self)
end

-- UNIT_MAXHEALTH
function XPerl_Player_Pet_Events:UNIT_MAXHEALTH()
	XPerl_Player_Pet_UpdateHealth(self)
end

function XPerl_Player_Pet_Events:UNIT_POWER_FREQUENT()
	XPerl_Player_Pet_UpdateMana(self)
	XPerl_Player_Pet_UpdateCombat(self)
end

function XPerl_Player_Pet_Events:UNIT_MAXPOWER()
	XPerl_Player_Pet_UpdateMana(self)
	XPerl_Player_Pet_UpdateCombat(self)
end

-- UNIT_LEVEL
function XPerl_Player_Pet_Events:UNIT_LEVEL()
	XPerl_Player_Pet_UpdateLevel(self)
end

-- UNIT_DISPLAYPOWER
function XPerl_Player_Pet_Events:UNIT_DISPLAYPOWER()
	XPerl_SetManaBarType(self)
end

-- UNIT_HAPPINESS
function XPerl_Player_Pet_Events:UNIT_HAPPINESS()
	XPerl_Player_Pet_SetHappiness(self)
	XPerl_Player_Pet_UpdateCombat(self)
end

-- PET_ATTACK_START
function XPerl_Player_Pet_Events:PET_ATTACK_START()
	XPerl_Player_Pet_UpdateCombat(self)
end

-- UNIT_COMBAT
function XPerl_Player_Pet_Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end

	if pconf.hitIndicator and pconf.portrait then
		CombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
	end

	if action == "HEAL" then
		XPerl_Player_Pet_CombatFlash(XPerl_Player_Pet, 0, true, true)
	elseif (damage and damage > 0) then
		XPerl_Player_Pet_CombatFlash(XPerl_Player_Pet, 0, true)
	end
end

-- UNIT_FACTION
function XPerl_Player_Pet_Events:UNIT_FACTION()
	XPerl_Player_Pet_UpdateName(self)
	XPerl_Player_Pet_UpdateCombat(self)
end

XPerl_Player_Pet_Events.UNIT_FLAGS = XPerl_Player_Pet_Events.UNIT_FACTION

-- PLAYER_REGEN_ENABLED
function XPerl_Player_Pet_Events:PLAYER_REGEN_ENABLED()
	if self:GetAttribute("unit") ~= self.partyid then
		self:SetAttribute("unit", self.partyid)
	end
end

-- PLAYER_ENTERING_WORLD
function XPerl_Player_Pet_Events:PLAYER_ENTERING_WORLD()
	if not IsVanillaClassic and UnitHasVehicleUI("player") then
		self.partyid = "player"
		self.unit = self.partyid
		self:SetAttribute("unit", "player")
	else
		self.partyid = "pet"
		self.unit = self.partyid
		self:SetAttribute("unit", "pet")
	end
end

-- UNIT_ENTERED_VEHICLE
function XPerl_Player_Pet_Events:UNIT_ENTERED_VEHICLE(showVehicle)
	if showVehicle then
		self.partyid = "player"
		self.unit = self.partyid
		if XPerl_ArcaneBar_SetUnit then
			XPerl_ArcaneBar_SetUnit(self.nameFrame, "player")
		end
		--[[if (not InCombatLockdown()) then
			self:SetAttribute("unit", "player")
		end]]
		XPerl_Player_Pet_UpdateDisplay(self)
	end
end

-- UNIT_EXITING_VEHICLE
function XPerl_Player_Pet_Events:UNIT_EXITING_VEHICLE()
	if self.partyid ~= "pet" then
		self.partyid = "pet"
		self.unit = self.partyid
		if (XPerl_ArcaneBar_SetUnit) then
			XPerl_ArcaneBar_SetUnit(self.nameFrame, "pet")
		end
		--[[if (not InCombatLockdown()) then
			self:SetAttribute("unit", "pet")
		end]]
		XPerl_Player_Pet_UpdateDisplay(self)
	end
end

function XPerl_Player_Pet_Events:UNIT_THREAT_LIST_UPDATE()
	XPerl_Unit_ThreatStatus(self)
end

function XPerl_Player_Pet_Events:PLAYER_TARGET_CHANGED()
	XPerl_Unit_ThreatStatus(self, nil, true)
end
XPerl_Player_Pet_Events.UNIT_TARGET = XPerl_Player_Pet_Events.PLAYER_TARGET_CHANGED

-- PLAYER_REGEN_DISABLED
local virtual
function XPerl_Player_Pet_Events:PLAYER_REGEN_DISABLED()
	if virtual then
		virtual = nil
		RegisterUnitWatch(XPerl_Player_Pet)
		if UnitExists("pet") then
			XPerl_Player_Pet:Show()
			XPerl_Player_Pet_UpdateDisplay(XPerl_Player_Pet)
		else
			XPerl_Player_Pet:Hide()
		end

		if XPerl_PetTarget then
			RegisterUnitWatch(XPerl_PetTarget)
			if (UnitExists("pettarget")) then
				XPerl_PetTarget:Show()
				XPerl_TargetTarget_UpdateDisplay(XPerl_PetTarget)
			else
				XPerl_PetTarget:Hide()
			end
		end
	end
end

function XPerl_Player_Pet_Events:UNIT_HEAL_PREDICTION(unit)
	if pconf.healprediction and unit == self.partyid then
		XPerl_SetExpectedHealth(self)
	end
	if not IsPandaClassic then
		return
	end
	if pconf.hotPrediction and unit == self.partyid then
		XPerl_SetExpectedHots(self)
	end
end

function XPerl_Player_Pet_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if pconf.absorbs and unit == self.partyid then
		XPerl_SetExpectedAbsorbs(self)
	end
end

function XPerl_Player_Pet_Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		XPerl_Player_Pet_UpdateResurrectionStatus(self)
	end
end

-- XPerl_Player_Pet_SetWidth
function XPerl_Player_Pet_SetWidth(self)
	pconf.size.width = max(0, pconf.size.width or 0)
	self.statsFrame:SetWidth(80 + pconf.size.width)
	self.nameFrame:SetWidth(80 + pconf.size.width)
	self:SetScale(pconf.scale)
	XPerl_StatsFrameSetup(self, nil, 2)
	XPerl_SavePosition(self, true)
end

-- XPerl_Player_Pet_Virtual
function XPerl_Player_Pet_Virtual(show)
	if not InCombatLockdown() then
		if show then
			if not virtual then
				virtual = true
				if not UnitExists("pet") then
					XPerl_Player_Pet:RegisterEvent("PLAYER_REGEN_DISABLED")
					UnregisterUnitWatch(XPerl_Player_Pet)
					XPerl_Player_Pet:Show()
					XPerl_Player_Pet.nameFrame.text:SetText(PET)
					XPerl_Player_Pet.statsFrame.healthBar.text:SetText("")
					XPerl_Player_Pet.statsFrame.manaBar.text:SetText("")
					XPerl_Player_Pet:SetAlpha(0.5)
				end

				if XPerl_PetTarget and not UnitExists("pettarget") then
					XPerl_PetTarget.virtual = true
					UnregisterUnitWatch(XPerl_PetTarget)
					XPerl_PetTarget:Show()
					XPerl_PetTarget.nameFrame.text:SetText(PET.." "..TARGET)
					XPerl_PetTarget.statsFrame.healthBar.text:SetText("")
					XPerl_PetTarget.statsFrame.manaBar.text:SetText("")
					XPerl_PetTarget.statsFrame.healthBar.percent:SetText("")
					XPerl_PetTarget.statsFrame.manaBar.percent:SetText("")
					XPerl_PetTarget:SetAlpha(0.5)
				end
			end
		else
			if virtual then
				virtual = nil
				RegisterUnitWatch(XPerl_Player_Pet)
				if XPerl_PetTarget then
					XPerl_PetTarget.virtual = nil
					if (XPerl_PetTarget.conf.enable) then
						RegisterUnitWatch(XPerl_PetTarget)
						XPerl_PetTarget:Hide()
					end
				end
				XPerl_Player_Pet:UnregisterEvent("PLAYER_REGEN_DISABLED")
			end
		end
	end
end

-- XPerl_Player_Pet_Set_Bits
function XPerl_Player_Pet_Set_Bits(self)
	if not virtual then
		RegisterUnitWatch(self)
	end

	if pconf.portrait then
		self.portraitFrame:Show()
		self.portraitFrame:SetWidth(50)
		self.statsFrame.resurrect:Hide()
	else
		self.portraitFrame:Hide()
		self.portraitFrame:SetWidth(3)
	end

	if pconf.name then
		self.nameFrame:Show()
		self.nameFrame:SetHeight(24)
	else
		self.nameFrame:Hide()
		self.nameFrame:SetHeight(2)
	end

	if pconf.name or pconf.portrait then
		if pconf.level then
			self.levelFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPLEFT", 2, 0)
		end
	else
		if pconf.level then
			self.levelFrame:SetPoint("TOPRIGHT", self.statsFrame, "TOPLEFT", 2, 0)
		end
	end

	if pconf.level then
		self.levelFrame:Show()
	else
		self.levelFrame:Hide()
	end

	self.buffOptMix = nil
	self.buffFrame:ClearAllPoints()
	if pconf.buffs.above then
		if pconf.portrait then
			self.buffFrame:SetPoint("BOTTOMLEFT", self.portraitFrame, "TOPLEFT", 3, 0)
		else
			self.buffFrame:SetPoint("BOTTOMLEFT", self.nameFrame, "TOPLEFT", 3, 0)
		end
	else
		if not pconf.extendPortrait and (not pconf.portrait or not pconf.name) then
			self.buffFrame:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 3, 0)
		else
			self.buffFrame:SetPoint("TOPLEFT", self.portraitFrame, "BOTTOMLEFT", 3, 0)
		end
	end

	if pconf.values then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
	else
		self.statsFrame.healthBar.text:Hide()
		self.statsFrame.manaBar.text:Hide()
	end

	self.portraitFrame:SetHeight(56 + (pconf.extendPortrait and 1 or 0) * 10)

	self.highlight:ClearAllPoints()
	if pconf.portrait or pconf.name then
		self.highlight:SetPoint("BOTTOMLEFT", self.portraitFrame)
	else
		self.highlight:SetPoint("BOTTOMLEFT", self.statsFrame)
	end
	self.highlight:SetPoint("TOPRIGHT", self.nameFrame)

	pconf.buffs.size = tonumber(pconf.buffs.size) or 20
	XPerl_SetBuffSize(self)

	XPerl_Register_Prediction(self, pconf, function(guid)
		if guid == UnitGUID("pet") then
			return "pet"
		end
	end, "pet", "player")

	XPerl_Player_Pet_SetWidth(self)

	if self:IsShown() then
		XPerl_Player_Pet_UpdateDisplay(self)
	end
end
