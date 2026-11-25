-- Author: Resike
-- License: GNU GPL v3, 29 June 2007
--
-- ZPerl.DropdownPicker: the list of a WowStyle1DropdownTemplate button, in place of its Blizzard menu. A Blizzard menu
-- builds frames, closures and layout tables for every choice on every open (its scroll mode too), garbage each time,
-- megabytes with a long LibSharedMedia list. This popup has ROWS rows, made once and shared by every dropdown that uses
-- it; scrolling rebinds them, so opening, scrolling and closing allocate nothing. It is drawn as the dropdown menus are
-- (Blizzard_Menu's MenuStyle1, radio buttons and checkboxes): the retail look, or the Classic one.

-- Upvalues
local floor = math.floor
local ipairs = ipairs
local max = math.max
local min = math.min
local pcall = pcall
local setmetatable = setmetatable

local CreateFrame = CreateFrame
local PlaySound = PlaySound

local ROWS, ROW_HEIGHT = 10, 20
local RETAIL = {
	bg = "common-dropdown-bg", bgX = 10, bgY = 3, bgBottom = 3, bgAlpha = 0.925,
	left = 8, top = 8, right = 8, bottom = 15,
	radio = "common-dropdown-tickradial", tick = "common-dropdown-icon-radialtick-yellow", radioX = -3, textX = 1,
	box = "common-dropdown-ticksquare", mark = "common-dropdown-icon-checkmark-yellow", markX = 2, markY = 1, boxX = 0, boxTextX = 7,
}
local CLASSIC = {
	bg = "common-dropdown-classic-bg", bgX = 3, bgY = 3, bgBottom = 4, bgAlpha = 1, inner = true,
	left = 16, top = 10, right = 16, bottom = 10,
	radio = "common-dropdown-tickradial-classic", tick = "common-dropdown-icon-radialtick-yellow-classic", radioX = 0, textX = 2,
	box = "common-dropdown-ticksquare-classic", mark = "common-dropdown-icon-checkmark-yellow-classic", markX = 0, markY = 0, boxX = 0, boxTextX = 2,
}

local function atlasInfo(name)
	return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
end
-- The client's own look; the other one when its atlases are missing from this client
local function pickStyle()
	local st, other = CLASSIC, RETAIL
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then st, other = other, st end
	if not atlasInfo(st.radio) and atlasInfo(other.radio) then st = other end
	return st
end
local function atlasSize(name)
	local info = atlasInfo(name)
	return info and info.width or 16, info and info.height or 16
end
-- A texture made at the atlas size, so a missing atlas leaves an empty space and not a region without size
local function atlasTexture(row, name, sub)
	local t = row:CreateTexture(nil, "ARTWORK", nil, sub)
	t:SetAtlas(name)
	t:SetSize(atlasSize(name))
	return t
end

local picker
local widths = setmetatable({}, {__mode = "k"})	-- The widest label of a list, by the list

local function lastOffset() return max(0, #picker.src.list - ROWS) end

local function redraw()
	local p = picker
	local src = p.src
	local list, check, texture, plain = src.list, src.check, src.texture, src.plain
	for i, row in ipairs(p.rows) do
		local c = list[p.offset + i]
		if c then
			row.choice = c
			local on = not plain and src.isSelected(c) and true or false
			if texture and c[3] then
				row.bar:SetTexture(c[3])
				row.bar:Show()
			else
				row.bar:Hide()
			end
			row.label:SetText(c[2])
			-- A title (c.title) is gold and takes no clicks, as in the menus
			row.label:SetFontObject(c.title and GameFontNormal or GameFontHighlight)
			row.label:SetJustifyH("LEFT")
			row:EnableMouse(not c.title)
			row.radio:SetShown(not check and not plain)
			row.tick:SetShown(not check and not plain and on)
			row.box:SetShown(check and not plain)
			row.mark:SetShown(check and not plain and on)
			row.label:SetPoint("LEFT", plain and 0 or check and p.boxText or p.radioText, 0)
			row:Show()
		else
			row.choice = nil
			row:Hide()
		end
	end
end

-- Moves the list to the row offset `to`; the scroll bar follows (its OnScroll lands back here, then changes nothing)
local function scrollTo(to)
	local p = picker
	local last = lastOffset()
	to = max(0, min(last, floor(to + 0.5)))
	if to ~= p.offset then
		p.offset = to
		redraw()
	end
	if last > 0 and p.bar.SetScrollPercentage then
		p.bar:SetScrollPercentage(to / last, true)
	end
end

local function create(dd)
	local st = pickStyle()
	local p = CreateFrame("Frame", nil, UIParent)
	p.style = st
	-- As Blizzard_Menu places its menus: an options window can share the strata, so 500 levels over the button (and at
	-- least 1000, the first owner may be a low one such as the minimap button). Set before the rows and the scroll bar
	-- are made, which take their levels from it.
	p:SetFrameStrata("FULLSCREEN_DIALOG")
	p:SetFrameLevel(min(max(dd:GetFrameLevel() + 500, 1000), 9000))
	p:SetClampedToScreen(true)
	p:EnableMouse(true)
	p:Hide()

	local bg = p:CreateTexture(nil, "BACKGROUND", nil, -7)
	bg:SetAtlas(st.bg)
	bg:SetPoint("TOPLEFT", -st.bgX, st.bgY)
	bg:SetPoint("BOTTOMRIGHT", st.bgX, -st.bgBottom)
	bg:SetAlpha(st.bgAlpha)
	if st.inner then
		local inner = p:CreateTexture(nil, "BACKGROUND", nil, -8)
		inner:SetColorTexture(0, 0, 0, 0.8)
		inner:SetPoint("TOPLEFT", bg, "TOPLEFT", 6, -6)
		inner:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -6, 6)
	end

	-- Where a name starts, after a radio or a checkbox
	p.radioText = st.radioX + atlasSize(st.radio) + st.textX
	p.boxText = st.boxX + atlasSize(st.box) + st.boxTextX
	-- Measures the labels, for the width of a list
	p.measure = p:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	p.measure:Hide()

	p.offset, p.rows = 0, {}
	local function pick(row)
		local c = row.choice
		if not c then
			return
		end
		local src = p.src
		local keep = src.pick(c)
		if src.check then
			PlaySound(src.isSelected(c) and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		else
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end
		if keep then
			redraw()
		else
			p:Hide()
		end
		if src.refresh then
			src.refresh()
		end
	end
	for i = 1, ROWS do
		local row = CreateFrame("Button", nil, p)
		row:SetHeight(ROW_HEIGHT)
		row:SetPoint("TOPLEFT", st.left, -st.top - (i - 1) * ROW_HEIGHT)
		-- The texture of the choice, behind its name
		row.bar = row:CreateTexture(nil, "BACKGROUND", nil, 1)
		row.bar:SetPoint("TOPLEFT", 0, -1)
		row.bar:SetPoint("BOTTOMRIGHT", 0, 1)
		row.bar:SetVertexColor(0, 0.8, 0, 0.8)	-- Health green
		row.radio = atlasTexture(row, st.radio, 1)
		row.radio:SetPoint("LEFT", st.radioX, 0)
		row.tick = atlasTexture(row, st.tick, 2)
		row.tick:SetPoint("TOPLEFT", row.radio, "TOPLEFT")
		row.box = atlasTexture(row, st.box, 1)
		row.box:SetPoint("LEFT", st.boxX, 0)
		row.mark = atlasTexture(row, st.mark, 2)
		row.mark:SetPoint("CENTER", row.box, "CENTER", st.markX, st.markY)
		row.label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		row.label:SetJustifyH("LEFT")
		row.label:SetPoint("LEFT", p.radioText, 0)
		row.label:SetPoint("RIGHT", -2, 0)
		row.label:SetHeight(ROW_HEIGHT)
		row.label:SetWordWrap(false)
		local hl = row:CreateTexture(nil, "BACKGROUND", nil, 2)
		hl:SetAllPoints()
		hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		hl:SetBlendMode("ADD")
		row:SetHighlightTexture(hl)
		row:SetScript("OnClick", pick)
		p.rows[i] = row
	end

	-- The menus' scroll bar, driven by hand: its percentage is the row offset over the last offset
	local bar = CreateFrame("EventFrame", nil, p, "MinimalScrollBar")
	bar:SetPoint("TOPRIGHT", -st.right, -st.top)
	bar:SetPoint("BOTTOMRIGHT", -st.right, st.bottom)
	bar:RegisterCallback(bar.Event.OnScroll, function(_, pct)
		local to = floor(pct * lastOffset() + 0.5)
		if to ~= p.offset then
			p.offset = to
			redraw()
		end
	end, p)
	p.bar = bar
	p:EnableMouseWheel(true)
	p:SetScript("OnMouseWheel", function(_, delta)
		scrollTo(p.offset - delta * 3)
	end)

	-- A click anywhere else closes it (the owner's own click toggles it)
	p:SetScript("OnEvent", function(self)
		if not self:IsMouseOver() and not (self.owner and self.owner:IsMouseOver()) then
			self:Hide()
		end
	end)
	p:SetScript("OnShow", function(self)
		pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN")
	end)
	p:SetScript("OnHide", function(self)
		self:UnregisterAllEvents()
		if self.owner then
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
		end
		self.owner = nil
	end)
	picker = p
	return p
end

-- The widest name of a list, measured once per list (each open for src.remeasure: a table refilled in place)
local function widest(p, src, list)
	local w = not src.remeasure and widths[list]
	if w then
		return w
	end
	w = 0
	local m = p.measure
	local measure = m.GetUnboundedStringWidth or m.GetStringWidth
	for _, c in ipairs(list) do
		m:SetText(c[2])
		w = max(w, measure(m))
	end
	widths[list] = w
	return w
end

local function toggle(dd, src)
	local p = picker or create(dd)
	if p:IsShown() and p.owner == dd then
		p:Hide()
		return
	end
	p:Hide()
	local st, list = p.style, src.list
	p.owner, p.src = dd, src
	local n = min(#list, ROWS)
	local scroll = #list > ROWS
	local h = n * ROW_HEIGHT + st.top + st.bottom
	-- As wide as the button, or the widest name (the menus widen to fit); the rows end at the scroll bar
	local barW = scroll and p.bar:GetWidth() + 4 or 0
	local nameX = src.plain and 0 or src.check and p.boxText or p.radioText
	local w = max(dd:GetWidth(), st.left + nameX + widest(p, src, list) + 4 + barW + st.right)
	p:SetScale(dd:GetEffectiveScale() / UIParent:GetEffectiveScale())
	p:SetSize(w, h)
	for _, row in ipairs(p.rows) do
		row:SetWidth(w - st.left - st.right - barW)
	end
	-- Below the button as the menus open, or above it when there is no room below
	p:ClearAllPoints()
	local bottom = dd:GetBottom()
	if bottom and bottom < h then
		p:SetPoint("BOTTOMLEFT", dd, "TOPLEFT", 0, 0)
	else
		p:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, 0)
	end
	p.bar:SetShown(scroll)
	if scroll then
		p.bar:Init(ROWS / #list, 1 / (#list - ROWS))
	end
	-- Opens on the (first) chosen value
	local at = 1
	if not src.plain then
		for i, c in ipairs(list) do
			if src.isSelected(c) then
				at = i
				break
			end
		end
	end
	p.offset = -1
	p:Show()
	scrollTo(at - floor(ROWS / 2))	-- Always redraws: no offset is -1
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

-- ZPerl.DropdownPicker(dd, src, getList)
-- Gives a WowStyle1DropdownTemplate button the picker for its list; its own menu is never opened, the template only
-- draws the button (its text set with dd:OverrideText). getList() hands the choices as the list opens: {key, label[,
-- file]} each, read only; the same table back is measured once. src, made once:
--   isSelected(c)	the choice is the value (a radio) or ticked (a checkbox); not asked for a plain list
--   pick(c)		a click on it; true keeps the list open
--   refresh()		optional: after a pick, to retext the button
--   check			checkboxes instead of radios
--   plain			a menu of actions: no radios or checkboxes; a choice with c.title is a gold heading
--   texture		each choice shows its file (c[3]) behind its name
--   remeasure		the list is one table refilled in place: measure its width on each open
function ZPerl.DropdownPicker(dd, src, getList)
	dd:SetupMenu(function() end)
	-- The template's OnShow (DropdownSelectionTextMixin) generates the menu each show: only once, it is empty
	local show = dd:GetScript("OnShow")
	dd:SetScript("OnShow", function(self, ...)
		if show and not self:GetMenuDescription() then
			return show(self, ...)
		end
	end)
	dd:SetScript("OnMouseDown", function(self)
		if not self:IsEnabled() then
			return
		end
		src.list = getList()
		toggle(self, src)
	end)
	dd:HookScript("OnHide", function(self)
		if picker and picker.owner == self then
			picker:Hide()
		end
	end)
end

-- ZPerl.DropdownPickerOpen(owner, src, list) - opens (or closes, when open for owner) the picker on any frame, such as
-- the minimap button's menu: src as for ZPerl.DropdownPicker, list its choices
function ZPerl.DropdownPickerOpen(owner, src, list)
	src.list = list
	toggle(owner, src)
end

-- ZPerl.DropdownPickerClose()
function ZPerl.DropdownPickerClose()
	if picker then
		picker:Hide()
	end
end

-- ZPerl.DropdownPickerRedraw(dd) - redraws the open list of dd (its choices changed state from elsewhere)
function ZPerl.DropdownPickerRedraw(dd)
	if picker and picker:IsShown() and picker.owner == dd then
		redraw()
	end
end
