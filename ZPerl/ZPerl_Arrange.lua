-- Z-Perl arrange mode: a small toolbar shown exactly while the frames are unlocked (out of combat).

local bar = CreateFrame("Frame", "ZPerl_ArrangeBar", UIParent)
bar:SetSize(280, 52)
bar:SetPoint("TOP", UIParent, "TOP", 0, -40) -- first show only; a drag re-anchors it, kept for the session
bar:SetFrameStrata("DIALOG")
bar:SetClampedToScreen(true)
bar:SetMovable(true)
bar:EnableMouse(true)
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", bar.StartMoving)
bar:SetScript("OnDragStop", bar.StopMovingOrSizing)
bar:Hide()

local bg = bar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.8)

local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", 6, -4)
title:SetText("Z-Perl")

local function snapText()
	return ZPerl.layout and ZPerl.layout.alignmentSnapToGrid and "Snap: on" or "Snap: off"
end

local function gridText()
	return ZPerl.layout and ZPerl.layout.alignmentGrid and "Grid: on" or "Grid: off"
end

local function button(key, label, x, onClick)
	local b = CreateFrame("Button", "ZPerl_ArrangeBar_" .. key, bar, "UIPanelButtonTemplate")
	b:SetSize(64, 24)
	b:SetPoint("BOTTOMLEFT", x, 6)
	b:SetText(label)
	b:SetScript("OnClick", onClick)
	return b
end

button("Done", "Done", 6, function()
	if InCombatLockdown() then
		ZPerl.Notice("Not available in combat.")
		return
	end
	ZPerl.LockFrames()
end)
local grid = button("Grid", gridText(), 74, function(self)
	ZPerl.AlignmentGridToggle()
	self:SetText(gridText())
end)
local snap = button("Snap", snapText(), 142, function(self)
	ZPerl.layout.alignmentSnapToGrid = not ZPerl.layout.alignmentSnapToGrid
	self:SetText(snapText())
end)
button("Settings", "Settings", 210, function() ZPerl.OpenSettings() end)

-- Called by ZPerl.UnlockFrames, ZPerl.LockFrames and the combat events.
function ZPerl.ArrangeBarUpdate()
	if ZPerl.Locked == 0 and not InCombatLockdown() then
		grid:SetText(gridText())
		snap:SetText(snapText())
		bar:Show()
	else
		bar:Hide()
	end
	ZPerl.FrameMenuUpdate()
end

-- Closes the options window, unlocks the frames and shows the toolbar.
function ZPerl.ArrangeMode()
	if InCombatLockdown() then
		ZPerl.Notice("Not available in combat.")
		return
	end
	if _G.ZPerl_OptionsWindow then _G.ZPerl_OptionsWindow:Hide() end
	ZPerl.UnlockFrames()
end

ZPerl.On("PLAYER_REGEN_DISABLED", function() bar:Hide() end)
ZPerl.On("PLAYER_REGEN_ENABLED", ZPerl.ArrangeBarUpdate)
