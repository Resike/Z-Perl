-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "frFR" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFFClic droit|r pour déplacer cette icône"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r pour l'utilisation mémoire de Z-Perl"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Maj|r pour l'utilisation mémoire de Z-Perl depuis le démarrage"

L["MINIMENU_ASSIST"]     = "Afficher le cadre d'assistance"
L["MINIMENU_CASTMON"]    = "Afficher le moniteur d'incantation"
L["MINIMENU_RAIDAD"]     = "Afficher l'admin du raid"
L["MINIMENU_ITEMCHK"]    = "Afficher le vérificateur d'objets"
L["MINIMENU_ROSTERTEXT"] = "Texte du roster"

L["TYPE_NOT_SPECIFIED"] = "Non spécifié"
L["TYPE_PET"]           = "Mascotte"
L["TYPE_ELITE"]         = "Élite"

-- Zones
L["LOC_ZONE_BARADIN_HOLD"]          = "Bastion de Baradin"
L["LOC_ZONE_BASTION_OF_TWILIGHT"]   = "Le bastion du Crépuscule"
L["LOC_ZONE_BLACK_TEMPLE"]          = "Temple noir"
L["LOC_ZONE_BLACKWING_DECENT"]      = "Descente de l’Aile noire"
L["LOC_ZONE_DRAGONSOUL"]            = "L’Âme des dragons"
L["LOC_ZONE_EYE_OF_ETERNITY"]       = "L’Œil de l’éternité"
L["LOC_ZONE_FIRELANDS"]             = "Terres de Feu"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "Sommet d’Hyjal"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "Citadelle de la Couronne de glace"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]      = "Le sanctum Obsidien"
L["LOC_ZONE_RUBY_SANCTUM"]          = "Le sanctum Rubis"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "Caverne du sanctuaire du Serpent"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "Plateau du Puits du soleil"
L["LOC_ZONE_THRONE_OF_FOUR_WINDS"]  = "Trône des quatre vents"
L["LOC_ZONE_TOMB_OF_SARGERAS"]      = "Tombe de Sargeras"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "L’épreuve du croisé"

-- Status
L["LOC_DEAD"]         = "Mort"
L["LOC_GHOST"]        = "Fantôme"
L["LOC_OFFLINE"]      = "Hors ligne"
L["LOC_RESURRECTED"]  = "Résurrecté"
L["LOC_SS_AVAILABLE"] = "Résurrection disponible"
L["LOC_UPDATING"]     = "Mise à jour"
L["LOC_ACCEPTEDRES"]  = "Résurrection acceptée"

L["LOC_NONEWATCHED"] = "Aucun observé"

L["LOC_STATUSTIP"]     = "Mises en évidence de statut : "
L["LOC_STATUSTIPLIST"] = {
	HOT = "Soins sur la durée",
	AGGRO = "Aggro",
	HEAL = "En train de guérir",
	SHIELD = "Protégé"
}

BINDING_NAME_ZPERL_TOGGLERAID         = "Basculer les fenêtres de raid"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "Basculer les mascottes du raid"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "Basculer la fenêtre des options"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "Basculer les buffs / débuffs / aucun"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Basculer les buffs / soins incantables"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "Basculer le détecteur de portée"

L["KEY_NOTICE_RAID_BUFFANY"]      = "Tous les buffs / débuffs sont affichés"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "Seulement les buffs ou débuffs incantables / curables sont affichés"
L["KEY_NOTICE_RAID_BUFFS"]        = "Buffs du raid affichés"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "Débuffs du raid affichés"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "Aucun buff de raid affiché"

L["DRAGHINT1"] = "|c00FFFFFFClic|r pour redimensionner la fenêtre"
L["DRAGHINT2"] = "|c00FFFFFFMaj+Clic|r pour redimensionner la fenêtre"

L["CMD_LOCK"]   = "verrouiller"
L["CMD_UNLOCK"] = "déverrouiller"

L["RAID_TOOLTIP_WITHBUFF"]    = "Avec buff : (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "Sans buff : (%s)"
