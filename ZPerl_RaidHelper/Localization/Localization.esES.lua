-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = ZPerl.L

L["TOOLTIP_ASSISTING"] = "Jugadores asistiendo:"
L["TOOLTIP_HEALERS"]   = "Curanderos que me señalan:"
L["TOOLTIP_ALLONME"]   = "Todos los que me señalan:"
L["TOOLTIP_ENEMYONME"] = "Enemigos señalandome:"
L["TOOLTIP_HELP"]      = "Pulsar para ver la vista en tiempo real"
L["TOOLTIP_PET"]       = "Mascota de %s"

L["BUTTON_TOGGLE_LABELS"]    = "Mostrar etiquetas de objetivo"
L["BUTTON_TOGGLE_MTTARGETS"] = "Mostrar el objetivo de los objetivos de los TP"
L["BUTTON_TOGGLE_SHOWMT"]    = "Mostrar los Tanques principales"
L["BUTTON_HELPER_PIN"]       = "Clavar ventana"

L["XS_TARGET"] = "Objetivo de %s"
L["NO_TARGET"] = "sin objetivo"

L["TITLE_MT_LONG"]       = "Objetivos de TP"
L["TITLE_MT_SHORT"]      = "TP"
L["TITLE_WARRIOR_LONG"]  = "Objetivos de guerrero"
L["TITLE_WARRIOR_SHORT"] = "Tanques"

L["HELPER_NEEDPROMOTE"] = "Debes ser promovido para definir el tanque principal"
L["HELPER_MASET"]       = "Asistente principal definido a %s"
L["HELPER_MACLEAR"]     = "¡Asistente principal |c00FF0000eliminado!"
L["HELPER_MAREMOVED"]   = "Asistente principal %s no encontrado en la lista de tanques - ¡eliminado!"
L["HELPER_MAREMOTESET"] = "%s ha asignado que el Asistente principal sea %s"

L["HELPER_FINDFOUND"]   = "El uso de BUSCAR encontró al siguiente posible objetivo. ('|c00007F00/zphelper find|r' para limpiar)."
L["HELPER_FINDCLEARED"] = "¡Buscar |c00FF0000limpiado!|r"
L["HELPER_FINDSET"]     = "Buscar definido a %s. ('|c00007F00/zphelper find|r' para limpiar)."

L["AGGRO_PET"]     = "- AGGRO EN MASCOTA -"
L["AGGRO_DRAGTIP"] = "Moeve la localización de la alerta de Aggro"
