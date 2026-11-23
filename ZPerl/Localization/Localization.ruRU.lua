-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "ruRU" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFFПравый клик|r - перемещение иконки"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r для просмотра потребления памяти Z-Perl'ом"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Shift|r для просмотра потребления памяти Z-Perl'ом после запуска"

L["MINIMENU_OPTIONS"]    = "Опции"
L["MINIMENU_ASSIST"]     = "Показ Фрейма Поддержки"
L["MINIMENU_CASTMON"]    = "Показ Монитора применений"
L["MINIMENU_RAIDAD"]     = "Показ Рейд Админа"
L["MINIMENU_ITEMCHK"]    = "Показ проверку вещей"
L["MINIMENU_ROSTERTEXT"] = "Список-Текст"

L["TYPE_NOT_SPECIFIED"] = "Не указанно"
L["TYPE_PET"]           = "Питомец"
L["TYPE_BOSS"]          = "Босс"
L["TYPE_RAREPLUS"]      = "Редкий+"
L["TYPE_ELITE"]         = "Элита"
L["TYPE_RARE"]          = "Редкий"

-- Zones
L["LOC_ZONE_BLACK_TEMPLE"]          = "Черный храм"
L["LOC_ZONE_EYE_OF_ETERNITY"]       = "Око Вечности"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "Вершина Хиджала"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "Цитадель Ледяной Короны"
L["LOC_ZONE_KARAZHAN"]              = "Каражан"
L["LOC_ZONE_NAXXRAMAS"]             = "Наксрамас"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]      = "Обсидиановое святилище"
L["LOC_ZONE_RUBY_SANCTUM"]          = "Рубиновое святилище"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "Змеиное святилище"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "Плато Солнечного Колодца"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "Испытание крестоносца"
L["LOC_ZONE_ULDUAR"]                = "Ульдуар"

-- Status
L["LOC_DEAD"]         = "цель мертва"
L["LOC_GHOST"]        = "Дух"
L["LOC_OFFLINE"]      = "Не в сети"
L["LOC_RESURRECTED"]  = "Воскрешаемый"
L["LOC_SS_AVAILABLE"] = "Камень души доступен"
L["LOC_UPDATING"]     = "Обновляется"
L["LOC_ACCEPTEDRES"]  = "Принято"
L["RAID_GROUPSHORT"]  = "Г%d"

L["LOC_NONEWATCHED"] = "не наблюдался"

L["LOC_STATUSTIP"]     = "Статус подсвечивания: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "Исцеления за Время",
	AGGRO = "Аггро",
	HEAL = "Излечен",
	SHIELD = "Защищенный"
}

BINDING_NAME_ZPERL_TOGGLERAID         = "Окна рейда"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "Питомцы рейда"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "Окно опций"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "Баффы/Дебаффы/пусто"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Примен./Лечение"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "Определитель досягаемости"

L["KEY_NOTICE_RAID_BUFFANY"]      = "Показ всех баффов/дебаффов"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "Показ только читаемые/исцеляющие баффы или дебаффы"
L["KEY_NOTICE_RAID_BUFFS"]        = "Показ баффов рейда"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "Показ дебаффов рейда"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "Не показ баффов рейда"

L["DRAGHINT1"] = "|c00FFFFFFКлик|r для масштабирования окна"
L["DRAGHINT2"] = "|c00FFFFFFShift+Клик|r для изменения размера окна"

L["RAID_TOOLTIP_WITHBUFF"]    = "С баффом: (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "Без баффа: (%s)"

L["MINIMAP_HELP1"]                    = "|c00FFFFFFЛевый клик|r - настройки"
L["LOC_ZONE_ANTORUS"]                 = "Анторус, Пылающий Трон"
L["LOC_ZONE_BARADIN_HOLD"]            = "Крепость Барадин"
L["LOC_ZONE_BASTION_OF_TWILIGHT"]     = "Сумеречный бастион"
L["LOC_ZONE_BLACKWING_DECENT"]        = "Твердыня Крыла Тьмы"
L["LOC_ZONE_DRAGONSOUL"]              = "Душа Дракона"
L["LOC_ZONE_FIRELANDS"]               = "Огненные Просторы"
L["LOC_ZONE_THRONE_OF_FOUR_WINDS"]    = "Трон Четырех Ветров"
L["LOC_ZONE_TOMB_OF_SARGERAS"]        = "Гробница Саргераса"
L["KEY_NOTICE_RAID_BUFFS_AND_DEBUFFS"] = "Показаны баффы и дебаффы рейда"
L["CMD_HELP"]                         = "|c00FFFF80Использование: |c00FFFFFF/zperl menu | lock | unlock | layout [название]"
L["LAYOUT_LIST"]                      = "Макеты:"
L["LAYOUT_CURRENT"]                   = " (текущий)"
L["LAYOUT_UNKNOWN"]                   = "Нет макета с названием %s"
