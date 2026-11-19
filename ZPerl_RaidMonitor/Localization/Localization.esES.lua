-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = ZPerl.L

L["RAID_MONITOR_TITLE"]  = "Monitor Casteo |c00A04040(BETA)|r"
L["RAID_MONITOR_TOTALS"] = "Alternar visualización de Totales y Estadísticas"

L["RAID_MONITOR_STATS_RAID_MANA"]   = "Mana Banda"
L["RAID_MONITOR_STATS_HIGH_MANA"]   = "Mana Alto"
L["RAID_MONITOR_STATS_LOW_MANA"]    = "Mana Bajo"
L["RAID_MONITOR_STATS_RAID_HEALTH"] = "Salud Banda"

L["MONITOR_LEFTCLICK"]   = "|c00FFFFFFClick izquierdo|r para %s"
L["MONITOR_RIGHTCLICK"]  = "|c00FFFFFFClick derecho|r para %s"
L["MONITOR_CLICKTARGET"] = "|c00FFFF80objetivo|r"

L["MONITOR_INNERVATE"] = "Enervar"
L["MONITOR_MANATIDE"]  = "Totem de Marea de maná"
