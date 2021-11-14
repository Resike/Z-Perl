-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC
local IsBCClassic = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

XPerl_ProductName		= "|cFFD00000Z-Perl|r UnitFrames"
XPerl_ShortProductName	= "|cFFD00000Z-Perl|r"
XPerl_Author			= "|cFFFF8080Resike|r"
XPerl_Description		= XPerl_ProductName.." by "..XPerl_Author
XPerl_VersionNumber		= GetAddOnMetadata("ZPerl", "Version")
XPerl_Version			= XPerl_Description.." - "..XPerl_VersionNumber
XPerl_LongDescription	= "UnitFrame replacement for new look Player, Pet, Party, Target, Target's Target, Focus, Raid"
XPerl_ModMenuIcon		= "Interface\\Icons\\INV_Misc_Gem_Pearl_02"

XPERL_MINIMAP_HELP1		= "|c00FFFFFFLeft click|r for Options (and to |c0000FF00unlock frames|r)"
XPERL_MINIMAP_HELP2		= "|c00FFFFFFRight click|r to drag this icon"
XPERL_MINIMAP_HELP3		= "\rReal Raid Members: |c00FFFF80%d|r\rReal Party Members: |c00FFFF80%d|r"
XPERL_MINIMAP_HELP4		= "\rYou are leader of the real party/raid"
XPERL_MINIMAP_HELP5		= "|c00FFFFFFAlt|r for Z-Perl memory usage"
XPERL_MINIMAP_HELP6		= "|c00FFFFFF+Shift|r for Z-Perl memory usage since startup"

XPERL_MINIMENU_OPTIONS	= "Options"
XPERL_MINIMENU_ASSIST	= "Show Assists Frame"
XPERL_MINIMENU_CASTMON	= "Show Casting Monitor"
XPERL_MINIMENU_RAIDAD	= "Show Raid Admin"
XPERL_MINIMENU_ITEMCHK	= "Show Item Checker"
XPERL_MINIMENU_RAIDBUFF	= "Raid Buffs"
XPERL_MINIMENU_ROSTERTEXT="Roster Text"
XPERL_MINIMENU_RAIDSORT	= "Raid Sort"
XPERL_MINIMENU_RAIDSORT_GROUP = "Sort by Group"
XPERL_MINIMENU_RAIDSORT_CLASS = "Sort by Class"

XPERL_TYPE_NOT_SPECIFIED	= "Not specified"
XPERL_TYPE_PET				= PET
XPERL_TYPE_BOSS				= "Boss"
XPERL_TYPE_RAREPLUS 		= "Rare+"
XPERL_TYPE_ELITE			= "Elite"
XPERL_TYPE_RARE				= "Rare"

-- Zones
XPERL_LOC_ZONE_ANTORUS				= "Antorus"
XPERL_LOC_ZONE_BARADIN_HOLD 		= "Baradin Hold"
XPERL_LOC_ZONE_BASTION_OF_TWILIGHT	= "Basion of Twilight"
XPERL_LOC_ZONE_BLACK_TEMPLE			= "Black Temple"
XPERL_LOC_ZONE_BLACKWING_DECENT		= "Blackwing Decent"
XPERL_LOC_ZONE_DRAGONSOUL			= "Dragonsoul"
XPERL_LOC_ZONE_EMERALD_NIGHTMARE	= "Emerald Nightmare"
XPERL_LOC_ZONE_EYE_OF_ETERNITY		= "The Eye of Eternity"
XPERL_LOC_ZONE_FIRELANDS			= "Firelands"
XPERL_LOC_ZONE_HYJAL_SUMMIT			= "Hyjal Summit"
XPERL_LOC_ZONE_ICECROWN_CITADEL		= "Icecrown Citadel"
XPERL_LOC_ZONE_KARAZHAN				= "Karazhan"
XPERL_LOC_ZONE_NAXXRAMAS			= "Naxxramas"
XPERL_LOC_ZONE_NIGHTHOLD			= "Nighthold"
XPERL_LOC_ZONE_OBSIDIAN_SANCTUM		= "The Obsidian Sanctum"
XPERL_LOC_ZONE_RUBY_SANCTUM			= "The Ruby Sanctum"
XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN	= "Serpentshrine Cavern"
XPERL_LOC_ZONE_SUNWELL_PLATEAU		= "Sunwell Plateau"
XPERL_LOC_ZONE_THRONE_OF_FOUR_WINDS = "Throne of Four Winds"
XPERL_LOC_ZONE_TOMB_OF_SARGERAS		= "Tomb of Sargeras"
XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER= "Trial of the Crusader"
XPERL_LOC_ZONE_TRIAL_OF_VALOR		= "Trial of Valor"
XPERL_LOC_ZONE_ULDUAR				= "Ulduar"
--Any zones 4.x and higher can all be localized from EJ, in 5.0, even these above zones are in EJ which means the rest can go bye bye too

-- Status
XPERL_LOC_DEAD		= DEAD			-- "Dead"
XPERL_LOC_GHOST 	= "Ghost"
XPERL_LOC_FEIGNDEATH	= "Feign Death"
XPERL_LOC_FEIGNDEATHSHORT	= "FD"
XPERL_LOC_OFFLINE	= PLAYER_OFFLINE	-- "Offline"
XPERL_LOC_RESURRECTED	= "Resurrected"
XPERL_LOC_SS_AVAILABLE	= "SS Available"
XPERL_LOC_UPDATING	= "Updating"
XPERL_LOC_ACCEPTEDRES	= "Accepted"		-- Res accepted
XPERL_RAID_GROUP	= "Group %d"
XPERL_RAID_GROUPSHORT	= "G%d"

XPERL_LOC_NONEWATCHED	= "none watched"

XPERL_LOC_STATUSTIP = "Status Highlights: " 	-- Tooltip explanation of status highlight on unit
XPERL_LOC_STATUSTIPLIST = {
	HOT = "Heal over Time",
	AGGRO = "Aggro",
	MISSING = "Missing your class' buff",
	HEAL = "Being healed",
	SHIELD = "Shielded"
}

XPERL_OK		= "OK"
XPERL_CANCEL	= "Cancel"

XPERL_LOC_LARGENUMTAG		= "K"
XPERL_LOC_HUGENUMTAG		= "M"
XPERL_LOC_VERYHUGENUMTAG	= "G"

BINDING_HEADER_ZPERL = XPerl_ProductName
BINDING_NAME_ZPERL_TOGGLERAID = "Toggle Raid Windows"
BINDING_NAME_ZPERL_TOGGLERAIDSORT = "Toggle Raid Sort by Class/Group"
BINDING_NAME_ZPERL_TOGGLERAIDPETS = "Toggle Raid Pets"
BINDING_NAME_ZPERL_TOGGLEOPTIONS = "Toggle Options Window"
BINDING_NAME_ZPERL_TOGGLEBUFFTYPE = "Toggle Buffs/Debuffs/none"
BINDING_NAME_ZPERL_TOGGLEBUFFCASTABLE = "Toggle Castable/Curable"
BINDING_NAME_ZPERL_TEAMSPEAKMONITOR = "Teamspeak Monitor"
BINDING_NAME_ZPERL_TOGGLERANGEFINDER = "Toggle Range Finder"

XPERL_KEY_NOTICE_RAID_BUFFANY = "All buffs/debuffs shown"
XPERL_KEY_NOTICE_RAID_BUFFCURECAST = "Only castable/curable buffs or debuffs shown"
XPERL_KEY_NOTICE_RAID_BUFFS = "Raid Buffs shown"
XPERL_KEY_NOTICE_RAID_DEBUFFS = "Raid Debuffs shown"
XPERL_KEY_NOTICE_RAID_NOBUFFS = "No raid buffs shown"

XPERL_DRAGHINT1		= "|c00FFFFFFClick|r to scale window"
XPERL_DRAGHINT2		= "|c00FFFFFFShift+Click|r to resize window"

-- Usage
XPerlUsageNameList	= {XPerl = "Core", XPerl_Player = "Player", XPerl_PlayerPet = "Pet", XPerl_Target = "Target", XPerl_TargetTarget = "Target's Target", XPerl_Party = "Party", XPerl_PartyPet = "Party Pets", XPerl_RaidFrames = "Raid Frames", XPerl_RaidHelper = "Raid Helper", XPerl_RaidAdmin = "Raid Admin", XPerl_TeamSpeak = "TS Monitor", XPerl_RaidMonitor = "Raid Monitor", XPerl_RaidPets = "Raid Pets", XPerl_ArcaneBar = "Arcane Bar", XPerl_PlayerBuffs = "Player Buffs", XPerl_GrimReaper = "Grim Reaper"}
XPERL_USAGE_MEMMAX	= "UI Mem Max: %d"
XPERL_USAGE_MODULES	= "Modules: "
XPERL_USAGE_NEWVERSION	= "*Newer version"
XPERL_USAGE_AVAILABLE	= "%s |c00FFFFFF%s|r is available for download"

XPERL_CMD_MENU		= "menu"
XPERL_CMD_OPTIONS	= "options"
XPERL_CMD_LOCK		= "lock"
XPERL_CMD_UNLOCK	= "unlock"
XPERL_CMD_CONFIG	= "config"
XPERL_CMD_LIST		= "list"
XPERL_CMD_DELETE	= "delete"
XPERL_CMD_HELP		= "|c00FFFF80Usage: |c00FFFFFF/zperl menu | lock | unlock | config list | config delete <realm> <name>"
XPERL_CANNOT_DELETE_CURRENT = "Cannot delete you current config"
XPERL_CONFIG_DELETED		= "Deleted config for %s/%s"
XPERL_CANNOT_FIND_DELETE_TARGET = "Cannot find config to delete (%s/%s)"
XPERL_CANNOT_DELETE_BADARGS = "Please give realm name and player name"
XPERL_CONFIG_LIST		= "Config List:"
XPERL_CONFIG_CURRENT		= " (Current)"

XPERL_RAID_TOOLTIP_WITHBUFF	= "With buff: (%s)"
XPERL_RAID_TOOLTIP_WITHOUTBUFF	= "Without buff: (%s)"
XPERL_RAID_TOOLTIP_BUFFEXPIRING	= "%s's %s expires in %s"	-- Name, buff name, time to expire

XPERL_NEW_VERSION_DETECTED = "New version detected:"
XPERL_DOWNLOAD_LATEST = "You can download the latest version from:"
XPERL_DOWNLOAD_LOCATION = "https://mods.curse.com/addons/wow/zperl"


-- Status highlight spells
if IsClassic then
	XPERL_HIGHLIGHT_SPELLS = {
		hotSpells  = {
			[GetSpellInfo(774)] = 12,			-- Rejuvenation (old id 26982)
			--[GetSpellInfo(155777)] = 12,		-- Rejuvenation Germination
			[GetSpellInfo(8936)] = 6,			-- Regrowth (old id 26980)
			[GetSpellInfo(139)] = 12,			-- Renew (old id 25222)
			--[GetSpellInfo(48438)] = 7,			-- Wild Growth
			--[GetSpellInfo(33763)] = 8,			-- Lifebloom
			--[GetSpellInfo(28880)] = 15,			-- Gift of the Naaru (Racial)
			--[GetSpellInfo(61295)] = 15,			-- Riptide
			--[GetSpellInfo(119611)] = 18,		-- Renewing Mist
			--[GetSpellInfo(115175)] = 8,			-- Soothing Mist
			--[GetSpellInfo(124682)] = 6,			-- Enveloping Mist
			--[GetSpellInfo(114163)] = 30			-- Eternal Flame
		},
		pomSpells = {
			--[GetSpellInfo(33076)] = 30,			-- Prayer of Mending
			--[GetSpellInfo(81749)] = 15,			-- Atonement
			--[GetSpellInfo(115151)] = 18,		-- Renewing Mist
			--[GetSpellInfo(157007)] = 60,		-- Beacon of Insight
		},
		shieldSpells = {
			[GetSpellInfo(17)] = 15,			-- Power Word: Shield
			--[GetSpellInfo(76669)] = 15,			-- Illuminated Healing
			--[GetSpellInfo(974)] = 600			-- Earth Shield	(old id 32594)
		},
	}
elseif IsBCClassic then
	XPERL_HIGHLIGHT_SPELLS = {
		hotSpells  = {
			[GetSpellInfo(774)] = 12,			-- Rejuvenation (old id 26982)
			--[GetSpellInfo(155777)] = 12,		-- Rejuvenation Germination
			[GetSpellInfo(8936)] = 6,			-- Regrowth (old id 26980)
			[GetSpellInfo(139)] = 12,			-- Renew (old id 25222)
			--[GetSpellInfo(48438)] = 7,			-- Wild Growth
			[GetSpellInfo(33763)] = 8,			-- Lifebloom
			[GetSpellInfo(28880)] = 15,			-- Gift of the Naaru (Racial)
			--[GetSpellInfo(61295)] = 15,			-- Riptide
			--[GetSpellInfo(119611)] = 18,		-- Renewing Mist
			--[GetSpellInfo(115175)] = 8,			-- Soothing Mist
			--[GetSpellInfo(124682)] = 6,			-- Enveloping Mist
			--[GetSpellInfo(114163)] = 30			-- Eternal Flame
		},
		pomSpells = {
			[GetSpellInfo(33076)] = 30,			-- Prayer of Mending
			--[GetSpellInfo(81749)] = 15,			-- Atonement
			--[GetSpellInfo(115151)] = 18,		-- Renewing Mist
			--[GetSpellInfo(157007)] = 60,		-- Beacon of Insight
		},
		shieldSpells = {
			[GetSpellInfo(17)] = 15,			-- Power Word: Shield
			--[GetSpellInfo(76669)] = 15,			-- Illuminated Healing
			--[GetSpellInfo(974)] = 600			-- Earth Shield	(old id 32594)
		},
	}
else
	XPERL_HIGHLIGHT_SPELLS = {
		hotSpells  = {
			[GetSpellInfo(774)] = 12,			-- Rejuvenation (old id 26982)
			[GetSpellInfo(155777)] = 12,		-- Rejuvenation Germination
			[GetSpellInfo(8936)] = 6,			-- Regrowth (old id 26980)
			[GetSpellInfo(139)] = 12,			-- Renew (old id 25222)
			[GetSpellInfo(48438)] = 7,			-- Wild Growth
			[GetSpellInfo(33763)] = 8,			-- Lifebloom
			[GetSpellInfo(28880)] = 15,			-- Gift of the Naaru (Racial)
			[GetSpellInfo(61295)] = 15,			-- Riptide
			[GetSpellInfo(119611)] = 18,		-- Renewing Mist
			[GetSpellInfo(115175)] = 8,			-- Soothing Mist
			[GetSpellInfo(124682)] = 6,			-- Enveloping Mist
			--[GetSpellInfo(114163)] = 30			-- Eternal Flame
		},
		pomSpells = {
			[GetSpellInfo(33076)] = 30,			-- Prayer of Mending
			[GetSpellInfo(81749)] = 15,			-- Atonement
			[GetSpellInfo(115151)] = 18,		-- Renewing Mist
			--[GetSpellInfo(157007)] = 60,		-- Beacon of Insight
		},
		shieldSpells = {
			[GetSpellInfo(17)] = 15,			-- Power Word: Shield
			--[GetSpellInfo(76669)] = 15,			-- Illuminated Healing
			--[GetSpellInfo(974)] = 600			-- Earth Shield	(old id 32594)
		},
	}
end


-- Default spells for range checking in the healer visual out-of-range cues.
if IsClassic then
	XPerl_DefaultRangeSpells = {
		DRUID	= {spell = GetSpellInfo(774)},				-- Rejuvenation
		PALADIN = {spell = GetSpellInfo(19750)},			-- Flash of Light
		PRIEST	= {spell = GetSpellInfo(2061)},				-- Flash Heal
		SHAMAN	= {spell = GetSpellInfo(8004)},				-- Healing Surge
		MAGE	= {spell = GetSpellInfo(475)},				-- Remove Lesser Curse
		ROGUE	= {spell = GetSpellInfo(57934)},			-- Trick of the Trade
		WARLOCK	= {spell = GetSpellInfo(5697)},				-- Unending Breath
		ANY		= {item = GetItemInfo(1251)}				-- Linen Bandage
	}
elseif IsBCClassic then
	XPerl_DefaultRangeSpells = {
		DRUID	= {spell = GetSpellInfo(774)},				-- Rejuvenation
		PALADIN = {spell = GetSpellInfo(19750)},			-- Flash of Light
		PRIEST	= {spell = GetSpellInfo(2061)},				-- Flash Heal
		SHAMAN	= {spell = GetSpellInfo(8004)},				-- Healing Surge
		MAGE	= {spell = GetSpellInfo(475)},				-- Remove Lesser Curse
		ROGUE	= {spell = GetSpellInfo(57934)},			-- Trick of the Trade
		WARLOCK	= {spell = GetSpellInfo(5697)},				-- Unending Breath
		ANY		= {item = GetItemInfo(1251)}				-- Linen Bandage
	}
else
	XPerl_DefaultRangeSpells = {
		DRUID	= {spell = GetSpellInfo(774)},				-- Rejuvenation
		PALADIN = {spell = GetSpellInfo(19750)},			-- Flash of Light
		PRIEST	= {spell = GetSpellInfo(2061)},				-- Flash Heal
		SHAMAN	= {spell = GetSpellInfo(8004)},				-- Healing Surge
		--MAGE	= {spell = GetSpellInfo(475)},				-- Remove Lesser Curse
		ROGUE	= {spell = GetSpellInfo(57934)},			-- Trick of the Trade
		WARLOCK	= {spell = GetSpellInfo(5697)},				-- Unending Breath
		ANY		= {item = GetItemInfo(173191)}				-- Heavy Shrouded Cloth Bandage
	}
end

-- Don't highlight these magical debuffs
if IsClassic then
	XPerl_ArcaneExclusions = {
		--[GetSpellInfo(63559)] = true,						-- Bind Life
		--[GetSpellInfo(30451)] = true,						-- Arcane Blast (again) (old 42897)
		--[GetSpellInfo(30108)] = true,						-- Unstable Affliction (old 30405)
		--[GetSpellInfo(15822)] = true,						-- Dreamless Sleep
		--[GetSpellInfo(24360)] = true,						-- Greater Dreamless Sleep
		--[GetSpellInfo(28504)] = true,						-- Major Dreamless Sleep
		--[GetSpellInfo(31257)] = true,						-- Chilled
		[GetSpellInfo(710)] = true,							-- Banish
		--[GetSpellInfo(44836)] = true,						-- Also Banish !?
		--[GetSpellInfo(24306)] = true,						-- Delusions of Jin'do
		--[GetSpellInfo(46543)] = {ROGUE = true, WARRIOR = true},	-- Ignite Mana
		--[GetSpellInfo(16567)] = {ROGUE = true, WARRIOR = true},	-- Tainted Mind
		--[GetSpellInfo(39052)] = {ROGUE = true},				-- Sonic Burst
		--[GetSpellInfo(41190)] = {ROGUE = true, WARRIOR = true}, -- Mind-numbing Poison
		[GetSpellInfo(25195)] = {ROGUE = true},				-- Curse of Tongues
		--[GetSpellInfo(30129)] = true,						-- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		--[GetSpellInfo(31651)] = {MAGE = true, WARLOCK = true, PRIEST = true},	-- Banshee Curse, Melee hit rating debuff
		--[GetSpellInfo(38913)] = {ROGUE = true},				-- Silence
		--[GetSpellInfo(31555)] = {ROGUE = true, WARRIOR = true},	-- Decayed Intellect
	}
elseif IsBCClassic then
	XPerl_ArcaneExclusions = {
		--[GetSpellInfo(63559)] = true,						-- Bind Life
		--[GetSpellInfo(30451)] = true,						-- Arcane Blast (again) (old 42897)
		--[GetSpellInfo(30108)] = true,						-- Unstable Affliction (old 30405)
		--[GetSpellInfo(15822)] = true,						-- Dreamless Sleep
		--[GetSpellInfo(24360)] = true,						-- Greater Dreamless Sleep
		--[GetSpellInfo(28504)] = true,						-- Major Dreamless Sleep
		--[GetSpellInfo(31257)] = true,						-- Chilled
		[GetSpellInfo(710)] = true,							-- Banish
		--[GetSpellInfo(44836)] = true,						-- Also Banish !?
		--[GetSpellInfo(24306)] = true,						-- Delusions of Jin'do
		--[GetSpellInfo(46543)] = {ROGUE = true, WARRIOR = true},	-- Ignite Mana
		--[GetSpellInfo(16567)] = {ROGUE = true, WARRIOR = true},	-- Tainted Mind
		--[GetSpellInfo(39052)] = {ROGUE = true},				-- Sonic Burst
		--[GetSpellInfo(41190)] = {ROGUE = true, WARRIOR = true}, -- Mind-numbing Poison
		[GetSpellInfo(25195)] = {ROGUE = true},				-- Curse of Tongues
		--[GetSpellInfo(30129)] = true,						-- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		--[GetSpellInfo(31651)] = {MAGE = true, WARLOCK = true, PRIEST = true},	-- Banshee Curse, Melee hit rating debuff
		--[GetSpellInfo(38913)] = {ROGUE = true},				-- Silence
		--[GetSpellInfo(31555)] = {ROGUE = true, WARRIOR = true},	-- Decayed Intellect
	}
else
	XPerl_ArcaneExclusions = {
		[GetSpellInfo(63559)] = true,						-- Bind Life
		[GetSpellInfo(30451)] = true,						-- Arcane Blast (again) (old 42897)
		[GetSpellInfo(30108)] = true,						-- Unstable Affliction (old 30405)
		[GetSpellInfo(15822)] = true,						-- Dreamless Sleep
		[GetSpellInfo(24360)] = true,						-- Greater Dreamless Sleep
		[GetSpellInfo(28504)] = true,						-- Major Dreamless Sleep
		[GetSpellInfo(31257)] = true,						-- Chilled
		[GetSpellInfo(710)] = true,							-- Banish
		[GetSpellInfo(44836)] = true,						-- Also Banish !?
		[GetSpellInfo(24306)] = true,						-- Delusions of Jin'do
		[GetSpellInfo(46543)] = {ROGUE = true, WARRIOR = true},	-- Ignite Mana
		[GetSpellInfo(16567)] = {ROGUE = true, WARRIOR = true},	-- Tainted Mind
		[GetSpellInfo(39052)] = {ROGUE = true},				-- Sonic Burst
		[GetSpellInfo(41190)] = {ROGUE = true, WARRIOR = true}, -- Mind-numbing Poison
		[GetSpellInfo(25195)] = {ROGUE = true},				-- Curse of Tongues
		[GetSpellInfo(30129)] = true,						-- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		[GetSpellInfo(31651)] = {MAGE = true, WARLOCK = true, PRIEST = true},	-- Banshee Curse, Melee hit rating debuff
		[GetSpellInfo(38913)] = {ROGUE = true},				-- Silence
		[GetSpellInfo(31555)] = {ROGUE = true, WARRIOR = true},	-- Decayed Intellect
	}
end
