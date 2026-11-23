-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

if (not ZPerl.RequestConfig) then
	return
end

local conf, rconf
ZPerl.RequestConfig(function(new)
	conf = new.custom
	rconf = new.raid
end, "$Revision:  $")

-- Upvalues
local pairs = pairs
local tinsert = tinsert
local tremove = tremove
local wipe = wipe

local CreateFrame = CreateFrame
local GetRealZoneText = GetRealZoneText
local SecureButton_GetUnit = SecureButton_GetUnit

local CustomHighlight = CreateFrame("Frame", "ZPerl_Custom")
CustomHighlight.active = {}
ZPerl.On("PLAYER_ENTERING_WORLD", function() CustomHighlight:PLAYER_ENTERING_WORLD() end)

CustomHighlight.RaidFrameArray = ZPerl.Raid.GetFrameArray()

-- DefaultZoneData
function CustomHighlight:DefaultZoneData()
	return {
		[L["LOC_ZONE_ANTORUS"]] =
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
		[L["LOC_ZONE_TOMB_OF_SARGERAS"]] =
			{
				[236449] = true,							-- Soulbind (The Desolate Host)
				[235213] = true,							-- Light Infusion (Maiden of Vigilance)
				[235240] = true,							-- Fel Infusion (Maiden of Vigilance)
				[240209] = true,							-- Unstable Soul (Maiden of Vigilance)
				[235222] = true,							-- Blood Siphon (Trash in front of Kil'Jaeden)
				[238429] = true,							-- Bursting Dreadflame (Kil'Jaeden)
			},
		[L["LOC_ZONE_SERPENTSHRINE_CAVERN"]] =
			{
				[38132] = true,								-- Paralyze - Picked up Tainted Core
			},
		[L["LOC_ZONE_BLACK_TEMPLE"]] =
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
		[L["LOC_ZONE_HYJAL_SUMMIT"]] =
			{
				[39941] = true,								-- Inferno
				[31347] = true,								-- Doom
			},
		[L["LOC_ZONE_KARAZHAN"]] =
			{
				[34661] = true,								-- Sacrifice (Illhoof)
				[30753] = true,								-- Red Riding Hood (Big Bad Wolf)
			},
		[L["LOC_ZONE_SUNWELL_PLATEAU"]] =
			{
				[45141] = true,								-- Burn (Brutallus)
				[45662] = true,								-- Encapsulate (Felmyst)
				[45855] = true,								-- Gas Nova (Felmyst)
				[45342] = true,								-- Conflagration (Grand Warlock Alythess)
				[45641] = true,								-- Fire Bloom (Kil'Jaeden)
			},
		[L["LOC_ZONE_NAXXRAMAS"]] =
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
		[L["LOC_ZONE_OBSIDIAN_SANCTUM"]] =
			{
				[39647] = true,								-- Curse of Mending (Trash)

				[60708] = true,								-- Fade Armor (Sartharion)
				[57491] = true,								-- Flame Tsunami (Sartharion)
			},
		[L["LOC_ZONE_EYE_OF_ETERNITY"]] =
			{
				[57407] = true,								-- Surge of Power (Malygos)
				[56272] = true,								-- Arcane Breath (Malygos)
			},
		[L["LOC_ZONE_ULDUAR"]] =
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
		[L["LOC_ZONE_TRIAL_OF_THE_CRUSADER"]] =
			{
				[66237] = true,								-- Incinerate Flesh (Lord Jaraxxus)

				[67700] = true,								-- Penetrating Cold (Anub'arak)
				[65775] = true,								-- Acid-Drenched Mandibles (Anub'arak)
			},
		[L["LOC_ZONE_ICECROWN_CITADEL"]] =
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
		[L["LOC_ZONE_RUBY_SANCTUM"]] =
			{
				[74505] = true,								-- Enervating Brand (Baltharus)

				[74453] = true,								-- Flame Beacon (Saviana)
				[74456] = true,								-- Conflagration (Saviana)

				[74367] = true,								-- Cleave Armor (Zarithrian)

				[74792] = true,								-- Shadow Consumption (Halion)
				[74562] = true,								-- Fiery Combustion (Halion)
			},
		[L["LOC_ZONE_BARADIN_HOLD"]] =
			{
				[88954] = true,								-- Consuming Darkness (Argaloth)
			},
		[L["LOC_ZONE_BLACKWING_DECENT"]] =
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
		[L["LOC_ZONE_BASTION_OF_TWILIGHT"]] =
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
		[L["LOC_ZONE_THRONE_OF_FOUR_WINDS"]] =
			{
				[93057] = true,								-- Slicing Gale (Conclave of Wind)
				[84645] = true,								-- Wind Chill (Conclave of Wind)

				[89668] = true,								-- Lightning Rod (Al'Akir)
			},
		[L["LOC_ZONE_FIRELANDS"]] =
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
		[L["LOC_ZONE_DRAGONSOUL"]] =
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

-- Enabled() - the highlight is on and the raid frames are too
local function Enabled()
	return conf and conf.enable and rconf and rconf.enable
end

local function OnUnitAura(_, unit)
	CustomHighlight:UNIT_AURA(unit)
end

local function OnZoneChanged()
	CustomHighlight:PLAYER_ENTERING_WORLD()
end

-- CustomHighlight:ReadZone - picks the current zone's list ({[spellID] = true}, matched against the aura's spellId)
-- The UNIT_AURA and zone handlers are registered only while the highlight is on.
function CustomHighlight:ReadZone()
	if Enabled() then
		if not self.listening then
			self.listening = true
			ZPerl.On("UNIT_AURA", OnUnitAura)
			ZPerl.On("ZONE_CHANGED_NEW_AREA", OnZoneChanged)
		end

		if not conf.zones then
			conf.zones = self:DefaultZoneData()
		end
		self.zoneData = conf.zones[GetRealZoneText()]
	else
		if self.listening then
			self.listening = nil
			ZPerl.Off("UNIT_AURA", OnUnitAura)
			ZPerl.Off("ZONE_CHANGED_NEW_AREA", OnZoneChanged)
		end
		self.zoneData = nil
	end
end

-- CustomHighlight:PLAYER_ENTERING_WORLD (and ZONE_CHANGED_NEW_AREA): the new zone's list, then every frame re-checked
-- so no icon of the previous zone stays up
function CustomHighlight:PLAYER_ENTERING_WORLD()
	self:ReadZone()
	if Enabled() then
		self:UpdateUnits()
	else
		self:ClearAll()
	end
end

-- CustomHighlight:UpdateUnits
function CustomHighlight:UpdateUnits()
	if not Enabled() then
		return
	end

	for unit, frame in pairs(self.RaidFrameArray) do
		if frame:IsShown() then
			self:Check(frame, unit)
		end
	end
end

-- CustomHighlight:Refresh: after a change of custom.enable, alpha or blend (the settings panel)
function CustomHighlight:Refresh()
	if Enabled() and self.usedIcons then
		for icon in pairs(self.usedIcons) do
			icon:SetAlpha(conf.alpha or 0.5)
			icon.tex:SetBlendMode(conf.blend or "ADD")
		end
	end
	self:PLAYER_ENTERING_WORLD()
end

-- CustomHighlight:IconAcquire
function CustomHighlight:IconAcquire()
	if not self.icons then
		self.icons = {}
	end
	if not self.usedIcons then
		self.usedIcons = {}
	end

	local icon = self.icons[1]
	if not icon then
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

-- CustomHighlight:IconFree
function CustomHighlight:IconFree(icon)
	icon:Hide()
	tinsert(self.icons, icon)
	self.usedIcons[icon] = nil
end

-- CustomHighlight:Highlight
function CustomHighlight:Highlight(frame, mode, unit, debuff, buffIcon)
	if self.active[frame] then
		-- Another matching debuff took over: show its icon
		if self.active[frame] ~= buffIcon and frame.customHighlight and frame.customHighlight.icon then
			self.active[frame] = buffIcon
			frame.customHighlight.icon.tex:SetTexture(buffIcon)
		end
	else
		self.active[frame] = buffIcon
		local c = frame.customHighlight
		if not c then
			c = {}
			frame.customHighlight = c
		end
		c.type = mode
		local icon = self:IconAcquire()
		c.icon = icon

		-- A child of the raid frame: it hides with the frame (and with the UI) and takes the frame's scale
		icon:SetParent(frame)
		icon:SetFrameLevel(frame:GetFrameLevel() + 10)
		icon:ClearAllPoints()
		icon:SetPoint("CENTER", frame, "CENTER")
		local size = frame:GetHeight()
		icon:SetWidth(size)
		icon:SetHeight(size)
		icon:SetAlpha(conf.alpha or 0.5)
		icon.tex:SetBlendMode(conf.blend or "ADD")

		icon.tex:SetTexture(buffIcon)
		icon:Show()
	end
end

-- CustomHighlight:Clear
function CustomHighlight:Clear(frame)
	if self.active[frame] then
		self.active[frame] = nil
		local c = frame.customHighlight
		if c then
			self:IconFree(c.icon)
			c.icon = nil
		end
	end
end

-- CustomHighlight:Clear
function CustomHighlight:ClearAll()
	if not self.usedIcons then
		return
	end
	-- usedIcons is a set keyed by icon (IconAcquire)
	for icon in pairs(self.usedIcons) do
		icon:Hide()
		tinsert(self.icons, icon)
	end
	wipe(self.usedIcons)
	wipe(self.active)
end

-- CustomHighlight:UNIT_AURA
-- Scans the unit's debuff slots on every event: no table builds, and the highlight must follow each aura change.
-- The raid frames are keyed by their unit: raidN, or player and partyN when they show a party (raid.inParty).
function CustomHighlight:UNIT_AURA(unit)
	local frame = ZPerl.Raid.GetUnitFrameByUnit(unit)
	if frame then
		self:Check(frame, unit)
	end
end

-- CustomHighlight:Check
function CustomHighlight:Check(frame, unit)
	if not Enabled() then
		return
	end

	local z = self.zoneData
	if z then
		if not unit then
			unit = frame:GetAttribute("unit")
			if not unit then
				unit = SecureButton_GetUnit(frame)
				if (not unit) then
					return
				end
			end
		end

		for i = 1, 40 do
			local name, icon, _, _, _, _, _, _, _, spellId = ZPerl.UnitAuraByIndex(unit, i, "HARMFUL")
			if not name then
				break
			end
			-- By spell ID: a name is shared by unrelated spells. A secret ID cannot be looked up.
			if spellId and ZPerl.CanAccess(spellId) and z[spellId] then
				self:Highlight(frame, "debuff", unit, name, icon)
				return
			end
		end
	end

	self:Clear(frame)
end

if not conf then
	conf = {
		enable = false,
		zones = CustomHighlight:DefaultZoneData(),
	}
end

CustomHighlight:PLAYER_ENTERING_WORLD()
