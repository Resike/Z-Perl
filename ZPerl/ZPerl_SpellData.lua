-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

-- Status highlight spells
if ZPerl.IsRetail then
	---@diagnostic disable-next-line: create-global
	ZPERL_HIGHLIGHT_SPELLS = {
		hotSpells = {
			[ZPerl.SpellName(774)] = 12,     -- Rejuvenation (old id 26982)
			[ZPerl.SpellName(155777)] = 12,  -- Rejuvenation Germination
			[ZPerl.SpellName(8936)] = 6,     -- Regrowth (old id 26980)
			[ZPerl.SpellName(139)] = 12,     -- Renew (old id 25222)
			[ZPerl.SpellName(48438)] = 7,    -- Wild Growth
			[ZPerl.SpellName(33763)] = 8,    -- Lifebloom
			[ZPerl.SpellName(28880)] = 15,   -- Gift of the Naaru (Racial)
			[ZPerl.SpellName(61295)] = 15,   -- Riptide
			[ZPerl.SpellName(119611)] = 18,  -- Renewing Mist
			[ZPerl.SpellName(115175)] = 8,   -- Soothing Mist
			[ZPerl.SpellName(124682)] = 6,   -- Enveloping Mist
			--[ZPerl.SpellName(114163)] = 30 -- Eternal Flame
		},
		pomSpells = {
			[ZPerl.SpellName(33076)] = 30,    -- Prayer of Mending
			[ZPerl.SpellName(81749)] = 15,    -- Atonement
			[ZPerl.SpellName(115151)] = 18,   -- Renewing Mist
			--[ZPerl.SpellName(157007)] = 60, -- Beacon of Insight
		},
		shieldSpells = {
			[ZPerl.SpellName(17)] = 15,      -- Power Word: Shield
			--[ZPerl.SpellName(76669)] = 15, -- Illuminated Healing
			--[ZPerl.SpellName(974)] = 600   -- Earth Shield (old id 32594)
		},
	}
elseif ZPerl.IsMists then
	ZPERL_HIGHLIGHT_SPELLS = {
		hotSpells = {
			[ZPerl.SpellName(774)] = 12,      -- Rejuvenation (old id 26982)
			--[ZPerl.SpellName(155777)] = 12, -- Rejuvenation Germination
			[ZPerl.SpellName(8936)] = 6,      -- Regrowth (old id 26980)
			[ZPerl.SpellName(139)] = 12,      -- Renew (old id 25222)
			[ZPerl.SpellName(48438)] = 7,     -- Wild Growth
			[ZPerl.SpellName(33763)] = 8,     -- Lifebloom
			[ZPerl.SpellName(28880)] = 15,    -- Gift of the Naaru (Racial)
			[ZPerl.SpellName(61295)] = 15,    -- Riptide
			[ZPerl.SpellName(119611)] = 18,   -- Renewing Mist
			[ZPerl.SpellName(115175)] = 8,    -- Soothing Mist
			[ZPerl.SpellName(124682)] = 6,    -- Enveloping Mist
			[ZPerl.SpellName(114163)] = 30    -- Eternal Flame
		},
		pomSpells = {
			[ZPerl.SpellName(33076)] = 30,    -- Prayer of Mending
			[ZPerl.SpellName(81749)] = 15,    -- Atonement
			[ZPerl.SpellName(115151)] = 18,   -- Renewing Mist
			--[ZPerl.SpellName(157007)] = 60, -- Beacon of Insight
		},
		shieldSpells = {
			[ZPerl.SpellName(17)] = 15,    -- Power Word: Shield
			[ZPerl.SpellName(76669)] = 15, -- Illuminated Healing
			[ZPerl.SpellName(974)] = 600   -- Earth Shield (old id 32594)
		},
	}
elseif ZPerl.IsBCC then
	ZPERL_HIGHLIGHT_SPELLS = {
		hotSpells = {
			[ZPerl.SpellName(774)] = 12,      -- Rejuvenation (old id 26982)
			--[ZPerl.SpellName(155777)] = 12, -- Rejuvenation Germination
			[ZPerl.SpellName(8936)] = 6,      -- Regrowth (old id 26980)
			[ZPerl.SpellName(139)] = 12,      -- Renew (old id 25222)
			--[ZPerl.SpellName(48438)] = 7,   -- Wild Growth
			[ZPerl.SpellName(33763)] = 8,     -- Lifebloom
			[ZPerl.SpellName(28880)] = 15,    -- Gift of the Naaru (Racial)
			--[ZPerl.SpellName(61295)] = 15,  -- Riptide
			--[ZPerl.SpellName(119611)] = 18, -- Renewing Mist
			--[ZPerl.SpellName(115175)] = 8,  -- Soothing Mist
			--[ZPerl.SpellName(124682)] = 6,  -- Enveloping Mist
			--[ZPerl.SpellName(114163)] = 30  -- Eternal Flame
		},
		pomSpells = {
			[ZPerl.SpellName(33076)] = 30,    -- Prayer of Mending
			--[ZPerl.SpellName(81749)] = 15,  -- Atonement
			--[ZPerl.SpellName(115151)] = 18, -- Renewing Mist
			--[ZPerl.SpellName(157007)] = 60, -- Beacon of Insight
		},
		shieldSpells = {
			[ZPerl.SpellName(17)] = 15,      -- Power Word: Shield
			--[ZPerl.SpellName(76669)] = 15, -- Illuminated Healing
			[ZPerl.SpellName(974)] = 600     -- Earth Shield (old id 32594)
		},
	}
else
	---@diagnostic disable-next-line: create-global
	ZPERL_HIGHLIGHT_SPELLS = {
		hotSpells = {
			[ZPerl.SpellName(774)] = 12,      -- Rejuvenation (old id 26982)
			--[ZPerl.SpellName(155777)] = 12, -- Rejuvenation Germination
			[ZPerl.SpellName(8936)] = 6,      -- Regrowth (old id 26980)
			[ZPerl.SpellName(139)] = 12,      -- Renew (old id 25222)
			--[ZPerl.SpellName(48438)] = 7,   -- Wild Growth
			--[ZPerl.SpellName(33763)] = 8,   -- Lifebloom
			--[ZPerl.SpellName(28880)] = 15,  -- Gift of the Naaru (Racial)
			--[ZPerl.SpellName(61295)] = 15,  -- Riptide
			--[ZPerl.SpellName(119611)] = 18, -- Renewing Mist
			--[ZPerl.SpellName(115175)] = 8,  -- Soothing Mist
			--[ZPerl.SpellName(124682)] = 6,  -- Enveloping Mist
			--[ZPerl.SpellName(114163)] = 30  -- Eternal Flame
		},
		pomSpells = {
			--[ZPerl.SpellName(33076)] = 30,  -- Prayer of Mending
			--[ZPerl.SpellName(81749)] = 15,  -- Atonement
			--[ZPerl.SpellName(115151)] = 18, -- Renewing Mist
			--[ZPerl.SpellName(157007)] = 60, -- Beacon of Insight
		},
		shieldSpells = {
			[ZPerl.SpellName(17)] = 15,      -- Power Word: Shield
			--[ZPerl.SpellName(76669)] = 15, -- Illuminated Healing
			--[ZPerl.SpellName(974)] = 600   -- Earth Shield (old id 32594)
		},
	}
end

-- Don't highlight these magical debuffs
if ZPerl.IsRetail then
	ZPerl.ArcaneExclusions = {
		[ZPerl.SpellName(63559)] = true,                                         -- Bind Life
		[ZPerl.SpellName(30451)] = true,                                         -- Arcane Blast (again) (old 42897)
		[ZPerl.SpellName(30108)] = true,                                         -- Unstable Affliction (old 30405)
		[ZPerl.SpellName(15822)] = true,                                         -- Dreamless Sleep
		[ZPerl.SpellName(24360)] = true,                                         -- Greater Dreamless Sleep
		[ZPerl.SpellName(28504)] = true,                                         -- Major Dreamless Sleep
		[ZPerl.SpellName(31257)] = true,                                         -- Chilled
		[ZPerl.SpellName(710)] = true,                                           -- Banish
		[ZPerl.SpellName(44836)] = true,                                         -- Also Banish !?
		[ZPerl.SpellName(24306)] = true,                                         -- Delusions of Jin'do
		[ZPerl.SpellName(46543)] = {ROGUE = true, WARRIOR = true},               -- Ignite Mana
		[ZPerl.SpellName(16567)] = {ROGUE = true, WARRIOR = true},               -- Tainted Mind
		[ZPerl.SpellName(39052)] = {ROGUE = true},                               -- Sonic Burst
		[ZPerl.SpellName(41190)] = {ROGUE = true, WARRIOR = true},               -- Mind-numbing Poison
		[ZPerl.SpellName(25195)] = {ROGUE = true},                               -- Curse of Tongues
		[ZPerl.SpellName(30129)] = true,                                         -- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		[ZPerl.SpellName(31651)] = {MAGE = true, WARLOCK = true, PRIEST = true}, -- Banshee Curse, Melee hit rating debuff
		[ZPerl.SpellName(38913)] = {ROGUE = true},                               -- Silence
		[ZPerl.SpellName(31555)] = {ROGUE = true, WARRIOR = true},               -- Decayed Intellect
	}
elseif ZPerl.IsMists then
	ZPerl.ArcaneExclusions = {
		--[ZPerl.SpellName(63559)] = true,                                         -- Bind Life
		--[ZPerl.SpellName(30451)] = true,                                         -- Arcane Blast (again) (old 42897)
		--[ZPerl.SpellName(30108)] = true,                                         -- Unstable Affliction (old 30405)
		--[ZPerl.SpellName(15822)] = true,                                         -- Dreamless Sleep
		--[ZPerl.SpellName(24360)] = true,                                         -- Greater Dreamless Sleep
		--[ZPerl.SpellName(28504)] = true,                                         -- Major Dreamless Sleep
		--[ZPerl.SpellName(31257)] = true,                                         -- Chilled
		[ZPerl.SpellName(710)] = true,                                             -- Banish
		--[ZPerl.SpellName(44836)] = true,                                         -- Also Banish !?
		--[ZPerl.SpellName(24306)] = true,                                         -- Delusions of Jin'do
		--[ZPerl.SpellName(46543)] = {ROGUE = true, WARRIOR = true},               -- Ignite Mana
		--[ZPerl.SpellName(16567)] = {ROGUE = true, WARRIOR = true},               -- Tainted Mind
		--[ZPerl.SpellName(39052)] = {ROGUE = true},                               -- Sonic Burst
		--[ZPerl.SpellName(41190)] = {ROGUE = true, WARRIOR = true},               -- Mind-numbing Poison
		[ZPerl.SpellName(25195)] = {ROGUE = true},                                 -- Curse of Tongues
		--[ZPerl.SpellName(30129)] = true,                                         -- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		--[ZPerl.SpellName(31651)] = {MAGE = true, WARLOCK = true, PRIEST = true}, -- Banshee Curse, Melee hit rating debuff
		--[ZPerl.SpellName(38913)] = {ROGUE = true},                               -- Silence
		--[ZPerl.SpellName(31555)] = {ROGUE = true, WARRIOR = true},               -- Decayed Intellect
	}
elseif ZPerl.IsBCC then
	ZPerl.ArcaneExclusions = {
		--[ZPerl.SpellName(63559)] = true,                                         -- Bind Life
		--[ZPerl.SpellName(30451)] = true,                                         -- Arcane Blast (again) (old 42897)
		--[ZPerl.SpellName(30108)] = true,                                         -- Unstable Affliction (old 30405)
		--[ZPerl.SpellName(15822)] = true,                                         -- Dreamless Sleep
		--[ZPerl.SpellName(24360)] = true,                                         -- Greater Dreamless Sleep
		--[ZPerl.SpellName(28504)] = true,                                         -- Major Dreamless Sleep
		--[ZPerl.SpellName(31257)] = true,                                         -- Chilled
		[ZPerl.SpellName(710)] = true,                                             -- Banish
		--[ZPerl.SpellName(44836)] = true,                                         -- Also Banish !?
		--[ZPerl.SpellName(24306)] = true,                                         -- Delusions of Jin'do
		--[ZPerl.SpellName(46543)] = {ROGUE = true, WARRIOR = true},               -- Ignite Mana
		--[ZPerl.SpellName(16567)] = {ROGUE = true, WARRIOR = true},               -- Tainted Mind
		--[ZPerl.SpellName(39052)] = {ROGUE = true},                               -- Sonic Burst
		--[ZPerl.SpellName(41190)] = {ROGUE = true, WARRIOR = true},               -- Mind-numbing Poison
		[ZPerl.SpellName(25195)] = {ROGUE = true},                                 -- Curse of Tongues
		--[ZPerl.SpellName(30129)] = true,                                         -- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		--[ZPerl.SpellName(31651)] = {MAGE = true, WARLOCK = true, PRIEST = true}, -- Banshee Curse, Melee hit rating debuff
		--[ZPerl.SpellName(38913)] = {ROGUE = true},                               -- Silence
		--[ZPerl.SpellName(31555)] = {ROGUE = true, WARRIOR = true},               -- Decayed Intellect
	}
else
	ZPerl.ArcaneExclusions = {
		--[ZPerl.SpellName(63559)] = true,                                         -- Bind Life
		--[ZPerl.SpellName(30451)] = true,                                         -- Arcane Blast (again) (old 42897)
		--[ZPerl.SpellName(30108)] = true,                                         -- Unstable Affliction (old 30405)
		--[ZPerl.SpellName(15822)] = true,                                         -- Dreamless Sleep
		--[ZPerl.SpellName(24360)] = true,                                         -- Greater Dreamless Sleep
		--[ZPerl.SpellName(28504)] = true,                                         -- Major Dreamless Sleep
		--[ZPerl.SpellName(31257)] = true,                                         -- Chilled
		[ZPerl.SpellName(710)] = true,                                             -- Banish
		--[ZPerl.SpellName(44836)] = true,                                         -- Also Banish !?
		--[ZPerl.SpellName(24306)] = true,                                         -- Delusions of Jin'do
		--[ZPerl.SpellName(46543)] = {ROGUE = true, WARRIOR = true},               -- Ignite Mana
		--[ZPerl.SpellName(16567)] = {ROGUE = true, WARRIOR = true},               -- Tainted Mind
		--[ZPerl.SpellName(39052)] = {ROGUE = true},                               -- Sonic Burst
		--[ZPerl.SpellName(41190)] = {ROGUE = true, WARRIOR = true},               -- Mind-numbing Poison
		[ZPerl.SpellName(25195)] = {ROGUE = true},                                 -- Curse of Tongues
		--[ZPerl.SpellName(30129)] = true,                                         -- Charred Earth - Nightbane debuff, can't be cleansed, but shows as magic
		--[ZPerl.SpellName(31651)] = {MAGE = true, WARLOCK = true, PRIEST = true}, -- Banshee Curse, Melee hit rating debuff
		--[ZPerl.SpellName(38913)] = {ROGUE = true},                               -- Silence
		--[ZPerl.SpellName(31555)] = {ROGUE = true, WARRIOR = true},               -- Decayed Intellect
	}
end
