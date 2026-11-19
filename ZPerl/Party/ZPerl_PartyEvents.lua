-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local shared = ZPerl.Party.shared
local Events = shared.Events
local Bus = shared.Bus
local allFrames = shared.allFrames
local PartyFrames = shared.PartyFrames
local startupDone
local conf, pconf
ZPerl.RequestConfig(function(new)
	conf = new
	pconf = new.party
end, "$Revision:  $")

-- Upvalues
local ipairs = ipairs
local max = max
local pairs = pairs
local tonumber = tonumber
local wipe = wipe

local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate
local GetNumSubgroupMembers = GetNumSubgroupMembers
local InCombatLockdown = InCombatLockdown
local RegisterUnitWatch = RegisterUnitWatch
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnregisterUnitWatch = UnregisterUnitWatch
local CanAccess = ZPerl.CanAccess

local ShowHideValues = shared.ShowHideValues
local UpdateResurrectionStatus = shared.UpdateResurrectionStatus
local UpdateHealth = shared.UpdateHealth
local UpdatePlayerFlags = shared.UpdatePlayerFlags
local auraInset = shared.auraInset
local auraSideAnchor = shared.auraSideAnchor
local placeAuras = shared.placeAuras
local CombatFlash = shared.CombatFlash
local UpdateName = shared.UpdateName
local UpdateAssignedRoles = shared.UpdateAssignedRoles
local UpdateAllAssignedRoles = shared.UpdateAllAssignedRoles
local UpdatePhasingDisplays = shared.UpdatePhasingDisplays
local UpdateLeader = shared.UpdateLeader
local UpdatePVP = shared.UpdatePVP
local UpdateCombat = shared.UpdateCombat
local UpdateClass = shared.UpdateClass
local UpdateMana = shared.UpdateMana
local UpdateRange = shared.UpdateRange
local TargetRaidIcon = shared.TargetRaidIcon
local UpdateTarget = shared.UpdateTarget

local partyHeader, partyAnchor
function shared.SetAnchors(header, anchor) -- set by ZPerl.Party.OnLoad
	partyHeader, partyAnchor = header, anchor
end

-- ZPerl.Party.OnUpdate
function ZPerl.Party.OnUpdate(self, elapsed)
	local partyid = self.partyid
	if not partyid then
		return
	end

	local feedback = pconf.hitIndicator
	if feedback then
		CombatFeedback_OnUpdate(self, elapsed)
	end

	if (self.PlayerFlash) then
		CombatFlash(self, elapsed, false)
	end
	ZPerl.OnUpdateIdle(self, feedback)
end

-- The poll of the party frames on the scheduler (it ran in OnUpdate). OnUpdate keeps the hit indicator and
-- the combat flash.
-- Every 0.2 s: the range checks (no event reports a unit's distance) and the target frame. The target frame redraws whole each tick on
-- purpose: partyN-target has no unit events for health, combat or name color (UNIT_TARGET and
-- RAID_TARGET_UPDATE cover a target change and its icon), and the redraw is a few setters per frame.
local function PollFrames()
	for _, self in ipairs(allFrames) do
		local partyid = self.partyid
		if (partyid and self:IsVisible()) then
			local targetid = self.targetid
			if pconf.range30yard then
				UpdateRange(self, partyid)
			end

			if conf.rangeFinder.enabled then
				ZPerl.UpdateSpellRange(self, partyid)
				ZPerl.UpdateSpellRange(self.targetFrame, targetid)
			end

			if (self.targetFrame:IsShown()) then
				UpdateTarget(self)
			end
		end
	end
end

ZPerl.Every(0.2, PollFrames)
-- No flag poll: UpdatePlayerFlags reads only AFK and DND, which PLAYER_FLAGS_CHANGED (Bus, below) carries
-- for the unit; UpdateDisplay reads them when a frame fills, and the party applier (SetBits1) re-runs it.

-- ZPerl.Party.UpdateDisplayAll
function ZPerl.Party.UpdateDisplayAll()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			ZPerl.Party.UpdateDisplay(frame)
		end
	end
end

-- ZPerl.Party.UpdateDisplay
function ZPerl.Party.UpdateDisplay(self, less)
	local partyid = self.partyid
	if not partyid then
		return
	end
	if not UnitExists(partyid) then
		return
	end

	self.afk, self.dnd = nil, nil
	UpdateName(self)
	TargetRaidIcon(self)
	UpdateLeader(self)
	UpdateClass(self)
	UpdateAssignedRoles(self)
	UpdatePhasingDisplays(self)

	if (not less) then
		ZPerl.SetManaBarType(self)
		UpdateMana(self)
		UpdateHealth(self)
		ZPerl.UnitUpdateLevel(self)
	end

	UpdatePlayerFlags(self)
	UpdateCombat(self)
	UpdatePVP(self)
	ZPerl.UnitUpdatePortrait(self)
	ZPerl.AurasRebuild(self)
	ZPerl.AurasUpdate(self)
	if (self.conf and conf.highlightDebuffs.enable) then
		ZPerl.CheckDebuffs(self, self.partyid)
	end
	UpdateTarget(self)
	ZPerl.UnitUpdateReadyState(self)

	if pconf.range30yard then
		UpdateRange(self)
	else
		self.nameFrame.rangeIcon:Hide()
	end
	ZPerl.UpdateSpellRange(self, partyid)
end

-------------------
-- Event Handler --
-------------------
-- EnableEvents: called by OnLoad. The unit events follow the frame's unit (ZPerl.UnitFrameSetUnit,
-- from onAttrChanged); in the preview the four frames share "player" and each gets its own events.
local function updatePowerType(self)
	ZPerl.SetManaBarType(self)
	UpdateMana(self)
end
ZPerl.Party.EnableEvents = function(self)
	self.updateHealth = UpdateHealth
	self.updatePower = UpdateMana
	self.updatePowerType = updatePowerType
	self.auraInset = auraInset
	self.auraSideAnchor = auraSideAnchor
	ZPerl.UnitFrameInit(self, {self.partyid}, {"Health", "Power", "Party", "Auras"})
end

-- PARTY_LEADER_CHANGED
-- fix by Sontix this portion of code was never called becuse the even PARTY_LEDAER_CHANGED is not registered
-- because Xperl rearrange the party members order to keep always on top the leader, UpdateDisplay() was need
-- to not mess-up party frame
-- (in that function the Leader Icon is updated, so there's no need to listen to this event)
-- function Events:PARTY_LEADER_CHANGED()
--	for i,frame in pairs(PartyFrames) do
--		if (frame.partyid) then
-- 			UpdateLeader(frame)
-- 		end
-- 	end
-- end

function Bus.PARTY_LOOT_METHOD_CHANGED()
	-- UpdateLeader shows or hides the master looter icon for every loot method; the role icon anchors to it
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			UpdateLeader(frame)
			UpdateAssignedRoles(frame)
		end
	end
end

-- RAID_TARGET_UPDATE
function Bus.RAID_TARGET_UPDATE()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			TargetRaidIcon(frame)
		end
	end
end

-- READY_CHECK
function Bus.READY_CHECK()
	for i, frame in pairs(PartyFrames) do
		if (frame.partyid) then
			ZPerl.UnitUpdateReadyState(frame)
		end
	end
end

Bus.READY_CHECK_CONFIRM = Bus.READY_CHECK
Bus.READY_CHECK_FINISHED = Bus.READY_CHECK

-- UNIT_COMBAT
function Events:UNIT_COMBAT(unit, action, descriptor, damage, damageType)
	if unit ~= self.partyid then
		return
	end
	-- set first: the flash and hit text animate even when a later line raises on a secret amount
	self:SetScript("OnUpdate", ZPerl.Party.OnUpdate)

	if pconf.hitIndicator then
		ZPerl.HitIndicator(self, action, descriptor, damage, damageType, pconf)
	end

	UpdateCombat(self)
	if (action == "HEAL") then
		CombatFlash(self, 0, true, true)
	elseif (ZPerl.IsHit(action, damage)) then
		CombatFlash(self, 0, true)
	end
end

-- UNIT_MAXHEALTH
function Events:UNIT_MAXHEALTH() -- after the Health element's update
	ZPerl.UnitUpdateLevel(self) -- Level not available until we've received maxhealth
	UpdateClass(self)
end

-- UNIT_CONNECTION
function Events:UNIT_CONNECTION(unit, online)
	if (unit == self.partyid) then
		ZPerl.Party.UpdateDisplay(self)
	end
end

-- UNIT_PHASE
function Events:UNIT_PHASE(unit)
	if (unit == self.partyid) then
		ZPerl.Party.UpdateDisplay(self)
	end
end

local function updatePartyThreat(immediate)
	for unitid, frame in pairs(PartyFrames) do
		if (frame:IsShown()) then
			ZPerl.UnitThreatStatus(frame, nil, immediate)
		end
	end
end

function Bus.UNIT_THREAT_LIST_UPDATE(event, unit)
	if (unit == "target") then
		updatePartyThreat()
	end
end

function Bus.PLAYER_TARGET_CHANGED()
	if partyHeader:GetAttribute("showPlayer") then
		local f = PartyFrames["player"]
		if f then
			--ZPerl.Party.UpdateDisplay(f)
			UpdateTarget(f)
			ZPerl.UpdateSpellRange(f.targetFrame, "target")
		end
	end
	updatePartyThreat(true)
end

-- PLAYER_ENTERING_WORLD
function Bus.PLAYER_ENTERING_WORLD()
	if (not startupDone) then
		startupDone = true
		ZPerl.ProtectedCall(ZPerl.Party.SetInitialAttributes)
	end

	ZPerl.Party.UpdateDisplayAll()
end

local rosterGuids = { }
-- ZPerl.Party.GetUnitFrameByGUID
function ZPerl.Party.GetUnitFrameByGUID(guid)
	if (not guid or not CanAccess(guid)) then
		return
	end
	local unitid = rosterGuids and rosterGuids[guid]
	if (unitid) then
		return PartyFrames[unitid]
	end
end

-- Per roster event: one "party"..i string and one UnitGUID per member (at most 5); no table is built.
-- Lua interns the strings, so a repeat allocates nothing new.
local function BuildGuidMap()
	if (GetNumSubgroupMembers() > 0) then
		--rosterGuids = ZPerl.GetReusableTable()
		wipe(rosterGuids)
		if partyHeader:GetAttribute("showPlayer") then
			local guid = UnitGUID("player")
			if (guid and CanAccess(guid)) then
				rosterGuids[guid] = "player"
			end
		end
		for i = 1, GetNumSubgroupMembers() do
			local guid = UnitGUID("party"..i)
			if (guid and CanAccess(guid)) then
				---@diagnostic disable-next-line: secret-table-key
				rosterGuids[guid] = "party"..i
			end
		end
	else
		wipe(rosterGuids)
	end
end

function Bus.GROUP_ROSTER_UPDATE()
	-- a drag cannot stay attached to the cursor when its frame is hidden by the roster change
	if (not InCombatLockdown()) then
		partyAnchor:StopMovingOrSizing()
	end
	BuildGuidMap()
	-- Full refresh of every frame on purpose: the event also carries role, leader, phase and ready
	-- changes for members whose GUID is the same, a secret GUID cannot be compared, and the frames
	-- do not store the GUID they last showed. At most 5 frames, on every roster event.
	ZPerl.Party.UpdateDisplayAll()
	
	-- Hide Blizzard party frames when roster changes: kept per roster event because Blizzard's party
	-- code may re-enable PartyFrame or the compact-party CVar on a roster change (not verified); once
	-- per burst, out of combat only
	if ZPerl.Party.HideBlizzardPartyFrames then
		ZPerl.Party.HideBlizzardPartyFrames()
	end
end

-- the highlight textures are applied at login, when a frame registers after that, and by the
-- highlighttex applier, so a roster event does not re-apply them
function Bus.PLAYER_LOGIN()
	ZPerl.SetHighlights()
	Bus.GROUP_ROSTER_UPDATE()
end

-- UNIT_PORTRAIT_UPDATE
function Events:UNIT_PORTRAIT_UPDATE()
	ZPerl.UnitUpdatePortrait(self, true)
end

-- PLAYER_FLAGS_CHANGED()
function Bus.PLAYER_FLAGS_CHANGED(event, unit)
	local f = PartyFrames[unit]
	if (f) then
		UpdatePlayerFlags(f)
	end
end

function Events:INCOMING_RESURRECT_CHANGED()
	UpdateResurrectionStatus(self)
end


-- UNIT_NAME_UPDATE
function Events:UNIT_NAME_UPDATE()
	UpdateName(self)
	UpdateHealth(self) -- Flags, class etc. not available until the first UNIT_NAME_UPDATE
	UpdateClass(self)
end

-- UNIT_LEVEL
function Events:UNIT_LEVEL()
	ZPerl.UnitUpdateLevel(self)
end

-- UNIT_AURA
function Events:UNIT_AURA()
	if (self.conf and conf.highlightDebuffs.enable) then
		ZPerl.CheckDebuffs(self, self.partyid)
	end
end

-- UNIT_FACTION
function Events:UNIT_FACTION(unit)
	UpdateName(self)
	UpdateCombat(self)
	UpdatePVP(self)
	ZPerl.UnitThreatStatus(self)
end

Events.UNIT_FLAGS = Events.UNIT_FACTION

function Events:UNIT_TARGET()
	UpdateTarget(self)
	updatePartyThreat(true)
end

function Events:UNIT_HEAL_PREDICTION(unit)
	if pconf.healprediction and unit == self.partyid then
		ZPerl.SetExpectedHealth(self)
	end
end

function Events:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	if (pconf.absorbs and unit == self.partyid) then
		ZPerl.SetExpectedAbsorbs(self)
	end
end


-- CalcWidth
local function CalcWidth(self)
	--return ZPerl_party1Highlight:GetWidth()

	local w = self.statsFrame:GetWidth() or 0

	if (pconf and pconf.portrait) then
		w = w + (self.portraitFrame:GetWidth() or 0) - 2
	else
		w = w + (self.levelFrame:GetWidth() or 0) - 2
	end

	return w
end

-- CalcHeight
local function CalcHeight(self)
	--return ZPerl_party1Highlight:GetHeight()

	if (pconf and pconf.portrait) then
		return self.portraitFrame:GetHeight() + 1
	end

	local h = self.statsFrame:GetHeight()

	if (pconf and pconf.name) then
		h = h + self.nameFrame:GetHeight() - 2
	end

	return h
end

-- ZPerl.Party.SetWidth
function ZPerl.Party.SetWidth(self)
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Party.SetBits)
		return
	end

	pconf.size.width = max(0, pconf.size.width or 0)

	local width = (36 * (pconf.percent or 0)) + 122	-- 158 enabled, 122 disabled
	self.statsFrame:SetWidth(width + pconf.size.width)
	self:SetWidth(CalcWidth(self))

	self.nameFrame:SetWidth(122 + (pconf.size.width / 2))

	ZPerl.StatsFrameSetup(self)
end

-- ZPerl.Party.SetBits
function ZPerl.Party.SetBits1(self)
	if (InCombatLockdown()) then
		ZPerl.AfterCombatFor(ZPerl.Party.SetBits1, self)
		return
	end

	self.portraitFrame:ClearAllPoints()
	self.nameFrame:ClearAllPoints()
	self.levelFrame:ClearAllPoints()
	self.statsFrame:ClearAllPoints()
	self.classFrame:ClearAllPoints()
	self.levelFrame.text:ClearAllPoints()
	self.highlight:ClearAllPoints()

	if (not pconf.portrait) then
		self.portraitFrame:Hide()

		self.levelFrame:SetWidth(30)
		self.levelFrame:SetHeight(41)

		if (pconf.flip) then
			self.nameFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			self.levelFrame:SetPoint("TOPRIGHT", self.nameFrame, "BOTTOMRIGHT", 0, 3)
			self.statsFrame:SetPoint("TOPRIGHT", self.levelFrame, "TOPLEFT", 2, 0)

			self.levelFrame.text:SetPoint("BOTTOM", self.levelFrame, "BOTTOM", 0, 4)
			self.classFrame:SetPoint("TOPRIGHT", self.levelFrame, "TOPRIGHT", -5, -5)

			self.highlight:SetPoint("TOPRIGHT", self.nameFrame, "TOPRIGHT", 0, 0)
			self.highlight:SetPoint("BOTTOMLEFT", self.statsFrame, "BOTTOMLEFT", 0, 0)
		else
			self.nameFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.levelFrame:SetPoint("TOPLEFT", self.nameFrame, "BOTTOMLEFT", 0, 3)
			self.statsFrame:SetPoint("TOPLEFT", self.levelFrame, "TOPRIGHT", -2, 0)

			self.levelFrame.text:SetPoint("BOTTOM", self.levelFrame, "BOTTOM", 0, 4)
			self.classFrame:SetPoint("TOPLEFT", self.levelFrame, "TOPLEFT", 5, -5)

			self.highlight:SetPoint("TOPLEFT", self.nameFrame, "TOPLEFT", 0, 0)
			self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
		end
	else
		self.portraitFrame:Show()
		self.statsFrame.resurrect:Hide()

		self.levelFrame:SetWidth(27)
		self.levelFrame:SetHeight(22)

		if (pconf.flip) then
			self.portraitFrame:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
			self.levelFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, 0)
			self.nameFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPLEFT", 2, 0)
			self.statsFrame:SetPoint("TOPRIGHT", self.nameFrame, "BOTTOMRIGHT", 0, 3)

			self.levelFrame.text:SetPoint("CENTER", 0, 0)
			self.classFrame:SetPoint("BOTTOMLEFT", self.portraitFrame, "BOTTOMRIGHT", 0, 3)

			self.highlight:SetPoint("TOPRIGHT", self.portraitFrame, "TOPRIGHT", 0, 0)
			self.highlight:SetPoint("BOTTOMLEFT", self.statsFrame, "BOTTOMLEFT", 0, 0)
		else
			self.portraitFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
			self.levelFrame:SetPoint("TOPRIGHT", self.portraitFrame, "TOPLEFT", 2, 0)
			self.nameFrame:SetPoint("TOPLEFT", self.portraitFrame, "TOPRIGHT", -2, 0)
			self.statsFrame:SetPoint("TOPLEFT", self.nameFrame, "BOTTOMLEFT", 0, 3)

			self.levelFrame.text:SetPoint("CENTER", 0, 0)
			self.classFrame:SetPoint("BOTTOMRIGHT", self.portraitFrame, "BOTTOMLEFT", 0, 3)

			self.highlight:SetPoint("TOPLEFT", self.portraitFrame, "TOPLEFT", 0, 0)
			self.highlight:SetPoint("BOTTOMRIGHT", self.statsFrame, "BOTTOMRIGHT", 0, 0)
		end
	end

	if (pconf.level) then
		self.levelFrame.text:Show()
		self.levelFrame:Show()

		if (pconf.portrait) then
			self.levelFrame:SetWidth(27)
		else
			self.levelFrame:SetWidth(30)
		end
	else
		self.levelFrame.text:Hide()
		self.levelFrame:Hide()
	end

	if (pconf.classIcon) then
		self.classFrame:Show()
		--self.levelFrame:Show()

		if (pconf.portrait) then
			self.levelFrame:SetWidth(27)
		else
			self.levelFrame:SetWidth(30)
		end
	else
		self.classFrame:Hide()

		if (not pconf.level) then
			self.levelFrame:SetWidth(2)
			--self.levelFrame:Hide()
		end
	end

	ShowHideValues(self)

	if (pconf.percent) then
		self.statsFrame.healthBar.percent:Show()
		self.statsFrame.manaBar.percent:Show()
	else
		self.statsFrame.healthBar.percent:Hide()
		self.statsFrame.manaBar.percent:Hide()
	end

	local height = ((pconf.name or 0) * 22) + 2 -- 24 when enabled, 2 when disabled

	self.targetFrame:ClearAllPoints()
	self.nameFrame:SetHeight(height)

	if (pconf.name) then
		self.nameFrame:Show()
		if (pconf.flip) then
			self.targetFrame:SetPoint("BOTTOMRIGHT", self.nameFrame, "BOTTOMLEFT", 2, 0)
		else
			self.targetFrame:SetPoint("BOTTOMLEFT", self.nameFrame, "BOTTOMRIGHT", -2, 0)
		end
	else
		self.nameFrame:Hide()
		if (pconf.flip) then
			self.targetFrame:SetPoint("TOPRIGHT", self.statsFrame, "BOTTOMRIGHT", 2, 0)
		else
			self.targetFrame:SetPoint("TOPLEFT", self.statsFrame, "BOTTOMLEFT", -2, 0)
		end
	end

	if (pconf.target.large) then
		self.targetFrame.healthBar.text:SetTextColor(1, 1, 1)
		self.targetFrame:SetHeight(28)
		self.targetFrame.healthBar:Show()
	else
		self.targetFrame:SetHeight(20)
		self.targetFrame.healthBar:Hide()
	end

	self.targetFrame:SetWidth(pconf.target.size)
	self.targetFrame:SetAlpha(conf.transparency.frame) -- nothing else resets it once the range fader is off
	self.targetFrame.healthBar:SetAlpha(1) -- its Bars fade (the health bar is its statsFrame), for the same reason

	pconf.buffs.size = tonumber(pconf.buffs.size) or 20
	ZPerl.Party.SetWidth(self)

	if (pconf.target.enable) then
		RegisterUnitWatch(self.targetFrame)
	else
		UnregisterUnitWatch(self.targetFrame)
		self.targetFrame:Hide()
	end

	if (self:IsShown()) then
		ZPerl.Party.UpdateDisplay(self)
	end

	--ZPerl_SetTextTransparencyFrame(self)

	self.petFrame = _G["ZPerl_partypet"..self:GetID()]
	if (self.petFrame) then
		self.petFrame:ClearAllPoints()
		if (pconf.flip) then
			self.petFrame:SetPoint("TOPRIGHT", self.statsFrame, "TOPLEFT", 2, 0)
		else
			self.petFrame:SetPoint("TOPLEFT", self.statsFrame, "TOPRIGHT", -2, 0)
		end
		if (not self.petFrame.perlDebuffsHooked) then
			self.petFrame.perlDebuffsHooked = true
			-- OnShow: PartyPet's SetScript("OnShow") drops hooks, so its handler calls ZPerl.Party.PlaceAuras(perlOwner)
			self.petFrame.perlOwner = self
			self.petFrame:HookScript("OnHide", function() placeAuras(self) end)
		end
		placeAuras(self)
	end
end

-- ZPerl.Party.SetInitialAttributes()
function ZPerl.Party.SetInitialAttributes()

	partyHeader:Hide()

	ZPerl.Party.SetMainAttributes()
	ZPerl.GroupVisibilityUpdate()
end

-- ZPerl.Party.SetMainAttributes
function ZPerl.Party.SetMainAttributes()
	partyAnchor:StopMovingOrSizing()

	partyHeader:ClearAllPoints()
	-- The header adds its first child's anchor for the new point without removing the old one; two vertical or horizontal
	-- anchors size the child from the header, whose size follows its children (each pass multiplies it). It re-anchors the
	-- children when it is shown again (SetInitialAttributes hides it first).
	for _, f in pairs(PartyFrames) do f:ClearAllPoints() end
	if (pconf.anchor == "TOP") then
		partyHeader:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", 0)
		partyHeader:SetAttribute("yOffset", -pconf.spacing)
	elseif (pconf.anchor == "LEFT") then
		partyHeader:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", pconf.spacing)
		partyHeader:SetAttribute("yOffset", 0)
	elseif (pconf.anchor == "BOTTOM") then
		partyHeader:SetPoint("BOTTOMLEFT", partyAnchor, "BOTTOMLEFT", 0, 0)
		partyHeader:SetAttribute("xOffset", 0)
		partyHeader:SetAttribute("yOffset", pconf.spacing)
	elseif (pconf.anchor == "RIGHT") then
		partyHeader:SetPoint("BOTTOMRIGHT", partyAnchor, "BOTTOMRIGHT", 0, 0)
		partyHeader:SetAttribute("xOffset", -pconf.spacing)
		partyHeader:SetAttribute("yOffset", 0)
	end

	partyHeader:SetAttribute("point", pconf.anchor or "TOP")
end

-- ZPerl.Party.Virtual
function ZPerl.Party.Virtual(on)
	local virtual = ZPerl_Party_AnchorVirtual
	if (on) then
		local w = CalcWidth(ZPerl_party1)
		local h = CalcHeight(ZPerl_party1)

		virtual:ClearAllPoints()
		if (pconf.anchor == "TOP") then
			virtual:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
			virtual:SetHeight((h * 4) + (pconf.spacing * 3))
			virtual:SetWidth(w)
		elseif (pconf.anchor == "LEFT") then
			virtual:SetPoint("TOPLEFT", partyAnchor, "TOPLEFT", 0, 0)
			virtual:SetHeight(h)
			virtual:SetWidth(w * 4 + (pconf.spacing * 3))
		elseif (pconf.anchor == "BOTTOM") then
			virtual:SetPoint("BOTTOMLEFT", partyAnchor, "BOTTOMLEFT", 0, 0)
			virtual:SetHeight((h * 4) + (pconf.spacing * 3))
			virtual:SetWidth(w)
		elseif (pconf.anchor == "RIGHT") then
			virtual:SetPoint("TOPRIGHT", partyAnchor, "TOPRIGHT", 0, 0)
			virtual:SetHeight(h)
			virtual:SetWidth(w * 4 + (pconf.spacing * 3))
		end
		virtual:OnBackdropLoaded()
		virtual:SetBackdropColor(conf.color.frame.r, conf.color.frame.g, conf.color.frame.b, conf.color.frame.a)
		virtual:SetBackdropBorderColor(conf.color.border.r, conf.color.border.g, conf.color.border.b, 1)
		virtual:Lower()
		if pconf.enable then
			virtual:Show()
		else
			virtual:Hide()
		end
	else
		if ZPerl.Locked == 0 then
			if pconf.enable then
				virtual:Show()
			else
				virtual:Hide()
			end
		else
			virtual:Hide()
		end
	end
end

-- ZPerl.Party.SetBits
function ZPerl.Party.SetBits()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Party.SetBits)
		return
	end
	local d = ZPerl.Dev; if d and d.listener then d.Emit("redisplay.party") end

	ZPerl.SetScale(partyAnchor, pconf.scale)

	ZPerl_Party_SecureHeader:SetAttribute("showPlayer", pconf.showPlayer)

	ZPerl.GroupVisibilityUpdate()

	if (ZPerl.layout) then
		conf = ZPerl.layout
		pconf = ZPerl.layout.party
		for k, v in pairs(PartyFrames) do
			v.conf = pconf
			ZPerl.Party.SetBits1(v)
		end
	end

	ZPerl.Party.SetInitialAttributes()

	if (ZPerl_Party_AnchorVirtual:IsShown()) then
		ZPerl.Party.Virtual(true)
	else
		ZPerl.Party.Virtual()
	end
	UpdateAllAssignedRoles()
end
