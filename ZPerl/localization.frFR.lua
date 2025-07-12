-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if GetLocale() == "frFR" then
	XPerl_Description		= XPerl_ProductName.." par "..XPerl_Author
	XPerl_LongDescription		= "Remplacement pour les cadres d'unités, avec une nouvelle apparence pour le joueur, mascotte, groupe, cible, cible de la cible, focus, raid"

	XPERL_MINIMAP_HELP1		= "|c00FFFFFFClic gauche|r pour les options (et pour |c0000FF00déverrouiller les cadres|r)"
	XPERL_MINIMAP_HELP2		= "|c00FFFFFFClic droit|r pour déplacer cette icône"
	XPERL_MINIMAP_HELP3		= "\rMembres du raid : |c00FFFF80%d|r\rMembres du groupe : |c00FFFF80%d|r"
	XPERL_MINIMAP_HELP4		= "\rVous êtes le leader du groupe / raid"
	XPERL_MINIMAP_HELP5		= "|c00FFFFFFAlt|r pour l'utilisation mémoire de Z-Perl"
	XPERL_MINIMAP_HELP6		= "|c00FFFFFF+Maj|r pour l'utilisation mémoire de Z-Perl depuis le démarrage"

	XPERL_MINIMENU_OPTIONS	= "Options"
	XPERL_MINIMENU_ASSIST	= "Afficher le cadre d'assistance"
	XPERL_MINIMENU_CASTMON	= "Afficher le moniteur d'incantation"
	XPERL_MINIMENU_RAIDAD	= "Afficher l'admin du raid"
	XPERL_MINIMENU_ITEMCHK	= "Afficher le vérificateur d'objets"
	XPERL_MINIMENU_RAIDBUFF	= "Buffs du raid"
	XPERL_MINIMENU_ROSTERTEXT="Texte du roster"
	XPERL_MINIMENU_RAIDSORT	= "Tri du raid"
	XPERL_MINIMENU_RAIDSORT_GROUP = "Trier par groupe"
	XPERL_MINIMENU_RAIDSORT_CLASS = "Trier par glasse"

	XPERL_TYPE_NOT_SPECIFIED	= "Non spécifié"
	XPERL_TYPE_PET			= "Mascotte"
	XPERL_TYPE_BOSS			= "Boss"
	XPERL_TYPE_RAREPLUS 		= "Rare+"
	XPERL_TYPE_ELITE		= "Élite"
	XPERL_TYPE_RARE			= "Rare"

	-- Zones
	XPERL_LOC_ZONE_ANTORUS			= "Antorus"
	XPERL_LOC_ZONE_BARADIN_HOLD 		= "Bastion de Baradin"
	XPERL_LOC_ZONE_BASTION_OF_TWILIGHT	= "Le bastion du Crépuscule"
	XPERL_LOC_ZONE_BLACK_TEMPLE		= "Temple noir"
	XPERL_LOC_ZONE_BLACKWING_DECENT		= "Descente de l’Aile noire"
	XPERL_LOC_ZONE_DRAGONSOUL		= "L’Âme des dragons"
	XPERL_LOC_ZONE_EMERALD_NIGHTMARE	= "Le Cauchemar d’émeraude"
	XPERL_LOC_ZONE_EYE_OF_ETERNITY		= "L’Œil de l’éternité"
	XPERL_LOC_ZONE_FIRELANDS		= "Terres de Feu"
	XPERL_LOC_ZONE_HYJAL_SUMMIT		= "Sommet d’Hyjal"
	XPERL_LOC_ZONE_ICECROWN_CITADEL		= "Citadelle de la Couronne de glace"
	XPERL_LOC_ZONE_KARAZHAN			= "Karazhan"
	XPERL_LOC_ZONE_NAXXRAMAS		= "Naxxramas"
	XPERL_LOC_ZONE_NIGHTHOLD		= "Palais Sacrenuit"
	XPERL_LOC_ZONE_OBSIDIAN_SANCTUM		= "Le sanctum Obsidien"
	XPERL_LOC_ZONE_RUBY_SANCTUM		= "Le sanctum Rubis"
	XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN	= "Caverne du sanctuaire du Serpent"
	XPERL_LOC_ZONE_SUNWELL_PLATEAU		= "Plateau du Puits du soleil"
	XPERL_LOC_ZONE_THRONE_OF_FOUR_WINDS 	= "Trône des quatre vents"
	XPERL_LOC_ZONE_TOMB_OF_SARGERAS		= "Tombe de Sargeras"
	XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER	= "L’épreuve du croisé"
	XPERL_LOC_ZONE_TRIAL_OF_VALOR		= "Le Jugement des Valeureux"
	XPERL_LOC_ZONE_ULDUAR			= "Ulduar"
	-- Any zones 4.x and higher can all be localized from EJ, in 5.0, even these above zones are in EJ which means the rest can go bye bye too

	-- Status
	XPERL_LOC_DEAD		= DEAD		-- "Dead"
	XPERL_LOC_GHOST 	= "Fantôme"
	XPERL_LOC_FEIGNDEATH	= "Feindre la mort"
	XPERL_LOC_FEIGNDEATHSHORT	= "FM"
	XPERL_LOC_OFFLINE	= PLAYER_OFFLINE	-- "Offline"
	XPERL_LOC_RESURRECTED	= "Résurrecté"
	XPERL_LOC_SS_AVAILABLE	= "Résurrection disponible"
	XPERL_LOC_UPDATING	= "Mise à jour"
	XPERL_LOC_ACCEPTEDRES	= "Résurrection acceptée"		-- Res accepted
	XPERL_RAID_GROUP	= "Groupe %d"
	XPERL_RAID_GROUPSHORT	= "G%d"

	XPERL_LOC_NONEWATCHED	= "Aucun observé"

	XPERL_LOC_STATUSTIP = "Mises en évidence de statut : " 	-- Tooltip explanation of status highlight on unit
	XPERL_LOC_STATUSTIPLIST = {
		HOT = "Soins sur la durée",
		AGGRO = "Aggro",
		MISSING = "Buff manquant de votre classe",
		HEAL = "En train de guérir",
		SHIELD = "Protégé"
	}

	XPERL_OK		= "OK"
	XPERL_CANCEL	= "Annuler"

	XPERL_LOC_LARGENUMTAG		= "K"
	XPERL_LOC_HUGENUMTAG		= "M"
	XPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_ZPERL = XPerl_ProductName
	BINDING_NAME_ZPERL_TOGGLERAID = "Basculer les fenêtres de raid"
	BINDING_NAME_ZPERL_TOGGLERAIDSORT = "Basculer le tri du raid par classe / groupe"
	BINDING_NAME_ZPERL_TOGGLERAIDPETS = "Basculer les mascottes du raid"
	BINDING_NAME_ZPERL_TOGGLEOPTIONS = "Basculer la fenêtre des options"
	BINDING_NAME_ZPERL_TOGGLEBUFFTYPE = "Basculer les buffs / débuffs / aucun"
	BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Basculer les buffs / soins incantables"
	BINDING_NAME_ZPERL_TEAMSPEAKMONITOR = "Moniteur de Teamspeak"
	BINDING_NAME_ZPERL_TOGGLERANGEFINDER = "Basculer le détecteur de portée"

	XPERL_KEY_NOTICE_RAID_BUFFANY = "Tous les buffs / débuffs sont affichés"
	XPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Seulement les buffs ou débuffs incantables / curables sont affichés"
	XPERL_KEY_NOTICE_RAID_BUFFS = "Buffs du raid affichés"
	XPERL_KEY_NOTICE_RAID_DEBUFFS = "Débuffs du raid affichés"
	XPERL_KEY_NOTICE_RAID_NOBUFFS = "Aucun buff de raid affiché"

	XPERL_DRAGHINT1		= "|c00FFFFFFClic|r pour redimensionner la fenêtre"
	XPERL_DRAGHINT2		= "|c00FFFFFFMaj+Clic|r pour redimensionner la fenêtre"

	-- Usage
	XPerlUsageNameList	= {XPerl = "Core", XPerl_Player = "Joueur", XPerl_PlayerPet = "Mascotte", XPerl_Target = "Cible", XPerl_TargetTarget = "Cible de la Cible", XPerl_Party = "Groupe", XPerl_PartyPet = "Mascottes du Groupe", XPerl_RaidFrames = "Cadres de Raid", XPerl_RaidHelper = "Aide de Raid", XPerl_RaidAdmin = "Admin du Raid", XPerl_TeamSpeak = "Moniteur TS", XPerl_RaidMonitor = "Moniteur de Raid", XPerl_RaidPets = "Mascottes du Raid", XPerl_ArcaneBar = "Barre Arcane", XPerl_PlayerBuffs = "Buffs du Joueur", XPerl_GrimReaper = "Grim Reaper"}
	XPERL_USAGE_MEMMAX	= "Mémoire de la IU max. : %d"
	XPERL_USAGE_MODULES	= "Modules : "
	XPERL_USAGE_NEWVERSION	= "*Nouvelle version"
	XPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r est disponible pour téléchargement"

	XPERL_CMD_MENU		= "menu"
	XPERL_CMD_OPTIONS	= "options"
	XPERL_CMD_LOCK		= "verrouiller"
	XPERL_CMD_UNLOCK	= "déverrouiller"
	XPERL_CMD_CONFIG	= "config"
	XPERL_CMD_LIST		= "liste"
	XPERL_CMD_DELETE	= "supprimer"
	XPERL_CMD_HELP		= "|c00FFFF80Utilisation: |c00FFFFFF/zperl menu | verrouiller | déverrouiller | config liste | config supprimer <royaume> <nom>"
	XPERL_CANNOT_DELETE_CURRENT = "Impossible de supprimer la configuration actuelle"
	XPERL_CONFIG_DELETED		= "Configuration supprimée pour %s/%s"
	XPERL_CANNOT_FIND_DELETE_TARGET = "Impossible de trouver la configuration à supprimer (%s/%s)"
	XPERL_CANNOT_DELETE_BADARGS = "Merci de fournir le nom du royaume et du joueur"
	XPERL_CONFIG_LIST		= "Liste de configurations :"
	XPERL_CONFIG_CURRENT		= " (Actuel)"

	XPERL_RAID_TOOLTIP_WITHBUFF	= "Avec buff : (%s)"
	XPERL_RAID_TOOLTIP_WITHOUTBUFF	= "Sans buff : (%s)"
	XPERL_RAID_TOOLTIP_BUFFEXPIRING	= "Le buff de %s, %s expire dans %s"	-- Nom, nom du buff, temps avant expiration

	XPERL_NEW_VERSION_DETECTED = "Nouvelle version détectée : "
	XPERL_DOWNLOAD_LATEST = "Vous pouvez télécharger la dernière version ici : "
	XPERL_DOWNLOAD_LOCATION = "https://mods.curse.com/addons/wow/zperl"
end
