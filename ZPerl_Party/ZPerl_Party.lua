-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local XPerl_Party_Events = { }
--local checkRaidNextUpdate
local PartyFrames = { }
local startupDone
local conf, pconf
XPerl_RequestConfig(function(new)
	conf = new
	pconf = new.party
	for k, v in pairs(PartyFrames) do
		v.conf = pconf
	end
end, "$Revision: @file-revision@ $")

local percD = "%d"..PERCENT_SYMBOL

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsWrathClassic = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

local ceil = ceil
local floor = floor
local format = format
local max = max
local pairs = pairs
local pcall = pcall
local strfind = strfind
local strmatch = strmatch
local tonumber = tonumber
local type = type
local wipe = wipe

local CheckInteractDistance = CheckInteractDistance
local GetLootMethod = GetLootMethod
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local RegisterUnitWatch = RegisterUnitWatch
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsAFK = UnitIsAFK
local UnitIsCharmed = UnitIsCharmed
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsDND = UnitIsDND
local UnitIsGhost = UnitIsGhost
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitIsMercenary = UnitIsMercenary
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitName = UnitName
local UnitPhaseReason = UnitPhaseReason
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnregisterUnitWatch = UnregisterUnitWatch

local CombatFeedback_Initialize = CombatFeedback_Initialize
local CombatFeedback_OnCombatEvent = CombatFeedback_OnCombatEvent
local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate

local partyHeader
local partyAnchor


local XPerl_Party_HighlightCallback

local feignDeath = GetSpellInfo(5384)

----------------------
-- Loading Function --
----------------------
function XPerl_Party_Events_OnLoad(self)
	local events = {
		"PLAYER_ENTERING_WORLD",
		"PLAYER_TARGET_CHANGED",
		"PLAYER_LOGIN",
		"PLAYER_FLAGS_CHANGED",
		"GROUP_ROSTER_UPDATE",
		"UNIT_CONNECTION",
		"UNIT_PHASE",
		"UNIT_COMBAT",
		"UNIT_FACTION",
		"UNIT_FLAGS",
		"UNIT_AURA",
		"UNIT_PORTRAIT_UPDATE",
		"UNIT_TARGET",
		"UNIT_HEAL_PREDICTION",
		"UNIT_ABSORB_AMOUNT_CHANGED",
		"UNIT_POWER_FREQUENT",
		"UNIT_MAXPOWER",
		IsClassic and "UNIT_HEALTH_FREQUENT" or "UNIT_HEALTH",
		"UNIT_MAXHEALTH",
		"UNIT_LEVEL",
		"UNIT_DISPLAYPOWER",
		"UNIT_NAME_UPDATE",
		"UNIT_THREAT_LIST_UPDATE",
		"RAID_TARGET_UPDATE",
		"READY_CHECK",
		"READY_CHECK_CONFIRM",
		"READY_CHECK_FINISHED",
		"PARTY_LOOT_METHOD_CHANGED",
		--"PET_BATTLE_OPENING_START",
		--"PET_BATTLE_CLOSE",
		"INCOMING_RESURRECT_CHANGED",
	}
	for i, event in pairs(events) do
		if pcall(self.RegisterEvent, self, event) then
			self:RegisterEvent(event)
		end
	end

	--partyHeader:UnregisterEvent("UNIT_NAME_UPDATE") -- IMPORTANT! Fix for WoW 2.1 UNIT_NAME_UPDATE lockup issues

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE") -- IMPORTANT! Stops raid framerate lagging when members join/leave/zone

	if IsRetail then
		XPerl_BlizzFrameDisable(PartyFrame)
	else
		for i = 1, 4 do
			XPerl_BlizzFrameDisable(_G["PartyMemberFrame"..i])
		end
	end

	self:SetScript("OnEvent", XPerl_Party_OnEvent)
	XPerl_RegisterOptionChanger(XPerl_Party_Set_Bits)
	XPerl_Highlight:Register(XPerl_Party_HighlightCallback, self)

	XPerl_Party_Set_Bits()

	--XPerl_Party_Events_OnLoad = nil
end

-- XPerl_Party_HighlightCallback
function XPerl_Party_HighlightCallback(self, updateGUID)
	if not updateGUID then
		return
	end

	local f = XPerl_Party_GetUnitFrameByGUID(updateGUID)
	if (f) then
		XPerl_Highlight:SetHighlight(f, updateGUID)
	end
end

-- SetFrameArray
local function SetFrameArray(self, value)
	for k, v in pairs(PartyFrames) do
		if (v == self) then
			PartyFrames[k] = nil
			if (XPerl_Party_Pet_ClearFrame) then
				local petid
				if k == "player" then
					petid = "pet"
				else
					petid = "partypet"..strmatch(k, "^party(%d)")
				end
				XPerl_Party_Pet_ClearFrame(petid)
			end
		end
	end

	self.partyid = value
	if (value) then
		self.targetid = value.."target"
		PartyFrames[value] = self
		if (XPerl_Party_Pet_SetFrame) then
			local petid
			if value == "player" then
				petid = "pet"
			else
				petid = "partypet"..strmatch(value, "^party(%d)")
			end
			XPerl_Party_Pet_SetFrame(self:GetID(), petid, value)
		end
	end
end

-- onAttrChanged
local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value and value ~= "party0") then
			SetFrameArray(self, value)
			if (self.partyid ~= value or self.lastName ~= UnitName(value) or self.lastGUID ~= UnitGUID(value)) then
				if (conf) then
					XPerl_Party_UpdateDisplay(self, true)
				end
				--[[if (XPerl_ArcaneBar_RegisterFrame) then
					XPerl_ArcaneBar_RegisterFrame(self.nameFrame, value)
				end]]
			end
		else
			SetFrameArray(self)
		end
	end
end

-- ZPerl_Party_OnLoad
function ZPerl_Party_OnLoad(self)
	XPerl_SetChildMembers(self)
	self.targetFrame.statsFrame = self.targetFrame.healthBar -- So the healthbar fades as part of pseudo statsFrame

	partyHeader = ZPerl_Party_SecureHeader
	partyAnchor = XPerl_Party_Anchor

	local id = strmatch(self:GetName(), ".+(%d)")
	self:SetID(tonumber(id))
	--_G["XPerl_party"..self:GetID()] = self

	if (self:GetID() > 1) then
		self.buffSetup = XPerl_party1.buffSetup
	else
		local BuffOnUpdate, DebuffOnUpdate, BuffUpdateTooltip, DebuffUpdateTooltip
		BuffUpdateTooltip = XPerl_Unit_SetBuffTooltip
		DebuffUpdateTooltip = XPerl_Unit_SetDebuffTooltip

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
			debuffSizeMod = 0.4,
			debuffAnchor1 = function(self, b)
				if (pconf.flip) then
					b:SetPoint("RIGHT", self.statsFrame, "LEFT", 0, 0)
				else
					b:SetPoint("LEFT", self.statsFrame, "RIGHT", 0, 0)
				end
			end,
			buffAnchor1 = function(self, b)
				if (pconf.flip) then
					b:SetPoint("TOPRIGHT", self.buffFrame, "TOPRIGHT", 0, 0)
				else
					b:SetPoint("TOPLEFT", self.buffFrame, "TOPLEFT", 0, 0)
				end
			end,
		}
	end

	partyHeader:SetAttribute("showPlayer", pconf.showPlayer)
	partyHeader:SetAttribute("child"..self:GetID(), self)
	if partyHeader:GetAttribute("showPlayer") then
		if self:GetID() == 1 then
			self.partyid = "player"
		else
			self.partyid = "party"..(self:GetID() - 1)
		end
	else
		self.partyid = "party"..self:GetID()
	end
	PartyFrames[self.partyid] = self

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	self.hitIndicator.text:SetPoint("CENTER", self.portraitFrame, "CENTER", 0, 0)

	self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")

	XPerl_RegisterClickCastFrame(self.nameFrame)
	XPerl_RegisterClickCastFrame(self)

	self.time = 0
	self.flagsCheck = 0

	XPerl_RegisterHighlight(self.highlight, 3)
	XPerl_RegisterHighlight(self.targetFrame, 3)
	XPerl_RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.portraitFrame, self.levelFrame, self.targetFrame})

	self.FlashFrames = {self.nameFrame, self.levelFrame, self.statsFrame, self.portraitFrame}

	self:SetScript("OnUpdate", XPerl_Party_OnUpdate)
	self:SetScript("OnAttributeChanged", onAttrChanged)
	self:SetScript("OnShow", XPerl_Party_UpdateDisplay) -- XPerl_Unit_UpdatePortrait)

	self.targetFrame:SetScript("OnUpdate", XPerl_Party_Target_OnUpdate)

	if (XPerl_ArcaneBar_RegisterFrame) then
		if self.partyid == "player" then
			XPerl_ArcaneBar_RegisterFrame(self.nameFrame, "party"..self.partyid)
		else
			XPerl_ArcaneBar_RegisterFrame(self.nameFrame, self.partyid)
		end
	end

	if (XPerlDB) then
		self.conf = XPerlDB.party
	end

	XPerl_Party_Set_Bits1(self)

	--[[if (XPerl_party1 and XPerl_party2 and XPerl_party3 and XPerl_party4) then
		ZPerl_Party_OnLoad = nil
	end]]
end

-- ShowHideValues
local function ShowHideValues(self)
	if (pconf.values) then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
	else
		if (not self.hideValues) then
			self.statsFrame.healthBar.text:Hide()
			self.statsFrame.manaBar.text:Hide()
		end
	end
end

-- XPerl_Party_UpdateHealPrediction
local function XPerl_Party_UpdateHealPrediction(self)
	if pconf.healprediction then
		XPerl_SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

-- XPerl_Party_UpdateAbsorbPrediction
local function XPerl_Party_UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end
-- XPerl_Party_UpdateHotsPrediction
local function XPerl_Party_UpdateHotsPrediction(self)
	if not IsWrathClassic then
		return
	end
	if pconf.hotPrediction then
		XPerl_SetExpectedHots(self)
	else
		self.statsFrame.expectedHots:Hide()
	end
end

local function XPerl_Party_UpdateResurrectionStatus(self)
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

local spiritOfRedemption = GetSpellInfo(27827)

-- XPerl_Party_UpdateHealth
local function XPerl_Party_UpdateHealth(self)
	if (not self.conf) then
		return
	end
	local partyid = self.partyid
	local Partyhealth, Partyhealthmax = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid)), UnitHealthMax(partyid)
	local reason

	--[[if (self.feigning and not UnitBuff(partyid, feignDeath)) then
		self.feigning = nil
	end]]

	XPerl_SetHealthBar(self, Partyhealth, Partyhealthmax)

	XPerl_Party_UpdateAbsorbPrediction(self)
	XPerl_Party_UpdateHealPrediction(self)
	XPerl_Party_UpdateHotsPrediction(self)
	XPerl_Party_UpdateResurrectionStatus(self)

	if (not UnitIsConnected(partyid)) then
		reason = XPERL_LOC_OFFLINE
	else
		--[[if (UnitBuff(partyid, feignDeath) and conf.showFD) then
			reason = XPERL_LOC_FEIGNDEATH
		else--]]if (self.afk and conf.showAFK) then
			reason = CHAT_MSG_AFK
		elseif (UnitIsDead(partyid)) then
			reason = XPERL_LOC_DEAD
		elseif (UnitIsGhost(partyid)) then
			reason = XPERL_LOC_GHOST
		elseif ((Partyhealth == 1) and (Partyhealthmax == 1)) then
			reason = XPERL_LOC_UPDATING
		--[[elseif (UnitBuff(partyid, spiritOfRedemption)) then
			reason = XPERL_LOC_DEAD--]]
		end
	end

	ShowHideValues(self)
	if (reason) then
		if (pconf.percent) then
			local old = self.statsFrame.healthBar.percent:GetText()
			self.statsFrame.healthBar.percent:SetText(reason)

			if (self.statsFrame.healthBar.percent:GetStringWidth() > (self.statsFrame:GetWidth() - self.statsFrame.healthBar:GetWidth() - 8)) then
				self.statsFrame.healthBar.percent:SetText(old)
				self.statsFrame.healthBar.text:SetText(reason)
				self.statsFrame.healthBar.text:Show()
			else
				self.statsFrame.healthBar.percent:Show()
			end
		else
			self.statsFrame.healthBar.text:SetText(reason)
			self.statsFrame.healthBar.text:Show()
		end

		self.statsFrame:SetGrey()
	else
		if (self.statsFrame.greyMana) then
			self.statsFrame.greyMana = nil
			XPerl_SetManaBarType(self)
		end
	end
end

-- XPerl_Party_UpdatePlayerFlags(self)
local function XPerl_Party_UpdatePlayerFlags(self)
	local change
	if (UnitIsAFK(self.partyid) and conf.showAFK) then
		if (not self.afk) then
			change = true
			self.afk = GetTime()
			self.dnd = nil
		end
	elseif (UnitIsDND(self.partyid)) then
		if (self.afk) then
			change = true
			self.afk = nil
		end
	else
		if (self.afk or self.dnd) then
			self.afk, self.dnd = nil, nil
			change = true
		end
	end

	if (change) then
		XPerl_Party_UpdateHealth(self)
	end
end

--------------------
-- Buff Functions --
--------------------

-- XPerl_Party_SetDebuffLocation
function XPerl_Party_SetDebuffLocation(self)
	local debuff1 = self.buffFrame.debuff and self.buffFrame.debuff[1]
	if (debuff1) then
		debuff1:ClearAllPoints()

		if (pconf.debuffs.below) then
			local buff1 = self.buffFrame.buff and self.buffFrame.buff[1]
			if (not buff1) then
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", self.buffFrame, "TOPRIGHT", 0, -20)
				else
					debuff1:SetPoint("TOPLEFT", self.buffFrame, "TOPLEFT", 0, -20)
				end
			else
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", buff1, "BOTTOMRIGHT", 0, -2)
				else
					debuff1:SetPoint("TOPLEFT", buff1, "BOTTOMLEFT", 0, -2)
				end
			end
		else
			if (self.petFrame and self.petFrame:IsShown()) then
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", self.petFrame.nameFrame, "TOPLEFT", 0, -4)
				else
					debuff1:SetPoint("TOPLEFT", self.petFrame.nameFrame, "TOPRIGHT", 0, -4)
				end
			else
				if (pconf.flip) then
					debuff1:SetPoint("TOPRIGHT", self.statsFrame, "TOPLEFT", 0, -4)
				else
					debuff1:SetPoint("TOPLEFT", self.statsFrame, "TOPRIGHT", 0, -4)
				end
			end

			if (pconf.debuffs.halfSize) then
				local buffWidth = debuff1:GetWidth() * debuff1:GetScale()
				local selfWidth = self:GetWidth() * self:GetScale()
				local maxDebuffWidth = floor(selfWidth / buffWidth)
				local prev
				if (self.perlDebuffs > maxDebuffWidth) then
					self.debuffFrame:SetScale(0.5)

					local Anchor, aHalf, aPrev, x
					if (pconf.flip) then
						Anchor = "TOPRIGHT"
						aHalf = "BOTTOMRIGHT"
						aPrev = "TOPLEFT"
						x = -2
					else
						Anchor = "TOPLEFT"
						aHalf = "BOTTOMLEFT"
						aPrev = "TOPRIGHT"
						x = 0
					end

					local halfPoint = ceil(self.perlBuffs / 2)
					for k, v in pairs(self.buffFrame.debuff) do
						if (prev) then
							v:ClearAllPoints()
							if (k == halfPoint) then
								v:SetPoint(Anchor, debuff1, aHalf, x, 0)
							else
								v:SetPoint(Anchor, prev, aPrev, x, 0)
							end
						end
						prev = v
					end
				else
					self.debuffFrame:SetScale(1)

					local Anchor, aPrev, x
					if (pconf.flip) then
						Anchor = "TOPRIGHT"
						aPrev = "TOPLEFT"
						x = -2
					else
						Anchor = "TOPLEFT"
						aPrev = "TOPRIGHT"
						x = 0
					end

					local prev
					for k, v in pairs(self.buffFrame.debuff) do
						if (prev) then
							v:ClearAllPoints()
							v:SetPoint(Anchor, prev, aPrev, x, 0)
						end
						prev = v
					end
				end
			else
				local Anchor, aPrev, x
				if (pconf.flip) then
					Anchor = "TOPRIGHT"
					aPrev = "TOPLEFT"
					x = -2
				else
					Anchor = "TOPLEFT"
					aPrev = "TOPRIGHT"
					x = 0
				end

				local prev
				for k, v in pairs(self.buffFrame.debuff) do
					if (prev) then
						v:ClearAllPoints()
						v:SetPoint(Anchor, prev, aPrev, x, 0)
					end
					prev = v
				end

				self.debuffFrame:SetScale(1)
			end
		end
	end
end

-- XPerl_Party_BuffPositions
local function XPerl_Party_BuffPositions(self)
	if (self.conf) then
		if (pconf.debuffs.below) then
			if (pconf.buffs.wrap) then
				XPerl_Unit_BuffPositions(self, self.buffFrame.buff, self.buffFrame.debuff, self.conf.buffs.size, self.conf.debuffs.size)
			end
		else
			-- Debuffs handled seperately by legacy code, so just do buffs
			if (pconf.buffs.wrap) then
				XPerl_Unit_BuffPositions(self, self.buffFrame.buff, nil, self.conf.buffs.size)
			end
			if pconf.debuffs.enable then
				XPerl_Party_SetDebuffLocation(self)
			end
		end
	end
end

-- XPerl_Party_Buff_UpdateAll
local function XPerl_Party_Buff_UpdateAll(self)
	--[[if not self:IsVisible() then
		return
	end]]
	if (self.conf) then
		if (not pconf.buffs.enable and not pconf.debuffs.enable) then
			self.buffFrame:Hide()
			self.debuffFrame:Hide()
		else
			XPerl_Unit_UpdateBuffs(self, nil, nil, pconf.buffs.castable, pconf.debuffs.curable)
			XPerl_Party_BuffPositions(self)
		end

		--[[if conf.showFD then
			local _, class = UnitClass(self.partyid)
			if (class == "HUNTER") then
				local feigning = UnitBuff(self.partyid, feignDeath)
				if (feigning ~= self.feigning) then
					self.feigning = feigning
					XPerl_Party_UpdateHealth(self)
				end
			end
		end--]]

		if (conf.highlightDebuffs.enable) then
			XPerl_CheckDebuffs(self, self.partyid)
		end
	end
end

-------------------------
-- The Update Function --
-------------------------
local function XPerl_Party_CombatFlash(self, elapsed, argNew, argGreen)
	if (XPerl_CombatFlashSet(self, elapsed, argNew, argGreen)) then
		XPerl_CombatFlashSetFrames(self)
	end
end

-- XPerl_Party_UpdateName
local function XPerl_Party_UpdateName(self)
	local partyid = self.partyid
	local Partyname = UnitName(partyid)
	self.lastName = Partyname
	self.lastGUID = UnitGUID(partyid)
	if (Partyname) then
		self.nameFrame.text:SetFontObject(GameFontNormal)
		self.nameFrame.text:SetText(Partyname)

		if (self.nameFrame.text:GetStringWidth() > self.nameFrame:GetWidth() - 4) then
			self.nameFrame.text:SetFontObject(GameFontNormalSmall)
		end

		XPerl_ColourFriendlyUnit(self.nameFrame.text, partyid)
	end
end

-- UpdateAssignedRoles
local function UpdateAssignedRoles(self)
	local unit = self.partyid
	local icon = self.nameFrame.roleIcon
	local isTank, isHealer, isDamage
	local inInstance, instanceType = IsInInstance()
	if not IsVanillaClassic and instanceType == "party" then
		-- No point getting it otherwise, as they can be wrong. Usually the values you had
		-- from previous instance if you're running more than one with the same people

		-- According to http://forums.worldofwarcraft.com/thread.html?topicId=26560499864
		-- this is the new way to check for roles
		-- Port this from XPerl_Player.lua by PlayerLin
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

	icon:ClearAllPoints()
	if (self.nameFrame.masterIcon:IsShown()) then
		icon:SetPoint("LEFT", self.nameFrame.masterIcon, "RIGHT")
	elseif (self.nameFrame.leaderIcon:IsShown()) then
		icon:SetPoint("LEFT", self.nameFrame.leaderIcon, "RIGHT")
	else
		icon:SetPoint("TOPLEFT", 10, 5)
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

-- UpdateAllAssignedRoles
local function UpdateAllAssignedRoles()
	for unit, frame in pairs(PartyFrames) do
		if (frame:IsShown()) then
			UpdateAssignedRoles(frame)
		end
	end
end

-- UpdatePhaseIndicators
local function UpdatePhasingDisplays(self)
	local unit = self.partyid
	local inPhase = not IsClassic and UnitPhaseReason(unit)

	if ( not inPhase or not UnitExists(unit) or not UnitIsConnected(unit)) then
		self.phasingIcon:Hide()
	else
		self.phasingIcon:Show()
	end
end

-- XPerl_Party_UpdateLeader
local function XPerl_Party_UpdateLeader(self)
	local partyid = self.partyid
	if (UnitIsGroupLeader(partyid)) then
		self.nameFrame.leaderIcon:Show()
	else
		self.nameFrame.leaderIcon:Hide()
	end

	local lootMethod, lootMaster, raidLootMaster = GetLootMethod()

	if (lootMethod == "master" and lootMaster) then
		if (partyid == "party"..lootMaster) then
			self.nameFrame.masterIcon:Show()
		else
			self.nameFrame.masterIcon:Hide()
		end
	end
	-- Removed the call to UpdateAllAssignedRoles because UpdateLeader() is called by UpdateDisplay()
	-- and UpdateDisplay() already call the UpdateAssignedRoles() function
end

-- XPerl_Party_UpdatePVP
local function XPerl_Party_UpdatePVP(self)
	local partyid = self.partyid

	local pvpIcon = self.nameFrame.pvpIcon

	local factionGroup, factionName = UnitFactionGroup(partyid)

	if pconf.pvpIcon and UnitIsPVPFreeForAll(partyid) then
		pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		pvpIcon:Show()
	elseif pconf.pvpIcon and factionGroup and factionGroup ~= "Neutral" and UnitIsPVP(partyid) then
		pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)

		if not IsClassic and UnitIsMercenary(partyid) then
			if factionGroup == "Horde" then
				pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
			elseif factionGroup == "Alliance" then
				pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
			end
		end

		pvpIcon:Show()
	else
		pvpIcon:Hide()
	end

	--[[local pvp = pconf.pvpIcon and ((UnitIsPVPFreeForAll(self.partyid) and "FFA") or (UnitIsPVP(self.partyid) and (UnitFactionGroup(self.partyid) ~= "Neutral") and UnitFactionGroup(self.partyid)))
	if (pvp) then
		self.nameFrame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		self.nameFrame.pvpIcon:Show()
	else
		self.nameFrame.pvpIcon:Hide()
	end]]
end

-- XPerl_Party_UpdateCombat
local function XPerl_Party_UpdateCombat(self)
	local partyid = self.partyid
	if (UnitIsVisible(partyid)) then
		if (UnitAffectingCombat(partyid)) then
			self.nameFrame.combatIcon:Show()
		else
			self.nameFrame.combatIcon:Hide()
		end

		if (UnitIsCharmed(partyid)) then
			self.nameFrame.warningIcon:Show()
		else
			self.nameFrame.warningIcon:Hide()
		end
	else
		self.nameFrame.combatIcon:Hide()
		self.nameFrame.warningIcon:Hide()
	end
end

-- XPerl_Party_UpdateClass
local function XPerl_Party_UpdateClass(self)
	local partyid = self.partyid
	if (UnitIsPlayer(partyid)) then
		local _, class = UnitClass(partyid)
		local l, r, t, b = XPerl_ClassPos(class)
		self.classFrame.tex:SetTexCoord(l, r, t, b)
	end

	if (pconf.classIcon) then
		self.classFrame:Show()
	else
		self.classFrame:Hide()
	end
end

-- XPerl_Party_UpdateMana
local function XPerl_Party_UpdateMana(self)
	local partyid = self.partyid
	if (self.afk and not UnitIsAFK(partyid)) then
		XPerl_Party_UpdatePlayerFlags(self)
	end

	local pType = XPerl_GetDisplayedPowerType(partyid)

	local Partymana = UnitPower(partyid, pType)
	local Partymanamax = UnitPowerMax(partyid, pType)

	--Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
	local percent
	if Partymana > 0 and Partymanamax == 0 then --We have current mana but max mana failed.
		Partymanamax = Partymana --Make max mana at least equal to current health
		percent = 1 --And percent 100% cause a number divided by itself is 1, duh.
	elseif Partymana == 0 and Partymanamax == 0 then--Probably doesn't use mana or is oom?
		percent = 0 --So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
	else
		percent = Partymana / Partymanamax--Everything is dandy, so just do it right way.
	end
	--end division by 0 check

	--[[if (Partymanamax == 1 and Partymana > Partymanamax) then
		Partymanamax = Partymana
	end--]]

	self.statsFrame.manaBar:SetMinMaxValues(0, Partymanamax)
	self.statsFrame.manaBar:SetValue(Partymana)

	if (XPerl_GetDisplayedPowerType(partyid) >= 1) then
		self.statsFrame.manaBar.percent:SetText(Partymana)
	else
		self.statsFrame.manaBar.percent:SetFormattedText(percD, 100 * percent)
	end

	--[[if (pconf.values) then
		self.statsFrame.manaBar.text:Show()
	else
		self.statsFrame.manaBar.text:Hide()
	end]]

	self.statsFrame.manaBar.text:SetFormattedText("%d/%d", Partymana, Partymanamax)

	if (not UnitIsConnected(partyid)) then
		self.statsFrame.healthBar.text:SetText(XPERL_LOC_OFFLINE)
		if (not self.statsFrame.greyMana) then
			self.statsFrame:SetGrey()
		end
	end
end

-- XPerl_Party_UpdateRange
local function XPerl_Party_UpdateRange(self, overrideUnit)
	local partyid = overrideUnit or self.partyid
	if (partyid) then
		if (not pconf.range30yard or CheckInteractDistance(partyid, 4) or not UnitIsConnected(partyid)) then
			self.nameFrame.rangeIcon:Hide()
		else
			self.nameFrame.rangeIcon:Show()
			self.nameFrame.rangeIcon:SetAlpha(1)
		end
		--[[if (UnitInVehicle(self.partyid) and pconf.range30yard) then -- Not sure if this is proper way to do it, so this pretty much forces anyone in a vehicle to show out of range.
			self.nameFrame.rangeIcon:Show()
			self.nameFrame.rangeIcon:SetAlpha(1)
		end]]
	end
end

-- XPerl_Party_SingleGroup
function XPerl_Party_SingleGroup()
	local num = GetNumGroupMembers()
	if (num > 5) then
		return
	end
	for i = 1, num do
		local _, _, subgroup = GetRaidRosterInfo(i)
		if (subgroup > 1) then
			return
		end
	end
	return true
end

-- CheckRaid
local function CheckRaid()
	if (InCombatLockdown()) then
		XPerl_OutOfCombatQueue[CheckRaid] = false
		return
	else
		if not pconf.enable then
			if partyHeader:IsShown() then
				partyHeader:Hide()
			end
			return
		end
		partyAnchor:StopMovingOrSizing()

		local singleGroup = XPerl_Party_SingleGroup()

		if (not pconf or ((pconf.inRaid and IsInRaid()) or (pconf.smallRaid and singleGroup) or (GetNumGroupMembers() > 0 and not IsInRaid()))) then -- or GetNumGroupMembers() > 0
			if not IsClassic then
				if not C_PetBattles.IsInBattle() then
					if (not partyHeader:IsShown()) then
						partyHeader:Show()
					end
				else
					if (partyHeader:IsShown()) then
						partyHeader:Hide()
					end
				end
			else
				if (not partyHeader:IsShown()) then
					partyHeader:Show()
				end
			end
		else
			if (partyHeader:IsShown()) then
				partyHeader:Hide()
			end
		end
	end
end

-- XPerl_Party_TargetUpdateHealPrediction
local function XPerl_Party_TargetUpdateHealPrediction(self)
	if pconf.healprediction then
		XPerl_SetExpectedHealth(self)
	else
		self.expectedHealth:Hide()
	end
end

-- XPerl_Party_TargetUpdateAbsorbPrediction
local function XPerl_Party_TargetUpdateAbsorbPrediction(self)
	if pconf.absorbs then
		XPerl_SetExpectedAbsorbs(self)
	else
		self.expectedAbsorbs:Hide()
	end
end

-- XPerl_Party_TargetUpdateHealth
local function XPerl_Party_TargetUpdateHealth(self)
	local tf = self.targetFrame
	local targetid = self.targetid
	local hp, hpMax, heal, absorb = UnitIsGhost(targetid) and 1 or (UnitIsDead(targetid) and 0 or UnitHealth(targetid)), UnitHealthMax(targetid), not IsVanillaClassic and UnitGetIncomingHeals(targetid), not IsClassic and UnitGetTotalAbsorbs(targetid)
	tf.lastHP, tf.lastHPMax, tf.lastHeal, tf.lastAbsorb = hp, hpMax, heal, absorb
	tf.lastUpdate = GetTime()

	--tf.healthBar:SetMinMaxValues(0, hpMax)
	--tf.healthBar:SetValue(hp)
	-- Begin 4.3 division by 0 work around to ensure we don't divide if max is 0
	local percent
	if UnitIsDeadOrGhost(targetid) then -- Probably dead target
		percent = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
	elseif hp > 0 and hpMax == 0 then -- We have current ho but max hp failed.
		hpMax = hp -- Make max hp at least equal to current health
		percent = 1 -- And percent 100% cause a number divided by itself is 1, duh.
	else
		if hpMax > 0 then
			percent = hp / hpMax--Everything is dandy, so just do it right way.
		end
	end
	--tf.healthBar:SetAlpha(1)
	-- end division by 0 check
	if (hpMax > 0) then
		tf.healthBar.text:SetFormattedText(percD, 100 * percent)	-- XPerl_Percent[floor(100 * hp / hpMax)])
		tf.healthBar:SetMinMaxValues(0, hpMax)
		tf.healthBar:SetValue(hp)
	end
	tf.healthBar.text:Show()

	XPerl_Party_TargetUpdateAbsorbPrediction(self.targetFrame)
	XPerl_Party_TargetUpdateHealPrediction(self.targetFrame)

	if (UnitIsDeadOrGhost(targetid)) then
		tf.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
		tf.healthBar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
		if (UnitIsDead(targetid)) then
			tf.healthBar.text:SetText(XPERL_LOC_DEAD)
		else
			tf.healthBar.text:SetText(XPERL_LOC_GHOST)
		end
	else
		--XPerl_ColourHealthBar(self.targetFrame, hp / hpMax, targetid)
		if hpMax > 0 then
			XPerl_SetSmoothBarColor(self.targetFrame.healthBar, percent)
		end
	end

	if (UnitAffectingCombat(targetid)) then
		tf.combatIcon:SetTexCoord(0.49, 1.0, 0.0, 0.49)
		tf.combatIcon:Show()
	else
		tf.combatIcon:Hide()
	end

	local pvp = pconf.pvpIcon and ((UnitIsPVPFreeForAll(targetid) and "FFA") or (UnitIsPVP(targetid) and (UnitFactionGroup(targetid) ~= "Neutral") and UnitFactionGroup(targetid)))
	if (pvp) then
		tf.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		tf.pvpIcon:Show()
	else
		tf.pvpIcon:Hide()
	end
end

-- XPerl_Party_TargetRaidIcon
local function XPerl_Party_TargetRaidIcon(self)
	local partyid = self.partyid
	XPerl_Update_RaidIcon(self.targetFrame.raidIcon, partyid.."target")
	XPerl_Update_RaidIcon(self.nameFrame.raidIcon, partyid)
end

-- XPerl_Party_UpdateTarget
local function XPerl_Party_UpdateTarget(self)
	if (pconf.target.enable) then
		local targetid = self.targetid
		local partyid = self.partyid
		if (targetid and UnitIsConnected(partyid) and UnitExists(partyid) and UnitIsVisible(partyid)) then
			local targetname = UnitName(targetid)
			if (targetname and targetname ~= UNKNOWNOBJECT) then
				--self.targetFrame:SetAlpha(1)
				self.targetFrame.text:SetText(targetname)
				XPerl_SetUnitNameColor(self.targetFrame.text, targetid)
				XPerl_Party_TargetUpdateHealth(self)
				XPerl_Party_TargetRaidIcon(self)
			end
		end
	end
end

-- XPerl_Party_OnUpdate
function XPerl_Party_OnUpdate(self, elapsed)
	local partyid = self.partyid
	if not partyid then
		return
	end

	if pconf.hitIndicator and pconf.portrait then
		CombatFeedback_OnUpdate(self, elapsed)
	end

	if (self.PlayerFlash) then
		XPerl_Party_CombatFlash(self, elapsed, false)
	end

	--self.time = self.time + elapsed
	--if (self.time >= 0.2) then
		--self.time = 0
		local targetid = self.targetid

		self.flagsCheck = self.flagsCheck + 1
		if (self.flagsCheck > 25) then
			XPerl_Party_UpdatePlayerFlags(self)
			self.flagsCheck = 0
		end

		if (pconf.target.large and self.targetFrame:IsShown()) then
			local hp, hpMax, heal, absorb = UnitIsGhost(targetid) and 1 or (UnitIsDead(targetid) and 0 or UnitHealth(targetid)), UnitHealthMax(targetid), not IsVanillaClassic and UnitGetIncomingHeals(targetid), not IsClassic and UnitGetTotalAbsorbs(targetid)
			if (hp ~= self.targetFrame.lastHP or hpMax ~= self.targetFrame.lastHPMax or heal ~= self.targetFrame.lastHeal or absorb ~= self.targetFrame.lastAbsorb or GetTime() > self.targetFrame.lastUpdate + 5000) then
				XPerl_Party_TargetUpdateHealth(self)
			end
		end

		self.time = self.time + elapsed
		if (self.time >= 0.2) then
			if pconf.range30yard then
				XPerl_Party_UpdateRange(self, partyid)
			end

			if conf.rangeFinder.enabled then
				XPerl_UpdateSpellRange(self, partyid)
				XPerl_UpdateSpellRange(self.targetFrame, targetid)
			end

			self.time = 0
		end

		--[=[if (checkRaidNextUpdate) then
			checkRaidNextUpdate = checkRaidNextUpdate - 1
			if (checkRaidNextUpdate <= 0) then
				checkRaidNextUpdate = nil
				CheckRaid()

				-- Due to a bug in the API (WoW 2.0.1), GetPartyLeaderIndex() can often claim
				-- that party1 is the leader, even when they're not. So, we do a delayed check
				-- after a party change
				--[[for i, frame in pairs(PartyFrames) do
					if (frame.partyid) then
						XPerl_Party_UpdateLeader(frame)
					end
				end]] -- Do we really need this now?
			end
		end]=]
	--end
end

-- XPerl_Party_Target_OnUpdate
function XPerl_Party_Target_OnUpdate(self, elapsed)
	self.time = elapsed + (self.time or 0)
	if (self.time >= 0.2) then
		XPerl_Party_UpdateTarget(self:GetParent())
		self.time = 0
	end
end

-- XPerl_Party_UpdateDisplayAll
function XPerl_Party_UpdateDisplayAll()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			XPerl_Party_UpdateDisplay(frame)
		end
	end
end

-- XPerl_Party_UpdateDisplay
function XPerl_Party_UpdateDisplay(self, less)
	if (self.conf and self.partyid and UnitExists(self.partyid)) then
		self.afk, self.dnd = nil, nil
		XPerl_Party_UpdateName(self)
		XPerl_Party_TargetRaidIcon(self)
		XPerl_Party_UpdateLeader(self)
		XPerl_Party_UpdateClass(self)
		UpdateAssignedRoles(self)
		UpdatePhasingDisplays(self)

		if (not less) then
			XPerl_SetManaBarType(self)
			XPerl_Party_UpdateMana(self)
			XPerl_Party_UpdateHealth(self)
			XPerl_Unit_UpdateLevel(self)
		end

		XPerl_Party_UpdatePlayerFlags(self)
		XPerl_Party_UpdateCombat(self)
		XPerl_Party_UpdatePVP(self)
		XPerl_Unit_UpdatePortrait(self)
		XPerl_Party_Buff_UpdateAll(self)
		XPerl_Party_UpdateTarget(self)
		XPerl_Unit_UpdateReadyState(self)
		XPerl_UpdateSpellRange(self, self.partyid)
	end
end

-------------------
-- Event Handler --
-------------------
function XPerl_Party_OnEvent(self, event, unit, ...)
	local func = XPerl_Party_Events[event]
	if (func) then
		if (strfind(event, "^UNIT_") and event ~= "UNIT_THREAT_LIST_UPDATE") then
			local f = PartyFrames[unit]
			if f then
				if event == "UNIT_CONNECTION" or event == "UNIT_PHASE" or event == "UNIT_HEAL_PREDICTION" or event == "UNIT_ABSORB_AMOUNT_CHANGED" then
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

-- PARTY_LEADER_CHANGED
-- fix by Sontix this portion of code was never called becuse the even PARTY_LEDAER_CHANGED is not registered
-- because Xperl rearrange the party members order to keep always on top the leader, UpdateDisplay() was need
-- to not mess-up party frame
-- (in that function the Leader Icon is updated, so there's no need to listen to this event)
-- function XPerl_Party_Events:PARTY_LEADER_CHANGED()
--	for i,frame in pairs(PartyFrames) do
--		if (frame.partyid) then
-- 			XPerl_Party_UpdateLeader(frame)
-- 		end
-- 	end
-- end

function XPerl_Party_Events:PARTY_LOOT_METHOD_CHANGED()
	local lootMethod, pindex,rindex = GetLootMethod()

	if (lootMethod == "master") then
		for i, frame in pairs(PartyFrames) do
			if (frame.partyid) then

				if (rindex == nil) then
					if (frame.partyid == "party"..pindex) then
						frame.nameFrame.masterIcon:Show()
					else
						frame.nameFrame.masterIcon:Hide()
					end
				else
					--If we are also in a raid group
					if (UnitIsUnit("raid"..rindex,frame.partyid)) then
						frame.nameFrame.masterIcon:Show()
					else
						frame.nameFrame.masterIcon:Hide()
					end
				end
			end
		end
	end
end

--[[function XPerl_Party_Events:PET_BATTLE_OPENING_START()
	CheckRaid()
end

function XPerl_Party_Events:PET_BATTLE_CLOSE()
	CheckRaid()
end]]

-- RAID_TARGET_UPDATE
function XPerl_Party_Events:RAID_TARGET_UPDATE()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			XPerl_Party_TargetRaidIcon(frame)
		end
	end
end

-- READY_CHECK
function XPerl_Party_Events:READY_CHECK()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			XPerl_Unit_UpdateReadyState(frame)
		end
	end
end

XPerl_Party_Events.READY_CHECK_CONFIRM = XPerl_Party_Events.READY_CHECK
XPerl_Party_Events.READY_CHECK_FINISHED = XPerl_Party_Events.READY_CHECK

-- UNIT_COMBAT
function XPerl_Party_Events:UNIT_COMBAT(...)
	local action, descriptor, damage, damageType = ...

	if (pconf.hitIndicator and pconf.portrait) then
		CombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
	end

	XPerl_Party_UpdateCombat(self)
	if (action == "HEAL") then
		XPerl_Party_CombatFlash(self, 0, true, true)
	elseif (damage and damage > 0) then
		XPerl_Party_CombatFlash(self, 0, true)
	end
end

-- UNIT_MAXHEALTH
function XPerl_Party_Events:UNIT_MAXHEALTH()
	XPerl_Party_UpdateHealth(self)
	XPerl_Unit_UpdateLevel(self) -- Level not available until we've received maxhealth
	XPerl_Party_UpdateClass(self)
end

-- UNIT_HEALTH_FREQUENT
function XPerl_Party_Events:UNIT_HEALTH_FREQUENT()
	XPerl_Party_UpdateHealth(self)
end

-- UNIT_HEALTH
function XPerl_Party_Events:UNIT_HEALTH()
	XPerl_Party_UpdateHealth(self)
end

-- UNIT_CONNECTION
function XPerl_Party_Events:UNIT_CONNECTION(unit, online)
	if (unit == self.partyid) then
		XPerl_Party_UpdateDisplay(self)
	end
end

-- UNIT_PHASE
function XPerl_Party_Events:UNIT_PHASE(unit)
	if (unit == self.partyid) then
		XPerl_Party_UpdateDisplay(self)
	end
end

local function updatePartyThreat(immediate)
	for unitid, frame in pairs(PartyFrames) do
		if (frame:IsShown()) then
			XPerl_Unit_ThreatStatus(frame, nil, immediate)
		end
	end
end

function XPerl_Party_Events:UNIT_THREAT_LIST_UPDATE(unit)
	if (unit == "target") then
		updatePartyThreat()
	end
end

function XPerl_Party_Events:PLAYER_TARGET_CHANGED()
	if partyHeader:GetAttribute("showPlayer") then
		local f = PartyFrames["player"]
		if f then
			--XPerl_Party_UpdateDisplay(f)
			XPerl_Party_UpdateTarget(f)
			XPerl_UpdateSpellRange(f.targetFrame, "target")
		end
	end
	updatePartyThreat(true)
end

-- PLAYER_ENTERING_WORLD
function XPerl_Party_Events:PLAYER_ENTERING_WORLD()
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE") -- Re-do, in case

	if (not startupDone) then
		startupDone = true
		XPerl_ProtectedCall(XPerl_Party_SetInitialAttributes)
		CheckRaid()
	end

	XPerl_Party_UpdateDisplayAll()
end

-- XPerl_Party_GetUnitFrameByUnit
function XPerl_Party_GetUnitFrameByUnit(unitid)
	return PartyFrames[unitid]
end

local rosterGuids = { }
-- XPerl_Party_GetUnitFrameByGUID
function XPerl_Party_GetUnitFrameByGUID(guid)
	local unitid = rosterGuids and rosterGuids[guid]
	if (unitid) then
		return PartyFrames[unitid]
	end
end

local function BuildGuidMap()
	if (GetNumSubgroupMembers() > 0) then
		--rosterGuids = XPerl_GetReusableTable()
		wipe(rosterGuids)
		if partyHeader:GetAttribute("showPlayer") then
			local guid = UnitGUID("player")
			if (guid) then
				rosterGuids[guid] = "player"
			end
		end
		for i = 1, GetNumSubgroupMembers() do
			local guid = UnitGUID("party"..i)
			if (guid) then
				rosterGuids[guid] = "party"..i
			end
		end
	else
		--rosterGuids = XPerl_FreeTable(rosterGuids)
		rosterGuids = { }
	end
end

function XPerl_Party_Events:GROUP_ROSTER_UPDATE()
	BuildGuidMap()
	--checkRaidNextUpdate = 3
	CheckRaid()
	XPerl_SetHighlights()
	XPerl_Party_UpdateDisplayAll()
end

XPerl_Party_Events.PLAYER_LOGIN = XPerl_Party_Events.GROUP_ROSTER_UPDATE

-- UNIT_PORTRAIT_UPDATE
function XPerl_Party_Events:UNIT_PORTRAIT_UPDATE()
	XPerl_Unit_UpdatePortrait(self, true)
end

-- UNIT_POWER_FREQUENT / UNIT_MAXPOWER
function XPerl_Party_Events:UNIT_POWER_FREQUENT()
	XPerl_Party_UpdateMana(self)
end

XPerl_Party_Events.UNIT_MAXPOWER = XPerl_Party_Events.UNIT_POWER_FREQUENT

-- UNIT_DISPLAYPOWER
function XPerl_Party_Events:UNIT_DISPLAYPOWER()
	XPerl_SetManaBarType(self)
	XPerl_Party_UpdateMana(self)
end

-- PLAYER_FLAGS_CHANGED()
function XPerl_Party_Events:PLAYER_FLAGS_CHANGED(unit)
	local f = PartyFrames[unit]
	if (f) then
		XPerl_Party_UpdatePlayerFlags(f)
	end
end

function XPerl_Party_Events:INCOMING_RESURRECT_CHANGED(unit)
	local f = PartyFrames[unit]
	if (f) then
		XPerl_Party_UpdateResurrectionStatus(f)
	end
end


-- UNIT_NAME_UPDATE
function XPerl_Party_Events:UNIT_NAME_UPDATE()
	XPerl_Party_UpdateName(self)
	XPerl_Party_UpdateHealth(self) -- Flags, class etc. not available until the first UNIT_NAME_UPDATE
	XPerl_Party_UpdateClass(self)
end

-- UNIT_LEVEL
function XPerl_Party_Events:UNIT_LEVEL()
	XPerl_Unit_UpdateLevel(self)
end

-- UNIT_AURA
function XPerl_Party_Events:UNIT_AURA()
	XPerl_Party_Buff_UpdateAll(self)
end

-- UNIT_FACTION
function XPerl_Party_Events:UNIT_FACTION(unit)
	XPerl_Party_UpdateName(self)
	XPerl_Party_UpdateCombat(self)
	XPerl_Party_UpdatePVP(self)
	XPerl_Unit_ThreatStatus(self)
end

XPerl_Party_Events.UNIT_FLAGS = XPerl_Party_Events.UNIT_FACTION

function XPerl_Party_Events:UNIT_TARGET()
	XPerl_Party_UpdateTarget(self)
	updatePartyThreat(true)
end

function XPerl_Party_Events:UNIT_HEAL_PREDICTION(unit)
	if pconf.healprediction and unit == self.partyid then
		XPerl_SetExpectedHealth(self)
	end
	if not IsWrathClassic then
		return
	end
	if pconf.hotPrediction and unit == self.partyid then
		XPerl_SetExpectedHots(self)
	end
end

function XPerl_Party_Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if (pconf.absorbs and unit == self.partyid) then
		XPerl_SetExpectedAbsorbs(self)
	end
end

---- Moving stuff ----
-- XPerl_Party_GetGap
function XPerl_Party_GetGap()
	--return floor(floor((XPerl_party1:GetBottom() - XPerl_party2:GetTop() + 0.01) * 100) / 100)
	return pconf.spacing
end

-- XPerl_Party_SetGap
function XPerl_Party_SetGap(newGap)
	if (type(newGap) ~= "number") then
		return
	end
	pconf.spacing = newGap
	XPerl_Party_SetMainAttributes()
	XPerl_Party_Virtual(true)
end

-- CalcWidth
local function CalcWidth(self)
	--return XPerl_party1Highlight:GetWidth()

	local w = self.statsFrame:GetWidth() or 0

	if (pconf and pconf.portrait) then
		w = w + (self.portraitFrame:GetWidth() or 0) - 2

		--[[if (pconf.level or pconf.classIcon) then
			w = w + (self.levelFrame:GetWidth() or 0) - 2
		end]]
	else
		w = w + (self.levelFrame:GetWidth() or 0) - 2
	end

	return w
end

-- CalcHeight
local function CalcHeight(self)
	--return XPerl_party1Highlight:GetHeight()

	if (pconf and pconf.portrait) then
		return self.portraitFrame:GetHeight() + 1
	end

	local h = self.statsFrame:GetHeight()

	if (pconf and pconf.name) then
		h = h + self.nameFrame:GetHeight() - 2
	end

	return h
end

-- XPerl_Party_SetWidth
function XPerl_Party_SetWidth(self)

	pconf.size.width = max(0, pconf.size.width or 0)

	local width = (36 * (pconf.percent or 0)) + 122	-- 158 enabled, 122 disabled
	self.statsFrame:SetWidth(width + pconf.size.width)
	self:SetWidth(CalcWidth(self))

	self.nameFrame:SetWidth(122 + (pconf.size.width / 2))

	XPerl_StatsFrameSetup(self)
end

-- XPerl_Party_Set_Bits
function XPerl_Party_Set_Bits1(self)
	if (InCombatLockdown()) then
		XPerl_OutOfCombatQueue[XPerl_Party_Set_Bits1] = self
		return
	end

	self.portraitFrame:ClearAllPoints()
	self.nameFrame:ClearAllPoints()
	self.levelFrame:ClearAllPoints()
	self.statsFrame:ClearAllPoints()
	self.classFrame:ClearAllPoints()
	self.levelFrame.text:ClearAllPoints()
	self.highlight:ClearAllPoints()

	if (not pconf.portrait) then
		self.portraitFrame:Hide()

		self.levelFrame:SetWidth(30)
		self.levelFrame:SetHeight(41)

		if (pconf.flip) then
			self.nameFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			self.levelFrame:SetPoint("TOPRIGHT", self.nameFrame, "BOTTOMRIGHT", 0, 3)
			self.statsFrame:SetPoint("TOPRIGHT", self.levelFrame, "TOPLEFT", 2, 0)

			self.levelFrame.text:SetPoint("BOTTOM", self.levelFrame, "BOTTOM", 0, 4)
			self.classFrame:SetPoint("TOPRIGHT", self.levelFrame, "TOPRIGHT", -5, -5)

			self.buffFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -2, 0)

			self.highlight:SetPoint("TOPRIGHT", self.nameFrame, "TOPRIGHT", 0, 0)
			self.highlight:SetPoint("BOTTOMLEFT", self.statsFrame, "BOTTOMLEFT", 0, 0)
		else
			self.nameFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.levelFrame:SetPoint("TOPLEFT", self.nameFrame, "BOTTOMLEFT", 0, 3)
			self.statsFrame:SetPoint("TOPLEFT", self.levelFrame, "TOPRIGHT", -2, 0)

			self.levelFrame.text:SetPoint("BOTTOM", self.levelFrame, "BOTTOM", 0, 4)
			self.classFrame:SetPoint("TOPLEFT", self.levelFrame, "TOPLEFT", 5, -5)

			self.buffFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, 0)

			self.highlight:SetPoint("TOPLEFT", self.nameFrame, "TOPLEFT", 0, 0)
			self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
		end
	else
		self.portraitFrame:Show()
		self.statsFrame.resurrect:Hide()

		self.levelFrame:SetWidth(27)
		self.levelFrame:SetHeight(22)

		if (pconf.flip) then
			self.portraitFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			self.levelFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, 0)
			self.nameFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPLEFT", 2, 0)
			self.statsFrame:SetPoint("TOPRIGHT", self.nameFrame, "BOTTOMRIGHT", 0, 3)

			self.levelFrame.text:SetPoint("CENTER", 0, 0)
			self.classFrame:SetPoint("BOTTOMLEFT", self.portraitFrame, "BOTTOMRIGHT", 0, 3)

			self.buffFrame:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -2, 0)

			self.highlight:SetPoint("TOPRIGHT", self.portraitFrame, "TOPRIGHT", 0, 0)
			self.highlight:SetPoint("BOTTOMLEFT", self.statsFrame, "BOTTOMLEFT", 0, 0)
		else
			self.portraitFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.levelFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPLEFT", 2, 0)
			self.nameFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, 0)
			self.statsFrame:SetPoint("TOPLEFT", self.nameFrame, "BOTTOMLEFT", 0, 3)

			self.levelFrame.text:SetPoint("CENTER", 0, 0)
			self.classFrame:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMLEFT", 0, 3)

			self.buffFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 2, 0)

			self.highlight:SetPoint("TOPLEFT", self.portraitFrame, "TOPLEFT", 0, 0)
			self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
		end
	end

	if (pconf.level) then
		self.levelFrame.text:Show()
		self.levelFrame:Show()

		if (pconf.portrait) then
			self.levelFrame:SetWidth(27)
		else
			self.levelFrame:SetWidth(30)
		end
	else
		self.levelFrame.text:Hide()
		self.levelFrame:Hide()
	end

	if (pconf.classIcon) then
		self.classFrame:Show()
		--self.levelFrame:Show()

		if (pconf.portrait) then
			self.levelFrame:SetWidth(27)
		else
			self.levelFrame:SetWidth(30)
		end
	else
		self.classFrame:Hide()

		if (not pconf.level) then
			self.levelFrame:SetWidth(2)
			--self.levelFrame:Hide()
		end
	end

	ShowHideValues(self)

	if (pconf.percent) then
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()
	else
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
	end

	local height = ((pconf.name or 0) * 22) + 2 -- 24 when enabled, 2 when disabled

	self.targetFrame:ClearAllPoints()
	self.nameFrame:SetHeight(height)

	if (pconf.name) then
		self.nameFrame:Show()
		if (pconf.flip) then
			self.targetFrame:SetPoint("BOTTOMRIGHT", self.nameFrame, "BOTTOMLEFT", 2, 0)
		else
			self.targetFrame:SetPoint("BOTTOMLEFT", self.nameFrame, "BOTTOMRIGHT", -2, 0)
		end
	else
		self.nameFrame:Hide()
		if (pconf.flip) then
			self.targetFrame:SetPoint("TOPRIGHT", self.statsFrame, "BOTTOMRIGHT", 2, 0)
		else
			self.targetFrame:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", -2, 0)
		end
	end

	if (pconf.target.large) then
		self.targetFrame.healthBar.text:SetTextColor(1, 1, 1)
		self.targetFrame:SetHeight(28)
		self.targetFrame.healthBar:Show()
	else
		self.targetFrame:SetHeight(20)
		self.targetFrame.healthBar:Hide()
	end

	self.targetFrame:SetWidth(pconf.target.size)

	pconf.buffs.size = tonumber(pconf.buffs.size) or 20
	XPerl_SetBuffSize(self)

	local function SetAllBuffs(self, buffs, debuff)
		local prevAnchor
		if (pconf.flip) then
			prevAnchor = "TOPRIGHT"
		else
			prevAnchor = "TOPLEFT"
		end
		if (buffs) then
			local prev = self
			for k,v in pairs(buffs) do
				v:ClearAllPoints()
				if (pconf.flip) then
					v:SetPoint("TOPRIGHT", prev, prevAnchor, -(1 + debuff), 0)
				else
					v:SetPoint("TOPLEFT", prev, prevAnchor, 1 + debuff, 0)
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

	if (not pconf.debuffs.halfSize) then
		self.debuffFrame:SetScale(1)
	end
	SetAllBuffs(self.debuffFrame, self.buffFrame.debuff, 1)
	SetAllBuffs(self.buffFrame, self.buffFrame.buff, 0)

	self.buffOptMix = nil
	self.debuffFrame:SetScale(1)
	XPerl_Party_BuffPositions(self)

	XPerl_Party_SetWidth(self)

	if (pconf.target.enable) then
		RegisterUnitWatch(self.targetFrame)
	else
		UnregisterUnitWatch(self.targetFrame)
		self.targetFrame:Hide()
	end

	if (self:IsShown()) then
		XPerl_Party_UpdateDisplay(self)
	end

	--XPerl_SetTextTransparencyFrame(self)

	--[[if (conf.ShowPartyPets == 1 and XPerl_PartyPetFrames) then
		if (not self.petFrame) then
			self.petFrame = CreateFrame("Button", "XPerl_partypet"..self:GetID(), self, "XPerl_Party_Pet_FrameTemplate")
	end]]

	self.petFrame = _G["XPerl_partypet"..self:GetID()]
	if (self.petFrame) then
		self.petFrame:ClearAllPoints()
		if (pconf.flip) then
			self.petFrame:SetPoint("TOPRIGHT", self.statsFrame, "TOPLEFT", 2, 0)
		else
			self.petFrame:SetPoint("TOPLEFT", self.statsFrame, "TOPRIGHT", -2, 0)
		end
	end

	if (XPerl_Voice) then
		XPerl_Voice:Register(self, true)
	end
end

-- XPerl_Party_SetInitialAttributes()
function XPerl_Party_SetInitialAttributes()

	--[[partyHeader.initialConfigFunction = function(self)
		-- This is the only place we're allowed to set attributes whilst in combat

		self:SetAttribute("*type1", "target")
		self:SetAttribute("type2", "menu")
		self.menu = XPerl_ShowGenericMenu
		XPerl_RegisterClickCastFrame(self)

		-- Does AllowAttributeChange work for children?
		self.nameFrame:SetAttribute("useparent-unit", true)
		self.nameFrame:SetAttribute("*type1", "target")
		self.nameFrame:SetAttribute("type2", "menu")
		self.nameFrame.menu = XPerl_ShowGenericMenu
		XPerl_RegisterClickCastFrame(self.nameFrame)

		--self:SetAttribute("initial-height", CalcHeight())
		--self:SetAttribute("initial-width", CalcWidth())
	end]]

	-- Fix Secure Header taint in combat
	--[[local maxColumns = partyHeader:GetAttribute("maxColumns") or 1
	local unitsPerColumn = partyHeader:GetAttribute("unitsPerColumn") or 5
	local startingIndex = partyHeader:GetAttribute("startingIndex") or 1
	local maxUnits = maxColumns * unitsPerColumn

	partyHeader:Show()
	partyHeader:SetAttribute("startingIndex", - maxUnits + 1)
	partyHeader:SetAttribute("startingIndex", startingIndex)]]

	partyHeader:Hide()

	XPerl_Party_SetMainAttributes()
	CheckRaid()
end

-- XPerl_Party_SetMainAttributes
function XPerl_Party_SetMainAttributes()

	partyAnchor:StopMovingOrSizing()

	partyHeader:ClearAllPoints()
	if (pconf.anchor == "TOP") then
		partyHeader:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", 0)
		partyHeader:SetAttribute("yOffset", -pconf.spacing)
	elseif (pconf.anchor == "LEFT") then
		partyHeader:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", pconf.spacing)
		partyHeader:SetAttribute("yOffset", 0)
	elseif (pconf.anchor == "BOTTOM") then
		partyHeader:SetPoint("BOTTOMLEFT", partyAnchor, "BOTTOMLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", 0)
		partyHeader:SetAttribute("yOffset", pconf.spacing)
	elseif (pconf.anchor == "RIGHT") then
		partyHeader:SetPoint("BOTTOMRIGHT", partyAnchor, "BOTTOMRIGHT", 0, 0)
		partyHeader:SetAttribute("xOffset", -pconf.spacing)
		partyHeader:SetAttribute("yOffset", 0)
	end

	partyHeader:SetAttribute("point", pconf.anchor or "TOP")
end

-- XPerl_Party_Virtual
function XPerl_Party_Virtual(on)
	local virtual = XPerl_Party_AnchorVirtual
	if (on) then
		local w = CalcWidth(XPerl_party1)
		local h = CalcHeight(XPerl_party1)

		virtual:ClearAllPoints()
		if (pconf.anchor == "TOP") then
			virtual:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
			virtual:SetHeight((h * 4) + (pconf.spacing * 3))
			virtual:SetWidth(w)
		elseif (pconf.anchor == "LEFT") then
			virtual:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
			virtual:SetHeight(h)
			virtual:SetWidth(w * 4 + (pconf.spacing * 3))
		elseif (pconf.anchor == "BOTTOM") then
			virtual:SetPoint("BOTTOMLEFT", partyAnchor, "BOTTOMLEFT", 0, 0)
			virtual:SetHeight((h * 4) + (pconf.spacing * 3))
			virtual:SetWidth(w)
		elseif (pconf.anchor == "RIGHT") then
			virtual:SetPoint("TOPRIGHT", partyAnchor, "TOPRIGHT", 0, 0)
			virtual:SetHeight(h)
			virtual:SetWidth(w * 4 + (pconf.spacing * 3))
		end
		virtual:OnBackdropLoaded()
		virtual:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
		virtual:SetBackdropBorderColor(conf.colour.border.r, conf.colour.border.g, conf.colour.border.b, 1)
		virtual:Lower()
		if pconf.enable then
			virtual:Show()
		else
			virtual:Hide()
		end
	else
		if XPerlLocked == 0 then
			if pconf.enable then
				virtual:Show()
			else
				virtual:Hide()
			end
		else
			virtual:Hide()
		end
	end
end

-- XPerl_Party_Set_Bits
function XPerl_Party_Set_Bits()
	if (InCombatLockdown()) then
		XPerl_OutOfCombatQueue[XPerl_Party_Set_Bits] = false
		return
	end

	partyAnchor:SetScale(pconf.scale)
	XPerl_SavePosition(partyAnchor, true)

	ZPerl_Party_SecureHeader:SetAttribute("showPlayer", pconf.showPlayer)

	ZPerl_Party_SecureState:SetAttribute("partyEnabled", pconf.enable)
	ZPerl_Party_SecureState:SetAttribute("partyInRaid", pconf.inRaid)
	ZPerl_Party_SecureState:SetAttribute("partySmallRaid", pconf.smallRaid)

	if (XPerlDB) then
		conf = XPerlDB
		pconf = XPerlDB.party
		for k, v in pairs(PartyFrames) do
			v.conf = pconf
			XPerl_Party_Set_Bits1(v)
		end
	end

	XPerl_Party_SetInitialAttributes()
	XPerl_Register_Prediction(XPerl_Party_Events_Frame, pconf, function(guid)
		local frame = XPerl_Party_GetUnitFrameByGUID(guid)
		if frame then
			return frame.partyid
		end
	end)

	if (XPerl_Party_AnchorVirtual:IsShown()) then
		XPerl_Party_Virtual(true)
	else
		XPerl_Party_Virtual()
	end
	UpdateAllAssignedRoles()
end
