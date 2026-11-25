-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

ZPerl.SetModuleRevision("$Revision:  $")

ZPerlRaidAdminItems = {}

-- Upvalues
local _G = _G

local floor = floor
local format = format
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local sort = sort
local strfind = strfind
local string = string
local strlen = strlen
local strlower = strlower
local strmatch = strmatch
local strsub = strsub
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local type = type
local unpack = unpack

local C_ChatInfo = C_ChatInfo
local C_Container = C_Container
local ChatEdit_GetActiveWindow = ChatEdit_GetActiveWindow
local ChatTypeInfo = ChatTypeInfo
local CheckInteractDistance = CheckInteractDistance
local ClearCursor = ClearCursor
local CursorHasItem = CursorHasItem
local DressUpItemLink = DressUpItemLink
local FauxScrollFrame_SetOffset = FauxScrollFrame_SetOffset
local FauxScrollFrame_Update = FauxScrollFrame_Update
local GetChannelName = GetChannelName
local GetContainerItemLink = GetContainerItemLink or C_Container.GetContainerItemLink
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetRealZoneText = GetRealZoneText
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsControlKeyDown = IsControlKeyDown
local IsInRaid = IsInRaid
local IsShiftKeyDown = IsShiftKeyDown
local SecondsToTime = SecondsToTime
local SendChatMessage = SendChatMessage
local SetPortraitTexture = SetPortraitTexture
local UnitClass = UnitClass
local UnitInRaid = UnitInRaid
local UnitIsConnected = UnitIsConnected
local UnitIsGroupAssistant = UnitIsGroupAssistant
local UnitName = UnitName

local CLASS_BUTTONS = CLASS_BUTTONS
local DURABILITY_TEMPLATE = DURABILITY_TEMPLATE
local HIGHLIGHT_FONT_COLOR = HIGHLIGHT_FONT_COLOR
local NONE = NONE
local NORMAL_FONT_COLOR = NORMAL_FONT_COLOR
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local RESISTANCE_LABEL = RESISTANCE_LABEL
local SPELL_REAGENTS = SPELL_REAGENTS

local GameTooltip = GameTooltip

local ItemResults = {["type"] = "item"}
local ResistResults = {["type"] = "res", count = 0}
local DurResults = {["type"] = "dur", count = 0}
local RegResults = {["type"] = "reg", count = 0}
local PlayerList = {}
local MsgQueue = {}
local SelectedPlayer
local ActiveScan
local ActiveScanItem
local ActiveScanTotals
local channelList = nil
local outputChannel = "RAID"
local outputChannelIndex = nil
local outputChannelSelection
local outputChannelColor

local ITEMLISTSIZE = 12
local PLAYERLISTSIZE = 10

-- ZPerl.RaidAdmin.CheckOnLoad
function ZPerl.RaidAdmin.CheckOnLoad(self)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnEvent", ZPerl.RaidAdmin.CheckOnEvent)
	self:SetScript("OnShow", ZPerl.RaidAdmin.CheckOnShow)
	self:SetScript("OnHide", ZPerl.RaidAdmin.CheckOnHide)
	--self:RegisterEvent("CHAT_MSG_ADDON")

	_G["ZPerl_CheckListItemsScrollBar"].offset = 0
	_G["ZPerl_CheckListPlayersScrollBar"].offset = 0

	if (ZPerl.RegisterPerlFrames) then
		ZPerl.RegisterPerlFrames(self)
	end

	ZPerl.RegisterScalableFrame(self, ZPerl_CheckAnchor)
	self.corner:SetParent(ZPerl_CheckList)

	ZPerl_Check:SetWidth(130)
	ZPerl_Check:SetHeight(18)

	ZPerl.RaidAdmin.CheckOnLoad = nil
end

if (not ZPerl.GetClassColor) then
	ZPerl.GetClassColor = function(class)
		if (class) then
			local color = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] -- Now using the WoW class color table
			if (color) then
				return color
			end
		end
		return {r = 0.5, g = 0.5, b = 1}
	end
end

if (not ZPerl.ColorTable) then
	ZPerl.ColorTable = setmetatable({},{
		__index = function(self, class)
			local c = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] or {r = 0, g = 0, b = 0}
			return format("|c00%02X%02X%02X", 255 * c.r, 255 * c.g, 255 * c.b)
		end
	})
end

if (not ZPerl.ClassPos) then
	local ClassPos = CLASS_BUTTONS
	function ZPerl.ClassPos(class)
		local b = ClassPos[class] -- Now using the Blizzard supplied from FrameXML/WorldStateFrame.lua
		if (b) then
			return unpack(b)
		end
		return 0.25, 0.5, 0.5, 0.75
	end
end

-- ZPerl.RaidAdmin.CheckSetup
function ZPerl.RaidAdmin.CheckSetup()
	SlashCmdList["ZPERLITEM"] = ZPerl.RaidAdmin.ItemCheck
	SLASH_ZPERLITEM1 = "/zpitem"
	SLASH_ZPERLITEM2 = "/raitem"
	SLASH_ZPERLITEM3 = "/radur"
	SLASH_ZPERLITEM4 = "/raresist"
	SLASH_ZPERLITEM5 = "/raresists"
	SLASH_ZPERLITEM6 = "/rareg"

	SlashCmdList["RAITEM"] = nil
	SLASH_RAITEM1 = nil
	SlashCmdList["RADUR"] = nil
	SLASH_RADUR1 = nil
	SlashCmdList["RARST"] = nil
	SLASH_RARST1 = nil
	SlashCmdList["RAREG"] = nil
	SLASH_RAREG1 = nil

	if (not ZPerlRaidAdminDB.ResistSort) then
		ZPerlRaidAdminDB.ResistSort = "fr"
	end
	for k,v in ipairs(ZPerlRaidAdminItems) do
		v.query = nil
	end

	ZPerl_CheckTitleBarPin:SetButtonTex()
	ZPerl_CheckTitleBarLockOpen:SetButtonTex()

	_G["ZPerl_CheckListPlayersTotals"]:SetHighlightTexture("")
	_G["ZPerl_CheckListPlayersTotals"]:SetScript("OnClick", nil)

	ZPerl.RaidAdmin.CheckItemsChanged()
	ZPerl.RaidAdmin.CheckUpdatePlayerList()

	ZPerl.RaidAdmin.CheckSetup = nil
end

-- ZPerl.RaidAdmin.CheckOnShow
function ZPerl.RaidAdmin.CheckOnShow(self)
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

-- ZPerl.RaidAdmin.CheckOnHide
function ZPerl.RaidAdmin.CheckOnHide(self)
	self:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

-- ZPerl.RaidAdmin.CheckOnEvent
function ZPerl.RaidAdmin.CheckOnEvent(self, event, a1)
	if (event == "GROUP_ROSTER_UPDATE") then
		if (not IsInRaid()) then
			ItemResults = {["type"] = "item"}
			ResistResults = {["type"] = "res", count = 0}
			DurResults = {["type"] = "dur", count = 0}
			RegResults = {["type"] = "reg", count = 0}
		end
		ZPerl.RaidAdmin.CheckValidateButtons()

	elseif (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_MODEL_CHANGED") then
		local n = UnitName(a1)
		---@diagnostic disable-next-line: secret-table-key
		local scan = ActiveScan and ZPerl.CanAccess(n) and ActiveScan[n]
		if (scan) then
			scan.changed = true
			scan.offline = nil
			scan.wrongZone = nil
		end
	end
end

-- CheckOnUpdate
-- Only active after a query, and only for 10 seconds
local function CheckOnUpdate(self, elapsed)
	-- TODO Total Progress indication
	if (#MsgQueue > 0) then
		local Time = GetTime()
		local send
		if (not self.lastMsgsent) then
			send = true
		elseif (Time > self.lastMsgsent + 1) then
			send = true
		end

		if (send) then
			self.lastMsgsent = Time

			local count = 0
			local msg = ""

			while (#MsgQueue > 0 and count < 4) do
				local sub = MsgQueue[1]

				if (strlen(msg..sub) > 220) and UnitInRaid("player") then
					C_ChatInfo.SendAddonMessage("CTRA", msg, "RAID")
					break
				else
					count = count + 1
					tremove(MsgQueue, 1)
					if (msg == "") then
						msg = sub
					else
						msg = msg.."#"..sub
					end
				end
			end

			if (msg ~= "") and UnitInRaid("player") then
				C_ChatInfo.SendAddonMessage("CTRA", msg, "RAID")
			end
		end

	elseif (ActiveScanItem) then
		ZPerl.RaidAdmin.CheckActiveScan()
	else
		if (self.queryStart and GetTime() > self.queryStart + 5) then
			self:SetScript("OnUpdate", nil)
			self.queryStart, self.lastMsgsent = nil, nil

			ZPerl.RaidAdmin.CheckValidateButtons()
		end
	end
end

-- GetVLinkName
local function GetVLinkName(v)
	local linkName
	if (strsub(v.link, 1, 1) == "|") then
		linkName = strmatch(v.link, "%[(.+)%]")
	else
		linkName = v.link
	end
	return linkName
end

-- ClearSelectedItem
local function ClearSelectedItem()
	for k,v in ipairs(ZPerlRaidAdminItems) do
		v.selected = nil
	end
end

-- TickItemByName
local function TickItemByName(itemName)
	for k,v in ipairs(ZPerlRaidAdminItems) do
		local name = GetVLinkName(v)

		if (name == itemName) then
			if (not v.fixed) then
				v.ticked = true
			end
			v.selected = true
			break
		end
	end
end

-- GotItem
local function GotItem(link)
	local findItem = strmatch(link, "item:(%d+):")
	for k,v in pairs(ZPerlRaidAdminItems) do
		local item = strmatch(v.link, "item:(%d+):")
		if (item == findItem) then
			return true
		end
	end
end

-- GotItem
local function GotItemName(itemName)
	for k,v in pairs(ZPerlRaidAdminItems) do
		local linkName = strmatch(v.link, "%[(.+)%]")
		if (linkName == itemName) then
			return true
		end
	end
end

-- InsertItemLink
local function InsertItemLink(itemLink)
	ClearSelectedItem()

	if (strsub(itemLink, 1, 1) == "|") then
		if (not GotItem(itemLink)) then
			tinsert(ZPerlRaidAdminItems, {link = itemLink, ticked = true, selected = true})
		else
			local linkName = strmatch(itemLink, "%[(.+)%]")
			TickItemByName(linkName)
		end
	else
		if (not GotItemName(itemLink)) then
			tinsert(ZPerlRaidAdminItems, {link = itemLink, ticked = true, selected = true})
		else
			local linkName = strmatch(itemLink, "%[(.+)%]")
			TickItemByName(linkName)
		end
	end
end

-- ZPerl.RaidAdmin.CheckExpand()
function ZPerl.RaidAdmin.CheckExpand(forced)
	ZPerl_Check:SetWidth(500)
		ZPerl_Check:SetHeight(240)
		ZPerl_CheckList:Show()
		ZPerl_CheckButton:Show()
	---@diagnostic disable-next-line: inject-field
	ZPerl_Check.forcedOpen = forced
	ZPerl_CheckTitleBarLockOpen:Show()
end

-- ZPerl.RaidAdmin.ItemCheck
function ZPerl.RaidAdmin.ItemCheck(itemName)
	local cmd = "/raitem"
	if (DEFAULT_CHAT_FRAME.editBox) then
		local command = DEFAULT_CHAT_FRAME.editBox:GetText()
		if (strlower(strsub(command, 1, 6)) == "/radur") then
			cmd = "/radur"
		elseif (strlower(strsub(command, 1, 9)) == "/raresist") then
			cmd = "/raresist"
		elseif (strlower(strsub(command, 1, 6)) == "/rareg") then
			cmd = "/rareg"
		end
	end

	ZPerl_Check:Show()
	ZPerl.RaidAdmin.CheckExpand(true)

	if (cmd == "/raitem") then
		if (not itemName or itemName == "") then
			return
		end

		if (strsub(itemName, 1, 1) == "|") then
			-- TODO search for item in inventory (and LootLink) and use the link
		end

		InsertItemLink(itemName)
	elseif (cmd == "/radur") then
		ClearSelectedItem()
		TickItemByName("dur")

	elseif (cmd == "/rareg") then
		ClearSelectedItem()
		TickItemByName("reg")

	elseif (cmd == "/raresist") then
		ClearSelectedItem()
		TickItemByName("res")
	end

	ZPerl.RaidAdmin.CheckQuery()
end

-- ZPerl_PickupContainerItem
local PickupBag, PickupSlot
if C_Container then
	hooksecurefunc(C_Container, "PickupContainerItem", function(bagID, slot)
		PickupBag, PickupSlot = bagID, slot
	end)
elseif PickupContainerItem then
	hooksecurefunc("PickupContainerItem", function(bagID, slot)
		PickupBag, PickupSlot = bagID, slot
	end)
end

-- sortItems
-- Fixed entries at top, followed by last current queried, followed by rest. Alphabetical within this.
local function sortItems(i1, i2)
	local itemName1 = GetVLinkName(i1)
	local itemName2 = GetVLinkName(i2)

	local t1, t2, f1, f2, q1, q2
	if (i1.fixed) then f1 = "0" else f1 = "1" end
	if (i2.fixed) then f2 = "0" else f2 = "1" end
	if (i1.ticked) then t1 = "0" else t1 = "1" end
	if (i2.ticked) then t2 = "0" else t2 = "1" end
	if (i1.query) then q1 = "0" else q1 = "1" end
	if (i2.query) then q2 = "0" else q2 = "1" end

	return f1..q1..t1..itemName1 < f2..q2..t2..itemName2
end

-- ItemsChanged
function ZPerl.RaidAdmin.CheckItemsChanged()
	-- Validate. Make sure we have our fixed entries
	local dur, reg, res
	for k,v in ipairs(ZPerlRaidAdminItems) do
		if (v.link == "res") then
			res = true
		elseif (v.link == "dur") then
			dur = true
		elseif (v.link == "reg") then
			reg = true
		end
	end
	if (not dur) then
		tinsert(ZPerlRaidAdminItems, {fixed = true, link = "dur"})
	end
	if (not res) then
		tinsert(ZPerlRaidAdminItems, {fixed = true, link = "res"})
	end
	if (not reg) then
		tinsert(ZPerlRaidAdminItems, {fixed = true, link = "reg"})
	end

	sort(ZPerlRaidAdminItems, sortItems)

	ZPerl.RaidAdmin.CheckUpdateItemList()
	ZPerl.RaidAdmin.CheckValidateButtons()
end

-- GetSelectedResults
local function GetSelectedItem()
	for k,v in ipairs(ZPerlRaidAdminItems) do
		if (v.selected) then
			if (v.fixed) then
				if (v.link == "res") then
					return ResistResults, "res"
				elseif (v.link == "dur") then
					return DurResults, "dur"
				elseif (v.link == "reg") then
					return RegResults, "reg"
				end
			else
				local linkName = GetVLinkName(v)
				if (linkName) then
					return ItemResults[linkName], "item"
				end
				break
			end
		end
	end
end

-- GetSelectedItemLink
local function GetSelectedItemLink()
	for k,v in ipairs(ZPerlRaidAdminItems) do
		if (v.selected) then
			return v.link
		end
	end
end

-- GetCursorItem
local function GetCursorItemLink(self)
	local id = self:GetID() + _G["ZPerl_CheckListItemsScrollBar"].offset
	local item = ZPerlRaidAdminItems[id]
	if (item and not item.fixed) then
		return item.link
	end
	return ""
end

-- SelectClickedTickItem
local function SelectClickedTickItem(self)
	local oldSelection
	for k, v in ipairs(ZPerlRaidAdminItems) do
		if (v.selected) then
			oldSelection = v
			v.selected = nil
		end
	end

	local id
	if ((self.GetFrameType or self.GetObjectType)(self) == "CheckButton") then
		id = self:GetParent():GetID()
	else
		id = self:GetID()
	end

	if (id and id > 0) then
		id = id + _G["ZPerl_CheckListItemsScrollBar"].offset

		local item = ZPerlRaidAdminItems[id]
		if (item) then
			item.selected = true
		end

		if (oldSelection ~= item) then
			ZPerl.RaidAdmin.CheckStopActiveScan()
			ActiveScan = nil
			ActiveScanTotals = nil
		end

		ZPerl.RaidAdmin.CheckUpdateItemList()
		ZPerl.RaidAdmin.CheckMakePlayerList()
		ZPerl.RaidAdmin.CheckShowInfo()
	end
end

-- ZPerl.RaidAdmin.CheckTickAll
function ZPerl.RaidAdmin.CheckTickAll(all)
	for k, v in ipairs(ZPerlRaidAdminItems) do
		if (not v.fixed) then
			v.ticked = all
		end
	end
	ZPerl.RaidAdmin.CheckItemsChanged()
end

-- ZPerl.RaidAdmin.CheckTickLastResults
function ZPerl.RaidAdmin.CheckTickLastResults()
	for k, v in ipairs(ZPerlRaidAdminItems) do
		if (not v.fixed) then
			v.ticked = nil

			local linkName = GetVLinkName(v)
			if (linkName) then
				if (ItemResults[linkName]) then
					v.ticked = true
				end
			end
		end
	end

	ZPerl.RaidAdmin.CheckItemsChanged()
end

-- ZPerl.RaidAdmin.CheckOnClickItem
function ZPerl.RaidAdmin.CheckOnClickItem(button)
	if (button == "LeftButton") then
		if (IsShiftKeyDown()) then
			local activeWindow = ChatEdit_GetActiveWindow()
			if ( activeWindow ) then
				activeWindow:Insert(GetCursorItemLink(button))
			end

		elseif (IsControlKeyDown()) then
			DressUpItemLink(GetCursorItemLink(button))

		else
			if (CursorHasItem()) then
				ClearCursor()

				if (PickupBag and PickupSlot) then
					local itemLink = GetContainerItemLink(PickupBag, PickupSlot)

					if (itemLink) then
						InsertItemLink(itemLink)
						ZPerl.RaidAdmin.CheckItemsChanged()
					end
				end
			end

			_G["ZPerl_CheckListPlayersScrollBarScrollBar"]:SetValue(0)
			ZPerl_CheckButtonPlayerPortrait:SetTexture("")	-- SetPortraitTexture(ZPerl_CheckButtonPlayerPortrait, "raidx")
			SelectedPlayer = nil
			SelectClickedTickItem(button)
			ZPerl.RaidAdmin.CheckValidateButtons()
		end
	end
end

local reagentClasses = {
	PRIEST = true,
	MAGE = true,
	DRUID = true,
	WARLOCK = true,
	PALADIN = true,
	SHAMAN = true
}

-- GetOnlineMembers
local function GetOnlineMembers()
	local count = 0
	local reagentCount = 0
	for i = 1,GetNumGroupMembers() do
		if (UnitIsConnected("raid"..i)) then
			local _, class = UnitClass("raid"..i)
			---@diagnostic disable-next-line: secret-table-key
			if (ZPerl.CanAccess(class) and reagentClasses[class]) then
				reagentCount = reagentCount + 1
			end

			if (ZPerlRoster) then
				---@diagnostic disable-next-line: secret-table-key
				local stats = ZPerlRoster[UnitName("raid"..i)]
				if (stats) then
					if (stats.version) then
						count = count + 1
					end
				end
			else
				count = count + 1
			end
		end
	end
	return count, reagentCount
end

-- SmoothColor
local function SmoothColor(percentage)
	local r, g
	if (percentage < 0.5) then
		g = 2 * percentage
		r = 1
	else
		g = 1
		r = 2 * (1 - percentage)
	end
	if (r < 0) then r = 0 elseif (r > 1) then r = 1 end
	if (g < 0) then g = 0 elseif (g > 1) then g = 1 end
	return r, g, 0
end

-- SmoothBarColor
local function SmoothGuageColor(bar, percentage)
	local r, g, b = SmoothColor(percentage)
	bar:SetVertexColor(r, g, b, 0.75)
end

-- ZPerl.RaidAdmin.CheckUpdateItemList
function ZPerl.RaidAdmin.CheckUpdateItemList()
	local onlineCount, reagentCount = GetOnlineMembers()
	local index = 1
	local i = 0
	for k,v in ipairs(ZPerlRaidAdminItems) do
		if (index > ITEMLISTSIZE) then
			break
		end
		if (i >= _G["ZPerl_CheckListItemsScrollBar"].offset) then
			local frame = _G["ZPerl_CheckListItems"..index]
			local nameFrame = _G["ZPerl_CheckListItems"..index.."Name"]
			local countFrame = _G["ZPerl_CheckListItems"..index.."Count"]
			local iconFrame = _G["ZPerl_CheckListItems"..index.."Icon"]
			local gaugeFrame = _G["ZPerl_CheckListItems"..index.."Gauge"]
			local tickFrame = _G["ZPerl_CheckListItems"..index.."Tick"]

			frame:Show()
			if (v.selected) then
				frame:LockHighlight()
			else
				frame:UnlockHighlight()
			end

			if (v.fixed) then
				tickFrame:Hide()
				iconFrame:Hide()

				local div
				if (v.link == "res") then
					nameFrame:SetText(RESISTANCE_LABEL)
					countFrame:SetText(ResistResults.count)
					if onlineCount == 0 then
						div = 1
					else
						div = ResistResults.count / onlineCount
					end

				elseif (v.link == "dur") then
					local dur,c = string.gsub(DURABILITY_TEMPLATE, " %%d / %%d", "")
					if (not dur or c ~= 1) then
						dur = "Durability"
					end
					nameFrame:SetText(dur)
					countFrame:SetText(DurResults.count)
					if onlineCount == 0 then
						div = 1
					else
						div = DurResults.count / onlineCount
					end

				elseif (v.link == "reg") then
					nameFrame:SetText(L["CHECK_REAGENTS"])
					countFrame:SetText(RegResults.count)
					if reagentCount == 0 then
						div = 1
					else
						div = RegResults.count / reagentCount
					end
				end
				nameFrame:SetTextColor(1, 1, 0.7)

				if (div > 0) then
					if (div > 1) then div = 1 end
					gaugeFrame:SetWidth((countFrame:GetLeft() - nameFrame:GetLeft()) * div)
					gaugeFrame:Show()
					SmoothGuageColor(gaugeFrame, div)
				else
					gaugeFrame:Hide()
				end
			else
				tickFrame:Show()
				tickFrame:SetChecked(v.ticked)

				nameFrame:SetText(v.link)

				local itemId = strmatch(v.link, "item:(%d+):")
				if (itemId) then
					local _, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)
					iconFrame:SetTexture(itemTexture)
					iconFrame:Show()
				else
					iconFrame:Hide()
				end

				local linkName = GetVLinkName(v)
				if (linkName) then
					local count = ""
					local result = ItemResults[linkName]
					if (result) then
						count = #result

						for _, r in pairs(result) do
							if (r == -1) then
								-- Don't count Blocked ones, it's misleading
								count = count - 1
							end
						end

						local div = count / onlineCount

						if (v.query and div > 0) then
							if (div > 1) then div = 1 end
							gaugeFrame:SetWidth((countFrame:GetLeft() - nameFrame:GetLeft()) * div)
							gaugeFrame:Show()
							SmoothGuageColor(gaugeFrame, div)
						else
							gaugeFrame:Hide()
						end
					else
						gaugeFrame:Hide()
					end
					countFrame:SetText(count)
				else
					gaugeFrame:Hide()
				end
			end

			index = index + 1
		end
		i = i + 1
	end

	for j = index, ITEMLISTSIZE do
			_G["ZPerl_CheckListItems"..j]:Hide()
	end

	if (FauxScrollFrame_Update(_G["ZPerl_CheckListItemsScrollBar"], #ZPerlRaidAdminItems, ITEMLISTSIZE, 1)) then
		_G["ZPerl_CheckListItemsScrollBar"]:Show()
	else
		_G["ZPerl_CheckListItemsScrollBar"]:Hide()
	end
end

-- SortPlayersByCount
local function SortPlayersByCount(p1, p2)
	local c1, c2
	if (p1.broken) then
		if (p1.connected and not p1.noCTRA) then	c1 = p1.broken + (1 - (p1.dur / 100))	else	c1 = -1	end
		if (p2.connected and not p2.noCTRA) then	c2 = p2.broken + (1 - (p2.dur / 100))	else	c2 = -1	end
	else
		if (p1.connected and not p1.noCTRA) then	c1 = p1.count	else	c1 = -1	end
		if (p2.connected and not p2.noCTRA) then	c2 = p2.count	else	c2 = -1	end
	end
	return c1 > c2
end

-- SortPlayersByName
local function SortPlayersByName(p1, p2)
	return p1.name < p2.name
end

-- SortPlayersByClass
local function SortPlayersByClass(p1, p2)
	return p1.class..p1.name < p2.class..p2.name
end

-- ScanOrder
local function ScanOrder(p)
	local s = ActiveScan[p.name]
	if (s) then
		if (s.notequipped) then
			return 1
		elseif (s.equipped) then
			if (s.changed) then
				return 2
			else
				return 3
			end
		elseif (s.notinzone) then
			return 4
		elseif (s.offline) then
			return 5
		end
	end
	return 0
end

-- SortPlayersByDur
local function SortPlayersByDur(p1, p2)
	if (p1.dur) then
		local o1, o2 = 0,0
		if (not p1.connected or p1.noCTRA) then o1 = 1000 end
		if (not p2.connected or p2.noCTRA) then o2 = 1000 end
		return p1.dur + o1 < p2.dur + o2
	else
		if (ActiveScan) then
			return ScanOrder(p1)..p1.class..p1.name < ScanOrder(p2)..p2.class..p2.name
		else
			return SortPlayersByCount(p1, p2)
		end
	end
end

-- SortPlayersByResist
local function SortPlayersByResist(p1, p2)
	local o1, o2 = 0,0
	if (not p1.connected or p1.noCTRA) then o1 = 1000 end
	if (not p2.connected or p2.noCTRA) then o2 = 1000 end
	return p1[ZPerlRaidAdminDB.ResistSort] - o1 > p2[ZPerlRaidAdminDB.ResistSort] - o2
end

-- ZPerl.RaidAdmin.CheckMakePlayerList
function ZPerl.RaidAdmin.CheckMakePlayerList()

	FauxScrollFrame_SetOffset(_G["ZPerl_CheckListPlayersScrollBar"], 0)

	local function ShowResists(show)
		local r = {"FR", "FRR", "NR", "SR", "AR"}
		for k,v in pairs(r) do
			local title = _G["ZPerl_CheckListPlayersTitle"..v]
			local total = _G["ZPerl_CheckListPlayersTotals"..v]
			if (show) then
				title:Show()
				total:Show()
			else
				title:Hide()
				total:Hide()
			end
		end
	end

	local function ShowCount(show)
		if (show) then
			_G["ZPerl_CheckListPlayersTitleCount"]:Show()
			_G["ZPerl_CheckListPlayersTotalsCount"]:Show()
		else
			_G["ZPerl_CheckListPlayersTitleCount"]:Hide()
			_G["ZPerl_CheckListPlayersTotalsCount"]:Hide()
		end
	end

	local function ShowDur(show)
		if (show) then
			_G["ZPerl_CheckListPlayersTitleDur"]:Show()
			_G["ZPerl_CheckListPlayersTotalsNR"]:Show()
		else
			_G["ZPerl_CheckListPlayersTitleDur"]:Hide()
			_G["ZPerl_CheckListPlayersTotalsNR"]:Hide()
		end
	end

	PlayerList = {}

	local results, resType = GetSelectedItem()
	if (results and results.last) then
		_G["ZPerl_CheckListPlayersTitleClass"]:Show()
		_G["ZPerl_CheckListPlayersTitleName"]:Show()
		_G["ZPerl_CheckListPlayersTotalsName"]:Show()

		if (resType == "item" or resType == "reg") then
			_G["ZPerl_CheckListPlayersTotalsName"]:SetText(L["CHECK_TOTALS"])
			_G["ZPerl_CheckListPlayersTitleCount"]:SetText("#")

			ShowCount(true)
			ShowResists(false)
			ShowDur(ActiveScan)

			if (ActiveScan) then
				_G["ZPerl_CheckListPlayersTitleDur"]:SetText(L["CHECK_EQUIPED"])
			end

		elseif (resType == "dur") then
			_G["ZPerl_CheckListPlayersTotalsName"]:SetText(L["CHECK_AVERAGE"])

			ShowResists(false)
			ShowCount(true)
			ShowDur(true)

			_G["ZPerl_CheckListPlayersTitleCount"]:SetText(L["CHECK_BROKEN"])
			_G["ZPerl_CheckListPlayersTitleDur"]:SetText("%")

		elseif (resType == "res") then
			_G["ZPerl_CheckListPlayersTotalsName"]:SetText(L["CHECK_AVERAGE"])

			ShowCount(false)
			ShowDur(false)
			ShowResists(true)
		end

		for i = 1, GetNumGroupMembers() do
			local name = UnitName("raid"..i)
			local _, class = UnitClass("raid"..i)
			local count = 0
			local noCTRA

			if (ZPerlRoster) then
				---@diagnostic disable-next-line: secret-table-key
				local stats = ZPerlRoster[name]
				if (stats) then
					if (not stats.version) then
						noCTRA = true
					end
				end
			end

			if (resType == "item") then
				for k,v in ipairs(results) do
					if (v.name == name) then	-- type(v) == "table" and
						count = v.count
						if (count > 0) then
							noCTRA = nil
						end
						break
					end
				end

				tinsert(PlayerList, {["name"] = name, unit = "raid"..i, ["count"] = count, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})

			elseif (resType == "reg") then
				---@diagnostic disable-next-line: secret-table-key
				if (reagentClasses[class] or results[name]) then
					---@diagnostic disable-next-line: secret-table-key
					local p = results[name]
					local reg = 0
					if (p) then
						reg = p.count
						if (reg > 0) then
							noCTRA = nil
						end
					end

					tinsert(PlayerList, {["name"] = name, unit = "raid"..i, ["count"] = reg, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})
				end

			elseif (resType == "res") then
				---@diagnostic disable-next-line: secret-table-key
				local p = results[name]
				local fr, frr, nr, sr, ar = 0, 0, 0, 0, 0
				if (p) then
					fr, frr, nr, sr, ar = p.fr, p.frr, p.nr, p.sr, p.ar
					if (fr + frr + nr + sr + ar > 0) then
						noCTRA = nil
					end
				end

				tinsert(PlayerList, {["name"] = name, unit = "raid"..i, ["fr"] = fr, ["frr"] = frr, ["nr"] = nr, ["sr"] = sr, ["ar"] = ar, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})

			elseif (resType == "dur") then
				---@diagnostic disable-next-line: secret-table-key
				local p = results[name]
				local dur, broken = 0, 0
				if (p) then
					dur, broken = p.dur, p.broken
					if (dur + broken > 0) then
						noCTRA = nil
					end
				end

				tinsert(PlayerList, {["name"] = name, unit = "raid"..i, ["dur"] = dur, ["broken"] = broken, ["class"] = class, connected = (UnitIsConnected("raid"..i) == 1), ["noCTRA"] = noCTRA})
			end
		end

		if (resType == "item" or resType == "reg") then
			sort(PlayerList, SortPlayersByCount)
		elseif (resType == "dur") then
			sort(PlayerList, SortPlayersByDur)
		elseif (resType == "res") then
			sort(PlayerList, SortPlayersByResist)
		end
	else
		_G["ZPerl_CheckListPlayersTitleClass"]:Hide()
		_G["ZPerl_CheckListPlayersTitleName"]:Hide()
		_G["ZPerl_CheckListPlayersTotalsName"]:Hide()
		ShowCount(false)
		ShowDur(false)
		ShowResists(false)
	end

	ZPerl.RaidAdmin.CheckUpdatePlayerList()
end

-- ZPerl.RaidAdmin.CheckUpdatePlayerList
function ZPerl.RaidAdmin.CheckUpdatePlayerList()
	local onlineCount, tFR, tFRR, tNR, tSR, tAR, tDur, tBroken, tCount = 0, 0, 0, 0, 0, 0, 0, 0, 0

	local _, resType = GetSelectedItem()
	local index = 1

	for i = 1,#PlayerList do
		--    + ZPerl_CheckListPlayersScrollBar.offset, PLAYERLISTSIZE + ZPerl_CheckListPlayersScrollBar.offset do
		local v = PlayerList[i]
		if (not v) then
			break
		end

		if (v.fr) then
			tFR = tFR + v.fr
			tFRR = tFRR + v.frr
			tNR = tNR + v.nr
			tSR = tSR + v.sr
			tAR = tAR + v.ar
		elseif (v.dur) then
			tDur = tDur + v.dur
			tBroken = tBroken + v.broken
		else
			if (v.count > 0) then
				tCount = tCount + v.count
			end
		end

		if (v.connected) then
			onlineCount = onlineCount + 1
		end

		if (i >= _G["ZPerl_CheckListPlayersScrollBar"].offset + 1 and index <= PLAYERLISTSIZE) then
			local frame = _G["ZPerl_CheckListPlayers"..index]
			local iconFrame = _G["ZPerl_CheckListPlayers"..index.."Icon"]
			local nameFrame = _G["ZPerl_CheckListPlayers"..index.."Name"]
			local countFrame = _G["ZPerl_CheckListPlayers"..index.."Count"]
			local resFrameFR = _G["ZPerl_CheckListPlayers"..index.."FR"]
			local resFrameFRR = _G["ZPerl_CheckListPlayers"..index.."FRR"]
			local resFrameNR = _G["ZPerl_CheckListPlayers"..index.."NR"]
			local resFrameSR = _G["ZPerl_CheckListPlayers"..index.."SR"]
			local resFrameAR = _G["ZPerl_CheckListPlayers"..index.."AR"]
			local resFrameEquiped = _G["ZPerl_CheckListPlayers"..index.."Equiped"]

			---@diagnostic disable-next-line: secret-comparison
			if (v.name == SelectedPlayer) then
				frame:LockHighlight()
			else
				frame:UnlockHighlight()
			end

			nameFrame:SetText(v.name)
			local color = ZPerl.GetClassColor(v.class)
			nameFrame:SetTextColor(color.r, color.g, color.b)

			if (v.class) then
				local r, l, t, b = ZPerl.ClassPos(v.class)
				iconFrame:SetTexCoord(r, l, t, b)
				iconFrame:Show()
			else
				iconFrame:Hide()
			end

			_G["ZPerl_CheckListPlayers"..index]:Show()

			local function ShowScanIcon()
				if (ActiveScan) then
					---@diagnostic disable-next-line: secret-table-key
					local z = ActiveScan[v.name]
					if (z) then
						resFrameEquiped:Show()
						if (z.equipped) then
							if (z.changed) then
								resFrameEquiped:SetTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
							else
								resFrameEquiped:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
							end
							resFrameEquiped:SetTexCoord(0, 1, 0, 1)
						elseif (z.offline) then
							resFrameEquiped:SetTexture("Interface\\CharacterFrame\\Disconnect-Icon")
							resFrameEquiped:SetTexCoord(0.2, 0.8, 0.2, 0.8)
						elseif (z.notequipped) then
							resFrameEquiped:SetTexture("Interface\\AddOns\\ZPerl_RaidAdmin\\Images\\ZPerl_Check")
							if (z.changed) then
								resFrameEquiped:SetTexCoord(0.75, 0.875, 0.25, 0.5)
							else
								resFrameEquiped:SetTexCoord(0.625, 0.75, 0.25, 0.5)
							end
						elseif (z.notinzone) then
							resFrameEquiped:SetTexture("Interface\\GossipFrame\\TaxiGossipIcon")
							resFrameEquiped:SetTexCoord(0, 1, 0, 1)
						else
							resFrameEquiped:Hide()
						end
					else
						resFrameEquiped:Hide()
					end
				else
					resFrameEquiped:Hide()
				end
			end

			if (not v.connected or v.noCTRA) then
				if (not v.connected) then
					countFrame:SetText(L["LOC_OFFLINE"])
				end
				countFrame:SetTextColor(0.5, 0.5, 0.5)
				countFrame:Show()

				ShowScanIcon()

				resFrameFR:Hide()
				resFrameFRR:Hide()
				resFrameNR:Hide()
				resFrameSR:Hide()
				resFrameAR:Hide()
			else
				if (v.fr) then
					if (v.fr == -1) then
						countFrame:SetText("Blocked")
						countFrame:SetTextColor(0.5, 0.5, 0.5)
						countFrame:Show()

						resFrameFR:Hide()
						resFrameFRR:Hide()
						resFrameNR:Hide()
						resFrameSR:Hide()
						resFrameAR:Hide()
						resFrameEquiped:Hide()
					else
						resFrameFR:SetText(v.fr)
						resFrameFRR:SetText(v.frr)
						resFrameNR:SetText(v.nr)
						resFrameNR:SetTextColor(0, 1, 0)
						resFrameSR:SetText(v.sr)
						resFrameAR:SetText(v.ar)

						resFrameFR:Show()
						resFrameFRR:Show()
						resFrameNR:Show()
						resFrameSR:Show()
						resFrameAR:Show()
						countFrame:Hide()
						resFrameEquiped:Hide()
					end

				elseif (v.dur) then
					resFrameNR:SetText(v.dur)
					countFrame:SetText(v.broken)

					local r, g, b = SmoothColor(v.dur)
					resFrameNR:SetTextColor(r, g, b)

					countFrame:Show()
					resFrameNR:Show()

					if (v.broken > 0) then
						countFrame:SetTextColor(1, 0, 0)
					else
						countFrame:SetTextColor(0, 1, 0)
					end

					resFrameFR:Hide()
					resFrameFRR:Hide()
					resFrameSR:Hide()
					resFrameAR:Hide()
					resFrameEquiped:Hide()
				else
					if (v.count == -1) then
						countFrame:SetText("Blocked")
						countFrame:SetTextColor(0.5, 0.5, 0.5)
					else
						countFrame:SetText(v.count)
						if (v.count == 0) then
							countFrame:SetTextColor(1, 0, 0)
						else
							countFrame:SetTextColor(0, 1, 0)
						end
					end

					countFrame:Show()

					ShowScanIcon()

					resFrameFR:Hide()
					resFrameFRR:Hide()
					resFrameNR:Hide()
					resFrameSR:Hide()
					resFrameAR:Hide()
				end
			end

			index = index + 1
		end
	end

	for i = index,PLAYERLISTSIZE do
		_G["ZPerl_CheckListPlayers"..i]:Hide()
	end

	if (resType == "dur") then
		_G["ZPerl_CheckListPlayersTotalsNR"]:SetText(floor(tDur / onlineCount))
		_G["ZPerl_CheckListPlayersTotalsNR"]:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		_G["ZPerl_CheckListPlayersTotalsCount"]:SetText(tBroken)

		local r, g, b = SmoothColor((tDur / onlineCount) / 100)
		_G["ZPerl_CheckListPlayersTotalsNR"]:SetTextColor(r, g, b)

		if (tBroken > 0) then
			_G["ZPerl_CheckListPlayersTotalsCount"]:SetTextColor(1, 0, 0)
		else
			_G["ZPerl_CheckListPlayersTotalsCount"]:SetTextColor(0, 1, 0)
		end

	elseif (resType == "res") then
		_G["ZPerl_CheckListPlayersTotalsFR"]:SetText(floor(tFR / onlineCount))
		_G["ZPerl_CheckListPlayersTotalsNR"]:SetText(floor(tNR / onlineCount))
		_G["ZPerl_CheckListPlayersTotalsNR"]:SetTextColor(0, 1, 0)
		_G["ZPerl_CheckListPlayersTotalsFRR"]:SetText(floor(tFRR / onlineCount))
		_G["ZPerl_CheckListPlayersTotalsSR"]:SetText(floor(tSR / onlineCount))
		_G["ZPerl_CheckListPlayersTotalsAR"]:SetText(floor(tAR / onlineCount))
	else
		_G["ZPerl_CheckListPlayersTotalsCount"]:SetText(tCount)

		if (tCount == 0) then
			_G["ZPerl_CheckListPlayersTotalsNR"]:SetTextColor(1, 0, 0)
		else
			_G["ZPerl_CheckListPlayersTotalsNR"]:SetTextColor(0, 1, 0)
		end
	end

	if (FauxScrollFrame_Update(_G["ZPerl_CheckListPlayersScrollBar"], #PlayerList, PLAYERLISTSIZE, 1)) then
		_G["ZPerl_CheckListPlayersScrollBar"]:Show()
	else
		_G["ZPerl_CheckListPlayersScrollBar"]:Hide()
	end
end

-- ZPerl.RaidAdmin.CheckShowInfo
function ZPerl.RaidAdmin.CheckShowInfo()
	if (ActiveScanTotals) then
		if (ActiveScanTotals.missing > 0) then
			ZPerl_CheckButtonInfo:SetFormattedText(L["CHECK_SCAN_MISSING"], ActiveScanTotals.missing)
		else
			ZPerl_CheckButtonInfo:SetText("")
		end
	else
		local results = GetSelectedItem()

		local t
		if (results and results.last and results.last > 0) then
			t = SecondsToTime(GetTime() - results.last)
		else
			t = ""
		end
		if (t ~= "") then
			ZPerl_CheckButtonInfo:SetFormattedText(L["CHECK_LASTINFO"], t)
		else
			ZPerl_CheckButtonInfo:SetText("")
		end
	end
end

-- ZPerl.RaidAdmin.CheckOnEnter
function ZPerl.RaidAdmin.CheckOnEnter(self)
	local f, anc
	if ((self.GetFrameType or self.GetObjectType)(self) == "CheckButton") then
		f = _G[self:GetParent():GetName().."Name"]
		anc = self:GetParent()
	else
		f = _G[self:GetName().."Name"]
		anc = self
	end
	if (f) then
		local link = f:GetText()
		if (link and strsub(link, 1, 1) == "|") then
			-- Have to strip excess information for the SetHyperlink call
			local itemId = strmatch(link, "item:(%d+):")
			if (itemId) then
				local newLink = format("item:%d:0:0:0", itemId)

				GameTooltip:SetOwner(anc, "ANCHOR_LEFT")
				GameTooltip:SetHyperlink(newLink)
				return
			end
		end
	end

	GameTooltip:SetOwner(_G["ZPerl_CheckListItems1"], "ANCHOR_LEFT")
	GameTooltip:SetText(L["CHECK_DROPITEMTIP1"], HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	GameTooltip:AddLine(L["CHECK_DROPITEMTIP2"], NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
	GameTooltip:Show()
end

-- ZPerl_Check_OnClickStart
function ZPerl.RaidAdmin.CheckOnClickTick(self)
	local id = self:GetParent():GetID() + _G["ZPerl_CheckListItemsScrollBar"].offset
	if (ZPerlRaidAdminItems[id]) then
		ZPerlRaidAdminItems[id].ticked = self:GetChecked()
	end
	ZPerl.RaidAdmin.CheckValidateButtons()
end

-- ZPerl.RaidAdmin.CheckDeleteSelectedItems
function ZPerl.RaidAdmin.CheckDeleteSelectedItems()
	local newList = {}

	for k, v in ipairs(ZPerlRaidAdminItems) do
		if (v.fixed or not v.ticked) then
			tinsert(newList, v)
		else
			local linkName = GetVLinkName(v)
			if (linkName) then
				ItemResults[linkName] = nil
			end
		end
	end

	ZPerlRaidAdminItems = newList

	ZPerl.RaidAdmin.CheckItemsChanged()
end

-- ZPerl.RaidAdmin.CheckQuery
function ZPerl.RaidAdmin.CheckQuery()
	local oldResults = ItemResults
	ItemResults = {["type"] = "item"}

	_G["ZPerl_CheckListItemsScrollBarScrollBar"]:SetValue(0)

	tinsert(MsgQueue, "DURC")
	tinsert(MsgQueue, "RSTC")
	tinsert(MsgQueue, "REAC")
	ResistResults.count = 0
	DurResults.count = 0
	RegResults.count = 0

	for k, v in ipairs(ZPerlRaidAdminItems) do
		if (v.ticked) then
			v.query = true
			v.ticked = nil

			if (not v.fixed) then
				local linkName = GetVLinkName(v)

				if (linkName) then
					ItemResults[linkName] = {last = 0}
					oldResults[linkName] = nil
					tinsert(MsgQueue, "ITMC "..linkName)
				end
			end
		else
			v.query = nil
		end
	end

	for k, v in pairs(oldResults) do
		if (type(v) == "table") then
			if (not v.fixed) then
				ItemResults[k] = v
			end
		end
	end

	---@diagnostic disable-next-line: inject-field
	ZPerl_Check.queryStart = GetTime()
	---@diagnostic disable-next-line: inject-field
	ZPerl_Check.lastMsgsent = nil
	ZPerl_Check:SetScript("OnUpdate", CheckOnUpdate)

	ZPerl.RaidAdmin.CheckItemsChanged()		-- Re-sort and re-show list with ticked items at top
	ZPerl.RaidAdmin.CheckValidateButtons()
end

-- GetActiveScanItem
local function GetActiveScanItem()
	local item = GetSelectedItemLink()
	local itemId
	if (item and strsub(item, 1, 1) == "|") then
		itemId = strmatch(item, "item:(%d+):")
		if (not itemId) then
			return
		end
	else
		return
	end

	local _, _, _, _, _, itemType, _, _, itemEquipLoc = GetItemInfo(itemId)

	if (not itemEquipLoc or not itemType) then
		return
	end

	if (not (itemType == "Armor" or itemType == "Weapon")) then
		return
	end

	local slots = {	INVTYPE_HEAD = 1,
			INVTYPE_NECK = 2,
			INVTYPE_SHOULDER = 3,
			INVTYPE_BODY = 4,
			INVTYPE_CHEST = 5,
			INVTYPE_ROBE = 5,
			INVTYPE_WAIST = 6,
			INVTYPE_LEGS = 7,
			INVTYPE_FEET = 8,
			INVTYPE_WRIST = 9,
			INVTYPE_HAND = 10,
			INVTYPE_FINGER = {11, 12},
			INVTYPE_TRINKET = {13, 14},
			INVTYPE_CLOAK = 15,
			INVTYPE_2HWEAPON = 16,
			INVTYPE_WEAPONMAINHAND = 16,
			INVTYPE_WEAPON = {16, 17},
			INVTYPE_WEAPONOFFHAND = 17,
			INVTYPE_HOLDABLE = 17,
			INVTYPE_SHIELD = 17,
			INVTYPE_RANGED = 18,
			INVTYPE_RELIC = 18,
			INVTYPE_TABARD = 19}

	local slot = slots[itemEquipLoc]
	if (slot) then
		return tonumber(itemId), slot
	end
end

-- GetSelectedPlayer
local function GetSelectedPlayer()
	if (SelectedPlayer) then
		for k,v in pairs(PlayerList) do
			---@diagnostic disable-next-line: secret-comparison
			if (v.name == SelectedPlayer) then
				return v
			end
		end
	end
end

-- ZPerl.RaidAdmin.CheckValidateButtons
function ZPerl.RaidAdmin.CheckValidateButtons()
	local fixedSelected, regSelected
	local anyTicked
	for k,v in ipairs(ZPerlRaidAdminItems) do
		if (v.selected) then
			if (v.fixed) then
				fixedSelected = true
			end
			if (v.link == "reg") then
				regSelected = true
			end
		end
		if (not v.fixed and v.ticked) then
			anyTicked = true
		end
	end

	local results = GetSelectedItem()

	if (anyTicked and not ZPerl_Check.queryStart) then
		ZPerl_CheckButtonDelete:Enable()
	else
		ZPerl_CheckButtonDelete:Disable()
	end

	if (not ZPerl_Check.queryStart and UnitIsGroupAssistant("player")) then
		ZPerl_CheckButtonQuery:Enable()
	else
		ZPerl_CheckButtonQuery:Disable()
	end

	if (((results and results.last) or ActiveScan) and IsInRaid()) then
		ZPerl_CheckButtonReport:Enable()
	else
		ZPerl_CheckButtonReport:Disable()
	end

	if (results and results.last and not (fixedSelected and not regSelected) and IsInRaid()) then
		ZPerl_CheckButtonReportWith:Enable()
		ZPerl_CheckButtonReportWithout:Enable()
	else
		ZPerl_CheckButtonReportWith:Disable()
		ZPerl_CheckButtonReportWithout:Disable()
	end

	if (ActiveScanItem) then
		local tex = ZPerl_CheckButtonEquiped:GetNormalTexture()
		tex:SetTexCoord(0.75, 0.875, 0.5, 0.75)
		tex = ZPerl_CheckButtonEquiped:GetPushedTexture()
		tex:SetTexCoord(0.875, 1, 0.5, 0.75)

				ZPerl_CheckButtonEquiped.tooltipText = "CHECK_SCANSTOP_DESC"
	else
		local tex = ZPerl_CheckButtonEquiped:GetNormalTexture()
		tex:SetTexCoord(0.375, 0.5, 0.5, 0.75)
		tex = ZPerl_CheckButtonEquiped:GetPushedTexture()
		tex:SetTexCoord(0.5, 0.625, 0.5, 0.75)

				ZPerl_CheckButtonEquiped.tooltipText = "CHECK_SCAN_DESC"
	end

	local myPlayer = GetSelectedPlayer()
	---@diagnostic disable-next-line: secret-table-key
	if (((results and results.last) or (ActiveScan and ActiveScan[SelectedPlayer])) and myPlayer and myPlayer.connected) then
		ZPerl_CheckButtonPlayer:Enable()
	else
		ZPerl_CheckButtonPlayer:Disable()
	end

	ZPerl_CheckButtonEquiped:Hide()
	ZPerl_CheckButtonEquiped:Show()

	if (results and not fixedSelected and GetActiveScanItem()) then
		ZPerl_CheckButtonEquiped:Enable()
	else
		ZPerl_CheckButtonEquiped:Disable()
	end
end

-- ZPerl.RaidAdmin.CheckPlayersSort
function ZPerl.RaidAdmin.CheckPlayersSort(sortType)
	if (sortType == "class") then
		sort(PlayerList, SortPlayersByClass)
	elseif (sortType == "name") then
		sort(PlayerList, SortPlayersByName)
	elseif (sortType == "count") then
		sort(PlayerList, SortPlayersByCount)
	elseif (sortType == "dur") then
		sort(PlayerList, SortPlayersByDur)
	elseif (strfind("frrsrnrar", sortType)) then
		ZPerlRaidAdminDB.ResistSort = sortType
		sort(PlayerList, SortPlayersByResist)
	end

	ZPerl.RaidAdmin.CheckUpdatePlayerList()
end

-- ZPerl.RaidAdmin.CheckReport
function ZPerl.RaidAdmin.CheckReport(showNames)
	local function ReportOutput(msg)
		if (msg) then
			SendChatMessage("<Z-Perl> "..msg, outputChannel, nil, outputChannelIndex)
		end
	end

	local link = GetSelectedItemLink()
	local msg
	if (link) then
		local myPlayer = GetSelectedPlayer()

		if (link == "res") then
			if (ResistResults.last) then
				if (showNames == "player") then
					if (SelectedPlayer) then
						if (myPlayer.connected) then
							msg = format(L["CHECK_REPORT_PRESISTS"], SelectedPlayer, myPlayer.fr, myPlayer.nr, myPlayer.frr, myPlayer.sr, myPlayer.ar)
						end
					end
				else
					local fr, frr, nr, sr, ar, count = 0, 0, 0, 0, 0, 0

					for k,v in ipairs(PlayerList) do
						if (v.connected) then
							count = count + 1

							fr = fr + v.fr
							frr = frr + v.frr
							nr = nr + v.nr
							sr = sr + v.sr
							ar = ar + v.ar
						end
					end

					fr = fr / count
					frr = frr / count
					nr = nr / count
					sr = sr / count
					ar = ar / count

					msg = format(L["CHECK_REPORT_RESISTS"], fr, nr, frr, sr, ar)
				end
				ReportOutput(msg)
			end

		elseif (link == "dur") then
			if (DurResults.last) then
				if (showNames == "player") then
					if (SelectedPlayer) then
						if (myPlayer.connected) then
							msg = format(L["CHECK_REPORT_PDURABILITY"], SelectedPlayer, myPlayer.dur, myPlayer.broken)
						end
					end
				else
					local dur, broken, brokenPeople, count = 0, 0, 0, 0

					for k,v in ipairs(PlayerList) do
						if (v.connected) then
							count = count + 1
							dur = dur + v.dur

							if (v.broken > 0) then
								brokenPeople = brokenPeople + 1
								broken = broken + v.broken
							end
						end
					end

					dur = dur / count

					msg = format(L["CHECK_REPORT_DURABILITY"], dur, brokenPeople, broken)
				end
				ReportOutput(msg)
			end
		else
			if (showNames == "player") then
				if (SelectedPlayer) then
					if (myPlayer.connected) then
						if (link == "reg") then
							if (RegResults.last) then
								---@diagnostic disable-next-line: secret-table-key
								msg = format(L["CHECK_REPORT_PITEM"], SelectedPlayer, myPlayer.count, L["REAGENTS"][myPlayer.class])
							end
						else
							---@diagnostic disable-next-line: secret-table-key
							if (ActiveScan and ActiveScan[SelectedPlayer]) then
								---@diagnostic disable-next-line: secret-table-key
								if (ActiveScan[SelectedPlayer].equipped) then
									msg = format(L["CHECK_REPORT_PEQUIPED"], SelectedPlayer, link)
								---@diagnostic disable-next-line: secret-table-key
								elseif (ActiveScan[SelectedPlayer].notequipped) then
									msg = format(L["CHECK_REPORT_PNOTEQUIPED"], SelectedPlayer, link)
								end
							else
								msg = format(L["CHECK_REPORT_PITEM"], SelectedPlayer, myPlayer.count, link)
							end
						end
						ReportOutput(msg)
					end
				end
			else
				local equipable = ""
				if (strsub(link, 1, 1) == "|") then
					local itemId = strmatch(link, "item:(%d+):")
					local _, _, _, _, _, itemType, _, _, itemEquipLoc = GetItemInfo(itemId)
					if (itemEquipLoc and itemType) then
						if (itemType == "Armor" or itemType == "Weapon") then
							equipable = "_EQ"
						end
					end
				end

				local with = {}
				local without = {}
				local offline = {}
				local totalItems = 0

				for k, v in ipairs(PlayerList) do
					if (ActiveScanTotals and ActiveScanTotals.missing == 0) then
						---@diagnostic disable-next-line: secret-table-key
						local scan = ActiveScan[v.name]
						if (scan.equipped) then
							tinsert(with, v)
						elseif (scan.notequipped) then
							tinsert(without, v)
						elseif (scan.offline) then
							tinsert(offline, v)
						end
					else
						if (v.connected) then
							if (v.count > 0) then
								tinsert(with, v)
								totalItems = totalItems + v.count
							elseif (not v.noCTRA) then
								tinsert(without, v)
							end
						else
							tinsert(offline, v)
						end
					end
				end

				if (ActiveScanTotals and ActiveScanTotals.missing == 0 and ActiveScanTotals.wrongZone == 0 and ActiveScanTotals.notequipped == 0) then
					if (ActiveScanTotals.offline == 0) then
						ReportOutput(format(L["CHECK_REPORT_ALLEQUIPED"], link))
					else
						ReportOutput(format(L["CHECK_REPORT_ALLEQUIPEDOFF"], link, ActiveScanTotals.offline))
					end
				else
					if (showNames) then
						if (link == "reg") then
							local c
							link, c = string.gsub(SPELL_REAGENTS, ": ", "")
							if (not link or c ~= 1) then
								link = "Reagents"
							end
						end

						local showList
						local showTitle
						if (showNames == "with") then
							if (ActiveScanTotals and ActiveScanTotals.missing == 0) then
								showTitle = link..L["CHECK_REPORT_EQUIPED"]
							else
								showTitle = link..L["CHECK_REPORT_WITH"..equipable]
							end
							if (#with > 0) then
								showList = with
							end
						elseif (showNames == "without") then
							if (ActiveScanTotals and ActiveScanTotals.missing == 0) then
								showTitle = link..L["CHECK_REPORT_NOTEQUIPED"]
							else
								showTitle = link..L["CHECK_REPORT_WITHOUT"..equipable]
							end
							if (#without > 0) then
								showList = without
							end
						end

						if (showList) then
							msg = showTitle
							local msgLocal = showTitle
							local first = true

							for k,v in ipairs(showList) do
								---@diagnostic disable-next-line: secret-table-key
								local name = ZPerl.ColorTable[v.class]..v.name.."|r"

								if (strlen(msg) + strlen(name) > 240) then
									ReportOutput(msg.."...")
									DEFAULT_CHAT_FRAME:AddMessage("<Z-Perl> "..msgLocal)
									msg = "  ... "..v.name
									msgLocal = "  ... "..name
								else
									if (first) then
										msg = msg..v.name
										msgLocal = msgLocal..name
										first = nil
									else
										msg = msg..", "..v.name
										msgLocal = msgLocal..", "..name
									end
								end
							end

							if (msg) then
								ReportOutput(msg)
							end
							if (msgLocal) then
								DEFAULT_CHAT_FRAME:AddMessage("<Z-Perl> "..msgLocal)
							end
						elseif (showTitle) then
							DEFAULT_CHAT_FRAME:AddMessage("<Z-Perl> "..showTitle..NONE)
						end
					else
						msg = link.." "

						local function Out(txt, num)
							if (num > 0) then
								msg = msg..format(txt, num)
							end
						end

						if (ActiveScanTotals) then	-- and ActiveScanTotals.missing == 0) then
							Out(L["CHECK_REPORT_EQUIPEDSHORT"], ActiveScanTotals.equipped)
							Out(L["CHECK_REPORT_NOTEQUIPEDSHORT"], ActiveScanTotals.notequipped)
							Out(L["CHECK_REPORT_OFFLINE"], ActiveScanTotals.offline)
							Out(L["CHECK_REPORT_NOTSCANNED"], ActiveScanTotals.missing + ActiveScanTotals.wrongZone)
						else
							Out(L["CHECK_REPORT_WITHSHORT"], #with)
							Out(L["CHECK_REPORT_WITHOUTSHORT"], #without)
							Out(" : %d "..L["LOC_OFFLINE"], #offline)
						end

						if (link ~= "reg") then
							Out(L["CHECK_REPORT_TOTAL"], totalItems)
						end

						ReportOutput(msg)
					end
				end
			end
		end
	end
end

-- ZPerl.RaidAdmin.CheckPlayerOnClick
function ZPerl.RaidAdmin.CheckPlayerOnClick(button)
	local index = button:GetID() + _G["ZPerl_CheckListPlayersScrollBar"].offset

	if (index < 1 or index > #PlayerList) then
		return
	end

	---@diagnostic disable-next-line: secret-comparison
	if (SelectedPlayer == PlayerList[index].name) then
		SelectedPlayer = nil
	else
		SelectedPlayer = PlayerList[index].name
	end

	ZPerl.RaidAdmin.CheckUpdatePlayerList()

	SetPortraitTexture(ZPerl_CheckButtonPlayerPortrait, PlayerList[index].unit)

	ZPerl.RaidAdmin.CheckValidateButtons()
end

-- ZPerl.RaidAdmin.CheckStopActiveScan
function ZPerl.RaidAdmin.CheckStopActiveScan()
	ZPerl_Check:UnregisterEvent("UNIT_INVENTORY_CHANGED")
	ZPerl_Check:UnregisterEvent("UNIT_MODEL_CHANGED")
	ActiveScanItem = nil
end

-- ZPerl.RaidAdmin.CheckStartActiveScan
function ZPerl.RaidAdmin.CheckStartActiveScan()
	if (ActiveScanItem) then
		ZPerl.RaidAdmin.CheckStopActiveScan()
	else
		local itemId, itemSlot = GetActiveScanItem()
		if (itemId) then
			ActiveScan = {}

			ActiveScanItem = {id = itemId, slot = itemSlot, missing = GetNumGroupMembers()}
			ActiveScanTotals = {missing = 0, equipped = 0, notequipped = 0, offline = 0, wrongZone = 0}

			ZPerl_Check:SetScript("OnUpdate", CheckOnUpdate)
			ZPerl_Check:RegisterEvent("UNIT_INVENTORY_CHANGED")
			ZPerl_Check:RegisterEvent("UNIT_MODEL_CHANGED")

			_G["ZPerl_CheckListPlayersTitleDur"]:SetText(L["CHECK_EQUIPED"])
			_G["ZPerl_CheckListPlayersTitleDur"]:Show()
		end
	end

	ZPerl.RaidAdmin.CheckValidateButtons()
end

-- ZPerl.RaidAdmin.CheckActiveScan
function ZPerl.RaidAdmin.CheckActiveScan()
	local function CheckSlot(unit, slot)
		local link = GetInventoryItemLink(unit, slot)
		local name = UnitName(unit)
		if (not ZPerl.CanAccess(name)) then
			return
		end

		---@diagnostic disable-next-line: secret-table-key
		local scan = ActiveScan[name]
		if (not scan) then
			scan = {}
			---@diagnostic disable-next-line: secret-table-key
			ActiveScan[name] = scan
		end

		if (link) then
			local itemId = strmatch(link, "item:(%d+):")
			if (itemId) then
				itemId = tonumber(itemId)

				if (itemId == ActiveScanItem.id) then
					scan.notequipped = nil
					scan.equipped = 1
					return true
				end
			end
		end

		scan.equipped = nil
		scan.notequipped = 1
	end

	local myZone = GetRealZoneText()

	local any
	local update
	ActiveScanTotals = {missing = 0, equipped = 0, notequipped = 0, offline = 0, wrongZone = 0}

	for i = 1, GetNumGroupMembers() do
		local name, _, _, _, _, _, zone = GetRaidRosterInfo(i)
		local unit = "raid"..i
		local myScan = ActiveScan[name]

		if (not myScan or myScan.changed) then
			if (myScan) then
				myScan.changed = nil
			end
			any = true
			if (not InCombatLockdown() and CheckInteractDistance(unit, 1)) then		-- Checks to see if in inspect range
				local eq
				if (type(ActiveScanItem.slot) == "table") then
					for k,v in pairs(ActiveScanItem.slot) do
						if (CheckSlot(unit, v)) then
							eq = true
							break
						end
					end
				else
					eq = CheckSlot(unit, ActiveScanItem.slot)
				end

				if (eq) then
					ActiveScanTotals.equipped = ActiveScanTotals.equipped + 1
				else
					ActiveScanTotals.notequipped = ActiveScanTotals.notequipped + 1
				end
				update = true

			elseif (not UnitIsConnected(unit)) then
				if (not ActiveScan[name]) then
					ActiveScan[name] = {}
				end

				ActiveScan[name].offline = 1
				ActiveScanTotals.offline = ActiveScanTotals.offline + 1
				update = true

			elseif (zone ~= myZone) then
				if (not ActiveScan[name]) then
					ActiveScan[name] = {}
				end

				ActiveScan[name].notinzone = 1
				ActiveScanTotals.wrongZone = ActiveScanTotals.wrongZone + 1
				update = true

			else
				ActiveScanTotals.missing = ActiveScanTotals.missing + 1
			end
		else
			ActiveScanTotals.missing	= ActiveScanTotals.missing	+ (myScan.missing	or 0)
			ActiveScanTotals.equipped	= ActiveScanTotals.equipped	+ (myScan.equipped	or 0)
			ActiveScanTotals.notequipped	= ActiveScanTotals.notequipped	+ (myScan.notequipped	or 0)
			ActiveScanTotals.offline	= ActiveScanTotals.offline	+ (myScan.offline	or 0)
			ActiveScanTotals.wrongZone	= ActiveScanTotals.wrongZone	+ (myScan.notinzone	or 0)
		end
	end

	ZPerl.RaidAdmin.CheckShowInfo()

	if (update) then
		sort(PlayerList, SortPlayersByDur)		-- It's actually by equipped, that's sorted out in sort func
		ZPerl.RaidAdmin.CheckUpdatePlayerList()
		ZPerl.RaidAdmin.CheckValidateButtons()
	end
end

-- ZPerl.RaidAdmin.GetChannelList
if (not ZPerl.RaidAdmin.GetChannelList) then
local function GetChatColor(name)
	local info = ChatTypeInfo[name]
	local clr = {r = 0.5, g = 0.5, b = 0.5}
	if (info) then
		clr.r = (info.r or 0.5)
		clr.g = (info.g or 0.5)
		clr.b = (info.b or 0.5)
	end
	return clr
end
function ZPerl.RaidAdmin.GetChannelList()
	local cList = {}
	local l = {"RAID", "OFFICER", "GUILD", "PARTY", "SAY"}
	for k,v in pairs(l) do
		tinsert(cList, {display = _G["CHAT_MSG_"..v], channel = v, color = GetChatColor(v)})
	end

	for i = 1, 10 do
		local c, name = GetChannelName(i)
		if (name and c ~= 0) then
			tinsert(cList, {display = name, channel = "CHANNEL", index = c, color = GetChatColor("CHANNEL"..c)})
		end
	end

	return cList
end
end

-- The report channel dropdown, its list in ZPerl.DropdownPicker (ZPerl_Picker.lua). The choices, {i, colored name,
-- entry = a GetChannelList entry} each, are kept until the joined channels change.
local channelChoices, channelNames = {}, {}
local function ChannelsChanged()
	for i = 1, 10 do
		local c, name = GetChannelName(i)
		if (channelNames[i] ~= (c ~= 0 and name or false)) then
			return true
		end
	end
end
local function ChannelChoices()
	if (channelList and not ChannelsChanged()) then
		return channelChoices
	end
	for i = 1, 10 do
		local c, name = GetChannelName(i)
		channelNames[i] = c ~= 0 and name or false
	end
	channelList = ZPerl.RaidAdmin.GetChannelList()
	channelChoices = {}
	for i, entry in ipairs(channelList) do
		local clr = entry.color
		channelChoices[i] = {i, format("|cFF%02X%02X%02X%s|r", clr.r * 255, clr.g * 255, clr.b * 255, entry.display or ""), entry = entry}
	end
	return channelChoices
end

local function IsOutputChannel(entry)
	return entry.channel == outputChannel and (outputChannel ~= "CHANNEL" or entry.index == outputChannelIndex)
end

-- The button shows the chosen channel in its chat color
local function ChannelButtonText(dd)
	for i, c in ipairs(ChannelChoices()) do
		if (IsOutputChannel(c.entry)) then
			outputChannelSelection = i
			local clr = c.entry.color
			outputChannelColor = {clr.r, clr.g, clr.b}
			dd:OverrideText(c.entry.display or "")
			if (dd.Text) then
				dd.Text:SetTextColor(clr.r, clr.g, clr.b)
			end
			return
		end
	end
end

-- ZPerl.RaidAdmin.CheckChannelsOnLoad
function ZPerl.RaidAdmin.CheckChannelsOnLoad(self)
	if (not outputChannelSelection) then
		outputChannelSelection = 1
	end

	self:SetSize(140, 26)
	local dd = CreateFrame("DropdownButton", nil, self, "WowStyle1DropdownTemplate")
	dd:SetWidth(120)
	dd:SetPoint("LEFT", 18, 0)
	ZPerl.DropdownPicker(dd, {
		isSelected = function(c) return IsOutputChannel(c.entry) end,
		pick = function(c)
			outputChannel = c.entry.channel
			outputChannelIndex = c.entry.index
		end,
		refresh = function() ChannelButtonText(dd) end,
	}, ChannelChoices)
	-- The frame's tooltip, over the button that covers it
	dd:HookScript("OnEnter", function() self:GetScript("OnEnter")(self) end)
	dd:HookScript("OnLeave", function() GameTooltip:Hide() end)
	self.dropdown = dd
	ChannelButtonText(dd)
end
