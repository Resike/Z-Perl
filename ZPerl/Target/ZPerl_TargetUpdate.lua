-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local conf, tconf, fconf
ZPerl.RequestConfig(function(new)
	conf = new
	tconf = conf.target
	fconf = conf.focus
end, "$Revision:  $")

local CanAccess = ZPerl.CanAccess
local IsSecret = ZPerl.IsSecret
local SetAlphaFromBoolean = ZPerl.SetAlphaFromBoolean
local SafeBool = ZPerl.SafeBool
-- Upvalues
local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod
local UnitAffectingCombat = UnitAffectingCombat
local UnitCanAssist = UnitCanAssist
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInRange = UnitInRange
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitIsGroupLeader = UnitIsGroupLeader
local UnitIsUnit = UnitIsUnit
local UnitPowerMax = UnitPowerMax

local CHAT_MSG_AFK = CHAT_MSG_AFK
local percD = "%d"..PERCENT_SYMBOL

-- ZPerl.Target.SetManaType
function ZPerl.Target.SetManaType(self)
	local unitPowerMax = UnitPowerMax(self.partyid)

	-- a secret maximum cannot be tested, keep the bar shown
	---@diagnostic disable-next-line: secret-comparison
	if ((CanAccess(unitPowerMax) and unitPowerMax == 0) or not self.conf.mana) then
		if (self.statsFrame.manaBar:IsShown()) then
			self.statsFrame.manaBar:Hide()

			if (self == ZPerl_Target or self == ZPerl_Focus or self == ZPerl_TargetTarget or self == ZPerl_FocusTarget or self == ZPerl_PetTarget or self == ZPerl_TargetTargetTarget) then
				self.statsFrame:SetHeight(28 + ((conf.bar.fat or 0) * 2))
				ZPerl.StatsFrameSetup(self)
			end
		end
		return
	end

	ZPerl.SetManaBarType(self)

	if (not self.statsFrame.manaBar:IsShown()) then
		self.statsFrame.manaBar:Show()
		self.statsFrame.manaBar.text:Show()
		if (self == ZPerl_Target or self == ZPerl_Focus or self == ZPerl_TargetTarget or self == ZPerl_FocusTarget or self == ZPerl_PetTarget or self == ZPerl_TargetTargetTarget) then
			self.statsFrame:SetHeight(40)
			ZPerl.StatsFrameSetup(self)
		end
	end
end

local powerStyle = {percent = percD, text = "valued"}
function ZPerl.Target.SetMana(self)
	if not self.partyid then
		self.targetmana = 0
		self.targetmanamax = 0
		return
	end

	local _, unitPower, unitPowerMax = ZPerl.PowerUpdate(self, powerStyle)
	self.targetmana = unitPower
	self.targetmanamax = unitPowerMax
end

-- ZPerl.Target.SetManaAndType: the power element's updatePowerType (UNIT_DISPLAYPOWER)
function ZPerl.Target.SetManaAndType(self)
	ZPerl.Target.SetManaType(self)
	ZPerl.Target.SetMana(self)
end

-- UpdateHealPrediction
local function UpdateHealPrediction(self)
	if self == ZPerl_Target then
		if tconf.healprediction then
			ZPerl.SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	elseif self == ZPerl_TargetTarget or self == ZPerl_TargetTargetTarget then
		if self.conf.healprediction then
			ZPerl.SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	elseif self == ZPerl_Focus then
		if fconf.healprediction then
			ZPerl.SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	elseif self == ZPerl_FocusTarget then
		if conf.focustarget.healprediction then
			ZPerl.SetExpectedHealth(self)
		else
			self.statsFrame.expectedHealth:Hide()
		end
	end
end

-- UpdateAbsorbPrediction
local function UpdateAbsorbPrediction(self)
	if self == ZPerl_Target then
		if tconf.absorbs then
			ZPerl.SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	elseif self == ZPerl_TargetTarget or self == ZPerl_TargetTargetTarget then
		if self.conf.absorbs then
			ZPerl.SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	elseif self == ZPerl_Focus then
		if fconf.absorbs then
			ZPerl.SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	elseif self == ZPerl_FocusTarget then
		if conf.focustarget.absorbs then
			ZPerl.SetExpectedAbsorbs(self)
		else
			self.statsFrame.expectedAbsorbs:Hide()
		end
	end
end

function ZPerl.Target.UpdateResurrectionStatus(self)
	if (SafeBool(UnitHasIncomingResurrection(self.partyid), false)) then
		if (self == ZPerl_Target and tconf.portrait) or (self == ZPerl_Focus and fconf.portrait) then
			self.portraitFrame.resurrect:Show()
		else
			self.statsFrame.resurrect:Show()
		end
	else
		if (self == ZPerl_Target and tconf.portrait) or (self == ZPerl_Focus and fconf.portrait) then
			self.portraitFrame.resurrect:Hide()
		else
			self.statsFrame.resurrect:Hide()
		end
	end
end

-- ZPerl.Target.UpdateHealth
function ZPerl.Target.UpdateHealth(self)
	local partyid = self.partyid
	if not partyid then
		self.targethp = 0
		self.targethpmax = 0
		self.afk = false
		return
	end

	local hp, hpMax = UnitHealth(partyid), UnitHealthMax(partyid)

	self.targethp = hp
	self.targethpmax = hpMax

	-- indirect units (pettarget, targettarget...) can return
	-- secret booleans, which cannot be tested; treat those as "alive and normal"
	local ghost = SafeBool(UnitIsGhost(partyid), false)
	local dead = SafeBool(UnitIsDead(partyid), false)
	local offline = UnitExists(partyid) and not SafeBool(UnitIsConnected(partyid), true)
	local afk = SafeBool(UnitIsAFK(partyid), false)
	self.afk = afk and conf.showAFK == 1

	ZPerl.SetHealthBar(self)

	UpdateAbsorbPrediction(self)
	UpdateHealPrediction(self)
	ZPerl.Target.UpdateResurrectionStatus(self)

	-- A readable max of 100 means hp is already a percent: print it as one
	---@diagnostic disable-next-line: secret-comparison
	if (CanAccess(hpMax) and hpMax == 100 and CanAccess(hp)) then
		ZPerl.FormatPercent(self.statsFrame.healthBar.text, (ghost or dead) and 0 or hp, "whole")
	end

	local color
	if (self.conf.percent) then
		if (ghost) then
			self.statsFrame.manaBar.percent:Hide()
			self.statsFrame.healthBar.percent:SetText(L["LOC_GHOST"])
		elseif (dead) then
			--self.statsFrame.manaBar.percent:Hide()
			self.statsFrame.healthBar.percent:SetText(L["LOC_DEAD"])
		elseif (offline) then
			self.statsFrame.manaBar.percent:Hide()
			self.statsFrame.healthBar.percent:SetText(L["LOC_OFFLINE"])
		elseif (afk and conf.showAFK) then
			self.statsFrame.healthBar.percent:SetText(CHAT_MSG_AFK)
		else
			self.statsFrame.manaBar.percent:Show()
			color = true
		end
	else
		if (ghost) then
			self.statsFrame.healthBar.text:SetText(L["LOC_GHOST"])
		elseif (dead) then
			self.statsFrame.healthBar.text:SetText(L["LOC_DEAD"])
		elseif (offline) then
			self.statsFrame.healthBar.text:SetText(L["LOC_OFFLINE"])
		elseif (afk and conf.showAFK) then
			self.statsFrame.healthBar.text:SetText(CHAT_MSG_AFK)
		else
			color = true
		end
	end

	if (color) then
		if (self.statsFrame.greyMana) then
			self.statsFrame.greyMana = nil
			ZPerl.Target.SetManaType(self)
		end
	else
		self.statsFrame:SetGrey()
	end
end

-- ZPerl.Target.UpdateCombat
function ZPerl.Target.UpdateCombat(self)
	if (UnitAffectingCombat(self.partyid)) then
		self.nameFrame.combatIcon:Show()
	else
		self.nameFrame.combatIcon:Hide()
	end
end

-- CombatFlash
local function CombatFlash(self, elapsed, argNew, argGreen)
	if (ZPerl.CombatFlashSet(self, elapsed, argNew, argGreen)) then
		ZPerl.CombatFlashSetFrames(self)
	end
end

-- ZPerl.Target.UpdateRange
function ZPerl.Target.UpdateRange(self)
	if not self.partyid then
		return
	end
	if not self.conf.range30yard then
		self.nameFrame.rangeIcon:Hide()
		return
	end
	local range, checkedRange = UnitInRange(self.partyid)
	if (IsSecret(range) or IsSecret(checkedRange)) then
		-- secret booleans drive the icon's alpha directly
		local icon = self.nameFrame.rangeIcon
		icon:Show()
		icon:SetAlpha(1)
		SetAlphaFromBoolean(icon, checkedRange, 1, 0)
		SetAlphaFromBoolean(icon, range, 0, icon:GetAlpha())
		return
	end
	-- range and checkedRange are readable here (the secret case returned above)
	---@diagnostic disable-next-line: secret-condition
	local inRange = not checkedRange or range
	---@diagnostic disable-next-line: secret-condition
	if not UnitIsConnected(self.partyid) or inRange then
		self.nameFrame.rangeIcon:Hide()
	else
		self.nameFrame.rangeIcon:Show()
		self.nameFrame.rangeIcon:SetAlpha(1)
	end
end

-- UpdateLeader
local function UpdateLeader(self)
	local partyid = self.partyid

	-- UnitIsGroupLeader/UnitIsGroupAssistant can be secret booleans for a
	-- secret-identity target; crashed on plain click-to-target.
	if (SafeBool(UnitIsGroupLeader(partyid), false)) then
		self.nameFrame.leaderIcon:Show()
		self.nameFrame.assistIcon:Hide()
	else
		self.nameFrame.leaderIcon:Hide()
		if (SafeBool(UnitIsGroupAssistant(partyid), false)) then
			self.nameFrame.assistIcon:Show()
		else
			self.nameFrame.assistIcon:Hide()
		end
	end

	local masterLooter = false
	local method, partyID, raidID = GetLootMethod()

	if ZPerl.IsMasterLoot(method) then
		if raidID then
			if SafeBool(UnitIsUnit("raid"..raidID, partyid), false) then
				masterLooter = true
			end
		elseif partyID then
			if SafeBool(UnitIsUnit("party"..partyID, partyid), false) or (partyID == 0 and SafeBool(UnitIsUnit("player", partyid), false)) then
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

	ZPerl.UpdateRaidIcon(raidIcon, self.partyid)

	raidIcon:ClearAllPoints()
	if (self.conf.raidIconAlternate) then
		-- the corner mark matches the Player frame's (20x20)
		raidIcon:SetHeight(20)
		raidIcon:SetWidth(20)
		raidIcon:SetPoint("CENTER", self.nameFrame, "TOPRIGHT", -5, -4)
	else
		raidIcon:SetHeight(32)
		raidIcon:SetWidth(32)
		raidIcon:SetPoint("CENTER", self.nameFrame, "CENTER", 0, 0)
	end
end

-- CheckDebuffs
local function CheckDebuffs(self)
	if (self.conf.highlightDebuffs.enable) then
		if (self.conf.highlightDebuffs.who == 1 or (self.conf.highlightDebuffs.who == 2 and UnitCanAssist("player", self.partyid)) or (self.conf.highlightDebuffs.who == 3 and not UnitCanAssist("player", self.partyid))) then
			ZPerl.CheckDebuffs(self, self.partyid)
		else
			ZPerl.CheckDebuffs(self, self.partyid, true)
		end
	end

	if (self.conf.reactionHighlight) then
		local c = ZPerl.ReactionColor(self.partyid)
		self.nameFrame:SetBackdropColor(c.r, c.g, c.b)
	end
end

-- used by ZPerl_TargetEvents.lua
ZPerl.Target.CombatFlash = CombatFlash
ZPerl.Target.UpdateLeader = UpdateLeader
ZPerl.Target.RaidTargetUpdate = RaidTargetUpdate
ZPerl.Target.CheckDebuffs = CheckDebuffs

-- ZPerl.Target.UpdateDisplay
function ZPerl.Target.UpdateDisplay(self)
	local partyid = self.partyid
	if not UnitExists(partyid) then
		return
	end

	ZPerl.NoFadeBars(true)

	ZPerl.Target.UpdateName(self)
	ZPerl.Target.UpdateClassification(self)
	ZPerl.Target.UpdateLevel(self)
	ZPerl.Target.UpdateType(self)
	ZPerl.Target.SetManaType(self)
	ZPerl.Target.SetMana(self)
	ZPerl.Target.UpdateHealth(self)
	ZPerl.Target.UpdateCombat(self)
	UpdateLeader(self)
	ZPerl.UnitThreatStatus(self, partyid == "target" and "player" or nil, true)

	RaidTargetUpdate(self)

	if self == ZPerl_Target then
		ZPerl.Target.UpdateCombo(self)
	end
	ZPerl.UnitUpdatePortrait(self)

	ZPerl_Highlight:SetHighlight(self, UnitGUID(partyid))

	if self.conf.range30yard then
		ZPerl.Target.UpdateRange(self)
	else
		self.nameFrame.rangeIcon:Hide()
	end
	ZPerl.UpdateSpellRange(self, partyid)

	ZPerl.NoFadeBars()

	-- a fresh target is the most common moment the AuraContainer
	-- fallback's friend/enemy half-assignment needs to change; rebuild here (a
	-- no-op on clients without it, deferred while secret) rather than on every
	-- UNIT_AURA.
	ZPerl.AurasRebuild(self)
	ZPerl.AurasUpdate(self)
	if (self.conf.highlightDebuffs.enable) then
		CheckDebuffs(self)
	end

	ZPerl.Target.UpdatePVP(self)
end

-- ZPerl.Target.OnUpdate
function ZPerl.Target.OnUpdate(self, elapsed)
	local partyid = self.partyid
	if not partyid then
		return
	end

	local feedback = self.conf.hitIndicator
	if feedback then
		CombatFeedback_OnUpdate(self, elapsed)
	end

	if (self.PlayerFlash) then
		CombatFlash(self, elapsed, false)
	end
	ZPerl.OnUpdateIdle(self, feedback)
end

-- Range checks every 0.2 s: no event reports a unit's distance
local function PollRangeOne(self)
	do
		local partyid = self and self.partyid
		if (partyid and self:IsVisible()) then
			if self.conf.range30yard then
				ZPerl.Target.UpdateRange(self)
			end
			if conf.rangeFinder.enabled then
				ZPerl.UpdateSpellRange(self, partyid)
			end
		end
	end
end

local function PollRange()
	PollRangeOne(ZPerl_Target)
	PollRangeOne(ZPerl_Focus)
end
ZPerl.Every(0.2, PollRange)
