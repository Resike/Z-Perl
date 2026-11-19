-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "itIT" then return end

local L = ZPerl.L

L["TOOLTIP_ASSISTING"] = "Giocatori che ti assistono:"
L["TOOLTIP_HEALERS"]   = "Curatori che ti bersagliano:"
L["TOOLTIP_ALLONME"]   = "Chi ti bersaglia:"
L["TOOLTIP_ENEMYONME"] = "Nemici che ti bersagliano:"
L["TOOLTIP_HELP"]      = "Fai click per aprire la vista in tempo reale"
L["TOOLTIP_PET"]       = "Pet di %s"

L["BUTTON_TOGGLE_LABELS"]    = "Abilita scritte bersagli"
L["BUTTON_TOGGLE_MTTARGETS"] = "Abilita la visualizzazione dei bersagli dei bersagli dei tank"
L["BUTTON_TOGGLE_SHOWMT"]    = "Abilita la visualizzazione del Guardiano PrincipaleToggle showing of the Main Tank"
L["BUTTON_HELPER_PIN"]       = "Blocca Finestra"

L["XS_TARGET"] = "Bersaglio di %s"
L["NO_TARGET"] = "Nessun Bersaglio"

L["TITLE_MT_LONG"]       = "Bersagli Guardiani Principali"
L["TITLE_MT_SHORT"]      = "GP"
L["TITLE_WARRIOR_LONG"]  = "Bersagli Guerrieri"
L["TITLE_WARRIOR_SHORT"] = "Guardiani"

L["HELPER_NEEDPROMOTE"] = "Devi essere promosso per impostare l'assist principale"
L["HELPER_MASET"]       = "Assist Principale impostato a %s"
L["HELPER_MACLEAR"]     = "Assist Principale |c00FF0000eliminato!"
L["HELPER_MAREMOVED"]   = "L'assist principale %s non è stato trovato nella lista dei guardiani - rimosso!"
L["HELPER_MAREMOTESET"] = "%s ha assegnato l'Assist Principale a %s"

L["HELPER_FINDFOUND"]   = "Trovato un bersaglio adatto con FIND. ('|c00007F00/zphelper find|r' per eliminare)."
L["HELPER_FINDCLEARED"] = "FIND |c00FF0000eliminato!|r"
L["HELPER_FINDSET"]     = "FIND impostato a %s. ('|c00007F00/zphelper find|r' per eliminare)."

L["AGGRO_PLAYER"]  = "- MINACCIA -"
L["AGGRO_PET"]     = "- FAMIGLIO MINACCIA -"
L["AGGRO_DRAGTIP"] = "Muovi la posizione dell'allerta della minaccia"
