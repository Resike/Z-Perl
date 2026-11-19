-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "zhCN" then return end

local L = ZPerl.L

L["ADMIN_TITLE"] = "Z-Perl 团队管理"

-- Raid Admin
L["BUTTON_ADMIN_PIN"]       = "固定窗口"
L["BUTTON_ADMIN_LOCKOPEN"]  = "窗口始终打开"
L["BUTTON_ADMIN_SAVE1"]     = "保存名单"
L["BUTTON_ADMIN_SAVE2"]     = "以指定的名字保存当前的队伍结构。如果未输入名字则以当前时间为名。"
L["BUTTON_ADMIN_LOAD1"]     = "载入名单"
L["BUTTON_ADMIN_LOAD2"]     = "载入所选择的名单。所保存的名单中的任何团队成员如果已经不在团队中，则以相同职业的代之。"
L["BUTTON_ADMIN_DELETE1"]   = "删除名单"
L["BUTTON_ADMIN_DELETE2"]   = "删除选选择的名单"
L["BUTTON_ADMIN_STOPLOAD1"] = "停止载入"
L["BUTTON_ADMIN_STOPLOAD2"] = "放弃载入名单"

L["LOAD"] = "载入"

L["SAVED_ROSTER"]         = "保存名单为 '%s'"
L["ADMIN_DIFFERENCES"]    = "%d 个成员不在当前名单"
L["NO_ROSTER_NAME_GIVEN"] = "没有该名字的名单"
L["NO_ROSTER_CALLED"]     = "保存的名单中没有 '%s'"

-- Item Checker
L["CHECK_TITLE"] = "Z-Perl 物品检查"

L["CHECK_NAME"] = "名称"

L["CHECK_DROPITEMTIP1"]         = "拖放物品"
L["CHECK_DROPITEMTIP2"]         = "可以拖放到此框并加入查询序列的的物品\r也可以使用命令/raitem添加物品到该列表"
L["CHECK_QUERY_DESC1"]          = "查询"
L["CHECK_QUERY_DESC2"]          = "使用/raitem命令检查所有勾选的物品\r总是查询当前耐久度、抗性和药剂信息"
L["CHECK_LAST_DESC1"]           = "最后"
L["CHECK_LAST_DESC2"]           = "重新勾选最后查询的物品"
L["CHECK_ALL_DESC1"]            = "全部"
L["CHECK_ALL_DESC2"]            = "勾选所有物品"
L["CHECK_NONE_DESC1"]           = "无"
L["CHECK_NONE_DESC2"]           = "不勾选所有物品"
L["CHECK_DELETE_DESC1"]         = "删除"
L["CHECK_DELETE_DESC2"]         = "从列表中永久删除所有勾选的物品"
L["CHECK_REPORT_DESC1"]         = "报告"
L["CHECK_REPORT_DESC2"]         = "生成报告并发送到团队频道"
L["CHECK_REPORT_WITH_DESC1"]    = "有"
L["CHECK_REPORT_WITH_DESC2"]    = "报告有该物品（或已穿上指定装备）的人到团队频道"
L["CHECK_REPORT_WITHOUT_DESC1"] = "无"
L["CHECK_REPORT_WITHOUT_DESC2"] = "报告无该物品（或未穿上指定装备）的人到团队频道"
L["CHECK_SCAN_DESC1"]           = "扫描"
L["CHECK_SCAN_DESC2"]           = "检查在观察范围内（10码）的所有团队成员是否已穿上该装备并在列表中显示出来。"
L["CHECK_SCANSTOP_DESC1"]       = "停止扫描"
L["CHECK_SCANSTOP_DESC2"]       = "停止扫描所选玩家装备"
L["CHECK_REPORTPLAYER_DESC1"]   = "报告玩家情况"
L["CHECK_REPORTPLAYER_DESC2"]   = "将所选玩家的装备情况生产报告并发布到团队频道"

L["CHECK_BROKEN"]               = "损坏"
L["CHECK_REPORT_DURABILITY"]    = "平均团队耐久度：%d%%，%d 个人，总共有 %d 件损坏的装备"
L["CHECK_REPORT_PDURABILITY"]   = "%s的耐久度：%d%%，有%d件损坏的装备"
L["CHECK_REPORT_RESISTS"]       = "平均团队抗性： %d 火焰, %d 自然, %d 冰霜, %d 暗影, %d 奥术"
L["CHECK_REPORT_PRESISTS"]      = "%s的抗性：%d 火焰, %d 自然, %d 冰霜, %d 暗影, %d 奥术"
L["CHECK_REPORT_WITH"]          = " - 有："
L["CHECK_REPORT_WITHOUT"]       = " - 无："
L["CHECK_REPORT_WITH_EQ"]       = " - 有 (或已装备)："
L["CHECK_REPORT_WITHOUT_EQ"]    = " - 无 (或未装备)："
L["CHECK_REPORT_EQUIPED"]       = " : 已装备："
L["CHECK_REPORT_NOTEQUIPED"]    = " ：未装备："
L["CHECK_REPORT_ALLEQUIPED"]    = "所有人都已装备 %s"
L["CHECK_REPORT_ALLEQUIPEDOFF"] = "所有人都已装备 %s，除了%d个离线成员"
L["CHECK_REPORT_PITEM"]         = "%s 背包里有 %d %s"
L["CHECK_REPORT_PEQUIPED"]      = "%s 已装备 %s"
L["CHECK_REPORT_PNOTEQUIPED"]   = "%s 没有装备 %s"
L["CHECK_REPORT_DROPDOWN"]      = "发布频道"
L["CHECK_REPORT_DROPDOWN_DESC"] = "选择物品检查结果的发布频道"

L["CHECK_REPORT_WITHSHORT"]       = "：%d 人有"
L["CHECK_REPORT_WITHOUTSHORT"]    = "：%d 人无"
L["CHECK_REPORT_EQUIPEDSHORT"]    = "：%d 人已装备"
L["CHECK_REPORT_NOTEQUIPEDSHORT"] = "：%d 人未装备"
L["CHECK_REPORT_OFFLINE"]         = "：%d 人离线"
L["CHECK_REPORT_TOTAL"]           = "：总共 %d 件物品"
L["CHECK_REPORT_NOTSCANNED"]      = "：%d 人未检查到"

L["CHECK_LASTINFO"] = "%s 以前接收到的最新数据"

L["CHECK_AVERAGE"] = "平均"
L["CHECK_TOTALS"]  = "总共"
L["CHECK_EQUIPED"] = "已装备"

L["CHECK_SCAN_MISSING"] = "正在扫描观察范围内的玩家的装备。(%d 人未扫描到)"

L["REAGENTS"] = {
	PRIEST = "神圣蜡烛",
	MAGE = "魔粉",
	DRUID = "野生棘根草",
	SHAMAN = "十字章",
	WARLOCK = "灵魂碎片",
	PALADIN = "神圣符印",
	ROGUE = "闪光粉"
}

L["CHECK_REAGENTS"] = "药剂"

-- Roster Text
L["ROSTERTEXT_TITLE"]         = ZPerl.ShortProductName.." 名单文字"
L["ROSTERTEXT_GROUP"]         = "小队 %d"
L["ROSTERTEXT_GROUP_DESC"]    = "使用小队 %d 的名字"
L["ROSTERTEXT_SAMEZONE"]      = "仅显示相同区域"
L["ROSTERTEXT_SAMEZONE_DESC"] = "仅包含和你处于同一地区的玩家的名字"
L["ROSTERTEXT_HELP"]          = "按Ctrl-C键将文本拷贝至剪贴板"
L["ROSTERTEXT_TOTAL"]         = "总计: %d"
L["ROSTERTEXT_SETN"]          = "%d 人"
L["ROSTERTEXT_SETN_DESC"]     = "在 %d 人团队中自动选择小队"
L["ROSTERTEXT_TOGGLE"]        = "反选"
L["ROSTERTEXT_TOGGLE_DESC"]   = "反选已选定的小队"
L["ROSTERTEXT_SORT"]          = "排序"
L["ROSTERTEXT_SORT_DESC"]     = "按名字排序而不按照小队+名字排序"
