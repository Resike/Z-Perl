-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

-- Elements (ZPerl_Unit.lua): Target holds what both frames handle; TargetOnly and FocusOnly the events
-- of one frame each. The Target events are defined in ZPerl_TargetEvents.lua.

local L = ZPerl.L

ZPerl.Elements.Target = {events = { }}
ZPerl.Elements.TargetOnly = {events = {}}
ZPerl.Elements.FocusOnly = {events = {}}
ZPerl.Elements.TargetHeal = {events = {}} -- On while the frame's heal prediction option is on
local conf, tconf, fconf
ZPerl.RequestConfig(function(new)
	conf = new
	tconf = conf.target
	fconf = conf.focus
	if (ZPerl_Target) then
		ZPerl_Target.conf = conf.target
		ZPerl.MainFrameStart(ZPerl_Target, conf.target.enable, TargetFrame)
	end
	if (ZPerl_Focus) then
		ZPerl_Focus.conf = conf.focus
	end
	if (ZPerl_TargetTarget) then
		ZPerl_TargetTarget.conf = conf.targettarget
	end
	if (ZPerl_FocusTarget) then
		ZPerl_FocusTarget.conf = conf.focustarget
	end
	if (ZPerl_PetTarget) then
		ZPerl_PetTarget.conf = conf.pettarget
	end
end, "$Revision:  $")

-- Secret value helpers from ZPerl.lua
local CanAccess = ZPerl.CanAccess
local SafeBool = ZPerl.SafeBool

-- Upvalues
local max = max
local tonumber = tonumber
local type = type

local CombatFeedback_Initialize = CombatFeedback_Initialize
local CreateFrame = CreateFrame
local GetDifficultyColor = GetCreatureDifficultyColor or GetQuestDifficultyColor
local RegisterUnitWatch = RegisterUnitWatch
local UnitClassBase = UnitClassBase
local UnitClassification = UnitClassification
local UnitCreatureType = UnitCreatureType
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitIsCharmed = UnitIsCharmed
local UnitIsFriend = UnitIsFriend
local UnitIsMercenary = UnitIsMercenary
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsVisible = UnitIsVisible
local UnitLevel = UnitLevel
local UnitPlayerControlled = UnitPlayerControlled
local UnregisterUnitWatch = UnregisterUnitWatch

local BackdropTemplateMixin = BackdropTemplateMixin

local FocusFrame = FocusFrame

-- Native Z-Perl combo points. Each point is its own StatusBar with a
-- one-point range, so Blizzard can safely feed a protected combo value into it
-- without addon code comparing or inspecting that value.
local function ZPerl_CreateComboDisplay(self)
	if self.foreverCombo then
		return
	end

	local holder = CreateFrame("Frame", self:GetName().."ForeverCombo", self)
	holder:SetSize(110, 10)
	holder:SetPoint("BOTTOMLEFT", self.nameFrame, "TOPLEFT", 4, 3)
	holder:SetFrameLevel(self.nameFrame:GetFrameLevel() + 3)
	holder.points = {}

	for i = 1, 7 do
		local point = CreateFrame("StatusBar", nil, holder, BackdropTemplateMixin and "BackdropTemplate")
		point:SetSize(14, 8)
		point:SetPoint("LEFT", holder, "LEFT", (i - 1) * 16, 0)
		point:SetStatusBarTexture(ZPerl.GetBarTexture())
		point:SetMinMaxValues(i - 1, i)
		point:SetValue(0)
		point:SetStatusBarColor(1, 0.78, 0, 1)
		if point.SetBackdrop then
			point:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 6})
			point:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
		end
		local background = point:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints()
		background:SetColorTexture(0.06, 0.06, 0.06, 0.9)
		holder.points[i] = point
	end

	holder:Hide()
	self.foreverCombo = holder
end

----------------------
-- Loading Function --
----------------------
function ZPerl.Target.OnLoad(self, partyid)
	self:RegisterForClicks("AnyUp")
	self:RegisterForDrag("LeftButton")
	ZPerl.SetChildMembers(self)
	-- The aura color highlight is for party and raid frames; this frame shows only the HoT highlight
	self.hotHighlightOnly = true

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	self.hitIndicator.text:SetPoint("CENTER", self.portraitFrame, "CENTER", 0, 0)

	self.updateHealth = ZPerl.Target.UpdateHealth
	self.updatePower = ZPerl.Target.SetMana
	self.updatePowerType = ZPerl.Target.SetManaAndType
	self.auraLineSize = ZPerl.Target.AuraLineSize
	self.auraInset = ZPerl.Target.AuraInset
	ZPerl.UnitFrameInit(self, {partyid}, {"Health", "Power", "Target", "Auras"})

	ZPerl_Highlight:Register(ZPerl.Target.HighlightCallback, self)

	self.partyid = partyid
	if (partyid == "target") then
		ZPerl_CreateComboDisplay(self)
		self.statsFrame.focusTarget:SetVertexColor(0.7, 1, 1, 0.5)

		ZPerl.UnitFrameEnable(self, "TargetOnly")

		self.nameFrame.cpMeter:SetFrameLevel(2)
		self.nameFrame.cpMeter:GetStatusBarTexture():SetHorizTile(false)
		self.nameFrame.cpMeter:GetStatusBarTexture():SetVertTile(false)

		self.combatMask = 0x00010000
	else
		ZPerl.UnitFrameEnable(self, "FocusOnly")
		--self:SetScript("OnShow", ZPerl.Target.UpdateDisplay)
		self.combatMask = 0x00020000
	end

	self.auraCancel = true

	--ZPerl.SecureUnitButtonOnLoad(self.nameFrame, partyid, nil, TargetFrameDropDown, ZPerl_ShowGenericMenu)		--TargetFrame.menu)
	--ZPerl.SecureUnitButtonOnLoad(self, partyid, nil, TargetFrameDropDown, ZPerl_ShowGenericMenu)				--TargetFrame.menu)
	--self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self.nameFrame:SetAttribute("unit", partyid)

	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")
	self:SetAttribute("unit", partyid)

	ZPerl.RegisterClickCastFrame(self.nameFrame)
	ZPerl.RegisterClickCastFrame(self)

	--RegisterUnitWatch(self)

	--self.PlayerFlash = 0
	self.time = 0

	--ZPerl_InitFadeFrame(self)

	ZPerl.RegisterHighlight(self.highlight, 3)
	ZPerl.RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.levelFrame, self.portraitFrame, self.typeFramePlayer, self.creatureTypeFrame, self.bossFrame, self.cpFrame})

	self.FlashFrames = {self.portraitFrame, self.nameFrame, self.levelFrame, self.statsFrame, self.bossFrame, self.typeFramePlayer, self.typeFrame}

	if (ZPerl.ArcaneBar.RegisterFrame) then
		ZPerl.ArcaneBar.RegisterFrame(self.nameFrame, partyid)
	end

	if (ZPerl.layout) then
		self.conf = ZPerl.layout[partyid]
		-- New-profile defaults are applied by TargetConfigDefault.
		-- Keep target debuffs a uniform size.  Enlarging player-applied debuffs
		-- during combat consumes two columns per icon and collapses the intended
		-- long left-to-right rows into three-icon rows.
		if (self.conf and self.conf.debuffs) then
			self.conf.debuffs.big = false
		end
	end

	ZPerl.RegisterOptionChanger(ZPerl.Target.SetBits, self, "target")

	if (ZPerl_Target and ZPerl_Focus) then
		ZPerl.Target.OnLoad = nil
	end
end

-- HighlightCallback
function ZPerl.Target.HighlightCallback(self, updateGUID)
	local guid = UnitGUID(self.partyid)
	if (guid and CanAccess(guid) and guid == updateGUID and SafeBool(UnitIsFriend("player", self.partyid), false)) then
		ZPerl_Highlight:SetHighlight(self, updateGUID)
	end
end

-- The aura strip is the frame; the level frame sits outside it, at the portrait's right edge. Rows
-- (Top, Bottom) wrap at the width of stats, portrait and level together; a Right block starts past
-- the level frame.
function ZPerl.Target.AuraLineSize(self, kind)
	local edge = self.statsFrame:GetWidth()
	if (self.portraitFrame and self.portraitFrame:IsShown()) then
		edge = edge - 2 + self.portraitFrame:GetWidth()
	end
	if (self.levelFrame and self.levelFrame:IsShown()) then
		edge = edge - 2 + self.levelFrame:GetWidth()
	end
	return ZPerl.AurasLineSize(self, kind, edge)
end
function ZPerl.Target.AuraInset(self, side)
	local lv = self.levelFrame
	local lr, fr = lv and lv:IsShown() and lv:GetRight(), self:GetRight()
	if (side == "RIGHT" and lr and fr and lr > fr) then
		return lr - fr
	end
	return 0
end

-------------------------
-- The Update Functions--
-------------------------
local function UpdatePVP(self)
	local partyid = self.partyid

	local pvpIcon = self.nameFrame.pvp

	local factionGroup = UnitFactionGroup(partyid)
	-- Faction names can be secret for creatures inside instances: they can be neither tested nor compared
	if (not CanAccess(factionGroup)) then
		factionGroup = nil
	end

	if self.conf.pvpIcon and SafeBool(UnitIsPVPFreeForAll(partyid), false) then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		pvpIcon:Show()
	elseif self.conf.pvpIcon and factionGroup and factionGroup ~= "Neutral" and SafeBool(UnitIsPVP(partyid), false) then
		pvpIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)

		if type(UnitIsMercenary) == "function" and SafeBool(UnitIsMercenary(partyid), false) then
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

	if (self.conf.reactionHighlight) then
		local c = ZPerl.ReactionColor(partyid)
		self.nameFrame:SetBackdropColor(c.r, c.g, c.b)

		if (conf.color.class and SafeBool(UnitPlayerControlled(partyid), false)) then
			ZPerl.SetUnitNameColor(self.nameFrame.text, partyid)
		else
			self.nameFrame.text:SetTextColor(1, 1, 1, conf.transparency.text)
		end
	else
		if not self.conf.highlightDebuffs.enable then
			self.nameFrame:SetBackdropColor(conf.color.frame.r, conf.color.frame.g, conf.color.frame.b, conf.color.frame.a)
		end
		ZPerl.SetUnitNameColor(self.nameFrame.text, partyid)
	end

	-- Indirect units can return secret flags; no icon in that case
	if SafeBool(UnitIsVisible(partyid), false) and SafeBool(UnitIsCharmed(partyid), false) and SafeBool(UnitIsPlayer(partyid), false) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- UpdateName
local function UpdateName(self)
	-- UnitName's second value used to be a rare cross-realm
	-- suffix; on Forever it's a mandatory surname that's sent for every player
	-- who has chosen to show it, so it can no longer be silently dropped here
	self.nameFrame.text:SetText(ZPerl.UnitFullName(self.partyid))
	UpdatePVP(self)
end

-- UpdateLevel
local function UpdateLevel(self)
	local targetlevel = UnitLevel(self.partyid)
	self.levelFrame.text:SetText(targetlevel)
	-- Set Level
	if (self.conf.level) then
		self.levelFrame:Show()
		self.levelFrame.skull:Hide()
		self.levelFrame:SetWidth(27)
		if (not CanAccess(targetlevel)) then
			-- Creature levels are secret inside instances
			self.levelFrame.text:SetTextColor(1, 1, 1)
			self.levelFrame.text:Show()
		elseif (targetlevel < 0) then
			self.levelFrame.text:Hide()
			self.levelFrame.skull:Show()
		else
			local color = GetDifficultyColor(targetlevel)
			self.levelFrame.text:SetTextColor(color.r, color.g, color.b)
			self.levelFrame.text:Show()
			local classification = UnitClassification(self.partyid)
			if (not self.conf.elite and CanAccess(classification) and (classification == "elite" or classification == "worldboss")) then
				self.levelFrame.text:SetFormattedText("%d+", targetlevel)
				self.levelFrame:SetWidth(33)
			end
		end
	end
end

-- UpdateClassification
local function UpdateClassification(self)
	local partyid = self.partyid
	local targetclassification = UnitClassification(partyid)
	local bossType, eliteGfx

	if (not CanAccess(targetclassification)) then
		-- The classification is secret, nothing can be decided
		self.bossFrame:Hide()
		self.eliteFrame:Hide()
		self.typeFramePlayer:Hide()
		return
	end

	if (targetclassification == "normal" and SafeBool(UnitPlayerControlled(partyid), false)) then
		if (not SafeBool(UnitIsPlayer(partyid), false)) then
			bossType = L["TYPE_PET"]
			self.bossFrame.text:SetTextColor(1, 1, 1)
			self.typeFramePlayer:Hide()
		end

	elseif (self.conf.level or targetclassification == "rareelite" or targetclassification == "rare" or targetclassification == "elite" or targetclassification == "worldboss") then
	--elseif ((self.conf.level and self.conf.elite) or targetclassification == "Rare+" or targetclassification == "Rare") then
		if (self.conf.eliteGfx) then
			eliteGfx = true
			if (targetclassification == "worldboss" or targetclassification == "elite") then
				self.eliteFrame.tex:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_Elite")
				self.eliteFrame.tex:SetVertexColor(1, 1, 0, 1)
			elseif (targetclassification == "rareelite") then
				self.eliteFrame.tex:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_Elite")
				self.eliteFrame.tex:SetVertexColor(1, 1, 1, 1)
			elseif (targetclassification == "rare") then
				self.eliteFrame.tex:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_Rare")
				self.eliteFrame.tex:SetVertexColor(1, 1, 1, 1)
			else
				eliteGfx = nil
			end
		else
			if (targetclassification == "worldboss") then
				bossType = L["TYPE_BOSS"]
				self.bossFrame.text:SetTextColor(1, 0.5, 0.5)
			elseif (targetclassification == "rareelite") then
				bossType = L["TYPE_RAREPLUS"]
				self.bossFrame.text:SetTextColor(0.8, 0.8, 0.8)
			elseif (targetclassification == "elite") then
				bossType = L["TYPE_ELITE"]
				self.bossFrame.text:SetTextColor(1, 1, 0.5)
			elseif (targetclassification == "rare") then
				bossType = L["TYPE_RARE"]
				self.bossFrame.text:SetTextColor(0.8, 0.8, 0.8)
			end
		end

		self.typeFramePlayer:Hide()
	end

	if (partyid == "target" and bossType and not tconf.eliteNone) or (partyid == "focus" and bossType and not fconf.eliteNone) then
		self.bossFrame:Show()
		self.bossFrame.text:SetText(bossType)
		-- GetStringWidth() can be secret even for plain text
		-- (section 3 taint-propagation nuance)
		ZPerl.SafeSetWidthFromText(self.bossFrame, self.bossFrame.text, 10, 70)
	else
		self.bossFrame:Hide()
	end

	if (eliteGfx) then
		self.eliteFrame:Show()
		if (partyid == "target" and ZPerl_Target_AssistFrame and ZPerl_Target_AssistFrame:IsShown()) then
			ZPerl_Target_AssistFrame:ClearAllPoints()
			ZPerl_Target_AssistFrame:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", 0, 0)
			ZPerl_Target_AssistFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel() + 2)
			self.eliteFrame.assistOutOfPlace = true
		end
		if (self.conf.level) then
			self.levelFrame:ClearAllPoints()
			self.levelFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPRIGHT", 0, 0)
			self.levelFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel() + 2)
			self.levelFrame.outOfPlace = true
		end
		-- This is hidden if the mob is elite regardless of graphics (wihout gfx it says "Elite" for example)
		--if (self.conf.classIcon) then
		--	self.typeFramePlayer:ClearAllPoints()
		--	self.typeFramePlayer:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMRIGHT", 0, 0)
		--	self.typeFramePlayer.outOfPlace = true
		--end
	else
		self.eliteFrame:Hide()
		if (partyid == "target" and self.eliteFrame.assistOutOfPlace) then
			self.eliteFrame.assistOutOfPlace = nil
			ZPerl_Target_AssistFrame:ClearAllPoints()
			ZPerl_Target_AssistFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, -20)
			ZPerl_Target_AssistFrame:SetFrameLevel(self.portraitFrame:GetFrameLevel())
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

-- UpdateType
local function UpdateType(self)
	local partyid = self.partyid
	local targettype = UnitCreatureType(partyid)
	-- Creature types are secret inside instances
	local typeReadable = CanAccess(targettype)

	---@diagnostic disable-next-line: secret-comparison
	if (typeReadable and (targettype == L["TYPE_NOT_SPECIFIED"] or targettype == "")) then
		targettype = nil
	end

	if (self.conf.mobType) then
		self.creatureTypeFrame:Show()
	else
		self.creatureTypeFrame:Hide()
	end

	self.typeFramePlayer:Hide()


	self.creatureTypeFrame.text:SetText(targettype)

	--if (UnitIsPlayer(partyid)) then
		local classification = UnitClassification(partyid)
		if (self.conf.classIcon and (SafeBool(UnitIsPlayer(partyid), false) or (CanAccess(classification) and classification == "normal"))) then
			local LocalClass = UnitClassBase(partyid)

			if (self.conf.classText) then
				-- The localized name: UnitClassBase gives the token ("WARRIOR"), which is for the icon
				self.bossFrame.text:SetText((UnitClass(partyid)))
				self.bossFrame.text:SetTextColor(1, 1, 1)
				self.bossFrame:Show()
				-- GetStringWidth() can be secret even for
				-- plain text (section 3 taint-propagation nuance)
				ZPerl.SafeSetWidthFromText(self.bossFrame, self.bossFrame.text, 10, 70)
			else
				if (SafeBool(UnitIsPlayer(partyid), false) or not SafeBool(UnitPlayerControlled(partyid), false)) then
					local l, r, t, b = ZPerl.ClassPos(LocalClass)
					self.typeFramePlayer.classTexture:SetTexCoord(l, r, t, b)
					self.typeFramePlayer:Show()
				end
			end
		end
		if (SafeBool(UnitIsPlayer(partyid), false)) then
			self.creatureTypeFrame:Hide()
		end
	--else
		if (targettype) then
			self.creatureTypeFrame.text:SetTextColor(1, 1, 1)
			-- typeReadable alone is not enough -- confirmed
			-- live crashing here even with targettype readable, because
			-- GetStringWidth() picks up taint from any secret value read
			-- earlier in this same update (section 3 taint-propagation
			-- nuance). Guard the width itself instead.
			ZPerl.SafeSetWidthFromText(self.creatureTypeFrame, self.creatureTypeFrame.text, 10, 70)
		else
			self.creatureTypeFrame:Hide()
		end
	--end

	AdjustCreatureTypeFrame(self)
end

-- Used by ZPerl_TargetUpdate.lua and ZPerl_TargetEvents.lua
ZPerl.Target.UpdatePVP = UpdatePVP
ZPerl.Target.UpdateName = UpdateName
ZPerl.Target.UpdateLevel = UpdateLevel
ZPerl.Target.UpdateClassification = UpdateClassification
ZPerl.Target.UpdateType = UpdateType

-- ApplyWidth: protected; reads the config when it runs
local function ApplyWidth(self)
	local frameConf = self.conf
	local inner = (frameConf.percent and 160 or 128) + frameConf.size.width
	self:SetWidth(128 + ((frameConf.portrait and 1 or 0) * 62) + ((frameConf.percent and 1 or 0) * 32) + frameConf.size.width)
	self.nameFrame:SetWidth(inner)
	self.statsFrame:SetWidth(inner)
	ZPerl.SetScale(self, frameConf.scale)
end

-- ZPerl.Target.SetWidth
function ZPerl.Target.SetWidth(self)
	self.conf.size.width = max(0, self.conf.size.width or 0)
	if self.conf.percent then
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()
	else
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
	end
	self.conf.scale = self.conf.scale or 0.8
	ZPerl.AfterCombatFor(ApplyWidth, self)
end


-- ApplyEnable: protected
local function ApplyEnable(self)
	if (self.conf.enable) then
		-- Blizzard's focus frame is hidden only while Z-Perl's is on; it comes back after a reload
		if (self == ZPerl_Focus and not self.blizzOff) then
			self.blizzOff = true
			ZPerl.BlizzFrameDisable(FocusFrame)
		end
		RegisterUnitWatch(self)
	else
		self:Hide()
		UnregisterUnitWatch(self)
	end
end

-- ZPerl.Target.SetBits
function ZPerl.Target.SetBits(self)
	local d = ZPerl.Dev; if d and d.listener then d.Emit("redisplay.target") end
	if self.off then
		return
	end

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

	if self == ZPerl_Target then
		ZPerl.RegisterPrediction(self, tconf, "TargetHeal")
	end
	if self == ZPerl_Focus then
		ZPerl.RegisterPrediction(self, fconf, "TargetHeal")
	end
	ZPerl.Target.SetWidth(self)

	ZPerl.AfterCombatFor(ApplyEnable, self)

	if (self == ZPerl_Target) then
		ZPerl.Target.RegisterComboEvents(self)
	end

	ZPerl.StatsFrameSetup(self)

	if (self:IsShown()) then
		ZPerl.Target.UpdateDisplay(self)
	end
end
