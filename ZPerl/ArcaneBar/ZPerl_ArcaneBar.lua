-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local ArcaneBars = {}

--[===[@debug@
local function d(...)
	ChatFrame1:AddMessage("Z-Perl: "..format(...))
end
--@end-debug@]===]

local conf
ZPerl.RequestConfig(function(new)
	conf = new
end, "$Revision:  $")


-- Upvalues
local format = format
local ipairs = ipairs
local max = max
local min = min
local pairs = pairs
local strfind = strfind
local tinsert = tinsert
local wipe = wipe

local CreateColor = CreateColor
local CreateFrame = CreateFrame
local GetNetStats = GetNetStats
local GetTime = GetTime
local GetUnitEmpowerHoldAtMaxTime = GetUnitEmpowerHoldAtMaxTime
local GetUnitEmpowerStageDuration = GetUnitEmpowerStageDuration
local UnitCastingDuration = UnitCastingDuration
local UnitCastingInfo = UnitCastingInfo
local UnitChannelDuration = UnitChannelDuration
local UnitChannelInfo = UnitChannelInfo
local UnitEmpoweredChannelDuration = UnitEmpoweredChannelDuration

local CASTING_BAR_HOLD_TIME = CASTING_BAR_HOLD_TIME
local FAILED = FAILED
local SPELL_FAILED_INTERRUPTED = SPELL_FAILED_INTERRUPTED

-- Cast times of other units can be secret in restricted content.
-- When the client offers duration objects the bar is driven by Blizzard
-- (SetTimerDuration); otherwise a simple sweep animation is shown.
local CanAccess = ZPerl.CanAccess
local IsSecret = ZPerl.IsSecret
local SafeBool = ZPerl.SafeBool

-- SetSecretTimes
-- Called instead of the start/end time maths when those values are secret. empowered: an evoker's
-- empowered cast, timed by its own duration object (stages and hold at max included).
local function SetSecretTimes(self, channeling, empowered)
	self.startTime, self.maxValue, self.endTime = nil, nil, nil
	self.timerDuration, self.unknownTime = nil, nil

	local durationObject
	if (self.SetTimerDuration) then
		if (empowered and UnitEmpoweredChannelDuration) then
			durationObject = UnitEmpoweredChannelDuration(self.unit, true)
		elseif (channeling and UnitChannelDuration) then
			durationObject = UnitChannelDuration(self.unit)
		elseif (not channeling and UnitCastingDuration) then
			durationObject = UnitCastingDuration(self.unit)
		end
	end

	if (durationObject) then
		self:SetTimerDuration(durationObject)
		self.timerDuration = true
	else
		-- Nothing about the cast can be read: breathe the bar until it ends
		self:SetMinMaxValues(0, 1)
		self:SetValue(0)
		self.unknownTime = true
		self.breathLevel, self.breathDir = 0, 1
	end
end

-- ClearSecretTimes
local function ClearSecretTimes(self)
	if (self.timerDuration) then
		self:SetMinMaxValues(0, 1)
		self:SetValue(1)
	end
	self.timerDuration, self.unknownTime = nil, nil
end

-- SecureUpdate
-- OnUpdate for bars whose cast times are secret
local function SecureUpdate(self, elapsed)
	if (self.unknownTime) then
		-- Fill for 1.2 s, drain for 1.2 s, repeat
		local level = self.breathLevel + (elapsed / 1.2) * self.breathDir
		if (level >= 1) then
			level, self.breathDir = 1, -1
		elseif (level <= 0) then
			level, self.breathDir = 0, 1
		end
		self.breathLevel = level
		self:SetValue(level)
		self.castTimeText:Hide()
	elseif (self.GetRemainingTime) then
		self.castTimeText:SetFormattedText("%.1f", self:GetRemainingTime())
	else
		self.castTimeText:Hide()
	end

	-- Whoever moved the fill, the spark sits on its leading edge
	if (self.barSpark) then
		local fill = self:GetStatusBarTexture()
		if (fill) then
			self.barSpark:ClearAllPoints()
			self.barSpark:SetPoint("TOP", fill, "TOPRIGHT", 0, 22)
			self.barSpark:SetPoint("BOTTOM", fill, "BOTTOMRIGHT", 0, -19)
		end
	end
	self.barFlash:Hide()
	if (self.precast) then
		self.precast:Hide()
	end
end

-- SpellName
local function SpellName(name)
	if (CanAccess(name)) then
		return (name:gsub(" %- No Text", ""))
	end
	return name
end

-- SameCast
-- castID comparison that tolerates secret IDs (never filters them out)
local function SameCast(castID, lineGUID)
	if (not CanAccess(castID) or not CanAccess(lineGUID)) then
		return true
	end
	return castID == 0 or castID == lineGUID
end

-- Registers frame to spellcast events.
local barColors = {
	main = {r = 1.0, g = 0.7, b = 0.0},
	channel = {r = 0.0, g = 1.0, b = 0.0},
	success = {r = 0.0, g = 1.0, b = 0.0},
	failure = {r = 1.0, g = 0.0, b = 0.0}
}

local events = {
	"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_INTERRUPTIBLE", "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "UNIT_SPELLCAST_DELAYED", "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_CHANNEL_STOP", "PLAYER_ENTERING_WORLD",
	-- Evoker empowered casts (retail; ZPerl.On skips events a client does not have)
	"UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_UPDATE", "UNIT_SPELLCAST_EMPOWER_STOP",
}

------------------------------------------------------------------------------
-- Empowered casts (evoker): held to charge through stages, released to cast. The bar fills like a cast over
-- the stages plus the time the spell can be held at its last stage; a thin pip marks where each stage is
-- reached, the fill takes the color of the stage reached, and at the end the bar holds full until the
-- release (UNIT_SPELLCAST_EMPOWER_STOP). With secret cast times the bar runs on the empowered duration
-- object and shows no stages.
local stageColors = {
	[0] = {0.55, 0.55, 0.55},	-- Charging, no stage yet
	{1.0, 0.82, 0.0},
	{1.0, 0.6, 0.0},
	{1.0, 0.35, 0.0},
	{1.0, 0.15, 0.15},
}

-- ClearStages
local function ClearStages(self)
	if (self.stagePips) then
		for _, pip in ipairs(self.stagePips) do
			pip:Hide()
		end
	end
	self.stagePoints = nil
	self.stage = nil
end

-- AddStages(self, numStages, totalMs): pips at the end of each stage, from the client's stage durations
local function AddStages(self, numStages, totalMs)
	ClearStages(self)
	if (not GetUnitEmpowerStageDuration or not CanAccess(numStages) or not CanAccess(totalMs) or totalMs <= 0) then
		return
	end
	local width = self:GetWidth()
	if (not CanAccess(width) or width <= 0) then
		return
	end
	self.stagePips = self.stagePips or {}
	local points, sum = {}, 0
	for i = 1, numStages do
		local duration = GetUnitEmpowerStageDuration(self.unit, i - 1)
		if (not CanAccess(duration)) then
			ClearStages(self)
			return
		end
		---@diagnostic disable-next-line: secret-comparison
		if (duration > 0) then
			---@diagnostic disable-next-line: secret-arithmetic
			sum = sum + duration
			points[#points + 1] = sum
			local pip = self.stagePips[#points]
			if (not pip) then
				pip = self:CreateTexture(nil, "OVERLAY")
				pip:SetColorTexture(1, 1, 1, 0.75)
				pip:SetWidth(2)
				self.stagePips[#points] = pip
			end
			pip:ClearAllPoints()
			pip:SetPoint("TOP", self, "TOPLEFT", width * min(1, sum / totalMs), 0)
			pip:SetPoint("BOTTOM", self, "BOTTOMLEFT", width * min(1, sum / totalMs), 0)
			pip:Show()
		end
	end
	self.stagePoints = points
	self.stage = -1
end

-- UpdateStage(self, elapsedMs): the stage reached so far colors the fill
local function UpdateStage(self, elapsedMs)
	local points = self.stagePoints
	if (not points) then
		return
	end
	local stage = 0
	for i, point in ipairs(points) do
		if (elapsedMs >= point) then
			stage = i
		else
			break
		end
	end
	if (stage ~= self.stage) then
		self.stage = stage
		local c = stageColors[min(stage, #stageColors)]
		self:SetStatusBarColor(c[1], c[2], c[3], conf.transparency.frame)
	end
end

-- enableToggle
-- Each enabled bar listens on the bus (ZPerl.On) for the cast events and its target/focus/party event.
local function listen(self, event)
	local fn = self.busFn
	if (not fn) then
		fn = function(...)
			ZPerl.ArcaneBar.OnEvent(self, ...)
		end
		self.busFn = fn
		self.busEvents = {}
	end
	ZPerl.On(event, fn)
	tinsert(self.busEvents, event)
end

local function enableToggle(self, value)
	if (value) then
		if (not self.Enabled) then
			for i, event in pairs(events) do
				listen(self, event)
			end

			self:SetScript("OnUpdate", ZPerl.ArcaneBar.OnUpdate)
			if (self.unit == "target") then
				listen(self, "PLAYER_TARGET_CHANGED")
			elseif (self.unit == "focus") then
				listen(self, "PLAYER_FOCUS_CHANGED")
			elseif (strfind(self.unit, "^party")) then
				listen(self, "PARTY_MEMBER_ENABLE")
				listen(self, "PARTY_MEMBER_DISABLE")
			end
			self.Enabled = 1
		end
	else
		if (self.Enabled) then
			for i, event in ipairs(self.busEvents) do
				ZPerl.Off(event, self.busFn)
			end
			wipe(self.busEvents)
			self:SetScript("OnUpdate", nil)
			self.Enabled = nil
			self:Hide()
		end
	end
end

-- overrideToggle(value): value (Keep Blizzard's cast bar) shows Blizzard's player cast bar
local function overrideToggle(value)
	if (ArcaneBars.player) then
		-- CastingBarFrame on Classic Era
		ZPerl.BlizzFrameHide(_G.PlayerCastingBarFrame or _G.CastingBarFrame, not value)
	end
end

-- ActiveCasting
-- See if we're probably still casting a spell, even though some other spell END event occured
local function ActiveCasting(self)
	local t = GetTime() * 1000
	local name, _, _, _, endTime = UnitCastingInfo(self.unit)
	if (not name) then
		name, _, _, _, endTime = UnitChannelInfo(self.unit)
	end
	if (name) then
		-- A secret end time means we cannot tell, assume active
		---@diagnostic disable-next-line: secret-comparison
		if (not CanAccess(endTime) or endTime > t + 500) then
			return true
		end
	end
end

--------------------------------------------------
--
-- Event/Update Handlers
--
--------------------------------------------------

-- ZPerl.ArcaneBar.OnEvent
function ZPerl.ArcaneBar.OnEvent(self, event, unit, ...)
	-- Override for showPlayer attribute in party.
	if self.unit == "partyplayer" then
		self.unit = "player"
	end

	if (event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "PARTY_MEMBER_ENABLE" or event == "PARTY_MEMBER_DISABLE") then
		local nameChannel, _, _, _, _, _, _, _, _, numStages = UnitChannelInfo(self.unit)
		local nameSpell = UnitCastingInfo(self.unit)
		if nameChannel then
			-- An empowered cast is a channel with stages
			if (CanAccess(numStages) and numStages and numStages > 0) then
				event = "UNIT_SPELLCAST_EMPOWER_START"
			else
				event = "UNIT_SPELLCAST_CHANNEL_START"
			end
			unit = self.unit
		elseif (nameSpell) then
			event = "UNIT_SPELLCAST_START"
			unit = self.unit
		else
			self.empowered = nil
			ClearStages(self)
			self:Hide()
			self.castTimeText:Hide()
			self.barParentName:SetAlpha(conf.transparency.text)
			self.barParentName:Show()
			return
		end
	end

	if (unit ~= self.unit) then
		return
	end

	-- An empowered cast ends with its own UNIT_SPELLCAST_EMPOWER_STOP: the other casts' stop, fail and interrupt
	-- events (an instant cast while charging) leave it be
	if (self.empowered and (event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED"
		or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_DELAYED")) then
		return
	end

	if (event == "UNIT_SPELLCAST_EMPOWER_START") then
		local name, _, _, startTime, endTime, isTradeSkill, _, _, _, numStages = UnitChannelInfo(self.unit)
		if (not name or (not self.showTradeSkills and isTradeSkill)) then
			self:Hide()
			return
		end
		self.spellText:SetText(SpellName(name))
		self.castID = nil
		self.barParentName:Hide()
		self.barSpark:Show()
		if (self.precast) then
			self.precast:Hide()
		end
		ClearStages(self)
		local hold = GetUnitEmpowerHoldAtMaxTime and GetUnitEmpowerHoldAtMaxTime(self.unit)
		if (IsSecret(startTime) or IsSecret(endTime) or IsSecret(hold)) then
			local c = stageColors[0]
			self:SetStatusBarColor(c[1], c[2], c[3], conf.transparency.frame)
			SetSecretTimes(self, true, true)
		else
			ClearSecretTimes(self)
			---@diagnostic disable-next-line: secret-arithmetic
			local totalMs = endTime + (hold or 0) - startTime
			---@diagnostic disable-next-line: secret-arithmetic
			self.startTime = startTime / 1000
			---@diagnostic disable-next-line: secret-arithmetic
			self.maxValue = (startTime + totalMs) / 1000
			self:SetMinMaxValues(self.startTime, self.maxValue)
			self:SetValue(self.startTime)
		end
		self:SetAlpha(1.0)
		self.castAlpha = 1.0
		self.holdTime = 0
		self.casting, self.channeling, self.fadeOut, self.flash = 1, nil, nil, nil
		self.empowered = true
		self:Show()
		self.delaySum = 0
		if (conf.player.castBar.castTime) then
			self.castTimeText:Show()
		else
			self.castTimeText:Hide()
		end
		-- Pips after Show, so the bar has its width
		if (self.startTime) then
			AddStages(self, numStages, (self.maxValue - self.startTime) * 1000)
			UpdateStage(self, 0)
		end
	elseif (event == "UNIT_SPELLCAST_EMPOWER_UPDATE") then
		if (self.empowered and self:IsShown()) then
			local name, _, _, startTime, endTime, _, _, _, _, numStages = UnitChannelInfo(self.unit)
			if (not name) then
				return
			end
			local hold = GetUnitEmpowerHoldAtMaxTime and GetUnitEmpowerHoldAtMaxTime(self.unit)
			if (IsSecret(startTime) or IsSecret(endTime) or IsSecret(hold)) then
				ClearStages(self)
				SetSecretTimes(self, true, true)
			else
				---@diagnostic disable-next-line: secret-arithmetic
				local totalMs = endTime + (hold or 0) - startTime
				---@diagnostic disable-next-line: secret-arithmetic
				self.startTime = startTime / 1000
				---@diagnostic disable-next-line: secret-arithmetic
				self.maxValue = (startTime + totalMs) / 1000
				self:SetMinMaxValues(self.startTime, self.maxValue)
				AddStages(self, numStages, totalMs)
			end
		end
	elseif (event == "UNIT_SPELLCAST_EMPOWER_STOP") then
		if (not self.empowered) then
			return
		end
		local _, _, complete = ...
		self.empowered = nil
		ClearStages(self)
		ClearSecretTimes(self)
		self.castTimeText:Hide()
		if (self.maxValue) then
			self:SetValue(self.maxValue)
		end
		self.barSpark:Hide()
		self.casting, self.channeling = nil, nil
		if (SafeBool(complete, true)) then
			-- released: the stage it was released at keeps its color through the flash
			self.barFlash:SetAlpha(0)
			self.flashAlpha = 0
			self.barFlash:Show()
			self.holdTime = 0
		else
			self.spellText:SetText(SPELL_FAILED_INTERRUPTED)
			self:SetStatusBarColor(barColors.failure.r, barColors.failure.g, barColors.failure.b, conf.transparency.frame)
			self.holdTime = GetTime() + (CASTING_BAR_HOLD_TIME or 1)
		end
		if (not self.fadeOut) then
			self.flash = 1
		end
		self.fadeOut = 1
	elseif (event == "UNIT_SPELLCAST_START") then
		local name, _, _, startTime, endTime, isTradeSkill, castID = UnitCastingInfo(self.unit)
		if (not name or (not self.showTradeSkills and isTradeSkill)) then
			self:Hide()
			return
		end

		self.empowered = nil
		ClearStages(self)
		self:SetStatusBarColor(barColors.main.r, barColors.main.g, barColors.main.b, conf.transparency.frame)
		self.spellText:SetText(SpellName(name))
		self.castID = castID
		self.barParentName:Hide()
		self.barSpark:Show()
		if (IsSecret(startTime) or IsSecret(endTime)) then
			SetSecretTimes(self, false)
		else
			ClearSecretTimes(self)
			---@diagnostic disable-next-line: secret-arithmetic
			self.startTime = startTime / 1000
			---@diagnostic disable-next-line: secret-arithmetic
			self.maxValue = endTime / 1000
			self:SetMinMaxValues(self.startTime, self.maxValue)
			self:SetValue(self.startTime)
		end
		self:SetAlpha(0.8)
		self.castAlpha = 0.8
		self.holdTime = 0
		self.casting, self.channeling, self.fadeOut, self.flash = 1, nil, nil, nil
		self:Show()
		self.delaySum = 0
		if (conf.player.castBar.castTime) then
			self.castTimeText:Show()
		else
			self.castTimeText:Hide()
		end
	elseif ((event == "UNIT_SPELLCAST_STOP" and self.casting) or (event == "UNIT_SPELLCAST_CHANNEL_STOP" and self.channeling)) then
		local lineGUID = ...
		if event == "UNIT_SPELLCAST_STOP" and not SameCast(self.castID, lineGUID) then
			return
		end
		if (not ActiveCasting(self)) then
			self.delaySum = 0
			self.sign = "+"
			self.castTimeText:Hide()
			if (not self:IsVisible()) then
				self:Hide()
			end
			if (self:IsShown()) then
				ClearSecretTimes(self)
				if (self.maxValue) then
					self:SetValue(self.maxValue)
				end
				self:SetStatusBarColor(barColors.success.r, barColors.success.g, barColors.success.b, conf.transparency.frame)
				self.barSpark:Hide()
				self.barFlash:SetAlpha(0)
				self.flashAlpha = 0
				self.barFlash:Show()
				self.casting = nil
				self.channeling = nil
				if (not self.fadeOut or event == "UNIT_SPELLCAST_CHANNEL_STOP") then
					self.flash = 1
				end
				self.fadeOut = 1
				self.holdTime = 0
			end
		end
	elseif (event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED") then
		local lineGUID = ...
		if not SameCast(self.castID, lineGUID) then
			return
		end
		if (not self.fadeOut and self:IsShown() and not ActiveCasting(self)) then
			if (event == "UNIT_SPELLCAST_FAILED") then
				self.spellText:SetText(FAILED)
			else
				self.spellText:SetText(SPELL_FAILED_INTERRUPTED)
			end

			ClearSecretTimes(self)
			if (self.maxValue) then
				self:SetValue(self.maxValue)
			end
			self:SetStatusBarColor(barColors.failure.r, barColors.failure.g, barColors.failure.b, conf.transparency.frame)
			self.barSpark:Hide()
			self.casting = nil
			self.channeling = nil
			if (not self.fadeOut) then
				self.flash = 1
			end
			self.fadeOut = 1
			self.holdTime = GetTime() + (CASTING_BAR_HOLD_TIME or 1)
		end
	elseif (event == "UNIT_SPELLCAST_INTERRUPTIBLE") or (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then
		if (self:IsShown()) then
			local name, _, _, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
			if (not name) then
				name, _, _, startTime, endTime, isTradeSkill = UnitChannelInfo(self.unit)
			end
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				-- If there is no name, there is no bar
				self:Hide()
				return
			end
			self.spellText:SetText(SpellName(name))
			if (IsSecret(startTime) or IsSecret(endTime)) then
				SetSecretTimes(self, self.channeling)
			else
				---@diagnostic disable-next-line: secret-arithmetic
				self.startTime = startTime / 1000
				---@diagnostic disable-next-line: secret-arithmetic
				self.maxValue = endTime / 1000
				self:SetMinMaxValues(self.startTime, self.maxValue)
			end
		end
	elseif (event == "UNIT_SPELLCAST_DELAYED") then
		if (self:IsShown()) then
			local name, _, _, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				-- If there is no name, there is no bar
				self:Hide()
				return
			end
			if (IsSecret(startTime) or IsSecret(endTime)) then
				SetSecretTimes(self, false)
			else
				---@diagnostic disable-next-line: secret-arithmetic
				self.startTime = startTime / 1000
				---@diagnostic disable-next-line: secret-arithmetic
				self.maxValue = endTime / 1000
				self:SetMinMaxValues(self.startTime, self.maxValue)
			end
		end
	elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
		local name, _, _, startTime, endTime, isTradeSkill = UnitChannelInfo(self.unit)
		if (not name or (not self.showTradeSkills and isTradeSkill)) then
			-- If there is no name, there is no bar
			self:Hide()
			return
		end

		self.empowered = nil
		ClearStages(self)
		self:SetStatusBarColor(barColors.channel.r, barColors.channel.g, barColors.channel.b, conf.transparency.frame)
		self.barSpark:Show()
		self.barParentName:Hide()
		self.spellText:SetText(SpellName(name))
		if (IsSecret(startTime) or IsSecret(endTime)) then
			SetSecretTimes(self, true)
		else
			ClearSecretTimes(self)
			self.maxValue = 1
			---@diagnostic disable-next-line: secret-arithmetic
			self.startTime = startTime / 1000
			---@diagnostic disable-next-line: secret-arithmetic
			self.endTime = endTime / 1000
			self:SetMinMaxValues(self.startTime, self.endTime)
			self:SetValue(self.endTime)
		end
		self:SetAlpha(1.0)
		self.castAlpha = 1.0
		self.holdTime = 0
		self.casting, self.channeling, self.fadeOut, self.flash = nil, 1, nil, nil
		self:Show()
		self.delaySum = 0
		if (conf.player.castBar.castTime) then
			self.castTimeText:Show()
		else
			self.castTimeText:Hide()
		end
	elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
		if (self:IsShown()) then
			local name, _, _, startTime, endTime, isTradeSkill = UnitChannelInfo(self.unit)
			if (not name or (not self.showTradeSkills and isTradeSkill)) then
				-- If there is no name, there is no bar
				self:Hide()
				return
			end
			if (IsSecret(startTime) or IsSecret(endTime)) then
				SetSecretTimes(self, true)
			else
				---@diagnostic disable-next-line: secret-arithmetic
				self.startTime = startTime / 1000
				---@diagnostic disable-next-line: secret-arithmetic
				self.endTime = endTime / 1000
				self.maxValue = self.startTime
				self:SetMinMaxValues(self.startTime, self.endTime)
			end
		end
	end

	if (not self:IsShown()) then
		self.castTimeText:Hide()
		self.barParentName:SetAlpha(conf.transparency.text)
		self.barParentName:Show()
	end
end

local function ShowPrecast(self, side)
	if (self.precast) then
		-- A channel's span ends at endTime; maxValue is a placeholder there
		local finish = self.channeling and self.endTime or self.maxValue
		if (conf.player.castBar.precast and finish and CanAccess(finish) and CanAccess(self.startTime)) then
			local _, _, _, latencyWorld = GetNetStats()
			local lag = min(1000, latencyWorld)
			if (lag < 10) then
				self.precast:Hide()
			else
				local total = finish - self.startTime
				if total <= 0 then
					total = 1.5
				end
				local width = self:GetWidth() / ((total * 1000) / lag)

				self.precast:ClearAllPoints()
				self.precast:SetPoint(side)
				self.precast:SetWidth(width)
				self.precast:SetHeight(self:GetHeight())
				self.precast:Show()
			end
		else
			self.precast:Hide()
		end
	end
end

-- ZPerl.ArcaneBar.OnUpdate
function ZPerl.ArcaneBar.OnUpdate(self, elapsed)
	-- Secret cast times, no maths possible here
	if ((self.timerDuration or self.unknownTime) and (self.casting or self.channeling)) then
		SecureUpdate(self, elapsed)
		return
	end

	local getTime = GetTime()
	local current_time = (self.maxValue or getTime) - getTime
	if (self.channeling) then
		current_time = self.endTime - getTime
	end
	if (current_time < 0) then
		current_time = 0
	end
	local text = format("%.1f", current_time)

	self.castTimeText:SetText(text)

	if (self.casting and self.empowered) then
		-- Charging through the stages, then held full until the release (UNIT_SPELLCAST_EMPOWER_STOP)
		local status = min(getTime, self.maxValue)
		local span = self.maxValue - self.startTime
		local fraction = span > 0 and (status - self.startTime) / span or 1
		self:SetValue(status)
		self.barFlash:Hide()
		UpdateStage(self, (status - self.startTime) * 1000)
		if (status >= self.maxValue) then
			self.barSpark:Hide()
		else
			local sparkPosition = max(0, fraction * self:GetWidth())
			self.barSpark:SetPoint("TOP", self, "TOPLEFT", sparkPosition, 22)
			self.barSpark:SetPoint("BOTTOM", self, "BOTTOMLEFT", sparkPosition, -19)
		end
	elseif (self.casting) then
		local status = getTime
		if (status > self.maxValue) then
			status = self.maxValue
			self:SetValue(status)
			self.barSpark:Hide()
			self:SetStatusBarColor(barColors.success.r, barColors.success.g, barColors.success.b, conf.transparency.frame)
			self.casting = nil
			self.barFlash:SetAlpha(0)
			self.flashAlpha = 0
			self.barFlash:Show()
			if (not self.fadeOut) then
				self.flash = 1
			end
			self.holdTime = 0
			self.fadeOut = 1
			return
		end

		self:SetValue(status)
		self.barFlash:Hide()

		local sparkPosition = ((status - self.startTime) / (self.maxValue - self.startTime)) * self:GetWidth()
		if (sparkPosition < 0) then
			sparkPosition = 0
		end
		self.barSpark:SetPoint("TOP", self, "TOPLEFT", sparkPosition, 22)
		self.barSpark:SetPoint("BOTTOM", self, "BOTTOMLEFT", sparkPosition, -19)

		ShowPrecast(self, "RIGHT")
	elseif (self.channeling) then
		local time = getTime
		if (time > self.endTime) then
			time = self.endTime
		end
		if (time == self.endTime) then
			self.channeling = nil
			self.barSpark:Hide()
			self.barFlash:SetAlpha(0)
			self.flashAlpha = 0
			self.barFlash:Show()
			if (not self.fadeOut) then
				self.flash = 1
			end
			self.holdTime = 0
			self.fadeOut = 1
			return
		end
		local barValue = self.startTime + (self.endTime - time)
		self:SetValue( barValue )
		self.barFlash:Hide()

		local sparkPosition = ((barValue - self.startTime) / (self.endTime - self.startTime)) * self:GetWidth()
		self.barSpark:SetPoint("TOP", self, "TOPLEFT", sparkPosition, 22)
		self.barSpark:SetPoint("BOTTOM", self, "BOTTOMLEFT", sparkPosition, -19)

		ShowPrecast(self, "LEFT")
	elseif (getTime < self.holdTime) then
		return
	elseif (self.flash) then
		-- Alphas are kept in fields: inside a range-faded party frame GetAlpha returns a secret.
		local alpha = (self.flashAlpha or 0) + elapsed * 3	-- CASTING_BAR_FLASH_STEP
		if (alpha < 1) then
			self.flashAlpha = alpha
			self.barFlash:SetAlpha(alpha)
		else
			self.flashAlpha = 1
			self.barFlash:SetAlpha(1)
			self.flash = nil
		end
	elseif (self.fadeOut) then
		local alpha = (self.castAlpha or 1) - elapsed * 2			-- CASTING_BAR_ALPHA_STEP
		self.castAlpha = alpha
		if (alpha > 0) then
			self:SetAlpha(alpha)
			self.barParentName:SetAlpha((1 - alpha) * conf.transparency.text)
			self.barParentName:Show()
		else
			self.fadeOut = nil
			self:Hide()
		end
	end

	if (not self:IsShown()) then
		self.castTimeText:Hide()
		self.barParentName:SetAlpha(conf.transparency.text)
		self.barParentName:Show()
	end
end

-- ZPerl.ArcaneBar.OnLoad
function ZPerl.ArcaneBar.OnLoad(self)
	ZPerl.SetChildMembers(self)

	-- ZPerl2 style completion glow around the cast bar's parent (the name frame).
	local around = self:GetParent() or self
	self.barFlash:ClearAllPoints()
	self.barFlash:SetPoint("TOPLEFT", around, "TOPLEFT", -3, 9)
	self.barFlash:SetPoint("BOTTOMRIGHT", around, "BOTTOMRIGHT", 3, -9)
	self.tex:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_StatusBar")
	self.tex:SetHorizTile(false)
	self.tex:SetVertTile(false)

	self.casting = nil
	self.holdTime = 0

	ZPerl.RegisterBar(self)
end

-- ZPerl.ArcaneBar.Set
function ZPerl.ArcaneBar.Set()
	if (conf) then
		for k, v in pairs(ArcaneBars) do
			if (v.optFrame and v.optFrame.conf and v.optFrame.conf.castBar) then
				enableToggle(v.bar, v.optFrame.conf.castBar.enable)
				-- Off, the glow's texture stays hidden: the flash still times the fade out
				v.bar.barFlash.tex:SetShown(v.optFrame.conf.castBar.flash and true or false)

				v.bar.castTimeText:ClearAllPoints()
				if (conf.player.castBar.inside) then
					v.bar.castTimeText:SetPoint("RIGHT", v.bar, "RIGHT", -2, 0)
					v.bar.castTimeText:SetJustifyH("RIGHT")
				else
					v.bar.castTimeText:SetPoint("LEFT", v.bar, "RIGHT", 2, 0)
					v.bar.castTimeText:SetJustifyH("LEFT")
				end
			end
		end

		overrideToggle(conf.player.castBar.original)
	end
end

-- SetArcaneBar
local function SetArcaneBar(value, new)
	for k, v in pairs(ArcaneBars) do
		if (v.bar == new.bar) then
			ArcaneBars[k] = nil
		end
	end

	ArcaneBars[value] = new
end

-- MakePreCast
local function MakePreCast(self)
	local tex = ZPerl.GetBarTexture()
	self.precast = self:CreateTexture(nil, "ARTWORK")
	self.precast:SetTexture(tex)
	self.precast:SetPoint("RIGHT")
	self.precast:SetWidth(1)
	self.precast:Hide()
	self.precast:SetBlendMode("ADD")
	self.precast:SetGradient("HORIZONTAL", CreateColor(0, 0, 1, 1), CreateColor(1, 0, 0, 1))
end

-- ZPerl.ArcaneBar.RegisterFrame
function ZPerl.ArcaneBar.RegisterFrame(self, unit)
	local f = self.castBar
	if (not f) then
		f = CreateFrame("StatusBar", self:GetName().."CastBar", self, "ZPerl_ArcaneBarTemplate")
		self.castBar = f
	end

	if (unit == "player") then
		MakePreCast(f)
	end

	f.unit = unit
	f.showTradeSkills = true
	f.barParentName = self.text
	f:SetPoint("TOPLEFT", 4, -4)
	f:SetPoint("BOTTOMRIGHT", -4, 4)

	SetArcaneBar(unit, {bar = f, optFrame = self:GetParent()})

	ZPerl.ArcaneBar.Set()
end

-- ZPerl.ArcaneBar.SetUnit
function ZPerl.ArcaneBar.SetUnit(self, unit)
	if (self.castBar) then
		self.castBar.unit = unit
	end
end

ZPerl.RegisterOptionChanger(ZPerl.ArcaneBar.Set, nil, "arcanebar")
