-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

-- Fading bars, flashing, portraits, level and tooltip updates, the health prediction bars and the threat display.

local conf

ZPerl.RequestConfig(function(New)
	conf = New
end, "$Revision: 1 $")

-- Upvalues
local abs = abs
local cos = cos
local error = error
local ipairs = ipairs
local max = max
local min = min
local next = next
local pairs = pairs
local select = select
local sin = sin
local strmatch = strmatch
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local type = type
local wipe = wipe

local CreateFrame = CreateFrame
local CreateUnitHealPredictionCalculator = CreateUnitHealPredictionCalculator
local GetDifficultyColor = GetCreatureDifficultyColor or GetQuestDifficultyColor
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetRaidTargetIndex = GetRaidTargetIndex
local GetReadyCheckStatus = GetReadyCheckStatus
local GetRealZoneText = GetRealZoneText
local GetTime = GetTime
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local SetPortraitTexture = SetPortraitTexture
local SetPortraitToTexture = SetPortraitToTexture or function(texture, asset)
	-- Removed from newer clients; plain texture swap is equivalent here
	texture:SetTexture(asset)
	texture:SetTexCoord(0, 1, 0, 1)
end
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local UnitAffectingCombat = UnitAffectingCombat
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitExists = UnitExists
local UnitGetDetailedHealPrediction = UnitGetDetailedHealPrediction
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsVisible = UnitIsVisible
local UnitLevel = UnitLevel
local UnitName = UnitName

local BackdropTemplateMixin = BackdropTemplateMixin
local Enum = Enum
local READY_CHECK_NOT_READY_TEXTURE = READY_CHECK_NOT_READY_TEXTURE
local READY_CHECK_READY_TEXTURE = READY_CHECK_READY_TEXTURE
local READY_CHECK_WAITING_TEXTURE = READY_CHECK_WAITING_TEXTURE

local UIParent = UIParent

local CanAccess, IsSecret = ZPerl.CanAccess, ZPerl.IsSecret
local colorCurves = ZPerl.colorCurves

local function rotate(angle)
	local A = cos(angle)
	local B = sin(angle)
	local ULx, ULy = -0.5 * A - -0.5 * B, -0.5 * B + -0.5 * A
	local LLx, LLy = -0.5 * A - 0.5 * B, -0.5 * B + 0.5 * A
	local URx, URy = 0.5 * A - -0.5 * B, 0.5 * B + -0.5 * A
	local LRx, LRy = 0.5 * A - 0.5 * B, 0.5 * B + 0.5 * A
	return ULx + 0.5, ULy + 0.5, LLx + 0.5, LLy + 0.5, URx + 0.5, URy + 0.5, LRx + 0.5, LRy + 0.5
end

-- smoothColor
local function smoothColor(percentage)
	local r, g, b
	if (percentage < 0.5) then
		r = 1
		g = min(1, max(0, 2 * percentage))
		b = 0
	else
		g = 1
		r = min(1, max(0, 2 * (1 - percentage)))
		b = 0
	end

	return r, g, b
end

----------------------
-- Fading Bar Stuff --
----------------------
local fadeBars = {}
local freeFadeBars = {}
local tempDisableFadeBars

function ZPerl.NoFadeBars(tempDisable)
	tempDisableFadeBars = tempDisable
end

-- CheckOnUpdate
local function CheckOnUpdate()
	if next(fadeBars) then
		ZPerl_Globals:SetScript("OnUpdate", ZPerl.BarUpdate)
	else
		ZPerl_Globals:SetScript("OnUpdate", nil)
	end
end

-- ZPerl.BarUpdate
--local speakerTimer = 0
--local speakerCycle = 0
function ZPerl.BarUpdate(self, arg1)
	local did
	for k, v in pairs(fadeBars) do
		if k:IsShown() then
			v:SetAlpha(k.fadeAlpha)
			k.fadeAlpha = k.fadeAlpha - (arg1 / conf.bar.fadeTime)

			local r, g, b = v.tex:GetVertexColor()
			v:SetStatusBarColor(r, g, b)
		else
			-- Not shown, so end it
			k.fadeAlpha = 0
		end

		if k.fadeAlpha <= 0 then
			tinsert(freeFadeBars, v)
			fadeBars[k] = nil
			k.fadeAlpha = nil
			k.fadeBar = nil
			v:SetValue(0)
			v:Hide()
			v.tex = nil
			did = true
		end
	end

	if did then
		CheckOnUpdate()
	end
end

-- GetFreeFader
local function GetFreeFader(parent)
	local bar = freeFadeBars[1]
	if bar then
		tremove(freeFadeBars, 1)
		bar:SetParent(parent)
	else
		-- Creates only when the pool is empty: the pool grows to the most bars fading at once and is
		-- never freed, so a steady state creates nothing. Frames cannot be destroyed, so pooling is the bound.
		bar = CreateFrame("StatusBar", nil, parent)
	end

	if bar then
		fadeBars[parent] = bar
		CheckOnUpdate()

		bar.tex = parent.tex

		local tex = parent:GetStatusBarTexture()
		if tex:GetTexture() then
			bar:SetStatusBarTexture(tex:GetTexture())
			bar:GetStatusBarTexture():SetHorizTile(false)
			bar:GetStatusBarTexture():SetVertTile(false)
		end

		local r, g, b = bar.tex:GetVertexColor()
		bar:SetStatusBarColor(r, g, b)

		bar:SetFrameLevel(parent:GetFrameLevel())

		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", 0, 0)
		bar:SetPoint("BOTTOMRIGHT", 0, 0)
		bar:SetAlpha(1)

		return bar
	end
end

-- ZPerl.StatusBarSetValue
function ZPerl.StatusBarSetValue(self, val)
	if not tempDisableFadeBars and conf.bar.fading and self:GetName() then
		local low, high = self:GetMinMaxValues()
		local current = self:GetValue()

		-- Secret values (health always, power always) cannot be compared, so every update fades
		-- from the old value; after a gain the fader lies inside the bar's own fill and does not show
		local readable = CanAccess(val) and CanAccess(current) and CanAccess(high)
		if not readable or (val < current and val <= high and val >= low) then
			local bar = fadeBars[self]

			if not bar then
				bar = GetFreeFader(self)
			end

			if bar then
				if not self.fadeAlpha then
					-- The party range fade sets a secret alpha, which BarUpdate cannot count down
					local alpha = self:GetParent():GetAlpha()
					self.fadeAlpha = CanAccess(alpha) and alpha or 1
					bar:SetValue(current)
				end

				bar:SetMinMaxValues(low, high)
				bar:SetAlpha(self.fadeAlpha)
				bar:Show()
			end
		end
	end

	ZPerl.OldStatusBarSetValue(self, val)
end

-----------------------------
-- Health and absorb loss  --
-----------------------------
-- After a loss, the lost part of the health bar (a red bar behind it, bar.healthLoss) and of the absorb
-- bar (a paler strip at its left end, bar.absorbLoss) drains away instead of vanishing: it waits
-- LOSS_DELAY, then shrinks over LOSS_DURATION. A further loss during the wait pushes the start back; one
-- during the drain restarts it from where it is. A gain back to the start ends it. A unit change (another
-- GUID, or one that cannot be read) and ZPerl.NoFadeBars start over without animating.
-- Readable values are animated here. A secret health (retail) cannot be subtracted, so the client's own
-- bar interpolation drains the red bar, where it has one; a secret absorb is not animated.
local LOSS_DURATION, LOSS_DELAY, LOSS_PAUSE, LOSS_POSTPONE = 0.75, 0.1, 0.025, 0.025
local Interpolation = Enum and Enum.StatusBarInterpolation
local EASE = Interpolation and Interpolation.ExponentialEaseOut
local IMMEDIATE = Interpolation and Interpolation.Immediate

-- LossValue(loss, current): the drawn value, from loss.startValue down to current, and how far the drain is (0..1)
local function LossValue(loss, current)
	local elapsed = GetTime() - loss.startTime
	if (elapsed <= 0) then
		return loss.startValue, 0
	end
	local done = elapsed / LOSS_DURATION
	if (done < 1 and loss.startValue > current) then
		return loss.startValue - done * (loss.startValue - current), done
	end
	return current, 1
end

-- LossTrack(loss, value): feeds a new readable value; returns true while an animation runs
local function LossTrack(loss, value)
	local last = loss.lastValue
	loss.lastValue = value
	if (not last or tempDisableFadeBars) then
		loss.startTime = nil
		return false
	end
	if (value < last) then
		local now = GetTime()
		if (not loss.startTime) then
			loss.startValue = last
			loss.startTime = now + LOSS_DELAY
		elseif (loss.startTime > now) then
			loss.startTime = loss.startTime + LOSS_POSTPONE
		else
			loss.startValue = LossValue(loss, last)
			loss.startTime = now + LOSS_PAUSE
		end
	elseif (loss.startTime and value >= loss.startValue) then
		loss.startTime = nil
	end
	return loss.startTime ~= nil
end

-- SameUnit(loss, unit): whether unit is the one loss saw last; remembers it
local function SameUnit(loss, unit)
	local guid = UnitGUID(unit)
	local same = CanAccess(guid) and CanAccess(loss.guid) and guid ~= nil and guid == loss.guid
	loss.guid = guid
	return same
end

local function StopLoss(loss)
	loss.startTime = nil
	loss:SetScript("OnUpdate", nil)
	loss:Hide()
end

local function HealthLossOnUpdate(loss)
	local value, done = LossValue(loss, loss.lastValue)
	if (done >= 1) then
		loss:SetValue(loss.lastValue)
		StopLoss(loss)
	else
		loss:SetValue(value)
	end
end

-- HideWithBar(loss, bar): a loss sits beside the health bar, not on it (a child would draw over the bar's
-- fill), so it does not hide with it on its own: it stops when the bar hides. The next update shows it again,
-- as for a new unit: what changed while hidden is not drained (the secret health eases only for the same unit).
local function HideWithBar(loss, bar)
	bar:HookScript("OnHide", function()
		loss.lastValue = nil
		loss.guid = nil
		StopLoss(loss)
	end)
end

-- HealthLossBar(bar): the red bar right behind the health bar, as the incoming heal bar is
local function HealthLossBar(bar)
	local loss = bar.healthLoss
	if (not loss) then
		local parent = bar:GetParent()
		loss = CreateFrame("StatusBar", nil, parent)
		loss:SetAllPoints(bar)
		loss:SetFrameLevel(max(bar:GetFrameLevel() - 1, parent:GetFrameLevel()))
		loss:SetStatusBarTexture(bar:GetStatusBarTexture():GetTexture() or "Interface\\TargetingFrame\\UI-StatusBar")
		loss.tex = loss:GetStatusBarTexture()
		ZPerl.RegisterBar(loss)
		loss:SetStatusBarColor(1, 0, 0, 1)
		loss:Hide()
		HideWithBar(loss, bar)
		bar.healthLoss = loss
	end
	return loss
end

-- ZPerl.HealthLoss(bar, unit, hp, hpMax, off): the health loss of a health bar just set to hp of hpMax;
-- off when the bar does not show the health (the inverse option)
function ZPerl.HealthLoss(bar, unit, hp, hpMax, off)
	local loss = bar.healthLoss
	if (off or not conf.bar.healthLoss) then
		if (loss) then
			loss.lastValue = nil
			StopLoss(loss)
		end
		return
	end
	loss = loss or HealthLossBar(bar)
	local same = SameUnit(loss, unit)
	loss:SetMinMaxValues(0, hpMax)

	if (CanAccess(hp) and CanAccess(hpMax)) then
		if (not same) then
			loss.lastValue = nil
		end
		if (LossTrack(loss, hp)) then
			HealthLossOnUpdate(loss)
			loss:Show()
			loss:SetScript("OnUpdate", HealthLossOnUpdate)
		else
			-- Kept at the health, so a later secret update drains from here
			loss:SetValue(hp)
			StopLoss(loss)
		end
	elseif (EASE) then
		-- The bar rests under the health bar's fill; after a loss it eases down from the old value
		loss.lastValue = nil
		loss.startTime = nil
		loss:SetScript("OnUpdate", nil)
		loss:SetValue(hp, (same and not tempDisableFadeBars) and EASE or IMMEDIATE)
		loss:Show()
	else
		loss.lastValue = nil
		StopLoss(loss)
	end
end

local function AbsorbLossOnUpdate(loss)
	local _, done = LossValue(loss, loss.lastValue)
	if (done >= 1) then
		StopLoss(loss)
		return
	end
	-- The health can change between absorb updates: read it here while it is readable
	local healthBar = loss.healthBar
	local hp = healthBar:GetValue()
	local hpMax = select(2, healthBar:GetMinMaxValues())
	---@diagnostic disable-next-line: secret-comparison
	if (CanAccess(hp) and CanAccess(hpMax) and hpMax > 0) then
		loss.hp, loss.hpMax = hp, hpMax
	end
	-- The absorb bar fills the health fill from its right end at the health bar's scale: the lost strip
	-- ends where the absorb bar begins, and is as wide as the part still draining
	-- the absorb bar never shows more than the health: both ends are clamped to it, and the drain runs
	-- over the clamped range, so a shield larger than the health does not hold the strip, then snap it
	local scale = healthBar:GetWidth() / loss.hpMax
	local fill = healthBar:GetStatusBarTexture()
	local shown = min(loss.lastValue, loss.hp)
	local start = min(loss.startValue, loss.hp)
	local value = start - done * (start - shown)
	local right = -shown * scale
	loss:SetPoint("TOPRIGHT", fill, "TOPRIGHT", right, 0)
	loss:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", right, 0)
	loss:SetWidth(max(0, (value - shown) * scale))
end

-- AbsorbLoss(bar, healthBar, unit, amount): the absorb loss of the absorb bar bar; healthBar nil stops it
local function AbsorbLoss(bar, healthBar, unit, amount)
	local loss = bar.absorbLoss
	local hp, hpMax
	if (healthBar and conf.bar.absorbLoss and not conf.bar.inverse) then
		hp = healthBar:GetValue()
		hpMax = select(2, healthBar:GetMinMaxValues())
		amount = amount or 0
	end
	---@diagnostic disable-next-line: secret-comparison
	if (not hp or not CanAccess(amount) or not CanAccess(hp) or not CanAccess(hpMax) or hpMax <= 0) then
		if (loss) then
			loss.lastValue = nil
			StopLoss(loss)
		end
		return
	end

	if (not loss) then
		loss = CreateFrame("Frame", nil, healthBar:GetParent())
		loss.texture = loss:CreateTexture(nil, "ARTWORK")
		loss.texture:SetAllPoints()
		loss.texture:SetTexture("Interface\\Buttons\\White8x8")
		loss:Hide()
		HideWithBar(loss, healthBar)
		bar.absorbLoss = loss
	end
	if (not SameUnit(loss, unit)) then
		loss.lastValue = nil
	end

	-- The absorb itself is tracked, not its clamp to the health: a health drop under a shield larger
	-- than the health is no absorb loss. The drawing clamps (AbsorbLossOnUpdate).
	loss.healthBar, loss.hp, loss.hpMax = healthBar, hp, hpMax
	if (LossTrack(loss, amount)) then
		local c = conf.color.bar.absorb or {r = 0.14, g = 0.33, b = 0.7, a = 0.7}
		loss.texture:SetVertexColor(c.r, c.g, c.b, (c.a or 1) * 0.6)
		loss:SetFrameLevel(healthBar:GetFrameLevel() + 1)
		AbsorbLossOnUpdate(loss)
		loss:Show()
		loss:SetScript("OnUpdate", AbsorbLossOnUpdate)
	else
		StopLoss(loss)
	end
end

-- ZPerl.RegisterClickCastFrame
function ZPerl.RegisterClickCastFrame(self)
	if not ClickCastFrames then
		---@diagnostic disable-next-line: create-global
		ClickCastFrames = { }
	end
	ClickCastFrames[self] = true
end

-- ZPerl.SecureUnitButtonOnLoad
function ZPerl.SecureUnitButtonOnLoad(self, unit, menufunc, m1, m2, toggledisabled)
	self:SetAttribute("*type1", "target")
	if toggledisabled then
		self:SetAttribute("type2", "menu")
	else
		self:SetAttribute("type2", "togglemenu")
	end

	if unit then
		self:SetAttribute("unit", unit)
	end

	ZPerl.RegisterClickCastFrame(self)
end

-- ZPerl.UpdateRaidIcon
-- GetRaidTargetIndex can return a mark's index secret and no mark as nil: the index is tested for truth only,
-- and SetRaidTargetIconTexture hands it to SetSpriteSheetCell, which takes a secret.
function ZPerl.UpdateRaidIcon(self, unit)
	local index = GetRaidTargetIndex(unit)
	if index then
		local mark
		if unit == "player" or unit == "vehicle" or unit == "target" or unit == "focus" then
			if self.texture then
				mark = self.texture
			else
				mark = self
			end
		else
			mark = self
		end
		SetRaidTargetIconTexture(mark, index)
		self:Show()
	else
		self:Hide()
	end
end

------------------------------------------------------------------------------
-- Flashing frames handler. Is hidden when there's nothing to do.
local FlashFrame = CreateFrame("Frame", "ZPerl_FlashFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
FlashFrame.list = { }
FlashFrame:Hide() -- Its OnUpdate runs only while a flash is active (ZPerl.FrameFlash shows it)

-- FrameFlashOnUpdate(self, elapsed)
local function FrameFlashOnUpdate(self, elapsed)
	for k, v in pairs(self.list) do
		if (k.frameFlash.out) then
			k.frameFlash.alpha = k.frameFlash.alpha - elapsed
			if (k.frameFlash.alpha < 0.2) then
				k.frameFlash.alpha = 0.2
				k.frameFlash.out = nil

				if (k.frameFlash.method == "out") then
					ZPerl.FrameFlashStop(k)
				end
			end
		else
			k.frameFlash.alpha = k.frameFlash.alpha + elapsed
			if (k.frameFlash.alpha > 1) then
				k.frameFlash.alpha = 1
				k.frameFlash.out = true

				if (k.frameFlash.method == "in") then
					ZPerl.FrameFlashStop(k)
				end
			end
		end

		if (k.frameFlash) then
			k:SetAlpha(k.frameFlash.alpha)
		end
	end
end

FlashFrame:SetScript("OnUpdate", FrameFlashOnUpdate)

-- ZPerl.FrameFlash
function ZPerl.FrameFlash(self)
	if (not FlashFrame.list[self]) then
		if (self.frameFlash) then
			error("Z-Perl ["..self:GetName()..".frameFlash is set with no entry in FlashFrame.list]")
		end

		self.frameFlash = {out = true, alpha = 1, shown = self:IsShown()}

		FlashFrame.list[self] = true
		FlashFrame:Show()
		self:Show()
	end
end

-- ZPerl.FrameFlashStop
function ZPerl.FrameFlashStop(self, method)
	if (not self.frameFlash) then
		return
	end

	if (method) then
		self.frameFlash.method = method
		return
	end

	if (not self.frameFlash.shown) then
		self:Hide()
	end

	--ZPerl.FreeTable(self.frameFlash)
	self.frameFlash = nil

	self:SetAlpha(1)

	FlashFrame.list[self] = nil

	if (not next(FlashFrame.list)) then
		FlashFrame:Hide()
	end
end

-- ZPerl.ProtectedCall
function ZPerl.ProtectedCall(func, self)
	if (func) then
		ZPerl.AfterCombat(func, self)
	end
end

-- nextMember(last)
function ZPerl.NextMember(_, last)
	if (last) then
		local raidCount = GetNumGroupMembers()
		if (raidCount > 0) then
			if (IsInRaid()) then
				local i = tonumber(strmatch(last, "^raid(%d+)"))
				if (i and i < raidCount) then
					i = i + 1
					local unitName, _, group, _, _, unitClass, zone, online, dead = GetRaidRosterInfo(i)
					return "raid"..i, unitName, unitClass, group, zone, online, dead
				end
			else
				local partyCount = GetNumSubgroupMembers()
				if (partyCount > 0) then
					local id
					if (last == "player") then
						id = "party1"
					else
						local i = tonumber(strmatch(last, "^party(%d+)"))
						if (i and i < partyCount) then
							i = i + 1
							id = "party"..i
						end
					end

					if (id) then
						local _, class = UnitClass(id)
						return id, UnitName(id), class, 1, "", UnitIsConnected(id), UnitIsDeadOrGhost(id)
					end
				end
			end
		end
	else
		if (IsInRaid()) then
			local unitName, _, group, _, _, unitClass, zone, online, dead = GetRaidRosterInfo(1)
			return "raid1", unitName, unitClass, group, zone, online, dead
		else
			local _, class = UnitClass("player")
			return "player", UnitName("player"), class, 1, GetRealZoneText(), 1, UnitIsDeadOrGhost("player")
		end
	end
end

-- A model does not take its parents' alpha, so the frame transparency and range fade would leave a 3D
-- portrait opaque. Each ancestor of a synced model gets a SetAlpha hook that hands the effective alpha on to
-- the models below it.
local modelsByFrame = setmetatable({}, {__mode = "k"})

-- Copies the model's effective alpha into its model alpha; also needed after SetUnit, as a new model starts opaque.
-- The range fade can give an ancestor a secret alpha, which SetModelAlpha refuses: the model keeps its last alpha.
local function UpdateModelAlpha(model)
	local alpha = model:GetEffectiveAlpha()
	if (CanAccess(alpha)) then
		model:SetModelAlpha(alpha)
	end
end

local function OnAncestorSetAlpha(frame)
	for model in pairs(modelsByFrame[frame]) do
		UpdateModelAlpha(model)
	end
end

-- Hooks the model's ancestors once. The walk stops below UIParent: hooking a Blizzard frame would write into
-- its table and taint it. SetUnit loads the model later and the loaded model starts opaque, so the alpha is also
-- handed on when it has loaded.
local function SyncModelAlpha(model)
	model:HookScript("OnModelLoaded", UpdateModelAlpha)
	local frame = model:GetParent()
	while (frame and frame ~= UIParent) do
		local models = modelsByFrame[frame]
		if (not models) then
			models = setmetatable({}, {__mode = "k"})
			modelsByFrame[frame] = models
			hooksecurefunc(frame, "SetAlpha", OnAncestorSetAlpha)
		end
		models[model] = true
		frame = frame:GetParent()
	end
	UpdateModelAlpha(model)
end

-- Every 3D portrait model, for the zoom applier
local portraitModels = setmetatable({}, {__mode = "k"})

-- The zoom of the 3D portraits (General > Look), clamped to the slider's range
local function PortraitZoom()
	return min(max(tonumber(conf.portraitZoom) or 1, 0.5), 1)
end

-- ZPerl.SetPortraitZoom: applies the zoom setting to the 3D portraits now showing a unit; the others take it when
-- their unit is set
function ZPerl.SetPortraitZoom()
	local zoom = PortraitZoom()
	for model in pairs(portraitModels) do
		if (model:IsShown()) then
			model:SetPortraitZoom(zoom)
		end
	end
end
ZPerl.RegisterApplier("portraitzoom", ZPerl.SetPortraitZoom)

-- ZPerl.UnitUpdatePortrait
function ZPerl.UnitUpdatePortrait(self, force)
	local model = self.portraitFrame and self.portraitFrame.portrait3D
	if (model and not model.alphaSync) then
		model.alphaSync = true
		SyncModelAlpha(model)
		portraitModels[model] = true
	end
	if (self.conf and self.conf.portrait) then
		if self.conf.classPortrait then
			local _, englishClass = UnitClass(self.partyid)
			if ZPerl.SafeBool(UnitIsPlayer(self.partyid), false) and englishClass and CanAccess(englishClass) then
				SetPortraitToTexture(self.portraitFrame.portrait, "Interface\\Icons\\ClassIcon_"..englishClass)
			else
				SetPortraitTexture(self.portraitFrame.portrait, self.partyid)
			end
		else
			SetPortraitTexture(self.portraitFrame.portrait, self.partyid)
		end
		-- If a player moves out of range for a 3D portrait, it will show their proper 2D one.
		-- NPC 3D portraits also frequently fail to render at all inside instances
		-- (dungeons/raids) on this client, leaving a blank spot instead of a model --
		-- use the already-populated 2D portrait for NPCs there instead of attempting
		-- 3D. Real players keep their animated portrait everywhere, since that case
		-- has been reliable.
		-- The class icon wins over 3D: choosing it keeps portrait3D, so a frame switched from 3D has both set
		if (not self.conf.classPortrait and self.conf.portrait3D and UnitIsVisible(self.partyid) and (not IsInInstance() or UnitIsPlayer(self.partyid))) then
			self.portraitFrame.portrait:Hide()
			local guid = UnitGUID(self.partyid)
			-- A secret GUID cannot be compared, and that includes the *stored*
			-- one from a previous secret-identity target -- this crashed on a
			-- perfectly readable new guid because the stored one was secret.
			-- Guard both sides; always refresh if either is unreadable.
			if force or not CanAccess(guid) or not CanAccess(self.portraitFrame.portrait3D.guid) or guid ~= self.portraitFrame.portrait3D.guid or not self.portraitFrame.portrait3D:IsShown() then
				self.portraitFrame.portrait3D:Show()
				self.portraitFrame.portrait3D:ClearModel()
				self.portraitFrame.portrait3D:SetUnit(self.partyid)
				self.portraitFrame.portrait3D:SetPortraitZoom(PortraitZoom())
				self.portraitFrame.portrait3D.guid = guid
				-- A new model starts opaque
				UpdateModelAlpha(self.portraitFrame.portrait3D)
			end
		else
			self.portraitFrame.portrait:Show()
			self.portraitFrame.portrait3D:Hide()
		end
	end
end

-- ZPerl.UnitUpdateLevel
colorCurves.levelSecret = {r = 1, g = 1, b = 1}
function ZPerl.UnitUpdateLevel(self)
	local level = UnitLevel(self.partyid)
	-- Creature levels can be secret inside instances
	local readable = CanAccess(level)
	local color = readable and GetDifficultyColor(level) or colorCurves.levelSecret
	if (self.levelFrame) then
		self.levelFrame.text:SetTextColor(color.r,color.g,color.b)
		self.levelFrame.text:SetText(level)
	elseif (self.nameFrame.level) then
		if (readable and level == 0) then
			level = ""
		end
		self.nameFrame.level:SetTextColor(color.r,color.g,color.b)
		self.nameFrame.level:SetText(level)
	end
end

-- ZPerl.Differs(a, b): whether a poll must redraw: a or b is secret (it cannot be compared, so the
-- poll redraws every tick) or they differ.
function ZPerl.Differs(a, b)
	return IsSecret(a) or IsSecret(b) or a ~= b
end

-- ZPerl.UnitOnEnter
function ZPerl.UnitOnEnter(self)
	ZPerl.PlayerTip(self)
	if (self.highlight) then
		self.highlight:Select()
	end

	if (self.statsFrame and self.statsFrame.healthBar and self.statsFrame.healthBar.text and not self.statsFrame.healthBar.text:IsShown()) then
		self.hideValues = true
		self.statsFrame.healthBar.text:Show()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Show()
		end
		if (self.statsFrame.xpBar and self.statsFrame.xpBar:IsShown()) then
			self.statsFrame.xpBar.text:Show()
		end
		if (self.statsFrame.repBar and self.statsFrame.repBar:IsShown()) then
			self.statsFrame.repBar.text:Show()
		end
	end
end

-- ZPerl.UnitOnLeave
function ZPerl.UnitOnLeave(self)
	ZPerl.PlayerTipHide()
	if (self.highlight) then
		self.highlight:Deselect()
	end

	if (self.hideValues) then
		self.hideValues = nil

		self.statsFrame.healthBar.text:Hide()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Hide()
		end
		if (self.statsFrame.xpBar and self.statsFrame.xpBar:IsShown()) then
			self.statsFrame.xpBar.text:Hide()
		end
		if (self.statsFrame.repBar and self.statsFrame.repBar:IsShown()) then
			self.statsFrame.repBar.text:Hide()
		end
	end
end

-- SetReadyTexture(texture, name): READY_CHECK_*_TEXTURE is a file path on Classic and an atlas name on retail
local function SetReadyTexture(texture, name)
	if (name and not name:find("\\", 1, true) and texture.SetAtlas) then
		texture:SetAtlas(name)
	else
		texture:SetTexture(name)
	end
end

-- ZPerl.UnitUpdateReadyState
function ZPerl.UnitUpdateReadyState(self)
	local status = conf.showReadyCheck and self.partyid and GetReadyCheckStatus(self.partyid)
	if status then
		self.statsFrame.ready:Show()
		if status == "ready" then
			---@diagnostic disable-next-line: type-mismatch
			SetReadyTexture(self.statsFrame.ready.check, READY_CHECK_READY_TEXTURE)
		elseif status == "waiting" then
			---@diagnostic disable-next-line: type-mismatch
			SetReadyTexture(self.statsFrame.ready.check, READY_CHECK_WAITING_TEXTURE)
		elseif status == "notready" then
			---@diagnostic disable-next-line: type-mismatch
			SetReadyTexture(self.statsFrame.ready.check, READY_CHECK_NOT_READY_TEXTURE)
		else
			self.statsFrame.ready:Hide()
		end
	else
		self.statsFrame.ready:Hide()
	end
end

-- ZPerl.SwitchAnchor(self, new)
-- Changes anchored corner without actually moving the frame

-- ZPerl.SwitchAnchor
function ZPerl.SwitchAnchor(self, New)
	local left, top, ratio = ZPerl.FramePointUI(self)
	if (left and not self:GetPoint(2)) then
		local a1, f, a2 = self:GetPoint(1)

		if (a1 == a2 and New ~= a1) then
			local x, y
			local newV =strmatch(New, "TOP") or strmatch(New, "BOTTOM")
			local newH = strmatch(New, "LEFT") or strmatch(New, "RIGHT")

			if (newV == "TOP") then
				y = (top - 768 / UIParent:GetEffectiveScale()) / ratio
			elseif (newV == "BOTTOM") then
				y = self:GetBottom()
			else
				y = self:GetBottom() + self:GetHeight() / 2
			end

			if (newH == "LEFT") then
				x = left / ratio
			elseif (newH == "RIGHT") then
				x = self:GetRight()
			else
				x = self:GetLeft() + self:GetWidth() / 2
			end

			self:ClearAllPoints()
			self:SetPoint(New, f, New, x, y)
		end
	end
end

-- ZPerl.SetExpectedAbsorbs
function ZPerl.SetExpectedAbsorbs(self)
	local bar
	if self.statsFrame and self.statsFrame.expectedAbsorbs then
		bar = self.statsFrame.expectedAbsorbs
	else
		bar = self.expectedAbsorbs
	end
	if (bar) then
		local unit = self.partyid

		if not unit then
			unit = self:GetParent().targetid
		end

		local amount = type(UnitGetTotalAbsorbs) == "function" and UnitGetTotalAbsorbs(unit)

		local healthBar
		if self.statsFrame and self.statsFrame.healthBar then
			healthBar = self.statsFrame.healthBar
		else
			healthBar = self.healthBar
		end
		if (not healthBar or ZPerl.SafeBool(UnitIsDeadOrGhost(unit), false)) then
			bar:Hide()
			AbsorbLoss(bar)
			return
		end
		AbsorbLoss(bar, healthBar, unit, amount)
		-- A secret is never nil; a readable amount must be above 0
		---@diagnostic disable-next-line: secret-comparison
		if (not IsSecret(amount) and (not amount or amount <= 0)) then
			bar:Hide()
			return
		end

		if ZPerl.SafeBool(UnitIsAFK(unit), false) then
			bar:SetStatusBarColor(0.2, 0.2, 0.2, 0.7)
		else
			if (not conf.color.bar.absorb) then
				conf.color.bar.absorb = {r = 0.14, g = 0.33, b = 0.7, a = 0.7}
			end
			bar:SetStatusBarColor(conf.color.bar.absorb.r, conf.color.bar.absorb.g, conf.color.bar.absorb.b, conf.color.bar.absorb.a)
		end

		-- The bar lies exactly over the health bar's fill and fills from its right end towards the left,
		-- scaled to the health bar's current value: absorb / health of the fill's width is absorb / max
		-- health of the whole bar, so it grows from the end of the health like the incoming heals, and
		-- an absorb above the health fills it to its max: the whole fill is covered. No maths, so it
		-- works the same with secret amounts and health. Anchored once.
		if (not bar.zperlOnFill) then
			bar.zperlOnFill = true
			bar:ClearAllPoints()
			bar:SetAllPoints(healthBar:GetStatusBarTexture())
			if (bar.SetFrameLevel and healthBar.GetFrameLevel) then
				bar:SetFrameLevel(healthBar:GetFrameLevel() + 1)
			end
		end
		if (bar.SetReverseFill) then
			bar:SetReverseFill(true)
		end
		bar:SetMinMaxValues(0, healthBar:GetValue())
		bar:SetValue(amount)
		bar:Show()
	end
end

-- PlaceExpectedHealth(bar, healthBar, afterFill)
-- The incoming heal bar is drawn two ways. Readable amounts: the bar covers the health bar and is filled
-- to health + incoming. Secret amounts (retail: health and incoming heals are always secret) cannot be
-- added, so the bar starts at the right edge of the health bar's fill, is as wide as the health bar and
-- is filled to incoming / max health; the client does the maths. The amount is clamped to the missing
-- health by the client's calculator (IncomingHeals), so the bar ends at the health bar's end. (A clip
-- frame cannot do it: a frame clipping a child anchored to a secret-sized region hides the child.)
-- Re-anchors only when the mode changes.
local function PlaceExpectedHealth(bar, healthBar, afterFill)
	if (afterFill) then
		-- The health bar's width can change with the frame size, so it is set on every call
		bar:SetWidth(healthBar:GetWidth())
	end
	if (bar.zperlAfterFill == afterFill) then
		return
	end
	bar.zperlAfterFill = afterFill

	bar:ClearAllPoints()
	if (afterFill) then
		local fill = healthBar:GetStatusBarTexture()
		bar:SetPoint("TOPLEFT", fill, "TOPRIGHT", 0, 0)
		bar:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT", 0, 0)
		bar:SetWidth(healthBar:GetWidth())
	else
		bar:SetAllPoints(healthBar)
	end
end

-- LibHealComm-4.0 (Classic Era only; the library does not load elsewhere): the incoming heals come from the
-- heals the group's healers announce, as the client has none of its own there.
local HealComm = LibStub and LibStub("LibHealComm-4.0", true)

-- IncomingHeals(unit)
-- The incoming heals on unit. LibHealComm: the direct heals landing in the next 3 seconds, scaled by the
-- unit's healing modifier. With the client's heal prediction calculator (retail) the amount is clamped
-- to the unit's missing health, so a secret amount needs no maths; else UnitGetIncomingHeals.
local calculator
local function IncomingHeals(unit)
	if (HealComm) then
		local guid = UnitGUID(unit)
		if (not guid) then
			return nil
		end
		return (HealComm:GetHealAmount(guid, HealComm.CASTED_HEALS, GetTime() + 3) or 0) * HealComm:GetHealModifier(guid)
	end
	if (calculator == nil) then
		calculator = false
		if (type(CreateUnitHealPredictionCalculator) == "function" and type(UnitGetDetailedHealPrediction) == "function") then
			calculator = CreateUnitHealPredictionCalculator()
			if (Enum and Enum.UnitIncomingHealClampMode) then
				calculator:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
			end
			-- The overflow past the missing health is a ratio (1.05) or a fraction (0.05) of it; no overflow
			local overflow = calculator:GetIncomingHealOverflowPercent()
			if (CanAccess(overflow)) then
				calculator:SetIncomingHealOverflowPercent(overflow >= 1 and 1 or 0)
			end
		end
	end
	if (calculator) then
		UnitGetDetailedHealPrediction(unit, "player", calculator)
		return (calculator:GetIncomingHeals())
	end
	if (type(UnitGetIncomingHeals) == "function") then
		return UnitGetIncomingHeals(unit)
	end
end

-- ZPerl.SetExpectedHealth
function ZPerl.SetExpectedHealth(self)
	local bar
	if self.statsFrame and self.statsFrame.expectedHealth then
		bar = self.statsFrame.expectedHealth
	else
		bar = self.expectedHealth
	end
	if (bar) then
		local unit = self.partyid

		if not unit then
			unit = self:GetParent().targetid
		end

		-- The client's own incoming heal value
		local amount = IncomingHeals(unit)

		if not conf.color.bar.healprediction then
			conf.color.bar.healprediction = { }
			conf.color.bar.healprediction.r = 0
			conf.color.bar.healprediction.g = 1
			conf.color.bar.healprediction.b = 1
			conf.color.bar.healprediction.a = 1
		end

		local healthBar
		if self.statsFrame and self.statsFrame.healthBar then
			healthBar = self.statsFrame.healthBar
		else
			healthBar = self.healthBar
		end
		if (not healthBar) then
			bar:Hide()
			return
		end

		if (IsSecret(amount) or IsSecret(UnitHealth(unit))) then
			-- Secret amount or health: nothing can be added or compared, so the client sizes the bar
			-- (PlaceExpectedHealth). A secret amount of 0 draws an empty bar.
			-- A secret is never nil; a readable amount (with secret health) must still be above 0
			---@diagnostic disable-next-line: secret-comparison
			local none = not IsSecret(amount) and (not amount or amount <= 0)
			if (none or ZPerl.SafeBool(UnitIsDeadOrGhost(unit), false)) then
				bar:Hide()
				return
			end
			PlaceExpectedHealth(bar, healthBar, true)
			bar:SetStatusBarColor(conf.color.bar.healprediction.r, conf.color.bar.healprediction.g, conf.color.bar.healprediction.b, conf.color.bar.healprediction.a)
			bar:SetMinMaxValues(0, UnitHealthMax(unit))
			bar:SetValue(amount)
			bar:Show()
			return
		end

		---@diagnostic disable-next-line: secret-comparison
		if (amount and amount > 0 and not ZPerl.SafeBool(UnitIsDeadOrGhost(unit), false)) then
			PlaceExpectedHealth(bar, healthBar, false)
			local healthMax = UnitHealthMax(unit)
			local health = ZPerl.SafeBool(UnitIsGhost(unit), false) and 1 or (ZPerl.SafeBool(UnitIsDead(unit), false) and 0 or UnitHealth(unit))
			if (not CanAccess(health) or not CanAccess(healthMax)) then
				bar:Hide()
				return
			end

			bar:SetStatusBarColor(conf.color.bar.healprediction.r, conf.color.bar.healprediction.g, conf.color.bar.healprediction.b, conf.color.bar.healprediction.a)

			bar:Show()
			bar:SetMinMaxValues(0, healthMax)
			---@diagnostic disable-next-line: secret-arithmetic, secret-argument
			bar:SetValue(min(healthMax, health + amount))

			return
		end
		bar:Hide()
	end
end

-- Threat Display
local function DrawHand(self, percent)
	local angle = 360 - (percent * 2.7 - 135)
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = rotate(angle)
	self.needle:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

local function DrawSlider(self, percent)
	local offset = (self:GetWidth() - 9) / 100 * percent
	self.needle:ClearAllPoints()
	self.needle:SetPoint("CENTER", self, "TOPLEFT", offset + 5, -2)

	local r, g, b
	if (percent <= 70) then
		r, g, b = 0, 1, 0
	else
		r, g, b = smoothColor(abs((percent - 100) / 30))
	end

	self.needle:SetVertexColor(r, g, b)
end

-- ZPerl.ThreatDisplayOnLoad
function ZPerl.ThreatDisplayOnLoad(self, mode)
	ZPerl.SetChildMembers(self)
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 4)
	self.text:SetWidth(100)
	self.current, self.target = 0, 0
	self.mode = mode

	if (mode == "nameFrame") then
		self.Draw = DrawSlider
	else
		self.Draw = DrawHand
	end
	self:Draw(0)
end

-- threatOnUpdate
local function threatOnUpdate(self, elapsed)
	local diff = (self.target - self.current) * 0.2
	self.current = min(100, max(0, self.current + diff))
	if (abs(self.current - self.target) <= 0.01) then
		self.current = self.target
		self:SetScript("OnUpdate", nil)
	end

	self:Draw(self.current)
end

-- ZPerl.UnitThreatStatus
function ZPerl.UnitThreatStatus(self, relative, immediate)
	if (type(UnitDetailedThreatSituation) ~= "function" or not self.partyid or not self.conf) then
		return
	end

	local mode = self.conf.threatMode or (self.conf.portrait and "portraitFrame" or "nameFrame")
	local t = self.threatFrames and self.threatFrames[mode]
	if (not self.conf.threat) then
		if (t) then
			t:Hide()
		end
		return
	end

	if (not t) then
		if (self.threatFrames) then
			for _,frame in pairs(self.threatFrames) do
				frame:SetScript("OnUpdate", nil)
				frame.current, frame.target = 0, 0
				frame:Hide()
			end
		else
			self.threatFrames = {}
		end
		if (self[mode]) then -- If desired parent frame exists
			-- Once per frame and mode: the `not t` guard above creates it on the first call and every
			-- later call reuses self.threatFrames[mode]; the frame carries the mode's template.
			t = CreateFrame("Frame", self:GetName().."Threat"..mode, self[mode], BackdropTemplateMixin and "BackdropTemplate,ZPerl_ThreatTemplate"..mode or "ZPerl_ThreatTemplate"..mode)
			t:SetAllPoints()
			self.threatFrames[mode] = t
		end

		self.threat = self.threatFrames[mode]
	end

	if (t) then
		local _, scaledPercent
		local one, two
		-- Attack/combat flags for compound units can be secret
		if (ZPerl.SafeBool(UnitAffectingCombat(self.partyid), false) or (relative and ZPerl.SafeBool(UnitAffectingCombat(relative), false))) then
			if (relative and ZPerl.SafeBool(UnitCanAttack(relative, self.partyid), false)) then
				one, two = relative, self.partyid
			else
				if (UnitExists("target") and ZPerl.SafeBool(UnitCanAttack(self.partyid, "target"), false)) then
					one, two = self.partyid, "target"
				elseif (ZPerl.SafeBool(UnitCanAttack("player", self.partyid), false)) then
					one, two = "player", self.partyid
				elseif (ZPerl.SafeBool(UnitCanAttack(self.partyid, self.partyid.."target"), false)) then
					one, two = self.partyid, self.partyid.."target"
				end
			end

			if (one) then
				-- scaledPercent is 0% - 100%, 100 means you pull agro
				-- rawPercent is before normalization so can go up to 110% or 130% before you pull agro
				_, _, scaledPercent = UnitDetailedThreatSituation(one, two)
			end
		end

		if (scaledPercent) then
			if (CanAccess(scaledPercent)) then
				---@diagnostic disable-next-line: secret-comparison
				if (scaledPercent ~= t.target) then
					t.target = scaledPercent
					if (immediate) then
						t.current = scaledPercent
					end
					t.one = one
					t.two = two
					t:SetScript("OnUpdate", threatOnUpdate)
				end

				-- smoothColor takes 0..1, red at 0: full threat is red, none green
				---@diagnostic disable-next-line: secret-arithmetic
				local r, g, b = smoothColor(1 - scaledPercent / 100)
				t.text:SetTextColor(r, g, b)
			else
				-- The text sink can show a secret percent, but the
				-- needle animation needs maths, so it stays where it is.
				t:SetScript("OnUpdate", nil)
				t.text:SetTextColor(1, 1, 1)
			end

			t.text:SetFormattedText("%d%%", scaledPercent)

			t:Show()
			return
		end

		t:Hide()
	end
end

-- ZPerl.RegisterPrediction(self, frameConf, element)
-- The heal prediction option turns the frame's heal element (UNIT_HEAL_PREDICTION for the frame's
-- units) on or off. The frame must have run ZPerl.UnitFrameInit.
function ZPerl.RegisterPrediction(self, frameConf, element)
	if not self then
		return
	end

	-- The client's own event drives the bar; with LibHealComm its callbacks do (below)
	if frameConf.healprediction and (HealComm or type(UnitGetIncomingHeals) == "function") then
		ZPerl.UnitFrameEnable(self, element)
	else
		ZPerl.UnitFrameDisable(self, element)
	end
end

-- LibHealComm callbacks: every argument that is a GUID (the caster's and the targets') is gathered, and each
-- unit frame that handles UNIT_HEAL_PREDICTION and shows one of those units gets that event, as the client
-- would send it. The frames' handlers check their heal prediction option themselves.
if (HealComm) then
	local guids = {}
	local function HealCommUpdate(_, ...)
		wipe(guids)
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if (type(v) == "string") then
				guids[v] = true
			end
		end
		for frame in pairs(ZPerl.UnitFrames) do
			local unit = frame.partyid
			if (unit and frame.__handlers.UNIT_HEAL_PREDICTION) then
				local guid = UnitGUID(unit)
				---@diagnostic disable-next-line: secret-table-key
				if (guid and guids[guid]) then
					ZPerl.UnitFrameOnEvent(frame, "UNIT_HEAL_PREDICTION", unit)
				end
			end
		end
	end
	for _, callback in ipairs({"HealComm_HealStarted", "HealComm_HealStopped", "HealComm_HealDelayed",
		"HealComm_HealUpdated", "HealComm_ModifierChanged", "HealComm_GUIDDisappeared"}) do
		---@diagnostic disable-next-line: undefined-field
		HealComm.RegisterCallback("ZPerl", callback, HealCommUpdate)
	end
end
