-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "deDE" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFFRechts-Klick|r, um das Symbol zu verschieben"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r, f\195\188r die Z-Perl Speicherausnutzung"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Umschalt|r, f\195\188r die Z-Perl Speicherausnutzung seit dem Start"

L["MINIMENU_OPTIONS"]    = "Optionen"
L["MINIMENU_ASSIST"]     = "Zeige Assistiert-Frame"
L["MINIMENU_CASTMON"]    = "Zeige Casting-Monitor"
L["MINIMENU_RAIDAD"]     = "Zeige Schlachtzugs-Admin"
L["MINIMENU_ITEMCHK"]    = "Zeige Gegenstands-Checker"
L["MINIMENU_ROSTERTEXT"] = "Listen-Text"

L["TYPE_NOT_SPECIFIED"] = "Nicht spezifiziert"
L["TYPE_PET"]           = "Begleiter"
L["TYPE_BOSS"]          = "Boss"
L["TYPE_RAREPLUS"]      = "Rar+"
L["TYPE_ELITE"]         = "Elite"
L["TYPE_RARE"]          = "Rar"

-- Zones
L["LOC_ZONE_BLACK_TEMPLE"]          = "Der Schwarze Tempel"
L["LOC_ZONE_EYE_OF_ETERNITY"]       = "Das Auge der Ewigkeit"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "Hyjalgipfel"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "Eiskronenzitadelle"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]      = "Das Obsidiansanktum"
L["LOC_ZONE_RUBY_SANCTUM"]          = "Das Rubinsanktum"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "H\195\182hle des Schlangenschreins"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "Sonnenbrunnenplateau"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "Pr\195\188fung des Kreuzfahrers"

-- Status
L["LOC_DEAD"]         = "Tot"
L["LOC_GHOST"]        = "Geist"
L["LOC_OFFLINE"]      = "Offline"
L["LOC_RESURRECTED"]  = "Wiederbelebung"
L["LOC_SS_AVAILABLE"] = "SS verf\195\188gbar"
L["LOC_UPDATING"]     = "Aktualisierung"
L["LOC_ACCEPTEDRES"]  = "Akzeptiert"

L["LOC_NONEWATCHED"] = "nicht beobachtet"

L["LOC_STATUSTIP"]     = "Status Hervorhebungen: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "Heilung \195\188ber Zeit",
	AGGRO = "Aggro",
	HEAL = "Wird geheilt",
	SHIELD = "Schild"
}

BINDING_NAME_ZPERL_TOGGLERAID         = "Schalter f\195\188r die Schlachtzugsfenster"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "Schalter f\195\188r Schlachtzugsbegleiter"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "Schalter f\195\188r das Optionenfenster"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "Schalter f\195\188r Buffs/Debuffs/Keine"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Schalter f\195\188r Zauberbar/Heilbar"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "Schalter f\195\188r Reichweiten-Finder"

L["KEY_NOTICE_RAID_BUFFANY"]      = "Alle Buffs/Debuffs anzeigen"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "Nur zauberbare/heilbare Buffs oder Debuffs anzeigen"
L["KEY_NOTICE_RAID_BUFFS"]        = "Schlachtzug-Buffs anzeigen"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "Schlachtzug-Debuffs anzeigen"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "Keine Schlachtzug-Buffs anzeigen"

L["DRAGHINT1"] = "|c00FFFFFFKlicken|r, zum Skalieren des Fensters"
L["DRAGHINT2"] = "|c00FFFFFFUmschalt+Klick|r, zum Anpassen der Fenstergr\195\182\195\159e"

L["RAID_TOOLTIP_WITHBUFF"]    = "Mit Buff: (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "Ohne Buff: (%s)"
