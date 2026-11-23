-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "ptBR" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFFClique direito|r para arrastar este ícone"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r para ver o uso de memória de Z-Perl"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Shift|r para ver o uso de memória de Z-Perl desde o início"

L["MINIMENU_OPTIONS"]    = "Opções"
L["MINIMENU_ASSIST"]     = "Mostrar quadro de assistente"
L["MINIMENU_CASTMON"]    = "Mostrar monitor de feitiço"
L["MINIMENU_RAIDAD"]     = "Mostrar administração de raide"
L["MINIMENU_ITEMCHK"]    = "Mostrar verificador de itens"
L["MINIMENU_ROSTERTEXT"] = "Texto da lista"

L["TYPE_NOT_SPECIFIED"] = "Não especificado"
L["TYPE_PET"]           = "Mascote"
L["TYPE_BOSS"]          = "Chefe"
L["TYPE_RAREPLUS"]      = "Raro+"
L["TYPE_RARE"]          = "Raro"

-- Zones
L["LOC_ZONE_BARADIN_HOLD"]          = "Guarnição Baradin"
L["LOC_ZONE_BASTION_OF_TWILIGHT"]   = "Bastião do Crepúsculo"
L["LOC_ZONE_BLACK_TEMPLE"]          = "Templo Negro"
L["LOC_ZONE_BLACKWING_DECENT"]      = "Descenso do Asa Negra"
L["LOC_ZONE_DRAGONSOUL"]            = "Alma Dragônica"
L["LOC_ZONE_EYE_OF_ETERNITY"]       = "Olho da Eternidade"
L["LOC_ZONE_FIRELANDS"]             = "Terras do Fogo"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "Pico Hyjal"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "Cidadela da Coroa de Gelo"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]      = "Santuário Obsidiano"
L["LOC_ZONE_RUBY_SANCTUM"]          = "Santuário Rubi"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "Caverna do Serpentário"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "Platô da Nascente do Sol"
L["LOC_ZONE_THRONE_OF_FOUR_WINDS"]  = "Trono dos Quatro Ventos"
L["LOC_ZONE_TOMB_OF_SARGERAS"]      = "Tumba de Sargeras"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "Prova do Cruzado"

-- Status
L["LOC_DEAD"]         = "Morto"
L["LOC_GHOST"]        = "Fantasma"
L["LOC_OFFLINE"]      = "Desconectado"
L["LOC_RESURRECTED"]  = "Ressuscitado"
L["LOC_SS_AVAILABLE"] = "PA disponível"
L["LOC_UPDATING"]     = "Atualizando"
L["LOC_ACCEPTEDRES"]  = "Aceito"

L["LOC_NONEWATCHED"] = "Nenhum observado"

L["LOC_STATUSTIP"]     = "Destaques de status: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "Cura ao longo do tempo",
	AGGRO = "Agro",
	HEAL = "Sendo curado",
	SHIELD = "Blindado"
}

BINDING_NAME_ZPERL_TOGGLERAID         = "Mostrar/ocultar janelas de raide"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "Mostrar/ocultar mascotes de raide"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "Mostrar/ocultar janela de opções"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "Mostrar/ocultar Bônus/perjuízos/nenhum"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Mostrar/ocultar lançáveis/curáveis"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "Mostrar/ocultar buscador de alcance"

L["KEY_NOTICE_RAID_BUFFANY"]      = "Todos os bônus/perjuízos mostrados"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "Apenas bônus ou penalidades lançáveis/curáveis mostrados"
L["KEY_NOTICE_RAID_BUFFS"]        = "Bônus de raide mostrados"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "Penalidades de raide mostrados"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "Nenhum bônus de raide mostrado"

L["DRAGHINT1"] = "|c00FFFFFFClique|r para redimensionar a janela"
L["DRAGHINT2"] = "|c00FFFFFFShift + clique|r para redimensionar a janela"

L["CMD_OPTIONS"] = "opções"
L["CMD_LOCK"]    = "bloquear"
L["CMD_UNLOCK"]  = "desbloquear"

L["RAID_TOOLTIP_WITHBUFF"]    = "Com bônus: (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "Sem bônus: (%s)"

L["MINIMAP_HELP1"]                    = "|c00FFFFFFClique esquerdo|r para as opções"
L["TYPE_ELITE"]                       = "Elite"
L["LOC_ZONE_ANTORUS"]                 = "Antorus, o Trono Ardente"
L["LOC_ZONE_KARAZHAN"]                = "Karazhan"
L["LOC_ZONE_NAXXRAMAS"]               = "Naxxramas"
L["LOC_ZONE_ULDUAR"]                  = "Ulduar"
L["RAID_GROUPSHORT"]                  = "G%d"
L["KEY_NOTICE_RAID_BUFFS_AND_DEBUFFS"] = "Bônus e penalidades de raide exibidos"
L["CMD_HELP"]                         = "|c00FFFF80Uso: |c00FFFFFF/zperl menu | lock | unlock | layout [nome]"
L["LAYOUT_LIST"]                      = "Layouts:"
L["LAYOUT_CURRENT"]                   = " (Atual)"
L["LAYOUT_UNKNOWN"]                   = "Nenhum layout chamado %s"
