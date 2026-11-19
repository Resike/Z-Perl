-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

if GetLocale() ~= "zhTW" then return end

local L = ZPerl.L

L["MINIMAP_HELP2"] = "|c00FFFFFF右鍵拖動|r 移動此圖標"
L["MINIMAP_HELP5"] = "|c00FFFFFFAlt|r 顯示 Z-Perl 記憶體用量"
L["MINIMAP_HELP6"] = "|c00FFFFFF+Shift|r 顯示 Z-Perl 記憶體使用明細"

L["MINIMENU_OPTIONS"]    = "功能設定"
L["MINIMENU_ASSIST"]     = "顯示協助框架"
L["MINIMENU_CASTMON"]    = "顯示施法監視"
L["MINIMENU_RAIDAD"]     = "顯示團隊幫手"
L["MINIMENU_ITEMCHK"]    = "顯示物品確認"
L["MINIMENU_ROSTERTEXT"] = "名單文字"

L["TYPE_NOT_SPECIFIED"] = "未指定"
L["TYPE_PET"]           = "寵物"
L["TYPE_BOSS"]          = "首領"
L["TYPE_RAREPLUS"]      = "稀有精英+"
L["TYPE_ELITE"]         = "精英"
L["TYPE_RARE"]          = "稀有"

-- Zones
L["LOC_ZONE_BLACK_TEMPLE"]          = "黑暗神廟"
L["LOC_ZONE_EYE_OF_ETERNITY"]       = "永恆之眼"
L["LOC_ZONE_HYJAL_SUMMIT"]          = "海加爾山"
L["LOC_ZONE_ICECROWN_CITADEL"]      = "冰冠城塞"
L["LOC_ZONE_KARAZHAN"]              = "卡拉贊"
L["LOC_ZONE_NAXXRAMAS"]             = "納克薩瑪斯"
L["LOC_ZONE_OBSIDIAN_SANCTUM"]      = "黑曜聖所"
L["LOC_ZONE_RUBY_SANCTUM"]          = "晶紅聖所"
L["LOC_ZONE_SERPENTSHRINE_CAVERN"]  = "毒蛇神殿洞穴"
L["LOC_ZONE_SUNWELL_PLATEAU"]       = "太陽之井高地"
L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"] = "十字軍試煉"
L["LOC_ZONE_ULDUAR"]                = "奧杜亞"

-- Status
L["LOC_DEAD"]         = "死亡"
L["LOC_GHOST"]        = "靈魂"
L["LOC_OFFLINE"]      = "離線"
L["LOC_RESURRECTED"]  = "復活"
L["LOC_SS_AVAILABLE"] = "靈魂保存"
L["LOC_UPDATING"]     = "更新中"
L["LOC_ACCEPTEDRES"]  = "已接受"
L["RAID_GROUPSHORT"]  = "%d隊"

L["LOC_NONEWATCHED"] = "無監看"

L["LOC_STATUSTIP"]     = "狀態提示："
L["LOC_STATUSTIPLIST"] = {
	HOT = "持續治療",
	AGGRO = "敵方目標",
	HEAL = "已受治療",
	SHIELD = "已上盾"
}

L["LOC_LARGENUMTAG"]    = "萬"
L["LOC_HUGENUMTAG"]     = "億"
L["LOC_VERYHUGENUMTAG"] = "兆"

BINDING_HEADER_ZPERL                  = "Z-Perl 快捷鍵設定"
BINDING_NAME_ZPERL_TOGGLERAID         = "開/關團隊視窗"
BINDING_NAME_ZPERL_TOGGLERAIDPETS     = "切換是否使用團隊寵物"
BINDING_NAME_ZPERL_TOGGLEOPTIONS      = "開/關設定視窗"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE     = "切換 增益/減益/無"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "切換顯示可施加/解除的增益/減益效果"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER  = "切換距離偵測開啟/關閉"

L["KEY_NOTICE_RAID_BUFFANY"]      = "顯示所有 增益/減益效果"
L["KEY_NOTICE_RAID_BUFFCURECAST"] = "只有 可施加/可解除 的增益/減益效果顯示"
L["KEY_NOTICE_RAID_BUFFS"]        = "顯示團隊的 增益效果"
L["KEY_NOTICE_RAID_DEBUFFS"]      = "顯示團隊的 減益效果"
L["KEY_NOTICE_RAID_NOBUFFS"]      = "不顯示團隊的 增益效果"

L["DRAGHINT1"] = "|c00FFFFFF點擊|r 調整視窗比例"
L["DRAGHINT2"] = "|c00FFFFFFShift+點擊|r 重置視窗尺寸"

L["RAID_TOOLTIP_WITHBUFF"]    = "有此 buff 的：(%s)"
L["RAID_TOOLTIP_WITHOUTBUFF"] = "沒有此 buff 的：(%s)"
