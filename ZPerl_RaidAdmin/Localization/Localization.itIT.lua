-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "itIT" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = ZPerl.ShortProductName.." Amministrazione Raid"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "Blocca finestra"
L["BUTTON_ADMIN_LOCKOPEN"]  = "Blocca finestra aperta"
L["BUTTON_ADMIN_SAVE1"]     = "Salva formazione"
L["BUTTON_ADMIN_SAVE2"]     = "Salva la formazione corrente con il nome specificato. Se non viene dato nessun nome, verrà usata l'ora corrente come nome"
L["BUTTON_ADMIN_LOAD1"]     = "Carica formazione"
L["BUTTON_ADMIN_LOAD2"]     = "Carica la formazione selzionata. Se ci sono dei membri mancanti, verranno sostituiti con altri della stessa classe che non erano salvati nella formazione"
L["BUTTON_ADMIN_DELETE1"]   = "Elimina formazione"
L["BUTTON_ADMIN_DELETE2"]   = "Elimina la formazione selzionata"
L["BUTTON_ADMIN_STOPLOAD1"] = "Blocca caricamento"
L["BUTTON_ADMIN_STOPLOAD2"] = "Interrompe la procedura di caricamento della formazione"

L["LOAD"] = "Carica"

L["SAVED_ROSTER"]         = "Formazione salvata come '%s'"
L["ADMIN_DIFFERENCES"]    = "%d rispetto alla formazione corrente"
L["NO_ROSTER_NAME_GIVEN"] = "Nessun nome è stato assegnato per la formazione"
L["NO_ROSTER_CALLED"]     = "Nessuna formazione salvata chiamata '%s'"

-- Item Checker
L["CHECK_TITLE"] = ZPerl.ShortProductName.." Controllo Oggetti"

L["CHECK_NAME"] = "Nome"

L["CHECK_DROPITEMTIP1"]         = "Drag-Drop Oggetti"
L["CHECK_DROPITEMTIP2"]         = "Gli oggetti possono essere trascinati in questa finestra per aggiungerli alla lista degli oggetti da controllare.\rPuoi anche usare il comando /raitem."
L["CHECK_QUERY_DESC1"]          = "Controlla"
L["CHECK_QUERY_DESC2"]          = "Esegue il controllo (/raitem) su tutti gli oggetti selezionati\rLa ricerca fornisce diverse informazioni sugli oggetti"
L["CHECK_LAST_DESC1"]           = "Ultimi"
L["CHECK_LAST_DESC2"]           = "Seleziona gli oggetti che hai controllato l'ultima volta"
L["CHECK_ALL_DESC1"]            = "Tutto"
L["CHECK_ALL_DESC2"]            = "Seleziona tutti gli oggetti"
L["CHECK_NONE_DESC1"]           = "Nessuno"
L["CHECK_NONE_DESC2"]           = "Deseleziona tutti gli oggetti"
L["CHECK_DELETE_DESC1"]         = "Elimina"
L["CHECK_DELETE_DESC2"]         = "Rimuovi tutti gli oggetti seleziona dalla lista"
L["CHECK_REPORT_DESC1"]         = "Riporta"
L["CHECK_REPORT_DESC2"]         = "Visualizza i risultati nella chat del incursione"
L["CHECK_REPORT_WITH_DESC1"]    = "Con"
L["CHECK_REPORT_WITH_DESC2"]    = "Visualizza i giocatori con l'oggetto (o che non ce l'hanno equipaggiato) nella chat del incursione. Se è stato effettuato un controllo equipaggiamenti, questi risultati verranno visualizzati."
L["CHECK_REPORT_WITHOUT_DESC1"] = "Senza"
L["CHECK_REPORT_WITHOUT_DESC2"] = "Visualizza i giocatori senza l'oggetto (o che ce l'hanno equipaggiato) nella chat del incursione."
L["CHECK_SCAN_DESC1"]           = "Scansiona"
L["CHECK_SCAN_DESC2"]           = "Controllerà chiunque del raid abbastanza vicino per effettuare un'ispezione dell'equipaggiamento, per vedere se ha l'oggetto selezionato equipaggiato e questo verrà indicato nella lista dei giocatore. Avvicinati agli altri giocatori del incursione fino a quando non sono stati tutti controllati."
L["CHECK_SCANSTOP_DESC1"]       = "Interrompi scansione"
L["CHECK_SCANSTOP_DESC2"]       = "Interrompi la scansione dei giocatori per l'oggetto selezionato"
L["CHECK_REPORTPLAYER_DESC1"]   = "Segnala giocatore"
L["CHECK_REPORTPLAYER_DESC2"]   = "Segnala i dettagli del giocatore per questo oggetto o stato nella chat dell'incursione"

L["CHECK_BROKEN"]            = "Rotto"
L["CHECK_REPORT_DURABILITY"] = "Rottura dell'equipaggamento media dei membri: %d%% e %d persone con un totale di %d oggetti rotti"
L["CHECK_REPORT_RESISTS"]    = "Average Raid resists: %d Fuoco, %d Natura, %d Gelo, %d Ombra, %d Arcano"
L["CHECK_REPORT_PRESISTS"]   = "%s's Resists: %d Fuoco, %d Natura, %d Gelo, %d Ombra, %d Arcano"

L["REAGENTS"] = {
	PRIEST = "Sacred Candle",
	MAGE = "Arcane Powder",
	DRUID = "Wild Thornroot",
	SHAMAN = "Ankh",
	WARLOCK = "Soul Shard",
	PALADIN = "Symbol of Divinity",
	ROGUE = "Flash Powder"
}

L["CHECK_REPORT_PDURABILITY"]    = "Durabilità di %s: %d%% con %d oggetti rotti"
L["CHECK_REPORT_WITH"]           = " - con: "
L["CHECK_REPORT_WITHOUT"]        = " - senza: "
L["CHECK_REPORT_WITH_EQ"]        = " - con (o non equipaggiato): "
L["CHECK_REPORT_WITHOUT_EQ"]     = " - senza (o equipaggiato): "
L["CHECK_REPORT_EQUIPED"]        = " : equipaggiato: "
L["CHECK_REPORT_NOTEQUIPED"]     = " : NON equipaggiato: "
L["CHECK_REPORT_ALLEQUIPED"]     = "Tutti hanno %s equipaggiato"
L["CHECK_REPORT_ALLEQUIPEDOFF"]  = "Tutti hanno %s equipaggiato, ma %d membri sono offline"
L["CHECK_REPORT_PITEM"]          = "%s ha %d %s nell'inventario"
L["CHECK_REPORT_PEQUIPED"]       = "%s ha %s equipaggiato"
L["CHECK_REPORT_PNOTEQUIPED"]    = "%s NON ha %s equipaggiato"
L["CHECK_REPORT_DROPDOWN"]       = "Canale di uscita"
L["CHECK_REPORT_DROPDOWN_DESC"]  = "Seleziona il canale di uscita per i risultati del Controllo Oggetti"
L["CHECK_REPORT_WITHSHORT"]      = " : %d con"
L["CHECK_REPORT_WITHOUTSHORT"]   = " : %d senza"
L["CHECK_REPORT_EQUIPEDSHORT"]   = " : %d equipaggiati"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = " : %d NON equipaggiati"
L["CHECK_REPORT_OFFLINE"]        = " : %d offline"
L["CHECK_REPORT_TOTAL"]          = " : %d oggetti in totale"
L["CHECK_REPORT_NOTSCANNED"]     = " : %d non controllati"
L["CHECK_LASTINFO"]              = "Ultimi dati ricevuti %sfa"
L["CHECK_AVERAGE"]               = "Media"
L["CHECK_TOTALS"]                = "Totale"
L["CHECK_EQUIPED"]               = "Equipaggiato"
L["CHECK_SCAN_MISSING"]          = "Scansione dei giocatori ispezionabili per l'oggetto. (%d non scansionati)"
L["CHECK_REAGENTS"]              = "Reagenti"
L["ROSTERTEXT_TITLE"]            = ZPerl.ShortProductName.." Testo formazione"
L["ROSTERTEXT_GROUP"]            = "Gruppo %d"
L["ROSTERTEXT_GROUP_DESC"]       = "Usa i nomi del gruppo %d"
L["ROSTERTEXT_SAMEZONE"]         = "Solo stessa zona"
L["ROSTERTEXT_SAMEZONE_DESC"]    = "Includi solo i giocatori che si trovano nella tua stessa zona"
L["ROSTERTEXT_HELP"]             = "Premi Ctrl-C per copiare il testo negli appunti"
L["ROSTERTEXT_TOTAL"]            = "Totale: %d"
L["ROSTERTEXT_SETN"]             = "%d giocatori"
L["ROSTERTEXT_SETN_DESC"]        = "Seleziona automaticamente i gruppi per un'incursione da %d giocatori"
L["ROSTERTEXT_TOGGLE"]           = "Inverti"
L["ROSTERTEXT_TOGGLE_DESC"]      = "Inverti i gruppi selezionati"
L["ROSTERTEXT_SORT"]             = "Ordina"
L["ROSTERTEXT_SORT_DESC"]        = "Ordina per nome invece che per gruppo e nome"
