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
