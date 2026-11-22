-------------------------------------------------------------------------------------
---------------------------------- DEFAULT CONFIGS ----------------------------------
-------------------------------------------------------------------------------------

local defaultConfig = {}


-- RegisterConfigDefault
local function RegisterConfigDefault(configFunc, configSection)
	tinsert(defaultConfig, {func = configFunc, section = configSection})
end

local function MakeDefaultConfig(new)
	for k, v in pairs(defaultConfig) do
		v.func(new, v.section)
	end
end

-- ZPerl.SetUntickedKeys(profile)
-- An unticked checkbox option is stored as false, a ticked one as 1. Sets false on every key of
-- ZPerl.CheckboxKeys (ZPerl_CheckboxKeys.lua) that is nil and whose table exists.
function ZPerl.SetUntickedKeys(profile)
	for _, e in ipairs(ZPerl.CheckboxKeys) do
		local t = profile
		for part in string.gmatch(e[1], "[^%.]+") do
			if (type(t) ~= "table") then
				break
			end
			t = t[part]
		end
		if (type(t) == "table" and t[e[2]] == nil) then
			t[e[2]] = false
		end
	end
end

-- ZPerl.OptionsDefaults()
function ZPerl.OptionsDefaults(new)
	MakeDefaultConfig(new)
	ZPerl.SetUntickedKeys(new)
end


-- AuraLayoutDefaults(sec, side, order)
-- The aura layout keys of one frame section: where each kind sits (TOP, BOTTOM, LEFT, RIGHT), the order
-- when both share a side, icons per line (0 = the frame's edge), fill direction, and offset.
local function AuraLayoutDefaults(sec, side, order)
	sec.auraOrder = order
	for _, kind in ipairs({"buffs", "debuffs"}) do
		local t = sec[kind]
		t.side, t.perLine, t.reverse, t.x, t.y = side, 0, false, 0, 0
	end
end

-- GlobalConfigDefault
local function GlobalConfigDefault(default)
	-- Defaults for global options

	if (not default) then
		error("Usage: GlobalConfigDefault(<table>)")
		return
	end

	default.transparency = {
		frame		= 1,
		text		= 1,
	}

	default.highlightSelection	= 1
	default.alignmentGrid		= false	-- the General > Frames grid and snap rows (ZPerl_Positions.lua)
	default.alignmentSnapToGrid	= false
	default.combatFlash	= 1
	default.maximumScale	= 1.5
	default.showAFK		= 1				-- 2.2.4
	default.oldRoleIcons = 1

	default.minimap = {
		enable		= 1,
	}

	default.highlightDebuffs = {
		enable		= 1,
		border		= 1,
		frame		= 1,
		class		= 1,
	}

	default.buffHelper = {
		enable		= 1,
		sort		= "group",		-- 2.2.5
		visible		= 1,			-- 2.2.9
	}

	default.buffs = {
		cooldown	= 1,			-- 2.2.3
		cooldownAny	= 1,			-- swipe on all auras, not only the player's
		countdown	= 1,			-- 2.2.2
		countdownAny	= 1,			-- duration text on all auras
--		blizzard	= nil,			-- Blizzard's countdown numbers on the cooldown frame
		omnicc		= 1,			-- let OmniCC-style addons show their text
	}

	default.rangeFinder = ZPerl.DefaultRangeFinder()

	default.tooltip = {
		enable		= 1,			-- 2.0.5
		enableBuffs	= 1,			-- 2.3.4a
--		fading		= nil,			-- 1.8.3
		modifier	= "all",		-- 2.0.6
	}

	default.color = {
		border		= {r = 0.5, g = 0.5, b = 0.5, a = 1},
		frame		= {r = 0, g = 0, b = 0, a = 1},
		class		= 1,
		classic		= 1,
		bar		= ZPerl.DefaultBarColors(),
		reaction	= ZPerl.DefaultReactionColors(),
		gradient	= ZPerl.DefaultGradientColors(),
	}

	default.bar = {
		texture		= {"Perl v2", "Interface\\AddOns\\ZPerl\\Images\\ZPerl_StatusBar"},
		background	= 1,
--		fading		= nil,		-- 1.8.9
		fadeTime	= 0.5,		-- 1.9.1
		healthLoss	= 1,		-- the lost health drains away in red
		absorbLoss	= 1,		-- the lost absorb drains away
		fullPulse	= 1,		-- the player's and pet's power bars pulse when full
		fat		= 1,
--		inverse		= nil,		-- 1.8.6
	}

	default.highlight = {
		enable			= 1,
		HOT			= 1,
		SHIELD			= 1,
		AGGRO			= 1,
	}

	default.custom = {				-- ZPerl_CustomHighlight; zones is created on first use
		enable			= false,
		alpha			= 0.5,
		blend			= "ADD",
	}

end

-- TargetConfigDefault
local function TargetConfigDefault(default, section)
	local defaultHD, defaultHDwho
	local _, class = UnitClass("player")
	if (section == "target" and class == "ROGUE") then
		defaultHD = 1
		defaultHDwho = 3
	else
		defaultHDwho = 2
	end
	default[section] = {
		enable			= 1,
		portrait		= 1,
		portrait3D		= 1,
		castBar = {
			enable		= 1,
		},
		hitIndicator	= 1,			-- 2.1.7
		hitIndicatorPos	= "PORTRAIT",
		threat			= 1,
		threatMode		= "portraitFrame",
		classIcon		= 1,
--		classText		= nil,			-- 2.0.6
		mobType			= 1,
		level			= 1,
		healprediction	= 1,
		absorbs			= 1,
		elite			= 1,
--		eliteGfx		= nil,
		mana			= 1,
		percent			= 1,
		values			= 1,
		pvpIcon			= 1,			-- 1.8.3
		scale			= 1,
		raidIconAlternate	= 1,
		buffs = {
			enable		= 1,
			wrap		= 1,
			size		= 25,
			rows		= 3,
			castable	= 0,
		},
		debuffs = {
			enable		= 1,
			size		= 25,
			curable		= 0,
		},
--		reactionHighlight	= nil,		-- 1.8.6
		healerMode = {
--			enable		= nil,			-- 1.9.1
			type		= 1,			-- 1.9.1
		},
		highlightDebuffs = {
			enable		= defaultHD,
			who			= defaultHDwho		-- 2.2.0
		},
		size = {
			width		= 0,
		},
		sound			= 1,			-- 2.2.6
	}
	if (section == "target") then
		default.target.combo = {
			enable		= 1,
			blizzard	= 1,
		}
		default.target.comboindicator = {
			enable		= 1,			-- 5.0.4
		}
	end
	AuraLayoutDefaults(default[section], (section == "focus") and "TOP" or "BOTTOM", "reaction")
end

-- PartyConfigDefault
local function PartyConfigDefault(default)
	default.party = {
		castBar = {
			enable		= 1,
		},
		spacing			= 40,			-- clears a buff row with duration text (25 + 12); the debuffs sit to the right
		anchor			= "TOP",
		enable			= 1,			-- 4.0.0
		portrait		= 1,
		portrait3D		= 1,
		hitIndicator	= 1,			-- 2.1.7
		hitIndicatorPos	= "PORTRAIT",
		threat			= 1,
		threatMode		= "portraitFrame",
		target = {
			enable		= 1,
			large		= 1,
			size		= 120,			-- 2.0.9
		},
		level			= 1,
		healprediction	= 1,
		absorbs			= 1,
		name			= 1,
		values			= 1,
		percent			= 1,
		classIcon		= 1,
		pvpIcon			= 1,			-- 1.8.3
		showPlayer		= nil,
		inRaid			= 1,
		buffs = {
			enable		= 1,
			wrap		= 1,			-- 2.3.5
			size		= 25,
			castable	= 0,
			rows		= 2,
		},
		debuffs = {
			enable		= 1,
			size		= 25,
			curable		= 0,
		},
		scale			= 1,
		healerMode = {
--			enable		= nil,			-- 1.9.1
			type		= 1,			-- 1.9.1
		},
		size = {
			width		= 0,
		},
--		flip			= nil,			-- 2.2.7
	}
	AuraLayoutDefaults(default.party, "BOTTOM", "buffs")
	-- debuffs beside the stats frame, growing away from it (past the pet frame while it shows), as the
	-- original Z-Perl had them
	default.party.debuffs.side = "RIGHT"
end

-- PartyPetConfigDefault
local function PartyPetConfigDefault(default)
	default.partypet = {
		enable			= 1,
		scale			= 1,
		name			= 1,
		buffs = {
			enable		= 1,
			castable	= 0,
			size		= 12,
		},
		debuffs = {
			enable		= 1,
			curable		= 0,
			size		= 12,			-- read by ZPerl_PartyPet.lua; ValidateSettings used to copy buffs.size
		},
		healerMode = {
			--enable		= nil,
			type		= 1,
		},
		mana			= 1,
		--level			= nil,
	}
	AuraLayoutDefaults(default.partypet, "BOTTOM", "buffs")
end

-- PlayerConfigDefault
local function PlayerConfigDefault(default)
	default.player = {
		enable			= 1,			-- the frame; takes effect after a reload
		castBar = {
			enable		= 1,
--			original	= nil,
--			castTime	= nil,
		},
		portrait		= 1,
		portrait3D		= 1,
		hitIndicator	= 1,
		hitIndicatorPos	= "PORTRAIT",
		level			= 1,
		healprediction	= 1,
		absorbs			= 1,
		classIcon		= 1,
--		xpBar			= nil,
--		repBar			= nil,
		classBar		= 1,			-- retail: Blizzard's class resource bars under the frame
		classBarPos		= "BOTTOM",		-- retail: "BOTTOM" under the stats frame, "TOP" on top of the name frame
		classBarX		= 0,			-- retail: class bar offset from that spot, in pixels
		classBarY		= 0,
		classBarTooltip	= false,		-- retail: the class bar's tooltip
		classBarMirror	= false,		-- retail: the class bar flipped left to right
		classBarMirrorV	= false,		-- retail: the class bar flipped top to bottom
		pvpIcon			= 1,
		energyTicker	= 1,			-- Classic-based clients: the energy tick spark on the power bar
		values			= 1,
		percent			= 1,
		scale			= 1,
		partyNumber		= 1,
--		withName		= nil,

		fullScreen = {
			enable		= 1,
		},

		healerMode = {
--			enable		= nil,
			type		= 1,
		},

		buffs = {
			enable		= 1,
			size		= 25,
			wrap		= 1,			-- 2.3.5
			rows		= 2,			-- 2.3.5
			hideBlizzard	= 1,
		},
		debuffs = {
			enable		= 1,
			size		= 25,
		},
		enchants = {					-- weapon enchants (poisons) at the start of the buff line
			enable		= 1,
		},
		size = {
			width		= 0,
		},
	}
	AuraLayoutDefaults(default.player, "BOTTOM", "buffs")
end

-- PetConfigDefault
local function PetConfigDefault(default)
	default.pet = {
		enable = 1,					-- the frame; takes effect after a reload
		castBar = {
			enable = 1,
		},
		portrait = 1,
		portrait3D = 1,
		hitIndicator= 1,
		hitIndicatorPos	= "PORTRAIT",
		happiness = {
			enable = 1,
			onlyWhenSad	= 1,
			flashWhenSad = 1,
		},
		threat = 1,
		threatMode = "portraitFrame",
		level = 1,
		healprediction = 1,
		absorbs = 1,
		scale = 1,
		name = 1,
		buffs = {
			enable = 1,
			size = 25,
			wrap = 1,
			rows = 3,
		},
		debuffs = {
			enable = 1,
			size = 25,
		},
		values = 1,
		healerMode = {
			type = 1,
		},
		size = {
			width = 0,
		},
	}
	AuraLayoutDefaults(default.pet, "BOTTOM", "buffs")
end

-- TargetTargetConfigDefault
local function TargetTargetConfigDefault(default, section)
	local e
	if (section ~= "targettargettarget") then
		e = 1
	end

	default[section] = {
		enable			= e,
		buffs = {
			enable		= 1,
			size		= 25,
			rows		= 3,
			castable	= 0,
			wrap		= 1,			-- 2.3.5
		},
		debuffs = {
			size		= 25,
			enable		= 1,
			curable		= 0,
		},
		scale			= 1,
		pvpIcon			= 1,
		percent			= 1,
		values			= 1,
--		level			= nil,
		healprediction	= 1,
		absorbs			= 1,
		mana			= 1,
		size = {
			width		= 0,
		},
		healerMode = {
--			enable		= nil,			-- 1.9.1
			type		= 1,			-- 1.9.1
		},
	}
	if (section == "pettarget") then
		default[section].absorbs, default[section].healprediction = nil, nil
	end
	AuraLayoutDefaults(default[section], "BOTTOM", "reaction")
end

-- RaidConfigDefault
local function RaidConfigDefault(default)
	default.raid = {
		enable			= 1,
--		sortByClass		= nil,
		sortByRole 		= nil,
--		sortAlpha		= nil,
		group = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
		class = {
			{enable = 1, name = "WARRIOR"},
			{enable = 1, name = "ROGUE"},
			{enable = 1, name = "HUNTER"},
			{enable = 1, name = "MAGE"},
			{enable = 1, name = "WARLOCK"},
			{enable = 1, name = "PRIEST"},
			{enable = 1, name = "DRUID"},
			{enable = 1, name = "SHAMAN"},
			{enable = 1, name = "PALADIN"},
		},	-- the newer classes are appended at the end of this function, on the clients that have them
		role			= nil,
		titles			= 1,
		percent			= 1,
		precisionPercent = 1,
		healprediction	= 1,
		absorbs			= 1,
		mana			= 1,
		manaPercent		= 1,
		precisionManaPercent = 1,
		scale			= 1,
		spacing			= 0,
		inParty			= nil,
		auraText		= false,			-- no duration text: it does not fit the raid frame
		buffs = {
--			enable		= nil,
			castable	= 0,
			size		= 10,
			wrap		= 1,
			rows		= 2,
		},
		debuffs = {
			enable		= 1,
			curable		= 0,
			size		= 10,
		},
--		mana			= nil,
		healerMode = {
--			enable		= nil,
		},
		anchor			= "TOP",
		gap				= 0,
		size = {
			width		= 0,
		},
	}
	-- debuffs inside the frame's right end, buffs inside its left end (the raid frames' auraInside), both bottom-aligned
	AuraLayoutDefaults(default.raid, "RIGHT", "debuffs")
	default.raid.buffs.side = "LEFT"
	default.raid.buffs.perLine, default.raid.debuffs.perLine = 4, 4
	default.raid.buffs.reverse, default.raid.debuffs.reverse = true, true
	for _, class in ipairs({"DEATHKNIGHT", "MONK", "DEMONHUNTER", "EVOKER"}) do
		if (LOCALIZED_CLASS_NAMES_MALE[class]) then
			tinsert(default.raid.class, {enable = 1, name = class})
		end
	end
end

-- RaidPetConfigDefault
local function RaidPetConfigDefault(default, section)
	default.raidpet = {
		enable			= 1,			-- 2.1.3
	}
end

RegisterConfigDefault(GlobalConfigDefault)
RegisterConfigDefault(TargetConfigDefault, "target")
RegisterConfigDefault(TargetConfigDefault, "focus")
RegisterConfigDefault(PartyConfigDefault)
RegisterConfigDefault(PartyPetConfigDefault)
RegisterConfigDefault(PlayerConfigDefault)
RegisterConfigDefault(PetConfigDefault)
RegisterConfigDefault(TargetTargetConfigDefault, "targettargettarget")
RegisterConfigDefault(TargetTargetConfigDefault, "targettarget")
RegisterConfigDefault(TargetTargetConfigDefault, "focustarget")
RegisterConfigDefault(TargetTargetConfigDefault, "pettarget")
RegisterConfigDefault(RaidConfigDefault)
RegisterConfigDefault(RaidPetConfigDefault)


-- ZPerl.DefaultGradientColors
function ZPerl.DefaultGradientColors()
	return {
		enable = 1,
		--horizontal = nil,
		s = {r = 0.25, g = 0.25, b = 0.25, a = 1},
		e = {r = 0.1, g = 0.1, b = 0.1, a = 0}
	}
end

-- ZPerl.DefaultReactionColors
function ZPerl.DefaultReactionColors()
	return {
		enemy		= {r = 1, g = 0, b = 0},
		neutral		= {r = 1, g = 1, b = 0},
		unfriendly	= {r = 1, g = 0.5, b = 0},
		friend		= {r = 0, g = 1, b = 0},
		none		= {r = 0.5, g = 0.5, b = 1},
		tapped		= {r = 0.5, g = 0.5, b = 0.5},
	}
end

-- ZPerl.DefaultBarColors
function ZPerl.DefaultBarColors()
	return {
		healthEmpty	= {r = 1, g = 0, b = 0},
		healthFull	= {r = 0, g = 1, b = 0},
		absorb		= {r = 0.14, g = 0.33, b = 0.7, a = 0.7},
		healprediction = {r = 0, g = 1, b = 1, a = 1},
		mana		= {r = 0, g = 0, b = 1},
		energy		= {r = 1, g = 1, b = 0},
		rage		= {r = 1, g = 0, b = 0},
		focus		= {r = 1, g = 0.5, b = 0.25},
	}
end

-- ZPerl.DefaultFrameAppearance
function ZPerl.DefaultFrameAppearance()
	ZPerl.layout.transparency.frame	= 1
	ZPerl.layout.transparency.text	= 1
	ZPerl.layout.color.border		= {r = 0.5, g = 0.5, b = 0.5, a = 1}
	ZPerl.layout.color.frame		= {r = 0, g = 0, b = 0, a = 1}
end

-- ZPerl.DefaultRangeFinder
function ZPerl.DefaultRangeFinder()
	return {						-- 2.1.7
--		enabled		= e,	-- 2.3.4a Defaulting to OFF now, because of so many confused users complaining about faded frames. RTFM... (TODO: Write a manual)
		Main		= {enabled = true, FadeAmount = 0.5},
		NameFrame	= {FadeAmount = 0.5},
		StatsFrame	= {FadeAmount = 0.5},
	}
end
