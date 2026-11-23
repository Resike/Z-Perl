-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local Events = { }
local conf, pconf
ZPerl.RequestConfig(function(new)
	conf = new
	pconf = conf.player
end, "$Revision:  $")

-- Upvalues
local floor = floor
local geterrorhandler = geterrorhandler
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local max = max
local min = min
local pcall = pcall
local select = select

local C_Timer = C_Timer
local C_XMLUtil = C_XMLUtil
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local Mixin = Mixin
local UnitClass = UnitClass
local UnitHasVehiclePlayerFrameUI = UnitHasVehiclePlayerFrameUI
local UnitHealthMax = UnitHealthMax
local UnitInVehicle = UnitInVehicle
local UnitOnTaxi = UnitOnTaxi
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitStagger = UnitStagger

local BackdropTemplateMixin = BackdropTemplateMixin
local Enum = Enum

local GameTooltip = GameTooltip
local PlayerBottomManagedFrameContainer = PlayerBottomManagedFrameContainer
local PlayerFrame = PlayerFrame
local PlayerFrameBottomManagedFramesContainer = PlayerFrameBottomManagedFramesContainer
local TotemFrame = TotemFrame

-- Update functions of ZPerl_Player.lua
local UpdateAssignedRoles = ZPerl.Player.UpdateAssignedRoles
local CombatFlash = ZPerl.Player.CombatFlash
local UpdateManaType = ZPerl.Player.UpdateManaType
local UpdateLeader = ZPerl.Player.UpdateLeader
local UpdateRaidTarget = ZPerl.Player.UpdateRaidTarget
local UpdateCombat = ZPerl.Player.UpdateCombat
local UpdateName = ZPerl.Player.UpdateName
local UpdateClass = ZPerl.Player.UpdateClass
local UpdateRep = ZPerl.Player.UpdateRep
local UpdateXP = ZPerl.Player.UpdateXP
local UpdatePVPTimer = ZPerl.Player.UpdatePVPTimer
local UpdatePVP = ZPerl.Player.UpdatePVP
local CreateBar = ZPerl.Player.CreateBar
local ApplyStatsHeight = ZPerl.Player.ApplyStatsHeight
local UpdateMana = ZPerl.Player.UpdateMana
local UpdateResurrectionStatus = ZPerl.Player.UpdateResurrectionStatus
local UpdateHealth = ZPerl.Player.UpdateHealth
local UpdateLevel = ZPerl.Player.UpdateLevel
local UpdateBuffs = ZPerl.Player.UpdateBuffs
local PlayerStatusOnUpdate = ZPerl.Player.PlayerStatusOnUpdate

-- EVENTS AND STUFF

-------------------
-- Event Handler --
-------------------
-- Elements (ZPerl_Unit.lua): PlayerLoad and PlayerWorld are on from OnLoad, the rest once the
-- variables are loaded; PlayerXP follows the XP bar option.
ZPerl.Elements.PlayerLoad = {events = {}}
ZPerl.Elements.PlayerWorld = {events = {}}
ZPerl.Elements.PlayerXP = {events = {}}
ZPerl.Elements.PlayerHeal = {events = {}}
ZPerl.Elements.Player = {
	events = Events,
	units = {UNIT_ENTERED_VEHICLE = {"player"}, UNIT_EXITING_VEHICLE = {"player"}},
}

function ZPerl.Elements.PlayerWorld.events:PLAYER_ALIVE()
	ZPerl.Player.UpdateDisplay(self)
end


-- SetUnitAttribute: protected
local function SetUnitAttribute(self)
	self:SetAttribute("unit", "player")
end

-- PLAYER_ENTERING_WORLD
function ZPerl.Elements.PlayerWorld.events:PLAYER_ENTERING_WORLD()
	self.updateAFK = true

	self.partyid = "player"
	self.unit = self.partyid
	ZPerl.AfterCombat(SetUnitAttribute, self)
	if (ZPerl.ArcaneBar.SetUnit) then
		ZPerl.ArcaneBar.SetUnit(self.nameFrame, "player")
	end

	ZPerl.Player.UpdateDisplay(self)

	--C_Timer.After(0.1, function() ZPerl.Player.SetBits(self) end)
end

-- UNIT_COMBAT
function Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end
	-- Set first: the flash and hit text animate even when a later line raises on a secret amount
	self:SetScript("OnUpdate", ZPerl.Player.OnUpdate)

	if pconf.hitIndicator then
		ZPerl.HitIndicator(self, action, descriptor, damage, damageType, pconf)
	end

	if (action == "HEAL") then
		CombatFlash(self, 0, true, true)
	elseif (ZPerl.IsHit(action, damage)) then
		CombatFlash(self, 0, true)
	end
end

-- UNIT_PORTRAIT_UPDATE
function Events:UNIT_PORTRAIT_UPDATE()
	ZPerl.UnitUpdatePortrait(self, true)
end

-- VARIABLES_LOADED
function ZPerl.Elements.PlayerLoad.events:VARIABLES_LOADED()
	self.doubleCheckAFK = 2 -- Check during 2nd UPDATE_FACTION, which are the last guarenteed events to come after logging in
	ZPerl.UnitFrameDisable(self, "PlayerLoad")

	self.updateHealth = UpdateHealth
	self.updatePower = UpdateMana
	self.updatePowerType = function(frame)
		UpdateManaType(frame)
		UpdateMana(frame)
	end
	ZPerl.UnitFrameEnable(self, "Health")
	ZPerl.UnitFrameEnable(self, "Power")
	ZPerl.UnitFrameEnable(self, "Player")
end

function Events:UPDATE_EXHAUSTION()
	UpdateXP(self)
end

-- PARTY_LOOT_METHOD_CHANGED
function Events:PARTY_LOOT_METHOD_CHANGED()
	UpdateLeader(self)
end

-- PARTY_LEADER_CHANGED
function Events:PARTY_LEADER_CHANGED()
	UpdateLeader(self)
end

-- GROUP_ROSTER_UPDATE
function Events:GROUP_ROSTER_UPDATE()
	UpdateLeader(self)
end

-- PLAYER_DEAD
function Events:PLAYER_DEAD()
	UpdateHealth(self)
end

-- UNIT_NAME_UPDATE
function Events:UNIT_NAME_UPDATE()
	UpdateName(self)
end

-- UNIT_LEVEL
function Events:UNIT_LEVEL()
	UpdateLevel(self)
	UpdateXP(self)
end

-- PLAYER_XP_UPDATE
function ZPerl.Elements.PlayerXP.events:PLAYER_XP_UPDATE()
	UpdateXP(self)
end

-- UPDATE_FACTION
function Events:UPDATE_FACTION()
	UpdateRep(self)

	if (self.doubleCheckAFK) then
		if (conf and pconf) then
			self.doubleCheckAFK = self.doubleCheckAFK - 1
			if (self.doubleCheckAFK <= 0) then
				UpdateHealth(self)
				self.doubleCheckAFK = nil
			end
		end
	end
end

-- UNIT_FACTION
function Events:UNIT_FACTION()
	UpdateHealth(self)
	UpdatePVP(self)
	UpdateCombat(self)
end
Events.UNIT_FLAGS = Events.UNIT_FACTION

function Events:PLAYER_FLAGS_CHANGED()
	UpdateHealth(self)
	UpdatePVPTimer(self)
end

-- RAID_TARGET_UPDATE
function Events:RAID_TARGET_UPDATE()
	UpdateRaidTarget(ZPerl_Player)
end

-- PLAYER_TALENT_UPDATE
function Events:PLAYER_TALENT_UPDATE()
	UpdateMana(self)
end

-- UPDATE_SHAPESHIFT_FORM
function Events:UPDATE_SHAPESHIFT_FORM()
	if (ZPerl.Player.playerClass == "DRUID") or (ZPerl.Player.playerClass == "SHAMAN") or (ZPerl.Player.playerClass == "PRIEST") then
		ZPerl.Player.DruidBarUpdate(self)
	end
end

-- PLAYER_ENTER_COMBAT, PLAYER_LEAVE_COMBAT
function Events:PLAYER_ENTER_COMBAT()
	UpdateCombat(self)
end
Events.PLAYER_LEAVE_COMBAT = Events.PLAYER_ENTER_COMBAT

-- PLAYER_REGEN_ENABLED
-- The unit attribute follows the attribute driver (vehicleui), in and out of combat.
function Events:PLAYER_REGEN_ENABLED()
	UpdateCombat(self)
	UpdateBuffs(self)
end

-- PLAYER_REGEN_DISABLED
function Events:PLAYER_REGEN_DISABLED()
	UpdateCombat(self)
	UpdateBuffs(self)
end

function Events:PLAYER_UPDATE_RESTING()
	UpdateCombat(self)
	UpdateXP(self)
end

function Events:PLAYER_SPECIALIZATION_CHANGED()
	ZPerl.Player.SetBits(self)

	if ZPerl.PlayerBuffs.Position then
		ZPerl.PlayerBuffs.Position(ZPerl_Player)
	end
end

function Events:UNIT_AURA()
	UpdateBuffs(self)
end

-- PLAYER_CONTROL_LOST
function Events:PLAYER_CONTROL_LOST()
	if pconf.fullScreen.enable and not UnitOnTaxi("player") then
		ZPerl.Player.isOutOfControl = true
	end
end

-- PLAYER_CONTROL_GAINED
function Events:PLAYER_CONTROL_GAINED()
	ZPerl.Player.isOutOfControl = nil
	if (pconf.fullScreen.enable) then
		PlayerStatusOnUpdate(self)
	end
end

-- UNIT_ENTERED_VEHICLE
function Events:UNIT_ENTERED_VEHICLE(unit, showVehicle)
	if showVehicle then
		self.partyid = "vehicle"
		self.unit = self.partyid
		if ZPerl.ArcaneBar.SetUnit then
			ZPerl.ArcaneBar.SetUnit(self.nameFrame, "vehicle")
		end
		ZPerl.Player.UpdateDisplay(self)
		--ZPerl.SetUnitNameColor(self.nameFrame.text, self.partyid)
	end
end

-- UNIT_EXITING_VEHICLE
function Events:UNIT_EXITING_VEHICLE()
	if self.partyid ~= "player" then
		self.partyid = "player"
		self.unit = self.partyid
		if ZPerl.ArcaneBar.SetUnit then
			ZPerl.ArcaneBar.SetUnit(self.nameFrame, "player")
		end
		ZPerl.Player.UpdateDisplay(self)
	end
end

-- Element PlayerHeal: on while the option is on (ZPerl.RegisterPrediction)
function ZPerl.Elements.PlayerHeal.events:UNIT_HEAL_PREDICTION(unit)
	if pconf.healprediction and unit == self.partyid then
		ZPerl.SetExpectedHealth(self)
	end
end

function Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if (pconf.absorbs and unit == self.partyid) then
		ZPerl.SetExpectedAbsorbs(self)
	end
end

function Events:INCOMING_RESURRECT_CHANGED(unit)
	if unit == self.partyid then
		UpdateResurrectionStatus(self)
	end
end

-- ZPerl.Player.SetWidth
function ZPerl.Player.SetWidth(self)
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Player.SetWidth, self)
		return
	end
	pconf.size.width = max(0, pconf.size.width or 0)
	if (pconf.percent) then
		self.nameFrame:SetWidth(160 + pconf.size.width)
		self.statsFrame:SetWidth(160 + pconf.size.width)
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()

		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.percent:Show()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.percent:Show()
		end
	else
		self.nameFrame:SetWidth(128 + pconf.size.width)
		self.statsFrame:SetWidth(128 + pconf.size.width)
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.percent:Hide()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.percent:Hide()
		end
	end

	ApplyStatsHeight(self)

	self:SetWidth(128 + (pconf.portrait and 1 or 0) * 62 + (pconf.percent and 1 or 0) * 32 + pconf.size.width)
	ZPerl.SetScale(self, pconf.scale)

	ZPerl.StatsFrameSetup(self, {self.statsFrame.druidBar, self.statsFrame.xpBar, self.statsFrame.repBar})
	if (ZPerl.PlayerBuffs.Position) then
		ZPerl.PlayerBuffs.Position(self)
	end

	UpdateHealth(self)
	UpdateMana(self)
	UpdateXP(self)
end

-- MakeXPBar
local function MakeXPBar(self)
	local f = CreateBar(self, "xpBar")
	local f2 = CreateBar(self, "xpRestBar")

	f2:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	f2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

	MakeXPBar = nil
end

-- Retail class resources
-- Retail's class resource bars (combo points, holy power, chi, runes, soul shards, arcane charges, essence) are
-- parts of the PlayerFrame Z-Perl hides, and they run off PlayerFrame's events Z-Perl switches off. As the
-- earlier Z-Perl did, and as Blizzard's Personal Resource Display does, the Z-Perl player frame gets its own bar
-- made from Blizzard's template for the class, which runs on its own events, in a holder under the stats frame
-- (frame.classBar). The templates are PlayerFrame "managed" frames that hand themselves to PlayerFrame's
-- bottom container, which reparents them: ours is taken back and opts out (MakeBlizzardBar).
-- A template can be gone or renamed on a newer client, or fail in addon hands (its Lua compares power values
-- that can be secret). Then Z-Perl draws the points itself (MakePoints): one StatusBar per point with a
-- one-point range, fed the raw power, which works with secret values. The switch happens when the template is
-- missing, or when the Blizzard bar is hidden or has no points while the class and spec should show some.
-- Blizzard's TotemFrame (totems, also the paladin's and death knight's summons) is moved under the holder, also
-- in combat (it is not protected). All off with player.classBar.
local ClassBarTemplates = {
	-- No size: the layout sizes it to its six runes (139 wide), so TOP is the runes' centre. aboveY: raised
	-- that much more in the Above position, where the runes' height would reach down over the name frame
	DEATHKNIGHT = {template = "RuneFrameTemplate", y = -3, scale = 0.95, aboveY = 7,
		tip = {"COMBAT_TEXT_RUNE_DEATH", "RUNES_TOOLTIP"}},
	DRUID = {template = "DruidComboPointBarTemplate", y = -6, aboveY = 10, power = "ComboPoints", cap = 5, form = "Energy", color = {1, 0.78, 0},
		tip = {"COMBO_POINTS_POWER", "COMBO_POINTS_DRUID_TOOLTIP"}},
	EVOKER = {template = "EssencePlayerFrameTemplate", y = -2, aboveY = 7, power = "Essence", cap = 6, color = {0.3, 0.85, 0.9},
		tip = {"POWER_TYPE_ESSENCE", "ESSENCE_TOOLTIP"}},
	MAGE = {template = "MageArcaneChargesFrameTemplate", y = -4, aboveY = 10, mixin = "MagePowerBar", power = "ArcaneCharges", cap = 4, spec = 1, color = {0.6, 0.45, 1},
		tip = {"ARCANE_CHARGES", "ARCANE_CHARGES_TOOLTIP"}},
	MONK = {template = "MonkHarmonyBarFrameTemplate", y = -5, aboveY = 7, power = "Chi", cap = 6, spec = 3, color = {0.6, 1, 0.85},
		tip = {"CHI_POWER", "CHI_TOOLTIP"}},
	PALADIN = {template = "PaladinPowerBarFrameTemplate", y = 3, aboveY = 14, power = "HolyPower", cap = 5, color = {0.95, 0.9, 0.6},
		tip = {"HOLY_POWER", "HOLY_POWER_TOOLTIP"}},
	ROGUE = {template = "RogueComboPointBarTemplate", y = -2, aboveY = 9, power = "ComboPoints", cap = 7, color = {1, 0.78, 0},
		tip = {"COMBO_POINTS_POWER", "COMBO_POINTS_ROGUE_TOOLTIP"}},
	-- aboveY: its 30 tall shards would reach 12 down over the name frame in the Above position
	WARLOCK = {template = "WarlockPowerFrameTemplate", y = -2, aboveY = 13, power = "SoulShards", cap = 5, color = {0.65, 0.4, 0.95},
		tip = {"SOUL_SHARDS_POWER", "SOUL_SHARDS_TOOLTIP"}},
}

-- Tooltip of the class bar (player.classBarTooltip, off by default): Blizzard's own title and text for the
-- resource (the names of Blizzard's global strings are in info.tip). Off, the bar ignores the mouse.
local function ClassBarTipEnter(bar)
	local tip = bar.zperlTip
	local title, text = tip and _G[tip[1]], tip and _G[tip[2]]
	if (not title) then
		return
	end
	if (pconf.classBarPos == "TOP") then
		-- Above the frame: the tooltip opens up and right from the bar's top right corner, off the frame
		GameTooltip:SetOwner(bar, "ANCHOR_NONE")
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOMLEFT", bar, "TOPRIGHT")
	else
		GameTooltip:SetOwner(bar, "ANCHOR_BOTTOMRIGHT")
	end
	GameTooltip:SetText(title, 1, 1, 1)
	if (text) then
		GameTooltip:AddLine(text, nil, nil, nil, true)
	end
	GameTooltip:Show()
end

local function ClassBarTipLeave()
	GameTooltip:Hide()
end

local function ClassBarTooltip(holder)
	local bar, info = holder.bar, holder.info
	if (not bar or not info) then
		return
	end
	local on = pconf.classBarTooltip and info.tip and true or false
	bar.zperlTip = info.tip
	bar:SetScript("OnEnter", on and ClassBarTipEnter or nil)
	bar:SetScript("OnLeave", on and ClassBarTipLeave or nil)
	bar:EnableMouse(on)
	if (not on and GameTooltip:IsOwned(bar)) then
		GameTooltip:Hide()
	end
end
-- Stands in for PlayerBottomManagedFrameContainer as the layoutParent of our bars
local unmanaged = {AddManagedFrame = function() end, RemoveManagedFrame = function() end}
local totemMoving
local CanAccess = ZPerl.CanAccess
local GetSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization

local function TotemAnchor(self)
	local totems = TotemFrame
	local wanted = pconf.classBar and not self.off
	if (not wanted and not self.totemsMoved) then
		return
	end
	totemMoving = true
	totems:ClearAllPoints()
	if (wanted) then
		totems:SetParent(self.classBar)
		-- Under the frame, below the class bar's default spot when that is under the frame too; anchored to the
		-- frame, not the bar, so the class bar's X / Y offsets leave the totems where they are
		local below = (pconf.classBarPos ~= "TOP") and self.classBar:GetHeight() or 0
		totems:SetPoint("TOP", self.statsFrame, "BOTTOM", 0, 2 - below)
	else
		-- Blizzard's container takes it back the next time it shows
		totems:SetParent(PlayerBottomManagedFrameContainer or PlayerFrameBottomManagedFramesContainer or PlayerFrame)
	end
	totemMoving = nil
	self.totemsMoved = wanted
end

-- Mirror: the class bar flipped left to right (player.classBarMirror) and/or top to bottom
-- (player.classBarMirrorV). Left to right, a layout bar (all but the paladin's) lays its points out right to
-- left. Every other frame and region of the bar has its anchors mirrored (LEFT and RIGHT swapped and x negated;
-- TOP and BOTTOM swapped and y negated), and every texture its texture coordinates swapped the same way.
-- Blizzard's code sets textures again as the points change state (SetAtlas, SetTexture, SetTexCoord), which
-- undoes the flip: hooks put it back. Points made later (a talent adding one) are taken in after each Layout.
-- State is kept per object and per direction, so switching an option off flips that direction back.
-- Flipbook animations play unflipped.
local mirrorH, mirrorV
local texH = setmetatable({}, {__mode = "k"})		-- Texture -> its coordinates are flipped left to right
local texV = setmetatable({}, {__mode = "k"})		-- Texture -> ... top to bottom
local texHooked = setmetatable({}, {__mode = "k"})
local anchorH = setmetatable({}, {__mode = "k"})	-- Frame or region -> its anchors are mirrored left to right
local anchorV = setmetatable({}, {__mode = "k"})	-- ... top to bottom
local flipping
local MIRROR_H = {LEFT = "RIGHT", RIGHT = "LEFT", TOPLEFT = "TOPRIGHT", TOPRIGHT = "TOPLEFT",
	BOTTOMLEFT = "BOTTOMRIGHT", BOTTOMRIGHT = "BOTTOMLEFT"}
local MIRROR_V = {TOP = "BOTTOM", BOTTOM = "TOP", TOPLEFT = "BOTTOMLEFT", BOTTOMLEFT = "TOPLEFT",
	TOPRIGHT = "BOTTOMRIGHT", BOTTOMRIGHT = "TOPRIGHT"}

local function ApplyTexFlip(t)
	local h, v = (texH[t] or false) ~= (mirrorH or false), (texV[t] or false) ~= (mirrorV or false)
	if (not h and not v) then
		return
	end
	local ulx, uly, llx, lly, urx, ury, lrx, lry = t:GetTexCoord()
	if (h) then
		ulx, uly, llx, lly, urx, ury, lrx, lry = urx, ury, lrx, lry, ulx, uly, llx, lly
	end
	if (v) then
		ulx, uly, llx, lly, urx, ury, lrx, lry = llx, lly, ulx, uly, lrx, lry, urx, ury
	end
	flipping = true
	t:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
	flipping = nil
	texH[t], texV[t] = mirrorH or false, mirrorV or false
end

-- Blizzard set the texture afresh: its coordinates are the unflipped ones again
local function TexReset(t)
	if (flipping) then
		return
	end
	texH[t], texV[t] = false, false
	ApplyTexFlip(t)
end

local function MirrorAnchors(obj)
	local h, v = (anchorH[obj] or false) ~= (mirrorH or false), (anchorV[obj] or false) ~= (mirrorV or false)
	if (not h and not v) then
		return
	end
	local n = obj:GetNumPoints()
	if (n == 0) then
		return
	end
	local points = {}
	for i = 1, n do
		points[i] = {obj:GetPoint(i)}
	end
	obj:ClearAllPoints()
	for _, p in ipairs(points) do
		local point, rel, relPoint, x, y = p[1], p[2], p[3], p[4] or 0, p[5] or 0
		if (h) then
			point, relPoint, x = MIRROR_H[point] or point, MIRROR_H[relPoint] or relPoint, -x
		end
		if (v) then
			point, relPoint, y = MIRROR_V[point] or point, MIRROR_V[relPoint] or relPoint, -y
		end
		obj:SetPoint(point, rel, relPoint, x, y)
	end
	anchorH[obj], anchorV[obj] = mirrorH or false, mirrorV or false
end

-- As Blizzard's LayoutFrame.lua tells a layout frame
local function IsLayoutFrame(frame)
	return frame.IsLayoutFrame ~= nil and frame:IsLayoutFrame() and true or false
end

-- MirrorWalk(obj, laidOut): every region and child of obj. laidOut: obj places its children itself (a layout
-- frame), so their anchors are its business.
local function MirrorWalk(obj, laidOut)
	for _, region in ipairs({obj:GetRegions()}) do
		if (region.GetTexCoord) then
			if (not texHooked[region]) then
				texHooked[region] = true
				-- SetAtlas and SetTexCoord set the coordinates afresh; SetTexture keeps them (still flipped), so
				-- it is not hooked: re-flipping after it would undo the mirror
				hooksecurefunc(region, "SetAtlas", TexReset)
				hooksecurefunc(region, "SetTexCoord", TexReset)
			end
			ApplyTexFlip(region)
		end
		MirrorAnchors(region)
	end
	for _, child in ipairs({obj:GetChildren()}) do
		if (not laidOut) then
			MirrorAnchors(child)
		end
		MirrorWalk(child, IsLayoutFrame(child))
	end
end

-- ClassBarMirror(holder): applies player.classBarMirror and classBarMirrorV to the Blizzard bar (Z-Perl's own
-- points read classBarMirror in UpdatePoints; flat bars look the same flipped top to bottom)
local function ClassBarMirror(holder)
	local bar = holder.blizz
	mirrorH = pconf.classBarMirror and true or false
	mirrorV = pconf.classBarMirrorV and true or false
	-- Nothing is walked or hooked until a mirror is first switched on
	if (not bar or (not mirrorH and not mirrorV and not holder.mirrorUsed)) then
		return
	end
	holder.mirrorUsed = true
	local laidOut = IsLayoutFrame(bar)
	if (laidOut) then
		bar.childLayoutDirection = mirrorH and "rightToLeft" or nil
		ZPerl.Pcall(bar.Layout, bar)
	end
	MirrorWalk(bar, laidOut)
end

-- PointsWanted(info): true when the class's points should show now (spec, druid form, a max above 0)
local function PointsWanted(info)
	local powerType = info.power and Enum.PowerType[info.power]
	if (not powerType) then
		return false
	end
	if (info.spec) then
		local spec = GetSpecialization and GetSpecialization()
		if (not CanAccess(spec) or spec ~= info.spec) then
			return false
		end
	end
	if (info.form) then
		local p = UnitPowerType("player")
		if (not CanAccess(p) or p ~= Enum.PowerType[info.form]) then
			return false
		end
	end
	local maxPower = UnitPowerMax("player", powerType)
	if (CanAccess(maxPower) and maxPower <= 0) then
		return false
	end
	return true
end

local function MakePoints(holder, info)
	local bar = CreateFrame("Frame", nil, holder)
	bar:SetHeight(10)
	bar:SetPoint("TOP", holder, "TOP", 0, -6)
	bar.points = {}
	local r, g, b = info.color[1], info.color[2], info.color[3]
	for i = 1, info.cap do
		local point = CreateFrame("StatusBar", nil, bar, BackdropTemplateMixin and "BackdropTemplate")
		point:SetSize(16, 8)
		point:SetPoint("LEFT", bar, "LEFT", (i - 1) * 18, 0)
		point:SetStatusBarTexture(ZPerl.GetBarTexture())
		point:SetMinMaxValues(i - 1, i)
		point:SetValue(0)
		point:SetStatusBarColor(r, g, b, 1)
		if (point.SetBackdrop) then
			point:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 6})
			point:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
		end
		local background = point:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints()
		background:SetColorTexture(0.06, 0.06, 0.06, 0.9)
		bar.points[i] = point
	end
	return bar
end

local function UpdatePoints(bar, info)
	if (not PointsWanted(info)) then
		bar:Hide()
		return
	end
	local powerType = Enum.PowerType[info.power]
	local shown = info.cap
	local maxPower = UnitPowerMax("player", powerType)
	if (CanAccess(maxPower) and maxPower > 0) then
		shown = min(info.cap, maxPower)
	end
	-- May be secret: only StatusBar:SetValue sees it
	local power = UnitPower("player", powerType)
	local mirror = pconf.classBarMirror
	for i, point in ipairs(bar.points) do
		if (i <= shown) then
			-- mirrored: the first point at the right end
			point:ClearAllPoints()
			point:SetPoint("LEFT", bar, "LEFT", (mirror and (shown - i) or (i - 1)) * 18, 0)
			point:SetValue(power)
			point:Show()
		else
			point:Hide()
		end
	end
	bar:SetWidth(shown * 18 - 2)
	bar:Show()
end

-- BlizzardBarFailed(bar, info): the Blizzard bar shows nothing while the class and spec should show points
local function BlizzardBarFailed(bar, info)
	if (not PointsWanted(info) or (UnitInVehicle and UnitInVehicle("player"))) then
		return false
	end
	if (not bar:IsShown()) then
		return true
	end
	return bar.classResourceButtonTable ~= nil and #bar.classResourceButtonTable == 0
end

local function MakeBlizzardBar(holder, info)
	if (C_XMLUtil and C_XMLUtil.GetTemplateInfo and not C_XMLUtil.GetTemplateInfo(info.template)) then
		return nil
	end
	local ok, bar = pcall(CreateFrame, "Frame", "ZPerl_ClassBar", holder, info.template)
	if (not ok) then
		geterrorhandler()(bar)
		return nil
	end
	-- As Blizzard's Personal Resource Display does with its own copy: the managed-frame template has already
	-- handed the bar to PlayerFrame's container (reparented there, inside the hidden PlayerFrame) before
	-- CreateFrame returns, so it is taken back; ignoreFramePositionManager stops the container doing that again,
	-- and the bar must not hide itself for Edit Mode's "Hide class info on player frame" (the PRD shows it).
	bar:SetParent(holder)
	bar.ignoreFramePositionManager = true
	bar.layoutParent = unmanaged
	bar.canBeHiddenByPersonalResourceDisplay = false
	bar.hiddenByPersonalResourceDisplay = false
	bar.unit = "player"
	if (info.mixin and _G[info.mixin]) then
		Mixin(bar, _G[info.mixin])
	end
	if (info.scale) then
		bar:SetScale(info.scale)
	end
	-- A layout frame sizes itself to its points: then its TOP anchor centres them on the stats frame
	if (bar.Layout) then
		ZPerl.Pcall(bar.Layout, bar)
	end
	bar:ClearAllPoints()
	bar:SetPoint("TOP", holder, "TOP", info.x or 0, info.y or 0)
	-- Anything of Blizzard's that moves it out of the holder is undone
	local moving
	hooksecurefunc(bar, "SetParent", function(b)
		if (moving or b.zperlRetired) then
			return
		end
		moving = true
		b:SetParent(holder)
		b:ClearAllPoints()
		b:SetPoint("TOP", holder, "TOP", info.x or 0, info.y or 0)
		moving = nil
	end)
	-- Points a layout adds (max power going up) take the mirror too
	if (bar.Layout) then
		hooksecurefunc(bar, "Layout", function(b)
			if (not b.zperlRetired and holder.mirrorUsed) then
				MirrorWalk(b, IsLayoutFrame(b))
			end
		end)
	end
	return bar
end

-- Mists of Pandaria Classic has no class resource templates: its class resource frames are single named
-- frames on PlayerFrame, each running on its own events. They are borrowed, as the earlier Z-Perl did: moved
-- under the holder, kept out of PlayerFrame's managed container (ignoreFramePositionManager) and pulled back
-- whenever Blizzard's code moves them. Offsets from the earlier Z-Perl.
local MistsFrames = {
	DEATHKNIGHT = {{frame = "RuneFrame", x = 3, y = -3}},
	DRUID = {{frame = "EclipseBarFrame", y = 1}},
	MONK = {{frame = "MonkHarmonyBar", y = 18}},
	PALADIN = {{frame = "PaladinPowerBar", y = 4}},
	PRIEST = {{frame = "PriestBarFrame", y = 0}},
	WARLOCK = {{frame = "WarlockPowerFrame", y = -1}},
}

local function BorrowBar(holder, spec)
	local bar = _G[spec.frame]
	if (not bar) then
		return nil
	end
	bar.ignoreFramePositionManager = true
	local moving
	local function place(b)
		if (moving) then
			return
		end
		moving = true
		b:SetParent(holder)
		b:ClearAllPoints()
		b:SetPoint("TOP", holder, "TOP", spec.x or 0, spec.y or 0)
		moving = nil
	end
	hooksecurefunc(bar, "SetParent", place)
	hooksecurefunc(bar, "SetPoint", place)
	place(bar)
	return bar
end

-- The Brewmaster monk's stagger bar (retail and Mists Classic) is Z-Perl's own StatusBar, not Blizzard's:
-- retail's MonkStaggerBar enables itself through PlayerFrame_UpdateArt, and a copy of its template would do its
-- color arithmetic on UnitStagger in addon code, where the value can be secret; Mists' MonkStaggerBar clicks
-- its parent (PlayerFrame) on mouse up, which fails once it is moved. This one takes the raw values
-- (StatusBar:SetValue and SetMinMaxValues accept secret ones) and colors itself green, yellow and red at
-- Blizzard's thresholds (30% and 60% of max health) when the values can be read. Mirrored left to right, it
-- fills from the right. Under the chi on Mists (which shows chi for every monk), alone on retail (whose chi bar
-- is the Windwalker's).
local STAGGER_SPELL = 115069
local STAGGER_COLORS = {{0.52, 1, 0.52}, {1, 0.98, 0.72}, {1, 0.42, 0.42}}
local STAGGER_Y = ZPerl.IsMists and -22 or -6
local SPEC_BREWMASTER = SPEC_MONK_BREWMASTER or 1

local function StaggerTipEnter(bar)
	if (pconf.classBarPos == "TOP") then
		GameTooltip:SetOwner(bar, "ANCHOR_NONE")
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOMLEFT", bar, "TOPRIGHT")
	else
		GameTooltip:SetOwner(bar, "ANCHOR_BOTTOMRIGHT")
	end
	GameTooltip:SetSpellByID(STAGGER_SPELL)
	GameTooltip:Show()
end

local function StaggerValue(bar)
	local stagger, maxHealth = UnitStagger("player") or 0, UnitHealthMax("player")
	bar:SetMinMaxValues(0, maxHealth)
	bar:SetValue(stagger)
	-- The share of max health on the left, the amount on the right (Z-Perl's number ladder; a secret one is
	-- abbreviated by the client): a percent needs a division, so it shows only while the values can be read.
	-- One decimal below 10%, rounded once (ZPerl.FormatPercent's extra half step would print no stagger as 0.1%).
	bar.value:SetText(ZPerl.ShortNumber(stagger))
	if (CanAccess(stagger) and CanAccess(maxHealth)) then
		---@diagnostic disable-next-line: secret-arithmetic
		local percent = maxHealth > 0 and stagger / maxHealth or 0
		local pct = percent * 100
		if (pct <= 0) then
			bar.percent:SetText("0%")
		elseif (pct < 10) then
			bar.percent:SetFormattedText("%.1f%%", pct)
		else
			bar.percent:SetFormattedText("%d%%", floor(pct + 0.5))
		end
		bar.percent:Show()
		local c = STAGGER_COLORS[percent >= 0.6 and 3 or (percent >= 0.3 and 2 or 1)]
		if (c ~= bar.color) then
			bar.color = c
			bar:SetStatusBarColor(c[1], c[2], c[3], 1)
		end
	else
		bar.percent:Hide()
	end
end

local function StaggerOnUpdate(bar, elapsed)
	bar.elapsed = (bar.elapsed or 0) + elapsed
	if (bar.elapsed >= 0.1) then
		bar.elapsed = 0
		StaggerValue(bar)
	end
end

-- PlaceHolder(self): the class bar holder at player.classBarPos, under the stats frame (default) or on top of the
-- name frame, moved by player.classBarX / classBarY. Above, it is raised by the class's aboveY, or, while retail's
-- stagger bar shows (a Brewmaster has no chi bar there), by STAGGER_ABOVE: the stagger bar ends 4 px over the name.
local STAGGER_ABOVE = 2
local function PlaceHolder(self)
	local holder = self.classBar
	local x, y = pconf.classBarX or 0, pconf.classBarY or 0
	holder:ClearAllPoints()
	if (pconf.classBarPos == "TOP") then
		local up = holder.info and holder.info.aboveY or 0
		if (ZPerl.IsRetail and holder.stagger and holder.stagger:IsShown()) then
			up = STAGGER_ABOVE
		end
		holder:SetPoint("BOTTOMLEFT", self.nameFrame, "TOPLEFT", x, y - 2 + up)
		holder:SetPoint("BOTTOMRIGHT", self.nameFrame, "TOPRIGHT", x, y - 2 + up)
	else
		holder:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", x, y + 2)
		holder:SetPoint("TOPRIGHT", self.statsFrame, "BOTTOMRIGHT", x, y + 2)
	end
end

-- UpdateStagger(holder): shows the stagger bar for a Brewmaster out of a vehicle, applies the options to it
local function UpdateStagger(holder)
	local bar = holder.stagger
	if (not bar) then
		return
	end
	local spec = GetSpecialization and GetSpecialization()
	local vehicle = UnitHasVehiclePlayerFrameUI and UnitHasVehiclePlayerFrameUI("player")
	local wanted = CanAccess(spec) and spec == SPEC_BREWMASTER and not (CanAccess(vehicle) and vehicle)
	bar:SetReverseFill(pconf.classBarMirror and true or false)
	local tip = pconf.classBarTooltip and true or false
	bar:SetScript("OnEnter", tip and StaggerTipEnter or nil)
	bar:SetScript("OnLeave", tip and ClassBarTipLeave or nil)
	bar:EnableMouse(tip)
	if (not tip and GameTooltip:IsOwned(bar)) then
		GameTooltip:Hide()
	end
	if (wanted) then
		StaggerValue(bar)
	end
	local shown = bar:IsShown()
	bar:SetShown(wanted and true or false)
	-- A spec change shows or hides it: the holder's Above raise follows
	if (holder.owner and shown ~= bar:IsShown()) then
		PlaceHolder(holder.owner)
	end
	-- On Mists the bar sits under the chi: the holder grows so the totems (the monk's statues) go below it
	local height = (ZPerl.IsMists and wanted) and 36 or holder.baseHeight
	if (height and holder:GetHeight() ~= height) then
		holder:SetHeight(height)
		if (holder.owner and TotemFrame) then
			TotemAnchor(holder.owner)
		end
	end
end

local function MakeStagger(holder)
	local bar = CreateFrame("StatusBar", "ZPerl_StaggerBar", holder, BackdropTemplateMixin and "BackdropTemplate")
	bar:Hide()
	bar:SetHeight(12)
	bar:SetPoint("TOPLEFT", holder, "TOPLEFT", 12, STAGGER_Y)
	bar:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -12, STAGGER_Y)
	bar:SetStatusBarTexture(ZPerl.GetBarTexture())
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	local c = STAGGER_COLORS[1]
	bar.color = c
	bar:SetStatusBarColor(c[1], c[2], c[3], 1)
	if (bar.SetBackdrop) then
		bar:SetBackdrop({edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 6})
		bar:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
	end
	local background = bar:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(0.06, 0.06, 0.06, 0.9)
	-- Above the fill, in white with an outline so it reads on green, yellow and red alike
	local text = CreateFrame("Frame", nil, bar)
	text:SetAllPoints()
	text:SetFrameLevel(bar:GetFrameLevel() + 2)
	for _, key in ipairs({"value", "percent"}) do
		local fs = text:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local font, size = fs:GetFont()
		if (font) then
			fs:SetFont(font, min(size or 9, 9), "OUTLINE")
		end
		bar[key] = fs
	end
	bar.percent:SetPoint("LEFT", 4, 0)
	bar.value:SetPoint("RIGHT", -4, 0)
	bar:SetScript("OnUpdate", StaggerOnUpdate)
	holder.stagger = bar

	local events = CreateFrame("Frame", nil, holder)
	for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE",
		"UNIT_ENTERED_VEHICLE", "UNIT_EXITED_VEHICLE"}) do
		ZPerl.RegisterEventSafe(events, event)
	end
	events:SetScript("OnEvent", function()
		UpdateStagger(holder)
	end)
end

local function MakeClassBar(self)
	local holder = CreateFrame("Frame", nil, self)
	holder:Hide()
	holder:SetHeight(22)
	self.classBar = holder

	-- The class resource bars are retail's (made from templates) and Mists Classic's (borrowed); elsewhere the
	-- holder carries only the totems
	local class = select(2, UnitClass("player"))
	if (ZPerl.IsMists and MistsFrames[class]) then
		for _, spec in ipairs(MistsFrames[class]) do
			holder.bar = BorrowBar(holder, spec) or holder.bar
		end
	end
	local info = ZPerl.IsRetail and ClassBarTemplates[class] or nil
	holder.info = info
	local blizz = info and MakeBlizzardBar(holder, info)
	holder.blizz = blizz

	local function usePoints()
		if (blizz) then
			-- Retired for good: no events, hidden, and no longer pulled back into the holder
			blizz.zperlRetired = true
			blizz:UnregisterAllEvents()
			blizz:Hide()
			blizz = nil
			holder.blizz = nil
		end
		if (not holder.points) then
			holder.points = MakePoints(holder, info)
		end
		holder.bar = holder.points
		ClassBarTooltip(holder)
		UpdatePoints(holder.points, info)
	end

	-- A bar for one spec (arcane charges, chi) checks the spec in Setup, and a bar that finds the wrong spec
	-- stops listening to everything but talent updates. The bar is made when the config loads, before the
	-- client knows the spec, so Setup runs again once the spec is known and whenever it changes (Blizzard's own
	-- bar gets this from PlayerFrame's events).
	-- The switch to Z-Perl's points is for good, so a failure must still hold a moment later: between a
	-- shapeshift's or a spec change's events the bar can briefly be hidden while the class should show it.
	local confirming
	local function blizzSetup()
		if (blizz.Setup) then
			ZPerl.Pcall(blizz.Setup, blizz)
			if (blizz:IsShown() and blizz.UpdatePower) then
				ZPerl.Pcall(blizz.UpdatePower, blizz)
			end
		end
		if (info.power and not confirming and BlizzardBarFailed(blizz, info)) then
			confirming = true
			C_Timer.After(1, function()
				confirming = nil
				if (blizz and BlizzardBarFailed(blizz, info)) then
					usePoints()
				end
			end)
		end
	end

	if (blizz) then
		holder.bar = blizz
		blizzSetup()
	elseif (info and info.power) then
		usePoints()
	end

	if (info and (blizz or holder.points)) then
		for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE",
			"TRAIT_CONFIG_UPDATED", "UPDATE_SHAPESHIFT_FORM"}) do
			ZPerl.RegisterEventSafe(holder, event)
		end
		if (info.power) then
			for _, event in ipairs({"UNIT_POWER_FREQUENT", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER"}) do
				if (ZPerl.EventValid(event)) then
					holder:RegisterUnitEvent(event, "player")
				end
			end
		end
		holder:SetScript("OnEvent", function(_, event)
			if (blizz) then
				if (event ~= "UNIT_POWER_FREQUENT" and event ~= "UNIT_MAXPOWER") then
					blizzSetup()
				end
			elseif (holder.points) then
				UpdatePoints(holder.points, info)
			end
		end)
	end

	if (class == "MONK" and (ZPerl.IsRetail or ZPerl.IsMists)) then
		holder.owner = self
		MakeStagger(holder)
	end

	if (not holder.bar and not holder.stagger) then
		holder:SetHeight(1)	-- No class bar: the totems sit right under the stats frame
	end
	holder.baseHeight = holder:GetHeight()

	if (TotemFrame) then
		-- TotemFrame and its buttons are not protected, so it is taken back at once, also in combat (when
		-- totems appear and retail's container grabs it)
		hooksecurefunc(TotemFrame, "SetParent", function()
			if (not totemMoving and pconf.classBar and not self.off) then
				TotemAnchor(self)
			end
		end)
	end
end

-- On the clients without class resource bars (the Classics) only Blizzard's TotemFrame, a child of the
-- hidden PlayerFrame there too, moves under the frame: their class bar options are not shown, so the
-- defaults apply (on, below).
local function ClassBarUpdate(self)
	if (not ZPerl.IsRetail and not TotemFrame) then
		return
	end
	if (pconf.classBar and not self.classBar) then
		MakeClassBar(self)
	end
	if (self.classBar) then
		-- player.classBarPos: under the stats frame (default) or on top of the name frame, moved by
		-- player.classBarX / classBarY
		local holder = self.classBar
		PlaceHolder(self)
		ClassBarTooltip(holder)
		ClassBarMirror(holder)
		if (holder.points and holder.info) then
			UpdatePoints(holder.points, holder.info)
		end
		UpdateStagger(holder)
		holder:SetShown(pconf.classBar and true or false)
		if (TotemFrame) then
			TotemAnchor(self)
		end
	end
end

-- SetBitsLayout: the protected part of ZPerl.Player.SetBits
local function SetBitsLayout(self)
	if (pconf.portrait) then
		self.portraitFrame:Show()
		self.portraitFrame:SetWidth(62)
		self.statsFrame.resurrect:Hide()
	else
		self.portraitFrame:Hide()
		self.portraitFrame:SetWidth(3)
	end

	ZPerl.Player.SetWidth(self)

	local h1 = self.nameFrame:GetHeight() + self.statsFrame:GetHeight() - 2
	local h2 = self.portraitFrame:GetHeight()
	ZPerl.SwitchAnchor(self, "TOPLEFT")
	self:SetHeight(max(h1, h2))

	if (pconf.extendPortrait) then
		local druidBarExtra
		if (UnitPowerType(self.partyid) > 0 and not pconf.noDruidBar) and ((ZPerl.Player.playerClass == "DRUID") or (ZPerl.Player.playerClass == "PRIEST")) then
			druidBarExtra = 1
		else
			druidBarExtra = 0
		end

		self:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
		self.portraitFrame:SetHeight(62 + druidBarExtra * 10 + (((pconf.xpBar and 1 or 0) + (pconf.repBar and 1 or 0)) * 10))
	else
		self:SetHeight(62)
		self.portraitFrame:SetHeight(62)
	end
end

-- ZPerl.Player.SetBits()
function ZPerl.Player.SetBits(self)
	local d = ZPerl.Dev; if d and d.listener then d.Emit("redisplay.player") end
	if (self.off) then
		return
	end
	if (ZPerl.ArcaneBar.RegisterFrame and not self.nameFrame.castBar) then
		ZPerl.ArcaneBar.RegisterFrame(self.nameFrame, "player")
	end

	if (pconf.level) then
		self.levelFrame:Show()
	else
		self.levelFrame:Hide()
	end

	UpdateClass(self)

	if (pconf.repBar) then
		if (not self.statsFrame.repBar) then
			CreateBar(self, "repBar")
		end

		self.statsFrame.repBar:Show()
	else
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar:Hide()
		end
	end

	if (pconf.xpBar) then
		if (not self.statsFrame.xpBar) then
			MakeXPBar(self)
		end

		self.statsFrame.xpBar:Show()
		self.statsFrame.xpRestBar:Show()

		ZPerl.UnitFrameEnable(self, "PlayerXP")
	else
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar:Hide()
			self.statsFrame.xpRestBar:Hide()
		end

		ZPerl.UnitFrameDisable(self, "PlayerXP")
	end

	if (pconf.values) then
		self.statsFrame.healthBar.text:Show()
		self.statsFrame.manaBar.text:Show()
		if (self.statsFrame.druidBar) then
			self.statsFrame.druidBar.text:Show()
		end
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.text:Show()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.text:Show()
		end
	else
		self.statsFrame.healthBar.text:Hide()
		self.statsFrame.manaBar.text:Hide()
		if (self.statsFrame.druidBar) then
			self.statsFrame.druidBar.text:Hide()
		end
		if (self.statsFrame.xpBar) then
			self.statsFrame.xpBar.text:Hide()
		end
		if (self.statsFrame.repBar) then
			self.statsFrame.repBar.text:Hide()
		end
	end

	ZPerl.RegisterPrediction(self, pconf, "PlayerHeal")

	if (ZPerl.Player.playerClass == "DRUID") or (ZPerl.Player.playerClass == "SHAMAN") or (ZPerl.Player.playerClass == "PRIEST") then
		ZPerl.Player.DruidBarUpdate(self)
	end

	ZPerl.AfterCombat(SetBitsLayout, self)
	ClassBarUpdate(self)
	if (ZPerl.Player.EnergyTickSetup) then -- The Classic-based clients only
		ZPerl.Player.EnergyTickSetup(self)
	end

	self:SetAlpha(conf.transparency.frame)

	ZPerl.Player.UpdateDisplay(self)

	if (ZPerl.PlayerBuffs.PlayerBuffSetup) then
		if (self.playerBuffsOn) then
			ZPerl.PlayerBuffs.PlayerBuffSetup(ZPerl_Player)
		end
	end

	UpdateAssignedRoles(self)
end

