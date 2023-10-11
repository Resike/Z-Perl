-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local XPerl_Target_Events = { }
local conf, tconf, fconf
XPerl_RequestConfig(function(new)
	conf = new
	tconf = conf.target
	fconf = conf.focus
	if (XPerl_Target) then
		XPerl_Target.conf = conf.target
	end
	if (XPerl_Focus) then
		XPerl_Focus.conf = conf.focus
	end
	if (XPerl_TargetTarget) then
		XPerl_TargetTarget.conf = conf.targettarget
	end
	if (XPerl_FocusTarget) then
		XPerl_FocusTarget.conf = conf.focustarget
	end
	if (XPerl_PetTarget) then
		XPerl_PetTarget.conf = conf.pettarget
	end
end, "$Revision: @file-revision@ $")

local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC
local IsWrathClassic = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local LCD = IsVanillaClassic and LibStub and LibStub("LibClassicDurations", true)
if LCD then
	LCD.RegisterCallback("ZPerl", "UNIT_BUFF", function(event, unit)
		if unit == "target" or unit == "focus" then
			XPerl_Target_Events:UNIT_AURA(event, unit)
		end
	end)
end

-- Upvalues
local _G = _G
local bit_band = bit.band
local format = format
local max = max
local pairs = pairs
local select = select
local string = string
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

local CanInspect = CanInspect
local CheckInteractDistance = CheckInteractDistance
local GetComboPoints = GetComboPoints
local GetDifficultyColor = GetDifficultyColor or GetQuestDifficultyColor
local GetInspectSpecialization = GetInspectSpecialization
local GetLootMethod = GetLootMethod
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpecializationInfoByID = GetSpecializationInfoByID
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local NotifyInspect = NotifyInspect
local PlaySound = PlaySound
local RegisterUnitWatch = RegisterUnitWatch
local UnitAffectingCombat = UnitAffectingCombat
local UnitBattlePetType = UnitBattlePetType
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitClassBase = UnitClassBase
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitInVehicle = UnitInVehicle
local UnitIsAFK = UnitIsAFK
local UnitIsBattlePetCompanion = UnitIsBattlePetCompanion
local UnitIsCharmed = UnitIsCharmed
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitIsMercenary = UnitIsMercenary
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitIsWildBattlePet = UnitIsWildBattlePet
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPlayerControlled = UnitPlayerControlled
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnregisterUnitWatch = UnregisterUnitWatch

local percD = "%d"..PERCENT_SYMBOL
local buffSetup
local lastInspectPending = 0
local mobhealth

local feignDeath = GetSpellInfo(5384)

----------------------
-- Loading Function --
----------------------
function XPerl_Target_OnLoad(self, partyid)
	self:RegisterForClicks("AnyUp")
	self:RegisterForDrag("LeftButton")
	XPerl_SetChildMembers(self)

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	self.hitIndicator.text:SetPoint("CENTER", self.portraitFrame, "CENTER", 0, 0)

	local events = {
		"UNIT_COMBAT",
		"PLAYER_FLAGS_CHANGED",
		"UNIT_CONNECTION",
		"UNIT_PHASE",
		"RAID_TARGET_UPDATE",
		"GROUP_ROSTER_UPDATE",
		"PARTY_LEADER_CHANGED",
		"PARTY_LOOT_METHOD_CHANGED",
		"UNIT_THREAT_LIST_UPDATE",
		"UNIT_FACTION",
		"UNIT_FLAGS",
		"UNIT_CLASSIFICATION_CHANGED",
		"UNIT_PORTRAIT_UPDATE",
		"UNIT_AURA",
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		--"PET_BATTLE_HEALTH_CHANGED",
		--"UPDATE_SUMMONPETS_ACTION",
		"UNIT_POWER_FREQUENT",
		"UNIT_MAXPOWER",
		"UNIT_LEVEL",
		"UNIT_DISPLAYPOWER",
		"UNIT_NAME_UPDATE",
		--"PET_BATTLE_OPENING_START"
		--"PET_BATTLE_CLOSE",
		"INCOMING_RESURRECT_CHANGED",
	}

	for i, event in pairs(events) do
		if string.find(event, "^UNIT_") or string.find(event, "^INCOMING") then
			if pcall(self.RegisterUnitEvent, self, event, partyid) then
				if event == "UNIT_MAXPOWER" then
					self:RegisterUnitEvent(event, partyid, "player")
				else
					self:RegisterUnitEvent(event, partyid)
				end
			end
		else
			if pcall(self.RegisterEvent, self, event) then
				self:RegisterEvent(event)
			end
		end
	end

	XPerl_Highlight:Register(XPerl_Target_HighlightCallback, self)

	self.partyid = partyid
	if (partyid == "target") then
		XPerl_BlizzFrameDisable(TargetFrame)
		XPerl_BlizzFrameDisable(TargetofTargetFrame)

		self.statsFrame.focusTarget:SetVertexColor(0.7, 1, 1, 0.5)

		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		if not IsVanillaClassic then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		end

		if (XPerl_Target_Events.INSPECT_READY) then
			self:RegisterEvent("INSPECT_READY")
		end
		self.combatMask = 0x00010000
	else
		XPerl_BlizzFrameDisable(FocusFrame)

		if not IsVanillaClassic then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		end
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		--self:SetScript("OnShow", XPerl_Target_UpdateDisplay)
		self.combatMask = 0x00020000
	end
	--self:RegisterEvent("UNIT_COMBO_POINTS") -- Not a standard unit event, becuase we want events for "player" even tho it's "target" or "focus" unit frame
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	self.nameFrame.cpMeter:SetFrameLevel(2)
	local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
	self.nameFrame.cpMeter:SetMinMaxValues(0, IsClassic and 5 or maxComboPoints)
	self.nameFrame.cpMeter:GetStatusBarTexture():SetHorizTile(false)
	self.nameFrame.cpMeter:GetStatusBarTexture():SetVertTile(false)

	local BuffOnUpdate, DebuffOnUpdate, BuffUpdateTooltip, DebuffUpdateTooltip
	BuffUpdateTooltip = XPerl_Unit_SetBuffTooltip
	DebuffUpdateTooltip = XPerl_Unit_SetDeBuffTooltip

	if (buffSetup) then
		self.buffSetup = buffSetup
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
			debuffSizeMod = 0.2,
			debuffAnchor1 = function(self, b)
				b:SetPoint("TOPLEFT", 0, 0)
			end,
		}
		self.buffSetup.buffAnchor1 = self.buffSetup.debuffAnchor1
		buffSetup = self.buffSetup
	end

	--XPerl_SecureUnitButton_OnLoad(self.nameFrame, partyid, nil, TargetFrameDropDown, XPerl_ShowGenericMenu)		--TargetFrame.menu)
	--XPerl_SecureUnitButton_OnLoad(self, partyid, nil, TargetFrameDropDown, XPerl_ShowGenericMenu)				--TargetFrame.menu)
	--self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self.nameFrame:SetAttribute("unit", partyid)

	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
	self:SetAttribute("unit", partyid)

	XPerl_RegisterClickCastFrame(self.nameFrame)
	XPerl_RegisterClickCastFrame(self)

	--RegisterUnitWatch(self)

	--self.PlayerFlash = 0
	self.perlBuffs, self.perlDebuffs, self.time = 0, 0, 0

	--XPerl_InitFadeFrame(self)

	if (partyid == "target" and XPerl_Target_AssistFrame) then
		-- Since target module is loaded after raid helper, we have to attach this manually
		-- because the target frame did not exist when this frame was created
		XPerl_Target_AssistFrame:SetParent(self)
		XPerl_Target_AssistFrame:ClearAllPoints()
		XPerl_Target_AssistFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, -20)
		XPerl_Target_AssistFrame:Raise()
	end

	XPerl_RegisterHighlight(self.highlight, 3)
	XPerl_RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.levelFrame, self.portraitFrame, self.typeFramePlayer, self.creatureTypeFrame, self.bossFrame, self.cpFrame})

	self.FlashFrames = {self.portraitFrame, self.nameFrame, self.levelFrame, self.statsFrame, self.bossFrame, self.typeFramePlayer, self.typeFrame}

	if (XPerl_ArcaneBar_RegisterFrame) then
		XPerl_ArcaneBar_RegisterFrame(self.nameFrame, partyid)
	end

	if (XPerlDB) then
		self.conf = XPerlDB[partyid]
	end

	XPerl_RegisterOptionChanger(XPerl_Target_Set_Bits, self)

	if (XPerl_Target and XPerl_Focus) then
		XPerl_Target_OnLoad = nil
	end
end

-- XPerl_Raid_HighlightCallback
function XPerl_Target_HighlightCallback(self, updateGUID)
	if (UnitGUID(self.partyid) == updateGUID and UnitIsFriend("player", self.partyid)) then
		XPerl_Highlight:SetHighlight(self, updateGUID)
	end
end

--------------------
-- Buff Functions --
--------------------

-- XPerl_Target_BuffPositions
local function XPerl_Target_BuffPositions(self)
	if (self.partyid and UnitCanAttack("player", self.partyid)) then
		XPerl_Unit_BuffPositions(self, self.buffFrame.debuff, self.buffFrame.buff, self.conf.debuffs.size, self.conf.buffs.size)
	else
		XPerl_Unit_BuffPositions(self, self.buffFrame.buff, self.buffFrame.debuff, self.conf.buffs.size, self.conf.debuffs.size)
	end
end

-- XPerl_Targets_BuffUpdate
function XPerl_Targets_BuffUpdate(self)
	if (not self.conf.buffs.enable and not self.conf.debuffs.enable) then
		self.buffFrame:Hide()
		self.debuffFrame:Hide()
	else
		XPerl_Unit_UpdateBuffs(self, nil, nil, self.conf.buffs.castable, self.conf.debuffs.curable)
		XPerl_Target_BuffPositions(self)
	end
end

-- GetComboColour
local function GetComboColour(num)
	if (num == 10) then
		return 0.3, 0, 1
	elseif (num == 9) then
		return 0.5, 0, 1
	elseif (num == 8) then
		return 0.7, 0, 1
	elseif (num == 7) then
		return 1, 0, 1
	elseif (num == 6) then
		return 1, 0, 0.5
	elseif (num == 5) then
		return 1, 0, 0
	elseif (num == 4) then
		return 1, 0.5, 0
	elseif (num == 3) then
		return 1, 1, 0
	elseif (num == 2) then
		return 0.5, 1, 0
	elseif (num == 1) then
		return 0, 1, 0
	end
end

---------------
-- Combo Points
---------------
function XPerl_Target_UpdateCombo(self)
	local comboPoints = IsClassic and GetComboPoints("player", "target") or UnitPower(UnitHasVehicleUI("player") and "vehicle" or "player", Enum.PowerType.ComboPoints)
	local r, g, b = GetComboColour(comboPoints)
	if (tconf.combo.enable) then
		--self.cpFrame:Hide()
		self.nameFrame.cpMeter:SetValue(comboPoints)
		self.nameFrame.cpMeter:Show()
		if r and g and b then
			self.nameFrame.cpMeter:SetStatusBarColor(r, g, b, 0.7)
		else
			self.nameFrame.cpMeter:Hide()
		end
	else
		self.nameFrame.cpMeter:Hide()
	end
	--[[if (tconf.combo.blizzard) then
		self.cpFrame:Hide()
	else
		--self.nameFrame.cpMeter:Hide()]]
	if tconf.comboindicator.enable then
		self.cpFrame:Show()
		self.cpFrame.text:SetText(comboPoints)
		if r and g and b then
			self.cpFrame.text:SetTextColor(r, g, b)
		else
			self.cpFrame:Hide()
		end
	else
		self.cpFrame:Hide()
	end
end

--[[local function XPerl_Target_DebuffUpdate(self)
	local partyid = self.partyid
	if (GetComboPoints((not IsClassic and UnitHasVehicleUI("player")) and "vehicle" or "player", partyid) == 0) then
		local numDebuffs = 0
		local r, g, b = GetComboColour(numDebuffs)
		if (tconf.combo.enable) then
			self.cpFrame:Hide()
			self.nameFrame.cpMeter:SetValue(numDebuffs)
			if (r) then
				self.nameFrame.cpMeter:Show()
				self.nameFrame.cpMeter:SetStatusBarColor(r, g, b, 0.4)
			else
				self.nameFrame.cpMeter:Hide()
			end
		else
			self.nameFrame.cpMeter:Hide()
			self.cpFrame.text:SetText(numDebuffs)
			if (r) then
				self.cpFrame:Show()
				self.cpFrame.text:SetTextColor(r, g, b)
			else
				self.cpFrame:Hide()
			end
		end
	else
		XPerl_Target_UpdateCombo(self)
	end
end--]]

-------------------------
-- The Update Functions--
-------------------------
local function XPerl_Target_UpdatePVP(self)
	local partyid = self.partyid

	local pvpIcon = self.nameFrame.pvp

	local factionGroup, factionName = UnitFactionGroup(partyid)

	if self.conf.pvpIcon and UnitIsPVPFreeForAll(partyid) then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		pvpIcon:Show()
	elseif self.conf.pvpIcon and factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(partyid) then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)

		if not IsClassic and UnitIsMercenary(partyid) then
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

	--[[local pvp = self.conf.pvpIcon and ((UnitIsPVPFreeForAll(partyid) and "FFA") or (UnitIsPVP(partyid) and (UnitFactionGroup(partyid) ~= "Neutral") and UnitFactionGroup(partyid)))
	if (pvp) then
		self.nameFrame.pvp.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		self.nameFrame.pvp:Show()
	else
		self.nameFrame.pvp:Hide()
	end]]

	if (self.conf.reactionHighlight) then
		local c = XPerl_ReactionColour(partyid)
		self.nameFrame:SetBackdropColor(c.r, c.g, c.b)

		if (conf.colour.class and UnitPlayerControlled(partyid)) then
			XPerl_SetUnitNameColor(self.nameFrame.text, partyid)
		else
			self.nameFrame.text:SetTextColor(1, 1, 1, conf.transparency.text)
		end
	else
		if not self.conf.highlightDebuffs.enable then
			self.nameFrame:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
		end
		XPerl_SetUnitNameColor(self.nameFrame.text, partyid)
	end

	if (UnitIsVisible(partyid) and UnitIsCharmed(partyid)) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- XPerl_Target_UpdateName
local function XPerl_Target_UpdateName(self)
	self.nameFrame.text:SetText(UnitName(self.partyid))
	XPerl_Target_UpdatePVP(self)
end

-- XPerl_Target_UpdateLevel
local function XPerl_Target_UpdateLevel(self)
	local targetlevel = UnitLevel(self.partyid)
	self.levelFrame.text:SetText(targetlevel)
	-- Set Level
	if (self.conf.level) then
		self.levelFrame:Show()
		self.levelFrame.skull:Hide()
		self.levelFrame:SetWidth(27)
		if (targetlevel < 0) then
			--[[if (UnitClassification(self.partyid) == "worldboss") then
				self.levelFrame.text:Hide()
				self.levelFrame.skull:Show()
			else
				self.levelFrame:Hide()
			end]]
			self.levelFrame.text:Hide()
			self.levelFrame.skull:Show()
		else
			local color = GetDifficultyColor(targetlevel)
			self.levelFrame.text:SetTextColor(color.r, color.g, color.b)
			self.levelFrame.text:Show()
			if (not self.conf.elite and (UnitClassification(self.partyid) == "elite" or UnitClassification(self.partyid) == "worldboss")) then
				self.levelFrame.text:SetFormattedText("%d+", targetlevel)
				self.levelFrame:SetWidth(33)
			end
		end
	end
end

-- XPerl_Target_UpdateClassification
local function XPerl_Target_UpdateClassification(self)
	local partyid = self.partyid
	local targetclassification = UnitClassification(partyid)
	local bossType, eliteGfx

	if (targetclassification == "normal" and UnitPlayerControlled(partyid)) then
		if (not UnitIsPlayer(partyid)) then
			bossType = XPERL_TYPE_PET
			self.bossFrame.text:SetTextColor(1, 1, 1)
			self.typeFramePlayer:Hide()
		end

	elseif (self.conf.level or targetclassification == "rareelite" or targetclassification == "rare" or targetclassification == "elite" or targetclassification == "worldboss") then
	--elseif ((self.conf.level and self.conf.elite) or targetclassification == "Rare+" or targetclassification == "Rare") then
		if (self.conf.eliteGfx) then
			eliteGfx = true
			if (targetclassification == "worldboss" or targetclassification == "elite") then
				self.eliteFrame.tex:SetTexture("Interface\\Addons\\ZPerl\\Images\\XPerl_Elite")
				self.eliteFrame.tex:SetVertexColor(1, 1, 0, 1)
			elseif (targetclassification == "rareelite") then
				self.eliteFrame.tex:SetTexture("Interface\\Addons\\ZPerl\\Images\\XPerl_Elite")
				self.eliteFrame.tex:SetVertexColor(1, 1, 1, 1)
			elseif (targetclassification == "rare") then
				self.eliteFrame.tex:SetTexture("Interface\\Addons\\ZPerl\\Images\\XPerl_Rare")
				self.eliteFrame.tex:SetVertexColor(1, 1, 1, 1)
			else
				eliteGfx = nil
			end
		else
			if (targetclassification == "worldboss") then
				bossType = XPERL_TYPE_BOSS
				self.bossFrame.text:SetTextColor(1, 0.5, 0.5)
			elseif (targetclassification == "rareelite") then
				bossType = XPERL_TYPE_RAREPLUS
				self.bossFrame.text:SetTextColor(0.8, 0.8, 0.8)
			elseif (targetclassification == "elite") then
				bossType = XPERL_TYPE_ELITE
				self.bossFrame.text:SetTextColor(1, 1, 0.5)
			elseif (targetclassification == "rare") then
				bossType = XPERL_TYPE_RARE
				self.bossFrame.text:SetTextColor(0.8, 0.8, 0.8)
			end
		end

		self.typeFramePlayer:Hide()
	end

	if (partyid == "target" and bossType and not tconf.eliteNone) or (partyid == "focus" and bossType and not fconf.eliteNone) then
		self.bossFrame:Show()
		self.bossFrame.text:SetText(bossType)
		self.bossFrame:SetWidth(self.bossFrame.text:GetStringWidth() + 10)
	else
		self.bossFrame:Hide()
	end

	if (eliteGfx) then
		self.eliteFrame:Show()
		if (partyid == "target" and XPerl_Target_AssistFrame and XPerl_Target_AssistFrame:IsShown()) then
			XPerl_Target_AssistFrame:ClearAllPoints()
			XPerl_Target_AssistFrame:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", 0, 0)
			XPerl_Target_AssistFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel() + 2)
			self.eliteFrame.assistOutOfPlace = true
		end
		if (self.conf.level) then
			self.levelFrame:ClearAllPoints()
			self.levelFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPRIGHT", 0, 0)
			self.levelFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel() + 2)
			self.levelFrame.outOfPlace = true
		end
		-- this is hidden if the mob is elite regardless of graphics (wihout gfx it says "Elite" for example)
		--if (self.conf.classIcon) then
		--	self.typeFramePlayer:ClearAllPoints()
		--	self.typeFramePlayer:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", 0, 0)
		--	self.typeFramePlayer.outOfPlace = true
		--end
	else
		self.eliteFrame:Hide()
		if (partyid == "target" and self.eliteFrame.assistOutOfPlace) then
			self.eliteFrame.assistOutOfPlace = nil
			XPerl_Target_AssistFrame:ClearAllPoints()
			XPerl_Target_AssistFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, -20)
			XPerl_Target_AssistFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel())
		end
		if (self.levelFrame.outOfPlace) then
			self.levelFrame.outOfPlace = nil
			self.levelFrame:ClearAllPoints()
			self.levelFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, 0)
			self.levelFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel())
		end
		--if (self.typeFramePlayer.outOfPlace) then
		--	self.typeFramePlayer.outOfPlace = nil
		--	self.typeFramePlayer:ClearAllPoints()
		--	self.typeFramePlayer:SetPoint("BOTTOMLEFT", self.portraitFrame, "BOTTOMRIGHT", 2, 2)
		--end
	end
end

-- AdjustCreatureTypeFrame
local function AdjustCreatureTypeFrame(self)
	-- If it's too long, we anchor it to left side of portrait instead of right, to avoid it overlapping some buffs
	self.creatureTypeFrame:ClearAllPoints()
	if (self.creatureTypeFrame:GetWidth() > self.portraitFrame:GetWidth()) then
		self.creatureTypeFrame:SetPoint("TOPLEFT", self.portraitFrame, "BOTTOMLEFT", 0, 2)
	else
		self.creatureTypeFrame:SetPoint("TOPRIGHT", self.portraitFrame, "BOTTOMRIGHT", 0, 2)
	end
end

local function UnitFullName(unit)
	local n,s = UnitName(unit)
	if (s and s ~= "") then
		return n.."-"..s
	end
	return n
end

-- XPerl_Target_UpdateTalents
local XPerl_Target_UpdateTalents
do
	local function ShowSpec(self, spec)--, s1, s2, s3)
		if (self.conf.talentsAsText and type(spec) == "string") then
			self.creatureTypeFrame.text:SetText(spec)
		else
			--self.creatureTypeFrame.text:SetFormattedText("%d / %d / %d", s1, s2, s3)
			self.creatureTypeFrame.text:SetText(spec)
		end
		self.creatureTypeFrame:SetWidth(self.creatureTypeFrame.text:GetStringWidth() + 10)
		self.creatureTypeFrame:Show()

		AdjustCreatureTypeFrame(self)
		XPerl_Target_BuffPositions(self)
	end

	local LGT = LibStub and LibStub("LibGroupTalents-1.0", true)
	local UpdateTalentsLGT
	if (LGT) then
		function UpdateTalentsLGT(self)
			local spec, s1, s2, s3 = LGT:GetUnitTalentSpec(self.partyid)
			if (spec) then
				ShowSpec(self, spec)--, s1, s2, s3)
				return true
			end
		end
	end

	local inspectReady
	local lastInspectTime = 0
	local lastInspectName, lastInspectUnit, lastInspectGUID
	local talentCache = setmetatable({}, {__mode = "kv"})
	local LTQ = LibStub and LibStub("LibTalentQuery-1.0", true)
	local lastInspectInvalid
	if (LTQ) then
		local function TalentQuery_Ready(e, name, realm, unit)
			if (UnitIsUnit(unit, XPerl_Target.partyid)) then
				inspectReady = true
				XPerl_Target_UpdateTalents(XPerl_Target, UnitGUID(unit))
			end
		end
		LTQ:RegisterCallback("TalentQuery_Ready", TalentQuery_Ready)
	else
		hooksecurefunc("NotifyInspect", function(unit)
			if (UnitIsUnit("player", unit) or (not IsClassic and UnitInVehicle(unit)) or not (UnitExists(unit) and CanInspect(unit) and UnitIsVisible(unit) and UnitIsConnected(unit) and CheckInteractDistance(unit, 4))) then
				return
			end
			lastInspectUnit = unit
			lastInspectPending = lastInspectPending + 1
			if (lastInspectPending > 1) then
				lastInspectInvalid = true
			end
			lastInspectTime = GetTime()
			lastInspectGUID = UnitGUID(unit)
			lastInspectName = UnitFullName(unit)
		end)

		-- INSPECT_READY
		function XPerl_Target_Events:INSPECT_READY(guid)
			if (UnitGUID(self.partyid) == guid) then
				inspectReady = true
				XPerl_Target_UpdateTalents(self, guid)
			end
		end
	end

	function XPerl_Target_UpdateTalents(self, guid)
		if (self.conf.showTalents and self == XPerl_Target and not self.creatureTypeFrame:IsShown()) then
			if (UpdateTalentsLGT and UpdateTalentsLGT(self)) then
				return
			end

			local partyid = self.partyid
			if (UnitIsVisible(partyid) and UnitExists(partyid) and UnitIsPlayer(partyid) and UnitLevel(partyid) > 10) then
				local name = UnitName(partyid)
				if (not name) then
					return
				else
					local cached = talentCache[name]
					local name1, name2, name3, group, iconTexture, background
					if (cached) then
						name1, name2, name3, group = unpack(cached)
					elseif (inspectReady and guid == UnitGUID(partyid)) then
						local remoteInspectNeeded = not UnitIsUnit("player", partyid) or nil
						if not IsClassic then
							group = GetInspectSpecialization("target")
							local _, spec = GetSpecializationInfoByID(group)
							name1 = group and spec or "None"
						else
							name1 = "None"
						end

						inspectReady = nil
					end

					if (name1) then
						if (not cached) then
							talentCache[name] = {name1, name2, name3, group}
						end
						ShowSpec(self, name1)
					end

					if (not cached) then
						if (LTQ) then
							inspectReady = nil
							LTQ:Query(partyid)
						else
							if (lastInspectPending == 0 or GetTime() > lastInspectTime + 15) then
								if (UnitExists(partyid) and UnitIsVisible(partyid) and CheckInteractDistance(partyid, 4)) then
									if (not UnitIsUnit("player", partyid)) then
										inspectReady = nil
										lastInspectInvalid = nil
										lastInspectPending = 0
										if (lastInspectName ~= UnitFullName(partyid)) then
											NotifyInspect(partyid)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- XPerl_Target_UpdateType
local function XPerl_Target_UpdateType(self)
	local partyid = self.partyid
	local targettype = UnitCreatureType(partyid)

	if (targettype == XPERL_TYPE_NOT_SPECIFIED or targettype == "") then
		targettype = nil
	end

	if (self.conf.mobType) then
		self.creatureTypeFrame:Show()
	else
		self.creatureTypeFrame:Hide()
	end

	self.typeFramePlayer:Hide()


	if not IsClassic and (UnitIsWildBattlePet(partyid) or UnitIsBattlePetCompanion(partyid)) then
		self.creatureTypeFrame.text:SetText(PET_TYPE_SUFFIX[UnitBattlePetType(partyid)])
	else
		self.creatureTypeFrame.text:SetText(targettype)
	end

	--if (UnitIsPlayer(partyid)) then
		if (self.conf.classIcon and (UnitIsPlayer(partyid) or UnitClassification(partyid) == "normal")) then
			local LocalClass, PlayerClass = UnitClassBase(partyid)

			if (self.conf.classText) then
				self.bossFrame.text:SetText(LocalClass)
				self.bossFrame.text:SetTextColor(1, 1, 1)
				self.bossFrame:Show()
				self.bossFrame:SetWidth(self.bossFrame.text:GetStringWidth() + 10)
			else
				if (UnitIsPlayer(partyid) or not UnitPlayerControlled(partyid)) then
					local l, r, t, b = XPerl_ClassPos(LocalClass)
					self.typeFramePlayer.classTexture:SetTexCoord(l, r, t, b)
					self.typeFramePlayer:Show()
				end
			end
		end
		if (UnitIsPlayer(partyid)) then
			self.creatureTypeFrame:Hide()
		end
	--else
		if (targettype) then
			self.creatureTypeFrame.text:SetTextColor(1, 1, 1)
			self.creatureTypeFrame:SetWidth(self.creatureTypeFrame.text:GetStringWidth() + 10)
		else
			self.creatureTypeFrame:Hide()
		end
	--end

	AdjustCreatureTypeFrame(self)

	XPerl_Target_UpdateTalents(self)
end

-- XPerl_Target_SetManaType
function XPerl_Target_SetManaType(self)
	local targetmanamax = UnitPowerMax(self.partyid)

	if (targetmanamax == 0 or not self.conf.mana) then
		if (self.statsFrame.manaBar:IsShown()) then
			self.statsFrame.manaBar:Hide()

			if (self == XPerl_Target or self == XPerl_Focus or self == XPerl_TargetTarget or self == XPerl_FocusTarget or self == XPerl_PetTarget or self == XPerl_TargetTargetTarget) then
				self.statsFrame:SetHeight(28 + ((conf.bar.fat or 0) * 2))
				XPerl_StatsFrameSetup(self)
			end
		end
		return
	end

	XPerl_SetManaBarType(self)

	if (not self.statsFrame.manaBar:IsShown()) then
		self.statsFrame.manaBar:Show()
		self.statsFrame.manaBar.text:Show()
		if (self == XPerl_Target or self == XPerl_Focus or self == XPerl_TargetTarget or self == XPerl_FocusTarget or self == XPerl_PetTarget or self == XPerl_TargetTargetTarget) then
			self.statsFrame:SetHeight(40)
			XPerl_StatsFrameSetup(self)
		end
	end
end

-- XPerl_Target_SetMana
function XPerl_Target_SetMana(self)
	local partyid = self.partyid
	if not partyid then
		self.targetmana = 0
		self.targetmanamax = 0
		return
	end

	local targetmana, targetmanamax = UnitPower(self.partyid), UnitPowerMax(self.partyid)
	local mb = self.statsFrame.manaBar

	self.targetmana = targetmana
	self.targetmanamax = targetmanamax

	--Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
	local pmanaPct
	if targetmana > 0 and targetmanamax == 0 then --We have current mana but max mana failed.
		targetmanamax = targetmana --Make max mana at least equal to current mana
		pmanaPct = 1 --And percent 100% cause a number divided by itself is 1, duh.
	elseif targetmana == 0 and targetmanamax == 0 then--Probably doesn't use mana or is oom?
		pmanaPct = 0 --So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
	else
		pmanaPct = targetmana / targetmanamax--Everything is dandy, so just do it right way.
	end
	--end division by 0 check

	mb:SetMinMaxValues(0, targetmanamax)
	mb:SetValue(targetmana)

	local p = XPerl_GetDisplayedPowerType(self.partyid)
	if p == 0 then
		mb.percent:SetFormattedText(percD, 100 * pmanaPct)	--	XPerl_Percent[floor(100 * (targetmana / targetmanamax))])
	else
		mb.percent:SetText(targetmana)
	end

	XPerl_SetValuedText(mb.text, targetmana, targetmanamax)
	--mb.text:SetFormattedText("%d/%d", targetmana, targetmanamax)
end

-- XPerl_Target_SetComboBar
function XPerl_Target_SetComboBar(self)
	if (tconf.combo.enable) then
		local comboPoints = IsClassic and GetComboPoints("player", "target") or UnitPower(UnitHasVehicleUI("player") and "vehicle" or "player", Enum.PowerType.ComboPoints)
		local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
		self.nameFrame.cpMeter:SetMinMaxValues(0, IsClassic and 5 or maxComboPoints)
		self.nameFrame.cpMeter:SetValue(comboPoints)
	end
end

-- XPerl_Target_UpdateHealPrediction
local function XPerl_Target_UpdateHealPrediction(self)
	if self == XPerl_Target then
		if tconf.healprediction then
			XPerl_SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	elseif self == XPerl_TargetTarget or self == XPerl_TargetTargetTarget then
		if conf.targettarget.healprediction then
			XPerl_SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	elseif self == XPerl_Focus then
		if fconf.healprediction then
			XPerl_SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	elseif self == XPerl_FocusTarget then
		if conf.focustarget.healprediction then
			XPerl_SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	end
end

-- XPerl_Target_UpdateAbsorbPrediction
local function XPerl_Target_UpdateAbsorbPrediction(self)
	if self == XPerl_Target then
		if tconf.absorbs then
			XPerl_SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	elseif self == XPerl_TargetTarget or self == XPerl_TargetTargetTarget then
		if conf.targettarget.absorbs then
			XPerl_SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	elseif self == XPerl_Focus then
		if fconf.absorbs then
			XPerl_SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	elseif self == XPerl_FocusTarget then
		if conf.focustarget.absorbs then
			XPerl_SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	end
end

-- XPerl_Target_UpdateHotsPrediction
local function XPerl_Target_UpdateHotsPrediction(self)
	if not IsWrathClassic then
		return
	end
	if self == XPerl_Target then
		if tconf.hotPrediction then
			XPerl_SetExpectedHots(self)
		else
			self.statsFrame.expectedHots:Hide()
		end
	elseif self == XPerl_TargetTarget or self == XPerl_TargetTargetTarget then
		if conf.targettarget.hotPrediction then
			XPerl_SetExpectedHots(self)
		else
			self.statsFrame.expectedHots:Hide()
		end
	elseif self == XPerl_Focus then
		if fconf.hotPrediction then
			XPerl_SetExpectedHots(self)
		else
			self.statsFrame.expectedHots:Hide()
		end
	elseif self == XPerl_FocusTarget then
		if conf.focustarget.hotPrediction then
			XPerl_SetExpectedHots(self)
		else
			self.statsFrame.expectedHots:Hide()
		end
	end
end

function XPerl_Target_UpdateResurrectionStatus(self)
	if (UnitHasIncomingResurrection(self.partyid)) then
		if (self == XPerl_Target and tconf.portrait) or (self == XPerl_Focus and fconf.portrait) then
			self.portraitFrame.resurrect:Show()
		else
			self.statsFrame.resurrect:Show()
		end
	else
		if (self == XPerl_Target and tconf.portrait) or (self == XPerl_Focus and fconf.portrait) then
			self.portraitFrame.resurrect:Hide()
		else
			self.statsFrame.resurrect:Hide()
		end
	end
end

-- XPerl_Target_UpdateHealth
function XPerl_Target_UpdateHealth(self)
	local partyid = self.partyid
	if not partyid then
		self.targethp = 0
		self.targetmax = 0
		self.afk = false
		return
	end

	local hb = self.statsFrame.healthBar
	local hbt = self.statsFrame.healthBar.text
	local hp, hpMax, percent = XPerl_Target_GetHealth(self)

	self.targethp = hp
	self.targethpmax = hpMax
	self.afk = UnitIsAFK(partyid) and conf.showAFK == 1

	--[[if (self.targethp == 100) then
		-- Try to work around the occasion WoW targettarget bug of a zero hp tank who is not at zero hp
		if (not UnitIsDeadOrGhost(partyid)) then
			if (UnitInRaid(partyid)) then
				for i = 1, GetNumGroupMembers() do
					local id = "raid"..i
					if (UnitIsUnit(id, partyid)) then
						hp, hpMax, percent = UnitIsGhost(id) and 1 or (UnitIsDead(id) and 0 or UnitHealth(id)), UnitHealthMax(id), false
						break
					end
				end
			end
		end
	end]]

	if hp and hp >= 0 and hpMax and hpMax > 0 then
		XPerl_SetHealthBar(self, hp, hpMax)
	end

	XPerl_Target_UpdateAbsorbPrediction(self)
	XPerl_Target_UpdateHealPrediction(self)
	XPerl_Target_UpdateHotsPrediction(self)
	XPerl_Target_UpdateResurrectionStatus(self)

	if (percent) then
		if UnitIsDeadOrGhost(partyid) or hpMax == 0 then -- 4.3+ fix so if for some dumb reason max HP is 0, prevent any division by 0.
			hbt:SetFormattedText(percD, 0)
		else
			hbt:SetFormattedText(percD, 100 * hp / hpMax)
		end
	end

	local color
	if (self.conf.percent) then
		if (UnitIsGhost(partyid)) then
			self.statsFrame.manaBar.percent:Hide()
			hb.percent:SetText(XPERL_LOC_GHOST)
		--[[elseif (conf.showFD and UnitBuff(partyid, feignDeath)) then
			--self.statsFrame.manaBar.percent:Hide()
			--hb.percent:SetText(XPERL_LOC_DEAD)
			hbt:SetText(XPERL_LOC_FEIGNDEATH)--]]
		elseif (UnitIsDead(partyid)) then
			--self.statsFrame.manaBar.percent:Hide()
			hb.percent:SetText(XPERL_LOC_DEAD)
		elseif (UnitExists(partyid) and not UnitIsConnected(partyid)) then
			self.statsFrame.manaBar.percent:Hide()
			hb.percent:SetText(XPERL_LOC_OFFLINE)
		elseif (UnitIsAFK(partyid) and conf.showAFK) --[[and (self == XPerl_Target or self == XPerl_Focus))]] then
			hb.percent:SetText(CHAT_MSG_AFK)
		else
			self.statsFrame.manaBar.percent:Show()
			color = true
		end
	else
		if (UnitIsGhost(partyid)) then
			hbt:SetText(XPERL_LOC_GHOST)
		--[[elseif (conf.showFD and UnitBuff(partyid, feignDeath)) then
			hbt:SetText(XPERL_LOC_FEIGNDEATH)--]]
		elseif (UnitIsDead(partyid)) then
			hbt:SetText(XPERL_LOC_DEAD)
		elseif (UnitExists(partyid) and not UnitIsConnected(partyid)) then
			hbt:SetText(XPERL_LOC_OFFLINE)
		elseif (UnitIsAFK(partyid) and conf.showAFK) then
			hbt:SetText(CHAT_MSG_AFK)
		else
			color = true
		end
	end

	if (color) then
		if hp and hp >= 0 and hpMax and hpMax > 0 then
			XPerl_ColourHealthBar(self, hp / hpMax)
		end

		if (self.statsFrame.greyMana) then
			self.statsFrame.greyMana = nil
			XPerl_Target_SetManaType(self)
		end
	else
		self.statsFrame:SetGrey()
	end
end

-- XPerl_Target_GetHealth
function XPerl_Target_GetHealth(self)
	local hp, hpMax = XPerl_Unit_GetHealth(self)
	return hp, hpMax, hpMax == 100
end

-- XPerl_Target_Update_Combat
function XPerl_Target_Update_Combat(self)
	if (UnitAffectingCombat(self.partyid)) then
		self.nameFrame.combatIcon:Show()
	else
		self.nameFrame.combatIcon:Hide()
	end
end

-- XPerl_Target_CombatFlash
local function XPerl_Target_CombatFlash(self, elapsed, argNew, argGreen)
	if (XPerl_CombatFlashSet(self, elapsed, argNew, argGreen)) then
		XPerl_CombatFlashSetFrames(self)
	end
end

-- XPerl_Target_Update_Range
function XPerl_Target_Update_Range(self)
	if (not tconf.range30yard or CheckInteractDistance(self.partyid, 4) or not UnitIsConnected(self.partyid)) then
		self.nameFrame.rangeIcon:Hide()
	else
		self.nameFrame.rangeIcon:Show()
		self.nameFrame.rangeIcon:SetAlpha(1)
	end
end

-- XPerl_Target_UpdateLeader
local function XPerl_Target_UpdateLeader(self)
	local leader
	local partyid = self.partyid

	if (UnitIsGroupLeader(partyid)) then
		self.nameFrame.leaderIcon:Show()
		self.nameFrame.assistIcon:Hide()
	else
		self.nameFrame.leaderIcon:Hide()
		if (UnitIsGroupAssistant(partyid)) then
			self.nameFrame.assistIcon:Show()
		else
			self.nameFrame.assistIcon:Hide()
		end
	end

	local masterLooter = false
	local method, partyID, raidID = GetLootMethod()

	if method and method == "master" then
		if raidID then
			if UnitIsUnit("raid"..raidID, partyid) then
				masterLooter = true
			end
		elseif partyID then
			if UnitIsUnit("party"..partyID, partyid) or (partyID == 0 and UnitIsUnit("player", partyid)) then
				masterLooter = true
			end
		end
	end

	if masterLooter then
		self.nameFrame.masterIcon:Show()
	else
		self.nameFrame.masterIcon:Hide()
	end
end

-- RaidTargetUpdate
local function RaidTargetUpdate(self)
	local raidIcon = self.nameFrame.raidIcon

	XPerl_Update_RaidIcon(raidIcon, self.partyid)

	raidIcon:ClearAllPoints()
	if (self.conf.raidIconAlternate) then
		raidIcon:SetHeight(16)
		raidIcon:SetWidth(16)
		raidIcon:SetPoint("CENTER", self.nameFrame, "TOPRIGHT", -5, -4)
	else
		raidIcon:SetHeight(32)
		raidIcon:SetWidth(32)
		raidIcon:SetPoint("CENTER", self.nameFrame, "CENTER", 0, 0)
	end
end

-- XPerl_Target_CheckDebuffs
local function XPerl_Target_CheckDebuffs(self)
	if (self.conf.highlightDebuffs.enable) then
		if (self.conf.highlightDebuffs.who == 1 or (self.conf.highlightDebuffs.who == 2 and UnitCanAssist("player", self.partyid)) or (self.conf.highlightDebuffs.who == 3 and not UnitCanAssist("player", self.partyid))) then
			XPerl_CheckDebuffs(self, self.partyid)
		else
			XPerl_CheckDebuffs(self, self.partyid, true)
		end
	end

	if (self.conf.reactionHighlight) then
		local c = XPerl_ReactionColour(self.partyid)
		self.nameFrame:SetBackdropColor(c.r, c.g, c.b)
	end
end

-- XPerl_Target_UpdateDisplay
function XPerl_Target_UpdateDisplay(self)
	local partyid = self.partyid
	if (UnitExists(partyid)) then
		XPerl_NoFadeBars(true)

		XPerl_Target_UpdateName(self)
		XPerl_Target_UpdateClassification(self)
		XPerl_Target_UpdateLevel(self)
		XPerl_Target_UpdateType(self)
		XPerl_Target_SetManaType(self)
		XPerl_Target_SetMana(self)
		XPerl_Target_UpdateHealth(self)
		XPerl_Target_Update_Combat(self)
		XPerl_Target_UpdateLeader(self)
		XPerl_Unit_ThreatStatus(self, partyid == "target" and "player" or nil, true)

		RaidTargetUpdate(self)

		if (self.conf.defer) then
			self.portraitFrame.portrait:Hide()
			self.portraitFrame.portrait3D:Hide()
			self.nameFrame.masterIcon:Hide()
			self.cpFrame:Hide()
			self.nameFrame.cpMeter:Hide()
			self.deferring = true
			self.time = -0.3
		else
			XPerl_Target_UpdateCombo(self)
			XPerl_Unit_UpdatePortrait(self)
		end

		XPerl_Highlight:SetHighlight(self, UnitGUID(partyid))

		XPerl_Target_Update_Range(self)
		XPerl_UpdateSpellRange(self, partyid)

		XPerl_NoFadeBars()

		-- Some optimizing here to limit the amount of work done on a target change
		local buffOptionString = tostring(self.statsFrame.manaBar:IsVisible() or 0)..tostring(self.bossFrame:IsVisible() or 0)..tostring(self.creatureTypeFrame:IsVisible() or 0)..tostring(self.statsFrame:GetWidth())
		if (self.buffOptionString ~= buffOptionString) then
			self.buffOptionString = buffOptionString
			-- Work out where all our buffs can fit, we only do this for a fresh target
			XPerl_Target_BuffPositions(self)
		end

		XPerl_Targets_BuffUpdate(self)
		--XPerl_Target_DebuffUpdate(self)
		if (self.conf.highlightDebuffs.enable) then
			XPerl_Target_CheckDebuffs(self)
		end

		XPerl_Target_UpdatePVP(self)
	end
end

-- XPerl_Target_OnUpdate
function XPerl_Target_OnUpdate(self, elapsed)
	if (tconf.hitIndicator and tconf.portrait) or (fconf.hitIndicator and fconf.portrait) then
		CombatFeedback_OnUpdate(self, elapsed)
	end

	local partyid = self.partyid
	local newAFK = UnitIsAFK(partyid)

	if (conf.showAFK and newAFK ~= self.afk) then
		XPerl_Target_UpdateHealth(self)
	end

	if self.deferring or conf.rangeFinder.enabled or tconf.range30yard then
		self.time = self.time + elapsed
		if (self.time > 0.2) then
			self.time = 0
			if tconf.range30yard then
				XPerl_Target_Update_Range(self)
			end
			if conf.rangeFinder.enabled then
				XPerl_UpdateSpellRange(self, partyid)
			end

			if (self.deferring) then
				self.deferring = nil
				XPerl_Target_Update_Combat(self)
				XPerl_Target_UpdateCombo(self)
				XPerl_Unit_UpdatePortrait(self)
				RaidTargetUpdate(self)
			end
		end
	end

	if (conf.combatFlash and self.PlayerFlash) then
		XPerl_Target_CombatFlash(self, elapsed, false)
	end
end

-------------------
-- Event Handler --
-------------------
function XPerl_Target_OnEvent(self, event, ...)
	local func = XPerl_Target_Events[event]
	func(self, ...)
end


function XPerl_Target_Events:PLAYER_REGEN_ENABLED()
	XPerl_Unit_ThreatStatus(self, self.partyid == "target" and "player" or nil)
end

function XPerl_Target_Events:PLAYER_REGEN_DISABLED()
	XPerl_Unit_ThreatStatus(self, self.partyid == "target" and "player" or nil)
end

function XPerl_Target_Events:PET_BATTLE_OPENING_START()
	if (XPerl_Target) then
		XPerl_Target:Hide()
	end
	if (XPerl_Focus) then
		XPerl_Focus:Hide()
	end
	if (XPerl_PetTarget) then
		XPerl_PetTarget:Hide()
	end
	if (XPerl_TargetTarget) then
		XPerl_TargetTarget:Hide()
	end
	if (XPerl_FocusTarget) then
		XPerl_FocusTarget:Hide()
	end
end

function XPerl_Target_Events:PET_BATTLE_CLOSE()
	if (XPerl_Target and UnitExists("target")) then
		XPerl_Target:Show()
	end
	if (XPerl_Focus and XPerl_Focus.conf.enable and UnitExists("focus")) then
		XPerl_Focus:Show()
	end
	if (XPerl_PetTarget and UnitExists("pettarget")) then
		XPerl_PetTarget:Show()
	end
	if (XPerl_TargetTarget and XPerl_TargetTarget.conf.enable and UnitExists("targettarget")) then
		XPerl_TargetTarget:Show()
	end
	if (XPerl_FocusTarget and XPerl_FocusTarget.conf.enable and UnitExists("focustarget")) then
		XPerl_FocusTarget:Show()
	end
end

-- PLAYER_ENTERING_WORLD
function XPerl_Target_Events:PLAYER_ENTERING_WORLD()
	if (UnitExists("focus")) then
		--self.feigning = nil
		self.PlayerFlash = 0
		XPerl_CombatFlashSetFrames(self)
		XPerl_Target_UpdateDisplay(self)
	end
end

local amountIndex = {
	SWING_DAMAGE = 1,
	RANGE_DAMAGE = 4,
	SPELL_DAMAGE = 4,
	SPELL_PERIODIC_DAMAGE = 4,
	DAMAGE_SHIELD = 4,
	ENVIRONMENTAL_DAMAGE = 2,
}

local missIndex = {
	SWING_MISSED = 1,
	RANGE_MISSED = 4,
	SPELL_MISSED = 4,
	SPELL_PERIODIC_MISSED = 4,
}

-- DoEvent
local function DoEvent(self, timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, destRaidFlags, ...)
	local feedbackText = self.feedbackText
	local fontHeight = self.feedbackFontHeight
	local text
	local r = 1
	local g = 1
	local b = 1

	if (event == "SWING_DAMAGE" or event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" or event == "DAMAGE_SHIELD" or event == "ENVIRONMENTAL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE") then
		local amount, overkill, spellSchool, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand, multistrike = select(amountIndex[event], ...)
		if (amount and amount ~= 0) then
			if (critical or crushing) then
				fontHeight = fontHeight * 1.5
			elseif (glancing) then
				fontHeight = fontHeight * 0.75
			end
			if (event ~= "SWING_DAMAGE" and event ~= "RANGE_DAMAGE") then
				b = 0
			end
			text = amount
		end

	elseif (event == "SWING_MISSED" or event == "RANGE_MISSED" or event == "SPELL_MISSED" or event == "SPELL_PERIODIC_MISSED") then
		local missType = select(missIndex[event], ...)
		if (missType) then
			if (event ~= "SWING_MISSED" and event ~= "RANGE_MISSED") then
				b = 0
			end
			text = CombatFeedbackText[missType]
		end

	elseif (event == "SPELL_HEAL" or event == "SPELL_PERIODIC_HEAL") then
		local spellID, spellName, spellSchool, amount, overhealing, absorbed, critical = ...
		if (amount and amount ~= 0) then
			if (critical) then
				fontHeight = fontHeight * 1.5
			end
			r = 0
			g = 1
			b = 0
			text = amount
		end
	end

	if (text) then
		self.feedbackStartTime = GetTime()

		feedbackText:SetTextHeight(fontHeight)
		feedbackText:SetText(text)
		feedbackText:SetTextColor(r, g, b)
		feedbackText:SetAlpha(0)
		feedbackText:Show()
	end
end

-- COMBAT_LOG_EVENT_UNFILTERED
function XPerl_Target_Events:COMBAT_LOG_EVENT_UNFILTERED()
	if (self.conf.hitIndicator and self.conf.portrait) then
		local _, _, _, _, _, srcFlags, _, _, _, dstFlags = CombatLogGetCurrentEventInfo()
		if (bit_band(dstFlags, self.combatMask) ~= 0 and bit_band(srcFlags, 0x00000001) ~= 0) or (UnitIsUnit("player", self.partyid) and bit_band(dstFlags, 0x00000001)) then
			DoEvent(self, CombatLogGetCurrentEventInfo())
		end
	end
end

-- UNIT_COMBAT
function XPerl_Target_Events:UNIT_COMBAT(unitID, action, descriptor, damage, damageType)
	if (unitID == self.partyid) then
		XPerl_Target_Update_Combat(self)

		if (not self.conf.ownDamageOnly) then
			if (self.conf.hitIndicator and self.conf.portrait) then
				CombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
			end
		end

		if (action == "HEAL") then
			XPerl_Target_CombatFlash(self, 0, true, true)
		elseif (damage and damage > 0) then
			XPerl_Target_CombatFlash(self, 0, true)
		end
	end
end

-- PLAYER_TARGET_CHANGED
function XPerl_Target_Events:PLAYER_TARGET_CHANGED()
	if self ~= XPerl_Target then
		return
	end
	if (self.conf.sound and UnitExists("target")) then
		if (UnitIsEnemy("target", "player")) then
			PlaySound(873)
		elseif (UnitIsFriend("player", "target")) then
			PlaySound(867)
		else
			PlaySound(871)
		end
	end

	--self.feigning = UnitBuff(self.partyid, feignDeath)
	self.PlayerFlash = 0
	XPerl_CombatFlashSetFrames(self)
	XPerl_Target_UpdateDisplay(self)

	if (UnitIsUnit("target", "focus")) then
		self.statsFrame.focusTarget:Show()
	else
		self.statsFrame.focusTarget:Hide()
	end

	if (XPerl_Focus and XPerl_Focus:IsShown() and XPerl_FocusTarget) then
		XPerl_TargetTarget_UpdateDisplay(XPerl_FocusTarget)
	end
end

-- PLAYER_FOCUS_CHANGED
function XPerl_Target_Events:PLAYER_FOCUS_CHANGED()
	if self ~= XPerl_Focus then
		return
	end
	if (self.conf.sound and UnitExists("focus")) then
		if (UnitIsEnemy("focus", "player")) then
			PlaySound(873)
		elseif (UnitIsFriend("player", "focus")) then
			PlaySound(867)
		else
			PlaySound(871)
		end
	end

	--self.feigning = UnitBuff(self.partyid, feignDeath)
	self.PlayerFlash = 0
	XPerl_CombatFlashSetFrames(self)
	XPerl_Target_UpdateDisplay(self)

	if (UnitIsUnit("target", "focus")) then
		XPerl_Target.statsFrame.focusTarget:Show()
	else
		XPerl_Target.statsFrame.focusTarget:Hide()
	end

	if (XPerl_FocusTarget) then
		XPerl_TargetTarget_UpdateDisplay(XPerl_FocusTarget)
	end
end

-- UNIT_HEALTH_FREQUENT
function XPerl_Target_Events:UNIT_HEALTH_FREQUENT()
	XPerl_Target_UpdateHealth(self)
end

-- UNIT_HEALTH
function XPerl_Target_Events:UNIT_HEALTH()
	XPerl_Target_UpdateHealth(self)
end

-- UNIT_MAXHEALTH
function XPerl_Target_Events:UNIT_MAXHEALTH()
	XPerl_Target_UpdateHealth(self)
end

-- PET_BATTLE_HEALTH_CHANGED
function XPerl_Target_Events:PET_BATTLE_HEALTH_CHANGED()
	XPerl_Target_UpdateHealth(self)
end

-- UPDATE_SUMMONPETS_ACTION
function XPerl_Target_Events:UPDATE_SUMMONPETS_ACTION()
	if UnitIsBattlePet("target") then
		XPerl_Target_UpdateHealth(XPerl_Target)
	end

	if UnitIsBattlePet("focus") then
		XPerl_Target_UpdateHealth(XPerl_Focus)
	end
end

-- UNIT_FLAGS
function XPerl_Target_Events:UNIT_FLAGS()
	XPerl_Target_UpdateName(self)
	XPerl_Target_UpdatePVP(self)
	XPerl_Target_Update_Combat(self)
end

-- RAID_TARGET_UPDATE
function XPerl_Target_Events:RAID_TARGET_UPDATE()
	RaidTargetUpdate(XPerl_Target)
	RaidTargetUpdate(XPerl_Focus)
end

-- UNIT_POWER_FREQUENT
function XPerl_Target_Events:UNIT_POWER_FREQUENT()
	XPerl_Target_SetMana(self)
end

-- UNIT_MAXPOWER
function XPerl_Target_Events:UNIT_MAXPOWER(unit)
	if unit == "target" then
		XPerl_Target_SetMana(self)
	else
		XPerl_Target_SetComboBar(self)
	end
end

-- UNIT_DISPLAYPOWER
function XPerl_Target_Events:UNIT_DISPLAYPOWER()
	XPerl_Target_SetManaType(self)
	XPerl_Target_SetMana(self)
end

-- UNIT_PORTRAIT_UPDATE
function XPerl_Target_Events:UNIT_PORTRAIT_UPDATE()
	XPerl_Unit_UpdatePortrait(self, true)
end

-- UNIT_NAME_UPDATE
function XPerl_Target_Events:UNIT_NAME_UPDATE()
	XPerl_Target_UpdateName(self)
	XPerl_Target_UpdateHealth(self)
	XPerl_Target_UpdateClassification(self)
end

-- UNIT_LEVEL
function XPerl_Target_Events:UNIT_LEVEL()
	XPerl_Target_UpdateLevel(self)
	XPerl_Target_UpdateClassification(self)
end

-- UNIT_CLASSIFICATION_CHANGED
function XPerl_Target_Events:UNIT_CLASSIFICATION_CHANGED()
	XPerl_Target_UpdateClassification(self)
end

-- UNIT_COMBO_POINTS
--[[function XPerl_Target_Events:UNIT_COMBO_POINTS(unit)
	if (unit == "player") or (unit == "vehicle") then
		XPerl_Target_UpdateCombo(self)
	end
end]]

-- UNIT_AURA
function XPerl_Target_Events:UNIT_AURA()
	if not UnitExists(self.partyid) then
		return
	end

	if (self.conf.highlightDebuffs.enable) then
		XPerl_Target_CheckDebuffs(self)
	end

	--XPerl_Targets_BuffUpdate(self)
	if self.conf.buffs.enable or self.conf.debuffs.enable then
		XPerl_Unit_UpdateBuffs(self, nil, nil, self.conf.buffs.castable, self.conf.debuffs.curable)
		XPerl_Target_BuffPositions(self)
	end
	--XPerl_Target_DebuffUpdate(self)

	--[[if conf.showFD then
		local _, class = UnitClass(self.partyid)
		if class == "HUNTER" then
			local feigning = UnitBuff(self.partyid, feignDeath)
			if feigning ~= self.feigning then
				self.feigning = feigning
				XPerl_Target_UpdateHealth(self)
			end
		end
	end--]]
end

-- UNIT_FACTION
function XPerl_Target_Events:UNIT_FACTION()
	XPerl_Target_UpdatePVP(self)
	XPerl_Target_BuffPositions(self)
end

-- HONOR_PRESTIGE_UPDATE
function XPerl_Target_Events:HONOR_PRESTIGE_UPDATE()
	XPerl_Target_UpdatePVP(self)
end

-- PLAYER_FLAGS_CHANGED
function XPerl_Target_Events:PLAYER_FLAGS_CHANGED()
	XPerl_Target_Update_Combat(self)
	XPerl_Target_UpdatePVP(self)
	XPerl_Target_UpdateHealth(self)
end

-- UNIT_CONNECTION
function XPerl_Target_Events:UNIT_CONNECTION(unit, online)
	if (unit == self.partyid) then
		XPerl_Target_UpdateDisplay(self)
	end
end

-- UNIT_PHASE
function XPerl_Target_Events:UNIT_PHASE(unit)
	if (unit == self.partyid) then
		XPerl_Target_UpdateDisplay(self)
	end
end

-- PARTY_LOOT_METHOD_CHANGED
function XPerl_Target_Events:PARTY_LOOT_METHOD_CHANGED()
	XPerl_Target_UpdateLeader(self)
end
XPerl_Target_Events.GROUP_ROSTER_UPDATE = XPerl_Target_Events.PARTY_LOOT_METHOD_CHANGED
XPerl_Target_Events.PARTY_LEADER_CHANGED = XPerl_Target_Events.PARTY_LOOT_METHOD_CHANGED

function XPerl_Target_Events:UNIT_THREAT_LIST_UPDATE(unit)
	if (UnitCanAttack("player", self.partyid or "target")) then
		XPerl_Unit_ThreatStatus(self, self.partyid == "target" and "player" or nil)
	else
		XPerl_Unit_ThreatStatus(self)
	end
end

function XPerl_Target_Events:UNIT_HEAL_PREDICTION(unit)
	if self == XPerl_Target then
		if (tconf.healprediction and unit == self.partyid) then
			XPerl_SetExpectedHealth(self)
		end
		if (tconf.hotPrediction and unit == self.partyid) then
			XPerl_SetExpectedHots(self)
		end
	elseif self == XPerl_TargetTarget or self == XPerl_TargetTargetTarget then
		if (conf.targettarget.healprediction and unit == self.partyid) then
			XPerl_SetExpectedHealth(self)
		end
		if (conf.targettarget.hotPrediction and unit == self.partyid) then
			XPerl_SetExpectedHots(self)
		end
	elseif self == XPerl_Focus then
		if (fconf.healprediction and unit == self.partyid) then
			XPerl_SetExpectedHealth(self)
		end
		if (fconf.hotPrediction and unit == self.partyid) then
			XPerl_SetExpectedHots(self)
		end
	elseif self == XPerl_FocusTarget then
		if (conf.focustarget.healprediction and unit == self.partyid) then
			XPerl_SetExpectedHealth(self)
		end
		if (conf.focustarget.hotPrediction and unit == self.partyid) then
			XPerl_SetExpectedHots(self)
		end
	end
end

function XPerl_Target_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if self == XPerl_Target then
		if (tconf.absorbs and unit == self.partyid) then
			XPerl_SetExpectedAbsorbs(self)
		end
	elseif self == XPerl_TargetTarget or self == XPerl_TargetTargetTarget then
		if (conf.targettarget.absorbs and unit == self.partyid) then
			XPerl_SetExpectedAbsorbs(self)
		end
	elseif self == XPerl_Focus then
		if (fconf.absorbs and unit == self.partyid) then
			XPerl_SetExpectedAbsorbs(self)
		end
	elseif self == XPerl_FocusTarget then
		if (conf.focustarget.absorbs and unit == self.partyid) then
			XPerl_SetExpectedAbsorbs(self)
		end
	end
end

function XPerl_Target_Events:INCOMING_RESURRECT_CHANGED(unit)
	if (unit == self.partyid) then
		XPerl_Target_UpdateResurrectionStatus(self)
	end
end

-- XPerl_Target_SetWidth
function XPerl_Target_SetWidth(self)
	self.conf.size.width = max(0, self.conf.size.width or 0)
	local w = 128 + ((self.conf.portrait and 1 or 0) * 62) + ((self.conf.percent and 1 or 0) * 32) + self.conf.size.width

	if (not InCombatLockdown()) then
		self:SetWidth(w)
	end

	if (self.conf.percent) then
		if (not InCombatLockdown()) then
			self.nameFrame:SetWidth(160 + self.conf.size.width)
			self.statsFrame:SetWidth(160 + self.conf.size.width)
		end
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()
	else
		if (not InCombatLockdown()) then
			self.nameFrame:SetWidth(128 + self.conf.size.width)
			self.statsFrame:SetWidth(128 + self.conf.size.width)
		end
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
	end

	self.conf.scale = self.conf.scale or 0.8
	if (not InCombatLockdown()) then
		self:SetScale(self.conf.scale)
	end

	XPerl_SavePosition(self, true)
end

-- XPerl_Target_Set_Bits
function XPerl_Target_Set_Bits(self)
	local _, playerClass = UnitClass("player")

	--self.buffOptionString = nil

	if (self.conf.portrait) then
		self.portraitFrame:Show()
		self.portraitFrame:SetWidth(62)
		self.statsFrame.resurrect:Hide()
	else
		self.portraitFrame:Hide()
		self.portraitFrame:SetWidth(3)
	end

	if (self.conf.values) then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
	else
		self.statsFrame.healthBar.text:Hide()
		self.statsFrame.manaBar.text:Hide()
	end

	self.eliteFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel() + 3)

	if (self.conf.level) then
		self.levelFrame:Show()
	else
		self.levelFrame:Hide()
	end

	if (self.conf.classIcon) then
		self.typeFramePlayer.classTexture:Show()
	else
		self.typeFramePlayer.classTexture:Hide()
	end

	--self.highlight:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", 26, -1)

	self.conf.buffs.size = tonumber(self.conf.buffs.size) or 20
	XPerl_SetBuffSize(self)

	if self == XPerl_Target then
		XPerl_Register_Prediction(self, tconf, function(guid)
			if guid == UnitGUID("target") then
				return "target"
			end
		end, "target")
	end
	if self == XPerl_Focus then
		XPerl_Register_Prediction(self, fconf, function(guid)
			if guid == UnitGUID("focus") then
				return "focus"
			end
		end, "focus")
	end
	XPerl_Target_SetWidth(self)

	if (not InCombatLockdown()) then
		if (self.conf.enable) then
			RegisterUnitWatch(self)
		else
			self:Hide()
			UnregisterUnitWatch(self)
		end
	end

	if (self == XPerl_Target) then
		XPerl_Target_Set_BlizzCPFrame(self)
	end

	XPerl_StatsFrameSetup(self)

	if (self.conf.ownDamageOnly and (self.conf.hitIndicator and self.conf.portrait)) then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	else
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end

	self.buffFrame:ClearAllPoints()
	if (self.conf.buffs.above) then
		self.buffFrame:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 2, 0)
	else
		self.buffFrame:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", 2, 0)
	end
	self.buffOptMix = nil

	if (self:IsShown()) then
		XPerl_Target_UpdateDisplay(self)
	end
end

function XPerl_Target_ComboFrame_Update()
	local comboPoints = IsClassic and GetComboPoints("player", "target") or UnitPower(UnitHasVehicleUI("player") and "vehicle" or "player", Enum.PowerType.ComboPoints)
	if comboPoints > 0 and UnitCanAttack((not IsClassic and UnitHasVehicleUI("player")) and "vehicle" or "player", "target") then
		if not ComboFrame:IsShown() then
			ComboFrame:Show()
			UIFrameFadeIn(ComboFrame, COMBOFRAME_FADE_IN)
		end

		local fadeInfo = { }
		for i = 1, not IsClassic and 9 or 5 do
			local comboPoint = _G["ComboPoint"..i]
			if i < 6 then
				comboPoint:Show()
			else
				if comboPoints >= i then
					comboPoint:Show()
				else
					comboPoint:Hide()
				end
			end
			if i <= comboPoints then
				if i > (ComboFrame.lastPoints or 0) then
					-- Fade in the highlight and set a function that triggers when it is done fading
					fadeInfo.mode = "IN"
					fadeInfo.timeToFade = COMBOFRAME_HIGHLIGHT_FADE_IN
					fadeInfo.finishedFunc = ComboPointShineFadeIn
					fadeInfo.finishedArg1 = comboPoint.Shine
					UIFrameFade(comboPoint.Highlight, fadeInfo)
				end
			else
				--[[if ENABLE_COLORBLIND_MODE == "1" then
					comboPoint:Hide()
				end]]
				comboPoint.Highlight:SetAlpha(0)
				comboPoint.Shine:SetAlpha(0)
			end
		end
		ComboPoint1.Highlight:SetAlpha(1)
	else
		--ComboPoint1.Highlight:SetAlpha(0)
		--ComboPoint1.Shine:SetAlpha(0)
		ComboFrame:Hide()
	end
	ComboFrame.lastPoints = comboPoints
end

function XPerl_Target_ComboFrame_OnEvent(self, event, ...)
	if (event == "PLAYER_TARGET_CHANGED") then
		XPerl_Target_ComboFrame_Update()
	end
end

-- Using the Blizzard Combo Point frame, but we move the buttons around a little
function XPerl_Target_Set_BlizzCPFrame(self)
	if tconf.combo.blizzard then
		ComboFrame:ClearAllPoints()
		for i = 1, not IsClassic and 9 or 5 do
			local combo = _G["ComboPoint"..i]
			if i < 9 then
				combo:ClearAllPoints()

				if i < 6 then
					combo:SetAlpha(1)
				else
					combo:SetAlpha(0.5)
				end
			else
				combo:ClearAllPoints()
				combo:Hide()
			end
		end

		if tconf.combo.pos == "top" then
			ComboFrame:SetPoint("TOP", self.portraitFrame, "TOP", 98, 4)
			ComboPoint1:SetPoint("TOPLEFT", 0, 0)
			ComboPoint2:SetPoint("LEFT", ComboPoint1, "RIGHT", 0, 1)
			ComboPoint3:SetPoint("LEFT", ComboPoint2, "RIGHT", 0, 1)
			ComboPoint4:SetPoint("LEFT", ComboPoint3, "RIGHT", 0, -1)
			ComboPoint5:SetPoint("LEFT", ComboPoint4, "RIGHT", 0, -1)
			if not IsClassic then
				ComboPoint6:SetPoint("TOPLEFT", ComboPoint2, "BOTTOMLEFT", 0, 0)
				ComboPoint7:SetPoint("TOPLEFT", ComboPoint3, "BOTTOMLEFT", 0, 0)
				ComboPoint8:SetPoint("TOPLEFT", ComboPoint4, "BOTTOMLEFT", 0, 0)
			end
		elseif tconf.combo.pos == "bottom" then
			ComboFrame:SetPoint("BOTTOM", self.portraitFrame, "BOTTOM", 98, -4)
			ComboPoint1:SetPoint("BOTTOMLEFT", 0, 0)
			ComboPoint2:SetPoint("LEFT", ComboPoint1, "RIGHT", 0, -1)
			ComboPoint3:SetPoint("LEFT", ComboPoint2, "RIGHT", 0, -1)
			ComboPoint4:SetPoint("LEFT", ComboPoint3, "RIGHT", 0, 1)
			ComboPoint5:SetPoint("LEFT", ComboPoint4, "RIGHT", 0, 1)
			if not IsClassic then
				ComboPoint6:SetPoint("BOTTOMLEFT", ComboPoint2, "TOPLEFT", 0, 0)
				ComboPoint7:SetPoint("BOTTOMLEFT", ComboPoint3, "TOPLEFT", 0, 0)
				ComboPoint8:SetPoint("BOTTOMLEFT", ComboPoint4, "TOPLEFT", 0, 0)
			end
		elseif tconf.combo.pos == "left" then
			ComboFrame:SetPoint("BOTTOMLEFT", self.portraitFrame, "BOTTOMLEFT", -1, 0)
			ComboPoint1:SetPoint("BOTTOMLEFT", 0, 0)
			ComboPoint2:SetPoint("BOTTOM", ComboPoint1, "TOP", -1, 0)
			ComboPoint3:SetPoint("BOTTOM", ComboPoint2, "TOP", -1, 0)
			ComboPoint4:SetPoint("BOTTOM", ComboPoint3, "TOP", 1, 0)
			ComboPoint5:SetPoint("BOTTOM", ComboPoint4, "TOP", 1, 0)
			if not IsClassic then
				ComboPoint6:SetPoint("TOPLEFT", ComboPoint2, "TOPRIGHT", 0, 0)
				ComboPoint7:SetPoint("TOPLEFT", ComboPoint3, "TOPRIGHT", 0, 0)
				ComboPoint8:SetPoint("TOPLEFT", ComboPoint4, "TOPRIGHT", 0, 0)
			end
		elseif tconf.combo.pos == "right" then
			ComboFrame:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", 2, 0)
			ComboPoint1:SetPoint("BOTTOMRIGHT", 0, 0)
			ComboPoint2:SetPoint("BOTTOM", ComboPoint1, "TOP", 1, 0)
			ComboPoint3:SetPoint("BOTTOM", ComboPoint2, "TOP", 1, 0)
			ComboPoint4:SetPoint("BOTTOM", ComboPoint3, "TOP", -1, 0)
			ComboPoint5:SetPoint("BOTTOM", ComboPoint4, "TOP", -1, 0)
			if not IsClassic then
				ComboPoint6:SetPoint("TOPRIGHT", ComboPoint2, "TOPLEFT", 0, 0)
				ComboPoint7:SetPoint("TOPRIGHT", ComboPoint3, "TOPLEFT", 0, 0)
				ComboPoint8:SetPoint("TOPRIGHT", ComboPoint4, "TOPLEFT", 0, 0)
			end
		else
			ComboFrame:SetPoint("TOP", self.portraitFrame, "TOP", 98, 4)
			ComboPoint1:SetPoint("TOPLEFT", 0, 0)
			ComboPoint2:SetPoint("LEFT", ComboPoint1, "RIGHT", 0, 1)
			ComboPoint3:SetPoint("LEFT", ComboPoint2, "RIGHT", 0, 1)
			ComboPoint4:SetPoint("LEFT", ComboPoint3, "RIGHT", 0, -1)
			ComboPoint5:SetPoint("LEFT", ComboPoint4, "RIGHT", 0, -1)
			if not IsClassic then
				ComboPoint6:SetPoint("TOPLEFT", ComboPoint2, "BOTTOMLEFT", 0, 0)
				ComboPoint7:SetPoint("TOPLEFT", ComboPoint3, "BOTTOMLEFT", 0, 0)
				ComboPoint8:SetPoint("TOPLEFT", ComboPoint4, "BOTTOMLEFT", 0, 0)
			end
		end

		ComboFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

		ComboFrame:SetScript("OnEvent", XPerl_Target_ComboFrame_OnEvent)
		ComboFrame:SetParent(XPerl_Target)

		XPerl_Target_ComboFrame_Update()
	else
		ComboFrame:Hide()
		ComboFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
	end
end
