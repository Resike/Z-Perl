-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

ZPerl.SetModuleRevision("$Revision:  $")

function ZPerl.Message(...)
	DEFAULT_CHAT_FRAME:AddMessage(L["MSG_PREFIX"].."- "..format(...))
end

function ZPerl.RaidHelper.SetupFrames()

	---@return number
	local function ValidAlpha(value)
		-- a stored or typed value that is not a number (/zphelper alpha raid x) becomes opaque
		local alpha = tonumber(value) or 1
		if (alpha < 0 or alpha > 1) then
			alpha = 1
		end
		return alpha
	end

	local function ValidScale(scale)
		scale = tonumber(scale)
		if (scale < 0.5) then
			scale = 0.5
		elseif (scale > (ZPerl.layout.maximumScale or 1.5)) then
			scale = (ZPerl.layout.maximumScale or 1.5)
		end
		return scale
	end

	if (ZPerlRaidHelperDB) then
		local assistsAlpha = ValidAlpha(ZPerlRaidHelperDB.AssistsFrame_Transparency)
		ZPerlRaidHelperDB.AssistsFrame_Transparency = assistsAlpha
		ZPerl_Assists_Frame:SetAlpha(assistsAlpha)

		local targetsAlpha = ValidAlpha(ZPerlRaidHelperDB.Targets_Transparency)
		ZPerlRaidHelperDB.Targets_Transparency = targetsAlpha
		ZPerl_RaidHelper_Frame:SetAlpha(targetsAlpha)

		--ZPerlRaidHelperDB.Scale_AssistsFrame = ValidScale(ZPerlRaidHelperDB.Scale_AssistsFrame)
		--ZPerl_Assists_Frame:SetScale(ZPerlRaidHelperDB.Scale_AssistsFrame)

		--ZPerlRaidHelperDB.Targets_Scale = ValidScale(ZPerlRaidHelperDB.Targets_Scale)
		--ZPerl_RaidHelper_Frame:SetScale(ZPerlRaidHelperDB.Targets_Scale)

		-- Assist Counters

		ZPerl.RaidHelper.SetupFrameSimple(ZPerl_RaidHelper_Frame, ZPerlRaidHelperDB.Background_Transparency)
		ZPerl.RaidHelper.SetupFrameSimple(ZPerl_MTTargets)
		ZPerl.RaidHelper.SetupFrameSimple(ZPerl_Assists_Frame, ZPerlRaidHelperDB.Assists_BackTransparency)
		ZPerl_ScrollSeperator:SetAlpha(ZPerlRaidHelperDB.Assists_BackTransparency)

		ZPerl_RaidHelper_Frame_TitleBar_ToggleMTTargets:SetButtonTex()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleLabels:SetButtonTex()
		ZPerl_RaidHelper_Frame_TitleBar_ToggleShowMT:SetButtonTex()
		ZPerl_RaidHelper_Frame_TitleBar_Pin:SetButtonTex()
	end

	if (ZPerl.RegisterHighlight) then
		ZPerl.RegisterHighlight(ZPerl_Player_TargettingFrame, 4)
		ZPerl.RegisterHighlight(ZPerl_Target_AssistFrame, 4)
		ZPerl.RegisterPerlFrames(ZPerl_Player_TargettingFrame)
		ZPerl.RegisterPerlFrames(ZPerl_Target_AssistFrame)
	end
end

-- ZPerl.RaidHelper.Slash
function ZPerl.RaidHelper.Slash(msg)

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
				ZPerlRaidHelperDB.Targets_Transparency = commands[3]
				return true
			elseif (SubCommandMatch(commands[2], "assists")) then
				ZPerlRaidHelperDB.AssistsFrame_Transparency = commands[3]
				return true
			end
		end
	end

	local options = {
		{"assists",	ZPerl.RaidHelper.AssistsViewOpen,		"Open Assists View"},
		{"raid",	ZPerl.RaidHelper.RaidHelpShow,		"Open Raid Helper"},
		{"alpha",	setAlpha,			"Set Alpha Level"},
		{"ctra",	ZPerl.RaidHelper.ToggleUseCTRATargets,	"Toggle Use of CTRA MT Targets"},
	}

	local foundFunc
	local foundDesc
	if (commands[1]) then
		local len = strlen(commands[1])
		if (len) then
			for i,entry in pairs(options) do
				---@diagnostic disable-next-line: type-mismatch
				if (strsub(entry[1], 1, len) == commands[1]) then
					if (foundFunc) then
						ZPerl.Message("Ambiguous command, failed.")
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
			ZPerl.RaidHelper.SetupFrames()
			if (foundDesc) then
				ZPerl.Message(foundDesc.." - |c0000C020done!|r")
			end
			return
		end
	end

	ZPerl.Message("Options: /zphelper [|c00FFFF00assists|r] [|c00FFFF00raid|r] [|c00FFFF00alpha|r raid|assists] [|c00FFFF00ctra|r]")
end

local function DefaultVar(name, value)
	if (ZPerlRaidHelperDB[name] == nil or (type(value) ~= type(ZPerlRaidHelperDB[name]))) then
		ZPerlRaidHelperDB[name] = value
	end
end

local function Defaults()
	DefaultVar("RaidHelper",		1)
	DefaultVar("UnitWidth",			100)
	DefaultVar("UnitHeight",		26)
	DefaultVar("UseCTRATargets",		1)
	DefaultVar("NoAutoList",		0)
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

	DefaultVar("BorderColor",		{r = 0.5, g = 0.5, b = 0.5, a = 1})
end

-- ZPerl.RaidHelper.Startup
-- Called after VARIABLES_LOADED
function ZPerl.RaidHelper.Startup()

	if (not ZPerlRaidHelperDB) then
		ZPerlRaidHelperDB = {}
	end
	ZPerl.MigrateColorKeys(ZPerlRaidHelperDB)
	Defaults()
	if (ZPerl.RaidHelper.StartAssists) then
		ZPerl.RaidHelper.StartAssists()
	end

	ZPerl.RaidHelper.SetupFrames()

	ZPerl_AssistPin:SetButtonTex()
	ZPerl_RaidHelper_Frame_TitleBar_Pin:SetButtonTex()

	if (ZPerl.RegisterOptionChanger) then
		ZPerl.RegisterOptionChanger(ZPerl.RaidHelper.SetupFrames, nil, "raidhelper")
	end
end

if (not ZPerl.SetUnitNameColor) then
	ZPerl.SetUnitNameColor = function(self, unit)
		local r, g, b = 0.5, 0.5, 1

		if (UnitPlayerControlled(unit) or not UnitIsVisible(unit)) then
			local _, class = UnitClass(unit)
			r, g, b = ZPerl.GetClassColor(class)
		else
			if (ZPerl.SafeBool(UnitIsTapDenied(unit), false)) then
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
if (not ZPerl.ColorFriendlyUnit) then
	ZPerl.ColorFriendlyUnit = function(frame, partyid)
		if (UnitCanAttack("player", partyid) and UnitIsEnemy("player", partyid)) then -- For dueling
			frame:SetTextColor(1, 0, 0)
		else
			if (not ZPerl.layout or ZPerl.layout.color.class) then
				local _, class = UnitClass(partyid)
				local color = ZPerl.GetClassColor(class)
				frame:SetTextColor(color.r, color.g, color.b)
			else
				if (ZPerl.SafeBool(UnitIsPVP(partyid), false)) then
					frame:SetTextColor(0, 1, 0)
				else
					frame:SetTextColor(0.5, 0.5, 1)
				end
			end
		end
	end
end

if (not ZPerl.GetClassColor) then
	ZPerl.GetClassColor = function(class)
		if (class) then
			local color = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class] -- Now using the WoW class color table
			if (color) then
				return color
			end
		end
		return {r = 0.5, g = 0.5, b = 1}
	end
end
