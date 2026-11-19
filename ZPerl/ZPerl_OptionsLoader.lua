-- The options window lives in its own load-on-demand addon, ZPerl_Options (ZPerl.Options, ZPerl.OptionsControls). This
-- file loads it on first use and opens it, and keeps Z-Perl's entry in Blizzard's Settings panel: one canvas category
-- with a line and a button that opens the options window.
-- No setting, vertical list or shown predicate is registered there (bug O33: they tainted the panel's list).

local OPTIONS_ADDON = "ZPerl_Options"

-- true once ZPerl_Options is loaded (loads it now if needed); false, with a notice, if it cannot be.
function ZPerl.LoadOptions()
	if ZPerl.Options then return true end
	local loaded, reason = C_AddOns.LoadAddOn(OPTIONS_ADDON)
	if not loaded or not ZPerl.Options then
		ZPerl.Notice("Could not load the options (%s): %s", OPTIONS_ADDON, reason and (_G["ADDON_" .. reason] or reason) or "unknown")
		return false
	end
	return true
end

function ZPerl.OpenSettings(tab)
	if ZPerl.LoadOptions() then ZPerl.Options.Open(tab) end
end
function ZPerl.ToggleSettings()
	local win = _G.ZPerl_OptionsWindow
	if win and win:IsShown() then win:Hide() else ZPerl.OpenSettings() end
end
function ZPerl.SettingsOpenPage(name) ZPerl.OpenSettings(name) end

local function build()
	local frame = CreateFrame("Frame")
	frame:Hide()
	local line = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	line:SetPoint("TOPLEFT", 16, -16)
	line:SetText("Z-Perl's options are in their own window.")
	local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	button:SetSize(200, 26)
	button:SetPoint("TOPLEFT", line, "BOTTOMLEFT", 0, -12)
	button:SetText("Open Z-Perl options")
	button:SetScript("OnClick", function() ZPerl.OpenSettings() end)
	Settings.RegisterAddOnCategory((Settings.RegisterCanvasLayoutCategory(frame, "Z-Perl")))
end

local function onLogin()
	ZPerl.Off("PLAYER_LOGIN", onLogin)
	build()
end
ZPerl.On("PLAYER_LOGIN", onLogin)
