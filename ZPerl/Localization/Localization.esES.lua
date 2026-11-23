-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFFClic derecho|r para arrastrar este icono"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r para ver el uso de memoria de Z-Perl"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Mayús|r para ver el uso de memoria de Z-Perl desde el inicio"

L["MINIMENU_OPTIONS"]    = "Opciones"
L["MINIMENU_ASSIST"]     = "Mostrar marco de asistentes"
L["MINIMENU_CASTMON"]    = "Mostrar monitor de lanzamiento"
L["MINIMENU_RAIDAD"]     = "Mostrar administración de banda"
L["MINIMENU_ITEMCHK"]    = "Mostrar verificador de objetos"
L["MINIMENU_ROSTERTEXT"] = "Texto de lista"

L["TYPE_NOT_SPECIFIED"] = "No indicado"
L["TYPE_PET"]           = "Mascota"
L["TYPE_BOSS"]          = "Jefe"
L["TYPE_RAREPLUS"]      = "Raro+"
L["TYPE_ELITE"]         = "Élite"
L["TYPE_RARE"]          = "Raro"

-- Zones
L["LOC_ZONE_BARADIN_HOLD"]          = "Bastión de Baradin"
L["LOC_ZONE_BASTION_OF_TWILIGHT"]   = "Bastión del Crepúsculo"
L["LOC_ZONE_BLACK_TEMPLE"]          = "Templo Oscuro"
L["LOC_ZONE_BLACKWING_DECENT"]      = "Descenso de Alanegra"
L["LOC_ZONE_DRAGONSOUL"]            = "Alma de Dragón"
L["LOC_ZONE_EYE_OF_ETERNITY"]       = "El Ojo de la Eternidad"
L["LOC_ZONE_FIRELANDS"]             = "Tierras de Fuego"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "La Cima Hyjal"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "Ciudadela de la Corona de Hielo"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]      = "El Sagrario Obsidiana"
L["LOC_ZONE_RUBY_SANCTUM"]          = "El Sagrario Rubí"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "Caverna Santuario Serpiente"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "Meseta de La Fuente del Sol"
L["LOC_ZONE_THRONE_OF_FOUR_WINDS"]  = "Trono de los Cuatro Vientos"
L["LOC_ZONE_TOMB_OF_SARGERAS"]      = "Tumba de Sargeras"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "Prueba del Cruzado"

-- Status
L["LOC_DEAD"]         = "Muerto"
L["LOC_GHOST"]        = "Fantasma"
L["LOC_OFFLINE"]      = "Desconectado"
L["LOC_RESURRECTED"]  = "Resucitado"
L["LOC_SS_AVAILABLE"] = "PA disponible"
L["LOC_UPDATING"]     = "Actualizando"
L["LOC_ACCEPTEDRES"]  = "Aceptado"

L["LOC_NONEWATCHED"] = "Ninguno observado"

L["LOC_STATUSTIP"]     = "Destacados de estado: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "Sanación en el tiempo",
	AGGRO = "Agro",
	HEAL = "Siendo sanado",
	SHIELD = "Blindado"
}

BINDING_NAME_ZPERL_TOGGLERAID         = "Mostrar/ocultar ventanas de banda"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "Mostrar/ocultar mascotas de banda"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "Mostrar/ocultar ventana de opciones"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "Mostrar/ocultar beneficios/perjuicios/ninguno"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Mostrar/ocultar lanzables/curables"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "Mostrar/ocultar buscador de alcance"

L["KEY_NOTICE_RAID_BUFFANY"]      = "Todos los beneficios/perjuicios mostrados"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "Solo beneficios o perjuicios lanzables/curables mostrados"
L["KEY_NOTICE_RAID_BUFFS"]        = "Beneficios de banda mostrados"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "Perjuicios de banda mostradas"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "Ningún beneficio de banda mostrado"

L["DRAGHINT1"] = "|c00FFFFFFHaz clic|r para escalar la ventana"
L["DRAGHINT2"] = "|c00FFFFFFMayús + clic|r para redimensionar la ventana"

L["CMD_MENU"]    = "menú"
L["CMD_OPTIONS"] = "opciones"
L["CMD_LOCK"]    = "bloquear"
L["CMD_UNLOCK"]  = "desbloquear"

L["RAID_TOOLTIP_WITHBUFF"]    = "Con beneficio: (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "Sin beneficio: (%s)"

L["MINIMAP_HELP1"]                    = "|c00FFFFFFClic izquierdo|r para las opciones"
L["LOC_ZONE_ANTORUS"]                 = "Antorus, el Trono Ardiente"
L["LOC_ZONE_KARAZHAN"]                = "Karazhan"
L["LOC_ZONE_NAXXRAMAS"]               = "Naxxramas"
L["LOC_ZONE_ULDUAR"]                  = "Ulduar"
L["RAID_GROUPSHORT"]                  = "G%d"
L["KEY_NOTICE_RAID_BUFFS_AND_DEBUFFS"] = "Beneficios y perjuicios de banda mostrados"
L["CMD_HELP"]                         = "|c00FFFF80Uso: |c00FFFFFF/zperl menu | lock | unlock | layout [nombre]"
L["LAYOUT_LIST"]                      = "Diseños:"
L["LAYOUT_CURRENT"]                   = " (Actual)"
L["LAYOUT_UNKNOWN"]                   = "No hay ningún diseño llamado %s"
