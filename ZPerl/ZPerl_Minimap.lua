-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

-- The minimap button, its menu and its tooltip.

local L = ZPerl.L

local conf

ZPerl.RequestConfig(function(New)
	conf = New
end, "$Revision: 1 $")

-- Upvalues
local collectgarbage = collectgarbage
local format = format
local ipairs = ipairs
local min = min
local pairs = pairs

local C_AddOns = C_AddOns
local GetAddOnCPUUsage = GetAddOnCPUUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local IsAltKeyDown = IsAltKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

local GameTooltip = GameTooltip
local UIParent = UIParent

-- Minimap Icon
function ZPerl.MinimapButtonOnClick(self, button)
	GameTooltip:Hide()
	if (button == "LeftButton") then
		ZPerl.DropdownPickerClose()
		ZPerl.ToggleSettings()
	elseif (button == "RightButton") then
		ZPerl.MinimapMenu(self)
	end
end

-- The minimap menu: every entry made once, {key, text, run = func, shown = func (offered only when it returns true)};
-- the menu is one table refilled with the shown entries on each open, in ZPerl.DropdownPicker's list (ZPerl_Picker.lua)
local function Loaded(addon)
	return C_AddOns.IsAddOnLoaded(addon)
end
local function Hidden(frame)
	return frame and not frame:IsShown()
end
local menuEntries = {
	{"title", ZPerl.ProductName, title = true},
	{"options", L["MINIMENU_OPTIONS"], run = function() ZPerl.OpenSettings() end},
	{"raidadmin", L["MINIMENU_RAIDAD"],
		shown = function() return Loaded("ZPerl_RaidAdmin") and Hidden(ZPerl_AdminFrame) end,
		run = function() ZPerl_AdminFrame:Show() end},
	{"itemcheck", L["MINIMENU_ITEMCHK"],
		shown = function() return Loaded("ZPerl_RaidAdmin") and Hidden(ZPerl_Check) end,
		run = function() ZPerl_Check:Show() end},
	{"rostertext", L["MINIMENU_ROSTERTEXT"],
		shown = function() return Loaded("ZPerl_RaidAdmin") and Hidden(ZPerl_RosterText) end,
		run = function() ZPerl_RosterText:Show() end},
	{"assists", L["MINIMENU_ASSIST"],
		shown = function() return Loaded("ZPerl_RaidHelper") and Hidden(ZPerl_Assists_Frame) end,
		run = function()
			ZPerlRaidHelperDB.AssistsFrame = 1
			ZPerlRaidHelperDB.TargettingFrame = 1
			ZPerl.RaidHelper.SetFrameSides()
		end},
	{"castmonitor", L["MINIMENU_CASTMON"],
		shown = function() return Loaded("ZPerl_RaidMonitor") and Hidden(ZPerl_RaidMonitor_Frame) end,
		run = function()
			ZPerlRaidMonitorDB.enabled = 1
			ZPerl_RaidMonitor_Frame:SetFrameSizes()
		end},
}
local menuList = {}
local menuSource = {
	plain = true,
	remeasure = true,
	pick = function(c)
		if (c.run) then
			c.run()
		end
	end,
}

-- ZPerl.MinimapMenu
function ZPerl.MinimapMenu(self)
	local n = 0
	for _, entry in ipairs(menuEntries) do
		if (not entry.shown or entry.shown()) then
			n = n + 1
			menuList[n] = entry
		end
	end
	for i = n + 1, #menuList do
		menuList[i] = nil
	end
	ZPerl.DropdownPickerOpen(self, menuSource, menuList)
end

-- ZPerl_Options loads on demand (the first time the options open): it has no startup memory, so its diff is all of it
local xpModList = {"ZPerl", "ZPerl_Options", "ZPerl_RaidHelper", "ZPerl_RaidAdmin", "ZPerl_RaidMonitor"}
local xpStartupMemory = {}

-- ZPerl.MinimapButtonInit
function ZPerl.MinimapButtonInit(self)
	--self.time = 0
	-- the memory API is optional, as in MinimapButtonDetails
	if (UpdateAddOnMemoryUsage and GetAddOnMemoryUsage) then
		collectgarbage()
		UpdateAddOnMemoryUsage()
		for k, v in pairs(xpModList) do
			local usedKB = GetAddOnMemoryUsage(v)
			if ((usedKB or 0) > 0) then
				xpStartupMemory[v] = usedKB
			end
		end
	end

	ZPerl.MinimapButtonUpdatePosition(self)

	if (conf.minimap.enable) then
		self:Show()
	else
		self:Hide()
	end

	--self.UpdateTooltip = ZPerl.MinimapButtonOnEnter

	ZPerl.MinimapButtonInit = nil
end

-- ZPerl.MinimapButtonUpdatePosition
-- Free dragging (ZPerl.xml OnDragStart/OnDragStop) replaced the old radius/angle
-- circle, which was sized for Era's minimap and misaligned on Forever.
function ZPerl.MinimapButtonUpdatePosition(self)
	ZPerl.PlaceFrame(self)
end

-- DiffColor(diff, val)
local function DiffColor(val)
	local r, g, b, offset
	offset = min(0.5, 0.5 * min(1, abs(val)))
	if (val < 0) then
		r = 0.5 + offset
		g = 0.5 - offset
		b = r
	else
		r = 0.5 + offset
		g = 0.5 - offset
		b = g
	end
	return format("|c00%02X%02X%02X", 255 * r, 255 * g, 255 * b)
end

-- ZPerl.MinimapButtonOnEnter
function ZPerl.MinimapButtonOnEnter(self)
	if (self.dragging) then
		return
	end

	GameTooltip:SetOwner(self or UIParent, "ANCHOR_LEFT")
	ZPerl.MinimapButtonDetails(GameTooltip)
end

-- ZPerl.MinimapButtonDetails
function ZPerl.MinimapButtonDetails(tt, ldb)
	tt:SetText("Z-Perl", 1, 1, 1)
	tt:AddLine(L["MINIMAP_HELP1"])
	if (not ldb) then
		tt:AddLine(L["MINIMAP_HELP2"])
	end
	if UpdateAddOnMemoryUsage then
		if (IsAltKeyDown()) then
			tt:AddLine(L["MINIMAP_HELP6"])
		elseif (not IsShiftKeyDown()) then
			tt:AddLine(L["MINIMAP_HELP5"])
		end
	end
	if UpdateAddOnMemoryUsage and IsAltKeyDown() then
		local showDiff = IsShiftKeyDown()

		local allAddonsCPU = 0
		for i = 1, C_AddOns.GetNumAddOns() do
			allAddonsCPU = allAddonsCPU + GetAddOnCPUUsage(i)
		end

		-- Show X-Perl memory usage
		UpdateAddOnMemoryUsage()
		UpdateAddOnCPUUsage()
		local totalKB, totalCPU, diffKB, diff = 0, 0, 0, 0
		local cpuText = ""
		for k, v in pairs(xpModList) do
			local usedKB = GetAddOnMemoryUsage(v)
			local usedCPU = GetAddOnCPUUsage(v)
			if ((usedKB or 0) > 0) then
				totalKB = totalKB + usedKB
				totalCPU = totalCPU + usedCPU

				if (allAddonsCPU > 0) then
					cpuText = format(" |c008080FF%.2f%%|r", 100 * (usedCPU / allAddonsCPU))
				end

				if (showDiff) then
					diff = usedKB - (xpStartupMemory[v] or 0)
					diffKB = diffKB + diff
					tt:AddDoubleLine(format(" %s", v), format("%.1fkB (%s%.1fkB|r)%s", usedKB, DiffColor(diff / 1000), diff, cpuText), 1, 1, 0.5, 1, 1, 1)
				else
					tt:AddDoubleLine(format(" %s", v), format("%.1fkB%s", usedKB, cpuText), 1, 1, 0.5, 1, 1, 1)
				end
			end
		end

		if (showDiff) then
			local color = DiffColor(diffKB / 3000)

			tt:AddDoubleLine("Total", format("%.1fkB (%s%.1fkB|r)", totalKB, color, diffKB), 1, 1, 1, 1, 1, 1)
		else
			tt:AddDoubleLine("Total", format("%.1fkB", totalKB), 1, 1, 1, 1, 1, 1)
		end

		if (totalCPU > 0) then
			tt:AddDoubleLine(" Z-Perl CPU Usage Comparison", format("%.2f%%", 100 * (totalCPU / allAddonsCPU)), 0.5, 0.5, 1, 0.5, 0.5, 1)
		end
	end

	tt:Show()
	--tt.updateTooltip = 1
end
