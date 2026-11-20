-- License: GNU GPL v3, 29 June 2007
-- English only; other locales use these strings.

if GetLocale() ~= "zhCN" then return end

local L = ZPerl.L

L["AURABL_ENABLE"]      = "启用增益黑名单"
L["AURABL_IMPORT"]      = "从 BetterBlizzFrames 导入"
L["AURABL_IMPORT_DESC"] = "将 BetterBlizzFrames 黑名单中尚未包含的条目添加到此列表。列表中已有的条目不会被修改。需要处于启用状态的 BetterBlizzFrames 插件。"
L["AURABL_IMPORT_NONE"] = "增益黑名单：未找到 BetterBlizzFrames 黑名单（必须启用 BetterBlizzFrames 插件）"
L["AURABL_IMPORTED"]    = "增益黑名单：已从 BetterBlizzFrames 导入 %d 个新法术，%d 个已存在，%d 个已跳过（无有效法术 ID）"
L["AURABL_ADD"]         = "添加"
L["AURABL_ADD_DESC"]    = "法术 ID 或完整法术名称："
L["AURABL_ADDED"]       = "增益黑名单：已添加 %s (%d)"
L["AURABL_EXISTS"]      = "增益黑名单：%s (%d) 已在列表中"
L["AURABL_NOTFOUND"]    = "增益黑名单：未找到法术“%s” - 请尝试输入法术 ID"
L["AURABL_COL_NAME"]    = "法术名称"
L["AURABL_COL_ID"]      = "法术 ID"
L["AURABL_REMOVE"]      = "移除"
L["AURABL_COUNT"]       = "共 %d 个法术"
L["AURABL_SPELL"]       = "法术 %d"
