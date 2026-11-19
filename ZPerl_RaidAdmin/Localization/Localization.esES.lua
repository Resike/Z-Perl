-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = "Z-Perl Administración de banda"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "Clavar ventana"
L["BUTTON_ADMIN_LOCKOPEN"]  = "Bloquear ventana abierta"
L["BUTTON_ADMIN_SAVE1"]     = "Guardar plantilla"
L["BUTTON_ADMIN_SAVE2"]     = "Guarda el diseño de la plantilla actual con el nombre especificado. Si no se indica ninguno, se utilizará la hora actual"
L["BUTTON_ADMIN_LOAD1"]     = "Cargar plantilla"
L["BUTTON_ADMIN_LOAD2"]     = "Cargar la plantilla seleccionada. Cualquier miembro de la banda, que estuviera en la plantilla, y no esté ahora, será reemplazado por un miembro de la misma clase que no esté guardado en la plantilla"
L["BUTTON_ADMIN_DELETE1"]   = "Borrar plantilla"
L["BUTTON_ADMIN_DELETE2"]   = "Borrar la plantilla seleccionada"
L["BUTTON_ADMIN_STOPLOAD1"] = "Detener carga"
L["BUTTON_ADMIN_STOPLOAD2"] = "Aborta el proceso de carga de la plantilla"

L["LOAD"] = "Cargar"

L["SAVED_ROSTER"]         = "Plantilla guardada llamada '%s'"
L["ADMIN_DIFFERENCES"]    = "%d diferencias con la plantilla actual"
L["NO_ROSTER_NAME_GIVEN"] = "No se ha dado nombre para la plantilla"
L["NO_ROSTER_CALLED"]     = "No hay ninguna plantilla guardad con el nombre '%s'"

-- Item Checker
L["CHECK_TITLE"] = "Z-Perl Comprobador de objetos"

L["CHECK_NAME"] = "Nombre"

L["CHECK_DROPITEMTIP1"]         = "Arrastrar objetos"
L["CHECK_DROPITEMTIP2"]         = "Los objetos pueden ser arrastrados a este marco para añadirlos a la lista de objetos a comprobar.\rTambién puede usar el comando /raitem normalmente y los objetos se añadirán aquí y se usarán en el futuro."
L["CHECK_QUERY_DESC1"]          = "Comprobar"
L["CHECK_QUERY_DESC2"]          = "Ejecuta la comprobación de objetos (/raitem) en todos los objetos seleccionados\rLa comprobación siempre obtiene la durabilidad actual, resistencia e información de ingredientes"
L["CHECK_LAST_DESC1"]           = "Último"
L["CHECK_LAST_DESC2"]           = "Re-marcar los objetos de la última búsqueda"
L["CHECK_ALL_DESC1"]            = "Todo"
L["CHECK_ALL_DESC2"]            = "Marcar todos los objetos"
L["CHECK_NONE_DESC1"]           = "Ninguno"
L["CHECK_NONE_DESC2"]           = "Desmarcar todos los objetos"
L["CHECK_DELETE_DESC1"]         = "Eliminar"
L["CHECK_DELETE_DESC2"]         = "Eliminar permanentemente todos los objetos seleccionados de la lista"
L["CHECK_REPORT_DESC1"]         = "Reporte"
L["CHECK_REPORT_DESC2"]         = "Mostrar reporte de los resultados seleccionados en el chat de banda"
L["CHECK_REPORT_WITH_DESC1"]    = "Con"
L["CHECK_REPORT_WITH_DESC2"]    = "Reportar gente con el objeto (o que no lo tengan equipado) al chat de banda. Si se ha hecho un escaneo de equipo, se mostrarán estos resultados en su lugar."
L["CHECK_REPORT_WITHOUT_DESC1"] = "Sin"
L["CHECK_REPORT_WITHOUT_DESC2"] = "Reportar gente sin el objeto (o que lo tengan equipado) al chat de banda."
L["CHECK_SCAN_DESC1"]           = "Escanear"
L["CHECK_SCAN_DESC2"]           = "Comprobará a todos en el rango de inspección, para ver si llevan el objeto seleccionado equipado, e indicarlo en la lista de jugadores. Moverse más cerca (10 metros) de la gente fuera de rango hasta que toda la banda haya sido comprobada."
L["CHECK_SCANSTOP_DESC1"]       = "Detener escaneo"
L["CHECK_SCANSTOP_DESC2"]       = "Detener el escaneo del equipo de los jugadores para el objeto seleccionado"
L["CHECK_REPORTPLAYER_DESC1"]   = "Reportar jugador"
L["CHECK_REPORTPLAYER_DESC2"]   = "Reportar detalles de los jugadores seleccionados sobre este objeto o estado al chat de banda"

L["CHECK_BROKEN"]               = "Rotos"
L["CHECK_REPORT_DURABILITY"]    = "Durabilidad media de la banda: %d%% y %d personas con un total de de %d objetos rotos"
L["CHECK_REPORT_PDURABILITY"]   = "Durabilidad de %s: %d%% con %d objetos rotos"
L["CHECK_REPORT_RESISTS"]       = "Resistencias medias de la banda: %d Fuego, %d Naturaleza, %d Escarcha, %d Sombras, %d Arcano"
L["CHECK_REPORT_PRESISTS"]      = "Resistencias de %s: %d Fuego, %d Naturaleza, %d Escarcha, %d Sombras, %d Arcano"
L["CHECK_REPORT_WITH"]          = " - con: "
L["CHECK_REPORT_WITHOUT"]       = " - sin: "
L["CHECK_REPORT_WITH_EQ"]       = " - con (o no equipado): "
L["CHECK_REPORT_WITHOUT_EQ"]    = " - sin (o equipado): "
L["CHECK_REPORT_EQUIPED"]       = " : equipado: "
L["CHECK_REPORT_NOTEQUIPED"]    = " : NO equipado: "
L["CHECK_REPORT_ALLEQUIPED"]    = "Todos tienen %s equipado/a"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "Todos tienen %s equipado/a, pero %d miembro(s) está(n) desconectado(s)"
L["CHECK_REPORT_PITEM"]         = "%s tiene %d %s en el inventario"
L["CHECK_REPORT_PEQUIPED"]      = "%s tiene %s equipado/a"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s NO tiene %s equipado/a"
L["CHECK_REPORT_DROPDOWN"]      = "Canal de salida"
L["CHECK_REPORT_DROPDOWN_DESC"] = "Seleccionar el canal de salida para el comprobador de objetos"

L["CHECK_REPORT_WITHSHORT"]       = " : %d con"
L["CHECK_REPORT_WITHOUTSHORT"]    = " : %d sin"
L["CHECK_REPORT_EQUIPEDSHORT"]    = " : %d equipado/a"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = " : %d NO equipado/a"
L["CHECK_REPORT_OFFLINE"]         = " : %d desconectado(s)"
L["CHECK_REPORT_TOTAL"]           = " : %d Objeto(s) Total(es)"
L["CHECK_REPORT_NOTSCANNED"]      = " : %d deseleccionado(s)"

L["CHECK_LASTINFO"] = "Últimos datos recibidos %sago"

L["CHECK_AVERAGE"] = "Media"
L["CHECK_EQUIPED"] = "Equipado"

L["CHECK_SCAN_MISSING"] = "Escaneando jugadores en rango para el objeto. (%d no escaneados)"

L["REAGENTS"] = {
	PRIEST = "Vela sacra",
	MAGE = "Partículas Arcanas",
	DRUID = "Raíz de espina salvaje",
	SHAMAN = "Ankh",
	WARLOCK = "Fragmento de alma",
	PALADIN = "Símbolo de Divinidad",
	ROGUE = "Partículas explosivas"
}

L["CHECK_REAGENTS"] = "Componentes"

-- Roster Text
L["ROSTERTEXT_TITLE"]         = ZPerl.ShortProductName.." Texto Lista"
L["ROSTERTEXT_GROUP"]         = "Grupo %d"
L["ROSTERTEXT_GROUP_DESC"]    = "Utilizar nombres del grupo %d"
L["ROSTERTEXT_SAMEZONE"]      = "Solo Misma Zona"
L["ROSTERTEXT_SAMEZONE_DESC"] = "Solo incluir nombres de jugadores que estén en la misma zona que tú"
L["ROSTERTEXT_HELP"]          = "Pulsa Ctrl-C para copiar el texto en el portapapeles"
L["ROSTERTEXT_SETN"]          = "%d Hombres"
L["ROSTERTEXT_SETN_DESC"]     = "Auto-selecciona los grupos para banda de  %d hombres"
L["ROSTERTEXT_TOGGLE"]        = "Alternar"
L["ROSTERTEXT_TOGGLE_DESC"]   = "Alternar grupos seleccionados"
L["ROSTERTEXT_SORT"]          = "Ordenar"
L["ROSTERTEXT_SORT_DESC"]     = "Ordenar por nombre en lugar de grupo+nombre"
