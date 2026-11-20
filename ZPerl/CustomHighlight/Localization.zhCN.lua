-- License: GNU GPL v3, 29 June 2007
-- English only; other locales use these strings.

if GetLocale() ~= "zhCN" then return end

local L = ZPerl.L

L["ZONE"]      = "区域"
L["REMOVE_ZONE"] = "移除区域"
L["Remove the shown zone and all its spells from the list, after a confirmation."] = "确认后从列表中移除当前显示的区域及其所有法术。"
L["Add a zone (its name as the game shows it)"] = "添加区域（需与游戏内显示的区域名一致）"
L["Add zone"] = "添加区域"
L["Add a zone with an empty list and show it. The name must match the game's zone name exactly."] = "添加一个包含空列表的新区域并显示它。名称必须与游戏内的区域名称完全一致。"
L["Current zone"] = "当前区域"
L["Add the zone you are in (or show it, when it is listed)."] = "添加你当前所在的区域（若已在列表中则直接显示它）。"
L["Add a debuff to this zone (spell ID)"] = "向此区域添加减益（法术 ID）"
L["Add spell"] = "添加技能"
L["Add a debuff by its spell ID. A raid member with that exact spell shows its icon. An exact name works only for spells the game can look up by name, mostly ones you know, so boss debuffs need their ID."] = "通过法术 ID 添加减益。当团队成员中了该精确法术时，框体上会显示其图标。完整法术名称仅对游戏能直接按名称检索的法术有效（通常为玩家自身已学会的法术），因此首领技能减益必须填写其法术 ID。"

L["Spell %d"] = "法术 %d"
L["%d spells in %s"] = "%d 个法术位于 %s"
L["Add a zone to start a list."] = "添加一个区域以开始创建列表。"

L["Custom highlights: no spell %s."] = "自定义高亮：未找到法术 %s。"
L["Custom highlights: no spell %s by name; use its spell ID."] = "自定义高亮：无法按名称找到法术 %s，请改用其法术 ID。"
L["Custom highlights: %s (%d) is already in %s."] = "自定义高亮：%s (%d) 已存在于 %s 中。"

L["Name"] = "名称"
L["Spell ID"] = "技能 ID"
L["Reset to defaults"] = "重置为默认"
L["Put back the default zones and spells of this layout's list, after a confirmation. Zones and spells you added are lost."] = "确认后将当前布局的列表恢复为默认的区域和法术。你自行添加的区域和法术将会丢失。"
L["Reset the custom highlight list of this layout to the default zones and spells? Zones and spells you added are lost."] = "确定要将当前布局的自定义高亮列表恢复为默认的区域和法术吗？你自行添加的区域和法术将会丢失。"
L["Remove"] = "移除"
L["Remove this spell from the zone's list."] = "从该区域的列表中移除此法术。"
L["Remove %s and its %d spells from the custom highlight list?"] = "确定要从自定义高亮列表中移除“%s”及其包含的 %d 个法术吗？"