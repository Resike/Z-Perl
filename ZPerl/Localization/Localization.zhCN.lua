-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "zhCN" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFF右键点击|r拖动图标"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r  Z-Perl 内存占用"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Shift|r  Z-Perl 启用以来的内存占用"

L["MINIMENU_OPTIONS"]    = "选项"
L["MINIMENU_ASSIST"]     = "显示助手窗口"
L["MINIMENU_CASTMON"]    = "显示施法监控窗口"
L["MINIMENU_RAIDAD"]     = "显示团队管理窗口"
L["MINIMENU_ITEMCHK"]    = "显示物品检查窗口"
L["MINIMENU_ROSTERTEXT"] = "名单文字"

L["TYPE_NOT_SPECIFIED"] = "未指定"
L["TYPE_PET"]           = "宠物"
L["TYPE_BOSS"]          = "首领"
L["TYPE_RAREPLUS"]      = "银英"
L["TYPE_ELITE"]         = "精英"
L["TYPE_RARE"]          = "稀有"

-- Zones
L["LOC_ZONE_BLACK_TEMPLE"]          = "黑暗神殿"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "海加尔峰"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "冰冠堡垒"
L["LOC_ZONE_KARAZHAN"]              = "卡拉赞"
L["LOC_ZONE_RUBY_SANCTUM"]          = "红玉圣殿"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "毒蛇神殿"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "太阳之井高地"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "十字军的试炼"
L["LOC_ZONE_ULDUAR"]                = "奥杜尔"

-- Status
L["LOC_DEAD"]         = "死亡"
L["LOC_GHOST"]        = "幽灵"
L["LOC_OFFLINE"]      = "离线"
L["LOC_RESURRECTED"]  = "已被复活"
L["LOC_SS_AVAILABLE"] = "灵魂已保存"
L["LOC_UPDATING"]     = "更新中"
L["LOC_ACCEPTEDRES"]  = "已接受"
L["RAID_GROUPSHORT"]  = "%d 队"

L["LOC_NONEWATCHED"] = "无监控"

L["LOC_STATUSTIP"]     = "状态提示: "
L["LOC_STATUSTIPLIST"] = {
	HOT = "持续治疗",
	AGGRO = "你仇恨过高了",
	HEAL = "正被治疗",
	SHIELD = "盾"
}

L["LOC_LARGENUMTAG"]    = "万"
L["LOC_HUGENUMTAG"]     = "亿"
L["LOC_VERYHUGENUMTAG"] = "兆"

BINDING_HEADER_ZPERL                  = "Z-Perl 快捷键"
BINDING_NAME_ZPERL_TOGGLERAID         = "切换团队窗口"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "切换团队宠物窗口"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "切换选项窗"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "切换增益/减益/无"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "切换显示可施加/解除的增益/减益魔法"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "切换距离侦测"

L["KEY_NOTICE_RAID_BUFFANY"]      = "显示所有的增益/减益魔法"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "只显示可施放/解除的的增益/减益魔法"
L["KEY_NOTICE_RAID_BUFFS"]        = "显示团队增益魔法"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "显示团队减益魔法"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "不显示团队增益/减益魔法"

L["DRAGHINT1"] = "|c00FFFFFF点击|r 改变窗口比例"
L["DRAGHINT2"] = "|c00FFFFFFShift+单击|r 改变窗口大小"

L["RAID_TOOLTIP_WITHBUFF"]    = "有该buff的成员： (%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "无该buff的成员： (%s)"
