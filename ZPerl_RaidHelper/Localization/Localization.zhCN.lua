-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "zhCN" then return end

local L = ZPerl.L

L["TOOLTIP_ASSISTING"] = "正在协助的玩家："
L["TOOLTIP_HEALERS"]   = "以我为目标的治疗者："
L["TOOLTIP_ALLONME"]   = "以我为目标的所有人："
L["TOOLTIP_ENEMYONME"] = "以我为目标的敌对者："
L["TOOLTIP_HELP"]      = "点击打开实时观察"
L["TOOLTIP_PET"]       = "%s的宠物"

L["BUTTON_TOGGLE_LABELS"]    = "显示坦克标签"
L["BUTTON_TOGGLE_MTTARGETS"] = "显示MT目标的目标"
L["BUTTON_TOGGLE_SHOWMT"]    = "显示主坦克"
L["BUTTON_HELPER_PIN"]       = "固定窗口"

L["XS_TARGET"] = "%s的目标"
L["NO_TARGET"] = "没有目标"

L["TITLE_MT_LONG"]       = "MT 目标"
L["TITLE_WARRIOR_LONG"]  = "战士目标"
L["TITLE_WARRIOR_SHORT"] = "坦克"

L["HELPER_NEEDPROMOTE"] = "你必须获得提升后才能设定主要协助对象"
L["HELPER_MASET"]       = "主要协助对象设为 %s"
L["HELPER_MACLEAR"]     = "主要协助对象 |c00FF0000已清除!"
L["HELPER_MAREMOVED"]   = "坦克列表中没有找到主要协助 %s - 移除!"
L["HELPER_MAREMOTESET"] = "%s 分配主要协助对象是 %s"

L["HELPER_FINDFOUND"]   = "使用 FIND 来搜寻适合的目标. ('|c00007F00/zphelper find|r' 可清除)."
L["HELPER_FINDCLEARED"] = "Find |c00FF0000已清除!|r"
L["HELPER_FINDSET"]     = "Find 设置为 %s. ('|c00007F00/zphelper find|r' 可清除)."

L["AGGRO_PLAYER"]  = "- 获得仇恨 -"
L["AGGRO_PET"]     = "- 宠物获得仇恨 -"
L["AGGRO_DRAGTIP"] = "移动仇恨警告位置"
