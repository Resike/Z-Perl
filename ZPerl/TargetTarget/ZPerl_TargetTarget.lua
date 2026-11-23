-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

-- Upvalues
local max = max
local strfind = strfind
local tonumber = tonumber

local CreateFrame = CreateFrame
local GetDifficultyColor = GetCreatureDifficultyColor or GetQuestDifficultyColor
local RegisterUnitWatch = RegisterUnitWatch
local UnitAffectingCombat = UnitAffectingCombat
local UnitCanAttack = UnitCanAttack
local UnitClassification = UnitClassification
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsAFK = UnitIsAFK
local UnitIsCharmed = UnitIsCharmed
local UnitIsConnected = UnitIsConnected
local UnitIsFriend = UnitIsFriend
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll
local UnitIsVisible = UnitIsVisible
local UnitLevel = UnitLevel
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnregisterUnitWatch = UnregisterUnitWatch

local UIParent = UIParent

-- Secret value helpers from ZPerl.lua
local CanAccess = ZPerl.CanAccess
local IsSecret = ZPerl.IsSecret
local SafeBool = ZPerl.SafeBool
local SetAlphaFromBoolean = ZPerl.SetAlphaFromBoolean

--local feignDeath = GetSpellInfo and GetSpellInfo(5384) or (C_Spell.GetSpellInfo(5384) and C_Spell.GetSpellInfo(5384).name)

local conf
ZPerl.RequestConfig(function(new)
	conf = new
	if ZPerl_TargetTarget then
		ZPerl_TargetTarget.conf = conf.targettarget
	end
	if ZPerl_TargetTargetTarget then
		ZPerl_TargetTargetTarget.conf = conf.targettargettarget
	end
	if ZPerl_FocusTarget then
		ZPerl_FocusTarget.conf = conf.focustarget
	end
	if ZPerl_PetTarget then
		ZPerl_PetTarget.conf = conf.pettarget
	end
end, "$Revision:  $")

-- ZPerl.TargetTarget.OnLoad
function ZPerl.TargetTarget.OnLoad(self)
	self:RegisterForClicks("AnyUp")
	self:RegisterForDrag("LeftButton")
	ZPerl.SetChildMembers(self)
	-- The aura color highlight is for party and raid frames; this frame shows only the HoT highlight
	self.hotHighlightOnly = true

	self.guid = 0

	-- Events: unit events for the unit the frame hangs off (regUnit), the elements below
	local regUnit
	local extra
	if (self == ZPerl_TargetTarget) then
		self.parentid = "target"
		self.partyid = "targettarget"
		regUnit = "target"
		extra = "TargetTargetTarget"
	elseif (self == ZPerl_FocusTarget) then
		self.parentid = "focus"
		self.partyid = "focustarget"
		regUnit = "focus"
		extra = "TargetTargetFocus"
	elseif (self == ZPerl_PetTarget) then
		self.parentid = "pet"
		self.partyid = "pettarget"
		regUnit = "pet"
	else
		self.parentid = "targettarget"
		self.partyid = "targettargettarget"
		regUnit = "target"
	end

	self.regUnit = regUnit
	ZPerl.UnitFrameInit(self, {regUnit}, {"TargetTarget", "Auras"})
	if (extra) then
		ZPerl.UnitFrameEnable(self, extra)
	end
	-- The frame's own unit gets no UNIT_AURA, and regUnit's aura changes are not its auras: the
	-- poll updates them
	ZPerl.UnregisterEventSafe(self, "UNIT_AURA")
	ZPerl.RegisterPrediction(self, conf[self.partyid], "TargetTargetHeal")

	ZPerl.SecureUnitButtonOnLoad(self, self.partyid)
	ZPerl.SecureUnitButtonOnLoad(self.nameFrame, self.partyid)

	--RegisterUnitWatch(self)

	self.targetname = ""

	--ZPerl_InitFadeFrame(self)
	ZPerl.RegisterHighlight(self.highlight, 2)
	ZPerl.RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.levelFrame})

	if ZPerl.layout then
		self.conf = ZPerl.layout[self.partyid]
	end

	ZPerl_Highlight:Register(ZPerl.TargetTarget.HighlightCallback, self)

	if self == ZPerl_TargetTarget then
		ZPerl.RegisterOptionChanger(ZPerl.TargetTarget.SetBits, "TargetTarget", "targettarget")
	end

	if ZPerl_TargetTarget and ZPerl_FocusTarget and ZPerl_PetTarget and ZPerl_TargetTargetTarget then
		ZPerl.TargetTarget.OnLoad = nil
	end
end

-- ZPerl.TargetTarget.HighlightCallback
function ZPerl.TargetTarget.HighlightCallback(self, updateGUID)
	local partyid = self.partyid
	local guid = UnitGUID(partyid)
	if guid and CanAccess(guid) and guid == updateGUID and UnitIsFriend("player", partyid) then
		ZPerl_Highlight:SetHighlight(self, updateGUID)
	end
end

-------------------------
-- The Update Function --
-------------------------
local function UpdatePVP(self)
	local partyid = self.partyid
	-- Indirect units can return secret flags; no icon in that case
	local ffa, isPvP, faction = UnitIsPVPFreeForAll(partyid), UnitIsPVP(partyid), UnitFactionGroup(partyid)
	if (not CanAccess(ffa) or not CanAccess(isPvP) or (faction ~= nil and not CanAccess(faction))) then
		self.nameFrame.pvpIcon:Hide()
		return
	end
	---@diagnostic disable-next-line: secret-condition
	local pvp = self.conf.pvpIcon and ((ffa and "FFA") or (isPvP and (faction ~= "Neutral") and faction))
	if pvp then
		self.nameFrame.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		self.nameFrame.pvpIcon:Show()
	else
		self.nameFrame.pvpIcon:Hide()
	end
end

-- RaidIconUpdate
local function RaidIconUpdate(self)
	local frameRaidIcon = self.nameFrame.raidIcon
	local frameNameFrame = self.nameFrame

	ZPerl.UpdateRaidIcon(frameRaidIcon, self.partyid)

	frameRaidIcon:ClearAllPoints()
	if conf.target.raidIconAlternate then
		frameRaidIcon:SetHeight(16)
		frameRaidIcon:SetWidth(16)
		frameRaidIcon:SetPoint("CENTER", frameNameFrame, "TOPRIGHT", -5, -4)
	else
		frameRaidIcon:SetHeight(32)
		frameRaidIcon:SetWidth(32)
		frameRaidIcon:SetPoint("CENTER", frameNameFrame, "CENTER", 0, 0)
	end
end

-- ZPerl.TargetTarget.UpdateDisplay
function ZPerl.TargetTarget.UpdateDisplay(self)
	if not self.conf then
		self.conf = ZPerl.layout and ZPerl.layout[self.partyid]
		if not self.conf then
			return
		end
	end
	local partyid = self.partyid
	if not partyid then
		self.targethp = 0
		self.targethpmax = 0
		self.targetmanatype = 0
		self.targetmana = 0
		self.targetmanamax = 0
		self.afk = false
		self.guid = nil
		return
	end
	if self.conf.enable and UnitExists(self.parentid) and SafeBool(UnitIsConnected(partyid), true) then
		-- Full "First Last" (or "First-Realm") display name
		self.targetname = ZPerl.UnitFullName(partyid)
		if self.targetname then
			ZPerl_Highlight:RemoveHighlight(self)

			UpdatePVP(self)

			-- Save these, so we know whether to update the frame later
			--self.targethp = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid))
			--self.targethpmax = UnitHealthMax(partyid)
			--self.targetmanatype = UnitPowerType(partyid)
			--self.targetmana = UnitPower(partyid)
			--self.targetmanamax = UnitPowerMax(partyid)
			--self.afk = UnitIsAFK(partyid) and conf.showAFK
			self.guid = UnitGUID(partyid)

			ZPerl.SetUnitNameColor(self.nameFrame.text, partyid)

			if self.conf.level then
				local TargetTargetLevel = UnitLevel(partyid)
				local classification = UnitClassification(partyid)

				self.levelFrame.text:Show()
				self.levelFrame.skull:Hide()
				if (not CanAccess(TargetTargetLevel) or not CanAccess(classification)) then
					-- Creature levels are secret inside instances
					self.levelFrame:SetWidth(27)
					self.levelFrame.text:SetText(TargetTargetLevel)
					self.levelFrame.text:SetTextColor(1, 1, 1)
				else
					local color = GetDifficultyColor(TargetTargetLevel)
					local isBoss
					if TargetTargetLevel == -1 then
						if classification == "worldboss" then
							isBoss = true
							TargetTargetLevel = ZPerl.L["TYPE_BOSS"]
						else
							self.levelFrame.text:Hide()
							self.levelFrame.skull:Show()
						end
					elseif (strfind(classification or "", "elite")) then
						TargetTargetLevel = TargetTargetLevel.."+"
						self.levelFrame:SetWidth(33)
					else
						self.levelFrame:SetWidth(27)
					end

					self.levelFrame.text:SetText(TargetTargetLevel)

					if isBoss then
						-- GetStringWidth() can be secret even
						-- for plain text (section 3 taint-propagation nuance)
						ZPerl.SafeSetWidthFromText(self.levelFrame, self.levelFrame.text, 6, 33)
						color = {r = 1, g = 0, b = 0}
					end

					self.levelFrame.text:SetTextColor(color.r, color.g, color.b)
				end
			end

			-- Set name - Must do after level as the NameFrame can change size just above here.
			local TargetTargetname = self.targetname
			self.nameFrame.text:SetText(TargetTargetname)

			-- Set health
			ZPerl.Target.UpdateHealth(self)

			-- Set mana
			if not self.statsFrame.greyMana then
				ZPerl.Target.SetManaType(self)
			end
			ZPerl.Target.SetMana(self)

			RaidIconUpdate(self)

			-- The containers' order follows the unit and its hostility; a guid that cannot be read
			-- cannot be compared, so then only a change of hostility rebuilds
			local hostile = SafeBool(UnitCanAttack("player", partyid), false)
			local guid = CanAccess(self.guid) and self.guid or nil
			if (guid ~= self.auraGuid or hostile ~= self.auraHostile) then
				self.auraGuid, self.auraHostile = guid, hostile
				ZPerl.AurasRebuild(self)
			end
			ZPerl.AurasUpdate(self)

			ZPerl.UpdateSpellRange(self, partyid)
			ZPerl_Highlight:SetHighlight(self, UnitGUID(partyid))
			return
		end
	end

	self.targetname = ""
	ZPerl_Highlight:RemoveHighlight(self)
end

-- UpdateControl
local function UpdateControl(self)
	local partyid = self.partyid
	-- Indirect units can return secret flags; no icon in that case
	if SafeBool(UnitIsVisible(partyid), false) and SafeBool(UnitIsCharmed(partyid), false) and SafeBool(UnitIsPlayer(self.partyid), false) then
		self.nameFrame.warningIcon:Show()
	else
		self.nameFrame.warningIcon:Hide()
	end
end

-- UpdateCombat
local function UpdateCombat(self)
	local inCombat = UnitAffectingCombat(self.partyid)
	if (IsSecret(inCombat)) then
		-- Let the widget resolve the secret boolean
		self.nameFrame.combatIcon:Show()
		SetAlphaFromBoolean(self.nameFrame.combatIcon, inCombat, 1, 0)
	elseif inCombat then
		self.nameFrame.combatIcon:SetAlpha(1)
		self.nameFrame.combatIcon:Show()
	else
		self.nameFrame.combatIcon:Hide()
	end
end

-- GuidChanged
local function GuidChanged(self, newGuid)
	if (not CanAccess(newGuid) or not CanAccess(self.guid)) then
		return false
	end
	return newGuid ~= self.guid
end

-- ZPerl.TargetTarget.OnUpdate
function ZPerl.TargetTarget.OnUpdate(self)
	local partyid = self.partyid

	local newGuid = UnitGUID(partyid)
	local newHP, newHPMax = UnitHealth(partyid), UnitHealthMax(partyid)
	local newManaType = UnitPowerType(partyid)
	local newMana = UnitPower(partyid)
	local newManaMax = UnitPowerMax(partyid)
	local newAFK = SafeBool(UnitIsAFK(partyid), false)

	-- ZPerl.Differs: a secret value redraws every tick
	if (conf.showAFK and newAFK ~= self.afk) or ZPerl.Differs(newHP, self.targethp) or ZPerl.Differs(newHPMax, self.targethpmax) then
		ZPerl.Target.UpdateHealth(self)
	end

	if (newManaType ~= self.targetmanatype) then
		ZPerl.Target.SetManaType(self)
		ZPerl.Target.SetMana(self)
	end

	if ZPerl.Differs(newMana, self.targetmana) or ZPerl.Differs(newManaMax, self.targetmanamax) then
		ZPerl.Target.SetMana(self)
	end

	if (GuidChanged(self, newGuid)) then
		ZPerl.TargetTarget.UpdateDisplay(self)
	end
end

-- ZPerl.TargetTarget.OnSlowUpdate: the 0.5 s poll of combat, control, PvP, auras, name color, range.
-- Target-of-target units get no UNIT_AURA or other unit events, so their auras are polled here.
function ZPerl.TargetTarget.OnSlowUpdate(self)
	local partyid = self.partyid
	UpdateCombat(self)
	UpdateControl(self)
	UpdatePVP(self)
	ZPerl.AurasUpdate(self)
	ZPerl.SetUnitNameColor(self.nameFrame.text, partyid)
	ZPerl.UpdateSpellRange(self, partyid)
	if (not CanAccess(UnitGUID(partyid))) then
		-- Secret GUID: target changes cannot be spotted, so refresh here
		ZPerl.TargetTarget.UpdateDisplay(self)
	end
end

-- ZPerl.TargetTarget.TargetTargetTargetOnUpdate
function ZPerl.TargetTarget.TargetTargetTargetOnUpdate(self)
	local partyid = self.partyid

	local newGuid = UnitGUID(partyid)
	local newHP, newHPMax = UnitHealth(partyid), UnitHealthMax(partyid)
	local newManaType = UnitPowerType(partyid)
	local newMana = UnitPower(partyid)
	local newAFK = SafeBool(UnitIsAFK(partyid), false)

	if (conf.showAFK and newAFK ~= self.afk) or ZPerl.Differs(newHP, self.targethp) or ZPerl.Differs(newHPMax, self.targethpmax) then
		ZPerl.Target.UpdateHealth(self)
	end

	if (newManaType ~= self.targetmanatype) then
		ZPerl.Target.SetManaType(self)
		ZPerl.Target.SetMana(self)
	end

	if ZPerl.Differs(newMana, self.targetmana) then
		ZPerl.Target.SetMana(self)
	end

	if (GuidChanged(self, newGuid)) then
		ZPerl.TargetTarget.UpdateDisplay(self)
	end
end

-- The polls of the frames whose own unit has no unit events, on the scheduler (they ran every frame).
local function poll(frame, func)
	if (frame and frame.partyid and frame:IsVisible()) then
		func(frame)
	end
end
ZPerl.Every(0.2, function()
	poll(ZPerl_TargetTarget, ZPerl.TargetTarget.OnUpdate)
	poll(ZPerl_FocusTarget, ZPerl.TargetTarget.OnUpdate)
	poll(ZPerl_PetTarget, ZPerl.TargetTarget.OnUpdate)
	poll(ZPerl_TargetTargetTarget, ZPerl.TargetTarget.TargetTargetTargetOnUpdate)
end)
ZPerl.Every(0.5, function()
	poll(ZPerl_TargetTarget, ZPerl.TargetTarget.OnSlowUpdate)
	poll(ZPerl_FocusTarget, ZPerl.TargetTarget.OnSlowUpdate)
	poll(ZPerl_PetTarget, ZPerl.TargetTarget.OnSlowUpdate)
	poll(ZPerl_TargetTargetTarget, ZPerl.TargetTarget.OnSlowUpdate)
end)

-------------------
-- Event Handler --
-------------------
-- Elements (ZPerl_Unit.lua): TargetTarget on every frame; TargetTargetTarget (the target frame's
-- target) and TargetTargetFocus (the focus frame's target) add the target/focus change.
local function refresh(self)
	ZPerl.NoFadeBars(true)
	ZPerl.TargetTarget.UpdateDisplay(self)
	if self ~= ZPerl_FocusTarget and ZPerl_FocusTarget and ZPerl_FocusTarget:IsShown() then
		ZPerl.TargetTarget.UpdateDisplay(ZPerl_FocusTarget)
	end
	ZPerl.NoFadeBars()
end
local function display(self)
	ZPerl.TargetTarget.UpdateDisplay(self)
end
-- Health and power events (the highest-rate events) update the bars only; name, level, auras and
-- the rest change with the unit, which UNIT_TARGET and the guid poll in OnUpdate refresh.
local function barsOf(frame, func)
	if frame and frame:IsShown() then
		func(frame)
	end
end
local function updateHealthBars(self)
	ZPerl.NoFadeBars(true)
	ZPerl.Target.UpdateHealth(self)
	if self ~= ZPerl_FocusTarget then
		barsOf(ZPerl_FocusTarget, ZPerl.Target.UpdateHealth)
	end
	ZPerl.NoFadeBars()
end
local function updatePowerBars(self)
	ZPerl.NoFadeBars(true)
	ZPerl.Target.SetMana(self)
	if self ~= ZPerl_FocusTarget then
		barsOf(ZPerl_FocusTarget, ZPerl.Target.SetMana)
	end
	ZPerl.NoFadeBars()
end

ZPerl.Elements.TargetTarget = {events = {
	RAID_TARGET_UPDATE = RaidIconUpdate,
	INCOMING_RESURRECT_CHANGED = function(self)
		ZPerl.Target.UpdateResurrectionStatus(self)
	end,
	[ZPerl.ForeverAPI.healthEvent] = updateHealthBars,
	UNIT_POWER_FREQUENT = updatePowerBars,
	UNIT_TARGET = refresh,
}}
-- On while the heal prediction option is on (ZPerl.RegisterPrediction); refreshes on the unit the
-- frame hangs off
ZPerl.Elements.TargetTargetHeal = {events = {
	UNIT_HEAL_PREDICTION = function(self, unit)
		if unit == self.regUnit and self.conf.healprediction then
			refresh(self)
		end
	end,
}}
-- A new target changes the target's target, so every shown field is stale: the full display is the update
ZPerl.Elements.TargetTargetTarget = {events = {PLAYER_TARGET_CHANGED = display}}
ZPerl.Elements.TargetTargetFocus = {events = {PLAYER_FOCUS_CHANGED = display}}

-- EnableDisable
local function EnableDisable(self)
	if self.conf.enable then
		if not self.virtual then
			RegisterUnitWatch(self)
		end
	else
		UnregisterUnitWatch(self)
		self:Hide()
	end
end

-- ApplyWidth: protected; reads the config when it runs
local function ApplyWidth(self)
	local width = (self.conf.percent and 160 or 128) + self.conf.size.width
	self:SetWidth(width)
	self.nameFrame:SetWidth(width)
	self.statsFrame:SetWidth(width)
	ZPerl.SetScale(self, self.conf.scale)
end

-- ZPerl.TargetTarget.SetWidth
function ZPerl.TargetTarget.SetWidth(self)

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

	ZPerl.StatsFrameSetup(self)
end

-- Set
local function Set(self)
	if not self.conf then
		self.conf = ZPerl.layout and ZPerl.layout[self.partyid]
		if not self.conf then
			return
		end
	end
	ZPerl.RegisterPrediction(self, self.conf, "TargetTargetHeal")
	if self.conf.level then
		self.levelFrame:Show()
		self.levelFrame:SetWidth(27)
	else
		self.levelFrame:Hide()
	end

	if self.conf.mana then
		self.statsFrame.manaBar:Show()
		self.statsFrame:SetHeight(40)
	else
		self.statsFrame.manaBar:Hide()
		self.statsFrame:SetHeight(30)
	end

	if self.conf.values then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
	else
		self.statsFrame.healthBar.text:Hide()
		self.statsFrame.manaBar.text:Hide()
	end

	self.conf.buffs.size = tonumber(self.conf.buffs.size) or 20

	ZPerl.TargetTarget.SetWidth(self)

	ZPerl.AfterCombatFor(EnableDisable, self)

	-- An option may have changed what the containers show; the display builds them for a new unit
	if (self.buffContainer) then
		ZPerl.AurasRebuild(self)
		ZPerl.AurasUpdate(self)
	end

	if self:IsShown() then
		ZPerl.TargetTarget.UpdateDisplay(self)
	end
end

-- ShowPetTarget: protected
local function ShowPetTarget()
	ZPerl_PetTarget:Show()
end

-- ZPerl.TargetTarget.SetBits
function ZPerl.TargetTarget.SetBits()
	local d = ZPerl.Dev; if d and d.listener then d.Emit("redisplay.targettarget") end
	if not ZPerl_TargetTarget then
		return
	end

	if conf.targettargettarget.enable then
		if not ZPerl_TargetTargetTarget then
			local ttt = CreateFrame("Button", "ZPerl_TargetTargetTarget", UIParent, "ZPerl_TargetTarget_Template")
			ZPerl.PlaceFrame(ttt)
		end
	end

	if conf.focustarget.enable then
		if not ZPerl_FocusTarget then
			local ft = CreateFrame("Button", "ZPerl_FocusTarget", UIParent, "ZPerl_TargetTarget_Template")
			ZPerl.PlaceFrame(ft)
		end
	end

	if conf.pettarget.enable and ZPerl_Player_Pet then
		if not ZPerl_PetTarget then
			local pt = CreateFrame("Button", "ZPerl_PetTarget", ZPerl_Player_Pet, "ZPerl_TargetTarget_Template")
			ZPerl.PlaceFrame(pt)
		end
		ZPerl.AfterCombat(ShowPetTarget)
	end

	Set(ZPerl_TargetTarget)
	if ZPerl_TargetTargetTarget then
		Set(ZPerl_TargetTargetTarget)
	end
	if ZPerl_FocusTarget then
		Set(ZPerl_FocusTarget)
	end
	if ZPerl_PetTarget then
		Set(ZPerl_PetTarget)
	end
end
