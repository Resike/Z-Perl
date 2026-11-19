-- License: GNU GPL v3, 29 June 2007
--
-- Hides chosen buffs on the Target, Focus, Target's Target and Focus Target
-- frames. The only links to the core are ZPerl.AuraBlacklist.Set (read by
-- ZPerl.AurasRebuild) and an entry in ZPerl.SettingsPages for its tab in the options window.

local L = ZPerl.L

if (not ZPerl.AurasUpdate or not ZPerl.CanAccess or not ZPerl.SafeBool) then
	return
end

-- Upvalues
local floor = floor
local format = format
local max = max
local next = next
local pairs = pairs
local sort = table.sort
local strlower = strlower
local strtrim = strtrim
local tonumber = tonumber
local type = type
local wipe = wipe

local C_Spell = C_Spell
local CreateFrame = CreateFrame
local GameTooltip_Hide = GameTooltip_Hide
local UnitExists = UnitExists

local BaseScrollBoxEvents = BaseScrollBoxEvents
local ScrollBoxConstants = ScrollBoxConstants

local GameTooltip = GameTooltip

local CanAccess = ZPerl.CanAccess
local GetSpellTextureFunc = (C_Spell and C_Spell.GetSpellTexture) or GetSpellTexture

local ADDON_NAME = "ZPerl"
local QUESTION_MARK = "Interface\\Icons\\INV_Misc_QuestionMark"
local ROWS = 16
local ROW_HEIGHT = 22

-- self.partyid of the frames that are filtered
local filteredUnits = {
	target = true,
	focus = true,
	targettarget = true,
	focustarget = true,
}

-- Units searched when a buff is added by name
local scanUnits = {"target", "focus", "targettarget", "focustarget", "player"}

local db			-- ZPerlDB.account.blacklist
local spells		-- db.spells: [spellID] = {name = "..."}
local sorted = {}	-- spell IDs in display order
local listOffset = 0	-- sorted index above the first row of the options list
local syncing		-- the list is setting its scroll bar (its scroll callback is ours)
local sortKeys = {}
local config		-- options tab content, built the first time the tab is shown

-- SpellNameIcon(spell) - name, icon, spellID for a spell ID or name; nil if unknown
local function SpellNameIcon(spell)
	local name, icon, id
	if (C_Spell and C_Spell.GetSpellInfo) then
		local info = C_Spell.GetSpellInfo(spell)
		if (info) then
			name, icon, id = info.name, info.iconID, info.spellID
		end
	elseif (GetSpellInfo) then
		local _
		name, _, icon, _, _, _, id = GetSpellInfo(spell)
	end
	if (not CanAccess(name)) then
		return nil
	end
	return name, icon, id
end

-- DisplayName(id, entry)
local function DisplayName(id, entry)
	return entry.name or format(L["AURABL_SPELL"], id)
end

-- SortByName
local function SortByName(a, b)
	local ka, kb = sortKeys[a], sortKeys[b]
	if (ka ~= kb) then
		return ka < kb
	end
	return a < b
end

-- RebuildSorted() - only after add / remove / import, never per frame
local function RebuildSorted()
	wipe(sorted)
	wipe(sortKeys)
	if (not spells) then
		return
	end
	for id, entry in pairs(spells) do
		sorted[#sorted + 1] = id
		sortKeys[id] = strlower(DisplayName(id, entry))
	end
	sort(sorted, SortByName)
end

-- GetBBFList() - BetterBlizzFrames' blacklist (read only), or nil
local function GetBBFList()
	---@diagnostic disable-next-line: undefined-global
	local bbf = BetterBlizzFramesDB
	if (type(bbf) == "table" and type(bbf.auraBlacklist) == "table") then
		return bbf.auraBlacklist
	end
end

-- InitDB() - on our ADDON_LOADED (SavedVariables are ready then)
local function InitDB()
	-- Account-wide, outside layouts.
	local cfg = ZPerlDB
	if (type(cfg.account) ~= "table") then
		cfg.account = {}
	end
	if (type(cfg.account.blacklist) ~= "table") then
		cfg.account.blacklist = {}
	end
	db = cfg.account.blacklist
	if (db.enabled == nil) then
		db.enabled = true
	end
	if (type(db.spells) ~= "table") then
		db.spells = {}
	end
	-- Drop anything that is not [integer] = table, and bad names, so lookups and sorting stay safe
	for id, entry in pairs(db.spells) do
		if (type(id) ~= "number" or id ~= floor(id) or id < 1 or id > 2^31 or type(entry) ~= "table") then
			db.spells[id] = nil
		elseif (type(entry.name) ~= "string") then
			entry.name = nil
		end
	end
	spells = db.spells
end

-- Aura exclusion ------------------------------------------------------------
-- ZPerl.AurasRebuild asks ZPerl.AuraBlacklist.Set(frame) for the spell IDs to drop from the frame's
-- buff group and merges them into the group's candidate filters (ZPerl.AurasGroups). The set holds
-- every listed ID: Blizzard skips excludeSpellIDs per aura where identity filtering is not permitted,
-- never-secret spells excepted (AuraContainerUtil.CanApplyIdentityCandidateFilters).

local excludeSet		-- [spellID] = true for every listed ID; nil when the list is empty
local setDirty = true	-- rebuild the set on next use

function ZPerl.AuraBlacklist.Set(frame)
	if (not db or not db.enabled or not frame or not filteredUnits[frame.partyid]) then
		return nil
	end
	if (setDirty) then
		local all = {}
		for id in pairs(spells) do
			all[id] = true
		end
		excludeSet = next(all) and all or nil
		setDirty = nil
	end
	return excludeSet
end

-- Refresh(frame) - rebuild the frame's containers with the current list (a rebuild in combat stays
-- pending until auras are readable), then show the result
local function Refresh(frame)
	if (frame and frame.buffContainer) then
		ZPerl.AurasRebuild(frame)
		if (frame:IsShown()) then
			ZPerl.AurasUpdate(frame)
		end
	end
end

local function RefreshFrames()
	Refresh(ZPerl_Target)
	Refresh(ZPerl_Focus)
	Refresh(ZPerl_TargetTarget)
	Refresh(ZPerl_FocusTarget)
end

-- Load() - the login path again: read the saved list, drop the cached set, rebuild the frames
function ZPerl.AuraBlacklist.Load()
	InitDB()
	setDirty = true
	-- the options list shows the sorted IDs of the list it last saw: re-read the new one (the list redraws on show)
	RebuildSorted()
	RefreshFrames()
end

-- Config_UpdateList() - fills the visible rows only
local function Config_UpdateList()
	if (not config or not config:IsVisible() or not spells) then
		return
	end
	local total = #sorted
	local range = max(0, total - ROWS)
	if (listOffset > range) then
		listOffset = range
	end
	local offset = listOffset
	-- the bar shows the rows in view out of all, and steps (arrows, wheel) one row at a time
	local bar = config.scrollBar
	syncing = true
	bar:SetVisibleExtentPercentage(total > ROWS and ROWS / total or 1)
	bar:SetPanExtentPercentage(range > 0 and 1 / range or 0)
	bar:SetScrollPercentage(range > 0 and offset / range or 0, ScrollBoxConstants.NoScrollInterpolation)
	syncing = nil
	for i = 1, ROWS do
		local row = config.rows[i]
		local id = sorted[offset + i]
		local entry = id and spells[id]
		if (entry) then
			row.spellID = id
			row.icon:SetTexture((GetSpellTextureFunc and GetSpellTextureFunc(id)) or QUESTION_MARK)
			row.name:SetText(DisplayName(id, entry))
			row.idText:SetText(id)
			row:Show()
		else
			row.spellID = nil
			row:Hide()
		end
	end
	config.count:SetText(format(L["AURABL_COUNT"], total))
	config.enable:SetChecked(db.enabled and true or false)
	config.import:SetEnabled(GetBBFList() ~= nil)
end

-- ListChanged(resort) - after any change to the list or the master toggle
local function ListChanged(resort)
	if (resort) then
		RebuildSorted()
		setDirty = true
	end
	Config_UpdateList()
	RefreshFrames()
end

-- FindAuraByName(name) - spell ID of a readable helpful aura with exactly this name
local function FindAuraByName(name)
	local lname = strlower(name)
	for u = 1, #scanUnits do
		local unit = scanUnits[u]
		if (UnitExists(unit)) then
			for i = 1, 40 do
				local auraName, _, _, _, _, _, _, _, _, spellID = ZPerl.UnitAuraByIndex(unit, i, "HELPFUL")
				if (not auraName) then
					break
				end
				if (CanAccess(auraName) and CanAccess(spellID) and strlower(auraName) == lname) then
					return spellID
				end
			end
		end
	end
end

-- AddSpell(text) - text is a spell ID or an exact spell name. Returns true when added.
local function AddSpell(text)
	text = strtrim(text or "")
	if (text == "" or not spells) then
		return
	end

	local id = tonumber(text)
	local name
	if (id) then
		-- Whole numbers from 1 to 2^31 only (rejects fractions, inf and nan)
		if (id > 0 and id <= 2^31 and id == floor(id)) then
			name = SpellNameIcon(id)
		end
		if (not name) then
			ZPerl.Notice(L["AURABL_NOTFOUND"], text)
			return
		end
	else
		id = FindAuraByName(text)
		if (id) then
			name = SpellNameIcon(id) or text
		else
			local _
			name, _, id = SpellNameIcon(text)
			if (not id or not name or strlower(name) ~= strlower(text)) then
				ZPerl.Notice(L["AURABL_NOTFOUND"], text)
				return
			end
		end
	end

	if (spells[id]) then
		ZPerl.Notice(L["AURABL_EXISTS"], DisplayName(id, spells[id]), id)
		return
	end

	spells[id] = {name = name}
	ZPerl.Notice(L["AURABL_ADDED"], name, id)
	ListChanged(true)
	return true
end

-- ImportBBF() - merge BetterBlizzFramesDB.auraBlacklist; never writes to BBF
local function ImportBBF()
	local src = GetBBFList()
	if (not src or not spells) then
		ZPerl.Notice(L["AURABL_IMPORT_NONE"])
		return
	end

	local added, existing, skipped = 0, 0, 0
	for key, entry in pairs(src) do
		local id = tonumber(key)
		if (not id and type(entry) == "table" and entry.id) then
			id = tonumber(entry.id)
		end
		if (id and id > 0 and id <= 2^31 and id == floor(id)) then
			if (spells[id]) then
				existing = existing + 1
			else
				local name
				if (type(entry) == "table") then
					if (type(entry.name) == "string" and entry.name ~= "") then
						name = entry.name
					end
				end
				spells[id] = {name = name or SpellNameIcon(id)}
				added = added + 1
			end
		else
			skipped = skipped + 1
		end
	end

	ZPerl.Notice(L["AURABL_IMPORTED"], added, existing, skipped)
	if (added > 0) then
		ListChanged(true)
	end
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

local function Row_OnEnter(self)
	if (self.spellID and GameTooltip.SetSpellByID) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(self.spellID)
		GameTooltip:Show()
	end
end

-- The wheel over the list or its rows steps the scroll bar a row
local function List_OnMouseWheel(self, delta)
	local bar = config and config.scrollBar
	if (bar) then
		bar:ScrollStepInDirection(-delta)
	end
end

local function Remove_OnClick(self)
	local row = self:GetParent()
	if (row.spellID and spells[row.spellID]) then
		spells[row.spellID] = nil
		ListChanged(true)
	end
end

local function CreateLabel(parent, text, font)
	local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormalSmall")
	label:SetText(text)
	return label
end

-- CreateRow(list, i)
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
	row.name:SetSize(216, ROW_HEIGHT)
	row.name:SetJustifyH("LEFT")
	row.name:SetWordWrap(false)

	row.idText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	row.idText:SetPoint("LEFT", 248, 0)
	row.idText:SetSize(64, ROW_HEIGHT)
	row.idText:SetJustifyH("LEFT")

	row.remove = CreateFrame("Button", nil, row, "UIPanelCloseButton")
	row.remove:SetSize(22, 22)
	row.remove:SetPoint("LEFT", 318, 0)
	row.remove.tooltipTitle = L["AURABL_REMOVE"]
	row.remove:SetScript("OnClick", Remove_OnClick)
	row.remove:SetScript("OnEnter", ShowTooltip)
	row.remove:SetScript("OnLeave", GameTooltip_Hide)

	row:Hide()
	return row
end

-- CreateConfig(parent) - the options tab content, built the first time the tab is shown
local function CreateConfig(parent)
	local f = CreateFrame("Frame", "ZPerl_AuraBlacklist_Config", parent)
	-- the controls sit 12 px in from f's edge: shifted back so they line up with the settings tabs' rows
	f:SetPoint("TOPLEFT", -12, 0)
	f:SetSize(460, 510)

	-- Master toggle
	local enable = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
	enable:SetSize(24, 24)
	enable:SetPoint("TOPLEFT", 12, -10)
	enable:SetScript("OnClick", function(self)
		db.enabled = self:GetChecked() and true or false
		ListChanged(false)
	end)
	local enableLabel = CreateLabel(f, L["AURABL_ENABLE"], "GameFontHighlight")
	enableLabel:SetPoint("LEFT", enable, "RIGHT", 2, 0)
	f.enable = enable

	-- Import from BetterBlizzFrames
	local import = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	import:SetSize(200, 22)
	import:SetPoint("TOPRIGHT", -14, -11)
	import:SetText(L["AURABL_IMPORT"])
	import:SetScript("OnClick", ImportBBF)
	import.tooltipTitle = L["AURABL_IMPORT"]
	import.tooltipText = L["AURABL_IMPORT_DESC"]
	import:SetScript("OnEnter", ShowTooltip)
	import:SetScript("OnLeave", GameTooltip_Hide)
	if (import.SetMotionScriptsWhileDisabled) then
		import:SetMotionScriptsWhileDisabled(true)
	end
	f.import = import

	-- Add by spell ID or exact name
	local addLabel = CreateLabel(f, L["AURABL_ADD_DESC"])
	addLabel:SetPoint("TOPLEFT", 16, -44)

	local edit = CreateFrame("EditBox", "ZPerl_AuraBlacklist_ConfigAdd", f, "InputBoxTemplate")
	edit:SetSize(260, 20)
	edit:SetPoint("TOPLEFT", 22, -60)
	edit:SetAutoFocus(false)
	edit:SetMaxLetters(100)
	local function DoAdd()
		if (AddSpell(edit:GetText())) then
			edit:SetText("")
		end
		edit:ClearFocus()
	end
	edit:SetScript("OnEnterPressed", DoAdd)
	edit:SetScript("OnEscapePressed", edit.ClearFocus)

	local add = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	add:SetSize(80, 22)
	add:SetPoint("LEFT", edit, "RIGHT", 8, 0)
	add:SetText(L["AURABL_ADD"])
	add:SetScript("OnClick", DoAdd)

	-- List
	local list = CreateFrame("Frame", nil, f, "ZPerl_BackdropTemplate")
	list:SetPoint("TOPLEFT", 12, -108)
	list:SetPoint("BOTTOMRIGHT", -12, 34)
	list:SetBackdrop(ZPerl.TooltipEdge9)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", List_OnMouseWheel)

	local colName = CreateLabel(f, L["AURABL_COL_NAME"])
	colName:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 32, 2)
	local colID = CreateLabel(f, L["AURABL_COL_ID"])
	colID:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 256, 2)

	-- Blizzard's minimal scroll bar (as in the game's settings); the rows show sorted[listOffset + 1 ...]
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
			Config_UpdateList()
		end
	end, f)
	f.scrollBar = scrollBar

	f.rows = {}
	for i = 1, ROWS do
		f.rows[i] = CreateRow(list, i)
	end

	local count = CreateLabel(f, "")
	count:SetPoint("BOTTOMLEFT", 16, 14)
	f.count = count

	f:SetScript("OnShow", Config_UpdateList)
	-- Switching tab or closing the options must not leave the add box focused
	f:SetScript("OnHide", function()
		edit:ClearFocus()
	end)
	return f
end

-- Our tab in Z-Perl's options window. The window (the ZPerl_Options addon) makes a tab of each entry and a frame it passes to
-- create(), the first time the tab is shown.
ZPerl.SettingsPages = ZPerl.SettingsPages or {}
tinsert(ZPerl.SettingsPages, {
	key = "AuraBlacklist",
	name = "Aura blacklist",
	create = function(page)
		config = CreateConfig(page)
		RebuildSorted()
		Config_UpdateList()
	end,
})

local function onAddonLoaded(_, name)
	if (name == ADDON_NAME) then
		InitDB()
		ZPerl.Off("ADDON_LOADED", onAddonLoaded)
		-- frames built before the list was loaded rebuild with it
		RefreshFrames()
	end
end
ZPerl.On("ADDON_LOADED", onAddonLoaded)
