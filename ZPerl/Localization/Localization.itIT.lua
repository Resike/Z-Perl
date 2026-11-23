-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "itIT" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFFClick Destro|r per spostare questa icona"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r per info sull'uso di memoria di Z-Perl"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Maiusc|r per l'uso di memoria di Z-Perl dall'avvio"

L["MINIMENU_OPTIONS"] = "Opzioni"
L["MINIMENU_ASSIST"]  = "Visualizza finestra assist"
L["MINIMENU_CASTMON"] = "Visualizza monitor dei lanci delle magie"
L["MINIMENU_RAIDAD"]  = "Visualizza Amministratore Incursione"
L["MINIMENU_ITEMCHK"] = "Visualizza Controllo Oggetti"

L["TYPE_NOT_SPECIFIED"] = "Non specificato"
L["TYPE_PET"]           = "Famiglio"
L["TYPE_RAREPLUS"]      = "Raro+"
L["TYPE_RARE"]          = "Raro"

-- Zones
L["LOC_ZONE_BLACK_TEMPLE"]     = "Tempio Nero"
L["LOC_ZONE_ICECROWN_CITADEL"] = "Corona di Ghiaccio"

-- Status
L["LOC_DEAD"]         = "Morto"
L["LOC_GHOST"]        = "Spirito"
L["LOC_OFFLINE"]      = "Offline"
L["LOC_RESURRECTED"]  = "Riportato in vita"
L["LOC_SS_AVAILABLE"] = "SS Disponibile"
L["LOC_UPDATING"]     = "In aggiornamento"
L["LOC_ACCEPTEDRES"]  = "Accettata"

L["LOC_STATUSTIP"]     = "Evidenziaziazione stato: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "Cure nel Tempo (HOT)",
	AGGRO = "Aggressione",
	HEAL = "Sta per essere curato",
	SHIELD = "Shielded"
}

BINDING_NAME_ZPERL_TOGGLERAID         = "Abilita/Disattiva Raid Windows"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "Abilita/Disattiva Raid Pets"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "Abilita/Disattiva finestra opzioni"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "Abilita/Disattiva Buffs/Debuffs/none"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Abilita/Disattiva Castable/Curable"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "Abilita/Disattiva Range Finder"

L["KEY_NOTICE_RAID_BUFFANY"]      = "Visualizza tutti i benefici/penalità"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "Visualizza solo benefici lanciabili/curabili o penalità"
L["KEY_NOTICE_RAID_BUFFS"]        = "Benefici dell'incursione mostrati"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "Penalità dell'incursione mostrati"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "Nessun beneficio dell'incursione mostrato"

L["DRAGHINT1"] = "|c00FFFFFFFai Click|r per riscalare la finestra"
L["DRAGHINT2"] = "|c00FFFFFFFai Maiusc+Click|r per ridimensionare la finestra"

L["CMD_OPTIONS"] = "opzioni"
L["CMD_LOCK"]    = "blocca"
L["CMD_UNLOCK"]  = "sblocca"

L["RAID_TOOLTIP_WITHBUFF"]    = "Con buff: (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "Senza buff: (%s)"

L["MINIMAP_HELP1"]                    = "|c00FFFFFFClic sinistro|r per le opzioni"
L["MINIMENU_ROSTERTEXT"]              = "Testo formazione"
L["TYPE_BOSS"]                        = "Boss"
L["TYPE_ELITE"]                       = "Élite"
L["LOC_ZONE_ANTORUS"]                 = "Antorus, il Trono Ardente"
L["LOC_ZONE_BARADIN_HOLD"]            = "Forte di Baradin"
L["LOC_ZONE_BASTION_OF_TWILIGHT"]     = "Bastione del Crepuscolo"
L["LOC_ZONE_BLACKWING_DECENT"]        = "Discesa dell'Alanera"
L["LOC_ZONE_DRAGONSOUL"]              = "Anima dei Draghi"
L["LOC_ZONE_EYE_OF_ETERNITY"]         = "Occhio dell'Eternità"
L["LOC_ZONE_FIRELANDS"]               = "Terre del Fuoco"
L["LOC_ZONE_HYJAL_SUMMIT"]            = "Vetta di Hyjal"
L["LOC_ZONE_KARAZHAN"]                = "Karazhan"
L["LOC_ZONE_NAXXRAMAS"]               = "Naxxramas"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]        = "Santuario di Ossidiana"
L["LOC_ZONE_RUBY_SANCTUM"]            = "Santuario di Rubino"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]    = "Caverna di Sacrespire"
L["LOC_ZONE_SUNWELL_PLATEAU"]         = "Altopiano del Pozzo Solare"
L["LOC_ZONE_THRONE_OF_FOUR_WINDS"]    = "Trono dei Quattro Venti"
L["LOC_ZONE_TOMB_OF_SARGERAS"]        = "Tomba di Sargeras"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"]   = "Prova del Crociato"
L["LOC_ZONE_ULDUAR"]                  = "Ulduar"
L["RAID_GROUPSHORT"]                  = "G%d"
L["LOC_NONEWATCHED"]                  = "nessuno osservato"
L["KEY_NOTICE_RAID_BUFFS_AND_DEBUFFS"] = "Benefici e penalità dell'incursione mostrati"
L["CMD_HELP"]                         = "|c00FFFF80Uso: |c00FFFFFF/zperl menu | blocca | sblocca | layout [nome]"
L["LAYOUT_LIST"]                      = "Layout:"
L["LAYOUT_CURRENT"]                   = " (Attuale)"
L["LAYOUT_UNKNOWN"]                   = "Nessun layout chiamato %s"
