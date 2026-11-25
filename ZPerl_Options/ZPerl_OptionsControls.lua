-- The options window's controls: one "line" per row of ZPerl.SettingsList (several rows for an `inline` tag), built on
-- first use and kept. A line is {ids, page, label, ctl, tip, box, h, full, Refresh(line, combat)}; `ctl` is the control
-- frame (CheckButton, Slider, Button, DropdownButton, or the group frame of an inline line). Values read and write
-- through ZPerl.SettingsCore (ZPerl_Settings.lua), so appliers, `with`, `also` and `each` act as they always did.

-- Upvalues
local floor = math.floor
local format = string.format
-- The options text by its English wording (Localization/Localization.lua): labels stay English in the rows, which
-- are matched by them, and are translated only here, where they are drawn
local L = ZPerl.OptionsL
local C = {}
ZPerl.OptionsControls = C

local COLW = 310
C.COLW = COLW
C.onChange = function(_) end -- The window sets it: called after a control wrote a value

local K -- ZPerl.SettingsCore, read at first use (ZPerl_Settings.lua is part of Z-Perl, which loads before this addon)
local function core()
	K = K or ZPerl.SettingsCore
	return K
end

------------------------------------------------------------------------------------------------ Needs and tips
local keyLabel
local function labelFor(key)
	if not keyLabel then
		keyLabel = {}
		for _, e in ipairs(ZPerl.SettingsList) do
			if e.path and not keyLabel[e.path] then keyLabel[e.path] = e.label end
			for _, k in ipairs(e.keys or {}) do
				if not keyLabel[k] then keyLabel[k] = e.label end
			end
		end
	end
	return keyLabel[key] or key
end

-- true when the row's `needs` holds; else false and what it needs. Runs for every row on each refresh: the text is
-- built only for a condition that fails, and a single condition is not wrapped in a new table.
local function needOk(k, c)
	if type(c) == "string" then return k.on(k.read(ZPerl.layout, c)) end
	if c.get then return c.get() and true or false end
	return k.norm(k.read(ZPerl.layout, c.key)) ~= k.norm(c["not"])
end
local function needText(c)
	if type(c) == "string" then return format(L["Needs: %s"], L[labelFor(c)]) end
	if c.get then return format(L["Needs: %s"], L[c.label]) end
	return format(L["Needs: %s set to something else"], L[labelFor(c.key)])
end
local function needsMet(e)
	local n = e.needs
	if n == nil then return true end
	local k = core()
	if type(n) == "string" or n.key or n.get then
		if needOk(k, n) then return true end
		return false, needText(n)
	end
	local missing
	for _, c in ipairs(n) do
		if not needOk(k, c) then
			local text = needText(c)
			missing = missing and (missing .. "; " .. text) or text
		end
	end
	return missing == nil, missing
end
C.needsMet = needsMet

local function reloadRow(e) return e.reload == true end
C.reloadRow = reloadRow

local function tipOf(e)
	if e.each then return core().sharedTip(e)() end
	return L[e.tip]
end

-- anchor: the frame the tooltip opens beside (default the control itself). line.Tip returns translated text; a plain
-- line.tip is the row's English text.
local function showTip(line, anchor)
	return function(self)
		GameTooltip:SetOwner(anchor or self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L[line.label], 1, 1, 1)
		GameTooltip:AddLine((line.Tip and line:Tip() or L[line.tip]) or "", 0.9, 0.9, 0.9, true)
		GameTooltip:Show()
	end
end
local function hookTip(frame, line, anchor)
	if frame.HookScript then
		frame:HookScript("OnEnter", showTip(line, anchor))
		frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
	end
	if frame.SetMotionScriptsWhileDisabled then frame:SetMotionScriptsWhileDisabled(true) end
end

-- The state is also kept on the control: a Slider answers IsEnabled from it (wowless does not implement the Slider's own).
local function setEnabled(ctl, on)
	ctl.fpOn = on
	if ctl.SetEnabled then
		ctl:SetEnabled(on)
	elseif on then
		ctl:Enable()
	else
		ctl:Disable()
	end
end

------------------------------------------------------------------------------------------------ Pieces
local function text(parent, font, str)
	local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
	fs:SetJustifyH("LEFT")
	if str then fs:SetText(str) end
	return fs
end

local function newBox(parent, h)
	local box = CreateFrame("Frame", nil, parent)
	box:SetSize(COLW, h)
	return box
end

local function labelOf(e) return L[e.label] .. (reloadRow(e) and " " .. L["(reload)"] or "") end

local function sliderFormat(e)
	if e.percent then return function(v) return format("%d%%", floor(v * 100 + 0.5)) end end
	if e.step >= 1 then return function(v) return e.zero and v < 0.5 and L[e.zero] or format("%d", floor(v + 0.5)) end end
	return function(v) return (format("%.2f", v):gsub("(%.%d-)0+$", "%1"):gsub("%.$", "")) end
end

-- e.options() lists names that are data (layout and texture names): only the fixed choice lists are translated
-- A list from a function is its own table, {key, label, file} each, not a copy: read only. The same table back from
-- the function means the menu built from it is still current.
local function choices(e)
	if type(e.options) == "function" then return e.options() end
	local out = {}
	if e.map then
		for i, m in ipairs(e.map) do out[i] = {i, L[m[1]]} end
	else
		for i, o in ipairs(e.options) do out[i] = {i, L[o[2]]} end
	end
	return out
end

local function hex2rgb(hex)
	local r, g, b = hex:match("^%x%x(%x%x)(%x%x)(%x%x)$")
	if not r then return 1, 1, 1 end
	return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end
local function rgb2hex(r, g, b)
	return format("FF%02X%02X%02X", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

------------------------------------------------------------------------------------------------ Builders
-- Each builder fills line.ctl and line.update(): re-read the row's value into the control.
local B = {}

function B.check(line, e, parent, x, labelText)
	local k = core()
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetSize(24, 24)
	cb:SetPoint("TOPLEFT", x or 0, 0)
	local fs = text(parent, "GameFontHighlight", labelText or labelOf(e))
	fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	fs:SetWidth(COLW - 30)
	cb:SetScript("OnClick", function(self)
		k.store(e, self:GetChecked() and true or false)
		C.onChange(e)
	end)
	hookTip(cb, line)
	return cb, fs, function() cb:SetChecked(k.valueOf(e, ZPerl.layout) and true or false) end
end

-- Blizzard's settings slider (MinimalSliderWithSteppersTemplate) look: its MinimalSliderTemplate track and thumb
-- between a back and a forward stepper, the value right of them. Built here rather than from the full template,
-- whose own value and callback handling would sit beside the settings core's. A client without the template
-- gets the plain slider.
local MINIMAL = C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo("MinimalSliderTemplate") ~= nil
local STEPPER_OFF_ALPHA = 0.5	-- As Blizzard's steppers

local function stepper(box, atlas, w, h)
	local b = CreateFrame("Button", nil, box)
	b:SetSize(w, h)
	local t = b:CreateTexture(nil, "BACKGROUND")
	t:SetAtlas(atlas, true)
	t:SetPoint("CENTER")
	b.tex = t
	return b
end

local function stepperEnabled(b, on)
	b:SetEnabled(on)
	b:SetAlpha(on and 1 or STEPPER_OFF_ALPHA)
	b.tex:SetDesaturated(not on)
end

function B.slider(line, e, box)
	local k = core()
	local fs = text(box, "GameFontHighlight", labelOf(e))
	fs:SetPoint("TOPLEFT", 0, 0)
	local val = text(box, "GameFontNormal")
	local s, back, fwd
	if MINIMAL then
		back = stepper(box, "Minimal_SliderBar_Button_Left", 11, 19)
		fwd = stepper(box, "Minimal_SliderBar_Button_Right", 9, 18)
		back:SetPoint("LEFT", box, "TOPLEFT", 2, -29)
		fwd:SetPoint("RIGHT", box, "TOPRIGHT", -44, -29)
		s = CreateFrame("Slider", nil, box, "MinimalSliderTemplate")
		s:SetPoint("LEFT", back, "RIGHT", 4, 0)
		s:SetPoint("RIGHT", fwd, "LEFT", -4, 0)
		s:SetHeight(19)
		val:SetPoint("LEFT", fwd, "RIGHT", 6, 0)
	else
		val:SetPoint("TOPRIGHT", -6, 0)
		s = CreateFrame("Slider", nil, box)
		s:SetOrientation("HORIZONTAL")
		s:SetSize(COLW - 20, 14)
		s:SetPoint("TOPLEFT", 4, -20)
		local bar = s:CreateTexture(nil, "BACKGROUND")
		bar:SetColorTexture(0.35, 0.35, 0.4, 0.9)
		bar:SetPoint("LEFT")
		bar:SetPoint("RIGHT")
		bar:SetHeight(4)
		s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
		s:GetThumbTexture():SetSize(14, 22)
	end
	s:SetMinMaxValues(e.min, e.max)
	s:SetValueStep(e.step)
	if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
	s:EnableMouse(true)
	s.IsEnabled = function(self) return self.fpOn ~= false end

	-- The steppers are off at either end of the range and while the slider is
	local function steppers()
		if not back then return end
		local on = s.fpOn ~= false
		local v, lo, hi = s:GetValue(), e.min, e.max
		stepperEnabled(back, on and v > lo + e.step * 0.5)
		stepperEnabled(fwd, on and v < hi - e.step * 0.5)
	end
	local nativeSetEnabled = s.SetEnabled
	s.SetEnabled = function(self, on)
		if nativeSetEnabled then nativeSetEnabled(self, on) end
		if self.Thumb then self.Thumb:SetAlpha(on and 1 or 0.7) end
		self.fpOn = on
		steppers()
	end

	-- One step: a stepper click (SetValue keeps it inside the range)
	local function nudge(dir)
		if s.fpOn == false then return end
		-- On the step grid, so fractional steps (0.01) do not save rounding drift
		local steps = math.floor((s:GetValue() - e.min) / e.step + 0.5) + dir
		s:SetValue(math.max(e.min, math.min(e.max, e.min + steps * e.step)))
	end
	if back then
		back:SetScript("OnClick", function()
			nudge(-1)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
		fwd:SetScript("OnClick", function()
			nudge(1)
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)
	end
	-- The wheel steps the value like the steppers (the page itself does not scroll on the wheel)
	s:EnableMouseWheel(true)
	s:SetScript("OnMouseWheel", function(_, delta) nudge(delta > 0 and 1 or -1) end)

	local fmt = sliderFormat(e)
	local busy
	s:SetScript("OnValueChanged", function(_, v)
		steppers()
		if busy or s.fpOn == false then return end
		k.store(e, v)
		val:SetText(fmt(k.valueOf(e, ZPerl.layout)))
		C.onChange(e)
	end)
	-- Beside the whole row: anchored to the track, the tooltip rises over the value text above its right end
	hookTip(s, line, box)
	line.fs = fs
	return s, nil, function()
		busy = true
		local v = k.valueOf(e, ZPerl.layout)
		s:SetValue(v)
		val:SetText(fmt(v))
		busy = false
		steppers()
	end
end

-- The button of a dropdown, its list in ZPerl.DropdownPicker (ZPerl_Picker.lua): a Blizzard menu makes garbage on every
-- open. getList() hands the choices as the list opens.
local function pickerButton(line, e, box, src, getList)
	local fs = text(box, "GameFontHighlight", labelOf(e))
	fs:SetPoint("TOPLEFT", 0, 0)
	local dd = CreateFrame("DropdownButton", nil, box, "WowStyle1DropdownTemplate")
	dd:SetWidth(COLW - 14)
	dd:SetPoint("TOPLEFT", 0, -18)
	ZPerl.DropdownPicker(dd, src, getList)
	hookTip(dd, line)
	return dd, fs
end

-- A dropdown of single choices. A table of options or a map is turned into choices once; a function is asked as the
-- list opens (ZPerl.SettingsBarTextureList hands back the same table until LibSharedMedia registers a texture).
function B.dropdown(line, e, box)
	local k = core()
	local static = type(e.options) ~= "function" and choices(e)
	local function getList() return static or choices(e) end
	local src = {
		texture = e.texture,
		isSelected = function(c) return k.valueOf(e, ZPerl.layout) == c[1] end,
		pick = function(c)
			k.store(e, c[1])
			C.onChange(e)
		end,
	}
	local dd, fs = pickerButton(line, e, box, src, getList)
	local shown
	local function refresh()
		local v = k.valueOf(e, ZPerl.layout)
		if v == shown then return end
		shown = v
		local label = v
		for _, c in ipairs(getList()) do
			if c[1] == v then label = c[2] break end
		end
		if dd.OverrideText then dd:OverrideText(label ~= nil and tostring(label) or "") end
	end
	src.refresh = refresh
	return dd, fs, refresh
end

-- The frames a shared row acts on: a checkbox per frame, the list kept open while ticking
function B.frames(line, e, box)
	local k = core()
	local list = {}
	for i, fl in ipairs(ZPerl.SettingsFrames) do list[i] = {i, L[fl]} end
	local src = {
		check = true,
		isSelected = function(c) return k.ticked(k.maskOf(e.section), c[1]) end,
		pick = function(c)
			k.setMask(e.section, bit.bxor(k.maskOf(e.section), bit.lshift(1, c[1] - 1)))
			return true
		end,
	}
	local dd, fs = pickerButton(line, e, box, src, function() return list end)
	local shown
	local function refresh()
		local mask = k.maskOf(e.section)
		if mask == shown then return end
		shown = mask
		local n, all = 0, #list
		for i = 1, all do if k.ticked(mask, i) then n = n + 1 end end
		if dd.OverrideText then dd:OverrideText(n == 0 and L["None"] or n == all and L["All frames"] or format(L["%d frames"], n)) end
	end
	src.refresh = refresh
	return dd, fs, refresh
end

function B.color(line, e, box)
	local k = core()
	local btn = CreateFrame("Button", nil, box)
	btn:SetSize(22, 22)
	btn:SetPoint("TOPLEFT", 0, 0)
	local border = btn:CreateTexture(nil, "BACKGROUND")
	border:SetAllPoints()
	border:SetColorTexture(0.8, 0.8, 0.8, 1)
	local sw = btn:CreateTexture(nil, "ARTWORK")
	sw:SetPoint("TOPLEFT", 2, -2)
	sw:SetPoint("BOTTOMRIGHT", -2, 2)
	local fs = text(box, "GameFontHighlight", labelOf(e))
	fs:SetPoint("LEFT", btn, "RIGHT", 6, 0)
	local function update()
		sw:SetColorTexture(hex2rgb(k.valueOf(e, ZPerl.layout)))
	end
	btn:SetScript("OnClick", function()
		local r, g, b = hex2rgb(k.valueOf(e, ZPerl.layout))
		-- The swatch has no opacity: the store keeps the stored alpha (the opacity has its own slider row)
		ColorPickerFrame:SetupColorPickerAndShow({
			r = r, g = g, b = b, hasOpacity = false,
			swatchFunc = function()
				k.store(e, rgb2hex(ColorPickerFrame:GetColorRGB()))
				C.onChange(e)
			end,
			cancelFunc = function()
				k.store(e, rgb2hex(r, g, b))
				C.onChange(e)
			end,
		})
	end)
	hookTip(btn, line)
	return btn, fs, update
end

-- A spell slot: drag a spell from the spellbook or an action bar onto it (or click it holding one). Right-click or
-- Alt-click clears it. The value is a spell ID, 0 when empty; while empty the slot shows e.auto() (the spell used
-- instead) faded. A passive spell is refused, and so is one e.accept(id) returns false for.
local function cursorSpell()
	local kind, slot, book, id = GetCursorInfo()
	if kind ~= "spell" then return end
	if type(id) == "number" and id > 0 then return id end
	local index = tonumber(slot)
	if not index then return end
	if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
		local bank = (book == "pet" or book == Enum.SpellBookSpellBank.Pet) and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
		local info = C_SpellBook.GetSpellBookItemInfo(index, bank)
		return info and info.spellID
	elseif GetSpellBookItemInfo then
		local _, sid = GetSpellBookItemInfo(index, book)
		return sid
	end
end

function B.spell(line, e, box)
	local k = core()
	local btn = CreateFrame("Button", nil, box)
	btn:SetSize(36, 36)
	btn:SetPoint("TOPLEFT", 3, -2)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	-- Only the slot part of the 64px empty-slot texture, kept within 2px of the button: the column clips anything
	-- left of its edge
	local slot = btn:CreateTexture(nil, "BACKGROUND")
	slot:SetTexture("Interface\\Buttons\\UI-EmptySlot")
	slot:SetTexCoord(0.19, 0.81, 0.19, 0.81)
	slot:SetPoint("TOPLEFT", -2, 2)
	slot:SetPoint("BOTTOMRIGHT", 2, -2)
	local icon = btn:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", 1, -1)
	icon:SetPoint("BOTTOMRIGHT", -1, 1)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	local fs = text(box, "GameFontHighlight", labelOf(e))
	fs:SetPoint("TOPLEFT", btn, "TOPRIGHT", 8, -2)
	fs:SetWidth(COLW - 60)
	local name = text(box, "GameFontNormalSmall")
	name:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
	name:SetWidth(COLW - 60)

	local function update()
		local id = k.valueOf(e, ZPerl.layout)
		local auto = (not id or id == 0) and e.auto and e.auto()
		local info = (id and id ~= 0 and C_Spell.GetSpellInfo(id)) or (auto and C_Spell.GetSpellInfo(auto))
		icon:SetTexture(info and info.iconID or nil)
		icon:SetDesaturated(auto and true or false)
		icon:SetAlpha(auto and 0.5 or 1)
		if not info then
			name:SetText(L["Automatic (drag a spell here)"])
		elseif auto then
			name:SetText(format(L["Automatic: %s (%d yd)"], info.name, info.maxRange or 0))
		else
			name:SetText(format(L["%s (%d yd)"], info.name, info.maxRange or 0))
		end
	end

	local function take()
		if not btn:IsEnabled() then return end
		local id = cursorSpell()
		if not id then return end
		if not C_Spell.GetSpellInfo(id) or (C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(id)) or (e.accept and not e.accept(id)) then
			PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST or 846)
			return
		end
		ClearCursor()
		k.store(e, id)
		update()
		C.onChange(e)
	end
	btn:SetScript("OnReceiveDrag", take)
	btn:SetScript("OnClick", function(_, button)
		if button == "RightButton" or IsAltKeyDown() then
			k.store(e, 0)
			update()
			C.onChange(e)
		else
			take()
		end
	end)
	hookTip(btn, line)
	return btn, fs, update
end

function B.button(line, e, box)
	local k = core()
	local b = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
	b:SetSize(COLW - 14, 24)
	b:SetPoint("TOPLEFT", 0, 0)
	b:SetText(L[e.label])
	b:SetScript("OnClick", function()
		k.click(e)
		C.onChange(e)
	end)
	hookTip(b, line)
	return b, nil, function() end
end

-- An inline line: a title and one small check per row, in one line.
local function buildInline(line, rows, box)
	local k = core()
	local title = L[line.label]
	local fs = text(box, "GameFontHighlight", title)
	fs:SetPoint("TOPLEFT", 0, -4)
	local subs = {}
	for i, e in ipairs(rows) do
		local cb = CreateFrame("CheckButton", nil, box, "UICheckButtonTemplate")
		cb:SetSize(24, 24)
		cb:SetPoint("TOPLEFT", 70 + (i - 1) * 46, 0)
		local num = text(box, "GameFontHighlight", (e.label:gsub("^%a+ ", "")))
		num:SetPoint("LEFT", cb, "RIGHT", 0, 0)
		cb:SetScript("OnClick", function(self)
			k.store(e, self:GetChecked() and true or false)
			C.onChange(e)
		end)
		hookTip(cb, {label = e.label, tip = e.tip})
		subs[i] = {e = e, cb = cb}
	end
	box.IsEnabled = function() return subs[1].cb:IsEnabled() end
	return function(combat)
		local allOk = true
		for _, s in ipairs(subs) do
			s.cb:SetChecked(k.valueOf(s.e, ZPerl.layout) and true or false)
			local ok = needsMet(s.e)
			allOk = allOk and ok
			setEnabled(s.cb, ok and not combat)
		end
		return allOk
	end
end

------------------------------------------------------------------------------------------------ Line
local HEIGHT = {check = 26, color = 26, button = 28, slider = 44, dropdown = 46, frames = 46, spell = 42}

-- rows: the rows of the line (one, or all rows of an inline tag). parent: the window's content frame.
function C.Make(parent, rows)
	local e = rows[1]
	local line = {rows = rows, ids = {}, page = e.page, label = e.label}
	for i, r in ipairs(rows) do line.ids[i] = r.id end
	local inline = e.inline ~= nil
	line.full = inline
	line.h = inline and 28 or HEIGHT[e.type] or 26
	local box = newBox(parent, line.h)
	if inline then
		box:SetWidth(8 * 46 + 80)
		line.label = (e.inline == "groups") and "Groups" or (e.inline == "classgroups") and "Class" or e.inline
		line.box = box
		local refresh = buildInline(line, rows, box)
		line.ctl = box
		function line.Refresh(self, combat)
			local ok = refresh(combat)
			self.tip = e.tip
			box:SetAlpha(1)
			return ok
		end
		return line
	end
	line.box = box
	local ctl, fs, update
	local t = e.type
	if t == "check" then
		ctl, fs, update = B.check(line, e, box)
	else
		ctl, fs, update = B[t](line, e, box)
	end
	fs = fs or line.fs
	line.ctl = ctl
	-- The tooltip text, built when it is shown (or read through O.Lines), not on every refresh: a shared row's text
	-- compares every ticked frame
	function line.Tip(self)
		local tip = tipOf(e) or ""
		if self.miss then tip = tip .. "\n" .. self.miss end
		self.tip = tip
		return tip
	end
	function line.Refresh(self, combat)
		update()
		local ok, miss = needsMet(e)
		self.miss = miss
		local on = ok and not combat
		setEnabled(ctl, on)
		box:SetAlpha(on and 1 or 0.5)
		if fs and fs.SetTextColor then
			if on then fs:SetTextColor(1, 1, 1) else fs:SetTextColor(0.6, 0.6, 0.6) end
		end
		return ok
	end
	return line
end
