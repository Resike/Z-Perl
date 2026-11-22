-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

ZPerl.ProductName      = "|cFFD00000Z-Perl|r"
ZPerl.ShortProductName = "|cFFD00000Z-Perl|r"
ZPerl.Description      = ZPerl.ProductName
ZPerl.VersionNumber    = C_AddOns.GetAddOnMetadata("ZPerl", "Version")
ZPerl.Version          = ZPerl.Description.." - "..ZPerl.VersionNumber
ZPerl.ModMenuIcon      = "Interface\\Icons\\INV_Misc_Gem_Pearl_02"

L["MINIMAP_HELP1"] = "|c00FFFFFFLeft click|r for Options"
L["MINIMAP_HELP2"] = "|c00FFFFFFRight click|r to drag this icon"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r for Z-Perl memory usage"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Shift|r for Z-Perl memory usage since startup"

L["MINIMENU_OPTIONS"]    = "Options"
L["MINIMENU_ASSIST"]     = "Show Assists Frame"
L["MINIMENU_CASTMON"]    = "Show Casting Monitor"
L["MINIMENU_RAIDAD"]     = "Show Raid Admin"
L["MINIMENU_ITEMCHK"]    = "Show Item Checker"
L["MINIMENU_ROSTERTEXT"] = "Roster Text"

L["TYPE_NOT_SPECIFIED"] = "Not specified"
L["TYPE_PET"]           = "Pet"
L["TYPE_BOSS"]          = "Boss"
L["TYPE_RAREPLUS"]      = "Rare+"
L["TYPE_ELITE"]         = "Elite"
L["TYPE_RARE"]          = "Rare"

-- Zones
L["LOC_ZONE_ANTORUS"]               = "Antorus"
L["LOC_ZONE_BARADIN_HOLD"]          = "Baradin Hold"
L["LOC_ZONE_BASTION_OF_TWILIGHT"]   = "The Bastion of Twilight"
L["LOC_ZONE_BLACK_TEMPLE"]          = "Black Temple"
L["LOC_ZONE_BLACKWING_DECENT"]      = "Blackwing Descent"
L["LOC_ZONE_DRAGONSOUL"]            = "Dragon Soul"
L["LOC_ZONE_EYE_OF_ETERNITY"]       = "The Eye of Eternity"
L["LOC_ZONE_FIRELANDS"]             = "Firelands"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "Hyjal Summit"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "Icecrown Citadel"
L["LOC_ZONE_KARAZHAN"]              = "Karazhan"
L["LOC_ZONE_NAXXRAMAS"]             = "Naxxramas"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]      = "The Obsidian Sanctum"
L["LOC_ZONE_RUBY_SANCTUM"]          = "The Ruby Sanctum"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "Serpentshrine Cavern"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "Sunwell Plateau"
L["LOC_ZONE_THRONE_OF_FOUR_WINDS"]  = "Throne of Four Winds"
L["LOC_ZONE_TOMB_OF_SARGERAS"]      = "Tomb of Sargeras"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "Trial of the Crusader"
L["LOC_ZONE_ULDUAR"]                = "Ulduar"
-- Any zones 4.x and higher can all be localized from EJ, in 5.0, even these above zones are in EJ which means the rest can go bye bye too

-- Status
L["LOC_DEAD"]         = "Dead"
L["LOC_GHOST"]        = "Ghost"
L["LOC_OFFLINE"]      = "Offline"
L["LOC_RESURRECTED"]  = "Resurrected"
L["LOC_SS_AVAILABLE"] = "SS Available"
L["LOC_UPDATING"]     = "Updating"
L["LOC_ACCEPTEDRES"]  = "Accepted"
L["RAID_GROUPSHORT"]  = "G%d"

L["LOC_NONEWATCHED"] = "none watched"

L["LOC_STATUSTIP"]     = "Status Highlights: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "Heal over Time",
	AGGRO = "Aggro",
	HEAL = "Being healed",
	SHIELD = "Shielded"
}

L["LOC_LARGENUMTAG"]    = "K"
L["LOC_HUGENUMTAG"]     = "M"
L["LOC_VERYHUGENUMTAG"] = "G"

BINDING_HEADER_ZPERL                  = ZPerl.ProductName
BINDING_NAME_ZPERL_TOGGLERAID         = "Toggle Raid Windows"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "Toggle Raid Pets"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "Toggle Options Window"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "Toggle Buffs/Debuffs/none"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Toggle Castable/Curable"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "Toggle Range Finder"

L["KEY_NOTICE_RAID_BUFFANY"]           = "All buffs/debuffs shown"
L["KEY_NOTICE_RAID_BUFFCURECAST"]      = "Only castable/curable buffs or debuffs shown"
L["KEY_NOTICE_RAID_BUFFS"]             = "Raid Buffs shown"
L["KEY_NOTICE_RAID_DEBUFFS"]           = "Raid Debuffs shown"
L["KEY_NOTICE_RAID_BUFFS_AND_DEBUFFS"] = "Raid Buffs and Debuffs shown"
L["KEY_NOTICE_RAID_NOBUFFS"]           = "No raid buffs shown"

L["DRAGHINT1"] = "|c00FFFFFFClick|r to scale window"
L["DRAGHINT2"] = "|c00FFFFFFShift+Click|r to resize window"

L["CMD_MENU"]       = "menu"
L["CMD_OPTIONS"]    = "options"
L["CMD_LOCK"]       = "lock"
L["CMD_UNLOCK"]     = "unlock"
L["CMD_LAYOUT"]     = "layout"
L["CMD_HELP"]       = "|c00FFFF80Usage: |c00FFFFFF/zperl menu | lock | unlock | layout [name]"
L["LAYOUT_LIST"]    = "Layouts:"
L["LAYOUT_CURRENT"] = " (Current)"
L["LAYOUT_UNKNOWN"] = "No layout named %s"

L["RAID_TOOLTIP_WITHBUFF"]    = "With buff: (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "Without buff: (%s)"
