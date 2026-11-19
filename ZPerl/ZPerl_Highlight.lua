-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local playerClass
local conf
ZPerl.RequestConfig(function(new)
	conf = new
end, "$Revision:  $")

-- Upvalues
local _G = _G

local bit = bit
local cos = cos
local format = format
local ipairs = ipairs
local min = min
local next = next
local pairs = pairs
local pcall = pcall
local random = random
local select = select
local sin = sin
local strfind = strfind
local tinsert = tinsert
local tremove = tremove
local type = type
local wipe = wipe

local C_Timer = C_Timer
local C_UnitAuras = C_UnitAuras
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local CreateFrame = CreateFrame
local GetTime = GetTime
local IsInRaid = IsInRaid
local SecureButton_GetUnit = SecureButton_GetUnit
local UnitClass = UnitClass
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGUID = UnitGUID
local UnitInParty = UnitInParty
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitPlayerOrPetInParty = UnitPlayerOrPetInParty
local UnitPlayerOrPetInRaid = UnitPlayerOrPetInRaid

local BackdropTemplateMixin = BackdropTemplateMixin

local GameTooltip = GameTooltip
local UIParent = UIParent

local hotSpells  = ZPERL_HIGHLIGHT_SPELLS.hotSpells
local pomSpells = ZPERL_HIGHLIGHT_SPELLS.pomSpells or {}
local shieldSpells = ZPERL_HIGHLIGHT_SPELLS.shieldSpells

-- secret value helpers from ZPerl.lua
local CanAccess = ZPerl.CanAccess
local UnitAuraByIndex = ZPerl.UnitAuraByIndex
local colors = {
	HOT = {r = 0.2, g = 0.4, b = 0.8, canFlash = true},
	POM = {r = 0.8, g = 0.6, b = 0.4},
	SHIELD = {r = 0.6, g = 0.1, b = 0.6, canFlash = true},
	AGGRO = {r = 0.8, g = 0, b = 0},
	SEL = {r = 0.86, g = 0.82, b = 0.41},
	TARGET = {r = 0.7167, g = 0.6833, b = 0.31467} -- Colored so that color * 1.2 == SEL color
}
-- status tooltip names the locale tables do not have: the client's own spell name
local statusNames = {POM = ZPerl.SpellName(33076)}

local xpHigh = ZPerl_Highlight or CreateFrame("Frame", "ZPerl_Highlight", nil, BackdropTemplateMixin and "BackdropTemplate")
-- the two colors of a two-highlight gradient, refilled per call (SetGradient copies the values)
local gradFrom, gradTo = CreateColor(0, 0, 0, 1), CreateColor(0, 0, 0, 1)
xpHigh.list = {}
xpHigh.callbacks = {}
xpHigh.flashers = {}
xpHigh.healBars = {}
xpHigh.mendingIcons = {}	-- the pool of hidden Prayer of Mending icons
xpHigh.shields = {}			-- [guid] = {{id, name, amount, maxAmount, expires, estimated}, ...}: your absorb shields

local playerGUID
local function myGUID()
	playerGUID = playerGUID or UnitGUID("player")
	return playerGUID
end

-- rotate
-- Positive angle is clockwise rotation
local function rotate(angle)
	local hcos = 0.5 * cos(angle)
	local mhcos = -hcos
	local hsin = 0.5 * sin(angle)
	local mhsin = -hsin
	local ULx, ULy, LLx, LLy = hcos - mhsin, mhsin + hcos, hcos - hsin, mhsin + mhcos
	local URx, URy, LRx, LRy = mhcos - mhsin, hsin + hcos, mhcos - hsin, hsin + mhcos
	return ULx + 0.5, ULy + 0.5, LLx + 0.5, LLy + 0.5, URx + 0.5, URy + 0.5, LRx + 0.5, LRy + 0.5
end

-- ZPerl_Highlight:Add
function xpHigh:Add(guid, highlightType, duration, source)
	if (not guid or not CanAccess(guid)) then
		return
	end
	if (not strfind(guid, "-")) then
		guid = self.lookup and self.lookup[guid]
		if (not guid) then
			-- not a GUID and no lookup entry: nil cannot be a table key
			return
		end
	end

	local a = self.list[guid]
	if (not a) then
		a = {}
		self.list[guid] = a
	end

	if (not duration) then
		a[highlightType] = nil
		self:Send(guid)
	else
		if (duration == 0) then
			a[highlightType] = 0
			self:Send(guid)
		else
			-- one Send per aura event, only while the HOTCOUNT option has registered UNIT_AURA; the callbacks redraw one frame
			if (highlightType == "HOTCOUNT") then
				a[highlightType] = duration
				self:Send(guid)
			else
				local newEndTime = GetTime() + duration
				local current = a[highlightType]
				-- a refresh extends it; the 0.1 s slack keeps the per-event re-reads of the same aura from redrawing
				if (not current or current < newEndTime - 0.1) then
					a[highlightType] = newEndTime
					-- an "about to expire" flash of this type belongs to the old end time
					if (self.flashers[guid] == highlightType) then
						self.flashers[guid] = nil
					end
					self:Send(guid)
				end
			end
		end
	end
end

-- xpHigh:TooltipInfo
function xpHigh:TooltipInfo(guid)
	if (not guid or not CanAccess(guid)) then
		return
	end
	local effects = self.list[guid]
	if (effects) then
		local str = ""
		local prefix = L["LOC_STATUSTIP"]
		for k,v in pairs(effects) do
			local desc = L["LOC_STATUSTIPLIST"][k] or statusNames[k]
			local c = colors[k]
			if (desc and c) then
				str = str..prefix..format("|c00%02X%02X%02X", 255 * c.r, 255 * c.g, 255 * c.b)..desc.."|r"
				prefix = ", "
			end
		end

		if (prefix == ", ") then
			GameTooltip:AddLine("\r"..str)
			GameTooltip:Show()
		end
	end
end

-- xpHigh:Remove
function xpHigh:Remove(guid, highlightType)
	if (not guid or not CanAccess(guid)) then
		return
	end
	if (not strfind(guid, "-")) then
		guid = self.lookup and self.lookup[guid]
	end

	local a = self.list[guid]
	if (a) then
		a[highlightType] = nil
		self:Send(guid)
	end
end

-- xpHigh:HasEffect
function xpHigh:HasEffect(guid, effect)
	if (not guid or not CanAccess(guid)) then
		return
	end
	if (not strfind(guid, "-")) then
		guid = self.lookup and self.lookup[guid]
	end

	local list = self.list[guid]
	if (list) then
		return list[effect]
	end
end

-- xpHigh:OnUpdate
-- The roster refresh, one video frame after the last GROUP_ROSTER_UPDATE
function xpHigh:RosterUpdate()
	if (self.rosterUpdate) then
		self.rosterUpdate = nil
		self:RefreshAllAuras() -- New roster, get all
	end
end

local function expireTick() xpHigh:Expire() end

-- The expiry check, every 0.2 s on the scheduler while HOT / SHIELD highlights are on
function xpHigh:Expire()
	-- We expire things 1 second early so people can cast in time for buff to expire
	local now = GetTime() --  + 1

	for guid, list in pairs(self.list) do
		local any
		for k, v in pairs(list) do
			any = true
			if (k ~= "HOTCOUNT") then
				if (v > 0) then
					if (v <= now) then
						self.flashers[guid] = nil
						list[k] = nil
						self:Send(guid)
					elseif (v <= now + 5 and colors[k] and colors[k].canFlash) then
						if (not self.flashers[guid]) then
							self.flashers[guid] = k
							self:Send(guid)
						end
					end
				end
			end
		end

		if (not any) then
			self.list[guid] = nil
			self.flashers[guid] = nil
		end
	end
end

-- xpHigh:Query
function xpHigh:SetHighlight(frame, guid)
	if (not frame.highlight) then
		ZPerl.Notice("No .highlight region for %s", tostring(frame:GetName()))
		return
	end
	self:ShowHealGlow(frame)

	local unitid
	if (not guid) then
		unitid = SecureButton_GetUnit(frame)
		if (unitid) then
			guid = UnitGUID(unitid)
		else
			return
		end
	end

	-- a secret GUID (creatures inside instances) has no entry
	if (guid and not CanAccess(guid)) then
		guid = nil
	end

	self:RosterUpdate()

	local hotCount, hotBar, pomActive, hotSparks
	if (guid and conf.highlight.enable) then
		---@diagnostic disable-next-line: secret-table-key
		local r = self.list[guid]
		if (r) then
			local r1, g1, b1, r2, g2, b2, t1
			for k, v in pairs(r) do
				if (k == "HOTCOUNT") then
					hotCount = v
				elseif (k == "HOT" and conf.highlight.sparkles) then
					hotBar = true
				elseif (k == "POM" and conf.highlight.sparkles) then
					pomActive = true
				elseif (k == "HOTSPARKS") then
					-- sparkles only, never a border color; independent of the Sparkles option
					hotSparks = conf.highlight.extraSparkles and true or nil
				elseif (not colors[k]) then
					-- a type without a color draws no border
				else
					if (not r1 or t1 == "TARGET") then
						if (not frame.hotHighlightOnly) then
							t1 = k
							r1, g1, b1 = colors[k].r, colors[k].g, colors[k].b
						end
					else
						r2, g2, b2 = colors[k].r, colors[k].g, colors[k].b
						break
					end
				end
			end

			if (r1) then
				frame.highlight.tex:Show()
				frame.highlight.tex:SetAlpha(1)

				if (frame.highlight.sel) then
					r1 = min(r1 * 1.2, 1)
					g1 = min(g1 * 1.2, 1)
					b1 = min(b1 * 1.2, 1)
				end

				if (r2) then
					if (frame.highlight.sel) then
						r2 = min(r2 * 1.2, 1)
						g2 = min(g2 * 1.2, 1)
						b2 = min(b2 * 1.2, 1)
					end
					gradFrom.r, gradFrom.g, gradFrom.b, gradTo.r, gradTo.g, gradTo.b = r1, g1, b1, r2, g2, b2
					frame.highlight.tex:SetGradient("HORIZONTAL", gradFrom, gradTo)
				else
					frame.highlight.tex:SetVertexColor(r1, g1, b1)
				end

				---@diagnostic disable-next-line: secret-table-key
				if (self.flashers[guid]) then
					ZPerl.FrameFlash(frame.highlight.tex)
				else
					ZPerl.FrameFlashStop(frame.highlight.tex)
				end
				self:ShowExtras(frame, guid, hotCount, hotBar, pomActive, hotSparks)
				return
			end
		end
	end

	self:RemoveHighlight(frame)
	self:ShowExtras(frame, guid, hotCount, hotBar, pomActive, hotSparks)
end

-- the pieces drawn on top of the border color: HoT counter, HoT bar, Prayer of Mending icon, extra sparkles, shield bar
function xpHigh:ShowExtras(frame, guid, hotCount, hotBar, pomActive, hotSparks)
	self:ShowHotCount(frame, hotCount)
	self:ShowHotBar(frame, hotBar)
	self:ShowMending(frame, pomActive)
	self:ShowHotSparks(frame, hotSparks)
	---@diagnostic disable-next-line: secret-table-key
	self:ShowShieldBar(frame, guid and conf.highlight.enable and self.shields[guid])
end

-- fluctuateOnUpdate
local function fluctuateOnUpdate(self, elapsed)
	if (self.fluctuate) then
		if (self.fluctuate == "dim" or self.fluctuate == "notbright") then
			self.fluctuatingBrightness = self.fluctuatingBrightness - elapsed
			if (self.fluctuatingBrightness < 0.5) then
				if (self.fluctuate == "dim") then
					self.fluctuatingBrightness = 0.5
					self.fluctuate = "notdim"
				else
					self.fluctuatingBrightness = nil
					self.fluctuate = nil
				end
			end
		elseif (self.fluctuate == "notdim" or self.fluctuate == "bright") then
			self.fluctuatingBrightness = self.fluctuatingBrightness + elapsed
			if (self.fluctuatingBrightness >= 1) then
				if (self.fluctuate == "notdim") then
					self.fluctuatingBrightness = nil
					self.fluctuate = nil
				else
					self.fluctuatingBrightness = 1
					self.fluctuate = "notbright"
				end
			end
		end
	elseif (random(10) == 1) then
		self.fluctuate = random(3) == 2 and "dim" or "bright"
		self.fluctuatingBrightness = 1
	end

	return self.fluctuatingBrightness or 1
end

-- hotBarOnUpdate
local function hotBarOnUpdate(self, elapsed)
	local _, Max = self:GetMinMaxValues()
	local val = self:GetValue()
	if (self.movementMod) then
		val = val - elapsed
		if (val <= 0) then
			self:Hide()
			return
		end

		self:SetValue(val)
	end

	local sparkPosition = self:GetWidth() * (val / Max)
	self.spark:SetPoint("CENTER", self, "LEFT", sparkPosition, 0)

	self.angle = self.angle + elapsed
	if (self.angle > 360) then
		self.angle = self.angle - 360
	end

	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = rotate(self.angle)
	self.spark:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
	self.shine:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)

	local a
	if (val < 5) then
		if (self.alphaPulse == "in") then
			a = self.alpha + elapsed * 2
			if (a >= 1) then
				a = 1
				self.alphaPulse = "out"
			end
		else
			a = self.alpha - elapsed * 2
			if (a < 0.3) then
				a = 0.3
				self.alphaPulse = "in"
			end
		end
	else
		a = 1
		self.alphaPulse = "out"
	end

	self.spark:SetVertexColor(1, 1, 1, a * fluctuateOnUpdate(self.spark, elapsed))
	self.shine:SetVertexColor(1, 1, 1, a * fluctuateOnUpdate(self.shine, elapsed))
	self.alpha = a
end

-- CreateShine
function xpHigh:CreateShine(parent)
	local shine = parent:CreateTexture(nil, "OVERLAY")
	shine:SetTexture(166928)
	shine:SetBlendMode("ADD")
	shine:SetWidth(12)
	shine:SetHeight(12)
	return shine
end

-- CreateHotBar
function xpHigh:CreateHotBar(frame)
	local parent = frame.healthBar
	if (not parent) then
		parent = frame.statsFrame and frame.statsFrame.healthBar
	end
	if (not parent) then
		return
	end

	local f = CreateFrame("StatusBar", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
	frame.highlight.hotBar = f
	f:SetPoint("TOPLEFT")
	f:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 0, -4)
	f:SetMinMaxValues(0, 0.1)
	f:Hide()
	f.movementMod = 1

	f.spark = self:CreateShine(f)
	f.shine = self:CreateShine(f)
	f.shine:SetPoint("CENTER", f, "LEFT")

	f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f:GetStatusBarTexture():SetHorizTile(false)
	f:GetStatusBarTexture():SetVertTile(false)
	f:SetStatusBarColor(1, 1, 0)

	f:SetScript("OnUpdate", hotBarOnUpdate)
	f:SetScript("OnShow", function(bar)
		bar.angle = 0
		bar.alpha = 1
		bar.alphaPulse = "out"
	end)
end

-- GetMyHotTime
-- aura names and times are secret in restricted content, so a
-- HOT that cannot be read simply does not count. Blizzard blocks this on purpose.
function xpHigh:GetMyHotTime(unit)
	local maxDur, maxTimeLeft = 0, 0
	for i = 1, 40 do
		local name, duration, expirationTime
		local _
		name, _, _, _, duration, expirationTime = UnitAuraByIndex(unit, i, "HELPFUL|PLAYER")
		if (not name) then
			break
		end

		if (CanAccess(name) and hotSpells[name] and CanAccess(expirationTime) and CanAccess(duration)) then
			local timeLeft = expirationTime - GetTime()
			if (timeLeft > maxTimeLeft) then
				maxDur, maxTimeLeft = duration, timeLeft
			end
		end
	end
	return maxDur, maxTimeLeft
end

-- ShowHotBar
function xpHigh:ShowHotBar(frame, show)
	local h = frame.highlight
	if (show and conf.highlight.HOT and conf.highlight.sparkles) then
		local unit = SecureButton_GetUnit(frame)
		if (unit) then
			local dur, timeLeft = self:GetMyHotTime(unit)
			if (dur and dur > 0) then
				if (not h.hotBar) then
					self:CreateHotBar(frame)
				end

				local _, b = h.hotBar:GetMinMaxValues()
				if (b > dur) then
					-- Changing HOTs shouldn't make the bar jump with varying buff durations, just use the max so far.
					dur = b
				end

				h.hotBar.unit = unit
				h.hotBar:SetMinMaxValues(0, dur)
				h.hotBar:SetValue(timeLeft)
				h.hotBar:Show()
				return
			end
		end
	end

	if (h.hotBar) then
		h.hotBar:Hide()
		h.hotBar:SetMinMaxValues(0, 0.1)
	end
end

-- xpHigh:CreateHotCount(frame)
function xpHigh:CreateHotCount(frame)

	local f = frame.highlight:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
	frame.highlight.hot = f

	f:SetTextColor(0, 1, 0)
	f:Hide()

	local sf = _G[frame:GetName().."statsFrame"]
	if (sf) then
		if (strfind(frame:GetName(), "ZPerl_Raid_Grp")) then
			f:SetTextHeight(15)
			f:SetPoint("TOPLEFT", sf, "TOPLEFT", 3, -3)
		else
			f:SetPoint("TOPLEFT", sf, "TOPLEFT", 5, -8)
		end
	else
		if (strfind(frame:GetName(), "ZPerl_Raid_GrpPets")) then
			f:SetTextHeight(15)
			f:SetPoint("TOPLEFT", 3, -3)
		else
			f:SetPoint("CENTER", 0, 0)
		end
	end
end

-- xpHigh:HasMyHOT(unit)
function xpHigh:HasMyHOT(unit)
	for i = 1, 40 do
		local name
		name = UnitAuraByIndex(unit, i, "HELPFUL|PLAYER")
		if not name then
			break
		end
		if CanAccess(name) and hotSpells[name] then
			return true
		end
	end
end

-- ShowHotCount
function xpHigh:ShowHotCount(frame, hotCount, unitid)
	local h = frame.highlight
	if (conf.highlight.HOTCOUNT) then
		if (hotCount and hotCount > 0) then
			if (not h.hot) then
				self:CreateHotCount(frame)
			end

			h.hot:SetText(hotCount)
			h.hot:Show()

			local unit = SecureButton_GetUnit(frame)
			if (unit and self:HasMyHOT(unit)) then
				h.hot:SetTextColor(0, 1, 0)
			else
				h.hot:SetTextColor(0.8, 0, 0)
			end
			return
		end
	end

	if (h.hot) then
		h.hot:Hide()
	end
end

------------------------------------------------------------------------------------------------ animation driver
-- The jump star and the sparkle areas move every video frame, so they run on the highlight frame's OnUpdate, set
-- only while one of them is active.
local function animOnUpdate(self, elapsed)
	if (self.mendingAnimation) then
		self:MendingAnimationOnUpdate(elapsed)
	end
	if (self.sparkleAreas) then
		self:SparkleAreasOnUpdate(elapsed)
	end
	if (not self.mendingAnimation and not (self.sparkleAreas and next(self.sparkleAreas))) then
		self:SetScript("OnUpdate", nil)
	end
end
function xpHigh:Animate()
	---@diagnostic disable-next-line: undefined-field
	if (not self:GetScript("OnUpdate")) then
		---@diagnostic disable-next-line: undefined-field
		self:SetScript("OnUpdate", animOnUpdate)
	end
end

------------------------------------------------------------------------------------------------ shield bar
-- A thin bar along the bottom of the health bar: how much of your absorb shields on the unit is left
function xpHigh:CreateShieldBar(frame)
	local parent = frame.healthBar
	if (not parent) then
		parent = frame.statsFrame and frame.statsFrame.healthBar
	end
	if (not parent) then
		return
	end

	local f = CreateFrame("StatusBar", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
	frame.highlight.shieldBar = f
	f:SetPoint("BOTTOMLEFT")
	f:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, 4)
	f:SetMinMaxValues(0, 0.1)
	f:Hide()

	f.spark = self:CreateShine(f)
	f.shine = self:CreateShine(f)
	f.shine:SetPoint("CENTER", f, "LEFT")

	f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	f:GetStatusBarTexture():SetHorizTile(false)
	f:GetStatusBarTexture():SetVertTile(false)
	f:SetStatusBarColor(1, 0.4, 1)

	-- no movementMod: the value only changes when the absorb does
	f:SetScript("OnUpdate", hotBarOnUpdate)
	f:SetScript("OnShow", function(bar)
		bar.angle = 0
		bar.alpha = 1
		bar.alphaPulse = "out"
	end)
end

-- TotalShield: the amount left and the full amount of all your shields on the unit
function xpHigh:TotalShield(guid)
	---@diagnostic disable-next-line: secret-table-key
	local list = self.shields[guid]
	if (list) then
		local total, maxAmount = 0, 0
		for _, s in ipairs(list) do
			total = total + s.amount
			maxAmount = maxAmount + s.maxAmount
		end
		return total, maxAmount
	end
end

function xpHigh:ShowShieldBar(frame, show)
	local h = frame.highlight
	if (show and conf.highlight.SHIELD and conf.highlight.sparkles) then
		local unit = SecureButton_GetUnit(frame)
		local guid = unit and UnitGUID(unit)
		if (guid and CanAccess(guid)) then
			local cur, max = self:TotalShield(guid)
			if (cur and max and max > 0) then
				if (not h.shieldBar) then
					self:CreateShieldBar(frame)
				end
				if (h.shieldBar) then
					h.shieldBar:SetMinMaxValues(0, max)
					h.shieldBar:SetValue(cur)
					h.shieldBar:Show()
					return
				end
			end
		end
	end

	if (h.shieldBar) then
		h.shieldBar:Hide()
		h.shieldBar:SetMinMaxValues(0, 0.1)
	end
end

------------------------------------------------------------------------------------------------ Prayer of Mending
-- GetMyPomTime(unit): the seconds left on your Prayer of Mending (or the client's other jumping heal of pomSpells)
function xpHigh:GetMyPomTime(unit)
	for i = 1, 40 do
		local name, expirationTime
		local _
		name, _, _, _, _, expirationTime = UnitAuraByIndex(unit, i, "HELPFUL|PLAYER")
		if (not name) then
			break
		end
		if (CanAccess(name) and pomSpells[name] and CanAccess(expirationTime)) then
			if (expirationTime == 0) then
				return pomSpells[name]
			end
			return expirationTime - GetTime()
		end
	end
end

-- the icon of the jumping heal the player's class has
local function pomIcon()
	local _, class = UnitClass("player")
	local id = (class == "MONK" and 115151) or (class == "PALADIN" and 157007) or 33076
	if (C_Spell and C_Spell.GetSpellTexture) then
		return C_Spell.GetSpellTexture(id)
	end
	return GetSpellTexture and GetSpellTexture(id)
end

-- mendingOnUpdate: the icon's turning shine; it pulses for the last 5 seconds
local function mendingOnUpdate(self, elapsed)
	if (self.shineMode == "in") then
		self.shineAlpha = self.shineAlpha + elapsed
		if (self.shineAlpha >= 1) then
			self.shineAlpha = 1
			self.shineMode = "out"
		end
	else
		self.shineAlpha = self.shineAlpha - elapsed
		if (self.shineAlpha <= 0.3) then
			self.shineAlpha = 0.3
			self.shineMode = "in"
		end
	end

	self.shineAngle = self.shineAngle + elapsed * 3
	if (self.shineAngle > 360) then
		self.shineAngle = self.shineAngle - 360
	end

	self.shine:SetTexCoord(rotate(self.shineAngle))
	self.shine:SetVertexColor(1, 1, 1, self.shineAlpha)

	if (GetTime() > self.endTime - 5) then
		self:SetAlpha(self.shineAlpha)
	else
		self:SetAlpha(1)
	end
end

local function mendingOnShow(self)
	self.shineAngle = 0
	self.shineAlpha = 0
	self.shineMode = "in"
	self:SetAlpha(1)
end

-- CreateMendingIcon: the spell's icon centred on the top edge of the health bar
function xpHigh:CreateMendingIcon(frame)
	local h = frame.highlight
	local p = frame.statsFrame
	local sizeMod, yOffset = -8, 0
	if (p) then
		p = p.healthBar or p
		local name = frame:GetName()
		if (name and strfind(name, "^ZPerl_Raid")) then
			sizeMod, yOffset = 0, -2
		else
			sizeMod, yOffset = 10, -4
		end
	end
	if (not h or not p) then
		return
	end

	local icon = h.mending or tremove(self.mendingIcons, 1)
	h.mending = icon
	if (icon) then
		icon:SetParent(p)
		icon:ClearAllPoints()
	else
		icon = CreateFrame("Frame", nil, p, BackdropTemplateMixin and "BackdropTemplate")
		h.mending = icon
		icon.tex = icon:CreateTexture(nil, "BACKGROUND")
		icon.tex:SetAllPoints()
		icon.tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		icon.shine = self:CreateShine(icon)
		icon.shine:SetPoint("TOPLEFT", -5, 5)
		icon.shine:SetPoint("BOTTOMRIGHT", 5, -5)
		icon:SetScript("OnUpdate", mendingOnUpdate)
		icon:SetScript("OnShow", mendingOnShow)
	end
	icon.tex:SetTexture(pomIcon())

	local size = p:GetHeight() + sizeMod
	icon:SetSize(size, size)
	icon:SetPoint("CENTER", p, "TOP", 0, yOffset)
	icon:Hide()

	-- where the icon sits on the frame: the jump star starts and lands there
	local x1, y1 = icon:GetCenter()
	local x2, y2 = frame:GetCenter()
	if (x1 and x2 and y1 and y2) then
		frame.lastPomPosX = x1 - x2
		frame.lastPomPosY = y1 - y2
	end

	icon.shine:Show()
	icon.shine:SetVertexColor(1, 1, 1, 0)
end

function xpHigh:ShowMending(frame, show)
	local h = frame.highlight
	if (show and conf.highlight.POM and conf.highlight.sparkles) then
		if (not h.mending or not h.mending:GetParent():IsShown()) then
			self:CreateMendingIcon(frame)
		end
		if (h.mending) then
			local unit = SecureButton_GetUnit(frame)
			if (unit) then
				h.mending.endTime = GetTime() + (self:GetMyPomTime(unit) or 30)
				h.mending:Show()
			end
		end
		return
	end

	if (h.mending) then
		h.mending:Hide()
		tinsert(self.mendingIcons, h.mending)
		h.mending = nil
	end
end

-- the unit frame of a GUID, for the jump star: the raid frames in a raid, else the party frames and the player frame
local function frameOfGUID(guid)
	if (not guid) then
		return
	end
	local f
	if (IsInRaid() and ZPerl.Raid and ZPerl.Raid.GetUnitFrameByGUID) then
		f = ZPerl.Raid.GetUnitFrameByGUID(guid)
	end
	if (not f and ZPerl.Party and ZPerl.Party.GetUnitFrameByGUID) then
		f = ZPerl.Party.GetUnitFrameByGUID(guid)
	end
	if (not f and guid == myGUID()) then
		f = _G.ZPerl_Player
	end
	if (f and f:IsVisible()) then
		return f
	end
end

-- TriggerMendingAnimation: a star flies from the frame the heal left to the frame it jumped to
function xpHigh:TriggerMendingAnimation(sourceGUID, targetGUID)
	if (not (conf.highlight.sparkles and conf.highlight.POM)) then
		return
	end
	local sourceFrame, targetFrame = frameOfGUID(sourceGUID), frameOfGUID(targetGUID)
	if (sourceFrame and targetFrame and sourceFrame ~= targetFrame) then
		self:StartMendingAnimation(sourceFrame, targetFrame)
	end
end

function xpHigh:StartMendingAnimation(sourceFrame, targetFrame)
	local oldMA = self.mendingAnimation
	local ma = {}
	self.mendingAnimation = ma

	local sx, sy = sourceFrame:GetCenter()
	local tx, ty = targetFrame:GetCenter()
	local ss, ts = sourceFrame:GetEffectiveScale(), targetFrame:GetEffectiveScale()

	if (oldMA) then
		-- a jump during a jump: the new star starts where the old one is
		ma.sourceX = oldMA.currentX
		ma.sourceY = oldMA.currentY
	else
		ma.sourceX = (sx + (sourceFrame.lastPomPosX or 0)) * ss
		ma.sourceY = (sy + (sourceFrame.lastPomPosY or 0)) * ss
	end

	ma.targetX = (tx + (targetFrame.lastPomPosX or 0)) * ts
	ma.targetY = (ty + (targetFrame.lastPomPosY or 0)) * ts
	ma.currentX = ma.sourceX
	ma.currentY = ma.sourceY

	-- the star takes 0.667 seconds to arrive
	ma.speedX = (ma.targetX - ma.sourceX) * 1.5
	ma.speedY = (ma.targetY - ma.sourceY) * 1.5

	ma.shown = 0
	ma.showGap = 1
	local icons = self.mendingAnimationIcons
	if (not icons) then
		icons = {}
		self.mendingAnimationIcons = icons
		for i = 1, 3 do
			local icon = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
			icons[i] = icon
			icon:SetFrameStrata("DIALOG")
			icon:SetSize((4 - i) * 8, (4 - i) * 8)
			icon:Hide()

			icon.tex = icon:CreateTexture(nil, "OVERLAY")
			icon.tex:SetTexture(166928)
			icon.tex:SetAllPoints()
			icon.tex:SetVertexColor(1 / i, 1 / i, 0.7 / i)
			icon.tex:SetBlendMode("ADD")
			icon.angle = 0
		end
	else
		for i = 1, 3 do
			icons[i]:Hide()
		end
	end
	self:Animate()
end

function xpHigh:MendingAnimationOnUpdate(elapsed)
	local ma = self.mendingAnimation
	local icons = self.mendingAnimationIcons

	ma.currentX = ma.currentX + ma.speedX * elapsed
	ma.currentY = ma.currentY + ma.speedY * elapsed

	if ((ma.speedX < 0 and ma.currentX < ma.targetX) or (ma.speedX > 0 and ma.currentX > ma.targetX)) then
		ma.currentX = ma.targetX
		ma.speedX = 0
	end
	if ((ma.speedY < 0 and ma.currentY < ma.targetY) or (ma.speedY > 0 and ma.currentY > ma.targetY)) then
		ma.currentY = ma.targetY
		ma.speedY = 0
	end
	if (ma.speedX == 0 and ma.speedY == 0 and not ma.endCounter) then
		ma.endCounter = 0
	end

	-- the three stars of the trail appear 0.2 s apart
	if (ma.shown < 3) then
		ma.showGap = ma.showGap + elapsed
		if (ma.showGap > 0.2) then
			ma.showGap = 0
			ma.shown = ma.shown + 1
			icons[ma.shown]:Show()
		end
	end

	local scale = UIParent:GetEffectiveScale() -- the positions are screen pixels
	for i = 1, ma.shown do
		local icon = icons[i]
		icon:ClearAllPoints()
		if (i == 1) then
			icon:SetPoint("CENTER", UIParent, "BOTTOMLEFT", ma.currentX / scale, ma.currentY / scale)
		else
			icon:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (ma.currentX - (ma.speedX * elapsed * i)) / scale, (ma.currentY - (ma.speedY * elapsed * i)) / scale)
		end

		icon.angle = icon.angle + elapsed * 3
		if (icon.angle > 360) then
			icon.angle = icon.angle - 360
		end
		icon.tex:SetTexCoord(rotate(icon.angle))
	end

	if (ma.endCounter) then
		ma.endCounter = ma.endCounter + 1
		if (ma.endCounter >= 5) then
			self:StopMendingAnimation()
		end
	end
end

function xpHigh:StopMendingAnimation()
	self.mendingAnimation = nil
	local icons = self.mendingAnimationIcons
	if (icons) then
		for i = 1, 3 do
			icons[i]:Hide()
		end
	end
end

-- PomAuraChanged(unit, guid): called from UNIT_AURA. The heal leaves one unit and lands on another: the two auras
-- change in either order, so whichever comes second starts the star from the unit that lost it to the one that
-- got it.
function xpHigh:PomAuraChanged(unit, guid)
	local timeLeft = self:GetMyPomTime(unit)
	local had = self:HasEffect(guid, "POM")
	local now = GetTime()
	if (timeLeft and timeLeft > 0) then
		self:Add(guid, "POM", timeLeft)
		if (not had) then
			if (self.pomLeft and self.pomLeft ~= guid and now - self.pomLeftTime < 2) then
				self:TriggerMendingAnimation(self.pomLeft, guid)
				self.pomLeft = nil
			else
				self.pomGot, self.pomGotTime = guid, now
			end
		end
	elseif (had) then
		self:Remove(guid, "POM")
		if (self.pomGot and self.pomGot ~= guid and now - self.pomGotTime < 1) then
			self:TriggerMendingAnimation(guid, self.pomGot)
			self.pomGot = nil
		else
			self.pomLeft, self.pomLeftTime = guid, now
		end
	end
end

------------------------------------------------------------------------------------------------ extra sparkles
-- SparkleArea(region, duration, mode, ttl): sparks rise out of the region for `duration` seconds
function xpHigh:SparkleArea(region, duration, mode, ttl)
	if (not region:GetLeft()) then
		return
	end
	local s = region:GetEffectiveScale()
	local area = {
		left = region:GetLeft() * s,
		right = region:GetRight() * s,
		top = region:GetTop() * s,
		bottom = region:GetBottom() * s,
	}
	area.key = format("%d-%d-%d-%d", area.left, area.right, area.top, area.bottom)
	self.sparkleAreas = self.sparkleAreas or {}
	if (self.sparkleAreas[area.key]) then
		return -- the same area is sparkling already
	end
	area.endTime = GetTime() + duration
	area.mode = mode or "evaporate"
	area.ttl = ttl or 0.5
	area.color = {r = 1, g = 1, b = 0.5}
	area.fadeInMultiplier = 6
	area.fadeOutMultiplier = 1
	area.rotateMultiplier = 1
	area.sparks = {}
	area.sparkTime = 0
	self.sparkleAreas[area.key] = area
	self:Animate()
end

local function sparkOnShow(self)
	self.angle = 0
	self.alpha = 0
	self.begin = GetTime()
	self.state = "new"
end

local function sparkOnUpdate(self, elapsed)
	local area = self.area
	if (not area) then
		self:Hide()
		return
	end
	self.angle = self.angle + elapsed * area.rotateMultiplier
	if (self.angle > 360) then
		self.angle = self.angle - 360
	end
	self.tex:SetTexCoord(rotate(self.angle))

	if (self.mode == "evaporate") then
		-- the spark is a child of UIParent: its centre and offsets are in UIParent's units; it rises `speed` screen
		-- pixels a second
		local x, y = self:GetCenter()
		if (x and y) then
			self:ClearAllPoints()
			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y + elapsed * self.speed / self:GetEffectiveScale())
		end
	end

	if (self.state == "new") then
		self.alpha = self.alpha + elapsed * area.fadeInMultiplier
		if (self.alpha >= 1) then
			self.alpha = 1
			self.state = (GetTime() > self.begin + self.ttl) and "fade" or "cycle"
		end
	elseif (self.state == "cycle") then
		if (GetTime() > self.begin + self.ttl) then
			self.state = "fade"
		end
	elseif (self.state == "fade") then
		self.alpha = self.alpha - elapsed * area.fadeOutMultiplier
		if (self.alpha <= 0) then
			self:Hide()
			xpHigh:SparkleAreaRemoveSpark(self)
			return
		end
	end

	local c = area.color
	self.tex:SetVertexColor(c.r, c.g, c.b, self.alpha * fluctuateOnUpdate(self, elapsed))
end

function xpHigh:SparkleAreaRemoveSpark(spark)
	local area = spark.area
	spark.area = nil
	self.activeSparks[spark.id] = nil
	tinsert(self.inactiveSparks, spark)
	if (area and area.sparks) then
		area.sparks[spark.id] = nil
	end
end

-- SparkleAreaAddSpark(area, bias): one spark from the pool, in the left, middle or right third of the area
function xpHigh:SparkleAreaAddSpark(area, bias)
	self.inactiveSparks = self.inactiveSparks or {}
	self.activeSparks = self.activeSparks or {}
	local spark = tremove(self.inactiveSparks, 1)
	if (not spark) then
		spark = CreateFrame("Frame", nil, UIParent)
		spark:SetFrameStrata("DIALOG")
		spark.tex = self:CreateShine(spark)
		spark.tex:SetAllPoints()
		spark:SetScript("OnShow", sparkOnShow)
		spark:SetScript("OnUpdate", sparkOnUpdate)
		spark:Hide()
		self.sparkIncrement = (self.sparkIncrement or 0) + 1
		spark.id = self.sparkIncrement
	end
	self.activeSparks[spark.id] = spark

	spark.mode = area.mode
	spark.ttl = area.ttl
	spark.area = area

	local size = 8 + random(6)
	spark:SetSize(size, size)
	spark.speed = size

	-- area is in screen pixels; the spark is placed in UIParent's coordinates
	local w = math.max(1, math.floor(area.right - area.left))
	local x
	if (bias == "left") then
		x = area.left + random(w) / 3
	elseif (bias == "right") then
		x = area.right - random(w) / 3
	elseif (bias == "middle") then
		x = area.left + (w / 3) + (random(w) / 3)
	else
		x = area.left + random(w)
	end
	local hgt = math.max(1, math.floor(area.top - area.bottom))
	local y = area.bottom + random(hgt) / (area.mode == "evaporate" and 2 or 1)
	local s = UIParent:GetEffectiveScale()
	spark:ClearAllPoints()
	spark:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)

	area.sparks[spark.id] = true
	spark:Show()
	return spark
end

function xpHigh:SparkleAreaOnUpdate(area, elapsed)
	if (GetTime() < area.endTime) then
		area.sparkTime = area.sparkTime + elapsed
		if (area.sparkTime > 0.1) then
			area.sparkTime = 0
			self:SparkleAreaAddSpark(area, "left")
			self:SparkleAreaAddSpark(area, "middle")
			self:SparkleAreaAddSpark(area, "right")
		end
	elseif (not next(area.sparks)) then
		self.sparkleAreas[area.key] = nil
	end
end

function xpHigh:SparkleAreasOnUpdate(elapsed)
	for _, area in pairs(self.sparkleAreas) do
		self:SparkleAreaOnUpdate(area, elapsed)
	end
end

-- ShowHotSparks: a short burst of sparks rising from the frame's health bar
function xpHigh:ShowHotSparks(frame, show)
	if (show and frame:IsVisible()) then
		local h = frame.healthBar or (frame.statsFrame and frame.statsFrame.healthBar)
		if (h) then
			self:SparkleArea(h, 0.4, "evaporate", 0.1)
		end
	end
end

-- xpHigh:RemoveHighlight
function xpHigh:RemoveHighlight(frame)
	ZPerl.FrameFlashStop(frame.highlight.tex)

	frame.highlight.tex:SetVertexColor(0.86, 0.82, 0.41)	-- Default selection color

	if (frame.highlight.sel and conf.highlightSelection) then
		frame.highlight.tex:Show()
		frame.highlight.tex:SetAlpha(1)
	else
		frame.highlight.tex:Hide()
	end
end

-- xpHigh:ClearAll
function xpHigh:ClearAll(clearType)
	if (clearType == "SHIELD") then
		for guid in pairs(self.shields) do
			self.shields[guid] = nil
			self:Send(guid)
		end
	elseif (clearType == "POM") then
		self.pomGot, self.pomLeft = nil, nil
		self:StopMendingAnimation()
	end
	for k, v in pairs(self.list) do
		if (v[clearType]) then
			v[clearType] = nil
			self:Send(k)
		end
	end
end

-- xpHigh:Send
function xpHigh:Send(guid)
	for k, v in pairs(self.callbacks) do
		v[1](v[2], guid)
	end
end

-- ZPerl_RegisterFrameHighlighter
function xpHigh:Register(callback, slf)
	tinsert(self.callbacks, {callback, slf})
end

-- Bus listeners (ZPerl.On) for the events OptionChange turns on and off.
local busFn = {
	UNIT_HEAL_PREDICTION = function(_, unit) xpHigh:UNIT_HEAL_PREDICTION(unit) end,
	UNIT_AURA = function(_, unit) xpHigh:UNIT_AURA(unit) end,
	GROUP_ROSTER_UPDATE = function() xpHigh:GROUP_ROSTER_UPDATE() end,
	-- the bus never registers it where the client withholds it (retail)
	COMBAT_LOG_EVENT_UNFILTERED = function()
		if (CombatLogGetCurrentEventInfo) then
			xpHigh:CombatLogEvent(CombatLogGetCurrentEventInfo())
		end
	end,
}
local busOn = {}
local function listen(event, on)
	if (on == (busOn[event] or false)) then
		return
	end
	busOn[event] = on
	if (on) then
		ZPerl.On(event, busFn[event])
	else
		ZPerl.Off(event, busFn[event])
	end
end

-- LibHealComm-4.0 (Classic Era only; the library does not load elsewhere): the incoming heals come from the heals
-- the group's healers announce, as the client has none of its own there.
local HealComm = LibStub and LibStub("LibHealComm-4.0", true)

-- IncomingHeals(unit): LibHealComm's direct heals landing in the next 3 seconds, else the client's own value
local function IncomingHeals(unit)
	if (HealComm) then
		local guid = UnitGUID(unit)
		return guid and HealComm:GetHealAmount(guid, HealComm.CASTED_HEALS, GetTime() + 3) or 0
	end
	if (type(UnitGetIncomingHeals) == "function") then
		return UnitGetIncomingHeals(unit)
	end
	return 0
end

-- The incoming heal glow. The heal amount is secret, so no code branches on it: a StatusBar of range 0 to 1 takes it
-- through SetValue (accepts secrets), and the client fills the bar fully for any amount of 1 or more and not at all
-- for 0. The bar's texture is the highlight texture, so the glow looks like the other highlights.
local function setHealBar(bar)
	local unit = SecureButton_GetUnit(bar.owner)
	if (unit and not UnitIsDeadOrGhost(unit)) then
		-- no truth test on the secret (`x or 0`): whether the client allows one is unverified
		local amount = IncomingHeals(unit)
		if (ZPerl.IsSecret(amount)) then
			bar:SetValue(amount)
		else
			bar:SetValue(amount or 0)
		end
	else
		bar:SetValue(0)
	end
end

function xpHigh:ShowHealGlow(frame)
	local h = frame.highlight
	local bar = h.healBar
	if (not (conf.highlight and conf.highlight.enable and conf.highlight.HEAL)) then
		if (bar) then
			bar:Hide()
		end
		return
	end
	if (not bar) then
		bar = CreateFrame("StatusBar", nil, h)
		bar:SetAllPoints()
		bar:SetMinMaxValues(0, 1)
		bar:SetStatusBarTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_Highlight")
		bar:GetStatusBarTexture():SetBlendMode("ADD")
		bar:SetStatusBarColor(0.2, 0.8, 0.2)
		bar.owner = frame
		h.healBar = bar
		self.healBars[bar] = true
	end
	bar:GetStatusBarTexture():SetTexCoord(h.tex:GetTexCoord())
	bar:Show()
	setHealBar(bar)
end

-- UNIT_HEAL_PREDICTION
function xpHigh:UNIT_HEAL_PREDICTION(unit)
	for bar in pairs(self.healBars) do
		if (SecureButton_GetUnit(bar.owner) == unit) then
			setHealBar(bar)
		end
	end
end

-- LibHealComm callbacks name GUIDs (the caster's and the targets'): every glow on a unit with one of them is redrawn
local healCommGUIDs = {}
local function HealCommUpdate(_, ...)
	wipe(healCommGUIDs)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if (type(v) == "string") then
			healCommGUIDs[v] = true
		end
	end
	for bar in pairs(xpHigh.healBars) do
		local unit = SecureButton_GetUnit(bar.owner)
		local guid = unit and UnitGUID(unit)
		---@diagnostic disable-next-line: secret-table-key
		if (guid and CanAccess(guid) and healCommGUIDs[guid]) then
			setHealBar(bar)
		end
	end
end
local HEALCOMM_CALLBACKS = {"HealComm_HealStarted", "HealComm_HealStopped", "HealComm_HealDelayed",
	"HealComm_HealUpdated", "HealComm_GUIDDisappeared"}
local healCommOn = false
local function listenHealComm(on)
	if (not HealComm or on == healCommOn) then
		return
	end
	healCommOn = on
	for _, callback in ipairs(HEALCOMM_CALLBACKS) do
		if (on) then
			HealComm.RegisterCallback(xpHigh, callback, HealCommUpdate)
		else
			HealComm.UnregisterCallback(xpHigh, callback)
		end
	end
end

-- xpHigh:HasMyShield(unit)
function xpHigh:HasMyShield(unit)
	for i = 1, 40 do
		local name, expirationTime
		local _
		name, _, _, _, _, expirationTime = UnitAuraByIndex(unit, i, "HELPFUL|PLAYER")
		if not name then
			break
		end
		if (CanAccess(name) and shieldSpells[name] and CanAccess(expirationTime)) then
			return expirationTime - GetTime()
		end
	end
end

------------------------------------------------------------------------------------------------ shield amounts
-- The shield bar shows how much of your absorb shields on a unit is left. Retail and Mists report the absorb left as
-- the aura's first value (points[1]). Classic Era and TBC do not: there the amount is estimated as of old, the
-- rank's base absorb (no spell power) with Improved Power Word: Shield, less the damage the combat log says was
-- absorbed on the unit.
local ESTIMATE = not (ZPerl.IsRetail or ZPerl.IsMists)
local absorbNames = {[ZPerl.SpellName(11426)] = true} -- Ice Barrier, besides shieldSpells
-- base absorb per rank (spell ID)
local absorbRanks = {
	-- Power Word: Shield
	[17] = 44, [592] = 88, [600] = 158, [3747] = 234, [6065] = 301, [6066] = 381,
	[10898] = 484, [10899] = 605, [10900] = 763, [10901] = 942, [25217] = 1144, [25218] = 1265,
	-- Ice Barrier
	[11426] = 438, [13031] = 549, [13032] = 678, [13033] = 818, [27134] = 925, [33405] = 1075,
}
local PWS = ZPerl.SpellName(17)
local IMPROVED_PWS = ZPerl.SpellName(14748) -- 5% more absorb per rank

local function talentRank(findName)
	if (not GetNumTalentTabs or not GetTalentInfo) then
		return 0
	end
	for tab = 1, GetNumTalentTabs() do
		for i = 1, GetNumTalents(tab) do
			---@diagnostic disable-next-line: missing-parameter
			local name, _, _, _, rank = GetTalentInfo(tab, i)
			if (name == findName) then
				return rank or 0
			end
		end
	end
	return 0
end

local function estimateAbsorb(spellId, name)
	local base = spellId and absorbRanks[spellId]
	if (not base) then
		return
	end
	if (name == PWS) then
		base = base * (1 + 0.05 * talentRank(IMPROVED_PWS))
	end
	return base
end

-- your auras on the unit as aura tables (nil while the client hides aura data)
local function myAuras(unit)
	if (ZPerl.AurasSecret()) then
		return
	end
	if (C_UnitAuras and C_UnitAuras.GetUnitAuras) then
		local ok, list = pcall(C_UnitAuras.GetUnitAuras, unit, "HELPFUL|PLAYER", 40)
		return ok and list or nil
	end
	local list = {}
	for i = 1, 40 do
		local a = ZPerl.AuraData and ZPerl.AuraData(unit, i, "HELPFUL|PLAYER")
		if (not a) then
			break
		end
		list[i] = a
	end
	return list
end

local function sameShields(a, b)
	if (not a or not b) then
		return a == b
	end
	if (#a ~= #b) then
		return false
	end
	for i = 1, #a do
		if (a[i].id ~= b[i].id or a[i].amount ~= b[i].amount or a[i].maxAmount ~= b[i].maxAmount) then
			return false
		end
	end
	return true
end

-- UpdateShields(unit, guid): re-reads your shields on the unit, from UNIT_AURA
function xpHigh:UpdateShields(unit, guid)
	if (not (conf.highlight.SHIELD and conf.highlight.sparkles)) then
		return
	end
	local auras = myAuras(unit)
	if (not auras) then
		return -- aura data hidden: keep what is known
	end
	---@diagnostic disable-next-line: secret-table-key
	local old = self.shields[guid]
	local new
	for _, a in ipairs(auras) do
		local name = a.name
		---@diagnostic disable-next-line: secret-table-key
		if (CanAccess(name) and (shieldSpells[name] or absorbNames[name])) then
			local id, expires = a.spellId, a.expirationTime
			if (not CanAccess(expires)) then
				expires = nil
			end
			local prev
			if (old) then
				for _, s in ipairs(old) do
					if (s.id == id) then
						prev = s
						break
					end
				end
			end
			-- a recast moves the end time: the shield is a new one
			local same = prev and prev.expires and expires and math.abs(prev.expires - expires) < 0.5
			local p = a.points and a.points[1]
			local entry
			if (type(p) == "number" and CanAccess(p) and p > 0) then
				local max = (same and not prev.estimated) and prev.maxAmount or 0
				entry = {id = id, name = name, amount = p, maxAmount = (p > max) and p or max, expires = expires}
			-- an estimate needs the combat log to go down (not on Forever, which withholds it): without it no bar
			elseif (ESTIMATE and ZPerl.EventValid("COMBAT_LOG_EVENT_UNFILTERED")) then
				if (same and prev.estimated) then
					entry = prev -- its amount goes down with the absorbed damage
				else
					local base = estimateAbsorb(id, name)
					if (base) then
						entry = {id = id, name = name, amount = base, maxAmount = base, expires = expires, estimated = true}
					end
				end
			end
			if (entry) then
				new = new or {}
				new[#new + 1] = entry
			end
		end
	end
	if (not sameShields(old, new)) then
		---@diagnostic disable-next-line: secret-table-key
		self.shields[guid] = new
		self:Send(guid)
	end
end

-- Damage(guid, absorbed): takes absorbed damage (from the combat log) off the estimated shields, first one first
function xpHigh:Damage(guid, absorbed)
	if (type(absorbed) ~= "number" or absorbed <= 0) then
		return
	end
	local list = self.shields[guid]
	if (not list) then
		return
	end
	local changed
	local i = 1
	while (absorbed > 0 and list[i]) do
		local s = list[i]
		if (s.estimated) then
			changed = true
			if (absorbed >= s.amount) then
				absorbed = absorbed - s.amount
				tremove(list, i)
			else
				s.amount = s.amount - absorbed
				absorbed = 0
			end
		else
			i = i + 1
		end
	end
	if (changed) then
		if (not next(list)) then
			self.shields[guid] = nil
		end
		self:Send(guid)
	end
end

------------------------------------------------------------------------------------------------ combat log
-- Classic clients only: retail does not give addons the combat log (ZPerl.EventValid refuses it there). It drives
-- the extra sparkles (your heals and heal over time ticks) and the absorbed damage of the estimated shields.
local MINE_PARTY_RAID = (COMBATLOG_OBJECT_AFFILIATION_MINE or 0) + (COMBATLOG_OBJECT_AFFILIATION_PARTY or 0) + (COMBATLOG_OBJECT_AFFILIATION_RAID or 0)
local TARGET_FOCUS = (COMBATLOG_OBJECT_TARGET or 0) + (COMBATLOG_OBJECT_FOCUS or 0)
-- a unit of your group, your target or your focus
local function wanted(flags)
	return type(flags) == "number" and (bit.band(flags, MINE_PARTY_RAID) ~= 0 or bit.band(flags, TARGET_FOCUS) ~= 0)
end

function xpHigh:CombatLogEvent(_, event, _, srcGUID, _, _, _, dstGUID, _, dstFlags, _, p1, p2, p3, p4, p5, p6, p7, p8, p9)
	if (not wanted(dstFlags)) then
		return
	end
	local hl = conf.highlight
	if (event == "SPELL_HEAL") then
		if (hl.HEAL and hl.extraSparkles and srcGUID == myGUID()) then
			self:Add(dstGUID, "HOTSPARKS", 0.1)
		end
	elseif (event == "SPELL_PERIODIC_HEAL") then
		if (hl.HOT and hl.extraSparkles and srcGUID == myGUID() and hotSpells[p2]) then
			self:Add(dstGUID, "HOTSPARKS", 0.1)
		end
	elseif (next(self.shields)) then
		-- absorbed damage: the field differs per event
		if (event == "SPELL_DAMAGE" or event == "SPELL_PERIODIC_DAMAGE" or event == "RANGE_DAMAGE") then
			self:Damage(dstGUID, p9)
		elseif (event == "SWING_DAMAGE") then
			self:Damage(dstGUID, p6)
		elseif (event == "ENVIRONMENTAL_DAMAGE") then
			self:Damage(dstGUID, p7)
		elseif (event == "SPELL_MISSED" or event == "SPELL_PERIODIC_MISSED" or event == "RANGE_MISSED") then
			if (p4 == "ABSORB") then
				self:Damage(dstGUID, p6)
			end
		elseif (event == "SWING_MISSED") then
			if (p1 == "ABSORB") then
				self:Damage(dstGUID, p3)
			end
		end
	end
end

-- RemoveAllFromGUID
function xpHigh:RemoveAllFromGUID(unit)
	local guid = UnitGUID(unit)
	if (not guid or not CanAccess(guid)) then
		return
	end
	---@diagnostic disable-next-line: secret-table-key
	if self.list[guid] or self.shields[guid] then
		---@diagnostic disable-next-line: secret-table-key
		self.list[guid] = nil
		---@diagnostic disable-next-line: secret-table-key
		self.shields[guid] = nil
		self:Send(guid)
	end
end

-- xpHigh:UNIT_AURA
-- Scans the unit's auras per event (up to three 40-slot loops) because the client gives no list of
-- who cast an aura or when it expires without iterating; the event names the unit, not the change.
function xpHigh:UNIT_AURA(unit)
	if not UnitInParty(unit) and not UnitPlayerOrPetInRaid(unit) and not UnitPlayerOrPetInParty(unit) then
		return
	end

	local guid = UnitGUID(unit)
	if (not CanAccess(guid)) then
		return
	end
	if UnitIsDeadOrGhost(unit) then
		self:RemoveAllFromGUID(unit)
		return
	end

	-- our own HOTs and shields are found from the unit's auras
	if (conf.highlight.HOT) then
		local _, timeLeft = self:GetMyHotTime(unit)
		if (timeLeft > 0) then
			-- Add extends an existing one, so a recast HoT moves its end time
			self:Add(guid, "HOT", timeLeft)
		else
			self:Remove(guid, "HOT")
		end
	end
	if (conf.highlight.SHIELD) then
		local timeLeft = self:HasMyShield(unit)
		if (timeLeft and timeLeft > 0) then
			self:Add(guid, "SHIELD", timeLeft)
		else
			self:Remove(guid, "SHIELD")
		end
	end

	-- Check for pre-mature end of shield buff (Power Word: Shield, Earth Shield)
	if playerClass == "SHAMAN" then	-- or playerClass == "PRIEST") then
		if self:HasEffect(guid, "SHIELD") then
			if not self:HasMyShield(unit) then
				self:Remove(guid, "SHIELD")
			end
		end
	end
	self:UpdateShields(unit, guid)

	-- your Prayer of Mending (and the client's other jumping heals): where it is, and the star when it jumps
	if (conf.highlight.POM and next(pomSpells)) then
		self:PomAuraChanged(unit, guid)
	end

	if conf.highlight.HOTCOUNT then
		local hotCount = 0
		for i = 1, 40 do
			local name
			name = UnitAuraByIndex(unit, i, "HELPFUL")
			if not name then
				break
			end
			if CanAccess(name) and hotSpells[name] then
				hotCount = hotCount + 1
			end
		end

		if hotCount == 0 then
			self:Remove(guid, "HOTCOUNT")
		else
			self:Add(guid, "HOTCOUNT", hotCount)
		end
	end
end

-- xpHigh:GROUP_ROSTER_UPDATE
local function rosterUpdateNow()
	xpHigh:RosterUpdate()
end

function xpHigh:GROUP_ROSTER_UPDATE()
	if (not self.rosterUpdate) then
		self.rosterUpdate = true
		C_Timer.After(0, rosterUpdateNow)
	end
end

xpHigh.GROUP_ROSTER_UPDATE = xpHigh.GROUP_ROSTER_UPDATE

-- xpHigh:RefreshAllAuras
function xpHigh:RefreshAllAuras()
	self.pomGot, self.pomLeft = nil, nil
	for unitid in ZPerl.NextMember do
		self:UNIT_AURA(unitid)
	end
end

-- xpHigh:OptionChange
function xpHigh:OptionChange()

	local _
	_, playerClass = UnitClass("player")

	if (not conf.highlight.enable or not conf.highlight.HOT) then
		self:ClearAll("HOT")
	end
	if (not conf.highlight.enable or not conf.highlight.SHIELD) then
		self:ClearAll("SHIELD")
	elseif (not conf.highlight.sparkles and next(self.shields)) then
		-- the shield bar is a sparkles piece: drop the amounts, keep the SHIELD highlights
		for guid in pairs(self.shields) do
			self.shields[guid] = nil
			self:Send(guid)
		end
	end
	local pom = conf.highlight.enable and conf.highlight.POM and next(pomSpells) ~= nil
	if (not pom) then
		self:ClearAll("POM")
	end
	if (not conf.highlight.enable or not conf.highlight.extraSparkles) then
		self:ClearAll("HOTSPARKS")
	end

	-- the combat log: the extra sparkles (independent of Sparkles), and the absorbed damage of the estimated shields
	local hl = conf.highlight
	listen("COMBAT_LOG_EVENT_UNFILTERED", (hl.enable and ((hl.extraSparkles and (hl.HEAL or hl.HOT)) or (ESTIMATE and hl.SHIELD and hl.sparkles))) and true or false)

	if HealComm or type(UnitGetIncomingHeals) == "function" then
		local heal = (conf.highlight.enable and conf.highlight.HEAL) and true or false
		if HealComm then
			listenHealComm(heal)
		else
			listen("UNIT_HEAL_PREDICTION", heal)
		end
		ZPerl.SetHighlights()
	end

	if (conf.highlight.enable and (conf.highlight.HOTCOUNT or conf.highlight.HOT or conf.highlight.SHIELD or pom)) then
		listen("UNIT_AURA", true)
		listen("GROUP_ROSTER_UPDATE", true)
		self:RefreshAllAuras()
	else
		listen("UNIT_AURA", false)
		listen("GROUP_ROSTER_UPDATE", false)
		self:ClearAll("HOTCOUNT")
		self:ClearAll("HOT")
		self:ClearAll("SHIELD")
		self:ClearAll("POM")
	end

	if (not conf.highlight.AGGRO) then
		ZPerl_Highlight:ClearAll("AGGRO")
	end

	-- a highlight ends by the clock and no event fires at its end, so the expiry is polled, only while a timed type is on
	if (conf.highlight.enable and (conf.highlight.HOT or conf.highlight.SHIELD or pom or conf.highlight.extraSparkles)) then
		ZPerl.Every(0.2, expireTick)
	else
		ZPerl.Cancel(expireTick)
	end
end

ZPerl.RegisterOptionChanger(xpHigh.OptionChange, xpHigh, "highlight")
