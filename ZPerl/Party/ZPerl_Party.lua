-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local Events = { } -- Unit events, one set per frame (element Party)
local Bus = { } -- Events no frame owns (ZPerl.On)
ZPerl.Elements.Party = {events = Events}
local allFrames = { } -- Every party frame, in creation order
--local checkRaidNextUpdate
local PartyFrames = { }
local conf, pconf
ZPerl.RequestConfig(function(new)
	conf = new
	pconf = new.party
	for _, v in ipairs(allFrames) do -- Every frame: one without a unit keeps its table too
		v.conf = pconf
	end
end, "$Revision:  $")

local percD = "%d"..PERCENT_SYMBOL

-- Upvalues
local pairs = pairs
local strmatch = strmatch
local tinsert = tinsert
local tonumber = tonumber
local type = type

local CombatFeedback_Initialize = CombatFeedback_Initialize
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local SetCVar = SetCVar
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitGUID = UnitGUID
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitHealthPercent = UnitHealthPercent
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
local UnitIsVisible = UnitIsVisible
local UnitName = UnitName
local UnitPhaseReason = UnitPhaseReason

local CHAT_MSG_AFK = CHAT_MSG_AFK
local CurveConstants = CurveConstants
local UNKNOWNOBJECT = UNKNOWNOBJECT

local GameFontNormal = GameFontNormal
local GameFontNormalSmall = GameFontNormalSmall
local PartyFrame = PartyFrame

-- Secret value helpers from ZPerl.lua
local CanAccess = ZPerl.CanAccess
local IsSecret = ZPerl.IsSecret
local SetAlphaFromBoolean = ZPerl.SetAlphaFromBoolean
local SafeBool = ZPerl.SafeBool

local partyHeader
local partyAnchor

local HighlightCallback

--local feignDeath = (C_Spell and C_Spell.GetSpellInfo(5384)) and C_Spell.GetSpellInfo(5384).name or GetSpellInfo(5384)
--local spiritOfRedemption = (C_Spell and C_Spell.GetSpellInfo(27827)) and C_Spell.GetSpellInfo(27827).name or GetSpellInfo(27827)

----------------------
-- Loading Function --
----------------------
function ZPerl.Party.EventsOnLoad(self)
	for event, fn in pairs(Bus) do
		ZPerl.On(event, fn)
	end

	--partyHeader:UnregisterEvent("UNIT_NAME_UPDATE") -- IMPORTANT! Fix for WoW 2.1 UNIT_NAME_UPDATE lockup issues


	-- Hide Blizzard party frames, only while Z-Perl's are on: they come back after a reload. The
	-- "Raid-style party frames" CVar is a saved client setting, so its value from before Z-Perl turned it off
	-- is kept in ZPerlDB.compactPartyCVar and put back once the party frames are off.
	local function HideBlizzardPartyFrames()
		local on = pconf and pconf.enable
		if (not on and not (ZPerlDB and ZPerlDB.compactPartyCVar)) then
			return
		end
		-- Can't modify protected frames (or set this CVar) during combat
		if InCombatLockdown() then
			ZPerl.AfterCombat(HideBlizzardPartyFrames)
			return
		end
		if (not on) then
			ZPerl.Pcall(SetCVar, "useCompactPartyFrames", ZPerlDB.compactPartyCVar)
			ZPerlDB.compactPartyCVar = nil
			return
		end

		if _G.PartyFrame then
			ZPerl.BlizzFrameDisable(PartyFrame)
			-- Hidden with PartyFrame; only their events need stopping
			for i = 1, 4 do
				local memberFrame = PartyFrame["MemberFrame"..i]
				if memberFrame then
					memberFrame:UnregisterAllEvents()
				end
			end
		else
			-- Classic Era: four separate PartyMemberFrame1-4
			for i = 1, 4 do
				ZPerl.BlizzFrameDisable(_G["PartyMemberFrame"..i])
			end
		end

		-- Disable "Raid-style party frames" CVar only — do NOT touch CompactRaidFrameManager
		-- itself, as that also controls the Blizzard raid frames. Hiding/disabling the
		-- manager here would suppress the native raid UI even when ZPerl_RaidFrames is
		-- not loaded, or when the user has "Disable the default raid frames" turned off.
		local compact = GetCVar("useCompactPartyFrames")
		if (compact and compact ~= "0") then
			if (ZPerlDB) then
				ZPerlDB.compactPartyCVar = compact
			end
			ZPerl.Pcall(SetCVar, "useCompactPartyFrames", "0")
		end
	end

	HideBlizzardPartyFrames()
	ZPerl.Party.HideBlizzardPartyFrames = HideBlizzardPartyFrames

	ZPerl.RegisterOptionChanger(ZPerl.Party.SetBits, nil, "party")
	ZPerl_Highlight:Register(HighlightCallback, self)

	ZPerl.Party.SetBits()

	--ZPerl.Party.EventsOnLoad = nil
end

-- HighlightCallback
function HighlightCallback(self, updateGUID)
	if not updateGUID then
		return
	end

	local f = ZPerl.Party.GetUnitFrameByGUID(updateGUID)
	if (f) then
		ZPerl_Highlight:SetHighlight(f, updateGUID)
	end
end

-- SetFrameArray
-- Options preview: while the options window is open and the player is solo, every party slot
-- shows the player, so layout and aura sizes can be judged without a group. showSolo makes the
-- header put the player in child1; children 2-4 are given the player unit and stacked the way
-- SecureGroupHeader_Update stacks them. That function rewrites the children on every header
-- attribute change, so the hook below re-applies the extra slots after it.
local function LayoutPreviewSlots(header)
	if (not ZPerl.Party.Previewing or header ~= ZPerl_Party_SecureHeader) then
		return
	end
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(LayoutPreviewSlots, header)
		return
	end
	if (IsInGroup()) then
		ZPerl.Party.Preview(false)
		return
	end
	-- Per header update, but only while the options preview is open and the player is solo (the
	-- returns above). SetAttribute("unit") is the only way to give the header children the player.
	local point = header:GetAttribute("point") or "TOP"
	local relativePoint = ({TOP = "BOTTOM", BOTTOM = "TOP", LEFT = "RIGHT", RIGHT = "LEFT"})[point]
	-- As SecureGroupHeader_Update: offsets keep their own sign (it multiplies by abs(direction)).
	local xMul = (point == "LEFT" or point == "RIGHT") and 1 or 0
	local yMul = (point == "TOP" or point == "BOTTOM") and 1 or 0
	local x, y = (header:GetAttribute("xOffset") or 0) * xMul, (header:GetAttribute("yOffset") or 0) * yMul
	for i = 2, 4 do
		local child, prev = header:GetAttribute("child"..i), header:GetAttribute("child"..(i - 1))
		child:ClearAllPoints()
		child:SetPoint(point, prev, relativePoint, x, y)
		child:SetAttribute("unit", "player")
		child:Show()
	end
end
hooksecurefunc("SecureGroupHeader_Update", LayoutPreviewSlots)

function ZPerl.Party.Preview(on)
	if (not ZPerl_Party_SecureHeader) then
		return
	end
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Party.Preview, on and true or false)
		return
	end
	on = on and not IsInGroup() or nil
	if (on == ZPerl.Party.Previewing) then
		return
	end
	local header = ZPerl_Party_SecureHeader
	ZPerl.Party.Previewing = on
	if (on) then
		header:SetAttribute("showSolo", true)
		ZPerl.GroupVisibilityUpdate()
		LayoutPreviewSlots(header)
	else
		for i = 2, 4 do
			local child = header:GetAttribute("child"..i)
			child:Hide()
			child:ClearAllPoints()
			child:SetAttribute("unit", nil)
		end
		header:SetAttribute("showSolo", nil)
		ZPerl.GroupVisibilityUpdate()
	end
end

local function SetFrameArray(self, value)
	for k, v in pairs(PartyFrames) do
		if (v == self) then
			PartyFrames[k] = nil
			if (ZPerl.PartyPet.ClearFrame) then
				local petid
				if k == "player" then
					petid = "pet"
				else
					petid = "partypet"..strmatch(k, "^party(%d)")
				end
				ZPerl.PartyPet.ClearFrame(petid)
			end
		end
	end

	self.partyid = value
	ZPerl.UnitFrameSetUnit(self, value)
	if (value) then
		self.targetid = value.."target"
		PartyFrames[value] = self
		if (ZPerl.PartyPet.SetFrame) then
			local petid
			if value == "player" then
				petid = "pet"
			else
				petid = "partypet"..strmatch(value, "^party(%d)")
			end
			ZPerl.PartyPet.SetFrame(self:GetID(), petid, value)
		end
	end
end

-- onAttrChanged
local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value and value ~= "party0") then
			SetFrameArray(self, value)
			-- Names and GUIDs are only compared when readable
			local currentName, currentGUID = UnitName(value), UnitGUID(value)
			if (self.partyid ~= value or not CanAccess(currentName) or not CanAccess(currentGUID) or self.lastName ~= currentName or self.lastGUID ~= currentGUID) then
				if (conf) then
					ZPerl.Party.UpdateDisplay(self, true)
				end
			end
		else
			SetFrameArray(self)
		end
	end
end

-- ZPerl.Party.OnLoad
function ZPerl.Party.OnLoad(self)
	ZPerl.SetChildMembers(self)
	self.targetFrame.statsFrame = self.targetFrame.healthBar -- So the healthbar fades as part of pseudo statsFrame
	-- The target frame is a child of this frame, whose range fader sets its alpha: the target runs its own range
	-- fade, so it must not also fade with the member (or take the frame transparency twice)
	if (self.targetFrame.SetIgnoreParentAlpha) then
		self.targetFrame:SetIgnoreParentAlpha(true)
	end

	partyHeader = ZPerl_Party_SecureHeader
	partyAnchor = ZPerl_Party_Anchor
	ZPerl.Party.shared.SetAnchors(partyHeader, partyAnchor)

	local id = strmatch(self:GetName(), ".+(%d)")
	self:SetID(tonumber(id))
	--_G["ZPerl_party"..self:GetID()] = self

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
	tinsert(allFrames, self)
	ZPerl.Party.EnableEvents(self)

	CombatFeedback_Initialize(self, self.hitIndicator.text, 30)

	self.hitIndicator.text:SetPoint("CENTER", self.portraitFrame, "CENTER", 0, 0)

	self.nameFrame:SetAttribute("useparent-unit", true)
	self.nameFrame:SetAttribute("*type1", "target")
	self.nameFrame:SetAttribute("type2", "togglemenu")
	self:SetAttribute("*type1", "target")
	self:SetAttribute("type2", "togglemenu")

	ZPerl.RegisterClickCastFrame(self.nameFrame)
	ZPerl.RegisterClickCastFrame(self)
	ZPerl.RegisterClickCastFrame(self.targetFrame)

	self.time = 0

	ZPerl.RegisterHighlight(self.highlight, 3)
	ZPerl.RegisterHighlight(self.targetFrame, 3)
	ZPerl.RegisterPerlFrames(self, {self.nameFrame, self.statsFrame, self.portraitFrame, self.levelFrame, self.targetFrame})

	self.FlashFrames = {self.nameFrame, self.levelFrame, self.statsFrame, self.portraitFrame}

	self:SetScript("OnAttributeChanged", onAttrChanged)
	self:SetScript("OnShow", ZPerl.Party.UpdateDisplay) -- ZPerl.UnitUpdatePortrait)

	if (ZPerl.ArcaneBar.RegisterFrame) then
		if self.partyid == "player" then
			ZPerl.ArcaneBar.RegisterFrame(self.nameFrame, "party"..self.partyid)
		else
			ZPerl.ArcaneBar.RegisterFrame(self.nameFrame, self.partyid)
		end
	end

	if (ZPerl.layout) then
		self.conf = ZPerl.layout.party
	end

	ZPerl.Party.SetBits1(self)
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

-- UpdateHealPrediction
local function UpdateHealPrediction(self)
	if pconf.healprediction then
		ZPerl.SetExpectedHealth(self)
	else
		self.statsFrame.expectedHealth:Hide()
	end
end

-- UpdateAbsorbPrediction
local function UpdateAbsorbPrediction(self)
	if pconf.absorbs then
		ZPerl.SetExpectedAbsorbs(self)
	else
		self.statsFrame.expectedAbsorbs:Hide()
	end
end

local function UpdateResurrectionStatus(self)
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

-- UpdateHealth
local function UpdateHealth(self)
	if (not self.conf) then
		return
	end
	local partyid = self.partyid
	local Partyhealth, Partyhealthmax = UnitHealth(partyid), UnitHealthMax(partyid)
	local reason

	ZPerl.SetHealthBar(self)

	UpdateAbsorbPrediction(self)
	UpdateHealPrediction(self)
	UpdateResurrectionStatus(self)

	if (not UnitIsConnected(partyid)) then
		reason = L["LOC_OFFLINE"]
	else
		if (self.afk and conf.showAFK) then
			reason = CHAT_MSG_AFK
		elseif (SafeBool(UnitIsDead(partyid), false)) then
			reason = L["LOC_DEAD"]
		elseif (SafeBool(UnitIsGhost(partyid), false)) then
			reason = L["LOC_GHOST"]
		---@diagnostic disable-next-line: secret-comparison
		elseif (CanAccess(Partyhealth) and CanAccess(Partyhealthmax) and (Partyhealth == 1) and (Partyhealthmax == 1)) then
			reason = L["LOC_UPDATING"]
		end
	end

	ShowHideValues(self)
	if (reason) then
		if (pconf.percent) then
			local old = self.statsFrame.healthBar.percent:GetText()
			self.statsFrame.healthBar.percent:SetText(reason)

			-- GetStringWidth can come back secret here once this
			-- update has touched a secret health value earlier, even though
			-- `reason` itself is always a plain localized string; when that
			-- happens the width can't safely be compared, so fall back to the
			-- wider text label rather than guess
			local textWidth = self.statsFrame.healthBar.percent:GetStringWidth()
			if (IsSecret(textWidth) or textWidth > (self.statsFrame:GetWidth() - self.statsFrame.healthBar:GetWidth() - 8)) then
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
			ZPerl.SetManaBarType(self)
		end
	end
end

-- UpdatePlayerFlags(self)
local function UpdatePlayerFlags(self)
	local change
	-- A party member's own AFK/DND state can be secret too (190x in one crash
	-- batch), same shape as the sibling fixes in Player/Target.
	if (SafeBool(UnitIsAFK(self.partyid), false) and conf.showAFK) then
		if (not self.afk) then
			change = true
			self.afk = GetTime()
			self.dnd = nil
		end
	elseif (SafeBool(UnitIsDND(self.partyid), false)) then
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
		UpdateHealth(self)
	end
end

-- The aura containers. The pet frame hangs off the stats frame's outer edge (RIGHT, LEFT when flipped):
-- while it shows, a block on that side starts past it.
local function auraInset(self, side)
	local pet = self.petFrame
	if (not pet or not pet:IsShown() or side ~= (pconf.flip and "LEFT" or "RIGHT")) then
		return 0
	end
	local pe, fe
	if (side == "RIGHT") then
		pe, fe = pet:GetRight(), self:GetRight()
	else
		pe, fe = pet:GetLeft(), self:GetLeft()
	end
	if (pe and fe) then
		-- The pet frame has its own scale: compare on screen, convert to this frame's units
		local s = self:GetEffectiveScale()
		local inset = (pe * pet:GetEffectiveScale() - fe * s) / s
		if (side == "LEFT") then
			inset = -inset
		end
		if (inset > 0) then
			return inset
		end
	end
	return 0
end
-- A block on the stats frame's outer edge (RIGHT, LEFT when flipped) hangs from the stats frame's top, 4
-- down, as the original debuffs did; the name / portrait row above would put it too high.
local function auraSideAnchor(self, side)
	if (side == (pconf.flip and "LEFT" or "RIGHT")) then
		return self.statsFrame, 0, -4
	end
end
-- The pet frame shows or hides: out of combat the blocks move now, else after combat; the gate marks
-- the frame pending itself while auras are secret
local function placeAuras(self)
	if (InCombatLockdown()) then
		ZPerl.AfterCombatFor(placeAuras, self)
		return
	end
	if (not ZPerl.AuraContainerGate(self)) then
		return
	end
	ZPerl.AurasPlace(self)
end
ZPerl.Party.PlaceAuras = placeAuras

-------------------------
-- The Update Function --
-------------------------
local function CombatFlash(self, elapsed, argNew, argGreen)
	if (ZPerl.CombatFlashSet(self, elapsed, argNew, argGreen)) then
		ZPerl.CombatFlashSetFrames(self)
	end
end

-- UpdateName
local function UpdateName(self)
	local partyid = self.partyid
	local partyname = UnitName(partyid)
	self.lastName = partyname
	self.lastGUID = UnitGUID(partyid)
	if (partyname) then
		self.nameFrame.text:SetFontObject(GameFontNormal)
		-- partyname stays the bare first name for the change
		-- detection in onAttrChanged above; only the displayed text gets the
		-- full "First Last" (or "First-Realm") form
		self.nameFrame.text:SetText(ZPerl.UnitFullName(partyid))

		-- GetStringWidth() can be secret even for plain text
		-- (section 3 taint-propagation nuance); leave the font as-is when it
		-- can't be measured.
		local nameWidth = self.nameFrame.text:GetStringWidth()
		if (not IsSecret(nameWidth) and nameWidth > self.nameFrame:GetWidth() - 4) then
			self.nameFrame.text:SetFontObject(GameFontNormalSmall)
		end

		ZPerl.ColorFriendlyUnit(self.nameFrame.text, partyid)
	end
end

-- UpdateAssignedRoles
local function UpdateAssignedRoles(self)
	local unit = self.partyid
	local icon = self.nameFrame.roleIcon
	local isTank, isHealer, isDamage
	if type(UnitGroupRolesAssigned) == "function" then
		local role = SafeBool(UnitGroupRolesAssigned(unit), nil)
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

	-- Role icons option check by playerlin
	if (conf and conf.oldRoleIcons) then
		if isTank then
			icon:SetTexture("Interface\\GroupFrame\\UI-Group-MainTankIcon")
			icon:Show()
		elseif isHealer then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_RoleHealer_old")
			icon:Show()
		elseif isDamage then
			icon:SetTexture("Interface\\GroupFrame\\UI-Group-MainAssistIcon")
			icon:Show()
		else
			icon:Hide()
		end
	else
		if isTank then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_RoleTank")
			icon:Show()
		elseif isHealer then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_RoleHealer")
			icon:Show()
		elseif isDamage then
			icon:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_RoleDamage")
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
	local inPhase = type(UnitPhaseReason) == "function" and UnitPhaseReason(unit)

	if ( not inPhase or not UnitExists(unit) or not UnitIsConnected(unit)) then
		self.phasingIcon:Hide()
	else
		self.phasingIcon:Show()
	end
end

-- UpdateLeader
local function UpdateLeader(self)
	local partyid = self.partyid
	-- Same secret-boolean shape confirmed live crashing the
	-- sibling UpdateLeader; fixed proactively here.
	if (SafeBool(UnitIsGroupLeader(partyid), false)) then
		self.nameFrame.leaderIcon:Show()
	else
		self.nameFrame.leaderIcon:Hide()
	end

	-- lootMaster is the party index (0 = the player), raidMaster the raid index when in a raid
	local lootMethod, lootMaster, raidMaster = GetLootMethod()
	local isMaster = false
	if (ZPerl.IsMasterLoot(lootMethod)) then
		if (raidMaster) then
			isMaster = SafeBool(UnitIsUnit("raid"..raidMaster, partyid), false)
		elseif (lootMaster) then
			isMaster = (lootMaster == 0 and partyid == "player") or partyid == "party"..lootMaster
		end
	end
	if (isMaster) then
		self.nameFrame.masterIcon:Show()
	else
		self.nameFrame.masterIcon:Hide()
	end
	-- Removed the call to UpdateAllAssignedRoles because UpdateLeader() is called by UpdateDisplay()
	-- and UpdateDisplay() already call the UpdateAssignedRoles() function
end

-- UpdatePVP
local function UpdatePVP(self)
	local partyid = self.partyid

	local pvpIcon = self.nameFrame.pvpIcon

	local factionGroup = UnitFactionGroup(partyid)
	-- As on the Target frame: a secret faction can be neither tested nor compared
	if (not CanAccess(factionGroup)) then
		factionGroup = nil
	end

	if pconf.pvpIcon and SafeBool(UnitIsPVPFreeForAll(partyid), false) then
		pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
		pvpIcon:Show()
	elseif pconf.pvpIcon and factionGroup and factionGroup ~= "Neutral" and SafeBool(UnitIsPVP(partyid), false) then
		pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..factionGroup)

		if type(UnitIsMercenary) == "function" and SafeBool(UnitIsMercenary(partyid), false) then
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

end

-- UpdateCombat
local function UpdateCombat(self)
	local partyid = self.partyid
	if UnitIsVisible(partyid) then
		if (UnitAffectingCombat(partyid)) then
			self.nameFrame.combatIcon:Show()
		else
			self.nameFrame.combatIcon:Hide()
		end

		-- Indirect units can return secret flags; no icon in that case
		if SafeBool(UnitIsCharmed(partyid), false) and SafeBool(UnitIsPlayer(partyid), false) then
			self.nameFrame.warningIcon:Show()
		else
			self.nameFrame.warningIcon:Hide()
		end
	else
		self.nameFrame.combatIcon:Hide()
		self.nameFrame.warningIcon:Hide()
	end
end

-- UpdateClass
local function UpdateClass(self)
	local partyid = self.partyid
	if (UnitIsPlayer(partyid)) then
		local _, class = UnitClass(partyid)
		local l, r, t, b = ZPerl.ClassPos(class)
		self.classFrame.tex:SetTexCoord(l, r, t, b)
	end

	if (pconf.classIcon) then
		self.classFrame:Show()
	else
		self.classFrame:Hide()
	end
end

-- UpdateMana
local powerStyle = {percent = percD, text = "whole"}
local function UpdateMana(self)
	local partyid = self.partyid
	-- Same AFK-secrecy risk as UpdatePlayerFlags;
	-- default to "still AFK" (skip the refresh) when uncertain.
	if (self.afk and not SafeBool(UnitIsAFK(partyid), true)) then
		UpdatePlayerFlags(self)
	end

	ZPerl.PowerUpdate(self, powerStyle)

	if (not UnitIsConnected(partyid)) then
		self.statsFrame.healthBar.text:SetText(L["LOC_OFFLINE"])
		if (not self.statsFrame.greyMana) then
			self.statsFrame:SetGrey()
		end
	end
end

-- ZPerl_Party_UpdateRange
local function UpdateRange(self, overrideUnit)
	local partyid = overrideUnit or self.partyid
	if not partyid then
		return
	end
	if not pconf.range30yard then
		self.nameFrame.rangeIcon:Hide()
		return
	end
	ZPerl.UpdateRangeIcon(self.nameFrame.rangeIcon, partyid)
end

-- ZPerl.Party.SingleGroup
function ZPerl.Party.SingleGroup()
	local num = GetNumGroupMembers()
	if (num > 5) then
		return
	end
	for i = 1, num do
		local _, _, subgroup = GetRaidRosterInfo(i)
		-- nil outside a raid (the group visibility asks in a party too) and for a member not loaded yet
		if (subgroup and subgroup > 1) then
			return
		end
	end
	return true
end

-- TargetUpdateHealPrediction
local function TargetUpdateHealPrediction(self)
	if pconf.healprediction then
		ZPerl.SetExpectedHealth(self)
	else
		self.expectedHealth:Hide()
	end
end

-- TargetUpdateAbsorbPrediction
local function TargetUpdateAbsorbPrediction(self)
	if pconf.absorbs then
		ZPerl.SetExpectedAbsorbs(self)
	else
		self.expectedAbsorbs:Hide()
	end
end

-- TargetUpdateHealth
local function TargetUpdateHealth(self)
	local tf = self.targetFrame
	local targetid = self.targetid
	ZPerl.HealthSetBar(tf.healthBar, targetid, true)

	-- direct: one format for plain and secret; FormatPercent rounds a readable value and adds a decimal below 10
	tf.healthBar.text:SetFormattedText(percD, UnitHealthPercent(targetid, true, CurveConstants.ScaleTo100))
	tf.healthBar.text:Show()

	TargetUpdateAbsorbPrediction(self.targetFrame)
	TargetUpdateHealPrediction(self.targetFrame)

	if (SafeBool(UnitIsDeadOrGhost(targetid), false)) then
		tf.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
		tf.healthBar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
		if (SafeBool(UnitIsDead(targetid), false)) then
			tf.healthBar.text:SetText(L["LOC_DEAD"])
		else
			tf.healthBar.text:SetText(L["LOC_GHOST"])
		end
	else
		ZPerl.SetSmoothBarColor(tf.healthBar, targetid)
	end

	local inCombat = UnitAffectingCombat(targetid)
	if (IsSecret(inCombat)) then
		tf.combatIcon:SetTexCoord(0.49, 1.0, 0.0, 0.49)
		tf.combatIcon:Show()
		SetAlphaFromBoolean(tf.combatIcon, inCombat, 1, 0)
	elseif (inCombat) then
		tf.combatIcon:SetTexCoord(0.49, 1.0, 0.0, 0.49)
		tf.combatIcon:SetAlpha(1)
		tf.combatIcon:Show()
	else
		tf.combatIcon:Hide()
	end

	local ffa, isPvP, faction = UnitIsPVPFreeForAll(targetid), UnitIsPVP(targetid), UnitFactionGroup(targetid)
	if (not CanAccess(ffa) or not CanAccess(isPvP) or (faction ~= nil and not CanAccess(faction))) then
		tf.pvpIcon:Hide()
		return
	end
	---@diagnostic disable-next-line: secret-condition
	local pvp = pconf.pvpIcon and ((ffa and "FFA") or (isPvP and (faction ~= "Neutral") and faction))
	if (pvp) then
		tf.pvpIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..pvp)
		tf.pvpIcon:Show()
	else
		tf.pvpIcon:Hide()
	end
end


-- TargetRaidIcon
local function TargetRaidIcon(self)
	local partyid = self.partyid
	ZPerl.UpdateRaidIcon(self.targetFrame.raidIcon, partyid.."target")
	ZPerl.UpdateRaidIcon(self.nameFrame.raidIcon, partyid)
end

-- UpdateTarget
local function UpdateTarget(self)
	if (pconf.target.enable) then
		local targetid = self.targetid
		local partyid = self.partyid
		if (targetid and UnitIsConnected(partyid) and UnitExists(partyid) and UnitIsVisible(partyid)) then
			local targetname = UnitName(targetid)
			---@diagnostic disable-next-line: secret-comparison
			if (targetname and (not CanAccess(targetname) or targetname ~= UNKNOWNOBJECT)) then
				--self.targetFrame:SetAlpha(1)
				self.targetFrame.text:SetText(ZPerl.UnitFullName(targetid))
				ZPerl.SetUnitNameColor(self.targetFrame.text, targetid)
				TargetUpdateHealth(self)
				TargetRaidIcon(self)
			end
		end
	end
end

-- Locals shared with ZPerl_PartyEvents.lua, loaded next.
ZPerl.Party.shared = {
	Events = Events, Bus = Bus, allFrames = allFrames, PartyFrames = PartyFrames,
	ShowHideValues = ShowHideValues,
	UpdateResurrectionStatus = UpdateResurrectionStatus,
	UpdateHealth = UpdateHealth,
	UpdatePlayerFlags = UpdatePlayerFlags,
	auraInset = auraInset,
	auraSideAnchor = auraSideAnchor,
	placeAuras = placeAuras,
	CombatFlash = CombatFlash,
	UpdateName = UpdateName,
	UpdateAssignedRoles = UpdateAssignedRoles,
	UpdateAllAssignedRoles = UpdateAllAssignedRoles,
	UpdatePhasingDisplays = UpdatePhasingDisplays,
	UpdateLeader = UpdateLeader,
	UpdatePVP = UpdatePVP,
	UpdateCombat = UpdateCombat,
	UpdateClass = UpdateClass,
	UpdateMana = UpdateMana,
	UpdateRange = UpdateRange,
	TargetRaidIcon = TargetRaidIcon,
	UpdateTarget = UpdateTarget,
}
