-- X-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 29 June 2007 (see LICENSE.txt)

if (not XPerl_RequestConfig) then
	return
end

local conf
XPerl_RequestConfig(function(new)
	conf = new.custom
end, "$Revision: @file-revision@ $")

local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

local pairs = pairs
local tinsert = tinsert
local tremove = tremove

local CreateFrame = CreateFrame
local GetRealZoneText = GetRealZoneText
local GetSpellInfo = GetSpellInfo
local UnitAura = UnitAura

local SecureButton_GetUnit = SecureButton_GetUnit

local ch = CreateFrame("Frame", "ZPerl_Custom")
ch.active = {}
ch:RegisterEvent("PLAYER_ENTERING_WORLD")
ch:RegisterEvent("UNIT_AURA")
ch:RegisterEvent("ZONE_CHANGED_NEW_AREA")
--ch:RegisterEvent("MINIMAP_ZONE_CHANGED")

ch.RaidFrameArray = XPerl_Raid_GetFrameArray()

-- ch:OnEvent(event, a, b, c)
function ch:OnEvent(event, a, b, c)
	self[event](self, a, b, c)
end

-- ch:AddDebuff
function ch:AddDebuff(debuffName)
	local zoneName = GetRealZoneText()
end

-- ch:AddDebuff
function ch:AddBuff(buffName)
	local zoneName = GetRealZoneText()
end

-- Pull zone names from encounter journal so they don't need to be localized.
-- Cataclysm Raids
local XPERL_LOC_ZONE_ANTORUS = not IsClassic and EJ_GetInstanceInfo(946) or XPERL_LOC_ZONE_ANTORUS
local XPERL_LOC_ZONE_BARADIN_HOLD = not IsClassic and EJ_GetInstanceInfo(75) or XPERL_LOC_ZONE_BARADIN_HOLD
local XPERL_LOC_ZONE_BASTION_OF_TWILIGHT = not IsClassic and EJ_GetInstanceInfo(72) or XPERL_LOC_ZONE_BASTION_OF_TWILIGHT
local XPERL_LOC_ZONE_BLACK_TEMPLE = not IsClassic and EJ_GetInstanceInfo(751) or XPERL_LOC_ZONE_BLACK_TEMPLE
local XPERL_LOC_ZONE_BLACKWING_DECENT = not IsClassic and EJ_GetInstanceInfo(73) or XPERL_LOC_ZONE_BLACKWING_DECENT
local XPERL_LOC_ZONE_DRAGONSOUL = not IsClassic and EJ_GetInstanceInfo(187) or XPERL_LOC_ZONE_DRAGONSOUL
local XPERL_LOC_ZONE_EMERALD_NIGHTMARE = not IsClassic and EJ_GetInstanceInfo(768) or XPERL_LOC_ZONE_EMERALD_NIGHTMARE
local XPERL_LOC_ZONE_EYE_OF_ETERNITY = not IsClassic and EJ_GetInstanceInfo(946) or XPERL_LOC_ZONE_EYE_OF_ETERNITY
local XPERL_LOC_ZONE_FIRELANDS = not IsClassic and EJ_GetInstanceInfo(78) or XPERL_LOC_ZONE_FIRELANDS
local XPERL_LOC_ZONE_HYJAL_SUMMIT = not IsClassic and EJ_GetInstanceInfo(750) or XPERL_LOC_ZONE_HYJAL_SUMMIT
local XPERL_LOC_ZONE_ICECROWN_CITADEL = not IsClassic and EJ_GetInstanceInfo(758) or XPERL_LOC_ZONE_ICECROWN_CITADEL
local XPERL_LOC_ZONE_KARAZHAN = not IsClassic and EJ_GetInstanceInfo(745) or XPERL_LOC_ZONE_KARAZHAN
local XPERL_LOC_ZONE_NAXXRAMAS = not IsClassic and EJ_GetInstanceInfo(754) or XPERL_LOC_ZONE_NAXXRAMAS
local XPERL_LOC_ZONE_NIGHTHOLD = not IsClassic and EJ_GetInstanceInfo(786) or XPERL_LOC_ZONE_NIGHTHOLD
local XPERL_LOC_ZONE_OBSIDIAN_SANCTUM = not IsClassic and EJ_GetInstanceInfo(755) or XPERL_LOC_ZONE_OBSIDIAN_SANCTUM
local XPERL_LOC_ZONE_RUBY_SANCTUM = not IsClassic and EJ_GetInstanceInfo(761) or XPERL_LOC_ZONE_RUBY_SANCTUM
local XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN = not IsClassic and EJ_GetInstanceInfo(748) or XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN
local XPERL_LOC_ZONE_SUNWELL_PLATEAU = not IsClassic and EJ_GetInstanceInfo(752) or XPERL_LOC_ZONE_SUNWELL_PLATEAU
local XPERL_LOC_ZONE_THRONE_OF_FOUR_WINDS = not IsClassic and EJ_GetInstanceInfo(74) or XPERL_LOC_ZONE_THRONE_OF_FOUR_WINDS
local XPERL_LOC_ZONE_TOMB_OF_SARGERAS = not IsClassic and EJ_GetInstanceInfo(875) or XPERL_LOC_ZONE_TOMB_OF_SARGERAS
local XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER = not IsClassic and EJ_GetInstanceInfo(757) or XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER
local XPERL_LOC_ZONE_TRIAL_OF_VALOR = not IsClassic and EJ_GetInstanceInfo(861) or XPERL_LOC_ZONE_TRIAL_OF_VALOR
local XPERL_LOC_ZONE_ULDUAR = not IsClassic and EJ_GetInstanceInfo(759) or XPERL_LOC_ZONE_ULDUAR
--[[
-- Mists of Pandaria Raids
local XPERL_LOC_ZONE_MOGUSHAN_VAULTS = EJ_GetInstanceInfo(317)
local XPERL_LOC_ZONE_TERRACE_OF_ENDLESS_SPRING = EJ_GetInstanceInfo(320)
local XPERL_LOC_ZONE_HEART_OF_FEAR = EJ_GetInstanceInfo(1009)
--]]
-- DefaultZoneData
function ch:DefaultZoneData()
	return {
		[XPERL_LOC_ZONE_ANTORUS] =
			{
				[246220] = true,							-- Fel Bombardment (Garothi Worldbreaker)
				[248819] = true,							-- Siphoned (Felhounds of Sargeras)
				[248815] = true,							-- Enflamed (Felhounds of Sargeras)
				[244768] = true,							-- Desolate Gaze (Felhounds of Sargeras)
				[244071] = true,							-- Weight of Darkness (Felhounds of Sargeras)
				[244086] = true,							-- Molten Touch (Felhounds of Sargeras)
				[248861] = true,							-- Spear of Doom (Eonar)
				[248326] = true,							-- Rain of Fel (Eonar)
				[247552] = true,							-- Sleep Canister (Imonar)
				[248068] = true,							-- Empowered Pulse Grenade (Imonar)
				[253600] = true, 							-- Soulburn
				[249297] = true, 							-- Flames of Reorigination
				[252760] = true,							-- Demolish (Trash and Kin'garoth)
				[246687] = true,							-- Decimation (Garothi, Trash and Kin'garoth)
				[243961] = true,							-- Misery (Varimathras)
				[245586] = true,							-- Chilled Blood (Coven)
				[245995] = true,							-- Scorching Blaze (Aggramar)
				[251570] = true,							-- Soulbomb (Argus)
				[250669] = true,							-- Soulburst (Argus)
				[255199] = true,							-- Avatar of Aggramar (Argus)
			},
		[XPERL_LOC_ZONE_TOMB_OF_SARGERAS] =
			{
				[236449] = true,							-- Soulbind (The Desolate Host)
				[235213] = true,							-- Light Infusion (Maiden of Vigilance)
				[235240] = true,							-- Fel Infusion (Maiden of Vigilance)
				[240209] = true,							-- Unstable Soul (Maiden of Vigilance)
				[235222] = true,							-- Blood Siphon (Trash in front of Kil'Jaeden)
				[238429] = true,							-- Bursting Dreadflame (Kil'Jaeden)
			},
		[XPERL_LOC_ZONE_SERPENTSHRINE_CAVERN] =
			{
				[38132] = true,								-- Paralyze - Picked up Tainted Core
			},
		[XPERL_LOC_ZONE_BLACK_TEMPLE] =
			{
				[38132] = true,								-- Paralyze - Target of Illidan's Demons
				[40932] = true,								-- Agonizing Flames (Illidan)
				[41917] = true,								-- Parasitic Shadowfiend (Illidan)
				[46787] = true,								-- Fel Rage (Gurtogg Bloodboil)
				[39837] = true,								-- Impaling Spine (Najentus)
				[41001] = true,								-- Fatal Attraction (Mother Shahrazz)
				[40251] = true,								-- Shadow of Death (Terron Gorefiend)
				[43581] = true,								-- Deadly Poison (Illidari Council)
				[40585] = true,								-- Dark Barrage (Illidan)
			},
		[XPERL_LOC_ZONE_HYJAL_SUMMIT] =
			{
				[39941] = true,								-- Inferno
				[31347] = true,								-- Doom
			},
		[XPERL_LOC_ZONE_KARAZHAN] =
			{
				[34661] = true,								-- Sacrifice (Illhoof)
				[30753] = true,								-- Red Riding Hood (Big Bad Wolf)
			},
		[XPERL_LOC_ZONE_SUNWELL_PLATEAU] =
			{
				[45141] = true,								-- Burn (Brutallus)
				[45662] = true,								-- Encapsulate (Felmyst)
				[45855] = true,								-- Gas Nova (Felmyst)
				[45342] = true,								-- Conflagration (Grand Warlock Alythess)
				[45641] = true,								-- Fire Bloom (Kil'Jaeden)
			},
		[XPERL_LOC_ZONE_NAXXRAMAS] =
			{
				[29213] = true,								-- Curse of the Plaguebringer (Noth the Plaguebringer)
				[29212] = true,								-- Cripple (Noth the Plaguebringer)

				[29998] = true,								-- Decrepit Fever (Heigan the Unclean)
				[29310] = true,								-- Spell Disruption (Heigan the Unclean)

				[28169] = true,								-- Mutating Injection (Grobbulus)

				[54378] = true,								-- Mortal Wound (Gluth)
				[29306] = true,								-- Infected Wound (Gluth)

				[28542] = true,								-- Life Drain (Sapphiron)

				[28410] = true,								-- Chains of Kel'Thuzad (Kel'Thuzad)
				[27819] = true,								-- Detonate Mana (Kel'Thuzad)
				[27808] = true,								-- Frost Blast (Kel'Thuzad)

				[28622] = true,								-- Web Wrap (Maexxna)
				[54121] = true,								-- Necrotic Poison (Maexxna)
			},
		[XPERL_LOC_ZONE_OBSIDIAN_SANCTUM] =
			{
				[39647] = true,								-- Curse of Mending (Trash)

				[60708] = true,								-- Fade Armor (Sartharion)
				[57491] = true,								-- Flame Tsunami (Sartharion)
			},
		[XPERL_LOC_ZONE_EYE_OF_ETERNITY] =
			{
				[57407] = true,								-- Surge of Power (Malygos)
				[56272] = true,								-- Arcane Breath (Malygos)
			},
		[XPERL_LOC_ZONE_ULDUAR] =
			{
				[62928] = true,								-- Impale (Elder IronBranch)

				[62589] = true,								-- Nature's Fury (Freya)
				[62532] = true,								-- Conservator's Grip (Freya)
				[62861] = true,								-- Iron Roots (Freya)

				[62469] = true,								-- Freeze (Hodir)
				[61969] = true,								-- Flash Freeze (Hodir)
				[62188] = true,								-- Biting Cold (Hodir)

				[62680] = true,								-- Flame Jet (Ignis the Furnace Master)
				[62717] = true,								-- Slag Pot (Ignis the Furnace Master)

				[64290] = true,								-- Stone Grip (Kologarn)
				[63355] = true,								-- Crunch Armor (Kologarn)
				[62055] = true,								-- Brittle Skin (Kologarn)

				[62042] = true,								-- Stormhammer (Thorim)
				[62130] = true,								-- Unbalancing Strike (Thorim)
				[62526] = true,								-- Rune Detonation (Thorim)
				[62470] = true,								-- Deafening Thunder (Thorim)
				[62331] = true,								-- Impale (Thorim)

				[63018] = true,								-- Light Bomb (XT-002 Deconstructor)
				[63024] = true,								-- Gravity Bomb (XT-002 Deconstructor)

				[61888] = true,								-- Overwhelming Power(The Assembly of Iron)
				[61903] = true,								-- Fusion Punch (The Assembly of Iron)

				[63666] = true,								-- Napalm Shell (Mimiron)
				[62997] = true,								-- Plasma Blast (Mimiron)
				[64668] = true,								-- Magnetic Field (Mimiron)

				[63276] = true,								-- Mark of the Faceless (General Vezax)
				[63322] = true,								-- Saronite Vapors (General Vezax)

				[63830] = true,								-- Malady of the Mind (Yogg-Saron)
				[63802] = true,								-- Brain Link (Yogg-Saron)
				[63042] = true,								-- Dominate Mind (Yogg-Saron)
				[64156] = true,								-- Apathy (Yogg-Saron)
				[64153] = true,								-- Black Plague (Yogg-Saron)
				[64157] = true,								-- Curse of Doom (Yogg-Saron)
				[64152] = true,								-- Draining Poison (Yogg-Saron)
				[64125] = true,								-- Squeeze (Yogg-Saron)
			},
		[XPERL_LOC_ZONE_TRIAL_OF_THE_CRUSADER] =
			{
				[66237] = true,								-- Incinerate Flesh (Lord Jaraxxus)

				[67700] = true,								-- Penetrating Cold (Anub'arak)
				[65775] = true,								-- Acid-Drenched Mandibles (Anub'arak)
			},
		[XPERL_LOC_ZONE_ICECROWN_CITADEL] =
			{
--				[70451] = true,								-- Blood Mirror (Trash)
--				[70432] = true,								-- Blood Sap (Trash)
--				[71154] = true,								-- Rend Flesh (Trash)

				[69065] = true,								-- Impaled (Lord Marrowgars)

				[71289] = true,								-- Dominate Mind (Lady Deathwhisper)

				[72293] = true,								-- Mark of the Fallen Champion (Deathbringer Saurfang)
				[72438] = true,								-- Blood Nova (Deathbringer Saurfang)

				[73020] = true,								-- Vile Gas (Festergut/Heroic Rotface)
				[69674] = true,								-- Mutated Infection (Rotface)

				[70672] = true,								-- Gaseous Bloat (Professor Putricide)
				[70447] = true,								-- Volatile Ooze Adhesive (Professor Putricide)
				[72855] = true,								-- Unbound Plague (Professor Putricide)

				[71340] = true,								-- Pact of the Darkfallen (Blood Queen Lanathel)
				[71473] = true,								-- Essence of the Blood Queen (Blood Queen Lanathel)

				[71283] = true,								-- Gut Spray (Valithria Dreamwalker)
				[70751] = true,								-- Corrosion (Valithria Dreamwalker)

				[70126] = true,								-- Frost Beacon (Sindragosa)
				[69762] = true,								-- Unchained Magic (Sindragosa)

				[70337] = true,								-- Necrotic Plague (The Lich King)
				[70541] = true,								-- Infest (The Lich King)
				[69409] = true,								-- Soul Reaper (The Lich King)
				[68980] = true,								-- Harvest Soul (The Lich King)
			},
		[XPERL_LOC_ZONE_RUBY_SANCTUM] =
			{
				[74505] = true,								-- Enervating Brand (Baltharus)

				[74453] = true,								-- Flame Beacon (Saviana)
				[74456] = true,								-- Conflagration (Saviana)

				[74367] = true,								-- Cleave Armor (Zarithrian)

				[74792] = true,								-- Shadow Consumption (Halion)
				[74562] = true,								-- Fiery Combustion (Halion)
			},
		[XPERL_LOC_ZONE_BARADIN_HOLD] =
			{
				[88954] = true,								-- Consuming Darkness (Argaloth)
			},
		[XPERL_LOC_ZONE_BLACKWING_DECENT] =
			{
				[80094] = true,								-- Fixate (Toxitron)
				[79501] = true,								-- Aquiring Target (Magmatron)
				[79888] = true,								-- Lightning Conductor (Electron)
				[92053] = true,								-- Shadow Conductor (Omnitron Heroic)

				[89773] = true,								-- Mangle (Magmaw)
				[78941] = true,								-- Paracite Infection (Magmaw)

				[77699] = true,								-- Flash Freeze (Maloriak)
				[77760] = true,								-- Biting Chill (Maloriak)
				[77786] = true,								-- Consuming Flames (Maloriak)

				[82935] = true,								-- Caustic Slime (Chimaeron)
				[89084] = true,								-- Low Health (Chimaeron)

				[78092] = true,								-- Tracking (Atramedes)
				[92685] = true,								-- Pestered! (Atramedes Heroic)

				[79318] = true,								-- Dominion (Nefarian Heroic)
				[79339] = true,								-- Explosive Cinders (Nefarian Heroic)
			},
		[XPERL_LOC_ZONE_BASTION_OF_TWILIGHT] =
			{
				[86788] = true,								-- Blackout (Valiona & Theralion)
				[86622] = true,								-- Engulfing Magic (Valiona & Theralion)
				[88518] = true,								-- Twilight Meteorite (Valiona & Theralion)

				[82665] = true,								-- Heart of Ice (Ascendant Council)
				[82772] = true,								-- Frozen (Ascendant Council)
				[82660] = true,								-- Burning Blood (Ascendant Council)
				[83099] = true,								-- Lightning Rod (Ascendant Council)
				[84948] = true,								-- Gravity Crush (Ascendant Council)
				[92067] = true,								-- Static Overload (Ascendant Council Heroic)
				[92075] = true,								-- Gravity Core (Ascendant Council Heroic)
				[92307] = true,								-- Frost Beacon (Ascendant Council Heroic)

				[91317] = true,								-- Worshipping (Cho'gall)

				[89421] = true,								-- Wrack (Sinestra)
			},
		[XPERL_LOC_ZONE_THRONE_OF_FOUR_WINDS] =
			{
				[93057] = true,								-- Slicing Gale (Conclave of Wind)
				[84645] = true,								-- Wind Chill (Conclave of Wind)

				[89668] = true,								-- Lightning Rod (Al'Akir)
			},
		[XPERL_LOC_ZONE_FIRELANDS] =
			{
				[99837] = true,								-- Crystal Prison Trapped (Shannox)
				[99838] = true,								-- Immo Trap Debuff (Shannox)

				[99476] = true,								-- Widows Kiss (Beth'tilac)
				[99526] = true,								-- Fixate (Beth'tilac Heroic)

				[101223] = true,							-- Fieroblast(Alysrazor)

				[99402] = true,								-- Tormented (Baloroc)
				[99516] = true,								-- Countdown (Baloroc Heroic)

				[98450] = true,								-- Searing Seed (Staghelm)
				[98584] = true,								-- Burning Orb (Staghelm)

				[100460] = true,							-- Blazing Heat(Ragnaros)
				[99849] = true,								-- Fixate (Ragnaros)
				[98928] = true,								-- Lava Wave (Ragnaros)
			},
		[XPERL_LOC_ZONE_DRAGONSOUL] =
			{
				[103434] = true,							-- Disrupting Shadows (Zon'Ozz)

				[105171] = true,							-- Deep Corruption (Yor'Sahj)

				[109325] = true,							-- Frostflake (Hagara Heroic)

				[109075] = true,							-- Fading Light (Ultraxion)

				[107439] = true,							-- Twilight Barrage (Blackhorn Heroic)
				[110214] = true,							-- Consuming Shroud (Blackhorn Heroic)

				[105479] = true,							-- Searing Plasma (Spine of Deathwing)
				[105490] = true,							-- Grip (Spine of Deathwing)
				[106199] = true,							-- Blood Corruption: Death (Heroic Spine of Deathwing)

				[106794] = true,							-- Shrapnal (Madness of Deathwing)
				[106730] = true,							-- Tetanus (Madness of Deathwing)
				[108649] = true,							-- Parasite (Madness of Deathwing Heroic)
			},
	}
end

-- SetDefaultZoneData
function ch:SetDefaultZoneData()
	if (conf) then
		conf.zones = self:DefaultZoneData()
		XPerlDB.custom.zones = conf.zones
		self:PLAYER_ENTERING_WORLD()
	end
end

-- SetDefaultZoneData
function ch:SetDefaults()
	if (conf) then
		conf.alpha = 0.5
		conf.blend = "ADD"
		self:SetDefaultZoneData()
	end
end

-- ch:PLAYER_ENTERING_WORLD
function ch:PLAYER_ENTERING_WORLD()
	if (conf and conf.enable) then
		if (not conf.zones) then
			conf.zones = self:DefaultZoneData()
		end
		local zoneName = GetRealZoneText()
		self.zoneDataRaw = conf and conf.zones[zoneName]

		if (self.zoneDataRaw) then
			self.zoneData = {}
			for spellid in pairs(self.zoneDataRaw) do
				local spellName, _, icon = GetSpellInfo(spellid)
				if (spellName) then
					self.zoneData[spellName] = icon
				end
			end
		else
			self.zoneData = nil
		end
	else
		self.zoneData = nil
	end
end

ch.ZONE_CHANGED_NEW_AREA = ch.PLAYER_ENTERING_WORLD
--ch.MINIMAP_ZONE_CHANGED = ch.PLAYER_ENTERING_WORLD

-- UpdateRoster
function ch:UpdateUnits()
	for unit, frame in pairs(self.RaidFrameArray) do
		if (frame:IsShown()) then
			self:Check(frame, unit)
		end
	end
end

-- IconAcquire
function ch:IconAcquire()
	if (not self.icons) then
		self.icons = { }
	end
	if (not self.usedIcons) then
		self.usedIcons = { }
	end

	local icon = self.icons[1]
	if (not icon) then
		icon = CreateFrame("Frame", nil)
		icon:SetFrameStrata("MEDIUM")
		icon.tex = icon:CreateTexture(nil, "OVERLAY")
		icon.tex:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		icon.tex:SetAllPoints(true)
		icon.tex:SetBlendMode(conf.blend or "ADD")
	else
		tremove(self.icons, 1)
	end

	self.usedIcons[icon] = true
	return icon
end

-- IconFree
function ch:IconFree(icon)
	icon:Hide()
	tinsert(self.icons, icon)
	self.usedIcons[icon] = nil
end

-- ch:Highlight
function ch:Highlight(frame, mode, unit, debuff, buffIcon)
	if (not self.active[frame]) then
		self.active[frame] = buffIcon
		local c = frame.customHighlight
		if (not c) then
			c = { }
			frame.customHighlight = c
		end
		c.type = mode
		local icon = self:IconAcquire()
		c.icon = icon

		icon:ClearAllPoints()
		icon:SetPoint("CENTER", frame, "CENTER")
		local size = frame:GetHeight() * frame:GetEffectiveScale()
		icon:SetWidth(size)
		icon:SetHeight(size)
		icon:SetAlpha(conf.alpha or 0.5)
		icon.tex:SetBlendMode(conf.blend or "ADD")

		icon.tex:SetTexture(buffIcon)
		icon:Show()
	end
end

-- Clear
function ch:Clear(frame)
	if (self.active[frame]) then
		self.active[frame] = nil
		local c = frame.customHighlight
		if (c) then
			self:IconFree(c.icon)
			c.icon = nil
		end
	end
end

-- Clear
function ch:ClearAll()
	if not self.usedIcons then
		return
	end
	for frame in pairs(self.usedIcons) do
		local icon = self.usedIcons[frame]
		self.usedIcons[frame] = true
		tinsert(self.icons, icon)
		self.active[frame] = nil
		icon:Hide()
	end
end

-- UNIT_AURA
function ch:UNIT_AURA(unit)
	local frame = XPerl_Raid_GetUnitFrameByUnit(unit)
	if (frame) then
		self:Check(frame, unit)
	end
end

-- ch:Check
function ch:Check(frame, unit)
	if conf and (not conf.enable) then
		return
	end

	local z = self.zoneData
	if (z) then
		if (not unit) then
			unit = frame:GetAttribute("unit")
			if (not unit) then
				unit = SecureButton_GetUnit(frame)
				if (not unit) then
					return
				end
			end
		end

		for i = 1, 40 do
			local name, icon = UnitAura(unit, i, "HARMFUL")
			if (not name) then
				break
			end
			if (z[name]) then
				self:Highlight(frame, "debuff", unit, name, icon)
				return
			end
		end
	end

	self:Clear(frame)
end

if (not conf) then
	conf = {
		enable = true,
		zones = ch:DefaultZoneData(),
	}
end

ch:SetScript("OnEvent", ch.OnEvent)

ch:PLAYER_ENTERING_WORLD()
