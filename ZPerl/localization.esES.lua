-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)
-- Spanish Translations by Hastings, Woopy

if GetLocale() == "esES" or GetLocale() == "esMX" then
	XPerl_Description		= XPerl_ProductName.." por "..XPerl_Author
	XPerl_LongDescription		= "Reemplazo para los marcos de unidades, con un nuevo aspecto de jugador, mascota, grupo, objetivo, objetivo del objetivo, enfoque, banda"

	XPERL_MINIMAP_HELP1 = "|c00FFFFFFClic izquierdo|r para opciones (y para |c0000FF00desbloquear los marcos|r)"
	XPERL_MINIMAP_HELP2 = "|c00FFFFFFClic derecho|r para arrastrar este icono"
	XPERL_MINIMAP_HELP3 = "\rMiembros de la banda: |c00FFFF80%d|r\rMiembros del grupo: |c00FFFF80%d|r"
	XPERL_MINIMAP_HELP4 = "\rEres el lider del grupo/banda"
	XPERL_MINIMAP_HELP5 = "|c00FFFFFFAlt|r para ver el uso de memoria de Z-Perl"
	XPERL_MINIMAP_HELP6 = "|c00FFFFFF+Mayús|r para ver el uso de memoria de Z-Perl desde el inicio"

	XPERL_MINIMENU_OPTIONS = "Opciones"
	XPERL_MINIMENU_ASSIST = "Mostrar marco de asistentes"
	XPERL_MINIMENU_CASTMON = "Mostrar monitor de lanzamiento"
	XPERL_MINIMENU_RAIDAD = "Mostrar administración de banda"
	XPERL_MINIMENU_ITEMCHK = "Mostrar verificador de objetos"
	XPERL_MINIMENU_RAIDBUFF = "Beneficios de banda"
	XPERL_MINIMENU_ROSTERTEXT = "Texto de lista"
	XPERL_MINIMENU_RAIDSORT = "Ordenación de banda"
	XPERL_MINIMENU_RAIDSORT_GROUP = "Ordenar por grupo"
	XPERL_MINIMENU_RAIDSORT_CLASS = "Ordenar por clase"

	XPERL_TYPE_NOT_SPECIFIED = "No indicado"
	XPERL_TYPE_PET		= PET
	XPERL_TYPE_BOSS		= "Jefe"
	XPERL_TYPE_RAREPLUS 	= "Raro+"
	XPERL_TYPE_ELITE	= "Élite"
	XPERL_TYPE_RARE		= "Raro"

	-- Zones
	XPERL_LOC_ZONE_ANTORUS = "Antorus"
	XPERL_LOC_ZONE_BARADIN_HOLD = "Bastión de Baradin"
	XPERL_LOC_ZONE_BASTION_OF_TWILIGHT = "Bastión del Crepúsculo"
	XPERL_LOC_ZONE_BLACK_TEMPLE = "Templo Oscuro"
	XPERL_LOC_ZONE_BLACKWING_DECENT = "Descenso de Alanegra"
	XPERL_LOC_ZONE_DRAGONSOUL = "Alma de Dragón"
	XPERL_LOC_ZONE_EMERALD_NIGHTMARE = "Pesadilla Esmeralda"
	XPERL_LOC_ZONE_EYE_OF_ETERNITY = "El Ojo de la Eternidad"
	XPERL_LOC_ZONE_FIRELANDS = "Tierras de Fuego"
	XPERL_LOC_ZONE_HYJAL_SUMMIT = "La Cima Hyjal"
	XPERL_LOC_ZONE_ICECROWN_CITADEL = "Ciudadela de la Corona de Hielo"
	XPERL_LOC_ZONE_KARAZHAN = "Karazhan"
	XPERL_LOC_ZONE_NAXXRAMAS = "Naxxramas"
	XPERL_LOC_ZONE_NIGHTHOLD = "Bastión Nocturno"
	XPERL_LOC_ZONE_OBSIDIAN_SANCTUM = "El Sagrario Obsidiana"
	XPERL_LOC_ZONE_RUBY_SANCTUM = "El Sagrario Rubí"
	XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "Caverna Santuario Serpiente"
	XPERL_LOC_ZONE_SUNWELL_PLATEAU = "Meseta de La Fuente del Sol"
	XPERL_LOC_ZONE_THRONE_OF_FOUR_WINDS = "Trono de los Cuatro Vientos"
	XPERL_LOC_ZONE_TOMB_OF_SARGERAS = "Tumba de Sargeras"
	XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "Prueba del Cruzado"
	XPERL_LOC_ZONE_TRIAL_OF_VALOR = "Prueba del Valor"
	XPERL_LOC_ZONE_ULDUAR = "Ulduar"

	-- Status
	XPERL_LOC_DEAD		= DEAD
	XPERL_LOC_GHOST 	= "Fantasma"
	XPERL_LOC_FEIGNDEATH	= "Fingir muerte"
	XPERL_LOC_FEIGNDEATHSHORT	= "FM"
	XPERL_LOC_OFFLINE	= PLAYER_OFFLINE
	XPERL_LOC_RESURRECTED	= "Resucitado"
	XPERL_LOC_SS_AVAILABLE	= "PA disponible"
	XPERL_LOC_UPDATING	= "Actualizando"
	XPERL_LOC_ACCEPTEDRES	= "Aceptado"	-- Res accepted
	XPERL_RAID_GROUP	= "Grupo %d"
	XPERL_RAID_GROUPSHORT	= "G%d"

	XPERL_LOC_NONEWATCHED	= "Ninguno observado"

	XPERL_LOC_STATUSTIP = "Destacados de estado: "	-- Tooltip explanation of status highlight on unit
	XPERL_LOC_STATUSTIPLIST = {
		HOT = "Sanación en el tiempo",
		AGGRO = "Agro",
		MISSING = "Faltando tus beneficios de clase",
		HEAL = "Siendo sanado",
		SHIELD = "Blindado"
		}

	XPERL_OK	= "Hecho"
	XPERL_CANCEL	= "Cancelar"

	XPERL_LOC_LARGENUMTAG		= "K"
	XPERL_LOC_HUGENUMTAG		= "M"
	XPERL_LOC_VERYHUGENUMTAG	= "G"

	BINDING_HEADER_ZPERL = XPerl_ProductName
	BINDING_NAME_ZPERL_TOGGLERAID = "Mostrar/ocultar ventanas de banda"
	BINDING_NAME_ZPERL_TOGGLERAIDSORT = "Mostrar/ocultar ordenación de banda por clase/grupo"
	BINDING_NAME_ZPERL_TOGGLERAIDPETS = "Mostrar/ocultar mascotas de banda"
	BINDING_NAME_ZPERL_TOGGLEOPTIONS = "Mostrar/ocultar ventana de opciones"
	BINDING_NAME_ZPERL_TOGGLEBUFFTYPE = "Mostrar/ocultar beneficios/perjuicios/ninguno"
	BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Mostrar/ocultar lanzables/curables"
	BINDING_NAME_ZPERL_TEAMSPEAKMONITOR = "Monitor de Teamspeak"
	BINDING_NAME_ZPERL_TOGGLERANGEFINDER = "Mostrar/ocultar buscador de alcance"

	XPERL_KEY_NOTICE_RAID_BUFFANY = "Todos los beneficios/perjuicios mostrados"
	XPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Solo beneficios o perjuicios lanzables/curables mostrados"
	XPERL_KEY_NOTICE_RAID_BUFFS = "Beneficios de banda mostrados"
	XPERL_KEY_NOTICE_RAID_DEBUFFS = "Perjuicios de banda mostradas"
	XPERL_KEY_NOTICE_RAID_NOBUFFS = "Ningún beneficio de banda mostrado"

	XPERL_DRAGHINT1 = "|c00FFFFFFHaz clic|r para escalar la ventana"
	XPERL_DRAGHINT2 = "|c00FFFFFFMayús + clic|r para redimensionar la ventana"

	-- Usage
	XPerlUsageNameList = {
		XPerl = "Core",
		XPerl_Player = "Jugador",
		XPerl_PlayerPet = "Mascota",
		XPerl_Target = "Objetivo",
		XPerl_TargetTarget = "Objetivo del objetivo",
		XPerl_Party = "Grupo",
		XPerl_PartyPet = "Mascotas del grupo",
		XPerl_RaidFrames = "Marcos de banda",
		XPerl_RaidHelper = "Asistente de banda",
		XPerl_RaidAdmin = "Administrador de banda",
		XPerl_TeamSpeak = "Monitor de TS",
		XPerl_RaidMonitor = "Monitor de banda",
		XPerl_RaidPets = "Mascotas de banda",
		XPerl_ArcaneBar = "Barra arcana",
		XPerl_PlayerBuffs = "Beneficios del jugador",
		XPerl_GrimReaper = "Segador"
	}

	XPERL_USAGE_MEMMAX = "Memoria máxima de la IU: %d"
	XPERL_USAGE_MODULES = "Módulos: "
	XPERL_USAGE_NEWVERSION = "*Versión más reciente"
	XPERL_USAGE_AVAILABLE = "%s |c00FFFFFF%s|r está disponible para descargar"

	XPERL_CMD_MENU = "menú"
	XPERL_CMD_OPTIONS = "opciones"
	XPERL_CMD_LOCK = "bloquear"
	XPERL_CMD_UNLOCK = "desbloquear"
	XPERL_CMD_CONFIG = "config"
	XPERL_CMD_LIST = "lista"
	XPERL_CMD_DELETE = "eliminar"
	XPERL_CMD_HELP = "|c00FFFF80Uso: |c00FFFFFF/zperl menú | bloquear | desbloquear | config lista | config eliminar <reino> <nombre>"

	XPERL_CANNOT_DELETE_CURRENT = "No puedes eliminar tu configuración actual"
	XPERL_CONFIG_DELETED = "Configuración eliminada para %s/%s"
	XPERL_CANNOT_FIND_DELETE_TARGET = "No se encontró configuración para eliminar (%s/%s)"
	XPERL_CANNOT_DELETE_BADARGS = "Por favor, proporciona el nombre del reino y el nombre del jugador"
	XPERL_CONFIG_LIST = "Lista de configuraciones:"
	XPERL_CONFIG_CURRENT = " (Actual)"

	XPERL_RAID_TOOLTIP_WITHBUFF = "Con beneficio: (%s)"
	XPERL_RAID_TOOLTIP_WITHOUTBUFF = "Sin beneficio: (%s)"
	XPERL_RAID_TOOLTIP_BUFFEXPIRING = "El beneficio %s de %s expira en %s" -- Name, buff name, time to expire

	XPERL_NEW_VERSION_DETECTED = "Nueva versión detectada:"
	XPERL_DOWNLOAD_LATEST = "Puedes descargar la última versión desde:"
	XPERL_DOWNLOAD_LOCATION = "https://mods.curse.com/addons/wow/zperl"
end
