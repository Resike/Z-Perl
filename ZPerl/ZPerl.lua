-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

local conf

ZPerl.RequestConfig(function(New)
	conf = New
end, "$Revision: 12000 $")
ZPerl.SetModuleRevision("$Revision: 12000 $")

local ForeverAPI = ZPerl.ForeverAPI
------------------------------------------------------------------------------

-- Upvalues
local _G = _G

local format = format
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local strmatch = strmatch
local strupper = strupper
local tinsert = tinsert

local C_CurveUtil = C_CurveUtil
local C_Spell = C_Spell
local C_SpellBook = C_SpellBook
local CreateFrame = CreateFrame
local GetNumSpellTabs = GetNumSpellTabs
local GetSpellBookItemInfo = GetSpellBookItemInfo
local GetSpellTabInfo = GetSpellTabInfo
local IsPassiveSpell = IsPassiveSpell
local SecureButton_GetUnit = SecureButton_GetUnit
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitInRange = UnitInRange
local UnitIsConnected = UnitIsConnected
local UnitIsVisible = UnitIsVisible
local UnregisterUnitWatch = UnregisterUnitWatch

local BOOKTYPE_SPELL = BOOKTYPE_SPELL
local Enum = Enum
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local AlternatePowerBar = AlternatePowerBar
local PlayerFrame = PlayerFrame
local UIParent = UIParent

local ArcaneExclusions = ZPerl.ArcaneExclusions

local CanAccess = ZPerl.CanAccess
local IsSecret = ZPerl.IsSecret


--[==[@debug@
local function d(...)
	ChatFrame1:AddMessage(format(...))
end
--@end-debug@]==]

-- Compact Raid frame manager
local c = _G.CompactRaidFrameManager
if c then
	c:SetFrameStrata("MEDIUM")
end

------------------------------------------------------------------------------
-- Re-usable tables
--[[ local FreeTables = setmetatable({}, {__mode = "k"})

function ZPerl.GetReusableTable(...)
	for t in pairs(FreeTables) do
		FreeTables[t] = nil
		for i = 1, select("#", ...) do
			t[i] = select(i, ...)
		end
		return t
	end
	return {...}
end

function ZPerl.FreeTable(t, deep)
	if (t) then
		if (type(t) ~= "table") then
			error("Usage: ZPerl.FreeTable([table])")
		end
		if (FreeTables[t]) then
			error("ZPerl.FreeTable - Table already freed")
		end

		FreeTables[t] = true
		for k, v in pairs(t) do
			if (deep and type(v) == "table") then
				ZPerl.FreeTable(v, true)
			end
			t[k] = nil
		end
		--t[''] = 0
		--t[''] = nil
	end
end ]]

--local new, del = ZPerl.GetReusableTable, ZPerl.FreeTable

-- meta table for string based colors. Allows for other mods changing class colors and things all working:
-- class lookups are not cached, so a later change to CUSTOM_CLASS_COLORS shows up. Keys set directly
-- (ZPerl.ColorTable.pet) still win.
ZPerl.ColorTable = setmetatable({ }, {
	__index = function(self, class)
		if not class then
			return
		end
		local color = (_G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS)[strupper(class)]
		if (color) then
			return format("|c00%02X%02X%02X", 255 * color.r, 255 * color.g, 255 * color.b)
		end
		return "|c00808080"
	end
})

--ZPerl_Percent = setmetatable({},
--	{__mode = "kv",
--	__index = function(self, i)
--		if (type(i) == "number" and i >= 0) then
--			self[i] = format(percD, i)
--			return self[i]
--		end
--		return ""
--	end
--	})
--local xpPercent = ZPerl_Percent


-- We have a dummy do-nothing function here for classes that don't have range checking
-- The do-something function is setup after variables_loaded and we work out spell to use just once
function ZPerl.UpdateSpellRange(...)
end

--local SpiritRealm = (C_Spell and C_Spell.GetSpellInfo(235621)) and C_Spell.GetSpellInfo(235621).name or GetSpellInfo(235621)

-- Excluded(name, unit): the debuff is one of ZPerl.ArcaneExclusions for this unit. An entry is true (every
-- class) or a set of class tokens, as ZPerl.CheckDebuffs reads it; a secret class matches no set.
local function Excluded(name, unit)
	local e = ArcaneExclusions[name]
	if (type(e) == "table") then
		local _, class = UnitClass(unit)
		---@diagnostic disable-next-line: secret-table-key
		return CanAccess(class) and e[class] or false
	end
	return e
end

-- DoRangeCheck
-- HealthAbove(unit, mark) - true when the unit's health is over the fraction `mark`. A dead unit is not; a unit whose
-- health is secret is not either, so the plain range check decides instead of fading everyone.
local function HealthAbove(unit, mark)
	if ZPerl.SafeBool(UnitIsDeadOrGhost(unit), false) then
		return false
	end
	local hp, hpMax = UnitHealth(unit), UnitHealthMax(unit)
	if not CanAccess(hp) or not CanAccess(hpMax) then
		return false
	end
	-- both readable (checked above)
	---@diagnostic disable-next-line: secret-comparison
	if hpMax <= 0 then
		---@diagnostic disable-next-line: secret-comparison
		return hp > 0 -- the maximum failed: alive counts as full
	end
	---@diagnostic disable-next-line: secret-arithmetic, secret-comparison
	return hp / hpMax > mark
end

local function DoRangeCheck(unit, opt)
	local range
	-- PlusHealth (Health check): a unit over the health marker needs no heal, so it fades as if out of range. With
	-- PlusDebuff as well, such a unit is still clear when it has a curable debuff; a unit under the marker skips the
	-- debuff check and only the range decides.
	if opt.PlusHealth and HealthAbove(unit, opt.HealthLowPoint or 0.85) then
		range = 0
	end
	-- UnitAuraByIndex fetches the aura list once per unit, filter and frame time (ZPerl_Values.lua) and returns
	-- at once while auras are secret; this runs per frame per range tick only with the PlusDebuff option on.
	-- While auras are secret no debuff can be seen, so the plain range check decides instead of fading everyone.
	if opt.PlusDebuff and (not opt.PlusHealth or range == 0) and not ZPerl.AurasSecret() then
		local name = ZPerl.UnitAuraByIndex(unit, 1, "HARMFUL|RAID")
		if not name then
			range = 0
		elseif not CanAccess(name) then
			-- A secret name still proves a curable debuff is there
			range = nil
		else
			if Excluded(name, unit) then
				-- It's one of the filtered debuffs, so we have to iterate thru all debuffs to see if anything is curable
				range = 0 -- stays 0 when all 40 are filtered ones
				for i = 1, 40 do
					local auraName = ZPerl.UnitAuraByIndex(unit, i, "HARMFUL|RAID")
					if not auraName then
						range = 0
						break
					elseif not CanAccess(auraName) or not Excluded(auraName, unit) then
						range = nil
						break
					end
				end
			else
				range = nil -- a debuff on the unit: the plain range check decides
			end
		end
	end

	if not range then
		-- opt.interact set: the group range (40 yards) alone. Otherwise the part's own assist (spell) or attack (spell2)
		-- spell, or the one picked from the spellbook when none is set.
		local spell
		if not opt.interact then
			local kind = UnitCanAttack("player", unit) and "harm" or (UnitCanAssist("player", unit) and "help")
			if kind then
				spell = opt[kind == "harm" and "spell2" or "spell"] or ZPerl.RangeSpells[kind]
			end
		end
		if spell then
			range = C_Spell.IsSpellInRange(spell, unit)
		end
		-- No answer (no spell, or the check is invalid): a group member follows the group range, any other unit is in range.
		if not IsSecret(range) and range == nil then
			if ZPerl.SafeBool(UnitInRaid(unit), false) or ZPerl.SafeBool(UnitInParty(unit), false) then
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not ZPerl.SafeBool(checkedRange, true) then
					range = 1
				end
			else
				range = 1
			end
		end
	end

	-- a secret range result is returned as-is; the caller turns
	-- it into an alpha with ZPerl.RangeAlpha instead of comparing it here.
	if (IsSecret(range)) then
		return range, true
	end

	---@diagnostic disable-next-line: secret-comparison
	if range ~= 1 and range ~= true then
		return opt.FadeAmount
	end
end

-- ZPerl.RangeAlpha(result, secret, inAlpha, outAlpha)
-- Converts a DoRangeCheck result into an alpha value without Lua comparisons
-- when the result is secret. inAlpha is used when in range, outAlpha when not.
function ZPerl.RangeAlpha(result, secret, inAlpha, outAlpha)
	if (secret) then
		if (ForeverAPI.booleanCurves) then
			return C_CurveUtil.EvaluateColorValueFromBoolean(result, inAlpha, outAlpha)
		end
		return inAlpha
	end
	if (result) then
		return outAlpha
	end
	return inAlpha
end

-- ZPerl.UpdateSpellRangeSecure(self, unit, isRaidFrame)
-- Restricted-client version of the range fader. Every alpha is produced by
-- ZPerl.RangeAlpha and handed straight to SetAlpha, so nothing here branches
-- on a unit value.
function ZPerl.UpdateSpellRangeSecure(self, unit, isRaidFrame)
	local rf = conf.rangeFinder
	local base = conf.transparency.frame
	local mainA, nameA, statsA = base, 1, 1

	if (rf.enabled and (isRaidFrame or not rf.raidOnly)) then
		if (rf.Main.enabled) then
			local result, secret = DoRangeCheck(unit, rf.Main)
			mainA = ZPerl.RangeAlpha(result, secret, base, base * rf.Main.FadeAmount)
		else
			if (rf.NameFrame.enabled) then
				local result, secret = DoRangeCheck(unit, rf.NameFrame)
				nameA = ZPerl.RangeAlpha(result, secret, 1, rf.NameFrame.FadeAmount)
			end
			if (rf.StatsFrame.enabled) then
				local result, secret = DoRangeCheck(unit, rf.StatsFrame)
				statsA = ZPerl.RangeAlpha(result, secret, 1, rf.StatsFrame.FadeAmount)
			end
		end
	end

	local connected = UnitIsConnected(unit)
	if (CanAccess(connected) and not connected) then
		mainA = base * rf.Main.FadeAmount
		nameA, statsA = 1, 1
	end

	self:SetAlpha(mainA)
	if (self.nameFrame) then
		self.nameFrame:SetAlpha(nameA)
	end
	if (self.statsFrame) then
		self.statsFrame:SetAlpha(statsA)
	end
end

-- ZPerl.UpdateSpellRange(self)
function ZPerl.UpdateSpellRange2(self, overrideUnit, isRaidFrame)
	local unit
	if (overrideUnit) then
		unit = overrideUnit
	else
		unit = self:GetAttribute("unit")
		if (not unit) then
			unit = SecureButton_GetUnit(self)
		end
	end
	if (unit) then
		if (ForeverAPI.booleanCurves) then
			ZPerl.UpdateSpellRangeSecure(self, unit, isRaidFrame)
			return
		end

		local rf = conf.rangeFinder
		local mainA, nameA, statsA -- Receives main, name and stats alpha levels

		if (rf.enabled and (isRaidFrame or not conf.rangeFinder.raidOnly)) then
			if (not UnitIsVisible(unit)) then
				if (rf.Main.enabled) then
					mainA = conf.transparency.frame * rf.Main.FadeAmount
				else
					if (rf.NameFrame.enabled) then
						nameA = rf.NameFrame.FadeAmount
					end
					if (rf.StatsFrame.enabled) then
						statsA = rf.StatsFrame.FadeAmount
					end
				end
			else
				if (rf.Main.enabled) then
					mainA = DoRangeCheck(unit, rf.Main)
					if (mainA) then
						mainA = mainA * conf.transparency.frame
					end
				end

				if (rf.NameFrame.enabled) then
					-- the parts share one range check
					if (rf.Main.enabled) then
						if (mainA) then
							nameA = rf.NameFrame.FadeAmount
						end
					else
						nameA = DoRangeCheck(unit, rf.NameFrame)
						if (not nameA and mainA) then
							-- In range, but 'Whole' frame is out of range, so we need to override the fade for name
							nameA = 1
						end
					end
				end
				if (rf.StatsFrame.enabled) then
					-- the parts share one range check
					if (rf.Main.enabled) then
						if (mainA) then
							statsA = rf.StatsFrame.FadeAmount
						end
					else
						statsA = DoRangeCheck(unit, rf.StatsFrame)
						if (not statsA and mainA) then
							-- In range, but 'Whole' frame is out of range, so we need to override the fade for stats
							statsA = 1
						end
					end
				end
			end
		end

		local forcedMainA
		if (not mainA) then
			if (UnitIsConnected(unit)) then
				mainA = conf.transparency.frame
				forcedMainA = true
			else
				mainA = conf.transparency.frame * rf.Main.FadeAmount
				nameA, statsA = mainA, mainA
				forcedMainA = true
			end
		end

		self:SetAlpha(mainA)
		if (self.nameFrame) then
			if (nameA or forcedMainA) then
				self.nameFrame:SetAlpha(nameA or mainA)
			else
				self.nameFrame:SetAlpha(1)
			end
		end
		if (self.statsFrame) then
			if (statsA or forcedMainA) then
				self.statsFrame:SetAlpha(statsA or mainA)
			else
				self.statsFrame:SetAlpha(1)
			end
		end
	end
end

-- ZPerl.RangeSpells = {help = spellID, harm = spellID}
-- The spells DoRangeCheck asks for a friendly and a hostile unit. Runtime only, never saved.
ZPerl.RangeSpells = {}

-- ZPerl.PickRangeSpells()
-- Picks from the player's spellbook the helpful and the harmful spell with the longest range. A spell with
-- a minimum range is skipped: it would fade a close enemy. The first spell found wins a tie.
-- The spell IDs of the player's active, non-passive spellbook spells, by whichever spellbook API the client
-- has: C_SpellBook skill lines (retail, newer Classic), or the older spell tabs (Classic Era).
local function SpellbookSpellIDs()
	local ids = {}
	if (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then
		local bank, spellType = Enum.SpellBookSpellBank.Player, Enum.SpellBookItemType.Spell
		for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local line = C_SpellBook.GetSpellBookSkillLineInfo(i)
			if (line and not line.shouldHide and not line.isGuild and not line.offSpecID) then
				for slot = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
					local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
					if (item and item.itemType == spellType and not item.isPassive and not item.isOffSpec and item.spellID) then
						ids[#ids + 1] = item.spellID
					end
				end
			end
		end
	elseif (GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo) then
		local book = BOOKTYPE_SPELL or "spell"
		for tab = 1, GetNumSpellTabs() do
			local _, _, offset, numSlots = GetSpellTabInfo(tab)
			for slot = offset + 1, offset + numSlots do
				local kind, id = GetSpellBookItemInfo(slot, book)
				if (kind == "SPELL" and id and not (IsPassiveSpell and IsPassiveSpell(id))) then
					ids[#ids + 1] = id
				end
			end
		end
	end
	return ids
end

function ZPerl.PickRangeSpells()
	local help, harm, helpRange, harmRange
	for _, id in ipairs(SpellbookSpellIDs()) do
		if (C_Spell.SpellHasRange(id)) then
			local info = C_Spell.GetSpellInfo(id)
			if (info and info.minRange == 0 and info.maxRange) then
				if (C_Spell.IsSpellHelpful(id) and (not helpRange or info.maxRange > helpRange)) then
					help, helpRange = id, info.maxRange
				end
				if (C_Spell.IsSpellHarmful(id) and (not harmRange or info.maxRange > harmRange)) then
					harm, harmRange = id, info.maxRange
				end
			end
		end
	end
	ZPerl.RangeSpells.help, ZPerl.RangeSpells.harm = help, harm
end

ZPerl.On("SPELLS_CHANGED", ZPerl.PickRangeSpells)

-- ZPerl.StartupSpellRange()
function ZPerl.StartupSpellRange()
	local rf = conf.rangeFinder

	local function Setup1(self)
		if (not self.FadeAmount) then
			self.FadeAmount = 0.3
		end
		-- the old window's 10, 20, 30 and 45 yard choices all ran the group range check: they are the 40 yard choice
		if (self.interact) then
			self.interact = 5
		end
	end

	Setup1(rf.Main)
	Setup1(rf.NameFrame)
	Setup1(rf.StatsFrame)

	ZPerl.Pcall(ZPerl.PickRangeSpells)
	-- Put the real work function in place
	ZPerl.UpdateSpellRange = ZPerl.UpdateSpellRange2
end

ZPerl.RegisterOptionChanger(ZPerl.StartupSpellRange, nil, "spellrange")

-- StatsFrameSetGrey
local function StatsFrameSetGrey(self, r, g, b)
	if (not r) then
		r, g, b = 0.5, 0.5, 0.5
	end

	self.healthBar:SetStatusBarColor(r, g, b, 1)
	self.healthBar.bg:SetVertexColor(r, g, b, 0.5)
	if (self.manaBar) then
		self.manaBar:SetStatusBarColor(r, g, b, 1)
		self.manaBar.bg:SetVertexColor(r, g, b, 0.5)
	end
	self.greyMana = true
end

-- ZPerl.SetChildMembers - Recursive
-- This iterates a frame's child frames and regions and assigns member variables
-- based on the sub-set part of the child's name compared to the parent frame name
function ZPerl.SetChildMembers(self)
	local n = self:GetName()
	if (n) then
		local match = "^"..n:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0").."(.+)$"

		local function AddList(list)
			for _, v in pairs(list) do
				local t = v:GetName()
				if (t) then
					local found = strmatch(t, match)
					if (found) then
						--if (self[found] == v) then
						--	break		-- Already done
						--end
						self[found] = v
					end
				end
			end
		end

		AddList({self:GetRegions()})

		local children = {self:GetChildren()}
		AddList(children)

		for _, v in pairs(children) do
			if (v:GetName()) then
				ZPerl.SetChildMembers(v)
			end
			v:SetScript("OnLoad", nil)
		end

		self:SetScript("OnLoad", nil)
	end
end

-- ZPerl.BarTextures: Z-Perl's own bar textures, {name, file}, first in the Bar texture option and registered with
-- LibSharedMedia for other addons
ZPerl.BarTextures = {
	{"Perl v2", "Interface\\AddOns\\ZPerl\\Images\\ZPerl_StatusBar"},
}
for i = 1, 9 do
	local name = i == 2 and "BantoBar" or "X-Perl "..i
	tinsert(ZPerl.BarTextures, {name, "Interface\\AddOns\\ZPerl\\Images\\ZPerl_StatusBar"..(i + 1)})
end

do
	local media

	-- ZPerl.RegisterSMBarTextures
	function ZPerl.RegisterSMBarTextures()
		if (LibStub) then
			media = LibStub("LibSharedMedia-3.0", true)
		end

		if (media) then
			for _, v in pairs(ZPerl.BarTextures) do
				media:Register("statusbar", v[1], v[2])
			end

			media:Register("border", "X-Perl Thin", "Interface\\AddOns\\ZPerl\\Images\\ZPerl_ThinEdge")
		end
	end
end

-- ZPerl.GetBarTexture
function ZPerl.GetBarTexture()
	local texture = conf and conf.bar and conf.bar.texture and conf.bar.texture[2]
	if texture then
		return texture
	end
	return "Interface\\AddOns\\ZPerl\\Images\\ZPerl_StatusBar"
end

-- ZPerl.StatsFrameOnLoad
function ZPerl.StatsFrameOnLoad(self)
	self:OnBackdropLoaded()
	ZPerl.SetChildMembers(self)
	self.SetGrey = StatsFrameSetGrey
end

-- ZPerl.GetClassColor
local defaultColor = {r = 0.5, g = 0.5, b = 1}
function ZPerl.GetClassColor(class)
	return (class and CanAccess(class) and (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]) or defaultColor
end

local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()
local hideWanted = {}	-- frame -> true while Z-Perl keeps it hidden
local ownParent = {}	-- frame -> the parent it goes back to when Z-Perl stops hiding it
local hideHooked = {}
local reparenting

local function applyBlizzHide(frame)
	reparenting = true
	if (hideWanted[frame]) then
		frame:SetParent(hiddenParent)
	elseif (ownParent[frame]) then
		-- a parent Z-Perl hides (the cast bar locked to PlayerFrame) would keep it hidden
		local parent = ownParent[frame]
		frame:SetParent(hideWanted[parent] and UIParent or parent)
		ownParent[frame] = nil
	end
	reparenting = nil
end

local function blizzHideNow(frame)
	-- in combat even an unprotected frame waits: Blizzard's layout code runs on its reparent
	ZPerl.AfterCombatFor(applyBlizzHide, frame)
end

-- ZPerl.BlizzFrameHide(frame, hide)
-- The one way Z-Perl hides a Blizzard frame: parented to a
-- hidden frame, so no Show() of Blizzard's makes it visible, and a SetParent of Blizzard's is undone.
-- hide false gives the frame its parent back. In combat the frame moves at combat end.
function ZPerl.BlizzFrameHide(frame, hide)
	if (not frame or not hide == not hideWanted[frame]) then
		return
	end
	if (hide and not ownParent[frame]) then
		ownParent[frame] = frame:GetParent() or UIParent
	end
	hideWanted[frame] = hide and true or nil
	if (hide and not hideHooked[frame]) then
		hideHooked[frame] = true
		hooksecurefunc(frame, "SetParent", function(self, parent)
			if (reparenting or not hideWanted[self]) then
				return
			end
			-- Blizzard moved it: that parent is the one to give back
			ownParent[self] = parent
			blizzHideNow(self)
		end)
	end
	blizzHideNow(frame)
end

---------------------------------
--Loading Function             --
---------------------------------

-- ZPerl.BlizzFrameDisable(frame)
-- Hides a Blizzard frame for good: its events (and its bars' events) off, then ZPerl.BlizzFrameHide.
function ZPerl.BlizzFrameDisable(self)
	if not self then
		return
	end

	UnregisterUnitWatch(self)

	self:UnregisterAllEvents()

	if self == PlayerFrame then
		if AlternatePowerBar then
			AlternatePowerBar:UnregisterAllEvents()
		end
	end

	self:SetMovable(true)
	self:SetUserPlaced(true)
	self:SetDontSavePosition(true)
	self:SetMovable(false)

	ZPerl.BlizzFrameHide(self, true)

	local health = self.healthBar or self.healthbar or self.HealthBar
	if health then
		health:UnregisterAllEvents()
	end

	local power = self.manabar or self.ManaBar
	if power then
		power:UnregisterAllEvents()
	end

	local spell = self.castBar or self.spellbar or self.CastingBarFrame
	if spell then
		spell:UnregisterAllEvents()
	end

	local powerBarAlt = self.powerBarAlt or self.PowerBarAlt
	if powerBarAlt then
		powerBarAlt:UnregisterAllEvents()
	end

	local buffFrame = self.BuffFrame
	if buffFrame then
		buffFrame:UnregisterAllEvents()
	end

	local debuffFrame = self.DebuffFrame
	if debuffFrame then
		debuffFrame:UnregisterAllEvents()
	end

	-- The player frame's class power bar also drives the Personal Resource Display's class
	-- resource (e.g. combo points, which other addons can show on the target nameplate).
	local classPowerBar = self.classPowerBar
	if classPowerBar and self ~= PlayerFrame then
		classPowerBar:UnregisterAllEvents()
	end

	local ccRemoverFrame = self.CcRemoverFrame
	if ccRemoverFrame then
		ccRemoverFrame:UnregisterAllEvents()
	end

	local petFrame = self.petFrame or self.PetFrame
	if petFrame then
		petFrame:UnregisterAllEvents()
	end
end

-- ZPerl.MainFrameStart(frame, on, blizz)
-- The once-a-session start of the Player, Pet and Target frames, run at the first profile hand-out (the
-- addon's files run before SavedVariables are read); their enable key takes effect after a reload. On:
-- Blizzard's frame is hidden for good. Off: the Z-Perl frame is hidden, its unit watch and events are off and
-- frame.off stops its Set_Bits; Blizzard's frame stays as it is.
function ZPerl.MainFrameStart(frame, on, blizz)
	if frame.started then
		return
	end
	frame.started = true
	if on then
		ZPerl.BlizzFrameDisable(blizz)
		return
	end
	frame.off = true
	UnregisterUnitWatch(frame)
	frame:UnregisterAllEvents()
	ZPerl.AfterCombatFor(frame.Hide, frame)
end

