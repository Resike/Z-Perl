-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "deDE" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = ZPerl.ShortProductName.." Schlachtzugsadmin"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "Pin das Fenster"
L["BUTTON_ADMIN_LOCKOPEN"]  = "Das Fenster offen halten"
L["BUTTON_ADMIN_SAVE1"]     = "Liste speichern"
L["BUTTON_ADMIN_SAVE2"]     = "Speichere die derzeitige Liste unter dem spezifischen Namen. Wenn kein Name angegeben wird, wird die aktulle Zeit als Name benutzt"
L["BUTTON_ADMIN_LOAD1"]     = "Liste laden"
L["BUTTON_ADMIN_LOAD2"]     = "Lade die ausgew\195\164hlte Liste. Jedes Schlachtzugsmitglied der gespeicherten Liste, welches nicht l\195\164nger im Schlachtzug ist, wird mit einem Mitglieder derselben Klasse ersetzt, welches nicht Miglied der Liste ist"
L["BUTTON_ADMIN_DELETE1"]   = "Liste l\195\182schen"
L["BUTTON_ADMIN_DELETE2"]   = "Die ausgew\195\164hlte Liste l\195\182schen"
L["BUTTON_ADMIN_STOPLOAD1"] = "Laden stoppen"
L["BUTTON_ADMIN_STOPLOAD2"] = "Den Ladevorgang f\195\188r die Liste abbrechen"

L["LOAD"] = "Laden"

L["SAVED_ROSTER"]         = "Gespeicherte Liste hei\195\159t '%s'"
L["ADMIN_DIFFERENCES"]    = "%d Unterschiede zur aktuellen Liste"
L["NO_ROSTER_NAME_GIVEN"] = "Kein Listenname angegeben"
L["NO_ROSTER_CALLED"]     = "Kein gespeicherter Listenname hei\195\159t '%s'"

-- Item Checker
L["CHECK_TITLE"] = ZPerl.ShortProductName.." Gegenstands-Check"

L["CHECK_NAME"] = "Name"

L["CHECK_DROPITEMTIP1"]         = "Gegenst\195\164nde einf\195\188gen"
L["CHECK_DROPITEMTIP2"]         = "Gegenst\195\164nde k\195\182nnen in dieses Fenster gezogen werden und zur Liste der abfragbaren Gegenst\195\164nde hinzugef\195\188gt werden.\rDu kannst auch ganz normal den /raitem Befehl verwenden um Gegenst\195\164nde hinzuzuf\195\188gen und diese zuk\195\188nftig zu verwenden."
L["CHECK_QUERY_DESC1"]          = "Abfrage"
L["CHECK_QUERY_DESC2"]          = "F\195\188hrt einen Gegenstands-Check (/raitem) f\195\188r alle ausgew\195\164hlten Gegenst\195\164nde durch \rQuery zeigt immer die aktuellen Informationen f\195\188r die Haltbarkeit, Widerst\195\164nde und Reagenzien"
L["CHECK_LAST_DESC1"]           = "Letzte"
L["CHECK_LAST_DESC2"]           = "W\195\164hle die zuletzt gesuchten Gegenst\195\164nde an"
L["CHECK_ALL_DESC1"]            = "Alle"
L["CHECK_ALL_DESC2"]            = "Alle Gegenst\195\164nde ausw\195\164hlen"
L["CHECK_NONE_DESC1"]           = "Nichts"
L["CHECK_NONE_DESC2"]           = "Alle Gegenst\195\164nde abw\195\164hlen"
L["CHECK_DELETE_DESC1"]         = "Löschen"
L["CHECK_DELETE_DESC2"]         = "Entferne dauerhaft alle ausgew\195\164hlten Gegenst\195\164nde von der Liste"
L["CHECK_REPORT_DESC1"]         = "Bericht"
L["CHECK_REPORT_DESC2"]         = "Zeige den Bericht der ausgew\195\164hlten Ergebnisse im Schlachtzugschannel"
L["CHECK_REPORT_WITH_DESC1"]    = "Mit"
L["CHECK_REPORT_WITH_DESC2"]    = "Melde Spieler mit dem Gegenstand (oder nicht angelegt haben) im Schlachtzugschannel"
L["CHECK_REPORT_WITHOUT_DESC1"] = "Ohne"
L["CHECK_REPORT_WITHOUT_DESC2"] = "Melde Spieler ohne den Gegenstand (oder angelegt haben) im Schlachtzugschannel"
L["CHECK_SCAN_DESC1"]           = "Scannen"
L["CHECK_SCAN_DESC2"]           = "Überpr\195\188ft jeden im Schlachtzug innerhalb der Betrachtungsreichweite, um zu sehen ob diese den ausw\195\164hlten Gegenstand angelegt haben und gibt dies in der Spielerliste an. Bewege Dich bis zu 10 Meter an die Spieler im Schlachtzug heran, bis alle \195\188berpr\195\188ft wurden."
L["CHECK_SCANSTOP_DESC1"]       = "Scan stoppen"
L["CHECK_SCANSTOP_DESC2"]       = "Stoppe das Scannen der Spielerausr\195\188stungen f\195\188r den ausgew\195\164hlten Gegenstand"
L["CHECK_REPORTPLAYER_DESC1"]   = "Spieler melden"
L["CHECK_REPORTPLAYER_DESC2"]   = "Melde die Spielerdetails des ausgew\195\164hlten Spieler f\195\188r diesen Gegenstand oder Status im Schlachtzugschannel"

L["CHECK_BROKEN"]               = "Besch\195\164digt"
L["CHECK_REPORT_DURABILITY"]    = "Durchschnittliche Schlachtzugshaltbarkeit: %d%% und %d Spieler mit insgesamt %d besch\195\164digten Gegenst\195\164nden"
L["CHECK_REPORT_PDURABILITY"]   = "%s's Haltbarkeit: %d%% mit %d besch\195\164digten Gegenst\195\164nden"
L["CHECK_REPORT_RESISTS"]       = "Durchschnittliche Schlachtzugswiderst\195\164nde: %d Feuer, %d Natur, %d Frost, %d Schatten, %d Arkan"
L["CHECK_REPORT_PRESISTS"]      = "%s's widersteht: %d Feuer, %d Natur, %d Frost, %d Schatten, %d Arkan"
L["CHECK_REPORT_WITH"]          = " - mit: "
L["CHECK_REPORT_WITHOUT"]       = " - ohne: "
L["CHECK_REPORT_WITH_EQ"]       = " - mit (oder nicht angelegt): "
L["CHECK_REPORT_WITHOUT_EQ"]    = " - ohne (oder angelegt): "
L["CHECK_REPORT_EQUIPED"]       = " : angelegt: "
L["CHECK_REPORT_NOTEQUIPED"]    = " : NICHT angelegt: "
L["CHECK_REPORT_ALLEQUIPED"]    = "Jeder hat %s angelegt"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "Jeder hat %s  angelegt, aber %d Spieler sind offline"
L["CHECK_REPORT_PITEM"]         = "%s hat %d %s im Inventar"
L["CHECK_REPORT_PEQUIPED"]      = "%s hat %s angelegt"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s HAT %s NICHT angelegt"
L["CHECK_REPORT_DROPDOWN"]      = "Ausgabe-Channel"
L["CHECK_REPORT_DROPDOWN_DESC"] = "W\195\164hle einen Ausgabe-Channel f\195\188r die Ergebnisse des Gegenstands-Checker"

L["CHECK_REPORT_WITHSHORT"]       = " : %d mit"
L["CHECK_REPORT_WITHOUTSHORT"]    = " : %d ohne"
L["CHECK_REPORT_EQUIPEDSHORT"]    = " : %d angelegt"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = " : %d NICHT angelegt"
L["CHECK_REPORT_TOTAL"]           = " : %d Gesamte Gegenst\195\164nde"
L["CHECK_REPORT_NOTSCANNED"]      = " : %d ungepr\195\188ft"

L["CHECK_LASTINFO"] = "Letzte Daten empfangen %sago"

L["CHECK_AVERAGE"] = "Durschnitt"
L["CHECK_TOTALS"]  = "Gesamt"
L["CHECK_EQUIPED"] = "Angelegt"

L["CHECK_SCAN_MISSING"] = "Scanne betrachtbare Spieler nach Gegenstand. (%d ungescannt)"

L["REAGENTS"] = {
	PRIEST = "Hochheilige Kerze",
	MAGE = "Arkanes Pulver",
	DRUID = "Wilder Dornwurz",
	SHAMAN = "Ankh",
	WARLOCK = "Seelensplitter",
	PALADIN = "Symbol of Divinity",
	ROGUE = "Blitzstrahlpulver"
} -- English: PALADIN

L["CHECK_REAGENTS"] = "Reagenzien"

-- Roster Text
L["ROSTERTEXT_TITLE"]         = ZPerl.ShortProductName.." Listen Text"
L["ROSTERTEXT_GROUP"]         = "Gruppe %d"
L["ROSTERTEXT_GROUP_DESC"]    = "Verwende Namen f\195\188r Gruppe %d"
L["ROSTERTEXT_SAMEZONE"]      = "Nur selbes Gebiet"
L["ROSTERTEXT_SAMEZONE_DESC"] = "Nur Spielernamen mit einbeziehen, die sich in dem selben Gebiet wie Du befinden"
L["ROSTERTEXT_HELP"]          = "Dr\195\188cke STRG-C zum Kopieren des Textes in die Zwischenablage"
L["ROSTERTEXT_TOTAL"]         = "Gesamt: %d"
L["ROSTERTEXT_SETN"]          = "%d-Mann"
L["ROSTERTEXT_SETN_DESC"]     = "W\195\164hle automatisch die Gruppen f\195\188r einen %d-Mann Schlachtzug"
L["ROSTERTEXT_TOGGLE"]        = "Umschalten"
L["ROSTERTEXT_TOGGLE_DESC"]   = "Die ausgew\195\164hlten Gruppen umschalten"
L["ROSTERTEXT_SORT"]          = "Sortieren"
L["ROSTERTEXT_SORT_DESC"]     = "Nach Name sortieren anstatt nach Gruppe+Name"
