-- Author: Resike
-- License: GNU GPL v3, 29 June 2007
--
-- The editor of the custom highlight list: a tab of Z-Perl's options window (through ZPerl.SettingsPages, like the aura
-- blacklist). The list is ZPerl.layout.custom.zones = {[zone name] = {[spellID] = true}}, per layout; the raid frames show
-- an icon for a debuff of the current zone's list (ZPerl_CustomHighlight.lua). Every change runs the "custom" applier,
-- which re-reads the current zone.

if (not ZPerl.RequestConfig or not _G.ZPerl_Custom) then
	return
end

-- Upvalues
local floor = floor
local format = format
local ipairs = ipairs
local max = max
local pairs = pairs
local sort = table.sort
local strlower = strlower
local strtrim = strtrim
local tonumber = tonumber
local type = type
local wipe = wipe

local C_Spell = C_Spell
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GameTooltip_Hide = GameTooltip_Hide
local GetRealZoneText = GetRealZoneText

local BaseScrollBoxEvents = BaseScrollBoxEvents
local ScrollBoxConstants = ScrollBoxConstants

local CustomHighlight = _G.ZPerl_Custom
-- ZPerl.OptionsL once the options window builds our tab (ZPerl_Options loads on demand); the English text until then
local L = ZPerl.L
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local ROWS = 14
local ROW_HEIGHT = 22

local config			-- The tab's content, built the first time the tab is shown
local zone				-- The zone shown in the list
local sorted = {}		-- Spell IDs of the zone, by name
local sortKeys = {}
local listOffset = 0	-- Sorted index above the first row
local syncing			-- The list is setting its scroll bar (its scroll callback is ours)

-- Zones() - the layout's zone table, made from the defaults the first time (as the highlight itself does)
local function Zones()
	local conf = ZPerl.layout and ZPerl.layout.custom
	if (type(conf) ~= "table") then
		return nil
	end
	if (type(conf.zones) ~= "table") then
		conf.zones = CustomHighlight:DefaultZoneData()
	end
	return conf.zones
end

-- SpellInfo(spell) - name, icon, spellID for a spell ID or name; nil if unknown
local function SpellInfo(spell)
	if (C_Spell and C_Spell.GetSpellInfo) then
		local info = C_Spell.GetSpellInfo(spell)
		if (info and ZPerl.CanAccess(info.name)) then
			return info.name, info.iconID, info.spellID
		end
	end
end

local function Apply()
	local apply = ZPerl.Appliers and ZPerl.Appliers.custom
	if (apply) then
		apply()
	end
end

-- ZoneNames() - the zones of the list, by name
local function ZoneNames()
	local out = {}
	for name in pairs(Zones() or {}) do
		out[#out + 1] = name
	end
	sort(out, function(a, b) return strlower(a) < strlower(b) end)
	return out
end

local function CountOf(spells)
	local n = 0
	for _ in pairs(spells) do
		n = n + 1
	end
	return n
end

-- Pick() - keeps the shown zone valid: the current zone when it is listed, else the first one
local function Pick()
	local zones = Zones()
	if (not zones) then
		zone = nil
		return
	end
	if (zone and zones[zone]) then
		return
	end
	local here = GetRealZoneText()
	zone = (here and zones[here]) and here or ZoneNames()[1]
end

local function RebuildSorted()
	wipe(sorted)
	wipe(sortKeys)
	local zones = Zones()
	local spells = zone and zones and zones[zone]
	if (type(spells) ~= "table") then
		return
	end
	for id in pairs(spells) do
		if (type(id) == "number") then
			sorted[#sorted + 1] = id
			sortKeys[id] = strlower(SpellInfo(id) or format(L["Spell %d"], id))
		end
	end
	sort(sorted, function(a, b)
		if (sortKeys[a] ~= sortKeys[b]) then
			return sortKeys[a] < sortKeys[b]
		end
		return a < b
	end)
end

-- UpdateList() - fills the visible rows, the zone menu and the counts
local function UpdateList()
	if (not config or not config:IsVisible()) then
		return
	end
	local total = #sorted
	local range = max(0, total - ROWS)
	if (listOffset > range) then
		listOffset = range
	end
	local bar = config.scrollBar
	syncing = true
	bar:SetVisibleExtentPercentage(total > ROWS and ROWS / total or 1)
	bar:SetPanExtentPercentage(range > 0 and 1 / range or 0)
	bar:SetScrollPercentage(range > 0 and listOffset / range or 0, ScrollBoxConstants.NoScrollInterpolation)
	syncing = nil
	for i = 1, ROWS do
		local row = config.rows[i]
		local id = sorted[listOffset + i]
		if (id) then
			local name, icon = SpellInfo(id)
			row.spellID = id
			row.icon:SetTexture(icon or QUESTION_MARK)
			row.name:SetText(name or format(L["Spell %d"], id))
			row.idText:SetText(id)
			row:Show()
		else
			row.spellID = nil
			row:Hide()
		end
	end
	config.zoneMenu:GenerateMenu()
	if (not zone and config.zoneMenu.OverrideText) then
		config.zoneMenu:OverrideText(L["No zones"])
	end
	config.count:SetText(zone and format(L["%d spells in %s"], total, zone) or L["Add a zone to start a list."])
	config.addSpell:SetEnabled(zone ~= nil)
	config.spellEdit:SetEnabled(zone ~= nil)
	config.removeZone:SetEnabled(zone ~= nil)
end

-- Changed() - after any change to the list: re-pick, re-sort, redraw, re-read the current zone
local function Changed()
	Pick()
	RebuildSorted()
	UpdateList()
	Apply()
end

local function ShowZone(name)
	zone = name
	listOffset = 0
	RebuildSorted()
	UpdateList()
end

-- AddZone(text) - a zone name as the game writes it (GetRealZoneText). Returns true when added.
local function AddZone(text)
	local zones = Zones()
	text = strtrim(text or "")
	if (text == "" or not zones) then
		return
	end
	if (not zones[text]) then
		zones[text] = {}
		Changed()
	end
	ShowZone(text)
	return true
end

-- AddSpell(text) - a spell ID or an exact spell name, to the shown zone. Returns true when added.
local function AddSpell(text)
	local zones = Zones()
	text = strtrim(text or "")
	if (text == "" or not zone or not zones or not zones[zone]) then
		return
	end
	local id = tonumber(text)
	local name
	if (id) then
		if (id > 0 and id <= 2^31 and id == floor(id)) then
			name = SpellInfo(id)
		end
	else
		local _, found
		name, _, found = SpellInfo(text)
		if (name and strlower(name) == strlower(text)) then
			id = found
		else
			name = nil
		end
	end
	if (not name or not id) then
		ZPerl.Notice(id and L["Custom highlights: no spell %s."] or L["Custom highlights: no spell %s by name; use its spell ID."], text)
		return
	end
	if (zones[zone][id]) then
		ZPerl.Notice(L["Custom highlights: %s (%d) is already in %s."], name, id, zone)
		return
	end
	zones[zone][id] = true
	Changed()
	return true
end

local function Confirm(text, fn)
	StaticPopup_Show("ZPERL_SETTINGS_CONFIRM", text, nil, fn)
end

local function RemoveZone()
	local zones = Zones()
	if (not zone or not zones) then
		return
	end
	local name = zone
	Confirm(format(L["Remove %s and its %d spells from the custom highlight list?"], name, CountOf(zones[name] or {})), function()
		zones[name] = nil
		if (zone == name) then
			zone = nil
		end
		listOffset = 0
		Changed()
	end)
end

local function ResetDefaults()
	Confirm(L["Reset the custom highlight list of this layout to the default zones and spells? Zones and spells you added are lost."], function()
		local conf = ZPerl.layout and ZPerl.layout.custom
		if (type(conf) == "table") then
			conf.zones = CustomHighlight:DefaultZoneData()
			zone = nil
			listOffset = 0
			Changed()
		end
	end)
end

-- Tooltips
local function ShowTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(self.tooltipTitle, 1, 1, 1)
	if (self.tooltipText) then
		GameTooltip:AddLine(self.tooltipText, nil, nil, nil, true)
	end
	GameTooltip:Show()
end
local function Tip(frame, title, text)
	frame.tooltipTitle, frame.tooltipText = title, text
	frame:SetScript("OnEnter", ShowTooltip)
	frame:SetScript("OnLeave", GameTooltip_Hide)
	if (frame.SetMotionScriptsWhileDisabled) then
		frame:SetMotionScriptsWhileDisabled(true)
	end
end

local function Row_OnEnter(self)
	if (self.spellID and GameTooltip.SetSpellByID) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(self.spellID)
		GameTooltip:Show()
	end
end

-- The wheel over the list or its rows steps the scroll bar a row
local function List_OnMouseWheel(_, delta)
	local bar = config and config.scrollBar
	if (bar) then
		bar:ScrollStepInDirection(-delta)
	end
end

local function Remove_OnClick(self)
	local id = self:GetParent().spellID
	local zones = Zones()
	if (id and zone and zones and zones[zone]) then
		zones[zone][id] = nil
		Changed()
	end
end

local function Label(parent, text, font)
	local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormalSmall")
	label:SetText(text)
	return label
end

local function CreateRow(list, i)
	local row = CreateFrame("Frame", nil, list)
	row:SetSize(400, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -8 - (i - 1) * ROW_HEIGHT)
	row:EnableMouse(true)
	row:EnableMouseWheel(true)
	row:SetScript("OnEnter", Row_OnEnter)
	row:SetScript("OnLeave", GameTooltip_Hide)
	row:SetScript("OnMouseWheel", List_OnMouseWheel)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(18, 18)
	row.icon:SetPoint("LEFT", 0, 0)
	row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", 24, 0)
	row.name:SetSize(260, ROW_HEIGHT)
	row.name:SetJustifyH("LEFT")
	row.name:SetWordWrap(false)

	row.idText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	row.idText:SetPoint("LEFT", 292, 0)
	row.idText:SetSize(70, ROW_HEIGHT)
	row.idText:SetJustifyH("LEFT")

	row.remove = CreateFrame("Button", nil, row, "UIPanelCloseButton")
	row.remove:SetSize(22, 22)
	row.remove:SetPoint("LEFT", 370, 0)
	row.remove:SetScript("OnClick", Remove_OnClick)
	Tip(row.remove, L["Remove"], L["Remove this spell from the zone's list."])

	row:Hide()
	return row
end

-- An edit box with a button beside it; Enter or the button runs fn(text), which returns true to clear the box
local function EditWithButton(f, y, width, label, buttonText, fn)
	local edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	edit:SetSize(width, 20)
	edit:SetPoint("TOPLEFT", 22, y)
	edit:SetAutoFocus(false)
	edit:SetMaxLetters(100)
	local text = Label(f, label)
	text:SetPoint("BOTTOMLEFT", edit, "TOPLEFT", -6, 2)
	local function run()
		if (fn(edit:GetText())) then
			edit:SetText("")
		end
		edit:ClearFocus()
	end
	edit:SetScript("OnEnterPressed", run)
	edit:SetScript("OnEscapePressed", edit.ClearFocus)
	local button = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	button:SetSize(90, 22)
	button:SetPoint("LEFT", edit, "RIGHT", 8, 0)
	button:SetText(buttonText)
	button:SetScript("OnClick", run)
	return edit, button
end

local function CreateConfig(parent)
	local f = CreateFrame("Frame", "ZPerl_CustomHighlight_Config", parent)
	-- The controls sit 12 px in from f's edge: shifted back so they line up with the settings tabs' rows
	f:SetPoint("TOPLEFT", -12, 0)
	f:SetSize(460, 560)

	-- Zone picker and Remove zone
	local zoneLabel = Label(f, L["Zone"])
	zoneLabel:SetPoint("TOPLEFT", 16, -12)
	local menu = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
	menu:SetWidth(300)
	menu:SetPoint("TOPLEFT", 14, -28)
	menu:SetupMenu(function(_, root)
		local names = ZoneNames()
		if (#names > 20 and root.SetScrollMode) then
			root:SetScrollMode(20 * 20)
		end
		local zones = Zones() or {}
		for _, name in ipairs(names) do
			root:CreateRadio(format("%s (%d)", name, CountOf(zones[name])), function() return zone == name end, function() ShowZone(name) end)
		end
	end)
	f.zoneMenu = menu

	local removeZone = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	removeZone:SetSize(110, 22)
	removeZone:SetPoint("LEFT", menu, "RIGHT", 8, 0)
	removeZone:SetText(L["Remove zone"])
	removeZone:SetScript("OnClick", RemoveZone)
	Tip(removeZone, L["Remove zone"], L["Remove the shown zone and all its spells from the list, after a confirmation."])
	f.removeZone = removeZone

	-- Add zone: typed, or the zone you are in
	local _, addZone = EditWithButton(f, -76, 220, L["Add a zone (its name as the game shows it)"], L["Add zone"], AddZone)
	Tip(addZone, L["Add zone"], L["Add a zone with an empty list and show it. The name must match the game's zone name exactly."])
	local here = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	here:SetSize(110, 22)
	here:SetPoint("LEFT", addZone, "RIGHT", 6, 0)
	here:SetText(L["Current zone"])
	here:SetScript("OnClick", function() AddZone(GetRealZoneText()) end)
	Tip(here, L["Current zone"], L["Add the zone you are in (or show it, when it is listed)."])

	-- Add spell to the shown zone
	local spellEdit, addSpell = EditWithButton(f, -124, 220, L["Add a debuff to this zone (spell ID)"], L["Add spell"], AddSpell)
	Tip(addSpell, L["Add spell"], L["Add a debuff by its spell ID. A raid member with that exact spell shows its icon. An exact name works only for spells the game can look up by name, mostly ones you know, so boss debuffs need their ID."])
	f.spellEdit, f.addSpell = spellEdit, addSpell

	-- List
	local list = CreateFrame("Frame", nil, f, "ZPerl_BackdropTemplate")
	list:SetPoint("TOPLEFT", 12, -170)
	list:SetPoint("BOTTOMRIGHT", -12, 40)
	list:SetBackdrop(ZPerl.TooltipEdge9)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", List_OnMouseWheel)

	local colName = Label(f, L["Name"])
	colName:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 32, 2)
	local colID = Label(f, L["Spell ID"])
	colID:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 300, 2)

	local scrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
	scrollBar:SetPoint("TOPRIGHT", -10, -8)
	scrollBar:SetPoint("BOTTOMRIGHT", -10, 8)
	scrollBar:RegisterCallback(BaseScrollBoxEvents.OnScroll, function(_, percentage)
		if (syncing) then
			return
		end
		local range = max(0, #sorted - ROWS)
		local offset = floor(percentage * range + 0.5)
		if (offset ~= listOffset) then
			listOffset = offset
			UpdateList()
		end
	end, f)
	f.scrollBar = scrollBar

	f.rows = {}
	for i = 1, ROWS do
		f.rows[i] = CreateRow(list, i)
	end

	local count = Label(f, "")
	count:SetPoint("BOTTOMLEFT", 16, 18)
	f.count = count

	local reset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	reset:SetSize(150, 22)
	reset:SetPoint("BOTTOMRIGHT", -14, 12)
	reset:SetText(L["Reset to defaults"])
	reset:SetScript("OnClick", ResetDefaults)
	Tip(reset, L["Reset to defaults"], L["Put back the default zones and spells of this layout's list, after a confirmation. Zones and spells you added are lost."])

	-- A layout switch or a zone change while the tab was hidden: re-read on show
	f:SetScript("OnShow", function()
		Pick()
		RebuildSorted()
		UpdateList()
	end)
	f:SetScript("OnHide", function()
		spellEdit:ClearFocus()
	end)
	return f
end

ZPerl.SettingsPages = ZPerl.SettingsPages or {}
tinsert(ZPerl.SettingsPages, {
	key = "CustomHighlight",
	name = "Custom highlights",
	create = function(page)
		L = ZPerl.OptionsL
		config = CreateConfig(page)
		Pick()
		RebuildSorted()
		UpdateList()
	end,
})
