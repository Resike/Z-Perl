-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local Events = ZPerl.Elements.Target.events

local conf, tconf, fconf
ZPerl.RequestConfig(function(new)
	conf = new
	tconf = conf.target
	fconf = conf.focus
end, "$Revision:  $")

local SafeBool = ZPerl.SafeBool
-- Upvalues
local PlaySound = PlaySound
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsUnit = UnitIsUnit

-------------------
-- Event Handler --
-------------------

function Events:PLAYER_REGEN_ENABLED()
	ZPerl.UnitThreatStatus(self, self.partyid == "target" and "player" or nil)
end

function Events:PLAYER_REGEN_DISABLED()
	ZPerl.UnitThreatStatus(self, self.partyid == "target" and "player" or nil)
end

-- PLAYER_ENTERING_WORLD
function ZPerl.Elements.FocusOnly.events:PLAYER_ENTERING_WORLD()
	if (UnitExists("focus")) then
		--self.feigning = nil
		self.PlayerFlash = 0
		ZPerl.CombatFlashSetFrames(self)
		ZPerl.Target.UpdateDisplay(self)
	end
end

-- UNIT_COMBAT
function Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end
	-- set first: the flash and hit text animate even when a later line raises on a secret amount
	self:SetScript("OnUpdate", ZPerl.Target.OnUpdate)

	ZPerl.Target.UpdateCombat(self)

	if self.conf.hitIndicator then
		ZPerl.HitIndicator(self, action, descriptor, damage, damageType, self.conf)
	end

	if (action == "HEAL") then
		ZPerl.Target.CombatFlash(self, 0, true, true)
	elseif (ZPerl.IsHit(action, damage)) then
		ZPerl.Target.CombatFlash(self, 0, true)
	end
end

-- PLAYER_TARGET_CHANGED
-- Full display refresh on purpose: a new target changes every shown field, and the frame is not
-- updated by any other event until the unit's next health, power or aura event.
function ZPerl.Elements.TargetOnly.events:PLAYER_TARGET_CHANGED()
	if self ~= ZPerl_Target then
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

	self.PlayerFlash = 0
	ZPerl.CombatFlashSetFrames(self)
	ZPerl.Target.UpdateDisplay(self)

	if (SafeBool(UnitIsUnit("target", "focus"), false)) then
		self.statsFrame.focusTarget:Show()
	else
		self.statsFrame.focusTarget:Hide()
	end

	if (ZPerl_Focus and ZPerl_Focus:IsShown() and ZPerl_FocusTarget) then
		ZPerl.TargetTarget.UpdateDisplay(ZPerl_FocusTarget)
	end
end

-- PLAYER_FOCUS_CHANGED
function ZPerl.Elements.FocusOnly.events:PLAYER_FOCUS_CHANGED()
	if self ~= ZPerl_Focus then
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

	self.PlayerFlash = 0
	ZPerl.CombatFlashSetFrames(self)
	ZPerl.Target.UpdateDisplay(self)

	if (SafeBool(UnitIsUnit("target", "focus"), false)) then
		ZPerl_Target.statsFrame.focusTarget:Show()
	else
		ZPerl_Target.statsFrame.focusTarget:Hide()
	end

	if (ZPerl_FocusTarget) then
		ZPerl.TargetTarget.UpdateDisplay(ZPerl_FocusTarget)
	end
end

-- UNIT_FLAGS
function Events:UNIT_FLAGS()
	ZPerl.Target.UpdateName(self)
	ZPerl.Target.UpdatePVP(self)
	ZPerl.Target.UpdateCombat(self)
end

-- RAID_TARGET_UPDATE
function Events:RAID_TARGET_UPDATE()
	ZPerl.Target.RaidTargetUpdate(ZPerl_Target)
	ZPerl.Target.RaidTargetUpdate(ZPerl_Focus)
end

-- UNIT_PORTRAIT_UPDATE
function Events:UNIT_PORTRAIT_UPDATE()
	ZPerl.UnitUpdatePortrait(self, true)
end

-- UNIT_NAME_UPDATE
function Events:UNIT_NAME_UPDATE()
	ZPerl.Target.UpdateName(self)
	ZPerl.Target.UpdateHealth(self)
	ZPerl.Target.UpdateClassification(self)
	ZPerl.Target.UpdateType(self) -- puts back the class text UpdateClassification hides with no elite tag
end

-- UNIT_LEVEL
function Events:UNIT_LEVEL()
	ZPerl.Target.UpdateLevel(self)
	ZPerl.Target.UpdateClassification(self)
	ZPerl.Target.UpdateType(self)
end

-- UNIT_CLASSIFICATION_CHANGED
function Events:UNIT_CLASSIFICATION_CHANGED()
	ZPerl.Target.UpdateClassification(self)
	ZPerl.Target.UpdateType(self)
end

-- UNIT_AURA
function Events:UNIT_AURA()
	if not UnitExists(self.partyid) then
		return
	end

	if (self.conf.highlightDebuffs.enable) then
		ZPerl.Target.CheckDebuffs(self)
	end
end

-- UNIT_FACTION
function Events:UNIT_FACTION()
	ZPerl.Target.UpdatePVP(self)
	-- the containers' order follows hostility
	ZPerl.AurasRebuild(self)
	ZPerl.AurasUpdate(self)
end

-- PLAYER_FLAGS_CHANGED
function Events:PLAYER_FLAGS_CHANGED()
	ZPerl.Target.UpdateCombat(self)
	ZPerl.Target.UpdatePVP(self)
	ZPerl.Target.UpdateHealth(self)
end

-- UNIT_CONNECTION
function Events:UNIT_CONNECTION(unit, online)
	if (unit == self.partyid) then
		ZPerl.Target.UpdateDisplay(self)
	end
end

-- UNIT_PHASE
function Events:UNIT_PHASE(unit)
	if (unit == self.partyid) then
		ZPerl.Target.UpdateDisplay(self)
	end
end

-- PARTY_LOOT_METHOD_CHANGED
function Events:PARTY_LOOT_METHOD_CHANGED()
	ZPerl.Target.UpdateLeader(self)
end
Events.GROUP_ROSTER_UPDATE = Events.PARTY_LOOT_METHOD_CHANGED
Events.PARTY_LEADER_CHANGED = Events.PARTY_LOOT_METHOD_CHANGED

function Events:UNIT_THREAT_LIST_UPDATE(unit)
	if (UnitCanAttack("player", self.partyid or "target")) then
		ZPerl.UnitThreatStatus(self, self.partyid == "target" and "player" or nil)
	else
		ZPerl.UnitThreatStatus(self)
	end
end

function ZPerl.Elements.TargetHeal.events:UNIT_HEAL_PREDICTION(unit)
	if self == ZPerl_Target then
		if (tconf.healprediction and unit == self.partyid) then
			ZPerl.SetExpectedHealth(self)
		end
	elseif self == ZPerl_Focus then
		if (fconf.healprediction and unit == self.partyid) then
			ZPerl.SetExpectedHealth(self)
		end
	end
end

function Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if self == ZPerl_Target then
		if (tconf.absorbs and unit == self.partyid) then
			ZPerl.SetExpectedAbsorbs(self)
		end
	elseif self == ZPerl_TargetTarget or self == ZPerl_TargetTargetTarget then
		if (self.conf.absorbs and unit == self.partyid) then
			ZPerl.SetExpectedAbsorbs(self)
		end
	elseif self == ZPerl_Focus then
		if (fconf.absorbs and unit == self.partyid) then
			ZPerl.SetExpectedAbsorbs(self)
		end
	elseif self == ZPerl_FocusTarget then
		if (conf.focustarget.absorbs and unit == self.partyid) then
			ZPerl.SetExpectedAbsorbs(self)
		end
	end
end

function Events:INCOMING_RESURRECT_CHANGED(unit)
	if (unit == self.partyid) then
		ZPerl.Target.UpdateResurrectionStatus(self)
	end
end
