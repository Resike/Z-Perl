-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

XPerl_SetModuleRevision("$Revision: @file-revision@ $")

function XPerl_Message(...)
	DEFAULT_CHAT_FRAME:AddMessage(XPERL_MSG_PREFIX.."- "..format(...))
end

function XPerl_SetupFrames()

	local function ValidAlpha(alpha)
		alpha = tonumber(alpha)
		if (alpha < 0 or alpha > 1) then
			alpha = 1
		end
		return alpha
	end

	local function ValidScale(scale)
		scale = tonumber(scale)
		if (scale < 0.5) then
			scale = 0.5
		elseif (scale > (XPerlDB.maximumScale or 1.5)) then
			scale = (XPerlDB.maximumScale or 1.5)
		end
		return scale
	end

	if (ZPerlConfigHelper) then
		ZPerlConfigHelper.AssistsFrame_Transparency = ValidAlpha(ZPerlConfigHelper.AssistsFrame_Transparency)
		XPerl_Assists_Frame:SetAlpha(ZPerlConfigHelper.AssistsFrame_Transparency)

		ZPerlConfigHelper.Targets_Transparency = ValidAlpha(ZPerlConfigHelper.Targets_Transparency)
		XPerl_RaidHelper_Frame:SetAlpha(ZPerlConfigHelper.Targets_Transparency)

		--ZPerlConfigHelper.Scale_AssistsFrame = ValidScale(ZPerlConfigHelper.Scale_AssistsFrame)
		--XPerl_Assists_Frame:SetScale(ZPerlConfigHelper.Scale_AssistsFrame)

		--ZPerlConfigHelper.Targets_Scale = ValidScale(ZPerlConfigHelper.Targets_Scale)
		--XPerl_RaidHelper_Frame:SetScale(ZPerlConfigHelper.Targets_Scale)

		-- Assist Counters

		XPerl_SetupFrameSimple(XPerl_RaidHelper_Frame, ZPerlConfigHelper.Background_Transparency)
		XPerl_SetupFrameSimple(XPerl_MTTargets)
		XPerl_SetupFrameSimple(XPerl_Assists_Frame, ZPerlConfigHelper.Assists_BackTransparency)
		XPerlScrollSeperator:SetAlpha(ZPerlConfigHelper.Assists_BackTransparency)

		XPerl_RaidHelper_Frame_TitleBar_ToggleMTTargets:SetButtonTex()
		XPerl_RaidHelper_Frame_TitleBar_ToggleLabels:SetButtonTex()
		XPerl_RaidHelper_Frame_TitleBar_ToggleShowMT:SetButtonTex()
		XPerl_RaidHelper_Frame_TitleBar_Pin:SetButtonTex()
	end

	if (XPerl_RegisterHighlight) then
		XPerl_RegisterHighlight(XPerl_Player_TargettingFrame, 4)
		XPerl_RegisterHighlight(XPerl_Target_AssistFrame, 4)
		XPerl_RegisterPerlFrames(XPerl_Player_TargettingFrame)
		XPerl_RegisterPerlFrames(XPerl_Target_AssistFrame)
	end
end

-- XPerl_Slash
function XPerl_Slash(msg)

	local commands = {}
	for x in string.gmatch(msg, "[^ ]+") do
		tinsert(commands, string.lower(x))
	end

	local function SubCommandMatch(cmd, match)
		return strsub(match, 1, strlen(cmd)) == cmd
	end

	local function setAlpha()
		if (commands[2] and commands[3]) then
			if (SubCommandMatch(commands[2], "raid")) then
				ZPerlConfigHelper.Targets_Transparency = commands[3]
				return true
			elseif (SubCommandMatch(commands[2], "assists")) then
				ZPerlConfigHelper.AssistsFrame_Transparency = commands[3]
				return true
			end
		end
	end

	local options = {
		{"ma",		XPerl_SetMainAssist},
		{"assists",	XPerl_AssistsView_Open,		"Open Assists View"},
		{"raid",	XPerl_RaidHelp_Show,		"Open Raid Helper"},
		{"alpha",	setAlpha,			"Set Alpha Level"},
		{"labels",	XPerl_Toggle_ToggleLabels,	"Toggle Tank Labels"},
		{"ctra",	XPerl_RaidHelper_ToggleUseCTRATargets,	"Toggle Use of CTRA MT Targets"},
	}

	local foundFunc
	local foundDesc
	if (commands[1]) then
		local smallest = 100
		local len = strlen(commands[1])
		if (len) then
			for i,entry in pairs(options) do
				if (strsub(entry[1], 1, len) == commands[1]) then
					if (foundFunc) then
						XPerl_Message("Ambiguous command, failed.")
						foundFunc = nil
						break
					end
					foundFunc = entry[2]
					foundDesc = entry[3]
				end
			end
		end
	end

	if (foundFunc) then
		if (foundFunc(msg, commands[2], commands[3], commands[4])) then
			XPerl_SetupFrames()
			if (foundDesc) then
				XPerl_Message(foundDesc.." - |c0000C020done!|r")
			end
			return
		end
	end

	XPerl_Message("Options: /xp [|c00FFFF00find|r] [|c00FFFF00assists|r] [|c00FFFF00raid|r] [|c00FFFF00labels|r] [|c00FFFF00alpha|r raid|assists] [|c00FFFF00scale|r raid|assists] [|c00FFFF00ctra|r]")
end

local function DefaultVar(name, value)
	if (ZPerlConfigHelper[name] == nil or (type(value) ~= type(ZPerlConfigHelper[name]))) then
		ZPerlConfigHelper[name] = value
	end
end

local function XPerl_Defaults()
	DefaultVar("RaidHelper",		1)
	DefaultVar("UnitWidth",			100)
	DefaultVar("UnitHeight",		26)
	DefaultVar("UseCTRATargets",		1)
	DefaultVar("NoAutoList",		0)
	DefaultVar("ExpandLock",		0)
	DefaultVar("ShowMT",			1)
	DefaultVar("MTLabels",			0)
	DefaultVar("MTTargetTargets",		1)
	DefaultVar("Targets_Transparency",	0.8)
	DefaultVar("Background_Transparency",	1)
	DefaultVar("Tooltips",			0)
	DefaultVar("TooltipsWhich",		2)		-- 1.9.4
	DefaultVar("MaxMainTanks",		10)
	DefaultVar("MTListUpward",		0)		-- 2.0.6
	DefaultVar("HealerMode",		0)		-- 2.1.0
	DefaultVar("HealerModeType",		1)		-- 2.1.0

	DefaultVar("TargetCounters",		1)
	DefaultVar("TargetCountersSelf",	1)
	DefaultVar("TargetCountersEnemy",	1)
	DefaultVar("ShowTargetCounters",	1)		-- 2.2.4
	DefaultVar("AssistsFrame",		1)
	DefaultVar("TargettingFrame",		1)
	DefaultVar("AssistsFrame_Transparency",	0.8)
	DefaultVar("Assists_BackTransparency",	1)
	DefaultVar("AggroWarning",		1)		-- 1.9.6

	DefaultVar("BorderColour",		{r = 0.5, g = 0.5, b = 0.5, a = 1})
	DefaultVar("BackgroundColour",		{r = 0, g = 0, b = 0, a = 1})
end

-- XPerl_Startup
-- Called after VARIABLES_LOADED
function XPerl_Startup()

	if (not ZPerlConfigHelper) then
		ZPerlConfigHelper = {}
	end
	XPerl_Defaults()
	if (XPerl_StartAssists) then
		XPerl_StartAssists()
	end

	XPerl_SetupFrames()

	XPerlAssistPin:SetButtonTex()
	XPerl_RaidHelper_Frame_TitleBar_Pin:SetButtonTex()

	if (XPerl_RegisterOptionChanger) then
		XPerl_RegisterOptionChanger(XPerl_SetupFrames)
	end
end

if (not XPerl_SetSmoothBarColor) then
	XPerl_SetSmoothBarColor = function(bar, percentage)
		if (bar) then
			local r, g, b
			if (XPerlDB.colour.classic) then
				if (percentage < 0.5) then
					r = 1
					g = 2*percentage
					b = 0
				else
					g = 1
					r = 2*(1 - percentage)
					b = 0
				end
			else
				local c = XPerlDB.colour
				r = c.healthEmpty.r + ((c.healthFull.r - c.healthEmpty.r) * percentage)
				g = c.healthEmpty.g + ((c.healthFull.g - c.healthEmpty.g) * percentage)
				b = c.healthEmpty.b + ((c.healthFull.b - c.healthEmpty.b) * percentage)
			end

			if (r >= 0 and g >= 0 and b >= 0 and r <= 1 and g <= 1 and b <= 1) then
				bar:SetStatusBarColor(r, g, b)
				if (bar.bg) then
					bar.bg:SetVertexColor(r, g, b, 0.25)
				end
			end
		end
	end
end

if (not XPerl_SetUnitNameColor) then
	XPerl_SetUnitNameColor = function(self, unit)
		local r, g, b = 0.5, 0.5, 1

		if (UnitPlayerControlled(unit) or not UnitIsVisible(unit)) then
			local _, class = UnitClass(unit)
			r, g, b = XPerl_GetClassColour(class)
		else
			if (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
				r, g, b = 0.5, 0.5, 0.5
			else
				local reaction = UnitReaction(unit, "player")

				if (reaction) then
					if (reaction >= 5) then
						r, g, b = 0, 1, 0
					elseif (reaction <= 2) then
						r, g, b = 1, 0, 0
					elseif (reaction == 3) then
						r, g, b = 1, 0.5, 0
					else
						r, g, b = 1, 1, 0
					end
				else
					if (UnitFactionGroup("player") == UnitFactionGroup(unit)) then
						r, g, b = 0, 1, 0
					elseif (UnitIsEnemy("player", unit)) then
						r, g, b = 1, 0, 0
					else
						r, g, b = 1, 1, 0
					end
				end
			end
		end

		self:SetTextColor(r, g, b)
	end
end

-- Perl UnitFrame function copies:
if (not XPerl_ColourFriendlyUnit) then
	XPerl_ColourFriendlyUnit = function(frame, partyid)
		if (UnitCanAttack("player", partyid) and UnitIsEnemy("player", partyid)) then -- For dueling
			frame:SetTextColor(1, 0, 0)
		else
			if (not XPerlDB or XPerlDB.colour.class) then
				local _, class = UnitClass(partyid)
				local color = XPerl_GetClassColour(class)
				frame:SetTextColor(color.r, color.g, color.b)
			else
				if (UnitIsPVP(partyid)) then
					frame:SetTextColor(0, 1, 0)
				else
					frame:SetTextColor(0.5, 0.5, 1)
				end
			end
		end
	end
end

if (not XPerl_GetClassColour) then
	XPerl_GetClassColour = function(class)
		if (class) then
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] -- Now using the WoW class color table
			if (color) then
				return color
			end
		end
		return {r = 0.5, g = 0.5, b = 1}
	end
end
