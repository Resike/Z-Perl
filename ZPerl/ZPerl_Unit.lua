-- Z-Perl unit-frame core: the number formatters for health and power text (the plain/secret split
-- lives here and nowhere else), the health and power elements, and the shared event dispatcher of
-- the unit frames. Loads after ZPerl.lua; client globals are read at call time.

local L = ZPerl.L

local conf
ZPerl.RequestConfig(function(New)
	conf = New
end, "$Revision: 1 $")

local largeNumTag = L["LOC_LARGENUMTAG"]
local hugeNumTag = L["LOC_HUGENUMTAG"]
local veryhugeNumTag = L["LOC_VERYHUGENUMTAG"]
local percD = "%d%%"
local perc0F = "%.0f%%"
local perc1F = "%.1f%%"

-- ZPerl.ShortNumber(v, compact, cap)
-- A readable v becomes an X-Perl ladder string on abs(v), sign kept. The default ladder is the one
-- of the value and deficit texts; compact is the healer-mode deficit in the percent slot. cap, the
-- max printed beside v, limits the bracket (a v above its max prints in the max's bracket, as the
-- old nested ladder did). A secret v goes to AbbreviateNumbers, which accepts one.
function ZPerl.ShortNumber(v, compact, cap)
	if (ZPerl.IsSecret(v)) then
		return AbbreviateNumbers(v)
	end
	local a = abs(v)
	if (cap and cap < a) then
		a = cap
	end
	if (compact) then
		if (a >= 10000000000) then
			return format("%.0f%s", v / 1000000000, veryhugeNumTag)
		elseif (a >= 1000000000) then
			return format("%.1f%s", v / 1000000000, veryhugeNumTag)
		elseif (a >= 10000000) then
			return format("%.0f%s", v / 1000000, hugeNumTag)
		elseif (a >= 1000000) then
			return format("%.1f%s", v / 1000000, hugeNumTag)
		elseif (a >= 10000) then
			return format("%.0f%s", v / 1000, largeNumTag)
		elseif (a >= 1000) then
			return format("%.1f%s", v / 1000, largeNumTag)
		end
	elseif (a >= 1000000000) then
		return format("%.2f%s", v / 1000000000, veryhugeNumTag)
	elseif (a >= 10000000) then
		return format("%.1f%s", v / 1000000, hugeNumTag)
	elseif (a >= 1000000) then
		return format("%.2f%s", v / 1000000, hugeNumTag)
	elseif (a >= 100000) then
		return format("%.1f%s", v / 1000, largeNumTag)
	end
	return format("%d", v)
end

-- ZPerl.ShortPair(v, max): the texts of a value and its max. If either is secret both go to
-- AbbreviateNumbers (a secret can be neither compared nor ladder-cut); otherwise each gets the
-- ladder, v capped at max, and a max of 1e9 or more keeps one decimal beside a v of 1e5-1e6.
function ZPerl.ShortPair(v, max)
	if (ZPerl.IsSecret(v) or ZPerl.IsSecret(max)) then
		return AbbreviateNumbers(v), AbbreviateNumbers(max)
	end
	local a = abs(v)
	if (max >= 1000000000 and a >= 100000 and a < 1000000) then
		return ZPerl.ShortNumber(v, nil, max), format("%.1f%s", max / 1000000000, veryhugeNumTag)
	end
	return ZPerl.ShortNumber(v, nil, max), ZPerl.ShortNumber(max)
end

-- ZPerl.SetDeficitPair(fs, missing, max, style)
-- Writes -missing/max to fs: the ladder through ZPerl.SetValuedText, or style "full" whole numbers.
function ZPerl.SetDeficitPair(fs, missing, max, style)
	if (ZPerl.IsSecret(missing)) then
		if (style == "full") then
			fs:SetFormattedText("-%d/%d", missing, max)
		else
			local a, b = ZPerl.ShortPair(missing, max)
			fs:SetFormattedText("-%s/%s", a, b)
		end
	elseif (style == "full") then
		fs:SetFormattedText("%d/%d", -missing, max)
	else
		ZPerl.SetValuedText(fs, -missing, max)
	end
end

-- ZPerl.FormatPercent(fs, pct, precise)
-- pct is 0..100. Readable: one decimal below 10 (always, when precise), else rounded. Secret:
-- rounded by %.0f (one decimal when precise), because a secret cannot be added to. precise "whole"
-- never prints a decimal.
function ZPerl.FormatPercent(fs, pct, precise)
	if (ZPerl.IsSecret(pct)) then
		-- a secret cannot be offset by 0.5 for rounding, so the format rounds it (99.6 shows 100)
		fs:SetFormattedText((precise and precise ~= "whole") and perc1F or perc0F, pct)
	elseif (precise == "whole" or (not precise and pct >= 10)) then
		fs:SetFormattedText(percD, pct + 0.5)
	else
		fs:SetFormattedText(perc1F, min(pct + 0.05, 100))
	end
end

-- ZPerl.SetDeficitText(fs, missing, style)
-- Writes -missing to fs. A secret cannot be concatenated, so the FontString is written here, as
-- "-%d". Readable: the X-Perl ladder, its compact form (style true) or the whole number (style
-- "full", for the frames that never abbreviated).
function ZPerl.SetDeficitText(fs, missing, style)
	if (ZPerl.IsSecret(missing)) then
		fs:SetFormattedText("-%d", missing)
	elseif (style == "full") then
		fs:SetFormattedText("%d", -missing)
	else
		fs:SetText(ZPerl.ShortNumber(-missing, style))
	end
end

-- ZPerl.HealthSetBar(bar, unit, ignoreInverse): fills a health bar from the unit (the "inverse" bar
-- option applies unless ignoreInverse, for the frames that never honoured it); returns hp, hpMax and missing
-- for the text, and runs the health loss animation (ZPerl.HealthLoss). The readable arithmetic only picks the deficit when both values can be read: it
-- keeps the ladder text of the plain path; a secret deficit comes from UnitHealthMissing. Every
-- health call passes usePredicted = true (the API's default, what the old code showed), so the bar,
-- the texts and the color read the same health.
function ZPerl.HealthSetBar(bar, u, ignoreInverse)
	local hp, hpMax = UnitHealth(u, true), UnitHealthMax(u)
	local missing
	if (ZPerl.CanAccess(hp) and ZPerl.CanAccess(hpMax)) then
		---@diagnostic disable-next-line: secret-comparison
		if (hp > hpMax) then
			hp = hpMax
		end
		---@diagnostic disable-next-line: secret-arithmetic
		missing = hpMax - hp
	else
		missing = UnitHealthMissing(u, true)
	end

	local inverse = conf.bar.inverse and not ignoreInverse
	bar:SetMinMaxValues(0, hpMax)
	bar:SetValue(inverse and missing or hp)
	ZPerl.HealthLoss(bar, u, hp, hpMax, inverse)
	return hp, hpMax, missing
end

-- ZPerl.HealthUpdateBar(frame): the bar of the health element of a unit frame (frame.partyid is
-- the unit, frame.statsFrame.healthBar the bar).
function ZPerl.HealthUpdateBar(frame)
	return ZPerl.HealthSetBar(frame.statsFrame.healthBar, frame.partyid)
end

-- ZPerl.HealthUpdate(frame): the health element for the unit frames whose bar carries a separate
-- .percent and .text: bar, color, then percent, value and healer-mode deficit text. The raid
-- frames, whose one text shows either, call the pieces themselves.
function ZPerl.HealthUpdate(frame)
	local u = frame.partyid
	local bar = frame.statsFrame.healthBar
	local hp, hpMax, missing = ZPerl.HealthUpdateBar(frame)
	ZPerl.ColorHealthBar(frame, u)

	local healer = frame.conf.healerMode
	if (bar.percent) then
		if (healer and healer.enable and healer.type == 2) then
			ZPerl.SetDeficitText(bar.percent, missing, true)
		else
			ZPerl.FormatPercent(bar.percent, UnitHealthPercent(u, true, CurveConstants.ScaleTo100))
		end
	end

	if (bar.text) then
		if (healer.enable and healer.type ~= 2) then
			if (healer.type == 1) then
				ZPerl.SetDeficitPair(bar.text, missing, hpMax)
			else
				ZPerl.SetDeficitText(bar.text, missing)
			end
		else
			ZPerl.SetValuedText(bar.text, hp, hpMax)
		end
	end
end

-- ZPerl.PowerSetBar(bar, unit, powerType, clampMax): fills a power bar from the unit; returns the
-- value, the max and the max the bar got. clampMax raises a readable max of 0 or less to 1 for the
-- bar (the pet frames), so an empty bar does not get a 0..0 range.
function ZPerl.PowerSetBar(bar, u, powerType, clampMax)
	local cur, max = UnitPower(u, powerType), UnitPowerMax(u, powerType)
	local barMax = max
	---@diagnostic disable-next-line: secret-comparison
	if (clampMax and ZPerl.CanAccess(max) and max <= 0) then
		barMax = 1
	end
	bar:SetMinMaxValues(0, barMax)
	bar:SetValue(cur)
	return cur, max, barMax
end

-- The full power pulse: a Lua port of Blizzard's FullResourcePulseFrame (retail's player power bar) when
-- a power that fills up (rage, energy, focus, ...) reaches its max in combat: a spike at the bar's right
-- end, then a glow that pulses while full and fades out when the power drops or combat ends. The port
-- rather than the template on every client: only retail and Forever have the template, and retail's
-- power is secret in combat, so the template would never play there. Classic textures stand in where
-- the client lacks the FullAlert atlases. Made on first use. Only readable values: the logic compares them.
-- Not on retail and Forever: the player's power is secret there in combat, when the pulse plays (the
-- option is hidden there too).
local PULSE_CLIENT = not ZPerl.IsRetail and not ZPerl.IsForever
local PULSE_TOKENS = {
	RAGE = true, FOCUS = true, ENERGY = true, LUNAR_POWER = true, MAELSTROM = true, FURY = true,
	PAIN = true, INSANITY = true, POWER_TYPE_HEAT = true,
}

-- The template's mixin (Blizzard_UnitFrame/Mainline/BuilderSpenderFrame.lua, FullResourcePulse)
local PulseMixin = {}

local function PulseOnEvent(self, event)
	if (event == "PLAYER_REGEN_ENABLED") then
		if (self.SpikeFrame.SpikeAnim:IsPlaying() or self.PulseFrame.PulseAnim:IsPlaying()) then
			self.FadeoutAnim:Play()
		end
	end
end

function PulseMixin:Initialize(active)
	self.active = active
	if (active) then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", PulseOnEvent)
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:SetScript("OnEvent", nil)
	end
end

function PulseMixin:SetMaxValue(maxValue)
	self.maxValue = maxValue
end

function PulseMixin:StartAnimIfFull(newValue)
	if (newValue == self.maxValue and UnitAffectingCombat("player")) then
		if (self.FadeoutAnim:IsPlaying() or not self.PulseFrame.PulseAnim:IsPlaying()) then
			self.SpikeFrame.SpikeAnim:Play()
		end
		self.FadeoutAnim:Stop()
		self:SetAlpha(1)
		self.PulseFrame.PulseAnim:Play()
	elseif (not self.FadeoutAnim:IsPlaying() and (self.PulseFrame.PulseAnim:IsPlaying() or self.SpikeFrame.SpikeAnim:IsPlaying())) then
		self.FadeoutAnim:Play()
	end
end

function PulseMixin:RemoveAnims()
	self:SetAlpha(0)
	self.PulseFrame.PulseAnim:Stop()
	self.SpikeFrame.SpikeAnim:Stop()
end

-- A texture of the port: the atlas at its size, or a classic stand-in (additive spark, tinted, w x h)
local SPARK = "Interface\\CastingBar\\UI-CastingBar-Spark"
local function PulseTexture(parent, atlas, w, h, r, g, b)
	local t = parent:CreateTexture(nil, "OVERLAY")
	if (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)) then
		t:SetAtlas(atlas, true)
	else
		t:SetTexture(SPARK)
		t:SetBlendMode("ADD")
		t:SetVertexColor(r, g, b)
		t:SetSize(w, h)
	end
	t:SetAlpha(0)
	return t
end

-- One animation of the port: kind "Alpha" (a, b = from, to), "Scale" (a, b = {x, y} from, to; origin
-- LEFT) or "Translation" (a, b = x, y offset)
local function PulseAnim(group, kind, target, duration, delay, smoothing, a, b)
	local anim = group:CreateAnimation(kind)
	if (target) then
		anim:SetTarget(target)
	end
	anim:SetOrder(1)
	anim:SetDuration(duration)
	anim:SetStartDelay(delay)
	anim:SetSmoothing(smoothing)
	if (kind == "Alpha") then
		anim:SetFromAlpha(a)
		anim:SetToAlpha(b)
	elseif (kind == "Scale") then
		anim:SetScaleFrom(a[1], a[2])
		anim:SetScaleTo(b[1], b[2])
		anim:SetOrigin("LEFT", 0, 0)
	else
		anim:SetOffset(a, b)
	end
end

-- The port of the template (Blizzard_UnitFrame/Mainline/BuilderSpenderFrame.xml, FullResourcePulseFrame)
---@return any
local function PulseFramePort(bar)
	local f = CreateFrame("Frame", nil, bar)
	f:SetSize(119, 12)

	local spike = CreateFrame("Frame", nil, f)
	spike:SetSize(119, 12)
	spike:SetPoint("TOPRIGHT")
	f.SpikeFrame = spike
	local big = PulseTexture(spike, "FullAlert-BigSpike", 48, 40, 1, 0.9, 0.5)
	big:SetPoint("RIGHT", 21, 0)
	local stay = PulseTexture(spike, "FullAlert-FrameGlow", 20, 24, 1, 1, 0.8)
	stay:SetPoint("RIGHT", 11, 0)
	spike.BigSpikeGlow, spike.AlertSpikeStay = big, stay

	local spikeAnim = spike:CreateAnimationGroup()
	spikeAnim:SetToFinalAlpha(true)
	PulseAnim(spikeAnim, "Alpha", big, 0.25, 0, "IN", 0, 1)
	PulseAnim(spikeAnim, "Scale", big, 0.1, 0, "NONE", {0.25, 0.75}, {1.4, 0.75})
	PulseAnim(spikeAnim, "Scale", big, 0.2, 0.2, "IN", {1, 1}, {0.5, 1})
	PulseAnim(spikeAnim, "Alpha", big, 0.25, 0.3, "NONE", 1, 0)
	PulseAnim(spikeAnim, "Alpha", stay, 0.25, 0, "IN", 0, 1)
	spike.SpikeAnim = spikeAnim

	local pulse = CreateFrame("Frame", nil, f)
	pulse:SetSize(119, 12)
	pulse:SetPoint("TOPRIGHT")
	f.PulseFrame = pulse
	local yellow = PulseTexture(pulse, "FullAlert-YellowCurveGlow", 20, 24, 1, 0.82, 0)
	yellow:SetSize(20, 24)
	yellow:SetPoint("RIGHT", -1, -1)
	local soft = PulseTexture(pulse, "FullAlert-SoftCurveGlow", 20, 24, 1, 1, 0.8)
	soft:SetSize(20, 24)
	soft:SetPoint("RIGHT", -1, -1)
	pulse.YellowGlow, pulse.SoftGlow = yellow, soft

	local pulseAnim = pulse:CreateAnimationGroup()
	pulseAnim:SetLooping("REPEAT")
	PulseAnim(pulseAnim, "Alpha", yellow, 0.1, 0, "NONE", 0, 1)
	PulseAnim(pulseAnim, "Translation", yellow, 0.5, 0, "OUT", 20, 0)
	PulseAnim(pulseAnim, "Alpha", yellow, 0.1, 0.4, "NONE", 1, 0)
	PulseAnim(pulseAnim, "Alpha", soft, 0.1, 0, "NONE", 0, 1)
	PulseAnim(pulseAnim, "Translation", soft, 0.7, 0, "OUT", 20, 0)
	PulseAnim(pulseAnim, "Alpha", soft, 0.1, 0.6, "NONE", 1, 0)
	pulse.PulseAnim = pulseAnim

	local fadeout = f:CreateAnimationGroup()
	fadeout:SetToFinalAlpha(true)
	PulseAnim(fadeout, "Alpha", nil, 0.5, 0, "NONE", 1, 0)
	fadeout:SetScript("OnFinished", function()
		pulseAnim:Stop()
		spikeAnim:Stop()
	end)
	f.FadeoutAnim = fadeout

	for k, v in pairs(PulseMixin) do
		f[k] = v
	end
	return f
end

local function FullPulseFrame(bar)
	local f = PulseFramePort(bar)
	f:ClearAllPoints()
	f:SetAllPoints(bar)
	local stay = f.SpikeFrame.AlertSpikeStay
	if (stay) then
		stay:ClearAllPoints()
		stay:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 11, 4)
		stay:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 11, -4)
	end
	f:RemoveAnims()
	return f
end

-- ZPerl.FullPowerPulse(bar, unit, cur, max): runs the pulse of a power bar just set to cur of max
function ZPerl.FullPowerPulse(bar, u, cur, max)
	local f = bar.fullPulse
	local _, token = UnitPowerType(u)
	---@diagnostic disable-next-line: secret-comparison
	local on = PULSE_CLIENT and conf.bar.fullPulse and ZPerl.CanAccess(token) and PULSE_TOKENS[token] and ZPerl.CanAccess(cur) and ZPerl.CanAccess(max) and max > 0
	if (not on) then
		if (f) then
			f:RemoveAnims()
		end
		return
	end
	if (f == nil) then
		f = FullPulseFrame(bar)
		bar.fullPulse = f
	end
	if (f.zperlMax ~= max or f.zperlToken ~= token) then
		f:Initialize(true)
		f:SetMaxValue(max)
		f.zperlMax, f.zperlToken = max, token
	end
	-- the template's own logic: a spike on reaching max in combat, a pulse while full, a fade out after
	f:StartAnimIfFull(cur)
end

-- ZPerl.PowerUpdate(frame, style): the power element of a unit frame (frame.partyid is the unit,
-- frame.statsFrame.manaBar the bar). style is a constant table of the module:
--   percent    format of the percent text ("%d%%" truncates, "%.0f%%" rounds); nil prints none
--   inText     the percent goes to the bar's .text (the pet frames) instead of its .percent
--   rawIfEmpty a readable max below 1 prints the value in the percent slot (as a type >= 1 power does)
--   text       value text in .text: "valued" (ZPerl.SetValuedText) or "whole" ("%d/%d")
--   clampMax   see ZPerl.PowerSetBar
--   fullPulse  the full power pulse (ZPerl.FullPowerPulse)
-- Returns the power type, value and max. A power type of 1 or more (rage, energy, ...) prints the
-- value where the percent would be; the percent is ZPerl.GetPowerPercent's, plain or secret.
function ZPerl.PowerUpdate(frame, style)
	local u = frame.partyid
	local bar = frame.statsFrame.manaBar
	local powerType = ZPerl.GetDisplayedPowerType(u)
	local cur, max = ZPerl.PowerSetBar(bar, u, powerType, style.clampMax)
	if (style.fullPulse) then
		ZPerl.FullPowerPulse(bar, u, cur, max)
	end

	if (style.percent) then
		local fs = style.inText and bar.text or bar.percent
		---@diagnostic disable-next-line: secret-comparison
		if (powerType >= 1 or (style.rawIfEmpty and ZPerl.CanAccess(max) and max < 1)) then
			fs:SetText(cur)
		else
			fs:SetFormattedText(style.percent, ZPerl.GetPowerPercent(u, powerType))
		end
	end

	if (style.text == "valued") then
		ZPerl.SetValuedText(bar.text, cur, max)
	elseif (style.text == "whole") then
		bar.text:SetFormattedText("%d/%d", cur, max)
	end
	return powerType, cur, max
end

-- Elements and the shared dispatcher.
-- An element is ZPerl.Elements[name] = {events = {EVENT = fn(frame, ...)}, units = {EVENT = {unit, ...}}}.
-- A frame turns it on with ZPerl.UnitFrameEnable; the element's events are then registered on the
-- frame and ZPerl.UnitFrameOnEvent calls fn(frame, ...) with the payload the client sent (the unit
-- first for a unit event). Events named UNIT_* or INCOMING_* are unit events: registered with
-- RegisterUnitEvent for units[EVENT], else for the frame's __units list, so the client filters by
-- unit and no handler checks it; units[EVENT] = false registers the event for every unit. An event
-- the client does not know is skipped. An event nobody handles is not registered.
ZPerl.Elements = {}

local function register(frame, event, el)
	local units = el.units and el.units[event]
	if (units == nil) then
		units = frame.__units
	end
	local isUnitEvent = strfind(event, "^UNIT_") or strfind(event, "^INCOMING_")
	if (isUnitEvent and units == nil and frame.__units == nil) then
		-- the frame has no unit yet: ZPerl.UnitFrameSetUnit registers the event when it gets one
		frame.__unitEvents[event] = true
	elseif (units and isUnitEvent) then
		if (el.units == nil or el.units[event] == nil) then
			frame.__unitEvents[event] = true -- follows the frame's unit (ZPerl.UnitFrameSetUnit)
		end
		ZPerl.RegisterUnitEventSafe(frame, event, unpack(units))
	else
		ZPerl.RegisterEventSafe(frame, event)
	end
end

-- ZPerl.UnitFrames: every frame that has run ZPerl.UnitFrameInit (weak keys), for callbacks that come
-- from a library instead of the client (LibHealComm in ZPerl_Display.lua)
ZPerl.UnitFrames = setmetatable({}, {__mode = "k"})

-- ZPerl.UnitFrameInit(frame, units, names): sets the frame's default unit list for unit events,
-- its OnEvent script, and enables the named elements.
function ZPerl.UnitFrameInit(frame, units, names)
	ZPerl.UnitFrames[frame] = true
	frame.__units = units
	frame.__handlers = frame.__handlers or {}
	frame.__elements = frame.__elements or {}
	frame.__unitEvents = frame.__unitEvents or {}
	frame:SetScript("OnEvent", ZPerl.UnitFrameOnEvent)
	for i = 1, #names do
		ZPerl.UnitFrameEnable(frame, names[i])
	end
end

-- ZPerl.UnitFrameEnable(frame, name): handlers join frame.__handlers[event] in the order enabled.
function ZPerl.UnitFrameEnable(frame, name)
	local el = ZPerl.Elements[name]
	if (not el) then
		error("Z-Perl: no element " .. tostring(name), 2)
	end
	if (frame.__elements[name]) then
		return
	end
	frame.__elements[name] = true
	for event, fn in pairs(el.events) do
		if (type(fn) ~= "function") then
			error("Z-Perl: element " .. name .. " has no handler for " .. event, 2)
		end
		local list = frame.__handlers[event]
		if (not list) then
			list = {}
			frame.__handlers[event] = list
			register(frame, event, el)
		end
		list[#list + 1] = fn
	end
end

-- ZPerl.UnitFrameDisable(frame, name): the inverse; an event nobody on the frame handles is unregistered.
function ZPerl.UnitFrameDisable(frame, name)
	local el = ZPerl.Elements[name]
	if (not frame.__elements[name]) then
		return
	end
	frame.__elements[name] = nil
	for event, fn in pairs(el.events) do
		-- a new list, so a dispatch loop running over the old one is not shifted
		local old, list, removed = frame.__handlers[event], {}, false
		for i = 1, #old do
			if (not removed and old[i] == fn) then
				removed = true
			else
				list[#list + 1] = old[i]
			end
		end
		frame.__handlers[event] = list
		if (#list == 0) then
			frame.__handlers[event] = nil
			frame.__unitEvents[event] = nil
			ZPerl.UnregisterEventSafe(frame, event)
		end
	end
end

-- ZPerl.UnitFrameSetUnit(frame, unit): points the unit events that follow the frame's unit (the
-- header children, whose unit changes with the group) at the new unit; nil stops them.
function ZPerl.UnitFrameSetUnit(frame, unit)
	frame.__units = unit and {unit} or nil
	for event in pairs(frame.__unitEvents) do
		ZPerl.UnregisterEventSafe(frame, event)
		if (unit) then
			ZPerl.RegisterUnitEventSafe(frame, event, unit)
		end
	end
end

function ZPerl.UnitFrameOnEvent(self, event, ...)
	local list = self.__handlers[event]
	if (list) then
		for i = 1, #list do
			list[i](self, ...)
		end
	end
end

-- The health and power elements: the module sets frame.updateHealth, frame.updatePower and
-- frame.updatePowerType (what its frame does on a display power change) and enables them.
local function updateHealth(frame)
	frame.updateHealth(frame)
end
local function updatePower(frame)
	frame.updatePower(frame)
end
local function updatePowerType(frame)
	frame.updatePowerType(frame)
end
ZPerl.Elements.Health = {events = {[ZPerl.ForeverAPI.healthEvent] = updateHealth, UNIT_MAXHEALTH = updateHealth}}
ZPerl.Elements.Power = {events = {UNIT_POWER_FREQUENT = updatePower, UNIT_MAXPOWER = updatePower, UNIT_DISPLAYPOWER = updatePowerType}}

-- The aura element. A frame with a frame.conf section with buffs and
-- debuffs turns it on with ZPerl.UnitFrameEnable(frame, "Auras") and sets what differs:
--   auraLineSize      function(frame, kind): the line width of the "buffs" or "debuffs" container
--                     (default ZPerl.AurasLineSize)
--   auraAnchor        region the blocks are placed against (default the frame)
--   auraInset         function(frame, side): extra distance from the anchor on that side
--   auraSideAnchor    function(frame, side): the region a block next to the frame on that side hangs
--                     from instead of the anchor (nil: the anchor), and an x, y it adds to the kind's offset
--   auraDebuffsNeedBuffs  debuffs show only while buffs are on
--   auraInside        set of sides ({RIGHT = true}) whose block next to the frame sits inside the anchor's
--                     edge on that side, icons filling inward from it
-- Update shows Blizzard's AuraContainer on every UNIT_AURA and combat change.
-- Without a container (no container API) it shows nothing. Rebuild reconfigures the
-- containers; the module calls it when the unit or an option changes. A rebuild that arrives while
-- auras are secret is left pending and applied by the next Update.

-- The line of a kind at full size that fits its anchor: perLine icons when set, else the anchor's
-- width (rowEdge, when the frame's strip is wider than the anchor).
local function fitLine(frame, kind, rowEdge)
	local o = frame.conf[kind]
	if ((o.perLine or 0) > 0 and o.size) then
		return o.perLine * (o.size + 3) - 3
	end
	local a = frame.auraAnchor or frame
	local edge = rowEdge or a:GetWidth()
	return (edge and edge > 0) and edge or 2000
end

-- ZPerl.AurasLineSize(frame, kind, rowEdge): the line width of the "buffs" or "debuffs" container.
-- Debuffs with halfSize: the fitting line at full size, whatever Wrap says, so the half-size icons
-- fill the same length. Otherwise one line (2000) with buffs.wrap off, and on Left and Right with no
-- perLine; else perLine icons, or the anchor's width. A frame's auraLineSize hook passes the rowEdge
-- that differs from the anchor's width.
function ZPerl.AurasLineSize(frame, kind, rowEdge)
	local c = frame.conf
	local o = c[kind]
	if (kind == "debuffs" and o.halfSize) then
		return fitLine(frame, kind, rowEdge)
	end
	local line = fitLine(frame, kind, rowEdge)
	if (not c.buffs.wrap) then
		line = 2000
	elseif ((o.side == "LEFT" or o.side == "RIGHT") and (o.perLine or 0) == 0) then
		line = 2000
	end
	-- both kinds inside the anchor at its two ends: a line holds what fits in half the anchor's width
	local b, d, inside = c.buffs, c.debuffs, frame.auraInside
	if (inside and b.enable and d.enable and b.side ~= d.side and inside[b.side] and inside[d.side] and o.size) then
		local half = (frame.auraAnchor or frame):GetWidth() / 2
		line = min(line, max(1, floor((half + 3) / (o.size + 3))) * (o.size + 3) - 3)
	end
	return line
end

local AXIS = AnchorUtil and AnchorUtil.FlowLayoutAxis or {Horizontal = 0, Vertical = 1}

-- the corner a block's first icon sits at (point), the corner of the anchor (or of the near block) it
-- hangs from (rel), and the direction away from the frame (ax, ay). Every block is rows: TOP and BOTTOM
-- fill rightward (reverse: leftward) and stack away from the frame; LEFT and RIGHT fill away from the frame
-- and stack downward (reverse: upward).
local OPPOSITE = {TOP = "BOTTOM", BOTTOM = "TOP", LEFT = "RIGHT", RIGHT = "LEFT"}
local function blockCorners(side, reverse)
	local rows = side == "TOP" or side == "BOTTOM"
	local h, v
	if (rows) then
		h, v = reverse and -1 or 1, side == "TOP" and 1 or -1
	else
		h, v = side == "LEFT" and -1 or 1, reverse and 1 or -1
	end
	local point = (v > 0 and "BOTTOM" or "TOP")..(h > 0 and "LEFT" or "RIGHT")
	local rel
	if (rows) then
		rel = side..(h > 0 and "LEFT" or "RIGHT")
	else
		rel = (v < 0 and "TOP" or "BOTTOM")..side
	end
	local ax = side == "LEFT" and -1 or side == "RIGHT" and 1 or 0
	local ay = side == "TOP" and 1 or side == "BOTTOM" and -1 or 0
	return point, rel, h, v, rows, ax, ay
end

-- Drag handles: while frames are unlocked and out of combat each aura block shows a handle over its
-- container (Blizzard's buttons are not scriptable, so Z-Perl's own frame takes the mouse). Drag stop adds
-- the handle's displacement to the kind's x / y and places the frame again. ZPerl.Locked is assigned in
-- many places, so a 0.2 s ticker follows it; combat is followed by event.
local handled, handlesOn, inCombat = {}, false, InCombatLockdown()
local HANDLE_LABEL = {buffs = "Buffs", debuffs = "Debuffs"}
-- Dummy icons: while the handles show, each draws four at its block's start, filling the way the block
-- fills, so an empty block shows where its auras go too. Debuffs carry the Magic, Curse, Poison and Disease border colors.
local DUMMY = {
	buffs = {
		{"Interface\\Icons\\Spell_Holy_WordFortitude"},
		{"Interface\\Icons\\Spell_Nature_Regeneration"},
		{"Interface\\Icons\\Spell_Holy_MagicalSentry"},
		{"Interface\\Icons\\Spell_Holy_PowerWordShield"},
		{"Interface\\Icons\\Spell_Holy_Renew"},
		{"Interface\\Icons\\Spell_Nature_Rejuvenation"},
		{"Interface\\Icons\\Spell_Magic_MageArmor"},
		{"Interface\\Icons\\Spell_Holy_FistOfJustice"},
		{"Interface\\Icons\\Spell_Nature_Thorns"},
		{"Interface\\Icons\\Spell_Holy_DivineSpirit"},
		{"Interface\\Icons\\Spell_Shadow_AntiShadow"},
		{"Interface\\Icons\\Ability_Warrior_BattleShout"},
	},
	debuffs = {
		{"Interface\\Icons\\Spell_Frost_FrostNova", border = {0.2, 0.6, 1}},
		{"Interface\\Icons\\Spell_Shadow_CurseOfSargeras", border = {0.6, 0, 1}},
		{"Interface\\Icons\\Spell_Nature_CorrosiveBreath", border = {0, 0.6, 0}},
		{"Interface\\Icons\\Spell_Shadow_AbominationExplosion", border = {0.6, 0.4, 0}},
	},
}

-- the dummies each group of ZPerl.AurasGroups gets: the double-size groups (Big, Big stealable) a few,
-- "other" the rest; each at most its group's maxFrameCount (the Rows cap)
local DUMMY_SHARE = {mine = 3, steal = 1}

-- lays the handle's dummy icons out as the container lays out its auras: the frame's aura groups in order,
-- each icon at its group's size, one flow from the start corner (point) along lines of the container's
-- width, 3 apart, a line as tall as its tallest icon and the lines the duration text gap apart, filling
-- the way the block fills (grow: 1 right, -1 left) and stacking the way it stacks (stack: 1 up, -1 down).
-- Returns the width and height the dummies take.
local function layoutDummies(frame, kind, h, point, grow, stack)
	local c = frame.conf
	local line = (frame.auraLineSize or ZPerl.AurasLineSize)(frame, kind)
	local half = kind == "debuffs" and c.debuffs.halfSize and frame.auraHalf or false
	local groups = ZPerl.AurasGroups(c, kind, nil, line, half)
	local hx, vy = (grow and grow < 0) and -1 or 1, (stack and stack > 0) and 1 or -1
	local total, i = #h.dummies, 0
	local x, y, lineH, width, lineGap = 0, 0, 0, 0, 0
	for _, g in ipairs(groups) do
		local size = g.size or c[kind].size or 25
		local n = min(DUMMY_SHARE[g.key] or total, total - i, g.maxFrameCount or total)
		for _ = 1, n do
			i = i + 1
			local border, icon = h.dummies[i][1], h.dummies[i][2]
			if (x > 0 and x + size > line) then
				y = y + lineH + lineGap
				x, lineH = 0, 0
			end
			border:ClearAllPoints()
			border:SetPoint(point, h, point, hx * x, vy * y)
			border:SetSize(size, size)
			border:Show()
			icon:Show()
			width = max(width, x + size)
			lineH = max(lineH, size)
			lineGap = max(lineGap, g.gap or 0)
			x = x + size + 3
		end
	end
	for k = i + 1, total do
		h.dummies[k][1]:Hide()
		h.dummies[k][2]:Hide()
	end
	return width, y + lineH
end

local function coverHandle(frame, kind)
	local h = frame[kind == "buffs" and "buffHandle" or "debuffHandle"]
	local container = frame[kind == "buffs" and "buffContainer" or "debuffContainer"]
	local point = frame.auraHandlePoint and frame.auraHandlePoint[kind]
	if (not h or not container or not point) then
		return
	end
	-- the client refuses to anchor an addon frame to the container or its holder (their template forbids
	-- untrusted layout scripts), so the handle goes to the unit frame at the container's measured rect
	-- only while the handles show: while auras are secret the container's rect is secret too, and
	-- arithmetic on it raises
	if (not handlesOn) then
		return
	end
	local size = frame.conf[kind].size or 25
	h:SetFrameLevel(container:GetFrameLevel() + 20)
	local cl, cb, fl, fb = container:GetLeft(), container:GetBottom(), frame:GetLeft(), frame:GetBottom()
	local w, ht = container:GetWidth(), container:GetHeight()
	local A = ZPerl.CanAccess
	local a = frame.auraHandleAnchor[kind]
	-- the label points the way the icons fill: every block's lines run left / right
	local name = HANDLE_LABEL[kind]
	h.label:SetText(a.grow and a.grow < 0 and "<< "..name or name.." >>")
	-- the handle is anchored as the holder is, at the block's start corner (beyond the nearer block it hangs
	-- off that block's handle), and shows the dummy icons laid out as the container would, so the place,
	-- the sizes and the fill direction show whatever auras the unit has. It covers the dummies, and the
	-- container when its rect is readable and larger (the start corner stays put)
	local target = a.after and frame[a.after == "buffs" and "buffHandle" or "debuffHandle"] or a.target
	h:ClearAllPoints()
	h:SetPoint(point, target, a.rel, a.x, a.y)
	local hw, hh = layoutDummies(frame, kind, h, point, a.grow, a.stack)
	hw, hh = max(hw, size), max(hh, size)
	if (A(cl) and A(cb) and A(fl) and A(fb) and A(w) and A(ht)) then
		hw, hh = max(hw, w), max(hh, ht)
	end
	h:SetSize(hw, hh)
end

local function stopDrag(h)
	if (h.dragFrom) then
		h:StopMovingOrSizing()
		h:SetUserPlaced(false)
		h.dragFrom = nil
	end
end

local function dragStop(h)
	local from = h.dragFrom
	if (not from) then
		return
	end
	stopDrag(h)
	local frame, kind = h.auraFrame, h.auraKind
	local l, b = h:GetLeft(), h:GetBottom()
	local o = frame.conf[kind]
	if (l and b) then
		-- the Settings sliders' range
		o.x = max(-300, min(300, (o.x or 0) + floor(l - from[1] + 0.5)))
		o.y = max(-300, min(300, (o.y or 0) + floor(b - from[2] + 0.5)))
	end
	-- frames share a conf (party members, party pets): every one of them moves
	for _, other in ipairs(handled) do
		if (other.conf and other.conf[kind] == o) then
			ZPerl.AurasPlace(other)
			coverHandle(other, kind)
		end
	end
	if (ZPerl.SettingsRefresh) then
		ZPerl.SettingsRefresh()
	end
end

local function makeHandle(frame, kind)
	local h = CreateFrame("Frame", nil, frame)
	h.auraFrame, h.auraKind = frame, kind
	local tex = h:CreateTexture(nil, "BACKGROUND")
	tex:SetAllPoints()
	tex:SetColorTexture(0.2, 0.6, 1, 0.35)
	h.dummies = {}
	for i, d in ipairs(DUMMY[kind]) do
		-- textures, not frames: the label (OVERLAY) stays on top. The border is the icon's box: the debuff
		-- dispel type's color, 1 pixel showing around the icon; a buff's is clear
		local border = h:CreateTexture(nil, "BORDER")
		local col = d.border
		if (col) then
			border:SetColorTexture(col[1], col[2], col[3], 1)
		else
			border:SetColorTexture(0, 0, 0, 0)
		end
		local icon = h:CreateTexture(nil, "ARTWORK")
		local inset = col and 1 or 0
		icon:SetPoint("TOPLEFT", border, "TOPLEFT", inset, -inset)
		icon:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", -inset, inset)
		icon:SetTexture(d[1])
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		border:Hide()
		icon:Hide()
		h.dummies[i] = {border, icon}
	end
	local label = h:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
	label:SetPoint("CENTER")
	label:SetText(HANDLE_LABEL[kind])
	h.label = label
	h:EnableMouse(true)
	h:SetMovable(true)
	h:RegisterForDrag("LeftButton")
	h:SetScript("OnDragStart", function(self)
		if (inCombat or ZPerl.Locked ~= 0 or ZPerl.AurasSecret()) then
			return
		end
		self.dragFrom = {self:GetLeft() or 0, self:GetBottom() or 0}
		self:StartMoving()
	end)
	h:SetScript("OnDragStop", dragStop)
	-- the container moves and resizes with its auras, and the handle is not anchored to it:
	-- ZPerl.AurasSyncHandles re-fits it on the 0.2 s ticker
	h:Hide()
	return h
end

local function refitHandle(frame, h)
	if (h:IsShown() and not h.dragFrom) then
		coverHandle(frame, h.auraKind)
	end
end

-- the ticker's handler; the harness's clock never fires timers in a probe run, so probes call it
function ZPerl.AurasSyncHandles()
	local on = ZPerl.Locked == 0 and not inCombat
	if (on == handlesOn) then
		if (on) then -- the containers move and resize with their auras: re-fit the shown handles
			for _, frame in ipairs(handled) do
				refitHandle(frame, frame.buffHandle)
				refitHandle(frame, frame.debuffHandle)
			end
		end
		return
	end
	handlesOn = on -- before the loop: coverHandle reads the container only while handles are on
	for _, frame in ipairs(handled) do
		for _, kind in ipairs({"buffs", "debuffs"}) do
			local h = frame[kind == "buffs" and "buffHandle" or "debuffHandle"]
			if (h) then
				if (on) then
					if (frame.conf[kind].enable) then
						coverHandle(frame, kind)
						h:Show()
					end
				else
					stopDrag(h)
					h:Hide()
				end
			end
		end
	end
end

local function ensureHandles(frame)
	if (not frame.buffHandle) then
		frame.buffHandle, frame.debuffHandle = makeHandle(frame, "buffs"), makeHandle(frame, "debuffs")
		handled[#handled + 1] = frame
	end
	for _, kind in ipairs({"buffs", "debuffs"}) do
		coverHandle(frame, kind)
		local h = frame[kind == "buffs" and "buffHandle" or "debuffHandle"]
		if (handlesOn and frame.conf[kind].enable) then
			h:Show()
		elseif (not frame.conf[kind].enable) then
			stopDrag(h)
			h:Hide()
		end
	end
end

do
	local function onRegen(event)
		inCombat = event == "PLAYER_REGEN_DISABLED"
		ZPerl.AurasSyncHandles()
	end
	ZPerl.On("PLAYER_REGEN_DISABLED", onRegen)
	ZPerl.On("PLAYER_REGEN_ENABLED", onRegen)
	ZPerl.Every(0.2, ZPerl.AurasSyncHandles)
end

-- ZPerl.AurasPlace(frame): sets the flow of the frame's two containers and anchors their holders. Each
-- kind (buffs.side / debuffs.side) goes to its side of the aura anchor (frame.auraAnchor, default the
-- frame), lines along the side and growing away from it, icons filling from the anchor's left / top edge
-- (right / bottom with reverse), moved by the kind's x, y. Two kinds on one side: the nearer by
-- frame.conf.auraOrder ("buffs", "debuffs", "reaction": debuffs on a unit the player can attack), the
-- other beyond it. Room for duration text (ZPerl.AuraGap) sits between the frame and a TOP block and
-- between the two blocks. frame.auraInset(frame, side) is extra distance from the anchor.
function ZPerl.AurasPlace(frame, fresh)
	local buffContainer, debuffContainer = frame.buffContainer, frame.debuffContainer
	-- a container built just now may be configured while auras are secret; a live one waits
	if (not buffContainer or not debuffContainer or (not fresh and not ZPerl.AuraContainerGate(frame))) then
		return
	end
	local c = frame.conf
	local anchor = frame.auraAnchor or frame
	local gap = ZPerl.AuraGap(c)
	local kinds = {
		buffs = {c.buffs, buffContainer, frame.buffHalfFrame},
		debuffs = {c.debuffs, debuffContainer, frame.debuffHalfFrame},
	}
	local order = c.auraOrder
	if (order == "reaction") then
		order = ZPerl.SafeBool(UnitCanAttack("player", frame.partyid), false) and "debuffs" or "buffs"
	end
	local first, second = "buffs", "debuffs"
	if (order == "debuffs") then
		first, second = second, first
	end
	local near
	for _, kind in ipairs({first, second}) do
		local o, container, holder = unpack(kinds[kind])
		local side = o.side or "BOTTOM"
		local inside = not (near and near.side == side) and frame.auraInside and frame.auraInside[side]
		-- inside: the opposite side's flow, pinned to the same corner of the anchor
		local point, rel, h, v, rows, ax, ay = blockCorners(inside and OPPOSITE[side] or side, o.reverse)
		if (inside) then
			rel = point
		end
		container:SetFlowLayoutAxis(AXIS.Horizontal)
		container:SetFlowLayoutAnchorPoint(point)
		container:SetFlowLayoutGrowthDirection(h, v)
		container:ClearAllPoints()
		container:SetPoint(point, holder, point, 0, 0)
		holder:ClearAllPoints()
		holder:SetSize(1, 1)
		local away
		local base, sx, sy
		if (frame.auraSideAnchor) then
			base, sx, sy = frame.auraSideAnchor(frame, side)
		end
		base = base or anchor
		local target = base
		if (near and near.side == side) then
			-- beyond the nearer block, which is placed already: no overlap however many lines it wraps
			target, away = near.container, (rows and gap > 0) and gap or 3
		elseif (inside) then
			away = 0
		else
			away = (side == "TOP" and gap or 0) + (frame.auraInset and frame.auraInset(frame, side) or 0)
		end
		local x, y = (o.x or 0) + ax * away, (o.y or 0) + ay * away
		if (target == base) then
			x, y = x + (sx or 0), y + (sy or 0)
		end
		frame.auraHandleAnchor = frame.auraHandleAnchor or {}
		local spacer = kind == "buffs" and target == base and not inside and frame.auraSpacer
		if (spacer) then
			-- frame.auraSpacer (the Player's weapon enchants) takes the start of the buff line and the holder
			-- hangs off its far end: resizing the spacer, allowed in combat, moves the buffs without a
			-- holder setter call, which the client refuses while auras are secret
			local far = rows and point:gsub("LEFT", "<"):gsub("RIGHT", "LEFT"):gsub("<", "RIGHT")
				or point:gsub("TOP", "<"):gsub("BOTTOM", "TOP"):gsub("<", "BOTTOM")
			spacer:ClearAllPoints()
			spacer:SetPoint(point, target, rel, x, y)
			-- a frame of length 0 has no rect, and neither would the holder: the spacer is 1 longer
			-- than its icons and the holder steps back by that 1
			local bx, by = rows and -h or 0, rows and 0 or -v
			holder:SetPoint(point, spacer, far, bx, by)
			frame.auraSpacerFlow = {point = point, h = h, v = v, rows = rows}
			frame.auraHandleAnchor[kind] = {target = spacer, rel = far, x = bx, y = by, rows = rows, grow = h, stack = v}
		else
			holder:SetPoint(point, target, rel, x, y)
			frame.auraHandleAnchor[kind] = {target = base, after = target ~= base and near.kind or nil, rel = rel,
				x = x, y = y, rows = rows, grow = h, stack = v}
			if (kind == "buffs") then
				frame.auraSpacerFlow = nil
			end
		end
		-- a disabled kind draws nothing, so it does not push the other one away
		if (o.enable) then
			near = near or {side = side, container = container, kind = kind}
		end
		frame.auraHandlePoint = frame.auraHandlePoint or {}
		frame.auraHandlePoint[kind] = point
	end
	ensureHandles(frame)
	if (frame.onAurasPlaced) then
		frame.onAurasPlaced(frame)
	end
end

-- ZPerl.AurasGroups(c, kind[, exclude]): the aura groups of a frame's buff or debuff container, from
-- the frame's options c and kind "buffs" or "debuffs"; a list of {key, filter, candidateFilters, size,
-- maxFrameCount, layoutIndex, cooldown, countdown}. exclude is a set of spell IDs the groups drop.
-- Reads no unit state and no aura data, so the filters apply whatever the unit's reaction.
-- One group, "other", unless an option asks for more. castable / curable (ticked = 1) add the RAID
-- token; onlyMine keeps the player's auras (and the pets' on the stand-in, see below). big splits "mine" (the player's and
-- pets', double size, first) from "other"; buffs.bigStealable adds "steal" (stealable buffs, double
-- size) and keeps them out of "other". buffs.bigpet is not read: the owner filter includes the pet.
-- lineSize (the container's line width) and buffs.rows set each group's maxFrameCount to rows x icons per
-- line, floor((lineSize + 3) / (size + 3)); without either it is math.huge, the container's own
-- default (no cap). half halves the sizes.
-- The global buffs.cooldown / countdown say whether a group's buttons draw the swipe / the duration text;
-- cooldownAny / countdownAny off limit them to the player's auras, which splits a "mine" group off
-- (at the normal size when Big is off) unless the group is all mine already.
function ZPerl.AurasGroups(c, kind, exclude, lineSize, half)
	local o = c[kind]
	local rows = c.buffs.rows
	local filter = kind == "buffs" and "HELPFUL" or "HARMFUL"
	if (o[kind == "buffs" and "castable" or "curable"] == 1) then
		filter = filter.."|RAID"
	end
	local b = conf.buffs
	local split = (b.cooldown and not b.cooldownAny) or (b.countdown and not b.countdownAny and c.auraText ~= false)
	local textOff = c.auraText == false
	local gap = ZPerl.AuraGap(c)
	-- Blizzard's container cannot be trusted with the owner candidate filter, so there the owner
	-- goes in the aura query instead: PLAYER (cast by the player, the pet or the vehicle) for a group of the
	-- player's auras, !PLAYER for the groups beside it. Every group there tests every aura on its own (an aura
	-- is not claimed by the first group it fits), so without !PLAYER "other" shows the player's auras again.
	-- A client whose filters cannot be negated (no AuraUtil.AuraFilterNegationPrefix) keeps only the candidate
	-- filter on those. The stand-in applies the candidate filter itself, so it gets no token.
	local native = not ZPerl.AuraStandIn
	local canNegate = native and AuraUtil and AuraUtil.AuraFilterNegationPrefix == "!"
	-- Where the token carries the owner the candidate filter does not: Blizzard's test of a secret
	-- isFromPlayerOrPlayerPet (another player's buff) drops the aura rather than passing it.
	local function group(key, size, owner, stealable)
		local f = filter
		local candOwner = owner
		if (owner == true and native) then
			f = f.."|PLAYER"
			candOwner = nil
		elseif (owner == false and canNegate) then
			f = f.."|!PLAYER"
			candOwner = nil
		end
		local cand
		if (exclude or candOwner ~= nil or stealable ~= nil) then
			cand = {excludeSpellIDs = exclude, isFromPlayerOrPlayerPet = candOwner, isStealable = stealable}
		end
		return {
			key = key,
			filter = f,
			candidateFilters = cand,
			size = size,
			maxFrameCount = (lineSize and rows and size) and rows * max(1, floor((lineSize + 3) / (size + 3))) or math.huge,
			layoutIndex = 1,
			-- the swipe and the text are one global for buffs and debuffs
			cooldown = b.cooldown and (b.cooldownAny or owner == true) and true or false,
			countdown = not textOff and b.countdown and (b.countdownAny or owner == true) and true or false,
			gap = gap,
		}
	end
	local size = o.size
	if (half and size) then
		size = size / 2
	end
	local big = o.big and size and size * 2
	if (o.onlyMine) then
		-- group adds the PLAYER token on Blizzard's container (see above)
		return {group(big and "mine" or "other", big or size, true)}
	end
	local mineSize = big or (split and size)
	local steal = kind == "buffs" and o.bigStealable
	-- false when the sibling groups take the other side of the split, else nil (no constraint)
	local notMine, notSteal
	if (mineSize) then
		notMine = false
	end
	if (steal) then
		notSteal = false
	end
	local list = {}
	if (mineSize) then
		list[#list + 1] = group("mine", mineSize, true)
	end
	if (steal) then
		list[#list + 1] = group("steal", size and size * 2, notMine, true)
	end
	list[#list + 1] = group("other", size, notMine, notSteal)
	for n, g in ipairs(list) do
		g.layoutIndex = n
	end
	return list
end

-- the container's line width for kind "buffs" or "debuffs"
local function lineSizeOf(frame, kind)
	return frame.auraLineSize(frame, kind)
end

-- ZPerl.AurasRebuild(frame): builds the containers, or, once built and while auras are readable,
-- tears them down and builds them again from the current options and unit.
function ZPerl.AurasRebuild(frame)
	local c = frame.conf
	frame.auraLineSize = frame.auraLineSize or ZPerl.AurasLineSize
	if (not c or not frame.partyid or not ZPerl.HasAuraContainerNow()) then
		return
	end
	if (not UnitExists(frame.partyid)) then
		-- the unit is back later: Update applies the request then
		if (frame.buffContainer) then
			frame.auraContainerPending = true
		end
		return
	end
	local fresh = not frame.buffContainer
	if (not fresh) then
		if (not ZPerl.AuraContainerGate(frame)) then
			return
		end
		frame.buffContainer:Hide()
		frame.debuffContainer:Hide()
		frame.buffContainer, frame.debuffContainer = nil, nil
	end

	-- debuffs.halfSize (party): half-size debuffs while Update found more than fit the line
	local half = c.debuffs.halfSize and frame.auraHalf or false
	frame.auraHalf = half
	frame.auraContainerPending = nil
	local exclude = ZPerl.AuraBlacklist.Set and ZPerl.AuraBlacklist.Set(frame)
	local buffLine, debuffLine = lineSizeOf(frame, "buffs"), lineSizeOf(frame, "debuffs")
	local buffContainer = ZPerl.AuraContainerCreate(frame, "buffHalfFrame",
		frame:GetName().."AuraBuffs", ZPerl.AurasGroups(c, "buffs", exclude, buffLine), buffLine)
	local debuffContainer = ZPerl.AuraContainerCreate(frame, "debuffHalfFrame",
		frame:GetName().."AuraDebuffs", ZPerl.AurasGroups(c, "debuffs", nil, debuffLine, half), debuffLine)
	frame.buffContainer, frame.debuffContainer = buffContainer, debuffContainer
	if (frame.auraContainerPending) then
		-- Create left a live container as it was (auras secret): placing it would reconfigure it
		return
	end
	ZPerl.AurasPlace(frame, fresh)
end

-- the container's own auto-refresh event list does not include UNIT_AURA: refresh on every show
-- a SetUnit that raises (a live container, auras secret) leaves the rebuild pending, which sets the unit
local function showContainer(frame, container, unit, enabled)
	-- while secret a pending frame waits for the rebuild instead of retrying (and reporting) each event
	if (container:GetUnit() ~= unit) then
		-- the container still tracks the old unit: hidden until the rebuild applies
		if (not ZPerl.AuraContainerGate(frame) or not ZPerl.Pcall(container.SetUnit, container, unit)) then
			frame.auraContainerPending = true
			if (container:IsShown()) then
				container:Hide()
			end
			return
		end
	end
	if (enabled) then
		if (not container:IsShown()) then
			container:Show()
		end
		if (container.UpdateAllAuras) then
			container:UpdateAllAuras()
		end
	elseif (container:IsShown()) then
		container:Hide()
	end
end

-- debuffs.halfSize (party): while auras are readable, half the
-- debuff size when more debuffs than fit the line, full size when they fit; a change rebuilds. While
-- secret the size stays.
local halfFilters = {}
local function checkHalfSize(frame, c, unit)
	local d = c.debuffs
	if (not d.halfSize or not d.enable or not d.size or not frame.debuffContainer or ZPerl.AurasSecret()) then
		return
	end
	local key = (d.curable == 1 and 2 or 0) + (d.onlyMine and 1 or 0)
	local filter = halfFilters[key]
	if (not filter) then
		filter = "HARMFUL"..(d.curable == 1 and "|RAID" or "")..(d.onlyMine and "|PLAYER" or "")
		halfFilters[key] = filter
	end
	-- the id list is the only way to count the debuffs against the line; it is the API's table, one per
	-- UNIT_AURA of a party frame with halfSize on
	local count
	if (C_UnitAuras.GetUnitAuraInstanceIDs) then
		local ids = C_UnitAuras.GetUnitAuraInstanceIDs(unit, filter)
		count = ids and #ids
	else
		-- Classic Era: counted by index
		count = 0
		while (ZPerl.AuraData(unit, count + 1, filter)) do
			count = count + 1
		end
	end
	local fit = max(1, floor((lineSizeOf(frame, "debuffs") + 3) / (d.size + 3)))
	local half = count ~= nil and count > fit
	if (half ~= (frame.auraHalf or false)) then
		frame.auraHalf = half
		ZPerl.AurasRebuild(frame)
	end
end

-- ZPerl.AurasUpdate(frame): shows the display that owns the auras now and refreshes it.
function ZPerl.AurasUpdate(frame)
	local c = frame.conf
	local unit = frame.partyid
	if (not c or not unit or not UnitExists(unit)) then
		return
	end
	if (frame.auraContainerPending or not frame.buffContainer) then
		ZPerl.AurasRebuild(frame)
	end
	local buffContainer, debuffContainer = frame.buffContainer, frame.debuffContainer
	if (not buffContainer) then
		return
	end
	checkHalfSize(frame, c, unit)

	local buffs, debuffs = c.buffs.enable, c.debuffs.enable
	if (frame.auraDebuffsNeedBuffs) then
		debuffs = buffs and debuffs
	end
	showContainer(frame, buffContainer, unit, buffs)
	showContainer(frame, debuffContainer, unit, debuffs)
end

-- Aura secrecy can flip after the combat event has been dispatched: run again one tick later.
local function updateAurasInCombatChange(frame)
	ZPerl.AurasUpdate(frame)
	C_Timer.After(0, function()
		ZPerl.AurasUpdate(frame)
	end)
end
local function updateAuras(frame, unit)
	if (unit == frame.partyid) then
		ZPerl.AurasUpdate(frame)
	end
end
ZPerl.Elements.Auras = {events = {
	UNIT_AURA = updateAuras,
	PLAYER_REGEN_DISABLED = updateAurasInCombatChange,
	PLAYER_REGEN_ENABLED = updateAurasInCombatChange,
}}
