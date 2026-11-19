-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "ruRU" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = ZPerl.ShortProductName.." Рейд Админ"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "Закрепить Окно"
L["BUTTON_ADMIN_LOCKOPEN"]  = "Блокировка открытого окна"
L["BUTTON_ADMIN_SAVE1"]     = "Сохр-ть Список"
L["BUTTON_ADMIN_SAVE2"]     = "Сохраняет текущий список с определённым именем. Если имя не заданно, будет использоваться текущее время вместо имени"
L["BUTTON_ADMIN_LOAD1"]     = "Загр-ть Список"
L["BUTTON_ADMIN_LOAD2"]     = "Загружает выбранный список. Любые участники рейда кто не сохранён в списке будут заменены вместо других с соответствующим классом"
L["BUTTON_ADMIN_DELETE1"]   = "Удалить Список"
L["BUTTON_ADMIN_DELETE2"]   = "Удалить выбранный список"
L["BUTTON_ADMIN_STOPLOAD1"] = "Остановить загрузку"
L["BUTTON_ADMIN_STOPLOAD2"] = "Прекратить процедуру загрузки списка"

L["LOAD"] = "Загр-ть"

L["SAVED_ROSTER"]         = "Сохр-ть список с названием '%s'"
L["ADMIN_DIFFERENCES"]    = "%d отличие с текущим списком"
L["NO_ROSTER_NAME_GIVEN"] = "Не задано имя списка"
L["NO_ROSTER_CALLED"]     = "Нет списка с названием '%s'"

-- Item Checker
L["CHECK_TITLE"] = ZPerl.ShortProductName.." Предмет контроль"

L["CHECK_NAME"] = "Имя"

L["CHECK_DROPITEMTIP1"]         = "Добытые вещи"
L["CHECK_DROPITEMTIP2"]         = "Предмет может быть перетащен в фрейм и добавлен в список запрашиваемых вещей.\rВы можете использовать простую команду /raitem  и предметы будут добавлены сюда в будущем."
L["CHECK_QUERY_DESC1"]          = "Запрос"
L["CHECK_QUERY_DESC2"]          = "Выполнить проверку предметов (/raitem) на все выбранные предметы\rЗапрос всегда выдаст информацию о текущей прочности, устойчивости и реагентах"
L["CHECK_LAST_DESC1"]           = "Последний"
L["CHECK_LAST_DESC2"]           = "Пере-отметить предметы последнего поиска"
L["CHECK_ALL_DESC1"]            = "Все"
L["CHECK_ALL_DESC2"]            = "Отметить все предметы"
L["CHECK_NONE_DESC1"]           = "Нет"
L["CHECK_NONE_DESC2"]           = "Снять отметку со всех предметов"
L["CHECK_DELETE_DESC1"]         = "Удалить"
L["CHECK_DELETE_DESC2"]         = "Навсегда удалить все отмеченные предметы из списка"
L["CHECK_REPORT_DESC1"]         = "Сообщить"
L["CHECK_REPORT_DESC2"]         = "Показать уведомление выбранных результатов в рейд чат"
L["CHECK_REPORT_WITH_DESC1"]    = "С"
L["CHECK_REPORT_WITH_DESC2"]    = "Уведомить людей с предметом (или не одетым) в рейд чат. Если сканирования снаряжения було выполнено, то результаты будут заменены."
L["CHECK_REPORT_WITHOUT_DESC1"] = "Без"
L["CHECK_REPORT_WITHOUT_DESC2"] = "Уведомить людей без предмета (или имеющих задействованый предмет) в рейд чат"
L["CHECK_SCAN_DESC1"]           = "Скан"
L["CHECK_SCAN_DESC2"]           = "Будет проверен каждый в рейде в пределах досягаемости, для просмотра выбранного снаряжения и отображения его в списке. Дальше 10ярд от рейда не попадут в проверку."
L["CHECK_SCANSTOP_DESC1"]       = "Стоп Скан"
L["CHECK_SCANSTOP_DESC2"]       = "Остановить сканирование снаряжения игроков для выбранного предмета"
L["CHECK_REPORTPLAYER_DESC1"]   = "Доложить игроку"
L["CHECK_REPORTPLAYER_DESC2"]   = "Доложить выбранным игрокам детали предмета или статус в рейд чат"

L["CHECK_BROKEN"]               = "Сломанный"
L["CHECK_REPORT_DURABILITY"]    = "Средняя прочность Рейда: %d%% и %d людей с общим количеством сломанных вещей %d"
L["CHECK_REPORT_PDURABILITY"]   = "%s's Прочность: %d%% с %d сломанных вещей"
L["CHECK_REPORT_RESISTS"]       = "Средняя устойчивость Рейда: %d огонь, %d природа, %d лед, %d тьма, %d тайная магия"
L["CHECK_REPORT_PRESISTS"]      = "%s's Устойчивость: %d огонь, %d природа, %d лед, %d тьма, %d тайная магия"
L["CHECK_REPORT_WITH"]          = " - с: "
L["CHECK_REPORT_WITHOUT"]       = " - без: "
L["CHECK_REPORT_WITH_EQ"]       = " - с (или не задействован): "
L["CHECK_REPORT_WITHOUT_EQ"]    = " - без (или задействован): "
L["CHECK_REPORT_EQUIPED"]       = " : одето: "
L["CHECK_REPORT_NOTEQUIPED"]    = " : НЕ одето: "
L["CHECK_REPORT_ALLEQUIPED"]    = "Все уже %s задействованы"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "Все уже %s задействованы, но %d игрок(оа) в не сети"
L["CHECK_REPORT_PITEM"]         = "%s имеет %d %s в инвентаре"
L["CHECK_REPORT_PEQUIPED"]      = "%s уже %s задействован"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s НЕ ИМЕЕТ %s одетым"
L["CHECK_REPORT_DROPDOWN"]      = "Канал вывода"
L["CHECK_REPORT_DROPDOWN_DESC"] = "Выберите канал вывода для результатов Предмет контроля"

L["CHECK_REPORT_WITHSHORT"]       = " : %d с"
L["CHECK_REPORT_WITHOUTSHORT"]    = " : %d без"
L["CHECK_REPORT_EQUIPEDSHORT"]    = " : %d одето"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = " : %d НЕ одето"
L["CHECK_REPORT_OFFLINE"]         = " : %d не в сети"
L["CHECK_REPORT_TOTAL"]           = " : %d Всего предметов"
L["CHECK_REPORT_NOTSCANNED"]      = " : %d не-проверено"

L["CHECK_LASTINFO"] = "Последние данные получены %sназад"

L["CHECK_AVERAGE"] = "Средний"
L["CHECK_TOTALS"]  = "Всего"
L["CHECK_EQUIPED"] = "Одето"

L["CHECK_SCAN_MISSING"] = "Производится сканирование предметов игроков. (%d не просканировано)"

L["REAGENTS"] = {
	PRIEST = "Священная свеча",
	MAGE = "Порошок чар",
	DRUID = "Дикий шипокорень",
	SHAMAN = "Крест",
	WARLOCK = "Осколок души",
	PALADIN = "Символ божественности",
	ROGUE = "Воспламеняющийся порошок"
}

L["CHECK_REAGENTS"] = "Реагенты"

-- Roster Text
L["ROSTERTEXT_TITLE"]         = ZPerl.ShortProductName.." Текст списка"
L["ROSTERTEXT_GROUP"]         = "Группа %d"
L["ROSTERTEXT_GROUP_DESC"]    = "Использовать имена для группы %d"
L["ROSTERTEXT_SAMEZONE"]      = "Только одинаковые зоны"
L["ROSTERTEXT_SAMEZONE_DESC"] = "Включает только имена игроков которые находятся в той-же зоне что и вы"
L["ROSTERTEXT_HELP"]          = "Нажмите Ctrl-C для копирования текста в буфер"
L["ROSTERTEXT_TOTAL"]         = "Всего: %d"
L["ROSTERTEXT_SETN"]          = "%d человек"
L["ROSTERTEXT_SETN_DESC"]     = "Авто выбор группы для рейда %d человек "
L["ROSTERTEXT_TOGGLE"]        = "Тумблер"
L["ROSTERTEXT_TOGGLE_DESC"]   = "Переключатель выбранной группы"
L["ROSTERTEXT_SORT"]          = "Сорт"
L["ROSTERTEXT_SORT_DESC"]     = "Сортировать по имени вместо группа+имя"
