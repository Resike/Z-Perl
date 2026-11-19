-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "frFR" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = "Z-Perl Raid Admin"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "V\195\169rrou de fen\195\170tres"
L["BUTTON_ADMIN_LOCKOPEN"]  = "V`195`169rouille les fen\195\170tres ouvertes"
L["BUTTON_ADMIN_SAVE1"]     = "Sauvegarder le roster"
L["BUTTON_ADMIN_SAVE2"]     = "Sauve la disposition courante de r\195\180le avec le nom indiqu\195\169. Si aucun nom donn\195\169, le temps courant ne sera employ\195\169 comme nom"
L["BUTTON_ADMIN_LOAD1"]     = "Charger le roster"
L["BUTTON_ADMIN_LOAD2"]     = "Charger le r\195\180le choisi. En pillent les membres du r\195\180le sauv\195\169 qui sont plus dans l'incursion ne seront remplac\195\169s par les membres de la m\195\170me classe qui ne sont pas sauv\195\169s dans le r\195\180le"
L["BUTTON_ADMIN_DELETE1"]   = "Effacement du roster"
L["BUTTON_ADMIN_DELETE2"]   = "Efface le roster s\195\169l\195\169ctionn\195\169"
L["BUTTON_ADMIN_STOPLOAD1"] = "Arr\195\170te le chargement"
L["BUTTON_ADMIN_STOPLOAD2"] = "Interrompre le chargement du roster"

L["LOAD"] = "Lancer"

L["SAVED_ROSTER"]         = "Roster sauvegard\195\169 est appell\195\169 '%s'"
L["ADMIN_DIFFERENCES"]    = "%d differences avec le roster en cours"
L["NO_ROSTER_NAME_GIVEN"] = "Pas de nom de roster donn\195\169"
L["NO_ROSTER_CALLED"]     = "Pas de roster sauvegard\195\169 appell\195\169 '%s'"

-- Item Checker
L["CHECK_TITLE"] = "Z-Perl V\195\169rificateur d'articles"

L["CHECK_NAME"] = "Noms"

L["CHECK_DROPITEMTIP1"]         = "Articles rammass\195\169s"
L["CHECK_DROPITEMTIP2"]         = "Des articles peuvent \195\170tre l\195\162chés dans ce cadre et \195\170tre ajout\195\169s \195\160 la liste d'articles questionnable. Vous pouvez \195\169galement employer la commande de /raitem comme normale et des articles \195\169galement seront ajout\195\169s ici et \195\160 l'avenir employ\195\169s."
L["CHECK_QUERY_DESC1"]          = "Qestion"
L["CHECK_QUERY_DESC2"]          = "Ex\195\169cute le contr81958180le d'article (/raitem) sur tous les articles La question obtient toujours le durablity, la résistance et l'information courants de réactifs"
L["CHECK_LAST_DESC1"]           = "derni\195\168res"
L["CHECK_LAST_DESC2"]           = "Re-tick la derni\195\168res recherche d'articles"
L["CHECK_ALL_DESC1"]            = "Tous"
L["CHECK_ALL_DESC2"]            = "Tick tout les articles"
L["CHECK_NONE_DESC1"]           = "Aucun"
L["CHECK_NONE_DESC2"]           = "Un-tick tous les articles"
L["CHECK_DELETE_DESC1"]         = "Suppr."
L["CHECK_DELETE_DESC2"]         = "Efface tous les ticks d'articles de la liste"
L["CHECK_REPORT_DESC1"]         = "Rapport"
L["CHECK_REPORT_DESC2"]         = "Montre les rapports des r\195\169sutats s\195\169l\195\169ctionn\195\169 dans le chat de raid"
L["CHECK_REPORT_WITH_DESC1"]    = "avec"
L["CHECK_REPORT_WITH_DESC2"]    = "Rapporter les personnes avec l'article (ou qui ne l'on pas \195\169quip\195\169) dans le chat de raid"
L["CHECK_REPORT_WITHOUT_DESC1"] = "Sans"
L["CHECK_REPORT_WITHOUT_DESC2"] = "Rapporter les personnes sans  l'article (ou avoir l'article \195\169quip\195\169) dans le chat de raid "
L["CHECK_SCAN_DESC2"]           = ""
L["CHECK_SCANSTOP_DESC1"]       = "Arretez le scan"
L["CHECK_SCANSTOP_DESC2"]       = ""
L["CHECK_REPORTPLAYER_DESC1"]   = "Rapportez au joueur"
L["CHECK_REPORTPLAYER_DESC2"]   = ""

L["CHECK_BROKEN"]               = "Durabilit\195\169"
L["CHECK_REPORT_DURABILITY"]    = " Moyenne de la durabilit\195\169 du raid %d%% et %d les personnes avec un total de %d d'articles cass\195\169s"
L["CHECK_REPORT_PDURABILITY"]   = "%s durabilit\195\169: %d%% avec %d d'articles cass\195\169s"
L["CHECK_REPORT_RESISTS"]       = "Moyenne de r\195\169sistance du raid %d Feu, %d Nature, %d Givre, %d Ombre, %d Arcanes"
L["CHECK_REPORT_PRESISTS"]      = "%s R\195\169sistances %d Feu, %d Nature, %d Givre, %d Ombre, %d Arcanes"
L["CHECK_REPORT_WITH"]          = " - avec : "
L["CHECK_REPORT_WITHOUT"]       = " - sans : "
L["CHECK_REPORT_WITH_EQ"]       = " - avec (ou pas \195\169qui\195\169): "
L["CHECK_REPORT_WITHOUT_EQ"]    = " - sans (ou \195\169quip\195\169): "
L["CHECK_REPORT_EQUIPED"]       = " : equp\195\169: "
L["CHECK_REPORT_NOTEQUIPED"]    = " : non-\195\169quip\195\169: "
L["CHECK_REPORT_ALLEQUIPED"]    = "Chacun a \195\169t\195\169 %s \195\169quip\195\169"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "Chacun a \195\169t\195\169 %s \195\169quip\195\169, mais %d sont hors-ligne"
L["CHECK_REPORT_PITEM"]         = "%s \195\160 \195\169t\195\169 %d %s dans les inventaires"
L["CHECK_REPORT_PEQUIPED"]      = "%s \195\160 \195\169t\195\169 %s \195\169quip\195\169"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s n'as pas \195\169t\195\169 %s \195\169quip\195\169"
L["CHECK_REPORT_DROPDOWN"]      = "Canaux de sorties"
L["CHECK_REPORT_DROPDOWN_DESC"] = "S\195\169l\195\169ctionne le canal de sortie pour le r\195\169sultat du controle d'articles"

L["CHECK_REPORT_WITHSHORT"]       = " : %d avec"
L["CHECK_REPORT_WITHOUTSHORT"]    = " : %d sans"
L["CHECK_REPORT_EQUIPEDSHORT"]    = " : %d equip\195\169"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = " : %d non-\195\169quip\195\169"
L["CHECK_REPORT_OFFLINE"]         = " : %d hors-ligne"
L["CHECK_REPORT_TOTAL"]           = " : %d Total d'articles"
L["CHECK_REPORT_NOTSCANNED"]      = " : %d non-recherch\195\169"

L["CHECK_AVERAGE"] = "Moyenne"
L["CHECK_EQUIPED"] = "Equip\195\169"

L["CHECK_SCAN_MISSING"] = "Scan d'inspection des joueurs pour l'article (%d non-trouv\195\169)"

L["REAGENTS"] = {
	PRIEST = "Bougie sacr\195\169e",
	MAGE = "Poudre des arcanes",
	DRUID = "Ronceterre sauvage",
	SHAMAN = "Croix",
	WARLOCK = "Fragment d'\195\162me",
	PALADIN = "Symbole de divinit\195\169",
	ROGUE = "Poudre \195\169clipsante"
}

L["CHECK_REAGENTS"] = "R\195\169actifs"

-- Roster Text
L["ROSTERTEXT_GROUP"] = "Groupe %d"
