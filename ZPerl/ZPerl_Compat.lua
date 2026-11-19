-- Z-Perl - API compatibility shims
--
-- The Forever client is Classic based, but Blizzard has said it will carry the
-- retail (Midnight) addon restrictions. Retail also removed a number of old
-- globals that the Z-Perl code base uses as table keys at load time
-- (GetSpellInfo, UnitAura, GetItemInfo ...). If Forever ever does the same, the
-- shims below keep the addon loading. Each one is only defined when the client
-- has removed the original and provides the modern replacement.

-- The addon table. Every function and shared table is a field of ZPerl, or of the sub-table of its module or raid
-- tool (ZPerl.Party.OnLoad). Frames and templates keep the ZPerl_ prefix because the engine owns their global names.
---@diagnostic disable-next-line: create-global
ZPerl = {}
for _, module in ipairs({"ArcaneBar", "AuraBlacklist", "CustomHighlight", "Party", "PartyPet", "Player", "PlayerBuffs",
	"PlayerPet", "Raid", "RaidPets", "Target", "TargetTarget", "RaidAdmin", "RaidHelper", "RaidMonitor"}) do
	ZPerl[module] = {}
end

-- ZPerl.L: the locale strings of Z-Perl and its raid tools, by short ID (L["RAID_GROUP"]). Each Localization.lua
-- fills it with English, then the Localization.<locale>.lua files of the client's locale overwrite what they
-- translate. A key nobody defines reads as its own name, so a missing string shows up instead of erroring.
-- Use rawget(ZPerl.L, key) to test whether a key exists.
ZPerl.L = setmetatable({}, {__index = function(_, key) return key end})

-- ZPerl.IsRetail: the retail (Mainline) client. Retail has classes, class resource bars, spec-based dispels
-- and atlas ready-check icons that the Classic-based clients do not; everything else is feature-detected.
ZPerl.IsRetail = WOW_PROJECT_ID ~= nil and WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
-- ZPerl.IsMists: Mists of Pandaria Classic, which has class resource frames and spec-based dispels of its own
ZPerl.IsMists = WOW_PROJECT_ID ~= nil and WOW_PROJECT_MISTS_CLASSIC ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
-- ZPerl.IsBCC: Burning Crusade Classic (TBC Anniversary), which has the TBC class spells and no Mists ones
ZPerl.IsBCC = WOW_PROJECT_ID ~= nil and WOW_PROJECT_BURNING_CRUSADE_CLASSIC ~= nil and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
-- ZPerl.IsForever: the Forever client (WOW_PROJECT_CAMELOT, interface 16001), Classic based with the retail addon
-- restrictions. Not feature-detected: Classic Era has the same secret-value APIs (issecretvalue, C_Secrets, UnitHealthPercent).
ZPerl.IsForever = WOW_PROJECT_ID ~= nil and WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT

-- Frames can invoke their highlight handlers even when Forever has prevented
-- the optional full highlight module from completing. Create the manager early
-- and give it harmless fallbacks; ZPerl_Highlight.lua replaces these methods
-- with the complete implementation when it loads successfully.
if (not ZPerl_Highlight) then
	---@diagnostic disable-next-line: create-global
	ZPerl_Highlight = CreateFrame("Frame", "ZPerl_Highlight")
	local function NoOp(...) end
	ZPerl_Highlight.Register = NoOp
	ZPerl_Highlight.SetHighlight = NoOp
	ZPerl_Highlight.RemoveHighlight = NoOp
	ZPerl_Highlight.ClearAll = NoOp
	ZPerl_Highlight.Add = NoOp
	ZPerl_Highlight.Remove = NoOp
	ZPerl_Highlight.TooltipInfo = NoOp
end

-- ZPerl.SpellName(spellID)
-- Spell name for use as a table key. Several Classic spell IDs are missing from
-- the retail spell database; the lookup then returns nil and "[nil] = true" in a
-- table constructor aborts the whole file (which is how ZPerl.lua died on retail,
-- taking every later ZPerl_ function with it). A unique placeholder that can never
-- match a real aura name is returned instead.
function ZPerl.SpellName(spellID)
	local name
	if (C_Spell and C_Spell.GetSpellInfo) then
		local info = C_Spell.GetSpellInfo(spellID)
		name = info and info.name
	elseif (GetSpellInfo) then
		name = GetSpellInfo(spellID)
	end
	return name or ("ZPerl_NoSpell_"..tostring(spellID))
end

if (not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo) then
	GetSpellInfo = function(spell)
		local info = C_Spell.GetSpellInfo(spell)
		if (info) then
			return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID, info.originalIconID
		end
	end
end

if (not GetItemInfo and C_Item and C_Item.GetItemInfo) then
	GetItemInfo = C_Item.GetItemInfo
end

if (not GetItemCount and C_Item and C_Item.GetItemCount) then
	GetItemCount = C_Item.GetItemCount
end

if (not IsAddOnLoaded and C_AddOns and C_AddOns.IsAddOnLoaded) then
	IsAddOnLoaded = C_AddOns.IsAddOnLoaded
end

if (not GetAddOnMetadata and C_AddOns and C_AddOns.GetAddOnMetadata) then
	GetAddOnMetadata = C_AddOns.GetAddOnMetadata
end

if (not GetAddOnInfo and C_AddOns and C_AddOns.GetAddOnInfo) then
	GetAddOnInfo = C_AddOns.GetAddOnInfo
end

if (not LoadAddOn and C_AddOns and C_AddOns.LoadAddOn) then
	LoadAddOn = C_AddOns.LoadAddOn
end

if (not EnableAddOn and C_AddOns and C_AddOns.EnableAddOn) then
	EnableAddOn = C_AddOns.EnableAddOn
end

if (not DisableAddOn and C_AddOns and C_AddOns.DisableAddOn) then
	DisableAddOn = C_AddOns.DisableAddOn
end
