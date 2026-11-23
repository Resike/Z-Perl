-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "zhTW" then return end

local L = ZPerl.L

L["TOOLTIP_ASSISTING"] = "正在協助的玩家："
L["TOOLTIP_HEALERS"]   = "以我為目標的治療者："
L["TOOLTIP_ALLONME"]   = "以我為目標的所有人："
L["TOOLTIP_ENEMYONME"] = "以我為目標的敵對者："
L["TOOLTIP_HELP"]      = "點擊開啟即時觀察"
L["TOOLTIP_PET"]       = "%s的寵物"

L["BUTTON_TOGGLE_LABELS"]    = "顯示坦克標籤"
L["BUTTON_TOGGLE_MTTARGETS"] = "顯示MT目標的目標"
L["BUTTON_TOGGLE_SHOWMT"]    = "開關是否顯示主坦克"
L["BUTTON_HELPER_PIN"]       = "固定視窗位置"

L["XS_TARGET"] = "%s 的目標"
L["NO_TARGET"] = "沒有目標"

L["TITLE_MT_LONG"]       = "MT 目標"
L["TITLE_WARRIOR_LONG"]  = "戰士目標"
L["TITLE_WARRIOR_SHORT"] = "坦克"

L["HELPER_NEEDPROMOTE"] = "你必須接受提升後才能設定主要協助對象"
L["HELPER_MASET"]       = "主要協助對象設為 %s "
L["HELPER_MACLEAR"]     = "主要協助對象 |c00FF0000已清除！"
L["HELPER_MAREMOVED"]   = "坦克列表中沒有找到主要協助 %s － 移除！"
L["HELPER_MAREMOTESET"] = "%s 分配主要協助對象是 %s"

L["HELPER_FINDFOUND"]   = "使用 FIND 來搜尋適合的目標. ('|c00007F00/zphelper find|r' 來清除)。"
L["HELPER_FINDCLEARED"] = "Find |c00FF0000已清除！|r"
L["HELPER_FINDSET"]     = "Find 設置為 %s. ('|c00007F00/zphelper find|r' 來清除)。"

L["AGGRO_PLAYER"]  = "－獲得仇恨－"
L["AGGRO_PET"]     = "－寵物獲得仇恨－"
L["AGGRO_DRAGTIP"] = "拖曳以移動'獲得仇恨'警告訊息的位置"

L["TITLE_MT_SHORT"] = "MT"
