-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if GetLocale() == "ptBR" then
	XPerl_Description = XPerl_ProductName.." por "..XPerl_Author
	XPerl_LongDescription = "Substituto para os quadros de unidades, com uma nova aparência para jogador, mascote, grupo, alvo, alvo do alvo, foco, raide"

	XPERL_MINIMAP_HELP1 = "|c00FFFFFFClique esquerdo|r para opções (e para |c0000FF00desbloquear os quadros|r)"
	XPERL_MINIMAP_HELP2 = "|c00FFFFFFClique direito|r para arrastar este ícone"
	XPERL_MINIMAP_HELP3 = "\rMembros da raide: |c00FFFF80%d|r\rMembros do grupo: |c00FFFF80%d|r"
	XPERL_MINIMAP_HELP4 = "\rVocê é o líder do grupo/raide"
	XPERL_MINIMAP_HELP5 = "|c00FFFFFFAlt|r para ver o uso de memória de Z-Perl"
	XPERL_MINIMAP_HELP6 = "|c00FFFFFF+Shift|r para ver o uso de memória de Z-Perl desde o início"

	XPERL_MINIMENU_OPTIONS = "Opções"
	XPERL_MINIMENU_ASSIST = "Mostrar quadro de assistente"
	XPERL_MINIMENU_CASTMON = "Mostrar monitor de feitiço"
	XPERL_MINIMENU_RAIDAD = "Mostrar administração de raide"
	XPERL_MINIMENU_ITEMCHK = "Mostrar verificador de itens"
	XPERL_MINIMENU_RAIDBUFF = "Bônus de raide"
	XPERL_MINIMENU_ROSTERTEXT = "Texto da lista"
	XPERL_MINIMENU_RAIDSORT = "Ordenação de raide"
	XPERL_MINIMENU_RAIDSORT_GROUP = "Ordenar por grupo"
	XPERL_MINIMENU_RAIDSORT_CLASS = "Ordenar por classe"

	XPERL_TYPE_NOT_SPECIFIED = "Não especificado"
	XPERL_TYPE_PET = "Mascote"
	XPERL_TYPE_BOSS = "Chefe"
	XPERL_TYPE_RAREPLUS = "Raro+"
	XPERL_TYPE_ELITE = "Elite"
	XPERL_TYPE_RARE = "Raro"

	-- Zones
	XPERL_LOC_ZONE_ANTORUS = "Antorus"
	XPERL_LOC_ZONE_BARADIN_HOLD = "Guarnição Baradin"
	XPERL_LOC_ZONE_BASTION_OF_TWILIGHT = "Bastião do Crepúsculo"
	XPERL_LOC_ZONE_BLACK_TEMPLE = "Templo Negro"
	XPERL_LOC_ZONE_BLACKWING_DECENT = "Descenso do Asa Negra"
	XPERL_LOC_ZONE_DRAGONSOUL = "Alma Dragônica"
	XPERL_LOC_ZONE_EMERALD_NIGHTMARE = "Pesadelo Esmeralda"
	XPERL_LOC_ZONE_EYE_OF_ETERNITY = "Olho da Eternidade"
	XPERL_LOC_ZONE_FIRELANDS = "Terras do Fogo"
	XPERL_LOC_ZONE_HYJAL_SUMMIT = "Pico Hyjal"
	XPERL_LOC_ZONE_ICECROWN_CITADEL = "Cidadela da Coroa de Gelo"
	XPERL_LOC_ZONE_KARAZHAN = "Karazhan"
	XPERL_LOC_ZONE_NAXXRAMAS = "Naxxramas"
	XPERL_LOC_ZONE_NIGHTHOLD = "Baluarte da Noite"
	XPERL_LOC_ZONE_OBSIDIAN_SANCTUM = "Santuário Obsidiano"
	XPERL_LOC_ZONE_RUBY_SANCTUM = "Santuário Rubi"
	XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = "Caverna do Serpentário"
	XPERL_LOC_ZONE_SUNWELL_PLATEAU = "Platô da Nascente do Sol"
	XPERL_LOC_ZONE_THRONE_OF_FOUR_WINDS = "Trono dos Quatro Ventos"
	XPERL_LOC_ZONE_TOMB_OF_SARGERAS = "Tumba de Sargeras"
	XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = "Prova do Cruzado"
	XPERL_LOC_ZONE_TRIAL_OF_VALOR = "Provação da Bravura"
	XPERL_LOC_ZONE_ULDUAR = "Ulduar"

	-- Status
	XPERL_LOC_DEAD = DEAD
	XPERL_LOC_GHOST = "Fantasma"
	XPERL_LOC_FEIGNDEATH = "Fingir de Morto"
	XPERL_LOC_FEIGNDEATHSHORT = "FM"
	XPERL_LOC_OFFLINE = PLAYER_OFFLINE
	XPERL_LOC_RESURRECTED = "Ressuscitado"
	XPERL_LOC_SS_AVAILABLE = "PA disponível"
	XPERL_LOC_UPDATING = "Atualizando"
	XPERL_LOC_ACCEPTEDRES = "Aceito"	-- Res aceito
	XPERL_RAID_GROUP = "Grupo %d"
	XPERL_RAID_GROUPSHORT = "G%d"

	XPERL_LOC_NONEWATCHED = "Nenhum observado"

	XPERL_LOC_STATUSTIP = "Destaques de status: "	-- Tooltip explicando o destaque de status na unidade
	XPERL_LOC_STATUSTIPLIST = {
		HOT = "Cura ao longo do tempo",
		AGGRO = "Agro",
		MISSING = "Faltando seus bônus de classe",
		HEAL = "Sendo curado",
		SHIELD = "Blindado"
	}

	XPERL_OK = "OK"
	XPERL_CANCEL = "Cancelar"

	XPERL_LOC_LARGENUMTAG = "K"
	XPERL_LOC_HUGENUMTAG = "M"
	XPERL_LOC_VERYHUGENUMTAG = "G"

	BINDING_HEADER_ZPERL = XPerl_ProductName
	BINDING_NAME_ZPERL_TOGGLERAID = "Mostrar/ocultar janelas de raide"
	BINDING_NAME_ZPERL_TOGGLERAIDSORT = "Mostrar/ocultar ordenação de raide por classe/grupo"
	BINDING_NAME_ZPERL_TOGGLERAIDPETS = "Mostrar/ocultar mascotes de raide"
	BINDING_NAME_ZPERL_TOGGLEOPTIONS = "Mostrar/ocultar janela de opções"
	BINDING_NAME_ZPERL_TOGGLEBUFFTYPE = "Mostrar/ocultar Bônus/perjuízos/nenhum"
	BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Mostrar/ocultar lançáveis/curáveis"
	BINDING_NAME_ZPERL_TEAMSPEAKMONITOR = "Monitor de Teamspeak"
	BINDING_NAME_ZPERL_TOGGLERANGEFINDER = "Mostrar/ocultar buscador de alcance"

	XPERL_KEY_NOTICE_RAID_BUFFANY = "Todos os bônus/perjuízos mostrados"
	XPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Apenas bônus ou penalidades lançáveis/curáveis mostrados"
	XPERL_KEY_NOTICE_RAID_BUFFS = "Bônus de raide mostrados"
	XPERL_KEY_NOTICE_RAID_DEBUFFS = "Penalidades de raide mostrados"
	XPERL_KEY_NOTICE_RAID_NOBUFFS = "Nenhum bônus de raide mostrado"

	XPERL_DRAGHINT1 = "|c00FFFFFFClique|r para redimensionar a janela"
	XPERL_DRAGHINT2 = "|c00FFFFFFShift + clique|r para redimensionar a janela"

	-- Uso
	XPerlUsageNameList = {
		XPerl = "Núcleo",
		XPerl_Player = "Jogador",
		XPerl_PlayerPet = "Mascote",
		XPerl_Target = "Alvo",
		XPerl_TargetTarget = "Alvo do alvo",
		XPerl_Party = "Grupo",
		XPerl_PartyPet = "Mascotes do grupo",
		XPerl_RaidFrames = "Quadros de raide",
		XPerl_RaidHelper = "Assistente de raide",
		XPerl_RaidAdmin = "Administrador de raide",
		XPerl_TeamSpeak = "Monitor de TS",
		XPerl_RaidMonitor = "Monitor de raide",
		XPerl_RaidPets = "Mascotes de raide",
		XPerl_ArcaneBar = "Barra arcana",
		XPerl_PlayerBuffs = "Bônus do jogador",
		XPerl_GrimReaper = "Ceifador"
	}

	XPERL_USAGE_MEMMAX = "Memória máxima da IU: %d"
	XPERL_USAGE_MODULES = "Módulos: "
	XPERL_USAGE_NEWVERSION = "*Versão mais recente"
	XPERL_USAGE_AVAILABLE = "%s |c00FFFFFF%s|r está disponível para download"

	XPERL_CMD_MENU = "menu"
	XPERL_CMD_OPTIONS = "opções"
	XPERL_CMD_LOCK = "bloquear"
	XPERL_CMD_UNLOCK = "desbloquear"
	XPERL_CMD_CONFIG = "config"
	XPERL_CMD_LIST = "lista"
	XPERL_CMD_DELETE = "excluir"
	XPERL_CMD_HELP = "|c00FFFF80Uso: |c00FFFFFF/zperl menu | bloquear | desbloquear | config lista | config excluir <reino> <nome>"

	XPERL_CANNOT_DELETE_CURRENT = "Não é possível excluir sua configuração atual"
	XPERL_CONFIG_DELETED = "Configuração excluída para %s/%s"
	XPERL_CANNOT_FIND_DELETE_TARGET = "Não foi possível encontrar a configuração para excluir (%s/%s)"
	XPERL_CANNOT_DELETE_BADARGS = "Por favor, forneça o nome do reino e o nome do jogador"
	XPERL_CONFIG_LIST = "Lista de configurações:"
	XPERL_CONFIG_CURRENT = " (Atual)"

	XPERL_RAID_TOOLTIP_WITHBUFF = "Com bônus: (%s)"
	XPERL_RAID_TOOLTIP_WITHOUTBUFF = "Sem bônus: (%s)"
	XPERL_RAID_TOOLTIP_BUFFEXPIRING = "O bônus %s de %s expira em %s" -- Nome, nome do Bônus, tempo até expirar

	XPERL_NEW_VERSION_DETECTED = "Nova versão detectada:"
	XPERL_DOWNLOAD_LATEST = "Você pode baixar a versão mais recente em:"
	XPERL_DOWNLOAD_LOCATION = "https://mods.curse.com/addons"
end
