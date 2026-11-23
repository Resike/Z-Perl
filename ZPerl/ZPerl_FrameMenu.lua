-- Edit on the frame: while the frames are unlocked and out of combat, an insecure overlay covers each listed frame.
-- Dragging it runs the frame's own drag scripts; a click (left or right, cursor moved under 5 px since mouse down) opens
-- ZPerl_FramePopup beside the frame: that frame's basic settings rows, built with the options window's controls
-- (ZPerl.OptionsControls.Make, in ZPerl_Options, loaded at the first popup), so every value goes through ZPerl.SettingsCore.
--
-- Rows: a main frame lists the basic rows of its settings page. A frame with its own section (pet's target, target of
-- target, target of target of target, focus target, party pets) lists only that section's rows, never the parent
-- frame's: the section's basic row (its switch) and each row whose label is the label of a basic row of the page, in
-- the page's order.

-- Frame -> {page, title, own section}
local FRAMES = {
	ZPerl_Player = {"Player", "Player"}, ZPerl_Player_Pet = {"Pet", "Pet"},
	ZPerl_PetTarget = {"Pet", "Pet target", "Pet's target"}, ZPerl_Target = {"Target", "Target"},
	ZPerl_TargetTarget = {"Target", "Target of target", "Target of target"},
	ZPerl_TargetTargetTarget = {"Target", "Target's target's target", "Target of target of target"},
	ZPerl_Focus = {"Focus", "Focus"}, ZPerl_FocusTarget = {"Focus", "Focus target", "Focus target"},
}
local ORDER = {"ZPerl_Player", "ZPerl_Player_Pet", "ZPerl_PetTarget", "ZPerl_Target", "ZPerl_TargetTarget", "ZPerl_TargetTargetTarget", "ZPerl_Focus", "ZPerl_FocusTarget"}
for i = 1, 5 do
	FRAMES["ZPerl_party" .. i], FRAMES["ZPerl_partypet" .. i] = {"Party", "Party"}, {"Party", "Party pets", "Party pets"}
	ORDER[#ORDER + 1] = "ZPerl_party" .. i
	ORDER[#ORDER + 1] = "ZPerl_partypet" .. i
end
for i = 1, 13 do
	FRAMES["ZPerl_Raid_Title" .. i] = {"Raid", "Raid"}
	ORDER[#ORDER + 1] = "ZPerl_Raid_Title" .. i
end

local WIDTH_PLAIN, WIDTH_INLINE = 340, 468
local popup, current, downX, downY, combat, wrapped
local built, shownLines = {}, {}

-- The lines of a frame: {rows...} per line; an inline tag is one line.
local function linesOf(name)
	local page, _, own = unpack(FRAMES[name])
	local basic, rank, rows = {}, {}, {}
	for _, e in ipairs(ZPerl.SettingsList) do
		if e.page == page and e.basic and not (e.showif and not e.showif()) then
			basic[#basic + 1] = e
			if not rank[e.label] then rank[e.label] = #basic end
		end
	end
	if own then
		for _, e in ipairs(ZPerl.SettingsList) do
			if e.page == page and e.section == own and not (e.showif and not e.showif()) then
				local r = e.basic and 0 or rank[e.label]
				if r then rows[#rows + 1] = {r, #rows, e} end
			end
		end
		table.sort(rows, function(a, b) if a[1] ~= b[1] then return a[1] < b[1] end return a[2] < b[2] end)
		for i, r in ipairs(rows) do rows[i] = r[3] end
	else
		rows = basic
	end
	local lines, tags = {}, {}
	for _, e in ipairs(rows) do
		if e.inline and tags[e.inline] then
			table.insert(tags[e.inline], e)
		else
			local l = {e}
			lines[#lines + 1] = l
			if e.inline then tags[e.inline] = l end
		end
	end
	return lines
end

local function refresh()
	if not (popup and popup:IsShown()) then return end
	local c = InCombatLockdown() and true or false
	for _, l in ipairs(shownLines) do l:Refresh(c) end
end

local function lineFor(rows)
	local ids = {}
	for i, r in ipairs(rows) do ids[i] = r.id end
	local key = table.concat(ids, "|")
	if not built[key] then built[key] = ZPerl.OptionsControls.Make(popup, rows) end
	return built[key]
end

local function create()
	popup = CreateFrame("Frame", "ZPerl_FramePopup", UIParent, "BackdropTemplate")
	popup:Hide()
	popup:SetFrameStrata("DIALOG")
	popup:SetClampedToScreen(true)
	popup:EnableMouse(true)
	-- The options window's look (ZPerl_OptionsWindow.lua): Z-Perl's options backdrop (tooltip border) in black under
	-- the frames' default gradient (grey at the top fading out downwards), with a white title.
	popup:SetBackdrop(ZPerl_Options_Backdrop_256_16_5555)
	popup:SetBackdropColor(0, 0, 0, 1)
	popup:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	local gradient = popup:CreateTexture(nil, "BORDER")
	gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	gradient:SetBlendMode("ADD")
	gradient:SetPoint("TOPLEFT", 3, -3)
	gradient:SetPoint("BOTTOMRIGHT", -3, 3)
	gradient:SetGradient("VERTICAL", CreateColor(0.1, 0.1, 0.1, 0), CreateColor(0.25, 0.25, 0.25, 1))
	tinsert(UISpecialFrames, "ZPerl_FramePopup")
	popup.title = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	popup.title:SetPoint("TOPLEFT", 14, -11)
	popup.title:SetTextColor(1, 1, 1)
	local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", -2, -2)
	closeButton:SetFrameLevel(popup:GetFrameLevel() + 10)
	popup.all = CreateFrame("Button", "ZPerl_FramePopup_All", popup, "UIPanelButtonTemplate")
	popup.all:SetHeight(24)
	popup.all:SetScript("OnClick", function()
		local page = current and FRAMES[current][1]
		popup:Hide()
		if page then ZPerl.SettingsOpenPage(page) end
	end)
	popup.lock = CreateFrame("Button", "ZPerl_FramePopup_Lock", popup, "UIPanelButtonTemplate")
	popup.lock:SetHeight(24)
	popup.lock:SetText("Lock frames")
	popup.lock:SetScript("OnClick", function() ZPerl.LockFrames() end)
end

-- The options window sets OptionsControls.onChange when ZPerl_Options loads: wrap it at the first popup use.
local function hook()
	local C = ZPerl.OptionsControls
	if wrapped ~= C.onChange then
		local cur = C.onChange
		wrapped = function(e) cur(e) refresh() end
		C.onChange = wrapped
	end
end

local function place(f)
	popup:ClearAllPoints()
	local cx = f:GetCenter()
	local right = true
	if cx then right = cx * f:GetEffectiveScale() / UIParent:GetEffectiveScale() < UIParent:GetWidth() / 2 end
	if right then popup:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0) else popup:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0) end
end

local function open(name)
	if InCombatLockdown() or combat or ZPerl.Locked ~= 0 then return end
	-- The popup's controls are the options window's (ZPerl.OptionsControls, in ZPerl_Options)
	if not ZPerl.LoadOptions() then return end
	if not popup then create() end
	hook()
	current = name
	local info = FRAMES[name]
	for _, l in pairs(built) do l.box:Hide() end
	popup.title:SetText(info[2])
	shownLines = {}
	local y, wide = -38, false
	for _, rows in ipairs(linesOf(name)) do
		local l = lineFor(rows)
		l.box:ClearAllPoints()
		l.box:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, y)
		l.box:Show()
		y = y - l.h - 4
		wide = wide or l.full
		shownLines[#shownLines + 1] = l
	end
	local w = wide and WIDTH_INLINE or WIDTH_PLAIN
	popup.all:SetText("All " .. info[2] .. " settings...")
	popup.all:SetWidth(w - 24)
	popup.all:ClearAllPoints()
	popup.all:SetPoint("TOPLEFT", 12, y - 6)
	popup.lock:SetWidth(w - 24)
	popup.lock:ClearAllPoints()
	popup.lock:SetPoint("TOPLEFT", 12, y - 34)
	popup:SetSize(w, -y + 72)
	place(_G[name])
	popup:Show()
	refresh()
end

local function close()
	current = nil
	if popup then popup:Hide() end
end

ZPerl.FramePopup = {
	Close = close,
	Lines = function()
		local out = {}
		if popup and popup:IsShown() then
			for i, l in ipairs(shownLines) do out[i] = {ids = l.ids, page = l.page, label = l.label, ctl = l.ctl} end
		end
		return out
	end,
}

local overlays = {}
local function forward(script)
	return function(self)
		local f = self:GetParent()
		local fn = f:GetScript(script)
		if fn then fn(f) end
	end
end
local function make(name)
	local f = _G[name]
	local o = CreateFrame("Button", name .. "_MenuOverlay", f)
	o:SetAllPoints(f)
	o:SetFrameStrata("HIGH")
	o:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	o:RegisterForDrag("LeftButton")
	o:SetScript("OnDragStart", forward("OnDragStart"))
	o:SetScript("OnDragStop", forward("OnDragStop"))
	o:SetScript("OnMouseDown", function() downX, downY = GetCursorPosition() end)
	o:SetScript("OnClick", function()
		local x, y = GetCursorPosition()
		-- A drag, not a click: moved 5 px or more on either axis
		if downX and (math.abs(x - downX) >= 5 or math.abs(y - downY) >= 5) then return end
		open(name)
	end)
	o:Hide()
	overlays[name] = o
	return o
end

-- Called by ZPerl.ArrangeBarUpdate (unlock, lock, combat end): overlays are shown exactly while unlocked and out of combat.
function ZPerl.FrameMenuUpdate()
	if InCombatLockdown() then return end -- The overlays were hidden by PLAYER_REGEN_DISABLED
	local on = ZPerl.Locked == 0
	if not on then close() end
	for _, name in ipairs(ORDER) do
		if _G[name] then
			local o = overlays[name]
			if on then
				o = o or make(name)
				o:Show()
			elseif o then
				o:Hide()
			end
		end
	end
end

ZPerl.On("PLAYER_REGEN_DISABLED", function()
	combat = true
	close()
	for _, o in pairs(overlays) do o:Hide() end
end)
ZPerl.On("PLAYER_REGEN_ENABLED", function() combat = false end)
