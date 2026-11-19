-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

-- Upvalues
local _G = _G

local abs = abs
local floor = floor
local format = format
local ipairs = ipairs
local pairs = pairs
local sort = sort
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring

local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsInGroup = IsInGroup
local IsInInstance = IsInInstance
local IsInRaid = IsInRaid
local SecondsToTime = SecondsToTime
local UnitAffectingCombat = UnitAffectingCombat
local UnitClass = UnitClass
local UnitInRaid = UnitInRaid
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsDND = UnitIsDND
local UnitIsVisible = UnitIsVisible

local ALL = ALL
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local NONE = NONE
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR

local GameTooltip = GameTooltip
local UIParent = UIParent

local SafeBool = ZPerl.SafeBool

local Shared = ZPerl.Raid.Shared
local allFrames = Shared.allFrames
local RaidGroupCounts = Shared.RaidGroupCounts
local FrameArray = Shared.FrameArray
local raidHeaders = Shared.raidHeaders
local rebuildAuras = Shared.rebuildAuras
local Setup1RaidFrame = Shared.Setup1RaidFrame
local RaidUnitName = Shared.RaidUnitName

local conf, rconf
ZPerl.RequestConfig(function(newConf)
	conf = newConf
	rconf = conf.raid
end, "$Revision:  $")

--------------------
-- Click Handlers --
--------------------

-- ZPerl.Raid.ScaleRaid
function ZPerl.Raid.ScaleRaid()
	for frame = 1, 13 do
		local f = _G["ZPerl_Raid_Title"..frame]
		if (f) then
			ZPerl.SetScale(f, rconf.scale)
		end
	end
end

-- ZPerl.Raid.SnapToNearby
-- Called on drag-stop for a raid group title frame. Snaps the dragged frame's
-- edges to any other group title frame's edges that are within a small
-- pixel threshold, so lining groups up side-by-side or stacked doesn't need
-- pixel-perfect dragging.
local RAID_SNAP_DISTANCE = 12
function ZPerl.Raid.SnapToNearby(self)
	if (not self) then return end
	local selfWidth, selfHeight = self:GetWidth(), self:GetHeight()
	local left, top = self:GetLeft(), self:GetTop()
	if (not left or not top or not selfWidth or not selfHeight) then return end
	local right, bottom = left + selfWidth, top - selfHeight

	for i = 1, 13 do
		local other = _G["ZPerl_Raid_Title"..i]
		if (other and other ~= self and other:IsShown()) then
			local oLeft, oTop = other:GetLeft(), other:GetTop()
			local oWidth, oHeight = other:GetWidth(), other:GetHeight()
			if (oLeft and oTop and oWidth and oHeight) then
				local oRight, oBottom = oLeft + oWidth, oTop - oHeight

				-- Horizontal: align left-to-left/right-to-right (side by side
				-- in the same column) or left-to-right/right-to-left (touching)
				if (math.abs(left - oLeft) <= RAID_SNAP_DISTANCE) then
					left = oLeft
				elseif (math.abs(right - oRight) <= RAID_SNAP_DISTANCE) then
					left = oRight - selfWidth
				elseif (math.abs(left - oRight) <= RAID_SNAP_DISTANCE) then
					left = oRight
				elseif (math.abs(right - oLeft) <= RAID_SNAP_DISTANCE) then
					left = oLeft - selfWidth
				end

				-- Vertical: align top-to-top/bottom-to-bottom (same row) or
				-- top-to-bottom/bottom-to-top (stacked)
				if (math.abs(top - oTop) <= RAID_SNAP_DISTANCE) then
					top = oTop
				elseif (math.abs(bottom - oBottom) <= RAID_SNAP_DISTANCE) then
					top = oBottom + selfHeight
				elseif (math.abs(top - oBottom) <= RAID_SNAP_DISTANCE) then
					top = oBottom
				elseif (math.abs(bottom - oTop) <= RAID_SNAP_DISTANCE) then
					top = oTop - selfHeight
				end

				right, bottom = left + selfWidth, top - selfHeight
			end
		end
	end

	self:ClearAllPoints()
	self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, top - selfHeight)
end

-- ZPerl.Raid.SetGap(gap)
-- Spaces raid groups 1-8 `gap` apart within their lines: rows (titles with the same top) for the TOP and
-- BOTTOM anchors, columns (same left) for LEFT and RIGHT, where one row of unit frames hangs below each
-- title. Each line keeps its end nearest the screen edge. Stores the gap; in combat it waits for combat end.
-- line order: by position, then group number for groups on the same spot
local function before(p, q, a, b)
	if (abs(p - q) > 0.5) then return p < q end
	return a:GetID() < b:GetID()
end
function ZPerl.Raid.SetGap(gap)
	gap = tonumber(gap)
	if (not gap) then
		return
	end
	rconf.gap = gap
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Raid.SetGap, gap)
		return
	end
	ZPerl.AlignmentGridHold(true) -- the gap is exact: no snap
	local across = rconf.anchor == "TOP" or rconf.anchor == "BOTTOM"
	local lines = { }
	for i = 1, 8 do
		local f = _G["ZPerl_Raid_Title"..i]
		-- a title not laid out yet has no rect (GetTop/GetLeft nil): it keeps its place
		local pos
		if (f) then
			if (across) then
				pos = f:GetTop()
			else
				pos = f:GetLeft()
			end
		end
		if (pos and f:GetLeft() and f:GetTop()) then
			local key = floor(pos + 0.5)
			lines[key] = lines[key] or { }
			tinsert(lines[key], f)
		end
	end
	for _, line in pairs(lines) do
		local f1 = line[1]
		local toFrame = UIParent:GetEffectiveScale() / f1:GetEffectiveScale()
		if (across) then
			sort(line, function(a, b) return before(a:GetLeft(), b:GetLeft(), a, b) end)
			local step = f1:GetWidth() + gap
			local left, right = line[1]:GetLeft(), line[#line]:GetRight()
			local x = left
			if (UIParent:GetRight() * toFrame - right < left) then
				x = right - #line * step + gap
			end
			for k, f in ipairs(line) do
				local top = f:GetTop()
				f:ClearAllPoints()
				f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + (k - 1) * step, top)
				ZPerl.SavePosition(f)
			end
		else
			sort(line, function(a, b) return before(b:GetTop(), a:GetTop(), a, b) end)
			local step = f1:GetHeight() + (rconf.mana and 43 or 38) + gap
			local top, bottom = line[1]:GetTop(), line[#line]:GetTop() - step + gap
			local y = top
			if (bottom < UIParent:GetTop() * toFrame - top) then
				y = bottom + #line * step - gap
			end
			for k, f in ipairs(line) do
				local left = f:GetLeft()
				f:ClearAllPoints()
				f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, y - (k - 1) * step)
				ZPerl.SavePosition(f)
			end
		end
	end
	ZPerl.AlignmentGridHold(false)
end

-- ZPerl.Raid.SetWidth
function ZPerl.Raid.SetWidth()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Raid.SetWidth)
		return
	end
	Shared.widthApplied, Shared.widthStale = 80 + rconf.size.width, nil
	for i = 1, 13 do
		local f = _G["ZPerl_Raid_Title"..i]
		if (f) then
			f:SetWidth(80 + rconf.size.width)
			f.virtual:SetWidth(80 + rconf.size.width)
		end
		for j = 1, 40 do
			local ub = _G["ZPerl_Raid_Grp"..i.."UnitButton"..j]
			if (ub) then
				ub:SetWidth(80 + rconf.size.width)
				ub.nameFrame:SetWidth(80 + rconf.size.width)
				ub.statsFrame:SetWidth(80 + rconf.size.width)
			end
		end
	end
end

-- ZPerl.Raid.RaidTitles
function ZPerl.Raid.RaidTitles()
	-- SetWidth walks 13 x 40 global names: only when the width option changed or a button was created
	-- since the last pass (ZPerl.Raid.Position runs this on every roster burst)
	if (Shared.widthStale or Shared.widthApplied ~= 80 + rconf.size.width) then
		ZPerl.Raid.SetWidth()
	end
	local singleGroup
	if (ZPerl.Party.SingleGroup) then
		if (conf.party.smallRaid and ZPerl.Raid.Initialized) then
			singleGroup = ZPerl.Party.SingleGroup()
		end
	end

	-- A profile saved before this client's newer classes existed (or before
	-- ZPerl.DefaultRaidClasses() listed all of them) can still have fewer entries
	-- than CLASS_COUNT; repair it the same way GroupFilter() does, or the
	-- index below is nil and this errors out before finishing raid setup.
	for i = 1, Shared.CLASS_COUNT do
		if (not rconf.class[i]) then
			rconf.class = ZPerl.DefaultRaidClasses()
			break
		end
	end

	local c
	for i = 1, Shared.CLASS_COUNT do
		local confClass = rconf.class[i].name
		local frame = _G["ZPerl_Raid_Title"..i]
		local titleFrame = frame.text
		local virtualFrame = frame.virtual

		if (not rconf.sortByClass and IsInRaid() and Shared.myGroup and Shared.myGroup == i) then
			c = HIGHLIGHT_FONT_COLOR
		else
			c = NORMAL_FONT_COLOR
		end
		titleFrame:SetTextColor(c.r, c.g, c.b)

		if (rconf.sortByClass) then
			if (LOCALIZED_CLASS_NAMES_MALE[confClass]) then
				titleFrame:SetText(LOCALIZED_CLASS_NAMES_MALE[confClass])
			end
		else
			titleFrame:SetFormattedText(L["RAID_GROUP"], i)
		end

		local enable = rconf.enable
		if (enable) then
			local _, instanceType = IsInInstance()
			if (instanceType == "pvp") then
				enable = not rconf.notInBG
			end
		end

		if (ZPerl.Locked == 0 or (RaidGroupCounts[i] > 0 and enable and rconf.group[i] and not singleGroup)) then
			if (ZPerl.Locked == 0 or rconf.titles) then
				if rconf.enable then
					if (not titleFrame:IsShown()) then
						titleFrame:Show()
					end
				else
					titleFrame:Hide()
				end
			else
				if (titleFrame:IsShown()) then
					titleFrame:Hide()
				end
			end

			if (ZPerl.Locked == 0) then
				local rows = rconf.sortByClass and max(1, RaidGroupCounts[i]) or 5
				virtualFrame:ClearAllPoints()
				if (rconf.anchor == "TOP") then
					virtualFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
					virtualFrame:SetHeight(((rconf.mana and 5 or 0) + 38) * rows + (rconf.spacing * (rows - 1)))
					virtualFrame:SetWidth(80 + rconf.size.width)
				elseif (rconf.anchor == "LEFT") then
					virtualFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
					virtualFrame:SetHeight((rconf.mana and 1 or 0) * 5 + 38)
					virtualFrame:SetWidth(80 * rows + (rconf.spacing * (rows - 1)) + rconf.size.width)
				elseif (rconf.anchor == "BOTTOM") then
					virtualFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0)
					virtualFrame:SetHeight(((rconf.mana and 5 or 0) + 38) * rows + (rconf.spacing * (rows - 1)))
					virtualFrame:SetWidth(80 + rconf.size.width)
				elseif (rconf.anchor == "RIGHT") then
					virtualFrame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0)
					virtualFrame:SetHeight((rconf.mana and 1 or 0) * 5 + 38)
					virtualFrame:SetWidth(80 * rows + (rconf.spacing * (rows - 1)) + rconf.size.width)
				end
				virtualFrame:OnBackdropLoaded()
				virtualFrame:SetBackdropColor(conf.color.frame.r, conf.color.frame.g, conf.color.frame.b, conf.color.frame.a)
				virtualFrame:SetBackdropBorderColor(conf.color.border.r, conf.color.border.g, conf.color.border.b, 1)
				if rconf.group[i] and (i < 9 or rconf.sortByClass) then
					if rconf.enable then
						virtualFrame:Show()
					else
						virtualFrame:Hide()
					end
				else
					virtualFrame:Hide()
					titleFrame:Hide()
				end
			else
				virtualFrame:Hide()
			end
		else
			if (virtualFrame:IsShown()) then
				virtualFrame:Hide()
			end
			if (titleFrame:IsShown()) then
				titleFrame:Hide()
			end
		end
	end

	ZPerl.ProtectedCall(ZPerl.Raid.EnableRaidMouse)
end

-- ZPerl.Raid.EnableRaidMouse()
function ZPerl.Raid.EnableRaidMouse()
	for i = 1, 13 do
		local frame = _G["ZPerl_Raid_Title"..i]
		if (ZPerl.Locked == 0) then
			frame:EnableMouse(true)
		else
			frame:EnableMouse(false)
		end
	end
end

------- ZPerl.Raid.ToggleRaidBuffs -------
-- Raid Buff Key Binding function --
function ZPerl.Raid.ToggleRaidBuffs(castable)
	if (castable) then
		if (rconf.buffs.castable == 1) then
			rconf.buffs.castable, rconf.debuffs.curable = 0, 0
			ZPerl.Notice(L["KEY_NOTICE_RAID_BUFFANY"])
		else
			rconf.buffs.castable, rconf.debuffs.curable = 1, 1
			ZPerl.Notice(L["KEY_NOTICE_RAID_BUFFCURECAST"])
		end
	else
		-- None -> Buffs -> Debuffs -> Both -> None
		local b, d = rconf.buffs.enable, rconf.debuffs.enable
		if (b and d) then
			rconf.buffs.enable, rconf.debuffs.enable = false, false
			ZPerl.Notice(L["KEY_NOTICE_RAID_NOBUFFS"])
		elseif (d) then
			rconf.buffs.enable, rconf.debuffs.enable = 1, 1
			ZPerl.Notice(L["KEY_NOTICE_RAID_BUFFS_AND_DEBUFFS"])
		elseif (b) then
			rconf.buffs.enable, rconf.debuffs.enable = false, 1
			ZPerl.Notice(L["KEY_NOTICE_RAID_DEBUFFS"])
		else
			rconf.buffs.enable, rconf.debuffs.enable = 1, false
			ZPerl.Notice(L["KEY_NOTICE_RAID_BUFFS"])
		end
	end

	for k, v in pairs(FrameArray) do
		rebuildAuras(v)
		if (v:IsShown()) then
			ZPerl.Raid.UpdateDisplay(v)
		end
	end
end

-- GetCombatRezzerList()
local normalRezzers = {
	PRIEST = true,
	SHAMAN = true,
	PALADIN = true,
}

local function SortCooldown(a, b)
	return a.cd < b.cd
end

local function GetCombatRezzerList()
	local anyCombat = 0
	local anyAlive = 0
	for i = 1, GetNumGroupMembers() do
		local unit = "raid"..i
		local _, class = UnitClass(unit)
		-- never key the table with a nil or secret class
		---@diagnostic disable-next-line: secret-table-key
		if (class and ZPerl.CanAccess(class) and normalRezzers[class]) then
			if (UnitAffectingCombat(unit)) then
				anyCombat = anyCombat + 1
			end
			if (not UnitIsDeadOrGhost(unit) and UnitIsConnected(unit)) then
				anyAlive = anyAlive + 1
			end
		end
	end

	-- We only need to know about battle rezzers if any normal rezzers are in combat
	if (anyCombat > 0 or anyAlive < 3) then
		local ret = { }

		for i = 1, GetNumGroupMembers() do
			local raidid = "raid"..i
			if (not UnitIsDeadOrGhost(raidid) and UnitIsVisible(raidid)) then
				local name, _, _, _, _, fileName = GetRaidRosterInfo(i)

				if (not UnitAffectingCombat(raidid)) then
					if (fileName == "PRIEST" or fileName == "SHAMAN" or fileName == "PALADIN") then
						tinsert(ret, {["name"] = name, class = fileName, cd = 0})
					end
				else
					if (fileName == "DRUID") then
						local myRoster = ZPerlRoster[name]

						if (myRoster) then
							tinsert(ret, {["name"] = name, class = fileName, cd = 0})
						end
					end
				end
			end
		end

		if (#ret > 0) then
			sort(ret, SortCooldown)

			local list = ""
			for k,v in ipairs(ret) do
				local name = ZPerl.ColorTable[v.class]..v.name.."|r"

				if (v.cd > 0) then
					name = name.." (in "..SecondsToTime(v.cd)..")"
				end

				if (list == "") then
					list = name
				else
					list = list..", "..name
				end
			end
			--del(ret)
			return list
		else
			--del(ret)
			return "|c00FF0000"..NONE.."|r"
		end
	end

	if (anyAlive == 0) then
		return "|c00FF0000"..NONE.."|r"
	elseif (anyCombat == 0) then
		return "|c00FFFFFF"..ALL.."|r"
	end
end

-- ZPerl.Raid.RaidTipExtra
function ZPerl.Raid.RaidTipExtra(unitid)
	if (UnitInRaid(unitid)) then
		local unitName = RaidUnitName(unitid)

		for i = 1, GetNumGroupMembers() do
			local name = GetRaidRosterInfo(i)
			if (name == unitName) then
				break
			end
		end

		local stats = ZPerlRoster[unitName]
		if (stats) then
			local t = GetTime()

			-- connected/AFK/DND status can all be secret
			-- default to "still offline/afk/dnd" when
			-- uncertain, so an unreadable state doesn't clear the flag.
			if (stats.offline and SafeBool(UnitIsConnected(unitid), false)) then
				stats.offline = nil
			end
			if (stats.afk and not SafeBool(UnitIsAFK(unitid), true)) then
				stats.afk = nil
			end
			if (stats.dnd and not SafeBool(UnitIsDND(unitid), true)) then
				stats.dnd = nil
			end

			if (stats.offline) then
				GameTooltip:AddLine(format(L["RAID_TOOLTIP_OFFLINE"], SecondsToTime(t - stats.offline)))

			elseif (stats.afk) then
				GameTooltip:AddLine(format(L["RAID_TOOLTIP_AFK"], SecondsToTime(t - stats.afk)))

			elseif (stats.dnd) then
				GameTooltip:AddLine(format(L["RAID_TOOLTIP_DND"], SecondsToTime(t - stats.dnd)))

			elseif (stats.fd) then
				if (not UnitIsDead(unitid)) then
					stats.fd = nil
				else
					local x = stats.fd + 360 - t
					if (x > 0) then
						GameTooltip:AddLine(format(L["RAID_TOOLTIP_DYING"], SecondsToTime(x)))
					end
				end
			end

			if (UnitIsDeadOrGhost(unitid)) then
				if (stats.resCount) then
					GameTooltip:AddLine(L["LOC_RESURRECTED"].." x"..stats.resCount)
				end

				local Rezzers = GetCombatRezzerList()
				if (Rezzers) then
					GameTooltip:AddLine(L["RAID_RESSER_AVAIL"]..Rezzers, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
				end
			end
		end

		GameTooltip:Show()
	end
end

-- SetMainHeaderAttributes
local function SetMainHeaderAttributes(self)
	self:Hide()

	if (rconf.sortAlpha) then
		self:SetAttribute("sortMethod", "NAME")
	else
		self:SetAttribute("sortMethod", nil)
	end

	self:SetAttribute("showParty", rconf.inParty)
	self:SetAttribute("showPlayer", rconf.inParty)
	self:SetAttribute("showRaid", true)

	-- always set: a point left from an earlier anchor (LEFT/RIGHT) would lay BOTTOM out as a row
	self:SetAttribute("point", rconf.anchor)
	self:SetAttribute("minWidth", 80)
	self:SetAttribute("minHeight", 10)
	local titleFrame = self:GetParent()
	self:ClearAllPoints()
	if (rconf.anchor == "TOP") then
		self:SetPoint("TOP", titleFrame, "BOTTOM", 0, 0)
		self:SetAttribute("xOffset", 0)
		self:SetAttribute("yOffset", -rconf.spacing)
	elseif (rconf.anchor == "LEFT") then
		self:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 0, 0)
		self:SetAttribute("xOffset", rconf.spacing)
		self:SetAttribute("yOffset", 0)
	elseif (rconf.anchor == "BOTTOM") then
		self:SetPoint("BOTTOM", titleFrame, "TOP", 0, 0)
		self:SetAttribute("xOffset", 0)
		self:SetAttribute("yOffset", rconf.spacing)
	elseif (rconf.anchor == "RIGHT") then
		self:SetPoint("TOPRIGHT", titleFrame, "BOTTOMRIGHT", 0, 0)
		self:SetAttribute("xOffset", -rconf.spacing)
		self:SetAttribute("yOffset", 0)
	end
end

local function GroupFilter(n)
	if (rconf.sortByClass) then
		if (not rconf.class[n]) then
			rconf.class = ZPerl.DefaultRaidClasses()
		end
		if (rconf.class[n].enable) then
			return rconf.class[n].name
		end
		return ""
	else
		local f
		if (rconf.group[n]) then
			f = tostring(n)
		end

		local invalid
		for i = 1, Shared.CLASS_COUNT do
			if (not rconf.class[i]) then
				invalid = true
			end
		end
		if (invalid) then
			rconf.class = ZPerl.DefaultRaidClasses()
		end

		for i = 1, Shared.CLASS_COUNT do
			if (rconf.class[i].enable) then
				if (not f) then
					f = rconf.class[i].name
				else
					f = f..","..rconf.class[i].name
				end
			end
		end
		return f
	end
end

-- ZPerl_Raid_SetAttributes
function ZPerl.Raid.ChangeAttributes()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Raid.ChangeAttributes)
		return
	end
	local d = ZPerl.Dev; if d and d.listener then d.Emit("header.rebuild") end

	rconf.anchor = (rconf and rconf.anchor) or "TOP"

	for i = 1, rconf.sortByClass and Shared.CLASS_COUNT or 9 do
		local groupHeader = raidHeaders[i]

		-- Guard against nil raidHeaders entry
		if not groupHeader then
			break
		end

		-- The attributes below and SetMainHeaderAttributes follow from these values alone: a header
		-- that has them already is left as it is (the pass hides, shows and rebuilds it)
		local key = table.concat({tostring(rconf.sortByRole), tostring(rconf.sortByClass), tostring(rconf.sortAlpha),
			tostring(rconf.inParty), tostring(rconf.anchor), tostring(rconf.spacing), tostring(GroupFilter(i)), i}, "|")
		if groupHeader.attributeKey ~= key then
		groupHeader.attributeKey = key

		-- Hide this when we change attributes, so the whole re-calc is only done once, instead of for every attribute change
		groupHeader:Hide()

		if rconf.sortByRole then
			groupHeader:SetAttribute("groupBy", "ASSIGNEDROLE")
			groupHeader:SetAttribute("groupingOrder", "TANK,HEALER,DAMAGER,NONE")
			groupHeader:SetAttribute("startingIndex", (i - 1) * 5 + 1)
			groupHeader:SetAttribute("unitsPerColumn", 5)
			groupHeader:SetAttribute("strictFiltering", nil)
			groupHeader:SetAttribute("groupFilter", nil)
			--groupHeader:SetAttribute("useparent-toggleForVehicle", true)
			--groupHeader:SetAttribute("useparent-allowVehicleTarget", true)
			--groupHeader:SetAttribute("useparent-unitsuffix", true)
			--groupHeader:SetAttribute("toggleForVehicle", true)
			--groupHeader:SetAttribute("allowVehicleTarget", true)
		else
			groupHeader:SetAttribute("strictFiltering", not rconf.sortByClass)
			groupHeader:SetAttribute("groupFilter", GroupFilter(i))
			groupHeader:SetAttribute("groupBy", nil)
			groupHeader:SetAttribute("groupingOrder", nil)
			groupHeader:SetAttribute("startingIndex", 1)
			groupHeader:SetAttribute("unitsPerColumn", nil)
			--groupHeader:SetAttribute("useparent-toggleForVehicle", true)
			--groupHeader:SetAttribute("useparent-allowVehicleTarget", true)
			--groupHeader:SetAttribute("useparent-unitsuffix", true)
			--groupHeader:SetAttribute("toggleForVehicle", true)
			--groupHeader:SetAttribute("allowVehicleTarget", true)
		end

		-- Fix Secure Header taint in combat
		local maxColumns = groupHeader:GetAttribute("maxColumns") or 1
		local unitsPerColumn = groupHeader:GetAttribute("unitsPerColumn") or 5
		local startingIndex = groupHeader:GetAttribute("startingIndex") or 1
		local maxUnits = maxColumns * unitsPerColumn

		groupHeader:Show()
		groupHeader:SetAttribute("startingIndex", - maxUnits + 1)
		groupHeader:SetAttribute("startingIndex", startingIndex)

		SetMainHeaderAttributes(groupHeader)
		end
	end

	-- A shown header makes buttons for every unit its attributes allow, so the decider sees the
	-- headers only once they have their attributes.
	ZPerl.Raid.Headers = raidHeaders
	ZPerl.GroupVisibilityUpdate()
end



-- ZPerl.Raid.SetBits
function ZPerl.Raid.SetBits(self)
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.Raid.SetBits, self)
		return
	end
	local d = ZPerl.Dev; if d and d.listener then d.Emit("redisplay.raid") end
	if (Shared.raidLoaded) then
		ZPerl.GroupVisibilityUpdate()
	end

	Shared.SkipHighlightUpdate = nil

	ZPerl.Raid.ScaleRaid()
	ZPerl.Raid.SetWidth()

	for i, frame in pairs(FrameArray) do
		Setup1RaidFrame(frame)
	end

	for i, frame in ipairs(allFrames) do
		if (rconf.mana) then
			ZPerl.UnitFrameEnable(frame, "Power")
		else
			ZPerl.UnitFrameDisable(frame, "Power")
		end
	end

	Shared.SkipHighlightUpdate = nil

	if (IsInRaid() or (IsInGroup() and rconf.inParty)) then
		ZPerl_Raid_Frame:Show()
	end
end

