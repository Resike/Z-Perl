-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

local L = ZPerl.L

ZPerl.SetModuleRevision("$Revision:  $")

-- SlashHandler
local function SlashHandler(msg)
	local args = { }
	for value in string.gmatch(msg, "[^ ]+") do
		tinsert(args, string.lower(value))
	end
	if (args[1] == nil or args[1] == L["CMD_MENU"] or args[1] == L["CMD_OPTIONS"]) then
		ZPerl.OpenSettings()
	elseif (args[1] == L["CMD_LOCK"]) then
		ZPerl.LockFrames()
	elseif (args[1] == L["CMD_UNLOCK"]) then
		ZPerl.UnlockFrames()
	elseif (args[1] == L["CMD_LAYOUT"]) then
		local active = ZPerl.ActiveLayout()
		local wanted = msg:match("^%s*%S+%s+(.-)%s*$")
		if (wanted == "") then
			wanted = nil
		end
		if (not wanted) then
			ZPerl.Notice(L["LAYOUT_LIST"])
			for _, name in ipairs(ZPerl.LayoutNames()) do
				DEFAULT_CHAT_FRAME:AddMessage(format("|c00FFFF80%s%s", name, name == active and L["LAYOUT_CURRENT"] or ""))
			end
		else
			for _, name in ipairs(ZPerl.LayoutNames()) do
				if (strlower(name) == strlower(wanted)) then
					ZPerl.SelectLayout(name)
					return
				end
			end
			ZPerl.Notice(L["LAYOUT_UNKNOWN"], wanted)
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["CMD_HELP"])
	end
end

SlashCmdList["ZPERL"] = SlashHandler
SLASH_ZPERL1 = "/zperl"
SLASH_ZPERL2 = "/zp"
