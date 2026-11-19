-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = ZPerl.L

L["RAID_GROUP"]           = "Grupo %d"
L["RAID_TOOLTIP_OFFLINE"] = "Desconectado durante %s"
L["RAID_TOOLTIP_AFK"]     = "AUS durante %s"
L["RAID_TOOLTIP_DND"]     = "NoMolestar durante %s"
L["RAID_TOOLTIP_DYING"]   = "Muerto desde hace %s"

L["RAID_RESSING"]      = " resucitando"
L["RAID_AFK"]          = "AUS"
L["RAID_RESSER_AVAIL"] = "Resurrectores disponibles: "
