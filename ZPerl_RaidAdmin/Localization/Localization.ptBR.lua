-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "ptBR" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = ZPerl.ShortProductName.." Administração de Raide"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "Fixar janela"
L["BUTTON_ADMIN_LOCKOPEN"]  = "Manter janela aberta"
L["BUTTON_ADMIN_SAVE1"]     = "Salvar formação"
L["BUTTON_ADMIN_SAVE2"]     = "Salva a formação atual com o nome especificado. Se nenhum nome for dado, a hora atual será usada como nome"
L["BUTTON_ADMIN_LOAD1"]     = "Carregar formação"
L["BUTTON_ADMIN_LOAD2"]     = "Carrega a formação selecionada. Membros da formação salva que não estão mais na raide serão substituídos por membros da mesma classe que não estão salvos na formação"
L["BUTTON_ADMIN_DELETE1"]   = "Excluir formação"
L["BUTTON_ADMIN_DELETE2"]   = "Exclui a formação selecionada"
L["BUTTON_ADMIN_STOPLOAD1"] = "Parar carregamento"
L["BUTTON_ADMIN_STOPLOAD2"] = "Interrompe o carregamento da formação"

L["LOAD"] = "Carregar"

L["SAVED_ROSTER"]         = "Formação salva como '%s'"
L["ADMIN_DIFFERENCES"]    = "%d diferenças em relação à formação atual"
L["NO_ROSTER_NAME_GIVEN"] = "Nenhum nome de formação informado"
L["NO_ROSTER_CALLED"]     = "Nenhuma formação salva chamada '%s'"

-- Item Checker
L["CHECK_TITLE"] = ZPerl.ShortProductName.." Verificação de Itens"

L["CHECK_NAME"] = "Nome"

L["CHECK_DROPITEMTIP1"]         = "Soltar itens"
L["CHECK_DROPITEMTIP2"]         = "Itens podem ser soltos nesta janela e adicionados à lista de itens consultáveis.\rVocê também pode usar o comando /raitem normalmente e os itens serão adicionados aqui para uso futuro."
L["CHECK_QUERY_DESC1"]          = "Consultar"
L["CHECK_QUERY_DESC2"]          = "Faz a verificação (/raitem) de todos os itens marcados\rA consulta sempre obtém informações atuais de durabilidade, resistências e reagentes"
L["CHECK_LAST_DESC1"]           = "Último"
L["CHECK_LAST_DESC2"]           = "Marca novamente os itens da última busca"
L["CHECK_ALL_DESC1"]            = "Todos"
L["CHECK_ALL_DESC2"]            = "Marca todos os itens"
L["CHECK_NONE_DESC1"]           = "Nenhum"
L["CHECK_NONE_DESC2"]           = "Desmarca todos os itens"
L["CHECK_DELETE_DESC1"]         = "Excluir"
L["CHECK_DELETE_DESC2"]         = "Remove permanentemente todos os itens marcados da lista"
L["CHECK_REPORT_DESC1"]         = "Relatar"
L["CHECK_REPORT_DESC2"]         = "Mostra um relatório dos resultados selecionados no chat da raide"
L["CHECK_REPORT_WITH_DESC1"]    = "Com"
L["CHECK_REPORT_WITH_DESC2"]    = "Relata no chat da raide quem tem o item (ou não o tem equipado). Se uma verificação de equipamento foi feita, esses resultados serão mostrados no lugar."
L["CHECK_REPORT_WITHOUT_DESC1"] = "Sem"
L["CHECK_REPORT_WITHOUT_DESC2"] = "Relata no chat da raide quem não tem o item (ou o tem equipado)"
L["CHECK_SCAN_DESC1"]           = "Verificar"
L["CHECK_SCAN_DESC2"]           = "Verifica todos na raide dentro do alcance de inspeção, para ver se têm o item selecionado equipado, e indica isso na lista de jogadores. Aproxime-se (10 metros) das pessoas da raide até que todas sejam verificadas."
L["CHECK_SCANSTOP_DESC1"]       = "Parar verificação"
L["CHECK_SCANSTOP_DESC2"]       = "Para de verificar o equipamento dos jogadores pelo item selecionado"
L["CHECK_REPORTPLAYER_DESC1"]   = "Relatar jogador"
L["CHECK_REPORTPLAYER_DESC2"]   = "Relata no chat da raide os detalhes do jogador selecionado para este item ou estado"

L["CHECK_BROKEN"]               = "Quebrado"
L["CHECK_REPORT_DURABILITY"]    = "Durabilidade média da raide: %d%% e %d pessoas com um total de %d itens quebrados"
L["CHECK_REPORT_PDURABILITY"]   = "Durabilidade de %s: %d%% com %d itens quebrados"
L["CHECK_REPORT_RESISTS"]       = "Resistências médias da raide: %d Fogo, %d Natureza, %d Gelo, %d Sombra, %d Arcano"
L["CHECK_REPORT_PRESISTS"]      = "Resistências de %s: %d Fogo, %d Natureza, %d Gelo, %d Sombra, %d Arcano"
L["CHECK_REPORT_WITH"]          = " - com: "
L["CHECK_REPORT_WITHOUT"]       = " - sem: "
L["CHECK_REPORT_WITH_EQ"]       = " - com (ou não equipado): "
L["CHECK_REPORT_WITHOUT_EQ"]    = " - sem (ou equipado): "
L["CHECK_REPORT_EQUIPED"]       = " : equipado: "
L["CHECK_REPORT_NOTEQUIPED"]    = " : NÃO equipado: "
L["CHECK_REPORT_ALLEQUIPED"]    = "Todos têm %s equipado"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "Todos têm %s equipado, mas %d membro(s) estão offline"
L["CHECK_REPORT_PITEM"]         = "%s tem %d %s no inventário"
L["CHECK_REPORT_PEQUIPED"]      = "%s tem %s equipado"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s NÃO tem %s equipado"
L["CHECK_REPORT_DROPDOWN"]      = "Canal de saída"
L["CHECK_REPORT_DROPDOWN_DESC"] = "Selecione o canal de saída dos resultados da Verificação de Itens"

L["CHECK_REPORT_WITHSHORT"]       = " : %d com"
L["CHECK_REPORT_WITHOUTSHORT"]    = " : %d sem"
L["CHECK_REPORT_EQUIPEDSHORT"]    = " : %d equipados"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = " : %d NÃO equipados"
L["CHECK_REPORT_OFFLINE"]         = " : %d offline"
L["CHECK_REPORT_TOTAL"]           = " : %d itens no total"
L["CHECK_REPORT_NOTSCANNED"]      = " : %d não verificados"

L["CHECK_LASTINFO"] = "Últimos dados recebidos há %s"

L["CHECK_AVERAGE"] = "Média"
L["CHECK_TOTALS"]  = "Total"
L["CHECK_EQUIPED"] = "Equipado"

L["CHECK_SCAN_MISSING"] = "Verificando o item nos jogadores inspecionáveis. (%d não verificados)"

L["CHECK_REAGENTS"] = "Reagentes"

-- Roster Text
L["ROSTERTEXT_TITLE"]         = ZPerl.ShortProductName.." Texto da Formação"
L["ROSTERTEXT_GROUP"]         = "Grupo %d"
L["ROSTERTEXT_GROUP_DESC"]    = "Usar nomes do grupo %d"
L["ROSTERTEXT_SAMEZONE"]      = "Somente a mesma zona"
L["ROSTERTEXT_SAMEZONE_DESC"] = "Incluir somente jogadores na mesma zona que você"
L["ROSTERTEXT_HELP"]          = "Pressione Ctrl-C para copiar o texto para a área de transferência"
L["ROSTERTEXT_TOTAL"]         = "Total: %d"
L["ROSTERTEXT_SETN"]          = "%d jogadores"
L["ROSTERTEXT_SETN_DESC"]     = "Selecionar automaticamente os grupos para uma raide de %d jogadores"
L["ROSTERTEXT_TOGGLE"]        = "Alternar"
L["ROSTERTEXT_TOGGLE_DESC"]   = "Alternar os grupos selecionados"
L["ROSTERTEXT_SORT"]          = "Ordenar"
L["ROSTERTEXT_SORT_DESC"]     = "Ordenar por nome em vez de grupo+nome"
