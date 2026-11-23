-- ZPerl_Options, a load-on-demand addon: Z-Perl loads it the first time the window or a frame's settings popup opens
-- (ZPerl.LoadOptions, ZPerl/ZPerl_OptionsLoader.lua).
--
-- Z-Perl's own options window: a title bar (search, close), a tab list (with "Advanced options" under it) (the pages of
-- ZPerl.SettingsList, then the pages other modules add through ZPerl.SettingsPages), and the rows of the tab in their
-- sections. Controls: ZPerl_OptionsControls.lua. Values: ZPerl.SettingsCore (ZPerl_Settings.lua).
--
-- Window state (position, scale, tab, "Advanced options") is account-wide: ZPerlDB.options = {x, y, scale, tab,
-- advanced}; it is
-- not part of a layout. Which sections are open is session state.
--
-- API (also what tools/wowless/optionswindow.lua drives): ZPerl.Options.Open(tab), SelectTab(name), SetAdvanced(bool),
-- SetSearch(text), SetScale(scale), ExpandAll(), Lines(), Refresh().

local C = ZPerl.OptionsControls
local L = ZPerl.OptionsL -- The drawn text by its English wording; page and section names stay English in the state
local O = {}
ZPerl.Options = O

local WIDTH, HEIGHT, TABW = 900, 660, 150
local CONTENTW = WIDTH - TABW - 56
local COLX = C.COLW + 20

local win, scroll, content, box, advanced, tabs, reloadBtn, reloadNote
local state = {tab = "General", advanced = false, search = "", open = {}}
local lines, built = {}, {}
local heads, subs = {}, {}
local needReload = false
local tabList = {}

local function saved()
	if not ZPerlDB then return state end
	ZPerlDB.options = ZPerlDB.options or {}
	return ZPerlDB.options
end

local function pageNames()
	local out, seen = {}, {}
	for _, e in ipairs(ZPerl.SettingsList) do
		if not seen[e.page] then
			seen[e.page] = true
			out[#out + 1] = e.page
		end
	end
	for _, p in ipairs(ZPerl.SettingsPages) do out[#out + 1] = p.name end
	return out
end
local function pageOf(name)
	for _, p in ipairs(ZPerl.SettingsPages) do
		if p.name == name then return p end
	end
end

------------------------------------------------------------------------------------------------ Layout
local function sectionOpen(sec)
	local o = state.open[sec.key]
	if o == nil then return sec.hasBasic end
	return o
end

-- The sections to show, each {key, page, name, rows, hasBasic, lines = {rows...}}. Kept while the tab, "Show
-- advanced options", the search and the rows' `showif` results stay the same, so opening the window again (or a
-- refresh-only layout) builds no tables.
-- The search matches the English text and the translation, so either finds a row.
local function matches(s, q)
	if type(s) ~= "string" or s == "" then return false end
	if s:lower():find(q, 1, true) then return true end
	local t = L[s]
	return t ~= s and t:lower():find(q, 1, true) ~= nil
end
local cache = {secs = nil, tab = nil, advanced = nil, search = nil, showifs = {}, results = {}}
local function cacheValid()
	if not cache.secs or cache.tab ~= state.tab or cache.advanced ~= state.advanced or cache.search ~= state.search then
		return false
	end
	for i, e in ipairs(cache.showifs) do
		if (e.showif() and true or false) ~= cache.results[i] then return false end
	end
	return true
end
local function collect()
	if cacheValid() then return cache.secs end
	local showifs, results = cache.showifs, cache.results
	wipe(showifs)
	wipe(results)
	local secs, byKey = {}, {}
	local q = state.search ~= "" and state.search:lower() or nil
	for _, e in ipairs(ZPerl.SettingsList) do
		local want
		if q then
			want = matches(e.label, q) or matches(e.tip, q)
		else
			want = e.page == state.tab and (state.advanced or e.basic)
		end
		local shown = true
		if want and e.showif then
			shown = e.showif() and true or false
			showifs[#showifs + 1] = e
			results[#results + 1] = shown
		end
		if want and shown then
			local key = e.page .. "|" .. e.section
			local sec = byKey[key]
			if not sec then
				sec = {key = key, page = e.page, name = e.section, lines = {}, tags = {}, hasBasic = false}
				byKey[key] = sec
				secs[#secs + 1] = sec
			end
			if e.basic then sec.hasBasic = true end
			if e.inline and sec.tags[e.inline] then
				local rows = sec.tags[e.inline]
				rows[#rows + 1] = e
			else
				local rows = {e}
				sec.lines[#sec.lines + 1] = rows
				if e.inline then sec.tags[e.inline] = rows end
			end
		end
	end
	cache.secs, cache.tab, cache.advanced, cache.search = secs, state.tab, state.advanced, state.search
	return secs
end

-- The line of a rows list; remembered on the list (kept by the section cache), so a layout of the same view
-- builds no lookup key.
local function lineFor(rows)
	if rows.line then return rows.line end
	local key = {}
	for i, r in ipairs(rows) do key[i] = r.id end
	key = table.concat(key, "|")
	local l = built[key]
	if not l then
		l = C.Make(content, rows)
		built[key] = l
	end
	rows.line = l
	return l
end

local function head(i)
	local h = heads[i]
	if not h then
		h = CreateFrame("Button", nil, content)
		h:SetHeight(24)
		-- A gold rule under the title, fading out to the right
		h.line = h:CreateTexture(nil, "BORDER")
		h.line:SetTexture("Interface\\Buttons\\WHITE8X8")
		h.line:SetHeight(1)
		h.line:SetPoint("BOTTOMLEFT")
		h.line:SetPoint("BOTTOMRIGHT")
		h.line:SetGradient("HORIZONTAL", CreateColor(0.86, 0.72, 0.2, 0.8), CreateColor(0.86, 0.72, 0.2, 0))
		-- The open/closed state of a collapsible section: a minus when open, a plus when closed
		h.icon = h:CreateTexture(nil, "ARTWORK")
		h.icon:SetSize(14, 14)
		h.icon:SetPoint("LEFT", 4, 0)
		h.fs = h:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		h.fs:SetPoint("LEFT", 6, 0)
		h.count = h:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		h.count:SetPoint("LEFT", h.fs, "RIGHT", 6, 0)
		h:SetScript("OnClick", function(self)
			if self.sec then
				state.open[self.sec.key] = not sectionOpen(self.sec)
				O.Layout()
			end
		end)
		heads[i] = h
	end
	return h
end
local function sub(i)
	local s = subs[i]
	if not s then
		s = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		-- A faint rule from the label to the right edge of the content
		s.rule = content:CreateTexture(nil, "BACKGROUND")
		s.rule:SetTexture("Interface\\Buttons\\WHITE8X8")
		s.rule:SetHeight(1)
		s.rule:SetPoint("LEFT", s, "RIGHT", 8, 0)
		s.rule:SetPoint("RIGHT", content, "RIGHT", -4, 0)
		s.rule:SetGradient("HORIZONTAL", CreateColor(0.6, 0.6, 0.6, 0.5), CreateColor(0.6, 0.6, 0.6, 0))
		subs[i] = s
	end
	return s
end

function O.Layout()
	if not win then return end
	for _, l in pairs(built) do l.box:Hide() end
	for _, h in ipairs(heads) do h:Hide() end
	for _, s in ipairs(subs) do
		s:Hide()
		s.rule:Hide()
	end
	wipe(lines)
	local searching = state.search ~= ""
	local pg = pageOf(state.tab)
	if pg and not searching then
		scroll:Hide()
		-- Another module page (e.g. Aura blacklist -> Custom highlights) must not stay under this one
		for _, p in ipairs(ZPerl.SettingsPages) do
			if p ~= pg and p.frame then p.frame:Hide() end
		end
		if not pg.frame then
			pg.frame = CreateFrame("Frame", nil, win)
			pg.frame:SetPoint("TOPLEFT", scroll, "TOPLEFT")
			pg.frame:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT")
			xpcall(pg.create, geterrorhandler(), pg.frame)
		end
		pg.frame:Show()
		return
	end
	for _, p in ipairs(ZPerl.SettingsPages) do
		if p.frame then p.frame:Hide() end
	end
	scroll:Show()

	local y, nh, ns = 0, 0, 0
	local col, rowTop, rowH = 0, 0, 0
	-- (a closure made here would be garbage on every layout: the column flush is written out where it is needed)
	local lastPage
	for _, sec in ipairs(collect()) do
		if col == 1 then y = rowTop - rowH - 4 end col = 0
		local n = #sec.lines
		local h
		nh = nh + 1
		h = head(nh)
		h:ClearAllPoints()
		h:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
		h:SetWidth(CONTENTW)
		h.sec = nil
		local title = L[sec.name]
		if searching and sec.page ~= lastPage then title = L[sec.page] .. ": " .. L[sec.name] end
		lastPage = sec.page
		local open = true
		if not searching and state.advanced then
			h.sec = sec
			open = sectionOpen(sec)
			h.count:SetText("(" .. n .. ")")
			h.count:Show()
			h.icon:SetTexture(open and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
			h.icon:Show()
			h.fs:SetPoint("LEFT", 22, 0)
		else
			h.count:Hide()
			h.icon:Hide()
			h.fs:SetPoint("LEFT", 6, 0)
		end
		h.fs:SetText(title)
		h:Show()
		y = y - 30
		if open then
			local group
			for _, rows in ipairs(sec.lines) do
				local e = rows[1]
				local l = lineFor(rows)
				if e.group ~= group then
					group = e.group
					if group then
						if col == 1 then y = rowTop - rowH - 4 end col = 0
						ns = ns + 1
						local s = sub(ns)
						s:ClearAllPoints()
						s:SetPoint("TOPLEFT", content, "TOPLEFT", 4, y)
						s:SetText(L[group])
						s:Show()
						s.rule:Show()
						y = y - 18
					end
				end
				l.box:ClearAllPoints()
				if l.full then
					if col == 1 then y = rowTop - rowH - 4 end col = 0
					l.box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
					y = y - l.h - 4
				elseif col == 0 then
					rowTop, rowH, col = y, l.h, 1
					l.box:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
				else
					rowH = math.max(rowH, l.h)
					l.box:SetPoint("TOPLEFT", content, "TOPLEFT", COLX, rowTop)
					y = rowTop - rowH - 4
					col = 0
				end
				l.box:Show()
				lines[#lines + 1] = l
			end
		end
		if col == 1 then y = rowTop - rowH - 4 end col = 0
		y = y - 8
	end
	content:SetSize(CONTENTW, math.max(1, -y + 10))
	O.Refresh()
end

------------------------------------------------------------------------------------------------ Refresh
function O.Refresh()
	if not win or not win:IsShown() then return end
	local combat = InCombatLockdown() and true or false
	for _, l in ipairs(lines) do l:Refresh(combat) end
	if reloadBtn then
		reloadBtn:SetShown(needReload)
		reloadNote:SetShown(needReload)
	end
end

function O.Lines()
	local out = {}
	for i, l in ipairs(lines) do out[i] = {ids = l.ids, page = l.page, label = l.label, ctl = l.ctl, tip = l.Tip and l:Tip() or l.tip} end
	return out
end

C.onChange = function(e)
	if C.reloadRow(e) then needReload = true end
	O.Refresh()
end

------------------------------------------------------------------------------------------------ State
local function selectedLook()
	for name, b in pairs(tabs) do
		local on = name == state.tab and state.search == ""
		b.sel:SetShown(on)
		b.accent:SetShown(on)
		-- The open tab in white, the others in the normal gold
		if on then b.fs:SetTextColor(1, 1, 1) else b.fs:SetTextColor(1, 0.82, 0) end
	end
end

function O.SelectTab(name)
	O.Create()
	if not tabs[name] then return end
	state.tab = name
	saved().tab = name
	if state.search ~= "" then
		box:SetText("")
		state.search = ""
	end
	selectedLook()
	scroll:SetVerticalScroll(0)
	O.Layout()
end

function O.SetAdvanced(on)
	O.Create()
	on = on and true or false
	state.advanced = on
	saved().advanced = on
	advanced:SetChecked(on)
	O.Layout()
end

function O.SetSearch(text)
	O.Create()
	text = text or ""
	if box:GetText() ~= text then box:SetText(text) end
	if state.search ~= text then
		state.search = text
		selectedLook()
		scroll:SetVerticalScroll(0)
		O.Layout()
	end
end

function O.ExpandAll()
	for _, sec in ipairs(collect()) do state.open[sec.key] = true end
	O.Layout()
end

------------------------------------------------------------------------------------------------ Frame
local function savePosition()
	local x, y = win:GetLeft(), win:GetBottom()
	if x and y then
		local s = saved()
		s.x, s.y = x, y
	end
end

local MINSCALE, MAXSCALE = 0.5, 1.5

-- Scales the window with its top left corner kept in place on the screen.
function O.SetScale(scale)
	O.Create()
	scale = math.min(MAXSCALE, math.max(MINSCALE, scale or 1))
	local left, top, eff = win:GetLeft(), win:GetTop(), win:GetEffectiveScale()
	win:SetScale(scale)
	if left and top then
		local neff = win:GetEffectiveScale()
		win:ClearAllPoints()
		win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * eff / neff, top * eff / neff)
		savePosition()
	end
	saved().scale = scale
end

function O.Create()
	if win then return win end
	win = CreateFrame("Frame", "ZPerl_OptionsWindow", UIParent, "BackdropTemplate")
	win:Hide()
	win:SetSize(WIDTH, HEIGHT)
	win:SetFrameStrata("FULLSCREEN_DIALOG")
	win:SetClampedToScreen(true)
	win:SetMovable(true)
	win:EnableMouse(true)
	-- The earlier Z-Perl options look: Z-Perl's options backdrop (tooltip border) in black under the frames'
	-- default gradient (grey at the top fading out downwards).
	win:SetBackdrop(ZPerl_Options_Backdrop_256_16_5555)
	win:SetBackdropColor(0, 0, 0, 1)
	win:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	local gradient = win:CreateTexture(nil, "BORDER")
	gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	gradient:SetBlendMode("ADD")
	gradient:SetPoint("TOPLEFT", 3, -3)
	gradient:SetPoint("BOTTOMRIGHT", -3, 3)
	gradient:SetGradient("VERTICAL", CreateColor(0.1, 0.1, 0.1, 0), CreateColor(0.25, 0.25, 0.25, 1))
	tinsert(UISpecialFrames, "ZPerl_OptionsWindow")

	local s = saved()
	win:SetScale(math.min(MAXSCALE, math.max(MINSCALE, s.scale or 1)))
	if s.x and s.y then
		win:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", s.x, s.y)
	else
		win:SetPoint("CENTER")
	end

	-- A drag anywhere on the window moves it (the controls take their own clicks), through the window's own drag
	-- scripts, so no frame lies over the title bar's controls.
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	win:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		savePosition()
	end)
	local title = win:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 14, -11)
	title:SetTextColor(0.82, 0, 0)
	-- "Z-Perl" in the product name's red (ZPerl.ProductName's D00000), the version number in the normal gold
	title:SetText(ZPerl.VersionNumber and ("Z-Perl |cffffd100" .. ZPerl.VersionNumber .. "|r") or "Z-Perl")
	local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetFrameLevel(win:GetFrameLevel() + 10)

	box = CreateFrame("EditBox", nil, win, "SearchBoxTemplate")
	box:SetSize(190, 22)
	-- The search at the right of the title bar, beside the close button
	box:SetPoint("RIGHT", close, "LEFT", -8, -6)
	box:HookScript("OnTextChanged", function(self) O.SetSearch(self:GetText()) end)

	-- "Advanced options" at the bottom of the tab list's panel (the reload note is at the footer's right)
	advanced = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
	advanced:SetSize(24, 24)
	advanced:SetFrameLevel(win:GetFrameLevel() + 10)
	advanced:SetPoint("BOTTOMLEFT", 10, 12)
	local at = win:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	at:SetPoint("LEFT", advanced, "RIGHT", 4, 0)
	at:SetText(L["Advanced options"])
	advanced.label = at
	advanced:SetHitRectInsets(0, -(at:GetStringWidth() + 4), 0, 0) -- The label clicks the box
	advanced:SetScript("OnClick", function(self) O.SetAdvanced(self:GetChecked()) end)

	-- The title bar's divider: a grey rule fading out at both ends
	local function rule(x1, x2, y)
		local t = win:CreateTexture(nil, "ARTWORK")
		t:SetTexture("Interface\\Buttons\\WHITE8X8")
		t:SetHeight(1)
		t:SetPoint("TOPLEFT", x1, y)
		t:SetPoint("TOPRIGHT", x2, y)
		return t
	end
	local divL = rule(8, -WIDTH / 2, -37)
	divL:SetGradient("HORIZONTAL", CreateColor(0.6, 0.6, 0.6, 0), CreateColor(0.6, 0.6, 0.6, 0.7))
	local divR = rule(WIDTH / 2, -8, -37)
	divR:SetGradient("HORIZONTAL", CreateColor(0.6, 0.6, 0.6, 0.7), CreateColor(0.6, 0.6, 0.6, 0))

	-- The tab list's panel: darker than the window, with the window's rounded tooltip edge at a smaller size
	local panel = CreateFrame("Frame", nil, win, "BackdropTemplate")
	panel:SetPoint("TOPLEFT", 6, -40)
	panel:SetPoint("BOTTOMLEFT", 6, 8)
	panel:SetWidth(TABW + 2)
	panel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = {left = 3, right = 3, top = 3, bottom = 3},
	})
	panel:SetBackdropColor(0, 0, 0, 0.4)
	panel:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)
	panel:SetFrameLevel(win:GetFrameLevel()) -- Under the tabs

	tabs = {}
	local ty = -44
	for _, name in ipairs(pageNames()) do
		local b = CreateFrame("Button", nil, win)
		b:SetSize(TABW - 10, 26)
		b:SetPoint("TOPLEFT", 10, ty)
		ty = ty - 28
		-- The open tab: a flat gold fill fading out to the right, with a gold bar on its left edge
		b.sel = b:CreateTexture(nil, "BACKGROUND")
		b.sel:SetAllPoints()
		b.sel:SetTexture("Interface\\Buttons\\WHITE8X8")
		b.sel:SetGradient("HORIZONTAL", CreateColor(1, 0.82, 0, 0.3), CreateColor(1, 0.82, 0, 0))
		b.sel:Hide()
		b.accent = b:CreateTexture(nil, "ARTWORK")
		b.accent:SetColorTexture(1, 0.82, 0, 1)
		b.accent:SetWidth(3)
		b.accent:SetPoint("TOPLEFT")
		b.accent:SetPoint("BOTTOMLEFT")
		b.accent:Hide()
		-- mouseover: a faint white fill fading the same way
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetTexture("Interface\\Buttons\\WHITE8X8")
		hl:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0.12), CreateColor(1, 1, 1, 0))
		local fs = b:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		fs:SetPoint("LEFT", 10, 0)
		fs:SetText(L[name])
		b.fs = fs
		b:SetScript("OnClick", function() O.SelectTab(name) end)
		tabs[name] = b
		tabList[#tabList + 1] = name
	end

	scroll = CreateFrame("ScrollFrame", nil, win)
	scroll:SetPoint("TOPLEFT", TABW + 22, -44) -- A gap after the tab panel
	scroll:SetPoint("BOTTOMRIGHT", -30, 40)
	content = CreateFrame("Frame", nil, scroll)
	content:SetSize(CONTENTW, 10)
	scroll:SetScrollChild(content)
	-- Blizzard's minimal scroll bar (as in the game's settings): a thin track and thumb between two arrows. A
	-- child of the scroll frame, so it hides with it.
	local bar = CreateFrame("EventFrame", nil, scroll, "MinimalScrollBar")
	bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 11, 0)
	bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 11, 0)
	ScrollUtil.InitScrollFrameWithScrollBar(scroll, bar)
	-- The wheel scrolls the page only over the bar (over the page it would move it under the cursor while a slider
	-- is wheeled): the scroll frame swallows it, so it does not zoom the camera either. The stock step is a few
	-- pixels a notch, slow for a long page: the bar steps a fixed 80 pixels instead (it follows through the
	-- OnVerticalScroll hook set above)
	scroll:SetScript("OnMouseWheel", function() end)
	bar:SetScript("OnMouseWheel", function(_, delta)
		scroll:SetVerticalScroll(Clamp(scroll:GetVerticalScroll() - delta * 80, 0, scroll:GetVerticalScrollRange()))
	end)

	reloadBtn = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
	reloadBtn:SetSize(120, 24)
	reloadBtn:SetPoint("BOTTOMRIGHT", -26, 10)
	reloadBtn:SetText(L["Reload UI"])
	reloadBtn:SetScript("OnClick", ReloadUI)
	reloadBtn:Hide()
	reloadNote = win:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	reloadNote:SetPoint("RIGHT", reloadBtn, "LEFT", -10, 0)
	reloadNote:SetText(L["A change needs a reload."])
	reloadNote:Hide()

	-- The scale grip in the bottom right corner: a drag scales the window so its right edge follows the cursor, a
	-- right click puts the scale back to 1
	local grip = CreateFrame("Button", nil, win)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -5, 5)
	grip:SetFrameLevel(win:GetFrameLevel() + 10)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:RegisterForClicks("RightButtonUp")
	grip:SetScript("OnClick", function() O.SetScale(1) end)
	-- The scale while dragging, as a percentage beside the grip
	local scaleText = grip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	scaleText:SetPoint("BOTTOMRIGHT", grip, "TOPLEFT", -2, 2)
	scaleText:Hide()
	grip:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then return end
		scaleText:SetFormattedText("%d%%", win:GetScale() * 100 + 0.5)
		scaleText:Show()
		local eff = win:GetEffectiveScale()
		local left = win:GetLeft() * eff
		local parent = UIParent:GetEffectiveScale()
		self:SetScript("OnUpdate", function()
			local x = GetCursorPosition()
			local w = x - left
			if w > 0 then
				local scale = w / WIDTH / parent
				if math.abs(scale - win:GetScale()) > 0.005 then
					O.SetScale(scale)
					scaleText:SetFormattedText("%d%%", win:GetScale() * 100 + 0.5)
				end
			end
		end)
	end)
	grip:SetScript("OnMouseUp", function(self)
		self:SetScript("OnUpdate", nil)
		scaleText:Hide()
	end)

	win:SetScript("OnShow", function() O.Layout() ZPerl.AlignmentGridUpdate() end)
	win:SetScript("OnHide", ZPerl.AlignmentGridUpdate)
	win:RegisterEvent("PLAYER_REGEN_DISABLED")
	win:RegisterEvent("PLAYER_REGEN_ENABLED")
	win:SetScript("OnEvent", function() O.Refresh() end)

	state.advanced = s.advanced and true or false
	advanced:SetChecked(state.advanced)
	state.tab = tabs[s.tab] and s.tab or "General"
	selectedLook()
	return win
end

function O.Open(tab)
	O.Create()
	if tab and tabs[tab] then
		state.tab = tab
		saved().tab = tab
		if state.search ~= "" then
			box:SetText("")
			state.search = ""
		end
		selectedLook()
	end
	if win:IsShown() then O.Layout() else win:Show() end
end
-- ZPerl.OpenSettings, ToggleSettings and SettingsOpenPage are Z-Perl's (ZPerl_OptionsLoader.lua): they load this addon.
