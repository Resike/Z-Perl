-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "zhTW" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = "Z-Perl 團隊管理介面"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "固定視窗位置"
L["BUTTON_ADMIN_LOCKOPEN"]  = "視窗保持開啟"
L["BUTTON_ADMIN_SAVE1"]     = "儲存名單"
L["BUTTON_ADMIN_SAVE2"]     = "以指定的名稱儲存當前的隊伍成員結構。如果未輸入名稱則以目前時間為名稱"
L["BUTTON_ADMIN_LOAD1"]     = "載入名單"
L["BUTTON_ADMIN_LOAD2"]     = "載入所選擇的名單，所儲存的名單中的任何團隊成員如果已經不在團隊中，則以相同職業的替代之"
L["BUTTON_ADMIN_DELETE1"]   = "刪除名單"
L["BUTTON_ADMIN_DELETE2"]   = "刪除所選擇的名單"
L["BUTTON_ADMIN_STOPLOAD1"] = "停止載入"
L["BUTTON_ADMIN_STOPLOAD2"] = "放棄載入名單"

L["LOAD"] = "載入"

L["SAVED_ROSTER"]         = "儲存名單為 '%s'"
L["ADMIN_DIFFERENCES"]    = "%d 個成員不在目前名單"
L["NO_ROSTER_NAME_GIVEN"] = "沒有該名稱的名單"
L["NO_ROSTER_CALLED"]     = "儲存的名單中沒有 '%s'"

-- Item Checker
L["CHECK_TITLE"] = "Z-Perl 物品確認"

L["CHECK_NAME"] = "名稱"

L["CHECK_DROPITEMTIP1"]         = "拖放物品"
L["CHECK_DROPITEMTIP2"]         = "物品項目可以投入這個框架來增加詢問項目列表 \r您可以使用 /raitem 指令將物品新增到此處以供未來使用"
L["CHECK_QUERY_DESC1"]          = "發送詢問"
L["CHECK_QUERY_DESC2"]          = "執行所有選定項目檢查 (/raitem)\r發送檢查訊息並獲得目前團隊的抵抗藥水和藥劑資訊"
L["CHECK_LAST_DESC1"]           = "上一次要求"
L["CHECK_LAST_DESC2"]           = "再次確認上一次要求搜尋檢查的物品"
L["CHECK_ALL_DESC1"]            = "全部"
L["CHECK_ALL_DESC2"]            = "確認所有物品"
L["CHECK_NONE_DESC1"]           = "無"
L["CHECK_NONE_DESC2"]           = "不選定任何物品"
L["CHECK_DELETE_DESC1"]         = "刪除"
L["CHECK_DELETE_DESC2"]         = "移除列表中所有指定的物品"
L["CHECK_REPORT_DESC1"]         = "回報"
L["CHECK_REPORT_DESC2"]         = "顯示所選擇的報告訊息到團隊頻道"
L["CHECK_REPORT_WITH_DESC1"]    = "有攜帶"
L["CHECK_REPORT_WITH_DESC2"]    = "回報隊員有攜帶的物品 (或 沒有的物品裝備) 訊息到團隊頻道."
L["CHECK_REPORT_WITHOUT_DESC1"] = "沒有攜帶"
L["CHECK_REPORT_WITHOUT_DESC2"] = "回報隊員沒有攜帶的物品 (或 已有的物品裝備) 訊息到團隊頻道"
L["CHECK_SCAN_DESC1"]           = "掃描"
L["CHECK_SCAN_DESC2"]           = "將檢查在團隊範圍內所有人, 看他們是否有裝備安排的物品和註名在玩家名單中. 請所有人盡量接近 (10 碼) 距離接受檢查."
L["CHECK_SCANSTOP_DESC1"]       = "停止掃描"
L["CHECK_SCANSTOP_DESC2"]       = "停止掃描所選擇的物品玩家裝備狀態"
L["CHECK_REPORTPLAYER_DESC1"]   = "報告玩家狀態"
L["CHECK_REPORTPLAYER_DESC2"]   = "回報所選擇的玩家物品或狀態細節到團隊頻道"

L["CHECK_BROKEN"]               = "損壞度"
L["CHECK_REPORT_DURABILITY"]    = "團隊平均耐久度: %d%% 及 %d 隊員共計 %d 裝備損壞"
L["CHECK_REPORT_PDURABILITY"]   = "%s's 耐久度: %d%% 與 %d 物品損壞"
L["CHECK_REPORT_RESISTS"]       = "團隊平均抗性: %d 火焰, %d 自然, %d 冰霜, %d 暗影, %d 秘法"
L["CHECK_REPORT_PRESISTS"]      = "%s's 抗性: %d 火焰, %d 自然, %d 冰霜, %d 暗影, %d 秘法"
L["CHECK_REPORT_WITH"]          = " - 有: "
L["CHECK_REPORT_WITHOUT"]       = " - 沒有: "
L["CHECK_REPORT_WITH_EQ"]       = " - 有 (或 沒有裝備): "
L["CHECK_REPORT_WITHOUT_EQ"]    = " - 沒有 (或 已裝備): "
L["CHECK_REPORT_EQUIPED"]       = " : 裝備: "
L["CHECK_REPORT_NOTEQUIPED"]    = " : 沒有裝備: "
L["CHECK_REPORT_ALLEQUIPED"]    = "大家有 %s 裝備"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "大家有 %s 裝備, 但 %d 隊員在離線狀態"
L["CHECK_REPORT_PITEM"]         = "%s 有 %d %s 庫存量"
L["CHECK_REPORT_PEQUIPED"]      = "%s 有 %s 裝備"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s 沒有 %s 裝備"
L["CHECK_REPORT_DROPDOWN"]      = "輸出頻道"
L["CHECK_REPORT_DROPDOWN_DESC"] = "選擇物品確認結果輸出的頻道"

L["CHECK_REPORT_WITHSHORT"]       = " : %d 有"
L["CHECK_REPORT_WITHOUTSHORT"]    = " : %d 沒有"
L["CHECK_REPORT_EQUIPEDSHORT"]    = " : %d 裝備"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = "： %d 沒裝備"
L["CHECK_REPORT_OFFLINE"]         = " : %d 離線"
L["CHECK_REPORT_TOTAL"]           = " : %d 物品總計"
L["CHECK_REPORT_NOTSCANNED"]      = " : %d 未經檢查"

L["CHECK_LASTINFO"] = "最後接受資訊： %s 之前"

L["CHECK_AVERAGE"] = "平均"
L["CHECK_TOTALS"]  = "總計"
L["CHECK_EQUIPED"] = "裝備"

L["CHECK_SCAN_MISSING"] = "掃描檢查玩家物品 (%d 尚未掃描)"

L["REAGENTS"] = {
	PRIEST = "神聖蠟燭",
	MAGE = "魔粉",
	DRUID = "野生棘根草",
	SHAMAN = "十字章",
	WARLOCK = "靈魂碎片",
	PALADIN = "神聖印記",
	ROGUE = "閃光粉"
}

L["CHECK_REAGENTS"] = "施法需要物品"

-- Roster Text
L["ROSTERTEXT_TITLE"]         = ZPerl.ShortProductName.." 名單字串"
L["ROSTERTEXT_GROUP"]         = "小隊 %d"
L["ROSTERTEXT_GROUP_DESC"]    = "使用名稱從小隊 %d"
L["ROSTERTEXT_SAMEZONE"]      = "只在相同區域"
L["ROSTERTEXT_SAMEZONE_DESC"] = "只包括和自己一樣區域的玩家名字"
L["ROSTERTEXT_HELP"]          = "按下 Ctrl-C 來複製文字到剪貼板"
L["ROSTERTEXT_TOTAL"]         = "總計：%d"
L["ROSTERTEXT_SETN"]          = "%d 人"
L["ROSTERTEXT_SETN_DESC"]     = "自動選擇小隊為一個 %d 人團隊"
L["ROSTERTEXT_TOGGLE"]        = "切換"
L["ROSTERTEXT_TOGGLE_DESC"]   = "切換選取的小隊"
L["ROSTERTEXT_SORT"]          = "排序"
L["ROSTERTEXT_SORT_DESC"]     = "以名稱排序替代隊伍 + 名稱"
