-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

-- Health, power and reaction colors, the unit tooltip, the combat flash and the debuff highlight.

local conf

ZPerl.RequestConfig(function(New)
	conf = New
end, "$Revision: 1 $")

-- Upvalues
local max = max
local min = min
local pairs = pairs
local setmetatable = setmetatable
local type = type
local unpack = unpack

local C_ClassColor = C_ClassColor
local C_CurveUtil = C_CurveUtil
local C_SpellBook = C_SpellBook
local CreateColor = CreateColor
local GameTooltip_SetDefaultAnchor = GameTooltip_SetDefaultAnchor
local GameTooltip_UnitColor = GameTooltip_UnitColor
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsPlayerSpell = IsPlayerSpell
local IsShiftKeyDown = IsShiftKeyDown
local IsSpellKnown = IsSpellKnown
local SecureButton_GetUnit = SecureButton_GetUnit
local SetCursor = SetCursor
local SpellCanTargetUnit = SpellCanTargetUnit
local SpellIsTargeting = SpellIsTargeting
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitHealthPercent = UnitHealthPercent
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsVisible = UnitIsVisible
local UnitPlayerControlled = UnitPlayerControlled
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction

local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS
local DebuffTypeColor = DebuffTypeColor or {
	none    = { r = 0.80, g = 0.00, b = 0.00 },
	Magic   = { r = 0.20, g = 0.60, b = 1.00 },
	Curse   = { r = 0.60, g = 0.00, b = 1.00 },
	Disease = { r = 0.60, g = 0.40, b = 0.00 },
	Poison  = { r = 0.00, g = 0.60, b = 0.00 },
}
local Enum = Enum
local PowerBarColor = PowerBarColor
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local GameTooltip = GameTooltip
local GameTooltipTextLeft1 = GameTooltipTextLeft1

local CanAccess = ZPerl.CanAccess
local ForeverAPI = ZPerl.ForeverAPI
local colorCurves = { }	-- Cached Blizzard color curves and small color tables
ZPerl.colorCurves = colorCurves
local ArcaneExclusions = ZPerl.ArcaneExclusions
local playerClass = select(2, UnitClass("player"))

-- ZPerl.HealthColorCurve
-- the same gradient as ZPerl.SetSmoothBarColor, built as a
-- Blizzard ColorCurve so UnitHealthPercent can evaluate it on a secret percent.
function ZPerl.HealthColorCurve()
	if (colorCurves.health or not ForeverAPI.colorCurves) then
		return colorCurves.health
	end
	local curve = C_CurveUtil.CreateColorCurve()
	curve:SetType(Enum.LuaCurveType.Linear)
	if (conf.color.classic) then
		curve:AddPoint(0, CreateColor(1, 0, 0, 1))
		curve:AddPoint(0.5, CreateColor(1, 1, 0, 1))
		curve:AddPoint(1, CreateColor(0, 1, 0, 1))
	else
		local c = conf.color.bar
		curve:AddPoint(0, CreateColor(c.healthEmpty.r, c.healthEmpty.g, c.healthEmpty.b, 1))
		curve:AddPoint(1, CreateColor(c.healthFull.r, c.healthFull.g, c.healthFull.b, 1))
	end
	colorCurves.health = curve
	return curve
end

-- ZPerl.HealthColor(unit)
-- Color object for the unit's current health, safe to pass to SetStatusBarColor
function ZPerl.HealthColor(unit)
	local curve = ZPerl.HealthColorCurve()
	if (curve and unit and ForeverAPI.healthPercent) then
		return UnitHealthPercent(unit, true, curve)
	end
end

---------------------------------
--Smooth Health Bar Color      --
---------------------------------
function ZPerl.SetSmoothBarColor(self, partyid)
	if (self) then
		-- Blizzard evaluates the gradient for us
		local color = ZPerl.HealthColor(partyid or self.partyid)
		if (not color) then
			return
		end
		---@diagnostic disable-next-line: secret-access
		local r, g, b = color.r, color.g, color.b

		self:SetStatusBarColor(r, g, b)

		if (self.bg) then
			self.bg:SetVertexColor(r, g, b, 0.25)
		end
	end
end

local barColors
function ZPerl.ResetBarColorCache()
	colorCurves.health = nil
	barColors = setmetatable({ }, {
		__index = function(self, k)
			local c = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[k]
			if (c) then
				if (not conf.color.classbarBright) then
					conf.color.classbarBright = 1
				end
				self[k] = {
					r = max(0, min(1, c.r * conf.color.classbarBright)),
					g = max(0, min(1, c.g * conf.color.classbarBright)),
					b = max(0, min(1, c.b * conf.color.classbarBright))
				}
				return self[k]
			end
		end
	})
end
ZPerl.ResetBarColorCache()

-- ZPerl.UnitClassToken(unit): the unit's class token (e.g. "PRIEST"), or nil when it cannot be read.
-- On Forever (and retail) an indirect unit such as "targettarget" or "focustarget" has a secret class in combat.
-- When it does, the class is looked for, in this order:
-- 1. the unit's GUID, when readable: GetPlayerInfoByGUID knows the class of any player;
-- 2. the last class read for this unit token, kept from when it was readable (out of combat, before the pull) until
--    the unit can have changed: only for a one-level indirect unit ("targettarget", "focustarget", "pettarget",
--    "party1target"...), whose changes the client announces (PLAYER_TARGET_CHANGED, PLAYER_FOCUS_CHANGED and
--    UNIT_TARGET of its parent, which fire in combat too). "targettargettarget" changes without an event: not kept;
-- 3. you and your group, matched with UnitIsUnit (a secret answer counts as no match). Forever answers a plain false
--    for an indirect unit in combat, so this finds nothing there; it is kept for clients that answer.
local function memberClass(unit, member)
	local same = UnitIsUnit(unit, member)
	---@diagnostic disable-next-line: secret-condition
	if (same ~= nil and CanAccess(same) and same) then
		local _, class = UnitClass(member)
		if (class and CanAccess(class)) then
			return class
		end
	end
end
local function findMemberClass(unit)
	local found = memberClass(unit, "player")
	if (found) then
		return found
	end
	if (IsInRaid()) then
		for i = 1, GetNumGroupMembers() do
			found = memberClass(unit, "raid" .. i)
			if (found) then
				return found
			end
		end
	else
		for i = 1, GetNumSubgroupMembers() do
			found = memberClass(unit, "party" .. i)
			if (found) then
				return found
			end
		end
	end
	return false
end
-- A secret health value redraws the bar every frame: the group scan (up to 41 UnitIsUnit calls) runs at most every
-- 0.5 s per unit token, as often as the target-of-target frames' own slow update.
local memberCache = {} -- Unit -> {class or false, time}

-- The class by GUID (any player, in the group or not); nil for a secret GUID, a non-player or no answer
local function guidClass(unit)
	local guid = UnitGUID(unit)
	if (not guid or not CanAccess(guid) or not GetPlayerInfoByGUID) then
		return
	end
	local ok, _, class = pcall(GetPlayerInfoByGUID, guid)
	if (ok and class and CanAccess(class)) then
		return class
	end
end

-- Last readable class of the one-level indirect units, by unit token. lastClass[unit] is dropped when the unit can
-- have changed (the events below).
local lastClass = {}
---@param unit string
local function keepable(unit)
	if (#unit <= 6 or unit:sub(-6) ~= "target") then
		return false
	end
	local parent = unit:sub(1, -7)
	-- The parent is a unit of its own ("target", "focus", "pet", "party1", "raid12"...), not an indirect one
	return parent == "target" or not parent:find("target", 1, true)
end
local function forget(parent)
	lastClass[parent .. "target"] = nil
end
ZPerl.On("PLAYER_TARGET_CHANGED", function() forget("target") end)
ZPerl.On("PLAYER_FOCUS_CHANGED", function() forget("focus") end)
ZPerl.On("UNIT_TARGET", function(_, unit)
	if (type(unit) == "string" and CanAccess(unit)) then
		forget(unit)
	end
end)
-- A new group member or pet under a party/raid unit token: those tokens' targets are other units now
ZPerl.On("GROUP_ROSTER_UPDATE", function() wipe(lastClass) end)

function ZPerl.UnitClassToken(unit)
	local _, class = UnitClass(unit)
	if (class == nil) then
		return nil
	end
	local keep = keepable(unit)
	if (CanAccess(class)) then
		if (keep) then
			lastClass[unit] = class
		end
		return class
	end

	class = guidClass(unit)
	if (class) then
		if (keep) then
			lastClass[unit] = class
		end
		return class
	end
	if (keep and lastClass[unit]) then
		return lastClass[unit]
	end

	local now = GetTime()
	local c = memberCache[unit]
	if (not c) then
		c = {false, nil}
		memberCache[unit] = c
	end
	if (not c[2] or now - c[2] >= 0.5) then
		c[1], c[2] = findMemberClass(unit), now
	end
	return c[1] or nil
end

-- Colors a health bar with a secret class token, as SetSecretClassColor does for names. bright scales the
-- channels (the class bar brightness); the bar clamps them, min / max can not on secret numbers.
local function SetSecretClassBarColor(bar, class, bright)
	local c = C_ClassColor.GetClassColor(class)
	---@diagnostic disable-next-line: secret-access
	local r, g, b = c.r, c.g, c.b
	if (bright ~= 1) then
		r, g, b = r * bright, g * bright, b * bright
	end
	bar:SetStatusBarColor(r, g, b)
	if (bar.bg) then
		bar.bg:SetVertexColor(r, g, b, 0.25)
	end
end

-- ZPerl.ColorHealthBar
function ZPerl.ColorHealthBar(self, partyid)
	if (not partyid) then
		partyid = self.partyid
	end
	local bar = self.statsFrame.healthBar
	if (conf.color.classbar) then
		local class = ZPerl.UnitClassToken(partyid)
		if (not class and C_ClassColor and C_ClassColor.GetClassColor and ZPerl.SafeBool(UnitIsPlayer(partyid), false)) then
			-- In instances and battlegrounds the class of a player outside the group is secret: the client
			-- resolves the color. Secret arithmetic refused: the unscaled color; refused too: health colors.
			local _, secretClass = UnitClass(partyid)
			if (secretClass ~= nil and not CanAccess(secretClass)) then
				local bright = conf.color.classbarBright or 1
				if (pcall(SetSecretClassBarColor, bar, secretClass, bright) or (bright ~= 1 and pcall(SetSecretClassBarColor, bar, secretClass, 1))) then
					return
				end
			end
		end
		if (class) then
			if (ZPerl.SafeBool(UnitIsPlayer(partyid), false)) then
				---@diagnostic disable-next-line: secret-table-key
				local c = barColors[class]
				if (c) then
					bar:SetStatusBarColor(c.r, c.g, c.b)
					if (bar.bg) then
						bar.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
					end
					return
				end
			end
		end
	end

	ZPerl.SetSmoothBarColor(bar, partyid)
end
--local ZPerl.ColorHealthBar = ZPerl.ColorHealthBar

-- ZPerl.SetValuedText
function ZPerl.SetValuedText(self, unitHealth, unitHealthMax, suffix)
	local hpText, maxText = ZPerl.ShortPair(unitHealth, unitHealthMax)
	self:SetFormattedText("%s/%s%s", hpText, maxText, suffix or "")
end

-- ZPerl.SetHealthBar(self): the health element reads the unit's values itself; the extra
-- arguments old callers still pass are ignored
function ZPerl.SetHealthBar(self)
	ZPerl.HealthUpdate(self)
end

---------------------------------
--Class Icon Location Functions--
---------------------------------
--local ClassPos = {
--	WARRIOR	= {0,    0.25,    0,	0.25},
--	MAGE	= {0.25, 0.5,     0,	0.25},
--	ROGUE	= {0.5,  0.75,    0,	0.25},
--	DRUID	= {0.75, 1,       0,	0.25},
--	HUNTER	= {0,    0.25,    0.25,	0.5},
--	SHAMAN	= {0.25, 0.5,     0.25,	0.5},
--	PRIEST	= {0.5,  0.75,    0.25,	0.5},
--	WARLOCK	= {0.75, 1,       0.25,	0.5},
--	PALADIN	= {0,    0.25,    0.5,	0.75},
--	none	= {0.25, 0.5, 0.5, 0.75},
--}
--function ZPerl.ClassPos(class)
--	return unpack(ClassPos[class] or ClassPos.none)
--end

function ZPerl.ClassPos(unitClass)
	if (not CanAccess(unitClass)) then
		return 0.25, 0.5, 0.5, 0.75
	end
	local b = CLASS_ICON_TCOORDS[unitClass]		-- Now using the Blizzard supplied from FrameXML/WorldStateFrame.lua
	if (b) then
		return unpack(b)
	end
	return 0.25, 0.5, 0.5, 0.75
end


function ZPerl.GetDisplayedPowerType(unitID)
	return UnitPowerType(unitID) or 0
end

local ManaColors = {
	[Enum.PowerType.Mana] = "mana",
	[Enum.PowerType.Rage] = "rage",
	[Enum.PowerType.Focus] = "focus",
	[Enum.PowerType.Energy] = "energy",
	[Enum.PowerType.Alternate] = "energy", -- Used by some bosses, show it as energy bar
}

-- Forever may expose a usable power token while its numeric power type is
-- restricted or differs from the retail Enum table. Keep the classic X-Perl
-- colors available independently of saved-profile migration.
local PowerTokenColors = {
	MANA = "mana",
	RAGE = "rage",
	FOCUS = "focus",
	ENERGY = "energy",
}
local DefaultPowerColors = {
	mana = {r = 0, g = 0, b = 1},
	rage = {r = 1, g = 0, b = 0},
	focus = {r = 1, g = 0.5, b = 0.25},
	energy = {r = 1, g = 1, b = 0},
}

-- ZPerl.SetManaBarType
function ZPerl.SetManaBarType(self)
	local m = self.statsFrame.manaBar
	if (m and not self.statsFrame.greyMana) then
		local unit = self.partyid -- SecureButton_GetUnit(self)
		if not unit then
			self.targetmanatype = 0
			return
		end
		if (unit) then
			local p, powerToken = UnitPowerType(unit)
			self.targetmanatype = p
			local colorKey
			if CanAccess(p) then
				colorKey = ManaColors[p]
			end
			if not colorKey and CanAccess(powerToken) then
				colorKey = PowerTokenColors[powerToken]
			end
			local c = colorKey and ((conf.color.bar and conf.color.bar[colorKey]) or DefaultPowerColors[colorKey])
			-- Retail's other power types (runic power, astral power, maelstrom, insanity, fury, pain) have no
			-- Z-Perl color option: they take Blizzard's color
			if (not c and PowerBarColor) then
				c = (CanAccess(powerToken) and PowerBarColor[powerToken]) or (CanAccess(p) and PowerBarColor[p])
			end
			if (c) then
				m:SetStatusBarColor(c.r, c.g, c.b, 1)
				m.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
			end
		end
	end
end

-- ZPerl.TooltipModiferPressed
function ZPerl.TooltipModiferPressed(buffs)
	local mod, ic
	if (buffs) then
		if (not conf.tooltip.enableBuffs) then
			return
		end
		mod = conf.tooltip.buffModifier
		ic = conf.tooltip.buffHideInCombat
	else
		if (not conf.tooltip.enable) then
			return
		end
		mod = conf.tooltip.modifier
		ic = conf.tooltip.hideInCombat
	end

	if (mod == "alt") then
		mod = IsAltKeyDown()
	elseif (mod == "shift") then
		mod = IsShiftKeyDown()
	elseif (mod == "ctrl") then
		mod = IsControlKeyDown()
	else
		mod = true
	end

	mod = mod and (not ic or not InCombatLockdown())

	return mod
end

-- ZPerl.PlayerTip
function ZPerl.PlayerTip(self, unitid)
	if (not unitid) then
		unitid = SecureButton_GetUnit(self)
	end

	if (not unitid or ZPerl.Locked == 0) then
		return
	end

	if (not ZPerl.TooltipModiferPressed()) then
		return
	end

	-- SpellCanTargetUnit is absent on this client; skip the cursor change rather than error.
	if (SpellCanTargetUnit and SpellIsTargeting()) then
		if (SpellCanTargetUnit(unitid)) then
			SetCursor("CAST_CURSOR")
		else
			SetCursor("CAST_ERROR_CURSOR")
		end
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(unitid)
	-- SetUnit supplies the tooltip's name color. On restricted clients (Retail, Forever) the
	-- legacy color helper tests secret unit booleans when called by an addon. Not keyed on
	-- issecretvalue: Classic Era has the secret-value API too, without the restrictions.
	if (not (ZPerl.IsRetail or ZPerl.IsForever)) then
		local r, g, b = GameTooltip_UnitColor(unitid)
		GameTooltipTextLeft1:SetTextColor(r, g, b)
	end
	GameTooltip:Show()

	if (ZPerl.Raid.RaidTipExtra) then
		ZPerl.Raid.RaidTipExtra(unitid)
	end

	ZPerl_Highlight:TooltipInfo(UnitGUID(unitid))
end

-- ZPerl.PlayerTipHide
function ZPerl.PlayerTipHide()
	if (conf.tooltip.fading) then
		GameTooltip:FadeOut()
	else
		GameTooltip:Hide()
	end
end

-- Colors a font string with a secret class token: C_ClassColor.GetClassColor resolves it on the client side,
-- and SetTextColor takes the secret channels as they are. Errors (an older client, a nil color) mean no color.
local function SetSecretClassColor(text, class, alpha)
	local c = C_ClassColor.GetClassColor(class)
	---@diagnostic disable-next-line: secret-access
	text:SetTextColor(c.r, c.g, c.b, alpha)
end

-- ZPerl.SetClassTextColor(text, unit)
-- Class color for a unit's name. In instances and battlegrounds the class of a player outside the group is
-- secret and ZPerl.UnitClassToken can not read it; the client still colors it from the secret token.
function ZPerl.SetClassTextColor(text, unit)
	local class = ZPerl.UnitClassToken(unit)
	if (not class and C_ClassColor and C_ClassColor.GetClassColor) then
		local _, secretClass = UnitClass(unit)
		if (secretClass ~= nil and not CanAccess(secretClass)) then
			if (pcall(SetSecretClassColor, text, secretClass, conf.transparency.text)) then
				return
			end
		end
	end
	local color = ZPerl.GetClassColor(class)
	text:SetTextColor(color.r, color.g, color.b, conf.transparency.text)
end

-- ZPerl.ColorFriendlyUnit
function ZPerl.ColorFriendlyUnit(self, partyid)
	local color
	-- ZPerl.SafeBool turns a secret boolean into the given default
	if (ZPerl.SafeBool(UnitCanAttack("player", partyid), false) and ZPerl.SafeBool(UnitIsEnemy("player", partyid), false)) then	-- For dueling
		color = conf.color.reaction.enemy
	else
		if (conf.color.class) then
			ZPerl.SetClassTextColor(self, partyid)
			return
		else
			if (ZPerl.SafeBool(UnitIsPVP(partyid), false)) then
				color = conf.color.reaction.friend
			else
				color = conf.color.reaction.none
			end
		end
	end

	self:SetTextColor(color.r, color.g, color.b, conf.transparency.text)
end

-- ZPerl.SameFaction
-- faction names can be secret for creatures inside instances
function ZPerl.SameFaction(argUnit)
	local mine, theirs = UnitFactionGroup("player"), UnitFactionGroup(argUnit)
	if (not CanAccess(theirs)) then
		return false
	end
	return mine == theirs
end

-- ZPerl.ReactionColor
function ZPerl.ReactionColor(argUnit)
	-- Every boolean here can be secret for indirect units and
	-- creatures inside instances; ZPerl.SafeBool supplies a neutral default
	if (ZPerl.SafeBool(UnitPlayerControlled(argUnit), false) or not ZPerl.SafeBool(UnitIsVisible(argUnit), true)) then
		if (ZPerl.SameFaction(argUnit)) then
			if (ZPerl.SafeBool(UnitIsEnemy("player", argUnit), false)) then
				-- Dueling
				return conf.color.reaction.enemy
			elseif (ZPerl.SafeBool(UnitIsPVP(argUnit), false)) then
				return conf.color.reaction.friend
			end
		else
			if (ZPerl.SafeBool(UnitIsPVP(argUnit), false)) then
				if (UnitIsPVP("player")) then
					return conf.color.reaction.enemy
				else
					return conf.color.reaction.neutral
				end
			end
		end
	else
		if ZPerl.SafeBool(UnitIsTapDenied(argUnit), false) and not ZPerl.SafeBool(UnitIsFriend("player", argUnit), true) then
			return conf.color.reaction.tapped
		else
			local reaction = UnitReaction(argUnit, "player")
			if (reaction and CanAccess(reaction)) then
				if (reaction >= 5) then
					return conf.color.reaction.friend
				elseif (reaction <= 2) then
					return conf.color.reaction.enemy
				elseif (reaction == 3) then
					return conf.color.reaction.unfriendly
				else
					return conf.color.reaction.neutral
				end
			else
				if (ZPerl.SameFaction(argUnit)) then
					return conf.color.reaction.friend
				elseif (ZPerl.SafeBool(UnitIsEnemy("player", argUnit), false)) then
					return conf.color.reaction.enemy
				else
					return conf.color.reaction.neutral
				end
			end
		end
	end

	return conf.color.reaction.none
end

-- ZPerl.SetUnitNameColor
function ZPerl.SetUnitNameColor(self, unit)
	local color
	if (ZPerl.SafeBool(UnitIsPlayer(unit), false) or not ZPerl.SafeBool(UnitIsVisible(unit), true)) then -- Changed UnitPlayerControlled to UnitIsPlayer for 2.3.5
		-- 1.8.3 - Changed to override pvp name colors
		if (conf.color.class) then
			ZPerl.SetClassTextColor(self, unit)
			return
		else
			color = ZPerl.ReactionColor(unit)
		end
	else
		if ZPerl.SafeBool(UnitIsTapDenied(unit), false) and not ZPerl.SafeBool(UnitIsFriend("player", unit), true) then
			color = conf.color.reaction.tapped
		else
			color = ZPerl.ReactionColor(unit)
		end
	end

	self:SetTextColor(color.r, color.g, color.b, conf.transparency.text)
end

-- ZPerl.CombatFlashSet
function ZPerl.CombatFlashSet(self, elapsed, argNew, argGreen)
	if (not conf.combatFlash) then
		-- Turned off mid-flash: end the flash, so CombatFlashSetFrames puts the base color back
		if (self.PlayerFlash) then
			self.PlayerFlash = 0
			self.PlayerFlashGreen = nil
			return true
		end
		return
	end

	if (self) then
		if (argNew) then
			self.PlayerFlash = 1.2 -- Old value: 1.5
			self.PlayerFlashGreen = argGreen
		else
			if (elapsed and self.PlayerFlash) then
				self.PlayerFlash = self.PlayerFlash - elapsed

				if (self.PlayerFlash <= 0) then
					self.PlayerFlash = 0
					self.PlayerFlashGreen = nil
				end
			else
				return
			end
		end

		return true
	end
end

-- ZPerl.OnUpdateIdle: the unit frames set OnUpdate when a combat flash or hit text starts (UNIT_COMBAT)
-- and call this at the end of each tick; it clears the script once nothing animates.
function ZPerl.OnUpdateIdle(self, feedback)
	if not self.PlayerFlash and not (feedback and self.feedbackText and self.feedbackText:IsShown()) then
		self:SetScript("OnUpdate", nil)
	end
end

-- ZPerl.CombatFlashSetFrames
function ZPerl.CombatFlashSetFrames(self)
	if (self.PlayerFlash) then
		local baseColor = self.forcedColor or conf.color.border

		local r, g, b, a
		if (self.PlayerFlash > 0) then
			local flashOffsetColor = min(self.PlayerFlash, 1) / 2
			if (self.PlayerFlashGreen) then
				r = min(1, max(0, baseColor.r - flashOffsetColor))
				g = min(1, max(0, baseColor.g + flashOffsetColor))
			else
				r = min(1, max(0, baseColor.r + flashOffsetColor))
				g = min(1, max(0, baseColor.g - flashOffsetColor))
			end
			b = min(1, max(0, baseColor.b - flashOffsetColor))
			a = min(1, max(0, baseColor.a + flashOffsetColor))
		else
			r, g, b, a = baseColor.r, baseColor.g, baseColor.b, baseColor.a
			self.PlayerFlash = false
		end

		-- nil when the frame's OnLoad stopped before setting it; PlayerFlash must still reach false above
		local frames = self.FlashFrames
		if frames then
			for i = 1, #frames do
				frames[i]:SetBackdropBorderColor(r, g, b, a)
			end
		end
	end
end

local MagicCureTalentsClassic = {
	["PALADIN"] = 4987, -- Clense
}

local MagicCureTalents = {
	["DRUID"] = 4, -- Resto
	["PALADIN"] = 1, -- Holy
	["SHAMAN"] = 3, -- Resto
}

local function CanClassCureMagic(class)
	if (MagicCureTalents[class]) then
		local spellID = MagicCureTalentsClassic[class]
		if (not spellID) then
			return nil
		end
		-- The global is a deprecated wrapper on some clients (Classic Era)
		if (IsSpellKnown) then
			return IsSpellKnown(spellID, false)
		end
		return C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(spellID) or nil
	end
end

-- Retail: dispels depend on spec and talents, so the debuff types the player can remove come from the
-- dispel spells known right now. spellID -> the types it removes.
local RetailDispels = {
	DRUID = {[88423] = {Magic = true, Curse = true, Poison = true}, [2782] = {Curse = true, Poison = true}},
	EVOKER = {[360823] = {Magic = true, Poison = true}, [365585] = {Poison = true}, [374251] = {Curse = true, Poison = true, Disease = true}},
	MAGE = {[475] = {Curse = true}},
	MONK = {[115450] = {Magic = true, Poison = true, Disease = true}, [218164] = {Poison = true, Disease = true}},
	PALADIN = {[4987] = {Magic = true, Poison = true, Disease = true}, [213644] = {Poison = true, Disease = true}},
	PRIEST = {[527] = {Magic = true, Disease = true}, [213634] = {Disease = true}},
	SHAMAN = {[77130] = {Magic = true, Curse = true}, [51886] = {Curse = true}},
	WARLOCK = {[89808] = {Magic = true}},	-- Singe Magic (imp)
}
-- Mists of Pandaria Classic: the same spells, but there Cleanse and Detox remove magic only with the healer's
-- passive (Sacred Cleansing, Internal Medicine), and there are no evokers
local MistsDispels = {
	DRUID = RetailDispels.DRUID,
	MAGE = RetailDispels.MAGE,
	MONK = {[115450] = {Poison = true, Disease = true}, [115451] = {Magic = true}},
	PALADIN = {[4987] = {Poison = true, Disease = true}, [53551] = {Magic = true}},
	PRIEST = RetailDispels.PRIEST,
	SHAMAN = RetailDispels.SHAMAN,
	WARLOCK = RetailDispels.WARLOCK,
}
if (ZPerl.IsMists) then
	RetailDispels = MistsDispels
end
local retailDispellable	-- Type -> true, rebuilt after SPELLS_CHANGED

local function KnowsSpell(spellID)
	if (IsPlayerSpell and IsPlayerSpell(spellID)) then
		return true
	end
	if (C_SpellBook and C_SpellBook.IsSpellKnown and Enum.SpellBookSpellBank) then
		return C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Player) or C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet)
	end
	return IsSpellKnown and (IsSpellKnown(spellID, false) or IsSpellKnown(spellID, true)) or false
end

local function RetailDispellable()
	if (not retailDispellable) then
		retailDispellable = {}
		for spellID, types in pairs(RetailDispels[playerClass] or {}) do
			if (KnowsSpell(spellID)) then
				for t in pairs(types) do
					retailDispellable[t] = true
				end
			end
		end
	end
	return retailDispellable
end

local getShow
function ZPerl.DebufHighlightInit()
	if ((ZPerl.IsRetail or ZPerl.IsMists) and RetailDispels[playerClass]) then
		ZPerl.On("SPELLS_CHANGED", function()
			retailDispellable = nil
		end)
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local d = RetailDispellable()
			return (d.Magic and Curses.Magic) or (d.Curse and Curses.Curse) or (d.Poison and Curses.Poison) or (d.Disease and Curses.Disease) or show
		end
		ZPerl.DebufHighlightInit = nil
		return
	end

	-- We also re-set the colors here so that we highlight best color per class
	if (playerClass == "MAGE") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Curse or show
		end
	elseif (playerClass == "DRUID") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Curse or Curses.Poison or magic or show
		end
	elseif (playerClass == "PRIEST") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Magic or Curses.Disease or show
		end
	elseif (playerClass == "WARLOCK") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Magic or show
		end
	elseif (playerClass == "PALADIN") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Poison or Curses.Disease or magic or show
		end
	elseif (playerClass == "SHAMAN") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Poison or Curses.Disease or magic or show
		end
	elseif (playerClass == "ROGUE") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Poison or show
		end
	else
		getShow = function(Curses)
			return Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
		end
	end

	ZPerl.DebufHighlightInit = nil
end

local bgDef = {
	bgFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_FrameBack",
	edgeFile = "",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = {left = 2, right = 2, top = 2, bottom = 2}
}
local normalEdge = "Interface\\Tooltips\\UI-Tooltip-Border"
local curseEdge = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_Curse"

-- SetBackdrop rebuilds the border and background textures, so it runs only when the edge definition
-- changed since the last call for that frame. Colors are cheap and other code changes them, so
-- they are set on every call.
local function setFlashBackdrop(f)
	local d = bgDef
	local inset = d.insets.left
	if f.xpBdEdge ~= d.edgeFile or f.xpBdSize ~= d.edgeSize or f.xpBdInset ~= inset then
		f.xpBdEdge, f.xpBdSize, f.xpBdInset = d.edgeFile, d.edgeSize, inset
		-- A copy: the frame keeps the table it is given, and bgDef changes on every call
		f:SetBackdrop({bgFile = d.bgFile, edgeFile = d.edgeFile, tile = d.tile, tileSize = d.tileSize,
			edgeSize = d.edgeSize, insets = {left = inset, right = d.insets.right, top = d.insets.top, bottom = d.insets.bottom}})
	end
end

-- ZPerl.CheckDebuffs
--local Curses = setmetatable({ }, {__mode = "k"})	-- 2.2.6 - Now re-using static table to save garbage memory creation
local Curses = { }
local debuffColors = { } -- Debuff type -> {r, g, b, a = 1}, copied from DebuffTypeColor
function ZPerl.CheckDebuffs(self, unit, resetBorders)
	if not self.FlashFrames then
		return
	end

	local high = conf.highlightDebuffs.enable or (self == ZPerl_Target and conf.target.highlightDebuffs.enable) or (self == ZPerl_Focus and conf.focus.highlightDebuffs.enable)

	if resetBorders or not high or not getShow then
		-- Reset the frame edges back to normal in case they changed options while debuffed.
		self.forcedColor = nil
		bgDef.edgeFile = self.edgeFile or normalEdge
		bgDef.edgeSize = self.edgeSize or 16
		bgDef.insets.left = self.edgeInsets or 3
		bgDef.insets.top = self.edgeInsets or 3
		bgDef.insets.right = self.edgeInsets or 3
		bgDef.insets.bottom = self.edgeInsets or 3
		--for i, f in pairs(self.FlashFrames) do
		for i = 1, #self.FlashFrames do
			local f = self.FlashFrames[i]
			setFlashBackdrop(f)
			f:SetBackdropColor(conf.color.frame.r, conf.color.frame.g, conf.color.frame.b, conf.color.frame.a)
			f:SetBackdropBorderColor(conf.color.border.r, conf.color.border.g, conf.color.border.b, conf.color.border.a)
		end
		return
	end

	if not unit then
		unit = self:GetAttribute("unit")
		if not unit then
			return
		end
	end

	Curses.Magic, Curses.Curse, Curses.Poison, Curses.Disease = nil, nil, nil, nil

	local show
	local debuffCount = 0
	local _, unitClass = UnitClass(unit)
	if (not CanAccess(unitClass)) then
		unitClass = nil
	end

	for i = 1, 40 do
		local name, dispelName
		local _
		name, _, _, dispelName = ZPerl.UnitAuraByIndex(unit, i, "HARMFUL")
		if not name then
			break
		end

		-- Secret aura names/types cannot be looked up, skip them
		if dispelName and CanAccess(dispelName) and CanAccess(name) then
			local exclude = ArcaneExclusions[name]
			---@diagnostic disable-next-line: secret-table-key
			if not exclude or (type(exclude) == "table" and not exclude[unitClass]) then
				Curses[dispelName] = dispelName
				debuffCount = debuffCount + 1
			end
		end
	end

	if debuffCount > 0 then
		-- 2.2.6 - Very (very very) slight speed optimazation by having a function per class which is set at startup
		show = getShow(Curses)
	end

	local color, borderColor
	if show then
		-- Z-Perl's own copy with an alpha: Blizzard's DebuffTypeColor is not written to
		color = debuffColors[show]
		if not color then
			local c = DebuffTypeColor[show]
			color = {r = c.r, g = c.g, b = c.b, a = 1}
			debuffColors[show] = color
		end

		if conf.highlightDebuffs.border then
			borderColor = color
		else
			borderColor = conf.color.border
		end
	else
		color = conf.color.frame
		borderColor = conf.color.border
	end

	-- bgDef is shared by every frame: its size and insets are this frame's on both branches, or the curse
	-- edge would take the size and insets of whichever frame was set last
	bgDef.edgeSize = self.edgeSize or 16
	bgDef.insets.left = self.edgeInsets or 3
	bgDef.insets.top = self.edgeInsets or 3
	bgDef.insets.right = self.edgeInsets or 3
	bgDef.insets.bottom = self.edgeInsets or 3
	if show and conf.highlightDebuffs.frame then
		self.forcedColor = borderColor
		bgDef.edgeFile = curseEdge
	else
		self.forcedColor = nil
		bgDef.edgeFile = self.edgeFile or normalEdge
	end

	--for i, f in pairs(self.FlashFrames) do
	for i = 1, #self.FlashFrames do
		local f = self.FlashFrames[i]
		if not conf.highlightDebuffs.frame then
			color = conf.color.frame
		end
		setFlashBackdrop(f)
		f:SetBackdropColor(color.r, color.g, color.b, color.a)
		f:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
	end
end
