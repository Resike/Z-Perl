-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)
if (GetLocale() == "itIT") then
	XPerl_ProductName		= "|cFFD00000X-Perl|r UnitFrames"
	XPerl_ShortProductName	= "|cFFD00000X-Perl|r"
	XPerl_Author			= "|cFFFF8080Zek|r"
	XPerl_Description		= XPerl_ProductName.." di "..XPerl_Author

	XPerl_Version			= XPerl_Description.." - "..XPerl_VersionNumber
	XPerl_LongDescription	= "Sostituzione dell'UnitFrame del Personaggio, Famiglio, Gruppo, Bersaglio, Bersaglio del Bersaglio, Focus e Incursioni"
	XPerl_ModMenuIcon		= "Interface\\Icons\\INV_Misc_Gem_Pearl_02"

	XPERL_MINIMAP_HELP1		= "|c00FFFFFFClick Sinistro|r per le opzioni (e per |c0000FF00sbloccare le finestre|r)"
	XPERL_MINIMAP_HELP2		= "|c00FFFFFFClick Destro|r per spostare questa icona"
	XPERL_MINIMAP_HELP3		= "\rMembri reali dell'incursione: |c00FFFF80%d|r\rMembri reali del gruppo: |c00FFFF80%d|r"
	XPERL_MINIMAP_HELP4		= "\rSei il capogruppo/capoincursione reale"
	XPERL_MINIMAP_HELP5		= "|c00FFFFFFAlt|r per info sull'uso di memoria di X-Perl"
	XPERL_MINIMAP_HELP6		= "|c00FFFFFF+Maiusc|r per l'uso di memoria di X-Perl dall'avvio"

	XPERL_MINIMENU_OPTIONS	= "Opzioni"
	XPERL_MINIMENU_ASSIST	= "Visualizza finestra assist"
	XPERL_MINIMENU_CASTMON	= "Visualizza monitor dei lanci delle magie"
	XPERL_MINIMENU_RAIDAD	= "Visualizza Amministratore Incursione"
	XPERL_MINIMENU_ITEMCHK	= "Visualizza Controllo Oggetti"
	XPERL_MINIMENU_RAIDBUFF = "Buff Incursione"
	XPERL_MINIMENU_ROSTERTEXT="Roster Text"
	XPERL_MINIMENU_RAIDSORT = "Riorganizzazione Incursione"
	XPERL_MINIMENU_RAIDSORT_GROUP = "Organizza per gruppo"
	XPERL_MINIMENU_RAIDSORT_CLASS = "Organizza per classe"

	XPERL_TYPE_NOT_SPECIFIED = "Non specificato"
	XPERL_TYPE_PET		= PET			-- "Pet"
	XPERL_TYPE_BOSS		= "Boss"
	XPERL_TYPE_RAREPLUS = "Raro+"
	XPERL_TYPE_ELITE	= "Elite"
	XPERL_TYPE_RARE		= "Raro"

	-- Zones
	XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "Serpentshrine Cavern"
	XPERL_LOC_ZONE_BLACK_TEMPLE = "Tempio Nero"
	XPERL_LOC_ZONE_HYJAL_SUMMIT = "Hyjal Summit"
	XPERL_LOC_ZONE_KARAZHAN = "Karazhan"
	XPERL_LOC_ZONE_SUNWELL_PLATEAU = "Sunwell Plateau"
	XPERL_LOC_ZONE_NAXXRAMAS = "Naxxramas"
	XPERL_LOC_ZONE_OBSIDIAN_SANCTUM = "The Obsidian Sanctum"
	XPERL_LOC_ZONE_EYE_OF_ETERNITY = "The Eye of Eternity"
	XPERL_LOC_ZONE_ULDUAR = "Ulduar"
	XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "Trial of the Crusader"
	XPERL_LOC_ZONE_ICECROWN_CITADEL = "Corona di Ghiaccio"
	XPERL_LOC_ZONE_RUBY_SANCTUM = "The Ruby Sanctum"
	--Any zones 4.x and higher can all be localized from EJ, in 5.0, even these above zones are in EJ which means the rest can go bye bye too

	-- Status
	XPERL_LOC_DEAD		= DEAD			-- "Dead"
	XPERL_LOC_GHOST		= "Spirito"
	XPERL_LOC_FEIGNDEATH	= "Finta morte"
	XPERL_LOC_OFFLINE	= PLAYER_OFFLINE	-- "Offline"
	XPERL_LOC_RESURRECTED	= "Riportato in vita"
	XPERL_LOC_SS_AVAILABLE	= "SS Disponibile"
	XPERL_LOC_UPDATING	= "In aggiornamento"
	XPERL_LOC_ACCEPTEDRES	= "Accettata"		-- Res accepted
	XPERL_RAID_GROUP	= "Gruppo %d"
	XPERL_RAID_GROUPSHORT	= "G%d"

	XPERL_LOC_NONEWATCHED	= "none watched"

	XPERL_LOC_STATUSTIP = "Evidenziaziazione stato: " 	-- Tooltip explanation of status highlight on unit
	XPERL_LOC_STATUSTIPLIST = {
		HOT = "Cure nel Tempo (HOT)",
		AGGRO = "Aggressione",
		MISSING = "Missing your class' buff",
		HEAL = "Sta per essere curato",
		SHIELD = "Shielded"
	}

	XPERL_OK		= "OK"
	XPERL_CANCEL		= "Annulla"

	XPERL_LOC_LARGENUMTAG		= "K"
	XPERL_LOC_HUGENUMTAG		= "M"
	XPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_ZPERL = XPerl_ProductName
	BINDING_NAME_ZPERL_TOGGLERAID = "Abilita/Disattiva Raid Windows"
	BINDING_NAME_ZPERL_TOGGLERAIDSORT = "Abilita/Disattiva riorganizzazione per classe/gruppo"
	BINDING_NAME_ZPERL_TOGGLERAIDPETS = "Abilita/Disattiva Raid Pets"
	BINDING_NAME_ZPERL_TOGGLEOPTIONS = "Abilita/Disattiva finestra opzioni"
	BINDING_NAME_ZPERL_TOGGLEBUFFTYPE = "Abilita/Disattiva Buffs/Debuffs/none"
	BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Abilita/Disattiva Castable/Curable"
	BINDING_NAME_ZPERL_TEAMSPEAKMONITOR = "Teamspeak Monitor"
	BINDING_NAME_ZPERL_TOGGLERANGEFINDER = "Abilita/Disattiva Range Finder"

	XPERL_KEY_NOTICE_RAID_BUFFANY = "Visualizza tutti i benefici/penalità"
	XPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Visualizza solo benefici lanciabili/curabili o penalità"
	XPERL_KEY_NOTICE_RAID_BUFFS = "Benefici dell'incursione mostrati"
	XPERL_KEY_NOTICE_RAID_DEBUFFS = "Penalità dell'incursione mostrati"
	XPERL_KEY_NOTICE_RAID_NOBUFFS = "Nessun beneficio dell'incursione mostrato"

	XPERL_DRAGHINT1		= "|c00FFFFFFFai Click|r per riscalare la finestra"
	XPERL_DRAGHINT2		= "|c00FFFFFFFai Maiusc+Click|r per ridimensionare la finestra"

	-- Usage
	XPerlUsageNameList	= {XPerl = "Core", XPerl_Player = "Giocatore", XPerl_PlayerPet = "Famiglio", XPerl_Target = "Bersaglio", XPerl_TargetTarget = "Bersaglio del bersaglio", XPerl_Party = "Gruppo", XPerl_PartyPet = "Famigli del gruppo", XPerl_RaidFrames = "Finestre del raid", XPerl_RaidHelper = "Aiutante dell'incursione", XPerl_RaidAdmin = "Amministrazione incursione", XPerl_TeamSpeak = "TS Monitor", XPerl_RaidMonitor = "Monitor dell'incursione", XPerl_RaidPets = "Famigli dell'incursione", XPerl_ArcaneBar = "Barra arcana", XPerl_PlayerBuffs = "Benefici del giocatore", XPerl_GrimReaper = "Grim Reaper"}
	XPERL_USAGE_MEMMAX	= "IU Mem Max: %d"
	XPERL_USAGE_MODULES	= "Moduli: "
	XPERL_USAGE_NEWVERSION	= "*Una nuova versione"
	XPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r è disponibile per il download"

	XPERL_CMD_MENU		= "menu"
	XPERL_CMD_OPTIONS	= "opzioni"
	XPERL_CMD_LOCK		= "blocca"
	XPERL_CMD_UNLOCK	= "sblocca"
	XPERL_CMD_CONFIG	= "configurazioni"
	XPERL_CMD_LIST		= "elenca"
	XPERL_CMD_DELETE	= "elimina"
	XPERL_CMD_HELP		= "|c00FFFF80Utilizzo: |c00FFFFFF/xperl menu | blocca | sblocca | configurazioni elenca | configurazioni elimina <reame> <nome>"
	XPERL_CANNOT_DELETE_CURRENT = "Impossibile cancellare la tua configurazione corrente"
	XPERL_CONFIG_DELETED		= "Configurazione di %s/%s cancellata"
	XPERL_CANNOT_FIND_DELETE_TARGET = "Impossibile trovare configurazione da cancellare (%s/%s)"
	XPERL_CANNOT_DELETE_BADARGS = "Prego scrivi il del reame e quello del personaggio"
	XPERL_CONFIG_LIST		= "Elenco configurazioni:"
	XPERL_CONFIG_CURRENT		= " (In uso)"

	XPERL_RAID_TOOLTIP_WITHBUFF	= "Con buff: (%s)"
	XPERL_RAID_TOOLTIP_WITHOUTBUFF	= "Senza buff: (%s)"
	XPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s ha usato %s che finisce in %s"	-- Name, buff name, time to expire

	XPERL_NEW_VERSION_DETECTED = "Nuova versione rilevata:"
end
