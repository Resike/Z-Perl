if (GetLocale() == "deDE") then
	XPERL_ADMIN_TITLE	= XPerl_ShortProductName.." Schlachtzugsadmin"

	-- Raid Admin
	XPERL_BUTTON_ADMIN_PIN			= "Pin das Fenster"
	XPERL_BUTTON_ADMIN_LOCKOPEN		= "Das Fenster offen halten"
	XPERL_BUTTON_ADMIN_SAVE1		= "Liste speichern"
	XPERL_BUTTON_ADMIN_SAVE2		= "Speichere die derzeitige Liste unter dem spezifischen Namen. Wenn kein Name angegeben wird, wird die aktulle Zeit als Name benutzt"
	XPERL_BUTTON_ADMIN_LOAD1		= "Liste laden"
	XPERL_BUTTON_ADMIN_LOAD2		= "Lade die ausgew\195\164hlte Liste. Jedes Schlachtzugsmitglied der gespeicherten Liste, welches nicht l\195\164nger im Schlachtzug ist, wird mit einem Mitglieder derselben Klasse ersetzt, welches nicht Miglied der Liste ist"
	XPERL_BUTTON_ADMIN_DELETE1		= "Liste l\195\182schen"
	XPERL_BUTTON_ADMIN_DELETE2		= "Die ausgew\195\164hlte Liste l\195\182schen"
	XPERL_BUTTON_ADMIN_STOPLOAD1	= "Laden stoppen"
	XPERL_BUTTON_ADMIN_STOPLOAD2	= "Den Ladevorgang f\195\188r die Liste abbrechen"

	XPERL_LOAD						= "Laden"

	XPERL_SAVED_ROSTER				= "Gespeicherte Liste hei\195\159t '%s'"
	XPERL_ADMIN_DIFFERENCES			= "%d Unterschiede zur aktuellen Liste"
	XPERL_NO_ROSTER_NAME_GIVEN		= "Kein Listenname angegeben"
	XPERL_NO_ROSTER_CALLED			= "Kein gespeicherter Listenname hei\195\159t '%s'"

	-- Item Checker
	XPERL_CHECK_TITLE				= XPerl_ShortProductName.." Gegenstands-Check"

	XPERL_CHECK_NAME				= NAME

	XPERL_CHECK_DROPITEMTIP1			= "Gegenst\195\164nde einf\195\188gen"
	XPERL_CHECK_DROPITEMTIP2			= "Gegenst\195\164nde k\195\182nnen in dieses Fenster gezogen werden und zur Liste der abfragbaren Gegenst\195\164nde hinzugef\195\188gt werden.\rDu kannst auch ganz normal den /raitem Befehl verwenden um Gegenst\195\164nde hinzuzuf\195\188gen und diese zuk\195\188nftig zu verwenden."
	XPERL_CHECK_QUERY_DESC1				= "Abfrage"
	XPERL_CHECK_QUERY_DESC2				= "F\195\188hrt einen Gegenstands-Check (/raitem) f\195\188r alle ausgew\195\164hlten Gegenst\195\164nde durch \rQuery zeigt immer die aktuellen Informationen f\195\188r die Haltbarkeit, Widerst\195\164nde und Reagenzien"
	XPERL_CHECK_LAST_DESC1				= "Letzte"
	XPERL_CHECK_LAST_DESC2				= "W\195\164hle die zuletzt gesuchten Gegenst\195\164nde an"
	XPERL_CHECK_ALL_DESC1				= ALL
	XPERL_CHECK_ALL_DESC2				= "Alle Gegenst\195\164nde ausw\195\164hlen"
	XPERL_CHECK_NONE_DESC1				= NONE
	XPERL_CHECK_NONE_DESC2				= "Alle Gegenst\195\164nde abw\195\164hlen"
	XPERL_CHECK_DELETE_DESC1			= DELETE
	XPERL_CHECK_DELETE_DESC2			= "Entferne dauerhaft alle ausgew\195\164hlten Gegenst\195\164nde von der Liste"
	XPERL_CHECK_REPORT_DESC1			= "Bericht"
	XPERL_CHECK_REPORT_DESC2			= "Zeige den Bericht der ausgew\195\164hlten Ergebnisse im Schlachtzugschannel"
	XPERL_CHECK_REPORT_WITH_DESC1		= "Mit"
	XPERL_CHECK_REPORT_WITH_DESC2		= "Melde Spieler mit dem Gegenstand (oder nicht angelegt haben) im Schlachtzugschannel"
	XPERL_CHECK_REPORT_WITHOUT_DESC1	= "Ohne"
	XPERL_CHECK_REPORT_WITHOUT_DESC2	= "Melde Spieler ohne den Gegenstand (oder angelegt haben) im Schlachtzugschannel"
	XPERL_CHECK_SCAN_DESC1				= "Scannen"
	XPERL_CHECK_SCAN_DESC2				= "Überpr\195\188ft jeden im Schlachtzug innerhalb der Betrachtungsreichweite, um zu sehen ob diese den ausw\195\164hlten Gegenstand angelegt haben und gibt dies in der Spielerliste an. Bewege Dich bis zu 10 Meter an die Spieler im Schlachtzug heran, bis alle \195\188berpr\195\188ft wurden."
	XPERL_CHECK_SCANSTOP_DESC1			= "Scan stoppen"
	XPERL_CHECK_SCANSTOP_DESC2			= "Stoppe das Scannen der Spielerausr\195\188stungen f\195\188r den ausgew\195\164hlten Gegenstand"
	XPERL_CHECK_REPORTPLAYER_DESC1		= "Spieler melden"
	XPERL_CHECK_REPORTPLAYER_DESC2		= "Melde die Spielerdetails des ausgew\195\164hlten Spieler f\195\188r diesen Gegenstand oder Status im Schlachtzugschannel"

	XPERL_CHECK_BROKEN					= "Besch\195\164digt"
	XPERL_CHECK_REPORT_DURABILITY		= "Durchschnittliche Schlachtzugshaltbarkeit: %d%% und %d Spieler mit insgesamt %d besch\195\164digten Gegenst\195\164nden"
	XPERL_CHECK_REPORT_PDURABILITY		= "%s's Haltbarkeit: %d%% mit %d besch\195\164digten Gegenst\195\164nden"
	XPERL_CHECK_REPORT_RESISTS			= "Durchschnittliche Schlachtzugswiderst\195\164nde: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
	XPERL_CHECK_REPORT_PRESISTS			= "%s's widersteht: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
	XPERL_CHECK_REPORT_WITH				= " - mit: "
	XPERL_CHECK_REPORT_WITHOUT			= " - ohne: "
	XPERL_CHECK_REPORT_WITH_EQ			= " - mit (oder nicht angelegt): "
	XPERL_CHECK_REPORT_WITHOUT_EQ		= " - ohne (oder angelegt): "
	XPERL_CHECK_REPORT_EQUIPED			= " : angelegt: "
	XPERL_CHECK_REPORT_NOTEQUIPED		= " : NICHT angelegt: "
	XPERL_CHECK_REPORT_ALLEQUIPED		= "Jeder hat %s angelegt"
	XPERL_CHECK_REPORT_ALLEQUIPEDOFF	= "Jeder hat %s  angelegt, aber %d Spieler sind offline"
	XPERL_CHECK_REPORT_PITEM			= "%s hat %d %s im Inventar"
	XPERL_CHECK_REPORT_PEQUIPED			= "%s hat %s angelegt"
	XPERL_CHECK_REPORT_PNOTEQUIPED		= "%s HAT %s NICHT angelegt"
	XPERL_CHECK_REPORT_DROPDOWN			= "Ausgabe-Channel"
	XPERL_CHECK_REPORT_DROPDOWN_DESC	= "W\195\164hle einen Ausgabe-Channel f\195\188r die Ergebnisse des Gegenstands-Checker"

	XPERL_CHECK_REPORT_WITHSHORT		= " : %d mit"
	XPERL_CHECK_REPORT_WITHOUTSHORT		= " : %d ohne"
	XPERL_CHECK_REPORT_EQUIPEDSHORT		= " : %d angelegt"
	XPERL_CHECK_REPORT_NOTEQUIPEDSHORT	= " : %d NICHT angelegt"
	XPERL_CHECK_REPORT_OFFLINE			= " : %d offline"
	XPERL_CHECK_REPORT_TOTAL			= " : %d Gesamte Gegenst\195\164nde"
	XPERL_CHECK_REPORT_NOTSCANNED		= " : %d ungepr\195\188ft"

	XPERL_CHECK_LASTINFO				= "Letzte Daten empfangen %sago"

	XPERL_CHECK_AVERAGE					= "Durschnitt"
	XPERL_CHECK_TOTALS					= "Gesamt"
	XPERL_CHECK_EQUIPED					= "Angelegt"

	XPERL_CHECK_SCAN_MISSING			= "Scanne betrachtbare Spieler nach Gegenstand. (%d ungescannt)"

	XPERL_REAGENTS						= {PRIEST = "Hochheilige Kerze", MAGE = "Arkanes Pulver", DRUID = "Wilder Dornwurz",
										   SHAMAN = "Ankh", WARLOCK = "Seelensplitter", ROGUE = "Blitzstrahlpulver"}
	XPERL_CHECK_REAGENTS				= "Reagenzien"

	-- Roster Text
	XPERL_ROSTERTEXT_TITLE			= XPerl_ShortProductName.." Listen Text"
	XPERL_ROSTERTEXT_GROUP			= "Gruppe %d"
	XPERL_ROSTERTEXT_GROUP_DESC		= "Verwende Namen f\195\188r Gruppe %d"
	XPERL_ROSTERTEXT_SAMEZONE		= "Nur selbes Gebiet"
	XPERL_ROSTERTEXT_SAMEZONE_DESC	= "Nur Spielernamen mit einbeziehen, die sich in dem selben Gebiet wie Du befinden"
	XPERL_ROSTERTEXT_HELP			= "Dr\195\188cke STRG-C zum Kopieren des Textes in die Zwischenablage"
	XPERL_ROSTERTEXT_TOTAL			= "Gesamt: %d"
	XPERL_ROSTERTEXT_SETN			= "%d-Mann"
	XPERL_ROSTERTEXT_SETN_DESC		= "W\195\164hle automatisch die Gruppen f\195\188r einen %d-Mann Schlachtzug"
	XPERL_ROSTERTEXT_TOGGLE			= "Umschalten"
	XPERL_ROSTERTEXT_TOGGLE_DESC	= "Die ausgew\195\164hlten Gruppen umschalten"
	XPERL_ROSTERTEXT_SORT			= "Sortieren"
	XPERL_ROSTERTEXT_SORT_DESC		= "Nach Name sortieren anstatt nach Gruppe+Name"
end
