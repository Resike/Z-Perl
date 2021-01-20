if (GetLocale() == "itIT") then
XPERL_ADMIN_TITLE	= XPerl_ShortProductName.." Amministrazione Raid"

XPERL_MSG_PREFIX	= "|c00C05050X-Perl|r "

-- Raid Admin
XPERL_BUTTON_ADMIN_PIN		= "Blocca finestra"
XPERL_BUTTON_ADMIN_LOCKOPEN	= "Blocca finestra aperta"
XPERL_BUTTON_ADMIN_SAVE1	= "Salva formazione"
XPERL_BUTTON_ADMIN_SAVE2	= "Salva la formazione corrente con il nome specificato. Se non viene dato nessun nome, verrà usata l'ora corrente come nome"
XPERL_BUTTON_ADMIN_LOAD1	= "Carica formazione"
XPERL_BUTTON_ADMIN_LOAD2	= "Carica la formazione selzionata. Se ci sono dei membri mancanti, verranno sostituiti con altri della stessa classe che non erano salvati nella formazione"
XPERL_BUTTON_ADMIN_DELETE1	= "Elimina formazione"
XPERL_BUTTON_ADMIN_DELETE2	= "Elimina la formazione selzionata"
XPERL_BUTTON_ADMIN_STOPLOAD1	= "Blocca caricamento"
XPERL_BUTTON_ADMIN_STOPLOAD2	= "Interrompe la procedura di caricamento della formazione"

XPERL_LOAD			= "Carica"

XPERL_SAVED_ROSTER		= "Formazione salvata come '%s'"
XPERL_ADMIN_DIFFERENCES		= "%d rispetto alla formazione corrente"
XPERL_NO_ROSTER_NAME_GIVEN	= "Nessun nome è stato assegnato per la formazione"
XPERL_NO_ROSTER_CALLED		= "Nessuna formazione salvata chiamata '%s'"

-- Item Checker
XPERL_CHECK_TITLE		= XPerl_ShortProductName.." Controllo Oggetti"

XPERL_CHECK_NAME		= "Nome"

XPERL_CHECK_DROPITEMTIP1	= "Drag-Drop Oggetti"
XPERL_CHECK_DROPITEMTIP2	= "Gli oggetti possono essere trascinati in questa finestra per aggiungerli alla lista degli oggetti da controllare.\rPuoi anche usare il comando /raitem."
XPERL_CHECK_QUERY_DESC1		= "Controlla"
XPERL_CHECK_QUERY_DESC2		= "Esegue il controllo (/raitem) su tutti gli oggetti selezionati\rLa ricerca fornisce diverse informazioni sugli oggetti"
XPERL_CHECK_LAST_DESC1		= "Ultimi"
XPERL_CHECK_LAST_DESC2		= "Seleziona gli oggetti che hai controllato l'ultima volta"
XPERL_CHECK_ALL_DESC1		= ALL
XPERL_CHECK_ALL_DESC2		= "Seleziona tutti gli oggetti"
XPERL_CHECK_NONE_DESC1		= NONE
XPERL_CHECK_NONE_DESC2		= "Deseleziona tutti gli oggetti"
XPERL_CHECK_DELETE_DESC1	= DELETE
XPERL_CHECK_DELETE_DESC2	= "Rimuovi tutti gli oggetti seleziona dalla lista"
XPERL_CHECK_REPORT_DESC1	= "Riporta"
XPERL_CHECK_REPORT_DESC2	= "Visualizza i risultati nella chat del incursione"
XPERL_CHECK_REPORT_WITH_DESC1	= "Con"
XPERL_CHECK_REPORT_WITH_DESC2	= "Visualizza i giocatori con l'oggetto (o che non ce l'hanno equipaggiato) nella chat del incursione. Se è stato effettuato un controllo equipaggiamenti, questi risultati verranno visualizzati."
XPERL_CHECK_REPORT_WITHOUT_DESC1= "Senza"
XPERL_CHECK_REPORT_WITHOUT_DESC2= "Visualizza i giocatori senza l'oggetto (o che ce l'hanno equipaggiato) nella chat del incursione."
XPERL_CHECK_SCAN_DESC1		= "Scansiona"
XPERL_CHECK_SCAN_DESC2		= "Controllerà chiunque del raid abbastanza vicino per effettuare un'ispezione dell'equipaggiamento, per vedere se ha l'oggetto selezionato equipaggiato e questo verrà indicato nella lista dei giocatore. Avvicinati agli altri giocatori del incursione fino a quando non sono stati tutti controllati."
XPERL_CHECK_SCANSTOP_DESC1	= "Interrompi scansione"
XPERL_CHECK_SCANSTOP_DESC2	= "Interrompi la scansione dei giocatori per l'oggetto selezionato"
XPERL_CHECK_REPORTPLAYER_DESC1	= "Segnala giocatore"
XPERL_CHECK_REPORTPLAYER_DESC2	= "Segnala i dettagli del giocatore per questo oggetto o stato nella chat dell'incursione"

XPERL_CHECK_BROKEN		= "Rotto"
XPERL_CHECK_REPORT_DURABILITY	= "Rottura dell'equipaggamento media dei membri: %d%% e %d persone con un totale di %d oggetti rotti"
XPERL_CHECK_REPORT_PDURABILITY	= "%s's Durability: %d%% with %d broken items"
XPERL_CHECK_REPORT_RESISTS	= "Average Raid resists: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
XPERL_CHECK_REPORT_PRESISTS	= "%s's Resists: %d "..SPELL_SCHOOL2_CAP..", %d "..SPELL_SCHOOL3_CAP..", %d "..SPELL_SCHOOL4_CAP..", %d "..SPELL_SCHOOL5_CAP..", %d "..SPELL_SCHOOL6_CAP
XPERL_CHECK_REPORT_WITH		= " - with: "
XPERL_CHECK_REPORT_WITHOUT	= " - without: "
XPERL_CHECK_REPORT_WITH_EQ	= " - with (or not equipped): "
XPERL_CHECK_REPORT_WITHOUT_EQ	= " - without (or equipped): "
XPERL_CHECK_REPORT_EQUIPED	= " : equipped: "
XPERL_CHECK_REPORT_NOTEQUIPED	= " : NOT equipped: "
XPERL_CHECK_REPORT_ALLEQUIPED	= "Everyone has %s equipped"
XPERL_CHECK_REPORT_ALLEQUIPEDOFF= "Everyone has %s equipped, but %d member(s) offline"
XPERL_CHECK_REPORT_PITEM	= "%s has %d %s in inventory"
XPERL_CHECK_REPORT_PEQUIPED	= "%s has %s equipped"
XPERL_CHECK_REPORT_PNOTEQUIPED	= "%s DOES NOT have %s equipped"
XPERL_CHECK_REPORT_DROPDOWN	= "Output Channel"
XPERL_CHECK_REPORT_DROPDOWN_DESC= "Select output channel for Item Checker results"

XPERL_CHECK_REPORT_WITHSHORT	= " : %d with"
XPERL_CHECK_REPORT_WITHOUTSHORT	= " : %d without"
XPERL_CHECK_REPORT_EQUIPEDSHORT	= " : %d equipped"
XPERL_CHECK_REPORT_NOTEQUIPEDSHORT	= " : %d NOT equipped"
XPERL_CHECK_REPORT_OFFLINE	= " : %d offline"
XPERL_CHECK_REPORT_TOTAL	= " : %d Total Items"
XPERL_CHECK_REPORT_NOTSCANNED	= " : %d un-checked"

XPERL_CHECK_LASTINFO		= "Last data received %sago"

XPERL_CHECK_AVERAGE		= "Average"
XPERL_CHECK_TOTALS		= "Total"
XPERL_CHECK_EQUIPED		= "Equipped"

XPERL_CHECK_SCAN_MISSING	= "Scanning inspectable players for item. (%d un-scanned)"

XPERL_REAGENTS			= {PRIEST = "Sacred Candle", MAGE = "Arcane Powder", DRUID = "Wild Thornroot",
					SHAMAN = "Ankh", WARLOCK = "Soul Shard", PALADIN = "Symbol of Divinity",
					ROGUE = "Flash Powder"}

XPERL_CHECK_REAGENTS		= "Reagents"

-- Roster Text
XPERL_ROSTERTEXT_TITLE		= XPerl_ShortProductName.." Roster Text"
XPERL_ROSTERTEXT_GROUP		= "Group %d"
XPERL_ROSTERTEXT_GROUP_DESC	= "Use names from group %d"
XPERL_ROSTERTEXT_SAMEZONE	= "Same Zone Only"
XPERL_ROSTERTEXT_SAMEZONE_DESC	= "Only include names of players in the same zone as yourself"
XPERL_ROSTERTEXT_HELP		= "Press Ctrl-C to copy the text to the clipboard"
XPERL_ROSTERTEXT_TOTAL		= "Total: %d"
XPERL_ROSTERTEXT_SETN		= "%d Man"
XPERL_ROSTERTEXT_SETN_DESC	= "Auto select the groups for a %d man raid"
XPERL_ROSTERTEXT_TOGGLE		= "Toggle"
XPERL_ROSTERTEXT_TOGGLE_DESC	= "Toggle the selected groups"
XPERL_ROSTERTEXT_SORT		= "Sort"
XPERL_ROSTERTEXT_SORT_DESC	= "Sort by name instead of by group+name"
end
