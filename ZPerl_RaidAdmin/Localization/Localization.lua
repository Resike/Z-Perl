--[[
	Localisation file
]]

local L = ZPerl.L

L["ADMIN_TITLE"] = ZPerl.ShortProductName.." Raid Admin"

L["MSG_PREFIX"] = "|c00C05050Z-Perl|r "

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "Pin Window"
L["BUTTON_ADMIN_LOCKOPEN"]  = "Lock Window Open"
L["BUTTON_ADMIN_SAVE1"]     = "Save Roster"
L["BUTTON_ADMIN_SAVE2"]     = "Saves the current roster layout with the name specified. If no name given, the current time will be used as the name"
L["BUTTON_ADMIN_LOAD1"]     = "Load Roster"
L["BUTTON_ADMIN_LOAD2"]     = "Load the selected roster. Any raid members of the saved roster who are no longer in the raid will be replaced by members of the same class who are not saved in the roster"
L["BUTTON_ADMIN_DELETE1"]   = "Delete Roster"
L["BUTTON_ADMIN_DELETE2"]   = "Delete the selected roster"
L["BUTTON_ADMIN_STOPLOAD1"] = "Stop Load"
L["BUTTON_ADMIN_STOPLOAD2"] = "Aborts the roster load procedure"

L["LOAD"] = "Load"

L["SAVED_ROSTER"]         = "Saved roster called '%s'"
L["ADMIN_DIFFERENCES"]    = "%d differences to current roster"
L["NO_ROSTER_NAME_GIVEN"] = "No roster name given"
L["NO_ROSTER_CALLED"]     = "No roster saved called '%s'"

-- Item Checker
L["CHECK_TITLE"] = ZPerl.ShortProductName.." Item Check"

L["CHECK_NAME"] = "Name"

L["CHECK_DROPITEMTIP1"]         = "Drop Items"
L["CHECK_DROPITEMTIP2"]         = "Items can be dropped into this frame and added to the list of queryable items.\rYou may also use the /raitem command as normal and items will also be added here and used in the future."
L["CHECK_QUERY_DESC1"]          = "Query"
L["CHECK_QUERY_DESC2"]          = "Performs item check (/raitem) on all ticked items\rQuery always gets current durablity, resistance and reagents information"
L["CHECK_LAST_DESC1"]           = "Last"
L["CHECK_LAST_DESC2"]           = "Re-tick the last search items"
L["CHECK_ALL_DESC1"]            = "All"
L["CHECK_ALL_DESC2"]            = "Tick all the items"
L["CHECK_NONE_DESC1"]           = "None"
L["CHECK_NONE_DESC2"]           = "Un-tick all the items"
L["CHECK_DELETE_DESC1"]         = "Delete"
L["CHECK_DELETE_DESC2"]         = "Permenantly remove all the ticked items from the list"
L["CHECK_REPORT_DESC1"]         = "Report"
L["CHECK_REPORT_DESC2"]         = "Show report of the selected results to the raid chat"
L["CHECK_REPORT_WITH_DESC1"]    = "With"
L["CHECK_REPORT_WITH_DESC2"]    = "Report people with the item (or don't have the item equipped) to the raid chat. If an equipment scan has been performed, these results will be shown instead."
L["CHECK_REPORT_WITHOUT_DESC1"] = "Without"
L["CHECK_REPORT_WITHOUT_DESC2"] = "Report people without the item (or have the item equipped) to the raid chat"
L["CHECK_SCAN_DESC1"]           = "Scan"
L["CHECK_SCAN_DESC2"]           = "Will check anyone in raid within inspect range, to see whether they have the selected item equipped and indicate this on the player list. Move closer (10 yards) to people in the raid until all are checked."
L["CHECK_SCANSTOP_DESC1"]       = "Stop Scan"
L["CHECK_SCANSTOP_DESC2"]       = "Stop scanning player's equipment for the selected item"
L["CHECK_REPORTPLAYER_DESC1"]   = "Report Player"
L["CHECK_REPORTPLAYER_DESC2"]   = "Report selected player's details for this item or status to the raid chat"

L["CHECK_BROKEN"]               = "Broken"
L["CHECK_REPORT_DURABILITY"]    = "Average Raid Durability: %d%% and %d people with a total of %d broken items"
L["CHECK_REPORT_PDURABILITY"]   = "%s's Durability: %d%% with %d broken items"
L["CHECK_REPORT_RESISTS"]       = "Average Raid resists: %d Fire, %d Nature, %d Frost, %d Shadow, %d Arcane"
L["CHECK_REPORT_PRESISTS"]      = "%s's Resists: %d Fire, %d Nature, %d Frost, %d Shadow, %d Arcane"
L["CHECK_REPORT_WITH"]          = " - with: "
L["CHECK_REPORT_WITHOUT"]       = " - without: "
L["CHECK_REPORT_WITH_EQ"]       = " - with (or not equipped): "
L["CHECK_REPORT_WITHOUT_EQ"]    = " - without (or equipped): "
L["CHECK_REPORT_EQUIPED"]       = " : equipped: "
L["CHECK_REPORT_NOTEQUIPED"]    = " : NOT equipped: "
L["CHECK_REPORT_ALLEQUIPED"]    = "Everyone has %s equipped"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "Everyone has %s equipped, but %d member(s) offline"
L["CHECK_REPORT_PITEM"]         = "%s has %d %s in inventory"
L["CHECK_REPORT_PEQUIPED"]      = "%s has %s equipped"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s DOES NOT have %s equipped"
L["CHECK_REPORT_DROPDOWN"]      = "Output Channel"
L["CHECK_REPORT_DROPDOWN_DESC"] = "Select output channel for Item Checker results"

L["CHECK_REPORT_WITHSHORT"]       = " : %d with"
L["CHECK_REPORT_WITHOUTSHORT"]    = " : %d without"
L["CHECK_REPORT_EQUIPEDSHORT"]    = " : %d equipped"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = " : %d NOT equipped"
L["CHECK_REPORT_OFFLINE"]         = " : %d offline"
L["CHECK_REPORT_TOTAL"]           = " : %d Total Items"
L["CHECK_REPORT_NOTSCANNED"]      = " : %d un-checked"

L["CHECK_LASTINFO"] = "Last data received %sago"

L["CHECK_AVERAGE"] = "Average"
L["CHECK_TOTALS"]  = "Total"
L["CHECK_EQUIPED"] = "Equipped"

L["CHECK_SCAN_MISSING"] = "Scanning inspectable players for item. (%d un-scanned)"

L["REAGENTS"] = {PRIEST = "Sacred Candle", MAGE = "Arcane Powder", DRUID = "Wild Thornroot",
					SHAMAN = "Ankh", WARLOCK = "Soul Shard", PALADIN = "Symbol of Divinity",
					ROGUE = "Flash Powder"}

L["CHECK_REAGENTS"] = "Reagents"

-- Roster Text
L["ROSTERTEXT_TITLE"]         = ZPerl.ShortProductName.." Roster Text"
L["ROSTERTEXT_GROUP"]         = "Group %d"
L["ROSTERTEXT_GROUP_DESC"]    = "Use names from group %d"
L["ROSTERTEXT_SAMEZONE"]      = "Same Zone Only"
L["ROSTERTEXT_SAMEZONE_DESC"] = "Only include names of players in the same zone as yourself"
L["ROSTERTEXT_HELP"]          = "Press Ctrl-C to copy the text to the clipboard"
L["ROSTERTEXT_TOTAL"]         = "Total: %d"
L["ROSTERTEXT_SETN"]          = "%d Man"
L["ROSTERTEXT_SETN_DESC"]     = "Auto select the groups for a %d man raid"
L["ROSTERTEXT_TOGGLE"]        = "Toggle"
L["ROSTERTEXT_TOGGLE_DESC"]   = "Toggle the selected groups"
L["ROSTERTEXT_SORT"]          = "Sort"
L["ROSTERTEXT_SORT_DESC"]     = "Sort by name instead of by group+name"
