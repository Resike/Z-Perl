-- Z-Perl UnitFrames
-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

local conf
local percD	= "%d"..PERCENT_SYMBOL
local perc1F = "%.1f"..PERCENT_SYMBOL

XPerl_RequestConfig(function(New)
	conf = New
end, "$Revision: @project-revision@ $")
XPerl_SetModuleRevision("$Revision: @project-revision@ $")

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local IsPandaClassic = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
local IsVanillaClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local IsClassic = WOW_PROJECT_ID >= WOW_PROJECT_CLASSIC

local UnitAuraWithBuffs
local LCD = IsVanillaClassic and LibStub and LibStub("LibClassicDurations", true)
if LCD then
	LCD:Register("ZPerl")
	UnitAuraWithBuffs = LCD.UnitAuraWithBuffs
end
local HealComm = IsVanillaClassic and LibStub and LibStub("LibHealComm-4.0", true)

-- Upvalues
local _G = _G
local abs = abs
local atan2 = math.atan2
local collectgarbage = collectgarbage
local cos = cos
local deg = math.deg
local error = error
local floor = floor
local format = format
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local max = max
local min = min
local next = next
local pairs = pairs
local pcall = pcall
local print = print
local select = select
local setmetatable = setmetatable
local sin = sin
local string = string
local strmatch = strmatch
local strsub = strsub
local strupper = strupper
local tinsert = tinsert
local tonumber = tonumber
local tremove = tremove
local type = type
local unpack = unpack

local CheckInteractDistance = CheckInteractDistance
local CreateFrame = CreateFrame
local DebuffTypeColor = DebuffTypeColor
local GetAddOnCPUUsage = GetAddOnCPUUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local GetCursorPosition = GetCursorPosition
local GetDifficultyColor = GetDifficultyColor or GetQuestDifficultyColor
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetLocale = GetLocale
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetRaidTargetIndex = GetRaidTargetIndex
local GetReadyCheckStatus = GetReadyCheckStatus
local GetRealmName = GetRealmName
local GetRealZoneText = GetRealZoneText
local GetSpecialization = GetSpecialization
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsAddOnLoaded = IsAddOnLoaded
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsInRaid = IsInRaid
local IsItemInRange = IsItemInRange
local IsShiftKeyDown = IsShiftKeyDown
local IsSpellInRange = IsSpellInRange
local SecureButton_GetUnit = SecureButton_GetUnit
local SetCursor = SetCursor
local SetPortraitTexture = SetPortraitTexture
local SetPortraitToTexture = SetPortraitToTexture
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local SpellCanTargetUnit = SpellCanTargetUnit
local SpellIsTargeting = SpellIsTargeting
local UnitAffectingCombat = UnitAffectingCombat
local UnitAlternatePowerInfo = UnitAlternatePowerInfo
local UnitAura = UnitAura
local UnitCanAssist = UnitCanAssist
local UnitCanAttack = UnitCanAttack
local UnitClass = UnitClass
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitExists = UnitExists
local UnitFactionGroup = UnitFactionGroup
local UnitGetIncomingHeals = UnitGetIncomingHeals
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitInRange = UnitInRange
local UnitInVehicle = UnitInVehicle
local UnitIsAFK = UnitIsAFK
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsTapDenied = UnitIsTapDenied
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitLevel = UnitLevel
local UnitName = UnitName
local UnitPlayerControlled = UnitPlayerControlled
local UnitPopup_ShowMenu = UnitPopup_ShowMenu
local UnitPopupMenus = UnitPopupMenus
local UnitPopupShown = UnitPopupShown
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction
local UnregisterUnitWatch = UnregisterUnitWatch
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

local BuffFrame = BuffFrame
local GameTooltip = GameTooltip
local Minimap = Minimap
local UIParent = UIParent

local ArcaneExclusions = XPerl_ArcaneExclusions

local largeNumTag = XPERL_LOC_LARGENUMTAG
local hugeNumTag = XPERL_LOC_HUGENUMTAG
local veryhugeNumTag = XPERL_LOC_VERYHUGENUMTAG

--[==[@debug@
local function d(...)
	ChatFrame1:AddMessage(format(...))
end
--@end-debug@]==]

-- Compact Raid frame manager
local c = _G.CompactRaidFrameManager
if c then
	c:SetFrameStrata("Medium")
end

------------------------------------------------------------------------------
-- Re-usable tables
local FreeTables = setmetatable({}, {__mode = "k"})
local requested, freed = 0, 0

function XPerl_GetReusableTable(...)
	requested = requested + 1
	for t in pairs(FreeTables) do
		FreeTables[t] = nil
		for i = 1, select("#", ...) do
			t[i] = select(i, ...)
		end
		return t
	end
	return {...}
end

function XPerl_FreeTable(t, deep)
	if (t) then
		if (type(t) ~= "table") then
			error("Usage: XPerl_FreeTable([table])")
		end
		if (FreeTables[t]) then
			error("XPerl_FreeTable - Table already freed")
		end

		freed = freed + 1

		FreeTables[t] = true
		for k, v in pairs(t) do
			if (deep and type(v) == "table") then
				XPerl_FreeTable(v, true)
			end
			t[k] = nil
		end
		--t[''] = 0
		--t[''] = nil
	end
end

function XPerl_TableStats()
	print(requested, freed)
	return requested, freed
end

--local new, del = XPerl_GetReusableTable, XPerl_FreeTable

local function rotate(angle)
	local A = cos(angle)
	local B = sin(angle)
	local ULx, ULy = -0.5 * A - -0.5 * B, -0.5 * B + -0.5 * A
	local LLx, LLy = -0.5 * A - 0.5 * B, -0.5 * B + 0.5 * A
	local URx, URy = 0.5 * A - -0.5 * B, 0.5 * B + -0.5 * A
	local LRx, LRy = 0.5 * A - 0.5 * B, 0.5 * B + 0.5 * A
	return ULx + 0.5, ULy + 0.5, LLx + 0.5, LLy + 0.5, URx + 0.5, URy + 0.5, LRx + 0.5, LRy + 0.5
end

-- meta table for string based colours. Allows for other mods changing class colours and things all working
XPerlColourTable = setmetatable({ }, {
	__index = function(self, class)
		if not class then
			return
		end
		local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[strupper(class or "")]
		if (c) then
			c = format("|c00%02X%02X%02X", 255 * c.r, 255 * c.g, 255 * c.b)
		else
			c = "|c00808080"
		end
		self[class] = c
		return c
	end
})

--XPerl_Percent = setmetatable({},
--	{__mode = "kv",
--	__index = function(self, i)
--		if (type(i) == "number" and i >= 0) then
--			self[i] = format(percD, i)
--			return self[i]
--		end
--		return ""
--	end
--	})
--local xpPercent = XPerl_Percent

-- XPerl_ShowMessage
-- debug function
--[[function XPerl_ShowMessage(cMsg)
	local str = "|c00FF7F00"..event.."|r"
	local theEnd
	if (arg1 and (arg1 == "player" or arg1 == "pet" or arg1 == "target" or arg1 =="focus" or strfind(arg1, "^raid") or strfind(arg1, "^party"))) then
		local class = select(2, UnitClass(arg1))
		if (class) then
			str = str..", |c00808080"..tostring(arg1).."("..XPerlColourTable[class]..UnitName(arg1).."|c00808080)|r"
			theEnd = 2
		end
	else
		theEnd = 1
	end

	local tail, doit = ""
	for i = 9,theEnd,-1 do
		local v = _G["arg"..i]
		if (v or doit) then
			if (tail ~= "") then
				tail = tostring(v)..", "..tail
			else
				tail = tostring(v)
			end
			doit = true
		end
	end
	if (tail ~= "") then
		str = str..", "..tail
	end

	if (cMsg) then
		str = cMsg.." - "..str
	end

	local cf = ChatFrame2
	if (not cf:IsVisible()) then
		cf = DEFAULT_CHAT_FRAME
	end
	if (self and self.GetName and self:GetName()) then
		cf:AddMessage("|c00007F7F"..self:GetName().."|r - "..str)
	else
		cf:AddMessage(str)
	end
end]]

XPerl_AnchorList = {"TOP", "LEFT", "BOTTOM", "RIGHT"}

-- FindABandage()
--[[local function FindABandage()
	local bandages = {
		[173192] = true, -- Shrouded Cloth Bandage
		[173191] = true, -- Heavy Shrouded Cloth Bandage
		[158382] = true, -- Deep Sea Bandage
		[158381] = true, -- Tidespray Linen Bandage
		[142332] = true, -- Feathered Luffa
		[136653] = true, -- Silvery Salve
		[133942] = true, -- Silkweave Splint
		[133940] = true, -- Silkweave Bandage
		[115497] = true, -- Ashran Bandage
		[111603] = true, -- Antiseptic Bandage
		[72986] = true, -- Heavy Windwool Bandage
		[72985] = true, -- Windwool Bandage
		[53051] = true, -- Dense Embersilk Bandage
		[53050] = true, -- Heavy Embersilk Bandage
		[53049] = true, -- Embersilk Bandage
		[34722] = true, -- Heavy Frostweave Bandage
		[34721] = true,	-- Frostweave Bandage
		[21991] = true, -- Heavy Netherweave Bandage
		[21990] = true, -- Netherweave Bandage
		[14530] = true, -- Heavy Runecloth Bandage
		[14529] = true, -- Runecloth Bandage
		[8545] = true, -- Heavy Mageweave Bandage
		[8544] = true, -- Mageweave Bandage
		[6451] = true, -- Heavy Silk Bandage
		[6450] = true, -- Silk Bandage
		[3531] = true, -- Heavy Wool Bandage
		[3530] = true, -- Wool Bandage
		[2581] = true, -- Heavy Linen Bandage
		[1251] = true, -- Linen Bandage
	}

	for k, v in pairs(bandages) do
		if (C_Item and C_Item.GetItemCount) and C_Item.GetItemCount(k) or GetItemCount(k) > 0 then
			return GetItemInfo(k)
		end
	end
end]]

local playerClass

-- We have a dummy do-nothing function here for classes that don't have range checking
-- The do-something function is setup after variables_loaded and we work out spell to use just once
function XPerl_UpdateSpellRange()
	return
end

--local SpiritRealm = (C_Spell and C_Spell.GetSpellInfo(235621)) and C_Spell.GetSpellInfo(235621).name or GetSpellInfo(235621)

-- DoRangeCheck
local function DoRangeCheck(unit, opt)
	local range
	if opt.PlusHealth then
		local hp, hpMax = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit)), UnitHealthMax(unit)
		-- Begin 4.3 divide by 0 work around.
		local percent
		if UnitIsDeadOrGhost(unit) or (hp == 0 and hpMax == 0) then -- Probably dead target
			percent = 0 -- So just automatically set percent to 0 and avoid division of 0/0 all together in this situation.
		elseif hp > 0 and hpMax == 0 then -- We have current HP but max hp failed.
			hpMax = hp -- Make max hp at least equal to current health
			percent = 1 -- 100% if they are alive with > 0 cur hp, since curhp = maxhp in this hack.
		else
			percent = hp / hpMax -- Everything is dandy, so just do it right way.
		end
		-- End divide by 0 work around
		if (percent > opt.HealthLowPoint) then
			range = 0
		end
	end

	if opt.PlusDebuff and ((opt.PlusHealth and range == 0) or not opt.PlusHealth) then
		local name
		if not IsVanillaClassic and C_UnitAuras then
			local auraData = C_UnitAuras.GetAuraDataByIndex(unit, 1, "HARMFUL|RAID")
			if auraData then
				name = auraData.name
			end
		else
			name = UnitAura(unit, 1, "HARMFUL|RAID")
		end
		if not name then
			range = 0
		else
			if ArcaneExclusions[name] then
				-- It's one of the filtered debuffs, so we have to iterate thru all debuffs to see if anything is curable
				for i = 1, 40 do
					local name
					if not IsVanillaClassic and C_UnitAuras then
						local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL|RAID")
						if auraData then
							name = auraData.name
						end
					else
						name = UnitAura(unit, i, "HARMFUL|RAID")
					end
					if not name then
						range = 0
						break
					elseif not ArcaneExclusions[name] then
						range = nil
						break
					end
				end
			else
				range = nil -- Override's the health check, because there's a debuff on unit
			end
		end
	end

	if not range then
		--local playerRealm = UnitAura("player", SpiritRealm, "HARMFUL")
		--local unitRealm = UnitAura(unit, SpiritRealm, "HARMFUL")

		--[[if playerRealm ~= unitRealm then
			range = nil
		else--]]
		if opt.interact then
			if opt.interact == 6 then -- 45y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 5 then -- 40y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 3 then -- 10y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 2 then -- 20y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			elseif opt.interact == 1 then -- 30y
				local checkedRange
				range, checkedRange = UnitInRange(unit)
				if not checkedRange then
					range = 1
				end
			end
			-- CheckInteractDistance
			-- 1 = Inspect = 28 yards (BCC = 28 yards) (Vanilla = 10 yards)
			-- 2 = Trade = 8 yards (BCC = 8 yards) (Vanilla = 11 yards)
			-- 3 = Duel = 7 yards (BCC = 7 yards) (Vanilla = 10 yards)
			-- 4 = Follow = 28 yards (BCC = 28 yards) (Vanilla = 28 yards)
			-- 5 = Pet-battle Duel = 7 yards (BCC = 7 yards) (Vanilla = 10 yards)
		elseif opt.spell or opt.spell2 then
			if UnitCanAssist("player", unit) and opt.spell then
				range = (C_Spell and C_Spell.IsSpellInRange) and C_Spell.IsSpellInRange(opt.spell, unit) or (IsSpellInRange and IsSpellInRange(opt.spell, unit))
			elseif UnitCanAttack("player", unit) and opt.spell2 then
				range = (C_Spell and C_Spell.IsSpellInRange) and C_Spell.IsSpellInRange(opt.spell2, unit) or (IsSpellInRange and IsSpellInRange(opt.spell2, unit))
			else
				-- Fallback (28y) (BCC = 28y) (Vanilla = 28 yards)
				range = not InCombatLockdown() and CheckInteractDistance(unit, 4) or 1
			end
		--[[elseif not IsRetail and not IsVanillaClassic and (opt.item or opt.item2) then
			if UnitCanAssist("player", unit) and opt.item then
				range = not InCombatLockdown() and IsItemInRange(opt.item, unit)
			elseif UnitCanAttack("player", unit) and opt.item2 then
				range = not InCombatLockdown() and IsItemInRange(opt.item2, unit)
			else
				-- Fallback (28y) (BCC = 28y) (Vanilla = 28 yards)
				range = not InCombatLockdown() and CheckInteractDistance(unit, 4)
			end]]
		else
			range = 1
		end
	end

	if range ~= 1 and range ~= true then
		return opt.FadeAmount
	end
end

-- XPerl_UpdateSpellRange(self)
function XPerl_UpdateSpellRange2(self, overrideUnit, isRaidFrame)
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
		local rf = conf.rangeFinder
		local mainA, nameA, statsA -- Receives main, name and stats alpha levels

		if (rf.enabled and (isRaidFrame or not conf.rangeFinder.raidOnly)) then
			if (not UnitIsVisible(unit))--[[ or UnitInVehicle(unit)]] then
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
			--[[elseif (XPerl_Highlight:HasEffect(UnitName(unit), "AGGRO")) then
				mainA = conf.transparency.frame]]
			else
				if (rf.Main.enabled) then
					mainA = DoRangeCheck(unit, rf.Main)
					if (mainA) then
						mainA = mainA * conf.transparency.frame
					end
				end

				if (rf.NameFrame.enabled) then
					-- check for same item/spell. Saves doing the check multiple times
					if (rf.Main.enabled and (rf.Main.spell == rf.NameFrame.spell) and (rf.Main.item == rf.NameFrame.item) and (rf.Main.spell2 == rf.NameFrame.spell2) and (rf.Main.item2 == rf.NameFrame.item2) and (rf.Main.PlusHealth == rf.NameFrame.PlusHealth)) then
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
					-- check for same item/spell. Saves doing the check multiple times
					if (rf.Main.enabled and (rf.Main.spell == rf.StatsFrame.spell) and (rf.Main.item == rf.StatsFrame.item) and (rf.Main.spell2 == rf.StatsFrame.spell2) and (rf.Main.item2 == rf.StatsFrame.item2) and (rf.Main.PlusHealth == rf.StatsFrame.PlusHealth)) then
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
				nameA, statsA = mainA
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
			if (nameA or forcedMainA) then
				self.statsFrame:SetAlpha(statsA or mainA)
			else
				self.statsFrame:SetAlpha(1)
			end
		end
	end
end

-- XPerl_StartupSpellRange()
function XPerl_StartupSpellRange()
	local _, playerClass = UnitClass("player")

	if (not XPerl_DefaultRangeSpells.ANY) then
		XPerl_DefaultRangeSpells.ANY = {}
	end

	--[[local bandage = FindABandage()
	if bandage then
		XPerl_DefaultRangeSpells.ANY.item = bandage
	end]]

	local rf = conf.rangeFinder

	local function Setup1(self)
		if type(self.spell) ~= "string" then
			self.spell = XPerl_DefaultRangeSpells[playerClass] and XPerl_DefaultRangeSpells[playerClass].spell
			if type(self.item) ~= "string" then
				self.item = (XPerl_DefaultRangeSpells.ANY and XPerl_DefaultRangeSpells.ANY.item) or ""
			end
		end
		if type(self.spell2) ~= "string" then
			self.spell2 = XPerl_DefaultRangeSpells[playerClass] and XPerl_DefaultRangeSpells[playerClass].spell2
			if type(self.item2) ~= "string" then
				self.item2 = (XPerl_DefaultRangeSpells.ANY and XPerl_DefaultRangeSpells.ANY.item2) or ""
			end
		end

		if (not self.FadeAmount) then
			self.FadeAmount = 0.3
		end
		if (not self.HealthLowPoint) then
			self.HealthLowPoint = 0.7
		end
	end

	Setup1(rf.Main)
	Setup1(rf.NameFrame)
	Setup1(rf.StatsFrame)

	--if (rangeCheckSpell) then
		-- Put the real work function in place
	XPerl_UpdateSpellRange = XPerl_UpdateSpellRange2
	--else
	--	XPerl_UpdateSpellRange = function() end
	--end
end

XPerl_RegisterOptionChanger(XPerl_StartupSpellRange)

-- XPerl_StatsFrame_SetGrey
local function XPerl_StatsFrame_SetGrey(self, r, g, b)
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

-- XPerl_SetChildMembers - Recursive
-- This iterates a frame's child frames and regions and assigns member variables
-- based on the sub-set part of the child's name compared to the parent frame name
function XPerl_SetChildMembers(self)
	local n = self:GetName()
	if (n) then
		local match = "^"..n.."(.+)$"

		local function AddList(list)
			for k, v in pairs(list) do
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

		local c = {self:GetChildren()}
		AddList(c, true)

		for k, v in pairs(c) do
			if (v:GetName()) then
				XPerl_SetChildMembers(v)
			end
			v:SetScript("OnLoad", nil)
		end

		self:SetScript("OnLoad", nil)
	end
end

do
	local shortlist
	local list
	local media

	-- XPerl_RegisterSMBarTextures
	function XPerl_RegisterSMBarTextures()
		if (LibStub) then
			media = LibStub("LibSharedMedia-3.0", true)
		end

		shortlist = {
			{"Perl v2", "Interface\\Addons\\ZPerl\\Images\\XPerl_StatusBar"},
		}
		for i = 1, 9 do
			local name = i == 2 and "BantoBar" or "X-Perl "..i
			tinsert(shortlist, {name, "Interface\\Addons\\ZPerl\\Images\\XPerl_StatusBar"..(i + 1)})
		end

		if (media) then
			for k, v in pairs(shortlist) do
				media:Register("statusbar", v[1], v[2])
			end

			media:Register("border", "X-Perl Thin", "Interface\\Addons\\ZPerl\\Images\\XPerl_ThinEdge")
		end
	end

	-- XPerl_AllBarTextures
	function XPerl_AllBarTextures(short)
		if (not list) then
			if (short) then
				return shortlist
			end

			if (media) then
				list = { }
				local smlBars = media:List("statusbar")
				for k, v in pairs(smlBars) do
					tinsert(list, {v, media:Fetch("statusbar", v)})
				end
			else
				list = shortlist
			end
		end

		return list
	end
end

-- XPerl_GetBarTexture
function XPerl_GetBarTexture()
	return (conf and conf.bar and conf.bar.texture and conf.bar.texture[2]) or "Interface\\TargetingFrame\\UI-StatusBar"
end

-- XPerl_StatsFrame_Setup
function XPerl_StatsFrame_Setup(self)
	self:OnBackdropLoaded()
	XPerl_SetChildMembers(self)
	self.SetGrey = XPerl_StatsFrame_SetGrey
end

-- XPerl_GetClassColour
local defaultColour = {r = 0.5, g = 0.5, b = 1}
function XPerl_GetClassColour(class)
	return (class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]) or defaultColour
end

local hookedFrames = {}
local hiddenParent = CreateFrame("Frame")
hiddenParent:Hide()

---------------------------------
--Loading Function             --
---------------------------------

-- XPerl_BlizzFrameDisable
function XPerl_BlizzFrameDisable(self)
	if not self then
		return
	end

	UnregisterUnitWatch(self)

	self:UnregisterAllEvents()

	if self == PlayerFrame then
		--[[local events = {
			"PLAYER_ENTERING_WORLD",
			"UNIT_ENTERING_VEHICLE",
			"UNIT_ENTERED_VEHICLE",
			"UNIT_EXITING_VEHICLE",
			"UNIT_EXITED_VEHICLE",
		}

		for i, event in pairs(events) do
			if pcall(self.RegisterEvent, self, event) then
				self:RegisterEvent(event)
			end
		end--]]

		if AlternatePowerBar then
			AlternatePowerBar:UnregisterAllEvents()
		end
	end

	if IsRetail and self == PartyFrame then
		for frame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
			XPerl_BlizzFrameDisable(frame)
		end
	end

	self:SetMovable(true)
	self:SetUserPlaced(true)
	self:SetDontSavePosition(true)
	self:SetMovable(false)

	if not InCombatLockdown() then
		self:Hide()
		self:SetParent(hiddenParent)
	end

	if not hookedFrames[self] then
		local ignoreParent
		hooksecurefunc(self, "SetParent", function()
			if ignoreParent then
				return
			end
			ignoreParent = true
			self:SetParent(hiddenParent)
			ignoreParent = nil
		end)

		hookedFrames[self] = true
	end

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

	local classPowerBar = self.classPowerBar
	if classPowerBar then
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

-- smoothColor
local function smoothColor(percentage)
	local r, g, b
	if (percentage < 0.5) then
		r = 1
		g = min(1, max(0, 2 * percentage))
		b = 0
	else
		g = 1
		r = min(1, max(0, 2 * (1 - percentage)))
		b = 0
	end

	return r, g, b
end

---------------------------------
--Smooth Health Bar Color      --
---------------------------------
function XPerl_SetSmoothBarColor(self, percentage)
	if (self) then
		local r, g, b
		if (conf.colour.classic) then
			r, g, b = smoothColor(percentage)
		else
			local c = conf.colour.bar
			r = min(1, max(0, c.healthEmpty.r + ((c.healthFull.r - c.healthEmpty.r) * percentage)))
			g = min(1, max(0, c.healthEmpty.g + ((c.healthFull.g - c.healthEmpty.g) * percentage)))
			b = min(1, max(0, c.healthEmpty.b + ((c.healthFull.b - c.healthEmpty.b) * percentage)))
		end

		self:SetStatusBarColor(r, g, b)

		if (self.bg) then
			self.bg:SetVertexColor(r, g, b, 0.25)
		end
	end
end

local barColours
function XPerl_ResetBarColourCache()
	barColours = setmetatable({ }, {
		__index = function(self, k)
			local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[k]
			if (c) then
				if (not conf.colour.classbarBright) then
					conf.colour.classbarBright = 1
				end
				self[k] = {
					r = max(0, min(1, c.r * conf.colour.classbarBright)),
					g = max(0, min(1, c.g * conf.colour.classbarBright)),
					b = max(0, min(1, c.b * conf.colour.classbarBright))
				}
				return self[k]
			end
		end
	})
end
XPerl_ResetBarColourCache()

-- XPerl_ColourHealthBar
function XPerl_ColourHealthBar(self, healthPct, partyid)
	if (not partyid) then
		partyid = self.partyid
	end
	local bar = self.statsFrame.healthBar
	if (--[[string.find(partyid, "raid") and ]]conf.colour.classbar and UnitIsPlayer(partyid)) then
		local _, class = UnitClass(partyid)
		if (class) then
			local c = barColours[class]
			if (c) then
				bar:SetStatusBarColor(c.r, c.g, c.b)
				if (bar.bg) then
					bar.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
				end
				return
			end
		end
	end

	XPerl_SetSmoothBarColor(bar, healthPct)
end
--local XPerl_ColourHealthBar = XPerl_ColourHealthBar

-- XPerl_SetValuedText
function XPerl_SetValuedText(self, unitHealth, unitHealthMax, suffix)
	local locale = GetLocale()
	if locale == "zhCN" or locale == "zhTW" then
		if unitHealthMax >= 1000000000000 then
			if abs(unitHealth) >= 1000000000000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000000000, veryhugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000000 then
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 10000, hugeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 1000000000000, veryhugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 1000000000 then
			if abs(unitHealth) >= 1000000000 then
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000000 then
				self:SetFormattedText("%.2f%s/%.1f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.1f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 100000000 then
			if abs(unitHealth) >= 100000000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 100000000, hugeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 100000000, hugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 1000000 then
			if abs(unitHealth) >= 1000000 then
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 10000, largeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 10000, largeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.1f%s%s", unitHealth, unitHealthMax / 10000, largeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 100000 then
			if abs(unitHealth) >= 100000 then
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 10000, largeNumTag, unitHealthMax / 10000, largeNumTag, suffix or "")
			else
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 10000, largeNumTag, suffix or "")
			end
		else
			self:SetFormattedText("%d/%d%s", unitHealth, unitHealthMax, suffix or "")
		end
	else
		if unitHealthMax >= 1000000000 then
			if abs(unitHealth) >= 1000000000 then
				-- 1.23G/1.23G
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000000, veryhugeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 10000000 then
				-- 12.3M/1.23G
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				-- 1.23M/1.23G
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				-- 123.4K/1.23G
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
			else
				-- 12345/1.23G
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 1000000000, veryhugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 10000000 then
			if abs(unitHealth) >= 10000000 then
				-- 12.3M/12.3M
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 1000000 then
				-- 1.23M/12.3M
				self:SetFormattedText("%.2f%s/%.1f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				-- 123.4K/12.3M
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
			else
				-- 12345/12.3M
				self:SetFormattedText("%d/%.1f%s%s", unitHealth, unitHealthMax / 1000000, hugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 1000000 then
			if abs(unitHealth) >= 1000000 then
				-- 1.23M/1.23M
				self:SetFormattedText("%.2f%s/%.2f%s%s", unitHealth / 1000000, hugeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
			elseif abs(unitHealth) >= 100000 then
				-- 123.4K/1.23M
				self:SetFormattedText("%.1f%s/%.2f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000000, hugeNumTag, suffix or "")
			else
				-- 12345/1.23M
				self:SetFormattedText("%d/%.2f%s%s", unitHealth, unitHealthMax / 1000000, hugeNumTag, suffix or "")
			end
		elseif unitHealthMax >= 100000 then
			if abs(unitHealth) >= 100000 then
				-- 123.4K/123.4K
				self:SetFormattedText("%.1f%s/%.1f%s%s", unitHealth / 1000, largeNumTag, unitHealthMax / 1000, largeNumTag, suffix or "")
			else
				-- 12345/123.4K
				self:SetFormattedText("%d/%.1f%s%s", unitHealth, unitHealthMax / 1000, largeNumTag, suffix or "")
			end
		else
			-- 12345/12345
			self:SetFormattedText("%d/%d%s", unitHealth, unitHealthMax, suffix or "")
		end
	end
end
local SetValuedText = XPerl_SetValuedText

-- XPerl_SetHealthBar
function XPerl_SetHealthBar(self, hp, Max)
	local bar = self.statsFrame.healthBar
	bar:SetMinMaxValues(0, Max)
	local percent
	if hp >= 1 and Max == 0 then -- For some dumb reason max HP is 0, normal HP is not, so lets use normal HP as max
		Max = hp
		percent = 1
	elseif hp == 0 and Max == 0 then -- Both are 0, so it's probably dead since usually current HP returns correctly when Max HP fails.
		percent = 0
	else
		percent = hp / Max
	end
	if percent > 1 then percent = 1 end -- percent only goes to 100
	if (conf.bar.inverse) then
		bar:SetValue(Max - hp)
		bar.tex:SetTexCoord(0, max(0,(1 - percent)), 0, 1)
	else
		bar:SetValue(hp)
		bar.tex:SetTexCoord(0, max(0, percent), 0, 1)
	end

	XPerl_ColourHealthBar(self, percent)
	if (bar.percent) then
		if (self.conf.healerMode and self.conf.healerMode.enable and self.conf.healerMode.type == 2) then
			--bar.percent:SetText(hp - Max)
			local health = hp - Max
			local locale = GetLocale()
			if locale == "zhCN" or locale == "zhTW" then
				if (abs(health) >= 1000000000000) then
					bar.percent:SetFormattedText("%.0f%s", health / 1000000000000, veryhugeNumTag)
				elseif (abs(health) >= 100000000) then
					bar.percent:SetFormattedText("%.0f%s", health / 100000000, hugeNumTag)
				elseif (abs(health) >= 1000000) then
					bar.percent:SetFormattedText("%.0f%s", health / 10000, largeNumTag)
				elseif (abs(health) >= 1000) then
					bar.percent:SetFormattedText("%.1f%s", health / 10000, largeNumTag)
				else
					bar.percent:SetFormattedText("%d", health)
				end
			else
				if (abs(health) >= 10000000000) then
					bar.percent:SetFormattedText("%.0f%s", health / 1000000000, veryhugeNumTag)
				elseif (abs(health) >= 1000000000) then
					bar.percent:SetFormattedText("%.1f%s", health / 1000000000, veryhugeNumTag)
				elseif (abs(health) >= 10000000) then
					bar.percent:SetFormattedText("%.0f%s", health / 1000000, hugeNumTag)
				elseif (abs(health) >= 1000000) then
					bar.percent:SetFormattedText("%.1f%s", health / 1000000, hugeNumTag)
				elseif (abs(health) >= 10000) then
					bar.percent:SetFormattedText("%.0f%s", health / 1000, largeNumTag)
				elseif (abs(health) >= 1000) then
					bar.percent:SetFormattedText("%.1f%s", health / 1000, largeNumTag)
				else
					bar.percent:SetFormattedText("%d", health)
				end
			end
		else
			local show = percent * 100
			if (show < 10) then
				bar.percent:SetFormattedText(perc1F or "%.1f%%", percent == 1 and 100 or show + 0.05)
			else
				bar.percent:SetFormattedText(percD or "%d%%", percent == 1 and 100 or show + 0.5)
			end
		end
	end

	if (bar.text) then
		local hbt = bar.text
		if (self.conf.healerMode.enable and self.conf.healerMode.type ~= 2) then
			local health = hp - Max
			if (self.conf.healerMode.type == 1) then
				SetValuedText(hbt, health, Max)
			else
				local locale = GetLocale()
				if locale == "zhCN" or locale == "zhTW" then
					if (abs(health) >= 1000000000000) then
						hbt:SetFormattedText("%.2f%s", health / 1000000000000, veryhugeNumTag)
					elseif (abs(health) >= 1000000000) then
						hbt:SetFormattedText("%.0f%s", health / 100000000, hugeNumTag)
					elseif (abs(health) >= 100000000) then
						hbt:SetFormattedText("%.1f%s", health / 100000000, hugeNumTag)
					elseif (abs(health) >= 1000000) then
						hbt:SetFormattedText("%.0f%s", health / 10000, largeNumTag)
					elseif (abs(health) >= 100000) then
						hbt:SetFormattedText("%.1f%s", health / 10000, largeNumTag)
					else
						hbt:SetFormattedText("%d", health)
					end
				else
					if (abs(health) >= 1000000000) then
						hbt:SetFormattedText("%.2f%s", health / 1000000000, veryhugeNumTag)
					elseif (abs(health) >= 10000000) then
						hbt:SetFormattedText("%.1f%s", health / 1000000, hugeNumTag)
					elseif (abs(health) >= 1000000) then
						hbt:SetFormattedText("%.2f%s", health / 1000000, hugeNumTag)
					elseif (abs(health) >= 100000) then
						hbt:SetFormattedText("%.1f%s", health / 1000, largeNumTag)
					else
						hbt:SetFormattedText("%d", health)
					end
				end
			end
		else
			SetValuedText(hbt, hp, Max)
		end
	end
	--XPerl_SetExpectedHealth(self)
end

---------------------------------
--Class Icon Location Functions--
---------------------------------
--local ClassPos = {
--	WARRIOR	= {0,    0.25,    0,	0.25},
--	MAGE	= {0.25, 0.5,     0,	0.25},
--	ROGUE	= {0.5,  0.75,    0,	0.25},
--	DRUID	= {0.75, 1,       0,	0.25},
--	HUNTER	= {0,    0.25,    0.25,	0.5},
--	SHAMAN	= {0.25, 0.5,     0.25,	0.5},
--	PRIEST	= {0.5,  0.75,    0.25,	0.5},
--	WARLOCK	= {0.75, 1,       0.25,	0.5},
--	PALADIN	= {0,    0.25,    0.5,	0.75},
--	none	= {0.25, 0.5, 0.5, 0.75},
--}
--function XPerl_ClassPos(class)
--	return unpack(ClassPos[class] or ClassPos.none)
--end

local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS
function XPerl_ClassPos(unitClass)
	local b = CLASS_ICON_TCOORDS[unitClass]		-- Now using the Blizzard supplied from FrameXML/WorldStateFrame.lua
	if (b) then
		return unpack(b)
	end
	return 0.25, 0.5, 0.5, 0.75
end

-- XPerl_Toggle
function XPerl_Toggle()
	if (XPerlLocked == 1) then
		XPerl_UnlockFrames()
	else
		XPerl_LockFrames()
	end
end

-- XPerl_UnlockFrames
function XPerl_UnlockFrames()
	XPerl_LoadOptions()

	XPerlLocked = 0

	if (XPerl_Party_Virtual) then
		XPerl_Party_Virtual(true)
	end

	if (XPerl_Player_Pet_Virtual) then
		XPerl_Player_Pet_Virtual(true)
	end

	if (XPerl_AggroAnchor) then
		XPerl_AggroAnchor:Enable()
	end

	--[[if (XPerl_Player) then
		if (XPerl_Player.runes and not InCombatLockdown()) then
			XPerl_Player.runes:EnableMouse(true)
		end
	end]]

	if (XPerl_Options) then
		XPerl_Options:Show()
		XPerl_Options:SetAlpha(0)
		XPerl_Options.Fading = "in"
	end

	if (XPerl_RaidTitles) then
		XPerl_RaidTitles()
		if (XPerl_RaidPets_Titles) then
			XPerl_RaidPets_Titles()
		end
	end
end

-- XPerl_LockFrames
function XPerl_LockFrames()
	XPerlLocked = 1
	if (XPerl_Options) then
		XPerl_Options.Fading = "out"
	end

	if (XPerl_Party_Virtual) then
		XPerl_Party_Virtual()
	end

	if (XPerl_Player_Pet_Virtual) then
		XPerl_Player_Pet_Virtual()
	end

	if (XPerl_AggroAnchor) then
		XPerl_AggroAnchor:Disable()
	end

	--[[if (XPerl_Player) then
		if (XPerl_Player.runes and not InCombatLockdown()) then
			XPerl_Player.runes:EnableMouse(false)
		end
	end]]

	if (XPerl_RaidTitles) then
		XPerl_RaidTitles()
		if (XPerl_RaidPets_Titles) then
			XPerl_RaidPets_Titles()
		end
	end

	XPerl_OptionActions()
end

-- Minimap Icon
function XPerl_MinimapButton_OnClick(self, button)
	GameTooltip:Hide()
	if (button == "LeftButton") then
		XPerl_Toggle()
	elseif (button == "RightButton") then
		XPerl_MinimapMenu(self)
	end
end

-- XPerl_MinimapMenu_OnLoad
function XPerl_MinimapMenu_OnLoad(self)
	local dropdown = MSA_DropDownMenu_Create(self:GetName().."_DropDown", self)
	dropdown.displayMode = "MENU"
	dropdown:SetAllPoints(self)
	MSA_DropDownMenu_Initialize(dropdown, XPerl_MinimapMenu_Initialize)
end

-- XPerl_MinimapMenu_Initialize
function XPerl_MinimapMenu_Initialize(self, level)
	local info

	if (level == 2) then
		return
	end

	info = MSA_DropDownMenu_CreateInfo()
	info.isTitle = 1
	info.text = XPerl_ProductName
	MSA_DropDownMenu_AddButton(info)

	info = MSA_DropDownMenu_CreateInfo()
	info.notCheckable = 1
	info.func = XPerl_Toggle
	info.text = XPERL_MINIMENU_OPTIONS
	MSA_DropDownMenu_AddButton(info)

	if (C_AddOns.IsAddOnLoaded("ZPerl_RaidHelper")) then
		if (XPerl_Assists_Frame and not XPerl_Assists_Frame:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = XPERL_MINIMENU_ASSIST
			info.func = function()
					ZPerlConfigHelper.AssistsFrame = 1
					ZPerlConfigHelper.TargettingFrame = 1
					XPerl_SetFrameSides()
				end
			MSA_DropDownMenu_AddButton(info)
		end
	end

	if (C_AddOns.IsAddOnLoaded("ZPerl_RaidMonitor")) then
		if (XPerl_RaidMonitor_Frame and not XPerl_RaidMonitor_Frame:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = XPERL_MINIMENU_CASTMON
			info.func = function()
				ZPerlRaidMonConfig.enabled = 1
				XPerl_RaidMonitor_Frame:SetFrameSizes()
			end
			MSA_DropDownMenu_AddButton(info)
		end
	end

	if (C_AddOns.IsAddOnLoaded("ZPerl_RaidAdmin")) then
		if (XPerl_AdminFrame and not XPerl_AdminFrame:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = XPERL_MINIMENU_RAIDAD
			info.func = function() XPerl_AdminFrame:Show() end
			MSA_DropDownMenu_AddButton(info)
		end

		if (XPerl_Check and not XPerl_Check:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = XPERL_MINIMENU_ITEMCHK
			info.func = function() XPerl_Check:Show() end
			MSA_DropDownMenu_AddButton(info)
		end

		if (XPerl_RosterText and not XPerl_RosterText:IsShown()) then
			info = MSA_DropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.text = XPERL_MINIMENU_ROSTERTEXT
			info.func = function() XPerl_RosterText:Show() end
			MSA_DropDownMenu_AddButton(info)
		end
	end
end

-- XPerl_MinimapMenu
function XPerl_MinimapMenu(self)
	if (not ZPerl_Minimap) then
		CreateFrame("Frame", "ZPerl_Minimap", nil, BackdropTemplateMixin and "BackdropTemplate")
		XPerl_MinimapMenu_OnLoad(ZPerl_Minimap)
	end

	MSA_ToggleDropDownMenu(1, nil, ZPerl_Minimap_DropDown, "cursor", 0, 0)
end

local xpModList = {"ZPerl", "ZPerl_Player", "ZPerl_PlayerBuffs", "ZPerl_PlayerPet", "ZPerl_Target", "ZPerl_TargetTarget", "ZPerl_Party", "ZPerl_PartyPet", "ZPerl_ArcaneBar", "ZPerl_RaidFrames", "ZPerl_RaidHelper", "ZPerl_RaidAdmin", "ZPerl_RaidMonitor", "ZPerl_RaidPets"}
local xpStartupMemory = {}

-- ZPerl_MinimapButton_Init
function ZPerl_MinimapButton_Init(self)
	--self.time = 0
	collectgarbage()
	UpdateAddOnMemoryUsage()
	local totalKB = 0
	for k, v in pairs(xpModList) do
		local usedKB = GetAddOnMemoryUsage(v)
		if ((usedKB or 0) > 0) then
			xpStartupMemory[v] = usedKB
		end
	end

	XPerl_MinimapButton_UpdatePosition(self)

	if (conf.minimap.enable) then
		self:Show()
	else
		self:Hide()
	end

	--self.UpdateTooltip = XPerl_MinimapButton_OnEnter

	ZPerl_MinimapButton_Init = nil
end

-- XPerl_MinimapButton_UpdatePosition
function XPerl_MinimapButton_UpdatePosition(self)
	if (not conf.minimap.radius) then
		if IsRetail then
			conf.minimap.radius = 101
		else
			conf.minimap.radius = 78
		end
	end
	self:ClearAllPoints()
	if IsRetail then
		self:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 80 - (conf.minimap.radius * cos(conf.minimap.pos)), (conf.minimap.radius * sin(conf.minimap.pos)) - 82)
	else
		self:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 54 - (conf.minimap.radius * cos(conf.minimap.pos)), (conf.minimap.radius * sin(conf.minimap.pos)) - 55)
	end
end

-- XPerl_MinimapButton_Dragging
function XPerl_MinimapButton_Dragging(self, elapsed)
	local xpos, ypos = GetCursorPosition()
	local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin - xpos / UIParent:GetScale() + 70
	ypos = ypos / UIParent:GetScale() - ymin - 70

	if (IsAltKeyDown()) then
		local radius = (xpos ^ 2 + ypos ^ 2) ^ 0.5
		if (radius < 78) then
			radius = 78
		end
		if (radius > 148) then
			radius = 148
		end
		conf.minimap.radius = radius
		end

	local angle = deg(atan2(ypos, xpos))
	if (angle < 0) then
		angle = angle + 360
	end
	conf.minimap.pos = angle

	XPerl_MinimapButton_UpdatePosition(self)
end

-- DiffColour(diff, val)
local function DiffColour(val)
	local r, g, b, offset
	offset = max(0, min(0.5, 0.5 * min(1, val)))
	if (val < 0) then
		r = 0.5 + offset
		g = 0.5 - offset
		b = r
	else
		r = 0.5 + offset
		g = 0.5 - offset
		b = g
	end
	return format("|c00%02X%02X%02X", 255 * r, 255 * g, 255 * b)
end

-- XPerl_MinimapButton_OnEnter
function XPerl_MinimapButton_OnEnter(self)
	if (self.dragging) then
		return
	end

	GameTooltip:SetOwner(self or UIParent, "ANCHOR_LEFT")
	XPerl_MinimapButton_Details(GameTooltip)
end

-- XPerl_MinimapButton_Details
function XPerl_MinimapButton_Details(tt, ldb)
	tt:SetText(XPerl_Version.." "..XPerl_GetRevision(), 1, 1, 1)
	tt:AddLine(XPERL_MINIMAP_HELP1)
	if (not ldb) then
		tt:AddLine(XPERL_MINIMAP_HELP2)
	end
	if UpdateAddOnMemoryUsage then
		if (IsAltKeyDown()) then
			tt:AddLine(XPERL_MINIMAP_HELP6)
		elseif (not IsShiftKeyDown()) then
			tt:AddLine(XPERL_MINIMAP_HELP5)
		end
	end
	--GetRealNumRaidMembers doesn't exist anymore in 5.0.4
	--[==[if (GetRealNumRaidMembers) then
		if (GetNumGroupMembers() > 0 and GetRealNumRaidMembers() > 0) then
			if (select(2, IsInInstance()) == "pvp") then
				tt:AddLine(format(XPERL_MINIMAP_HELP3, GetRealNumRaidMembers(), GetNumSubgroupMembers(LE_PARTY_CATEGORY_HOME)))

				if (IsRealPartyLeader()) then
					tt:AddLine(XPERL_MINIMAP_HELP4)
				end
			end
		end
	end]==]

	if UpdateAddOnMemoryUsage and IsAltKeyDown() then
		local showDiff = IsShiftKeyDown()

		local allAddonsCPU = 0
		for i = 1, C_AddOns.GetNumAddOns() do
			allAddonsCPU = allAddonsCPU + GetAddOnCPUUsage(i)
		end

		-- Show X-Perl memory usage
		UpdateAddOnMemoryUsage()
		UpdateAddOnCPUUsage()
		local totalKB, totalCPU, diffKB, diff = 0, 0, 0
		local cpuText = ""
		for k, v in pairs(xpModList) do
			local usedKB = GetAddOnMemoryUsage(v)
			local usedCPU = GetAddOnCPUUsage(v)
			if ((usedKB or 0) > 0) then
				totalKB = totalKB + usedKB
				totalCPU = totalCPU + usedCPU

				if (allAddonsCPU > 0) then
					cpuText = format(" |c008080FF%.2f%%|r", 100 * (usedCPU / allAddonsCPU))
				end

				if (showDiff) then
					diff = usedKB - xpStartupMemory[v]
					diffKB = diffKB + diff
					tt:AddDoubleLine(format(" %s", v), format("%.1fkB (%s%.1fkB|r)%s", usedKB, DiffColour(diff / 1000), diff, cpuText), 1, 1, 0.5, 1, 1, 1)
				else
					tt:AddDoubleLine(format(" %s", v), format("%.1fkB%s", usedKB, cpuText), 1, 1, 0.5, 1, 1, 1)
				end
			end
		end

		if (showDiff) then
			local color = DiffColour(diffKB / 3000)

			tt:AddDoubleLine("Total", format("%.1fkB (%s%.1fkB|r)", totalKB, color, diffKB), 1, 1, 1, 1, 1, 1)
		else
			tt:AddDoubleLine("Total", format("%.1fkB", totalKB), 1, 1, 1, 1, 1, 1)
		end

		local usedKB = GetAddOnMemoryUsage("ZPerl_Options")
		if ((usedKB or 0) > 0) then
			tt:AddDoubleLine(" ZPerl_Options", format("%.1fkB", usedKB), 0.5, 0.5, 0.5, 0.5, 0.5, 0.5)
		end

		if (totalCPU > 0) then
			tt:AddDoubleLine(" ZPerl CPU Usage Comparison", format("%.2f%%", 100 * (totalCPU / allAddonsCPU)), 0.5, 0.5, 1, 0.5, 0.5, 1)
		end
	end

	tt:Show()
	--tt.updateTooltip = 1
end

function XPerl_GetDisplayedPowerType(unitID)
	local barInfo = not IsClassic and GetUnitPowerBarInfo(unitID)
	if barInfo and barInfo.showOnRaid and UnitHasVehicleUI(unitID) and (UnitInParty(unitID) or UnitInRaid(unitID)) then
		return ALTERNATE_POWER_INDEX
	else
		return UnitPowerType(unitID) or 0
	end
end

local ManaColours = {
	[Enum.PowerType.Mana] = "mana",
	[Enum.PowerType.Rage] = "rage",
	[Enum.PowerType.Focus] = "focus",
	[Enum.PowerType.Energy] = "energy",
	[Enum.PowerType.Runes] = "runes",
	[Enum.PowerType.RunicPower] = "runic_power",
	[Enum.PowerType.Insanity] = "insanity",
	[Enum.PowerType.LunarPower] = "lunar",
	[Enum.PowerType.Maelstrom] = "maelstrom",
	[Enum.PowerType.Fury] = "fury",
	[Enum.PowerType.Pain] = "pain",
	[Enum.PowerType.Alternate] = "energy", -- used by some bosses, show it as energy bar
}

-- XPerl_SetManaBarType
function XPerl_SetManaBarType(self)
	local m = self.statsFrame.manaBar
	if (m and not self.statsFrame.greyMana) then
		local unit = self.partyid -- SecureButton_GetUnit(self)
		if not unit then
			self.targetmanatype = 0
			return
		end
		if (unit) then
			local p = XPerl_GetDisplayedPowerType(unit)
			self.targetmanatype = p
			if (p) then
				local c = conf.colour.bar[ManaColours[p]]
				if (c) then
					m:SetStatusBarColor(c.r, c.g, c.b, 1)
					m.bg:SetVertexColor(c.r, c.g, c.b, 0.25)
				end
			end
		end
	end
end

-- XPerl_TooltipModiferPressed
function XPerl_TooltipModiferPressed(buffs)
	local mod, ic
	if (buffs) then
		if (not conf.tooltip.enableBuffs) then
			return
		end
		mod = conf.tooltip.buffModifier
		ic = conf.tooltip.buffHideInCombat
	else
		if (not conf.tooltip.enable) then
			return
		end
		mod = conf.tooltip.modifier
		ic = conf.tooltip.hideInCombat
	end

	if (mod == "alt") then
		mod = IsAltKeyDown()
	elseif (mod == "shift") then
		mod = IsShiftKeyDown()
	elseif (mod == "control") then
		mod = IsControlKeyDown()
	else
		mod = true
	end

	mod = mod and (not ic or not InCombatLockdown())

	return mod
end

-- XPerl_PlayerTip
function XPerl_PlayerTip(self, unitid)
	if (not unitid) then
		unitid = SecureButton_GetUnit(self)
	end

	if (not unitid or XPerlLocked == 0) then
		return
	end

	if (not XPerl_TooltipModiferPressed()) then
		return
	end

	if (SpellIsTargeting()) then
		if (SpellCanTargetUnit(unitid)) then
			SetCursor("CAST_CURSOR")
		else
			SetCursor("CAST_ERROR_CURSOR")
		end
	end

	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(unitid)
	local r, g, b = GameTooltip_UnitColor(unitid)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
	GameTooltip:Show()

	if (XPerl_RaidTipExtra) then
		XPerl_RaidTipExtra(unitid)
	end

	XPerl_Highlight:TooltipInfo(UnitName(unitid))
end

-- XPerl_PlayerTipHide
function XPerl_PlayerTipHide()
	if (conf.tooltip.fading) then
		GameTooltip:FadeOut()
	else
		GameTooltip:Hide()
	end
end

-- XPerl_ColourFriendlyUnit
function XPerl_ColourFriendlyUnit(self, partyid)
	local color
	if (UnitCanAttack("player", partyid) and UnitIsEnemy("player", partyid)) then	-- For dueling
		color = conf.colour.reaction.enemy
	else
		if (conf.colour.class) then
			local _, class = UnitClass(partyid)
			color = XPerl_GetClassColour(class)
		else
			if (UnitIsPVP(partyid)) then
				color = conf.colour.reaction.friend
			else
				color = conf.colour.reaction.none
			end
		end
	end

	self:SetTextColor(color.r, color.g, color.b, conf.transparency.text)
end

-- XPerl_ReactionColour
function XPerl_ReactionColour(argUnit)
	if (UnitPlayerControlled(argUnit) or not UnitIsVisible(argUnit)) then
		if (UnitFactionGroup("player") == UnitFactionGroup(argUnit)) then
			if (UnitIsEnemy("player", argUnit)) then
				-- Dueling
				return conf.colour.reaction.enemy
			elseif (UnitIsPVP(argUnit)) then
				return conf.colour.reaction.friend
			end
		else
			if (UnitIsPVP(argUnit)) then
				if (UnitIsPVP("player")) then
					return conf.colour.reaction.enemy
				else
					return conf.colour.reaction.neutral
				end
			end
		end
	else
		if UnitIsTapDenied(argUnit) and not UnitIsFriend("player", argUnit) then
			return conf.colour.reaction.tapped
		else
			local reaction = UnitReaction(argUnit, "player")
			if (reaction) then
				if (reaction >= 5) then
					return conf.colour.reaction.friend
				elseif (reaction <= 2) then
					return conf.colour.reaction.enemy
				elseif (reaction == 3) then
					return conf.colour.reaction.unfriendly
				else
					return conf.colour.reaction.neutral
				end
			else
				if (UnitFactionGroup("player") == UnitFactionGroup(argUnit)) then
					return conf.colour.reaction.friend
				elseif (UnitIsEnemy("player", argUnit)) then
					return conf.colour.reaction.enemy
				else
					return conf.colour.reaction.neutral
				end
			end
		end
	end

	return conf.colour.reaction.none
end

-- XPerl_SetUnitNameColor
function XPerl_SetUnitNameColor(self, unit)
	local color
	if (UnitIsPlayer(unit) or not UnitIsVisible(unit)) then -- Changed UnitPlayerControlled to UnitIsPlayer for 2.3.5
		-- 1.8.3 - Changed to override pvp name colours
		if (conf.colour.class) then
			local _, class = UnitClass(unit)
			color = XPerl_GetClassColour(class)
		else
			color = XPerl_ReactionColour(unit)
		end
	else
		if UnitIsTapDenied(unit) and not UnitIsFriend("player", unit) then
			color = conf.colour.reaction.tapped
		else
			color = XPerl_ReactionColour(unit)
		end
	end

	self:SetTextColor(color.r, color.g, color.b, conf.transparency.text)
end

-- XPerl_CombatFlashSet
function XPerl_CombatFlashSet(self, elapsed, argNew, argGreen)
	if (not conf.combatFlash) then
		self.PlayerFlash = nil
		return
	end

	if (self) then
		if (argNew) then
			self.PlayerFlash = 1.2 -- Old value: 1.5
			self.PlayerFlashGreen = argGreen
		else
			if (elapsed and self.PlayerFlash) then
				self.PlayerFlash = self.PlayerFlash - elapsed

				if (self.PlayerFlash <= 0) then
					self.PlayerFlash = 0
					self.PlayerFlashGreen = nil
				end
			else
				return
			end
		end

		return true
	end
end

-- XPerl_CombatFlashSetFrames
function XPerl_CombatFlashSetFrames(self)
	if (self.PlayerFlash) then
		local baseColour = self.forcedColour or conf.colour.border

		local r, g, b, a
		if (self.PlayerFlash > 0) then
			local flashOffsetColour = min(self.PlayerFlash, 1) / 2
			if (self.PlayerFlashGreen) then
				r = min(1, max(0, baseColour.r - flashOffsetColour))
				g = min(1, max(0, baseColour.g + flashOffsetColour))
			else
				r = min(1, max(0, baseColour.r + flashOffsetColour))
				g = min(1, max(0, baseColour.g - flashOffsetColour))
			end
			b = min(1, max(0, baseColour.b - flashOffsetColour))
			a = min(1, max(0, baseColour.a + flashOffsetColour))
		else
			r, g, b, a = baseColour.r, baseColour.g, baseColour.b, baseColour.a
			self.PlayerFlash = false
		end

		for i = 1, #self.FlashFrames do
			self.FlashFrames[i]:SetBackdropBorderColor(r, g, b, a)
		end
	end
end

local MagicCureTalentsClassic = {
	["PALADIN"] = 4987, -- Clense
}

local MagicCureTalents = {
	["DRUID"] = 4, -- Resto
	["PALADIN"] = 1, -- Holy
	["SHAMAN"] = 3, -- Resto
	["MONK"] = 2, -- Mistweaver
	["EVOKER"] = 2 -- Preservation
}

local function CanClassCureMagic(class)
	if (MagicCureTalents[class]) then
		return not IsClassic and GetSpecialization() == MagicCureTalents[class] or (MagicCureTalentsClassic[class] and IsSpellKnown(MagicCureTalentsClassic[class]))
	end
end

local getShow
function ZPerl_DebufHighlightInit()
	-- We also re-set the colours here so that we highlight best colour per class
	if (playerClass == "MAGE") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Curse or show
		end
	elseif (playerClass == "DRUID") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Curse or Curses.Poison or magic or show
		end
	elseif (playerClass == "PRIEST") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Magic or Curses.Disease or show
		end
	elseif (playerClass == "WARLOCK") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Magic or show
		end
	elseif (playerClass == "MONK") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Poison or Curses.Disease or magic or show
		end
	elseif (playerClass == "PALADIN") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Poison or Curses.Disease or magic or show
		end
	elseif (playerClass == "SHAMAN") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return (not IsVanillaClassic and Curses.Curse) or (IsClassic and Curses.Poison) or (IsClassic and Curses.Disease) or magic or show
		end
	elseif (playerClass == "ROGUE") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			return Curses.Poison or show
		end
	elseif (playerClass == "EVOKER") then
		getShow = function(Curses)
			local show
			if (not conf.highlightDebuffs.class) then
				show = Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
			end
			local magic
			if (CanClassCureMagic(playerClass)) then
				magic = Curses.Magic
			end
			return Curses.Curse or Curses.Poison or Curses.Disease or magic or show
		end
	else
		getShow = function(Curses)
			return Curses.Magic or Curses.Curse or Curses.Poison or Curses.Disease
		end
	end

	ZPerl_DebufHighlightInit = nil
end

local bgDef = {
	bgFile = "Interface\\Addons\\ZPerl\\Images\\XPerl_FrameBack",
	edgeFile = "",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = {left = 2, right = 2, top = 2, bottom = 2}
}
local normalEdge = "Interface\\Tooltips\\UI-Tooltip-Border"
local curseEdge = "Interface\\Addons\\ZPerl\\Images\\XPerl_Curse"

-- XPerl_CheckDebuffs
--local Curses = setmetatable({ }, {__mode = "k"})	-- 2.2.6 - Now re-using static table to save garbage memory creation
local Curses = { }
function XPerl_CheckDebuffs(self, unit, resetBorders)
	if not self.FlashFrames then
		return
	end

	local high = conf.highlightDebuffs.enable or (self == XPerl_Target and conf.target.highlightDebuffs.enable) or (self == XPerl_Focus and conf.focus.highlightDebuffs.enable)

	if resetBorders or not high or not getShow then
		-- Reset the frame edges back to normal in case they changed options while debuffed.
		self.forcedColour = nil
		bgDef.edgeFile = self.edgeFile or normalEdge
		bgDef.edgeSize = self.edgeSize or 16
		bgDef.insets.left = self.edgeInsets or 3
		bgDef.insets.top = self.edgeInsets or 3
		bgDef.insets.right = self.edgeInsets or 3
		bgDef.insets.bottom = self.edgeInsets or 3
		--for i, f in pairs(self.FlashFrames) do
		for i = 1, #self.FlashFrames do
			local f = self.FlashFrames[i]
			f:SetBackdrop(bgDef)
			f:SetBackdropColor(conf.colour.frame.r, conf.colour.frame.g, conf.colour.frame.b, conf.colour.frame.a)
			f:SetBackdropBorderColor(conf.colour.border.r, conf.colour.border.g, conf.colour.border.b, conf.colour.border.a)
		end
		return
	end

	if not unit then
		unit = self:GetAttribute("unit")
		if not unit then
			return
		end
	end

	Curses.Magic, Curses.Curse, Curses.Poison, Curses.Disease = nil, nil, nil, nil

	local show
	local debuffCount = 0
	local _, unitClass = UnitClass(unit)

	for i = 1, 40 do
		local name, dispelName
		if not IsVanillaClassic and C_UnitAuras then
			local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
			if auraData then
				name = auraData.name
				dispelName = auraData.dispelName
			end
		else
			local _
			name, _, _, dispelName = UnitAura(unit, i, "HARMFUL")
		end
		if not name then
			break
		end

		if dispelName then
			local exclude = ArcaneExclusions[name]
			if not exclude or (type(exclude) == "table" and not exclude[unitClass]) then
				Curses[dispelName] = dispelName
				debuffCount = debuffCount + 1
			end
		end
	end

	if debuffCount > 0 then
		-- 2.2.6 - Very (very very) slight speed optimazation by having a function per class which is set at startup
		show = getShow(Curses)
	end

	local colour, borderColour
	if show then
		colour = DebuffTypeColor[show]
		colour.a = 1

		if conf.highlightDebuffs.border then
			borderColour = colour
		else
			borderColour = conf.colour.border
		end
	else
		colour = conf.colour.frame
		borderColour = conf.colour.border
	end

	if show and conf.highlightDebuffs.frame then
		self.forcedColour = borderColour
		bgDef.edgeFile = curseEdge
	else
		self.forcedColour = nil
		--bgDef.edgeFile = normalEdge

		bgDef.edgeFile = self.edgeFile or normalEdge
		bgDef.edgeSize = self.edgeSize or 16
		bgDef.insets.left = self.edgeInsets or 3
		bgDef.insets.top = self.edgeInsets or 3
		bgDef.insets.right = self.edgeInsets or 3
		bgDef.insets.bottom = self.edgeInsets or 3
	end

	--for i, f in pairs(self.FlashFrames) do
	for i = 1, #self.FlashFrames do
		local f = self.FlashFrames[i]
		if not conf.highlightDebuffs.frame then
			colour = conf.colour.frame
		end
		f:SetBackdrop(bgDef)
		f:SetBackdropColor(colour.r, colour.g, colour.b, colour.a)
		f:SetBackdropBorderColor(borderColour.r, borderColour.g, borderColour.b, borderColour.a)
	end
end

-- XPerl_GetSavePositionTable
function XPerl_GetSavePositionTable(create)
	if (not ZPerlConfigNew) then
		return
	end

	local name = UnitName("player")
	local realm = GetRealmName()

	if (not ZPerlConfigNew.savedPositions) then
		if (not create) then
			return
		end
		ZPerlConfigNew.savedPositions = {}
	end
	local c = ZPerlConfigNew.savedPositions
	if (not c[realm]) then
		if (not create) then
			return
		end
		c[realm] = {}
	end
	if (not c[realm][name]) then
		if (not create) then
			return
		end
		c[realm][name] = {}
	end
	local table = c[realm][name]

	return table
end


-- XPerl_SavePosition
function XPerl_SavePosition(self, onlyIfEmpty)
	local name = self:GetName()
	if (name) then
		local s = self:GetScale()
		local t = self:GetTop()
		local l = self:GetLeft()
		local h = self:IsResizable() and self:GetHeight()
		local w = self:IsResizable() and self:GetWidth()

		local table = XPerl_GetSavePositionTable(true)
		if (table) then
			if (not onlyIfEmpty or (onlyIfEmpty and not table[name])) then
				if (t and l) then
					if (not table[name]) then
						table[name] = {}
					end
					table[name].top = t * s
					table[name].left = l * s
					table[name].height = h
					table[name].width = w
				else
					table[name] = nil
				end
			else
				if (table[name] and not self:IsUserPlaced()) then
					XPerl_RestorePosition(self)
				end
			end
		end
	end
end

-- XPerl_RestorePosition
function XPerl_RestorePosition(self)
	if (ZPerlConfigNew.savedPositions) then
		local name = self:GetName()
		if (name) then
			local table = XPerl_GetSavePositionTable()
			if (table) then
				local pos = table[name]
				if (pos and pos.left and pos.top) then
					self:ClearAllPoints()
					self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left / self:GetScale(), pos.top / self:GetScale())

					if (pos.height and pos.width) then
						if (self:IsResizable()) then
							self:SetHeight(pos.height)
							self:SetWidth(pos.width)
						else
							pos.height, pos.width = nil, nil
						end
					end

					self:SetUserPlaced(true)
				end
			end
		end
	end
end

-- XPerl_RestoreAllPositions
function XPerl_RestoreAllPositions()
	local table = XPerl_GetSavePositionTable()
	if table then
		for k, v in pairs(table) do
			if k == "XPerl_Runes" or k == "XPerl_RaidHelper_Frame" or k == "XPerl_RaidMonitor_Frame" or k == "XPerl_Check" or k == "XPerl_AdminFrame" or k == "XPerl_Assists_Frame" then
				-- Fix for a wrong name with versions 2.3.2 and 2.3.2a
				-- It was using XPerl_Frame instead of XPerl_MTList_Anchor
				-- and XPerl_RaidMonitor_Frame instead of XPerl_RaidMonitor_Anchor
				-- And now a change to XPerl_Check to XPerl_CheckAnchor and XPerl_AdminFrame to XPerl_AdminFrameAnchor
				table[k] = nil
			elseif k == "XPerl_Options" or k == "XPerl_OptionsAnchor" then
				-- Noop
			else
				local frame = _G[k]
				if frame then
					--[[if k == "XPerl_Runes" and conf.player.dockRunes then
						break
					end]]
					if v.left and v.top then
						frame:SetUserPlaced(false)
						frame:ClearAllPoints()
						frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", v.left / frame:GetScale(), v.top / frame:GetScale())
						if k == "XPerl_Assists_FrameAnchor" then
							if ZPerlConfigHelper then
								if ZPerlConfigHelper.sizeAssistsX and ZPerlConfigHelper.sizeAssistsY then
									XPerl_Assists_Frame:SetWidth(ZPerlConfigHelper.sizeAssistsX)
									XPerl_Assists_Frame:SetHeight(ZPerlConfigHelper.sizeAssistsY)
								end
								if ZPerlConfigHelper.sizeAssistsS then
									XPerl_Assists_Frame:SetScale(ZPerlConfigHelper.sizeAssistsS)
								end
							end
						else
							if v.height and v.width then
								if frame:IsResizable() then
									frame:SetHeight(v.height)
									frame:SetWidth(v.width)
								else
									v.height, v.width = nil, nil
								end
							end
						end
						--[[if (k == "XPerl_Runes") then
							frame:SetMovable(true)
							frame:EnableMouse(true)
							frame:RegisterForDrag("LeftButton")
							frame:SetScript("OnDragStart", frame.StartMoving)
							frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
							frame:SetUserPlaced(true)
						else]]
							--frame:SetUserPlaced(true)
						--end
					end
				end
			end
		end
	end
end

local BuffExceptions
local DebuffExceptions
local SeasonalDebuffs
local RaidFrameIgnores
if IsRetail then
	BuffExceptions = {
		PRIEST = {
			[C_Spell.GetSpellInfo(774).name] = true,				-- Rejuvenation
			[C_Spell.GetSpellInfo(8936).name] = true,				-- Regrowth
			[C_Spell.GetSpellInfo(33076).name] = true,				-- Prayer of Mending
			[C_Spell.GetSpellInfo(81749).name] = true,				-- Atonement
		},
		DRUID = {
			[C_Spell.GetSpellInfo(139).name] = true,					-- Renew
		},
		WARLOCK = {
			[C_Spell.GetSpellInfo(20707).name] = true,				-- Soulstone Resurrection
		},
		HUNTER = {
			--[C_Spell.GetSpellInfo(13165).name] = true,				-- Aspect of the Hawk
			--[C_Spell.GetSpellInfo(5118).name] = true,				-- Aspect of the Cheetah
			--[C_Spell.GetSpellInfo(13159).name] = true,				-- Aspect of the Pack
			[C_Spell.GetSpellInfo(61648).name] = true,				-- Aspect of the Beast
			-- [C_Spell.GetSpellInfo(13163).name] = true,			-- Aspect of the Monkey
			--[C_Spell.GetSpellInfo(19506).name] = true,				-- Trueshot Aura
			[C_Spell.GetSpellInfo(5384).name] = true,				-- Feign Death
		},
		ROGUE = {
			[C_Spell.GetSpellInfo(1784).name] = true,				-- Stealth
			[C_Spell.GetSpellInfo(1856).name] = true,				-- Vanish
			[C_Spell.GetSpellInfo(2983).name] = true,				-- Sprint
			[C_Spell.GetSpellInfo(13750).name] = true,				-- Adrenaline Rush
			[C_Spell.GetSpellInfo(13877).name] = true,				-- Blade Flurry
		},
		PALADIN = {
			--[C_Spell.GetSpellInfo(20154).name] = true,				-- Seal of Righteousness
			--[C_Spell.GetSpellInfo(20165).name] = true,				-- Seal of Insight
			--[C_Spell.GetSpellInfo(20164).name] = true,				-- Seal of Justice
			--[C_Spell.GetSpellInfo(31801).name] = true,				-- Seal of Truth
			--[C_Spell.GetSpellInfo(20375).name] = true,				-- Seal of Command
			--[C_Spell.GetSpellInfo(20166).name] = true,				-- Seal of Wisdom
			--[C_Spell.GetSpellInfo(20165).name] = true,				-- Seal of Light
			--[C_Spell.GetSpellInfo(53736).name] = true,				-- Seal of Corruption
			--[C_Spell.GetSpellInfo(31892).name] = true,				-- Seal of Blood
			--[C_Spell.GetSpellInfo(31801).name] = true,				-- Seal of Vengeance
			[C_Spell.GetSpellInfo(25780).name] = true,				-- Righteous Fury
			--[C_Spell.GetSpellInfo(20925).name] = true,				-- Holy Shield
			--[C_Spell.GetSpellInfo(54428).name] = true,				-- Divine Plea
		},
	}
	DebuffExceptions = {
		ALL = {
			[C_Spell.GetSpellInfo(11196).name] = true,				-- Recently Bandaged
		},
		PRIEST = {
			[C_Spell.GetSpellInfo(6788).name] = true,				-- Weakened Soul
		},
		PALADIN = {
			[C_Spell.GetSpellInfo(25771).name] = true				-- Forbearance
		}
	}
	SeasonalDebuffs = {
		[C_Spell.GetSpellInfo(26004).name] = true,					-- Mistletoe
		[C_Spell.GetSpellInfo(26680).name] = true,					-- Adored
		[C_Spell.GetSpellInfo(26898).name] = true,					-- Heartbroken
		[C_Spell.GetSpellInfo(64805).name] = true,					-- Bested Darnassus
		[C_Spell.GetSpellInfo(64808).name] = true,					-- Bested the Exodar
		[C_Spell.GetSpellInfo(64809).name] = true,					-- Bested Gnomeregan
		[C_Spell.GetSpellInfo(64810).name] = true,					-- Bested Ironforge
		[C_Spell.GetSpellInfo(64811).name] = true,					-- Bested Orgrimmar
		[C_Spell.GetSpellInfo(64812).name] = true,					-- Bested Sen'jin
		[C_Spell.GetSpellInfo(64813).name] = true,					-- Bested Silvermoon City
		[C_Spell.GetSpellInfo(64814).name] = true,					-- Bested Stormwind
		[C_Spell.GetSpellInfo(64815).name] = true,					-- Bested Thunder Bluff
		[C_Spell.GetSpellInfo(64816).name] = true,					-- Bested the Undercity
		[C_Spell.GetSpellInfo(36900).name] = true,					-- Soul Split: Evil!
		[C_Spell.GetSpellInfo(36901).name] = true,					-- Soul Split: Good
		[C_Spell.GetSpellInfo(36899).name] = true,					-- Transporter Malfunction
		[C_Spell.GetSpellInfo(24755).name] = true,					-- Tricked or Treated
		[C_Spell.GetSpellInfo(69127).name] = true,					-- Chill of the Throne
		[C_Spell.GetSpellInfo(69438).name] = true,					-- Sample Satisfaction
	}

	RaidFrameIgnores = {
		[C_Spell.GetSpellInfo(26013).name] = true,					-- Deserter
		[C_Spell.GetSpellInfo(71041).name] = true,					-- Dungeon Deserter
		[C_Spell.GetSpellInfo(71328).name] = true,					-- Dungeon Cooldown
	}
else
	BuffExceptions = {
		PRIEST = {
			[GetSpellInfo(774)] = true,					-- Rejuvenation
			[GetSpellInfo(8936)] = true,				-- Regrowth
			--[GetSpellInfo(33076)] = true,				-- Prayer of Mending
			--[GetSpellInfo(81749)] = true,				-- Atonement
		},
		DRUID = {
			[GetSpellInfo(139)] = true,					-- Renew
		},
		WARLOCK = {
			[GetSpellInfo(20707)] = true,				-- Soulstone Resurrection
		},
		HUNTER = {
			[GetSpellInfo(13165)] = true,				-- Aspect of the Hawk
			[GetSpellInfo(5118)] = true,				-- Aspect of the Cheetah
			[GetSpellInfo(13159)] = true,				-- Aspect of the Pack
			--[GetSpellInfo(61648)] = true,				-- Aspect of the Beast
			--[GetSpellInfo(13163)] = true,				-- Aspect of the Monkey
			[GetSpellInfo(19506)] = true,				-- Trueshot Aura
			[GetSpellInfo(5384)] = true,				-- Feign Death
		},
		ROGUE = {
			[GetSpellInfo(1784)] = true,				-- Stealth
			[GetSpellInfo(1856)] = true,				-- Vanish
			[GetSpellInfo(2983)] = true,				-- Sprint
			[GetSpellInfo(13750)] = true,				-- Adrenaline Rush
			[GetSpellInfo(13877)] = true,				-- Blade Flurry
		},
		PALADIN = {
			[GetSpellInfo(20154)] = true,				-- Seal of Righteousness
			[GetSpellInfo(20165)] = true,				-- Seal of Insight
			[GetSpellInfo(20164)] = true,				-- Seal of Justice
			--[GetSpellInfo(31801)] = true,				-- Seal of Truth
			--[GetSpellInfo(20375)] = true,				-- Seal of Command
			--[GetSpellInfo(20166)] = true,				-- Seal of Wisdom
			[GetSpellInfo(20165)] = true,				-- Seal of Light
			--[GetSpellInfo(53736)] = true,				-- Seal of Corruption
			--[GetSpellInfo(31892)] = true,				-- Seal of Blood
			--[GetSpellInfo(31801)] = true,				-- Seal of Vengeance
			[GetSpellInfo(25780)] = true,				-- Righteous Fury
			[GetSpellInfo(20925)] = true,				-- Holy Shield
			--[GetSpellInfo(54428)] = true,				-- Divine Plea
		},
	}
	DebuffExceptions = {
		ALL = {
			[GetSpellInfo(11196)] = true,				-- Recently Bandaged
		},
		PRIEST = {
			[GetSpellInfo(6788)] = true,				-- Weakened Soul
		},
		PALADIN = {
			[GetSpellInfo(25771)] = true				-- Forbearance
		}
	}

	SeasonalDebuffs = {
		[GetSpellInfo(26004)] = true,					-- Mistletoe
		[GetSpellInfo(26680)] = true,					-- Adored
		[GetSpellInfo(26898)] = true,					-- Heartbroken
		--[GetSpellInfo(64805)] = true,					-- Bested Darnassus
		--[GetSpellInfo(64808)] = true,					-- Bested the Exodar
		--[GetSpellInfo(64809)] = true,					-- Bested Gnomeregan
		--[GetSpellInfo(64810)] = true,					-- Bested Ironforge
		--[GetSpellInfo(64811)] = true,					-- Bested Orgrimmar
		--[GetSpellInfo(64812)] = true,					-- Bested Sen'jin
		--[GetSpellInfo(64813)] = true,					-- Bested Silvermoon City
		--[GetSpellInfo(64814)] = true,					-- Bested Stormwind
		--[GetSpellInfo(64815)] = true,					-- Bested Thunder Bluff
		--[GetSpellInfo(64816)] = true,					-- Bested the Undercity
		--[GetSpellInfo(36900)] = true,					-- Soul Split: Evil!
		--[GetSpellInfo(36901)] = true,					-- Soul Split: Good
		--[GetSpellInfo(36899)] = true,					-- Transporter Malfunction
		[GetSpellInfo(24755)] = true,					-- Tricked or Treated
		--[GetSpellInfo(69127)] = true,					-- Chill of the Throne
		--[GetSpellInfo(69438)] = true,					-- Sample Satisfaction
	}

	RaidFrameIgnores = {
		[GetSpellInfo(26013)] = true,					-- Deserter
		--[GetSpellInfo(71041)] = true,					-- Dungeon Deserter
		--[GetSpellInfo(71328)] = true,					-- Dungeon Cooldown
	}
end

-- BuffException
local showInfo
local function BuffException(unit, index, filter, func, exceptions, raidFrames)
	local name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId
	if filter ~= "HELPFUL|RAID" and filter ~= "HARMFUL|RAID" then
		-- Not filtered, just return it
		if not IsVanillaClassic and C_UnitAuras then
			local auraData = func(unit, index, filter)
			if auraData then
				name = auraData.name
				icon = auraData.icon
				applications = auraData.applications
				dispelName = auraData.dispelName
				duration = auraData.duration
				expirationTime = auraData.expirationTime
				sourceUnit = auraData.sourceUnit
				isStealable = auraData.isStealable
				nameplateShowPersonal = auraData.nameplateShowPersonal
				spellId = auraData.spellId
			end
		else
			name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId = func(unit, index, filter)
		end
		return name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, index
	end

	if not IsVanillaClassic and C_UnitAuras then
		local auraData = func(unit, index, filter)
		if auraData then
			name = auraData.name
			icon = auraData.icon
			applications = auraData.applications
			dispelName = auraData.dispelName
			duration = auraData.duration
			expirationTime = auraData.expirationTime
			sourceUnit = auraData.sourceUnit
			isStealable = auraData.isStealable
			nameplateShowPersonal = auraData.nameplateShowPersonal
			spellId = auraData.spellId
		end
	else
		name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId = func(unit, index, filter)
	end
	if icon then
		-- We need the index of the buff unfiltered later for tooltips
		for i = 1, 40 do
			local name, icon, applications, sourceUnit
			if not IsVanillaClassic and C_UnitAuras then
				local auraData = func(unit, i, filter)
				if auraData then
					name = auraData.name
					icon = auraData.icon
					applications = auraData.applications
					sourceUnit = auraData.sourceUnit
				end
			else
				local _
				name, icon, applications, _, _, _, sourceUnit = func(unit, i, filter)
			end
			if not name then
				break
			end
			if name == name and icon == icon and applications == applications and sourceUnit == sourceUnit then
				index = i
				break
			end
		end

		return name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, index
	end

	-- See how many filtered buffs WoW has returned by default
	local normalBuffFilterCount = 0
	for i = 1, 40 do
		if not IsVanillaClassic and C_UnitAuras then
			local auraData = func(unit, i, filter == "HELPFUL" and "HELPFUL|RAID" or (filter == "HARMFUL" and "HARMFUL|RAID" or filter))
			if auraData then
				name = auraData.name
			end
		else
			name = func(unit, i, filter == "HELPFUL" and "HELPFUL|RAID" or (filter == "HARMFUL" and "HARMFUL|RAID" or filter))
		end
		if not name then
			normalBuffFilterCount = i - 1
			break
		end
	end

	-- Nothing found by default, so look for exceptions that we want to tack onto the end
	local unitClass
	local foundValid = 0
	local classExceptions = exceptions[playerClass]
	local allExceptions = exceptions.ALL
	for i = 1, 40 do
		if not IsVanillaClassic and C_UnitAuras then
			local auraData = func(unit, i, filter)
			if auraData then
				name = auraData.name
				icon = auraData.icon
				applications = auraData.applications
				dispelName = auraData.dispelName
				duration = auraData.duration
				expirationTime = auraData.expirationTime
				sourceUnit = auraData.sourceUnit
				isStealable = auraData.isStealable
				nameplateShowPersonal = auraData.nameplateShowPersonal
				spellId = auraData.spellId
			end
		else
			name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId = func(unit, i, filter)
		end
		if not name then
			break
		end

		local good
		if classExceptions then
			good = classExceptions[name]
		end
		if not good and allExceptions then
			good = allExceptions[name]
		end

		if type(good) == "string" then
			if not unitClass then
				local _, class = UnitClass(unit)
				unitClass = class
			end
			if good ~= unitClass then
				good = nil
			end
		end

		if good then
			foundValid = foundValid + 1
			if foundValid + normalBuffFilterCount == index then
				return name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId, i
			end
		end
	end
end

-- DebuffException
local function DebuffException(unit, start, filter, func, raidFrames)
	local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, index
	local valid = 0
	for i = 1, 40 do
		name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, index = BuffException(unit, i, filter, func, DebuffExceptions, raidFrames)
		if not name then
			break
		end
		if not SeasonalDebuffs[name] and not (raidFrames and RaidFrameIgnores[name]) then
			valid = valid + 1
			if valid == start then
				return name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, index
			end
		end
	end
end

-- XPerl_UnitBuff
function XPerl_UnitBuff(unit, index, filter, raidFrames)
	return BuffException(unit, index, filter, (IsVanillaClassic and unit == "target") and UnitAuraWithBuffs or ((not IsVanillaClassic and C_UnitAuras) and C_UnitAuras.GetAuraDataByIndex or UnitAura), BuffExceptions, raidFrames)
end

-- XPerl_UnitDebuff
function XPerl_UnitDebuff(unit, index, filter, raidFrames)
	if conf.buffs.ignoreSeasonal or raidFrames then
		return DebuffException(unit, index, filter, (not IsVanillaClassic and C_UnitAuras) and C_UnitAuras.GetAuraDataByIndex or UnitAura, raidFrames)
	end
	return BuffException(unit, index, filter, (not IsVanillaClassic and C_UnitAuras) and C_UnitAuras.GetAuraDataByIndex or UnitAura, DebuffExceptions, raidFrames)
end

-- XPerl_TooltipSetUnitBuff
-- Retreives the index of the actual unfiltered buff, and uses this on unfiltered tooltip call
function XPerl_TooltipSetUnitBuff(self, unit, ind, filter, raidFrames)
	local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, index = BuffException(unit, ind, filter, (IsVanillaClassic and unit == "target") and UnitAuraWithBuffs or ((not IsVanillaClassic and C_UnitAuras) and C_UnitAuras.GetAuraDataByIndex or UnitAura), BuffExceptions, raidFrames)
	if name and index then
		if Utopia_SetUnitBuff then
			Utopia_SetUnitBuff(self, unit, index)
		else
			self:SetUnitBuff(unit, index)
		end
	end
end

-- XPerl_TooltipSetUnitDebuff
-- Retreives the index of the actual unfiltered debuff, and uses this on unfiltered tooltip call
function XPerl_TooltipSetUnitDebuff(self, unit, ind, filter, raidFrames)
	local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID, index = XPerl_UnitDebuff(unit, ind, filter, raidFrames)
	if name and index then
		if Utopia_SetUnitDebuff then
			Utopia_SetUnitDebuff(self, unit, index)
		else
			self:SetUnitDebuff(unit, index)
		end
	end
end

----------------------
-- Fading Bar Stuff --
----------------------
local fadeBars = {}
local freeFadeBars = {}
local tempDisableFadeBars

function XPerl_NoFadeBars(tempDisable)
	tempDisableFadeBars = tempDisable
end

-- CheckOnUpdate
local function CheckOnUpdate()
	if next(fadeBars) then
		XPerl_Globals:SetScript("OnUpdate", XPerl_BarUpdate)
	else
		XPerl_Globals:SetScript("OnUpdate", nil)
	end
end

-- XPerl_BarUpdate
--local speakerTimer = 0
--local speakerCycle = 0
function XPerl_BarUpdate(self, arg1)
	local did
	for k, v in pairs(fadeBars) do
		if k:IsShown() then
			v:SetAlpha(k.fadeAlpha)
			k.fadeAlpha = k.fadeAlpha - (arg1 / conf.bar.fadeTime)

			local r, g, b = v.tex:GetVertexColor()
			v:SetStatusBarColor(r, g, b)
		else
			-- Not shown, so end it
			k.fadeAlpha = 0
		end

		if k.fadeAlpha <= 0 then
			tinsert(freeFadeBars, v)
			fadeBars[k] = nil
			k.fadeAlpha = nil
			k.fadeBar = nil
			v:SetValue(0)
			v:Hide()
			v.tex = nil
			did = true
		end
	end

	if did then
		CheckOnUpdate()
	end
end

-- GetFreeFader
local function GetFreeFader(parent)
	local bar = freeFadeBars[1]
	if bar then
		tremove(freeFadeBars, 1)
		bar:SetParent(parent)
	else
		bar = CreateFrame("StatusBar", nil, parent)
	end

	if bar then
		fadeBars[parent] = bar
		CheckOnUpdate()

		bar.tex = parent.tex

		local tex = parent:GetStatusBarTexture()
		if tex:GetTexture() then
			bar:SetStatusBarTexture(tex:GetTexture())
			bar:GetStatusBarTexture():SetHorizTile(false)
			bar:GetStatusBarTexture():SetVertTile(false)
		end

		local r, g, b = bar.tex:GetVertexColor()
		bar:SetStatusBarColor(r, g, b)

		bar:SetFrameLevel(parent:GetFrameLevel())

		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", 0, 0)
		bar:SetPoint("BOTTOMRIGHT", 0, 0)
		bar:SetAlpha(1)

		return bar
	end
end

-- XPerl_StatusBarSetValue
function XPerl_StatusBarSetValue(self, val)
	if not tempDisableFadeBars and conf.bar.fading and self:GetName() then
		local min, max = self:GetMinMaxValues()
		local current = self:GetValue()

		if val < current and val <= max and val >= min then
			local bar = fadeBars[self]

			if not bar then
				bar = GetFreeFader(self)
			end

			if bar then
				if not self.fadeAlpha then
					self.fadeAlpha = self:GetParent():GetAlpha()
					bar:SetValue(current)
				end

				bar:SetMinMaxValues(min, max)
				bar:SetAlpha(self.fadeAlpha)
				bar:Show()
			end
		end
	end

	XPerl_OldStatusBarSetValue(self, val)
end

-- XPerl_RegisterClickCastFrame
function XPerl_RegisterClickCastFrame(self)
	if not ClickCastFrames then
		ClickCastFrames = { }
	end
	ClickCastFrames[self] = true
end

function XPerl_UnregisterClickCastFrame(self)
	if ClickCastFrames then
		ClickCastFrames[self] = nil
	end
end

-- XPerl_SecureUnitButton_OnLoad
function XPerl_SecureUnitButton_OnLoad(self, unit, menufunc, m1, m2, toggledisabled)
	self:SetAttribute("*type1", "target")
	if toggledisabled then
		self:SetAttribute("type2", "menu")
	else
		self:SetAttribute("type2", "togglemenu")
	end

	if unit then
		self:SetAttribute("unit", unit)
	end

	XPerl_RegisterClickCastFrame(self)
end

-- XPerl_GetBuffButton
local buffIconCount = 0
function XPerl_GetBuffButton(self, buffnum, debuff, createIfAbsent, newID)
	debuff = debuff or 0
	local buffType, buffList		--, buffFrame

	if debuff == 1 then
		--buffFrame = self.debuffFrame
		buffType = "DeBuff"
		buffList = self.buffFrame.debuff
		if not buffList then
			self.buffFrame.debuff = { }
			buffList = self.buffFrame.debuff
		end
	else
		--buffFrame = self.buffFrame
		buffType = "Buff"
		buffList = self.buffFrame.buff
		if not buffList then
			self.buffFrame.buff = { }
			buffList = self.buffFrame.buff
		end
	end

	local button = buffList and buffList[buffnum]

	if not button and createIfAbsent then
		local setup = self.buffSetup
		local parent = self.buffFrame

		if debuff == 1 and setup.debuffParent then
			parent = self.debuffFrame
		end

		buffIconCount = buffIconCount + 1
		button = CreateFrame("Button", "XPerlBuff"..buffIconCount, parent, BackdropTemplateMixin and format("BackdropTemplate,XPerl_Cooldown_%sTemplate", buffType) or format("XPerl_Cooldown_%sTemplate", buffType))
		button:Hide()

		if setup.rightClickable then
			button:RegisterForClicks("RightButtonUp")
			--button:SetAttribute("type", "cancelaura")
			--button:SetAttribute("index", "number")
		end

		local size = self.conf.buffs.size
		if debuff == 1 then
			size = self.conf.debuffs.size or (size * (1 + (setup.debuffSizeMod * debuff)))
		end
		button:SetScale(size / 32)

		if setup.onCreate then
			setup.onCreate(button)
		end

		if debuff == 1 then
			--buffFrame.UpdateTooltip = setup.updateTooltipDebuff
			button.UpdateTooltip = setup.updateTooltipDebuff
			for k, v in pairs (setup.debuffScripts) do
				button:SetScript(k, v)
			end
		else
			--buffFrame.UpdateTooltip = setup.updateTooltipBuff
			button.UpdateTooltip = setup.updateTooltipBuff
			for k, v in pairs (setup.buffScripts) do
				button:SetScript(k, v)
			end
		end
		buffList[buffnum] = button

		button:ClearAllPoints()
		if buffnum == 1 then
			if debuff == 1 then
				if setup.debuffAnchor1 then
					setup.debuffAnchor1(self, button)
				end
			else
				if setup.buffAnchor1 then
					setup.buffAnchor1(self, button)
				end
			end
		else
			button:SetPoint("TOPLEFT", buffList[buffnum - 1], "TOPRIGHT", 1 + debuff, 0)
		end
	end
	-- TODO: Variable this
	button.cooldown:SetDrawEdge(false)
	-- Blizzard Cooldown Text Support
	if not conf.buffs.blizzard then
		button.cooldown:SetHideCountdownNumbers(true)
	else
		button.cooldown:SetHideCountdownNumbers(false)
	end
	-- OmniCC Support
	if not conf.buffs.omnicc then
		button.cooldown.noCooldownCount = true
	else
		button.cooldown.noCooldownCount = nil
	end
	button:SetID(newID or buffnum)

	return button
end

-- BuffCooldownDisplay
local function BuffCooldownDisplay(self)
	if self.countdown then
		local t = GetTime()
		if t > self.endTime - 1 then
			self.countdown:SetText(strsub(format("%.1f", max(0, self.endTime - t)), 2, 10))
			self.countdown:Show()
		elseif t > self.endTime - conf.buffs.countdownStart then
			self.countdown:SetText(max(0, floor(self.endTime - t)))
			self.countdown:Show()
		else
			self.countdown:Hide()
		end
	end
end

-- XPerl_CooldownFrame_SetTimer(self, start, duration, enable)
function XPerl_CooldownFrame_SetTimer(self, start, duration, enable, mine)
	if start > 0 and duration > 0 and enable > 0 then
		self:SetCooldown(start, duration)
		self.endTime = start + duration

		if conf.buffs.countdown and (mine or conf.buffs.countdownAny) then
			self:SetScript("OnUpdate", BuffCooldownDisplay)
		else
			self:SetScript("OnUpdate", nil)
			self.countdown:Hide()
		end

		self:Show()
	else
		self:Hide()
	end
end

-- AuraButtonOnShow
local function AuraButtonOnShow(self)
	if (not conf.buffs.blizzardCooldowns) then
		if (self.cooldown) then
			self.cooldown:Hide()
		end
		return
	end

	local cd = self.cooldown
	if (not cd) then
		cd = CreateFrame("Cooldown", nil, self, BackdropTemplateMixin and "BackdropTemplate,CooldownFrameTemplate" or "CooldownFrameTemplate")
		self.cooldown = cd
		if self.Icon then
			cd:SetAllPoints(self.Icon)
		else
			cd:SetAllPoints(self:GetName().."Icon")
		end
	end
	cd:SetReverse(true)
	--cd:SetDrawEdge(true) Blizzard removed this call from 5.0.4, commented it out to avoid lua error

	if (not cd.countdown) then
		cd.countdown = self.cooldown:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
		if self.Icon then
			cd.countdown:SetPoint("TOPLEFT", self.Icon)
			cd.countdown:SetPoint("BOTTOMRIGHT", self.Icon, -1, 2)
		else
			cd.countdown:SetPoint("TOPLEFT", self:GetName().."Icon")
			cd.countdown:SetPoint("BOTTOMRIGHT", self:GetName().."Icon", -1, 2)
		end
		cd.countdown:SetTextColor(1, 1, 0)
	end

	local duration, expirationTime, sourceUnit
	if not IsVanillaClassic and C_UnitAuras then
		local auraData = C_UnitAuras.GetAuraDataByIndex("player", self.xindex, self.xfilter)
		if auraData then
			duration = auraData.duration
			expirationTime = auraData.expirationTime
			sourceUnit = auraData.sourceUnit
		end
	else
		local _
		_, _, _, _, duration, expirationTime, sourceUnit = UnitAura("player", self.xindex, self.xfilter)
	end

	if duration and expirationTime then
		local start = expirationTime - duration
		XPerl_CooldownFrame_SetTimer(self.cooldown, start, duration, 1, sourceUnit == "player")
	end
end

-- XPerl_AuraButton_UpdateInFo
-- Hook for Blizzard aura button setup to add cooldowns if we have them enabled
local function XPerl_AuraButton_UpdateInfo(button, buttonInfo, expanded)
	if not button then
		return
	end
	if (conf.buffs.blizzardCooldowns and BuffFrame:IsShown()) then
		button.xindex = buttonInfo.index
		button.xfilter = buttonInfo.filter
		button:SetScript("OnShow", AuraButtonOnShow)
		if (button:IsShown()) then
			AuraButtonOnShow(button)
		end
	end
end

-- XPerl_AuraButton_Update
-- Hook for Blizzard aura button setup to add cooldowns if we have them enabled
local function XPerl_AuraButton_Update(buttonName, index, filter)
	if (conf.buffs.blizzardCooldowns and BuffFrame:IsShown()) then
		local buffName = buttonName..index
		local button = _G[buffName]
		if (button) then
			button.xindex = index
			button.xfilter = filter
			button:SetScript("OnShow", AuraButtonOnShow)
			if (button:IsShown()) then
				AuraButtonOnShow(button)
			end
		end
	end
end

if AuraFrameMixin then
	-- TODO: Figure out what's changed here
	--hooksecurefunc(AuraFrameMixin, "Update", XPerl_AuraButton_UpdateInfo)
elseif AuraButton_Update then
	hooksecurefunc("AuraButton_Update", XPerl_AuraButton_Update)
end

-- XPerl_Unit_BuffSpacing
local function XPerl_Unit_BuffSpacing(self)
	local w = self.statsFrame:GetWidth()
	if (self.portraitFrame and self.portraitFrame:IsShown()) then
		w = w - 2 + self.portraitFrame:GetWidth()
	end
	if (self.levelFrame and self.levelFrame:IsShown()) then
		w = w - 2 + self.levelFrame:GetWidth()
	end
	if (not self.buffSpacing) then
		--self.buffSpacing = XPerl_GetReusableTable()
		self.buffSpacing = { }
	end
	self.buffSpacing.rowWidth = w

	local srs = 0
	if (not self.conf.buffs.above) then
		if (not self.statsFrame.manaBar or not self.statsFrame.manaBar:IsShown()) then
			srs = 10
		end

		if (self.creatureTypeFrame and self.creatureTypeFrame:IsShown()) then
			srs = srs + self.creatureTypeFrame:GetHeight() - 2
		end
	end

	if (srs > 0) then
		self.buffSpacing.smallRowHeight = srs
		self.buffSpacing.smallRowWidth = self.statsFrame:GetWidth()
	else
		self.buffSpacing.smallRowHeight = 0
		self.buffSpacing.smallRowWidth = w
	end
end

-- WieghAnchor(self, at)
local function WieghAnchor(self)
	if (not self.TOPLEFT or self.conf.flip ~= self.lastFlip or self.conf.buffs.above ~= self.lastAbove) then
		self.lastFlip = self.conf.flip
		self.lastAbove = self.conf.buffs.above

		local left, right, top, bottom
		if (self.conf.flip) then
			left, right = "RIGHT", "LEFT"
			self.SPACING = -1
		else
			left, right = "LEFT", "RIGHT"
			self.SPACING = 1
		end
		if (self.conf.buffs.above) then
			top, bottom = "BOTTOM", "TOP"
			self.VSPACING = 1
		else
			top, bottom = "TOP", "BOTTOM"
			self.VSPACING = -1
		end

		self.TOPLEFT = top..left
		self.TOPRIGHT = top..right
		self.BOTTOMLEFT = bottom..left
		self.BOTTOMRIGHT = bottom..right
	end
end

-- XPerl_Unit_BuffPositionsType
local function XPerl_Unit_BuffPositionsType(self, list, useSmallStart, buffSizeBase)
	local prevBuff, reusedSpace, hideFrom
	local firstOfRow = nil
	local prevRow, prevRowI = list[1], 1
	if (not prevRow) then
		return
	end
	local above = self.conf.buffs.above
	local colPoint, curRow, rowsHeight = 0, 1, 0
	local rowSize = (useSmallStart and self.buffSpacing.smallRowWidth) or self.buffSpacing.rowWidth
	local maxRows = self.conf.buffs.rows or 99
	local decrementMaxRowsIfLastIsBig -- Descriptive variable names ftw... If only upvalues took no actual memory space for the name... :(

	for i = 1, #list do
		if (curRow > maxRows) then
			hideFrom = i
			break
		end

		if (rowsHeight >= self.buffSpacing.smallRowHeight) then
			rowSize = self.buffSpacing.rowWidth
		end

		local buff = list[i]
		if (i > 1 and not buff:IsShown()) then
			break
		end

		local buffSize = (buff.big and (buffSizeBase * 2)) or buffSizeBase

		buff:ClearAllPoints()
		if (i == 1) then
			prevRow, prevRowI = buff, 1

			if (buff.big) then
				if (curRow == maxRows) then
					maxRows = maxRows + 1
					decrementMaxRowsIfLastIsBig = true
				end
			end

			if (self.prevBuff) then
				buff:SetPoint(self.TOPLEFT, self.prevBuff, self.BOTTOMLEFT, 0, self.VSPACING)
			else
				buff:SetPoint(self.TOPLEFT, 0, 0)
			end
		elseif (firstOfRow) then
			firstOfRow = nil
			if (not buff.big and prevRow.big and not reusedSpace) then
				-- Previous row starts with a big buff at start, so we try to use the odd space between rows
				-- for normal size buffs instead of starting a new row and having a buff width of wasted space.
				-- So we get:
				--	1123456
				--	11789AB
				--	CDEF
				-- Instead of:
				--	1123456
				--	11
				--	789ABCD
				--	EF

				local tempColPoint = (buffSizeBase * 2) + 1
				local j = prevRowI
				while (j < #list) do
					local temp = list[j + 1]
					if (temp and temp.big) then
						tempColPoint = tempColPoint + (buffSizeBase * 2) + 1
						j = j + 1
					else
						break
					end
				end

				if (tempColPoint < rowSize - buffSizeBase) then		--  and rowsHeight - buffSizeBase - 1 >= self.buffSpacing.smallRowHeight
					local prevRowBig, prevRowBigI = list[j], j
					colPoint = tempColPoint
					buff:SetPoint(self.BOTTOMLEFT, prevRowBig, self.BOTTOMRIGHT, self.SPACING, 0)
				else
					buff:SetPoint(self.TOPLEFT, prevRow, self.BOTTOMLEFT, 0, self.VSPACING)
					prevRow, prevRowI = buff, i
				end
				reusedSpace = true
			else
				buff:SetPoint(self.TOPLEFT, prevRow, self.BOTTOMLEFT, 0, self.VSPACING)
				prevRow, prevRowI = buff, i
				reusedSpace = nil

				if (buff.big) then
					if (curRow == maxRows) then
						maxRows = maxRows + 1
						decrementMaxRowsIfLastIsBig = true
					end
				end
			end
		else
			buff:SetPoint(self.TOPLEFT, prevBuff, self.TOPRIGHT, self.SPACING, 0)
		end

		colPoint = colPoint + buffSize + 1

		local nextBuff = list[i + 1]
		local nextBuffSize = buffSize
		if (nextBuff) then
			nextBuffSize = (nextBuff.big and (buffSizeBase * 2)) or buffSizeBase
		end

		if (self.conf.buffs.wrap and colPoint + nextBuffSize + 1 > rowSize) then
			if (buff.big and decrementMaxRowsIfLastIsBig) then
				decrementMaxRowsIfLastIsBig = nil
				maxRows = maxRows - 1
			end

			colPoint = 0
			curRow = curRow + 1
			if (prevRow.big) then
				rowsHeight = rowsHeight + (buffSize * 2) + 1
			else
				rowsHeight = rowsHeight + buffSize + 1
			end
			firstOfRow = true
		end

		prevBuff = buff
	end

	if (hideFrom) then
		for i = hideFrom,#list do
			list[i]:Hide()
		end
	end
	if (useSmallStart) then
		self.hideFrom1 = hideFrom
	else
		self.hideFrom2 = hideFrom
	end

	self.prevBuff = prevRow
end

-- XPerl_Unit_BuffPositions
function XPerl_Unit_BuffPositions(self, buffList1, buffList2, size1, size2)
	local optMix = format("%d%d%d%d%d%d%d", self.perlBuffs or 0, self.perlDebuffs or 0, self.perlBuffsMine or 0, self.perlDebuffsMine or 0, UnitCanAttack("player", self.partyid) and 1 or 0, (UnitPowerMax(self.partyid) > 0) and 1 or 0, (self.creatureTypeFrame and self.creatureTypeFrame:IsVisible()) and 1 or 0)
	if (optMix ~= self.buffOptMix) then
		WieghAnchor(self)

		local buffsFirst = self.buffFrame.buff == buffList1

		self.buffOptMix = optMix
		self.prevBuff = nil

		if (self.GetBuffSpacing) then
			self:GetBuffSpacing(self)
		else
			XPerl_Unit_BuffSpacing(self)
		end

		-- De-anchor first 2 because faction changes can mess up the order of things.
		if (buffList1 and buffList1[1]) then
			buffList1[1]:ClearAllPoints()
		end
		if (buffList2 and buffList2[1]) then
			buffList2[1]:ClearAllPoints()
		end

		if (buffList1) then
			XPerl_Unit_BuffPositionsType(self, buffList1, true, size1)
		end
		if (buffList2) then
			XPerl_Unit_BuffPositionsType(self, buffList2, false, size2)
		end

		if (buffList2) then
			-- If top row is disabled, then nudge the bottom row into it's place
			if (buffsFirst) then
				if (not self.conf.buffs.enable) then
					buffList2[1]:SetPoint(self.TOPLEFT, self.buffFrame, self.TOPLEFT, 0, self.VSPACING)
				end
			else
				if (not self.conf.debuffs.enable) then
					buffList2[1]:SetPoint(self.TOPLEFT, self.buffFrame, self.TOPLEFT, 0, self.VSPACING)
				end
			end
		end
	else
		if (self.hideFrom1 and buffList1) then
			for i = self.hideFrom1,#buffList1 do
				buffList1[i]:Hide()
			end
		end
		if (self.hideFrom2 and buffList2) then
			for i = self.hideFrom2,#buffList2 do
				buffList2[i]:Hide()
			end
		end
	end
end

--[[local function fixMeBlizzard(self)
	self.anim:Play()
	self:SetScript("OnUpdate", nil)
end]]

-- XPerl_Unit_UpdateBuffs(self)
function XPerl_Unit_UpdateBuffs(self, maxBuffs, maxDebuffs, castableOnly, curableOnly)
	local buffs, debuffs, buffsMine, debuffsMine = 0, 0, 0, 0
	local partyid = self.partyid

	if (self.conf and UnitExists(partyid)) then
		if (not maxBuffs) then
			maxBuffs = 40
		end
		if (not maxDebuffs) then
			maxDebuffs = 40
		end
		local lastIcon = 0

		XPerl_GetBuffButton(self, 1, 0, true)
		XPerl_GetBuffButton(self, 1, 1, true)

		local isFriendly = not UnitCanAttack("player", partyid)

		if (self.conf.buffs.enable and maxBuffs and maxBuffs > 0) then
			local buffIconIndex = 1
			self.buffFrame:Show()
			for mine = 1, 2 do
				if (self.conf.buffs.onlyMine and mine == 2) then
					if (not UnitCanAttack("player", partyid)) then
						break
					end
					-- else we'll ignore this option for enemy targets, because
					-- it's unlikey that we'll be buffing them
				end
				-- Two passes here now since 3.0.1, cos they did away with the GetPlayerBuff function
				-- in favor of all in UnitAura instead. We still want our big buffs first in the list,
				-- so we have to scan thru twice. I know what you're thinking: "Why do 2 passes when
				-- player's buffs are first anyway". Well, usually they are, but in the case of hunters
				-- and warlocks, the pet triggered buffs can be anywhere, but we still want those alongside
				-- our own buffs.
				for buffnum = 1, maxBuffs do
					local filter = castableOnly == 1 and "HELPFUL|RAID" or "HELPFUL"
					local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID = XPerl_UnitBuff(partyid, buffnum, filter)
					if (not name) then
						if (mine == 1) then
							maxBuffs = buffnum - 1
						end
						break
					end

					local isPlayer
					if (self.conf.buffs.bigpet) then
						isPlayer = unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"
					else
						isPlayer = unitCaster == "player" or unitCaster == "vehicle"
					end

					if (icon and (((mine == 1) and (isPlayer or canStealOrPurge)) or ((mine == 2) and not (isPlayer or canStealOrPurge)))) then
						local button = XPerl_GetBuffButton(self, buffIconIndex, 0, true, buffnum)
						button.filter = filter
						button:SetAlpha(1)

						buffs = buffs + 1

						button.icon:SetTexture(icon)
						if (count > 1) then
							button.count:SetText(count)
							button.count:Show()
						else
							button.count:Hide()
						end

						-- Handle cooldowns
						if (button.cooldown) then
							if (duration and duration > 0 and expirationTime and expirationTime > 0 and conf.buffs.cooldown and (isPlayer or conf.buffs.cooldownAny)) then
								local start = expirationTime - duration
								XPerl_CooldownFrame_SetTimer(button.cooldown, start, duration, 1, isPlayer)
							else
								button.cooldown:Hide()
							end
						end

						button:Show()

						if (canStealOrPurge) then --  and UnitCanAttack("player", partyid)
							if (not button.steal) then
								button.steal = CreateFrame("Frame", nil, button, BackdropTemplateMixin and "BackdropTemplate")
								button.steal:SetPoint("TOPLEFT", -2, 2)
								button.steal:SetPoint("BOTTOMRIGHT", 2, -2)

								button.steal.tex = button.steal:CreateTexture(nil, "OVERLAY")
								button.steal.tex:SetAllPoints()
								button.steal.tex:SetTexture("Interface\\Addons\\ZPerl\\Images\\StealMe")

								local g = button.steal.tex:CreateAnimationGroup()
								button.steal.anim = g
								local r = g:CreateAnimation("Rotation")
								g.rot = r

								r:SetDuration(4)
								r:SetDegrees(-360)
								r:SetOrigin("CENTER", 0, 0)

								g:SetLooping("REPEAT")
								g:Play()
							end

							button.steal:Show()
							button.steal.anim:Play()
							--button.steal:SetScript("OnUpdate", fixMeBlizzard) -- Workaround for Play not always working...
						else
							if (button.steal) then
								button.steal:Hide()
							end
						end

						lastIcon = buffIconIndex

						if ((self.conf.buffs.big and isPlayer) or (self.conf.buffs.bigStealable and canStealOrPurge)) then
							buffsMine = buffsMine + 1
							button.big = true
							button:SetScale((self.conf.buffs.size * 2) / 32)
						else
							button.big = nil
							button:SetScale(self.conf.buffs.size / 32)
						end
						buffIconIndex = buffIconIndex + 1
					end
				end
			end
			for buffnum = lastIcon + 1, 40 do
				local button = self.buffFrame.buff and self.buffFrame.buff[buffnum]
				if (button) then
					button.expireTime = nil
					button:Hide()
				else
					break
				end
			end
		else
			self.buffFrame:Hide()
		end

		if (self.conf.debuffs.enable and maxDebuffs and maxDebuffs > 0) then
			local buffIconIndex = 1
			self.debuffFrame:Show()
			lastIcon = 0
			for mine = 1, 2 do
				if (self.conf.debuffs.onlyMine and mine == 2) then
					if (UnitCanAttack("player", partyid)) then
						break
					end
					-- Else we'll ignore this option for friendly targets, because it's unlikey
					-- (except for PW:Shield and HoProtection) that we'll be debuffing friendlies
				end

				for buffnum = 1, maxDebuffs do
					local filter = (isFriendly and curableOnly == 1) and "HARMFUL|RAID" or "HARMFUL"
					local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellID = XPerl_UnitDebuff(partyid, buffnum, filter)

					if (not name) then
						if (mine == 1) then
							maxDebuffs = buffnum - 1
						end
						break
					end

					local isPlayer
					if (self.conf.buffs.bigpet) then
						isPlayer = unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"
					else
						isPlayer = unitCaster == "player"
					end

					if (icon and (((mine == 1) and isPlayer) or ((mine == 2) and not isPlayer))) then
						local button = XPerl_GetBuffButton(self, buffIconIndex, 1, true, buffnum)
						button.filter = filter
						button:SetAlpha(1)

						debuffs = debuffs + 1

						button.icon:SetTexture(icon)
						if ((count or 0) > 1) then
							button.count:SetText(count)
							button.count:Show()
						else
							button.count:Hide()
						end

						local borderColor = DebuffTypeColor[(debuffType or "none")]
						button.border:SetVertexColor(borderColor.r, borderColor.g, borderColor.b)

						-- Handle cooldowns
						if (button.cooldown) then
							if (duration and duration > 0 and expirationTime and expirationTime > 0 and conf.buffs.cooldown and (isPlayer or conf.buffs.cooldownAny)) then
								local start = expirationTime - duration
								XPerl_CooldownFrame_SetTimer(button.cooldown, start, duration, 1, isPlayer)
							else
								button.cooldown:Hide()
							end
						end

						lastIcon = buffIconIndex
						button:Show()

						if (self.conf.debuffs.big and isPlayer) then
							debuffsMine = debuffsMine + 1
							button.big = true
							button:SetScale((self.conf.debuffs.size * 2) / 32)
						else
							button.big = nil
							button:SetScale(self.conf.debuffs.size / 32)
						end
						buffIconIndex = buffIconIndex + 1
					end
				end
			end
			for buffnum = lastIcon + 1, 40 do
				local button = self.buffFrame.debuff and self.buffFrame.debuff[buffnum]
				if (button) then
					button.expireTime = nil
					button:Hide()
				else
					break
				end
			end
		else
			self.debuffFrame:Hide()
		end
	end

	self.perlBuffs = buffs
	self.perlDebuffs = debuffs

	if (self.conf and self.conf.buffs.big) then
		self.perlBuffsMine = buffsMine
		self.perlDebuffsMine = debuffsMine
	else
		self.perlBuffsMine, self.perlDebuffsMine = nil, nil
	end
end

-- XPerl_SetBuffSize
function XPerl_SetBuffSize(self)
	local sizeBuff = self.conf.buffs.size
	local sizeDebuff = (self.conf.debuffs and self.conf.debuffs.size) or (sizeBuff * (1 + self.buffSetup.debuffSizeMod))

	local buff
	for i = 1, 40 do
		buff = self.buffFrame.buff and self.buffFrame.buff[i]
		if (buff) then
			buff:SetScale(sizeBuff / 32)
		end

		buff = self.buffFrame.debuff and self.buffFrame.debuff[i]
		if (buff) then
			buff:SetScale(sizeDebuff / 32)
		end

		buff = self.buffFrame.tempEnchant and self.buffFrame.tempEnchant[i]
		if (buff) then
			buff:SetScale(sizeBuff / 32)
		end
	end
end

-- XPerl_Update_RaidIcon
function XPerl_Update_RaidIcon(self, unit)
	local index = GetRaidTargetIndex(unit)
	if index then
		local mark
		if unit == "player" or unit == "vehicle" or unit == "target" or unit == "focus" then
			if self.texture then
				mark = self.texture
			else
				mark = self
			end
		else
			mark = self
		end
		SetRaidTargetIconTexture(mark, index)
		self:Show()
	else
		self:Hide()
	end
end

------------------------------------------------------------------------------
-- Flashing frames handler. Is hidden when there's nothing to do.
local FlashFrame = CreateFrame("Frame", "XPerl_FlashFrame", nil, BackdropTemplateMixin and "BackdropTemplate")
FlashFrame.list = { }

-- XPerl_FrameFlash_OnUpdate(self, elapsed)
local function XPerl_FrameFlash_OnUpdate(self, elapsed)
	for k, v in pairs(self.list) do
		if (k.frameFlash.out) then
			k.frameFlash.alpha = k.frameFlash.alpha - elapsed
			if (k.frameFlash.alpha < 0.2) then
				k.frameFlash.alpha = 0.2
				k.frameFlash.out = nil

				if (k.frameFlash.method == "out") then
					XPerl_FrameFlashStop(k)
				end
			end
		else
			k.frameFlash.alpha = k.frameFlash.alpha + elapsed
			if (k.frameFlash.alpha > 1) then
				k.frameFlash.alpha = 1
				k.frameFlash.out = true

				if (k.frameFlash.method == "in") then
					XPerl_FrameFlashStop(k)
				end
			end
		end

		if (k.frameFlash) then
			k:SetAlpha(k.frameFlash.alpha)
		end
	end
end

FlashFrame:SetScript("OnUpdate", XPerl_FrameFlash_OnUpdate)

-- XPerl_FrameFlash
function XPerl_FrameFlash(self)
	if (not FlashFrame.list[self]) then
		if (self.frameFlash) then
			error("X-Perl ["..self:GetName()..".frameFlash is set with no entry in FlashFrame.list]")
		end

		--[[self.frameFlash = XPerl_GetReusableTable()
		self.frameFlash.out = true
		self.frameFlash.alpha = 1
		self.frameFlash.shown = self:IsShown()]]
		self.frameFlash = {out = true, alpha = 1, shown = self:IsShown()}

		FlashFrame.list[self] = true
		FlashFrame:Show()
		self:Show()
	end
end

-- XPerl_FrameIsFlashing(self)
function XPerl_FrameIsFlashing(self)
	return self.frameFlash		--FlashFrame.list[self]
end

-- XPerl_FrameFlashStop
function XPerl_FrameFlashStop(self, method)
	if (not self.frameFlash) then
		return
	end

	if (method) then
		self.frameFlash.method = method
		return
	end

	if (not self.frameFlash.shown) then
		self:Hide()
	end

	--XPerl_FreeTable(self.frameFlash)
	self.frameFlash = nil

	self:SetAlpha(1)

	FlashFrame.list[self] = nil

	if (not next(FlashFrame.list)) then
		FlashFrame:Hide()
	end
end

-- XPerl_ProtectedCall
function XPerl_ProtectedCall(func, self)
	if (func) then
		if (InCombatLockdown()) then
			XPerl_OutOfCombatQueue[func] = self == nil and false or self
			--[[if (self) then
				tinsert(XPerl_OutOfCombatQueue, {func, self})
			else
				tinsert(XPerl_OutOfCombatQueue, func)
			end]]
		else
			func(self)
		end
	end
end

-- nextMember(last)
function XPerl_NextMember(_, last)
	if (last) then
		local raidCount = GetNumGroupMembers()
		if (raidCount > 0) then
			if (IsInRaid()) then
				local i = tonumber(strmatch(last, "^raid(%d+)"))
				if (i and i < raidCount) then
					i = i + 1
					local unitName, _, group, _, _, unitClass, zone, online, dead = GetRaidRosterInfo(i)
					return "raid"..i, unitName, unitClass, group, zone, online, dead
				end
			else
				local partyCount = GetNumSubgroupMembers()
				if (partyCount > 0) then
					local id
					if (last == "player") then
						id = "party1"
					else
						local i = tonumber(strmatch(last, "^party(%d+)"))
						if (i and i < partyCount) then
							i = i + 1
							id = "party"..i
						end
					end

					if (id) then
						local _, class = UnitClass(id)
						return id, UnitName(id), class, 1, "", UnitIsConnected(id), UnitIsDeadOrGhost(id)
					end
				end
			end
		end
	else
		if (IsInRaid()) then
			local unitName, _, group, _, _, unitClass, zone, online, dead = GetRaidRosterInfo(1)
			return "raid1", unitName, unitClass, group, zone, online, dead
		else
			local _, class = UnitClass("player")
			return "player", UnitName("player"), class, 1, GetRealZoneText(), 1, UnitIsDeadOrGhost("player")
		end
	end
end

-- XPerl_Unit_UpdatePortrait
function XPerl_Unit_UpdatePortrait(self, force)
	if (self.conf and self.conf.portrait) then
		if self.conf.classPortrait then
			local _, englishClass = UnitClass(self.partyid)
			if UnitIsPlayer(self.partyid) and englishClass then
				SetPortraitToTexture(self.portraitFrame.portrait, "Interface\\Icons\\ClassIcon_"..englishClass)
			else
				SetPortraitTexture(self.portraitFrame.portrait, self.partyid)
			end
		else
			SetPortraitTexture(self.portraitFrame.portrait, self.partyid)
		end
		-- If a player moves out of range for a 3D portrait, it will show their proper 2D one
		if (self.conf.portrait3D and UnitIsVisible(self.partyid)) then
			self.portraitFrame.portrait:Hide()
			local guid = UnitGUID(self.partyid)
			if force or guid ~= self.portraitFrame.portrait3D.guid or not self.portraitFrame.portrait3D:IsShown() then
				self.portraitFrame.portrait3D:Show()
				self.portraitFrame.portrait3D:ClearModel()
				self.portraitFrame.portrait3D:SetUnit(self.partyid)
				self.portraitFrame.portrait3D:SetPortraitZoom(1)
				self.portraitFrame.portrait3D.guid = guid
			end
		else
			self.portraitFrame.portrait:Show()
			self.portraitFrame.portrait3D:Hide()
		end
	end
end

-- XPerl_Unit_UpdateLevel
function XPerl_Unit_UpdateLevel(self)
	local level = UnitLevel(self.partyid)
	local color = GetDifficultyColor(level)
	if (self.levelFrame) then
		self.levelFrame.text:SetTextColor(color.r,color.g,color.b)
		self.levelFrame.text:SetText(level)
	elseif (self.nameFrame.level) then
		if (level == 0) then
			level = ""
		end
		self.nameFrame.level:SetTextColor(color.r,color.g,color.b)
		self.nameFrame.level:SetText(level)
	end
end

-- XPerl_Unit_GetHealth
--This function sucks, it needs reworking so it self corrects /0 problems here. But i haven't quite figured out how to approach it here yet. So i just fix stuff at sethealth functions.
function XPerl_Unit_GetHealth(self)
	local partyid = self.partyid
	local hp, hpMax = UnitIsGhost(partyid) and 1 or (UnitIsDead(partyid) and 0 or UnitHealth(partyid)), UnitHealthMax(partyid)

	if (hp > hpMax) then
		if (UnitIsGhost(partyid)) then
			hp = 1
		elseif UnitIsDead(partyid) then
			hp = 0
		else
			hp = hpMax
		end
	end

	return hp or 0, hpMax or 1, (hpMax == 100)
end

-- ZPerl_Unit_OnEnter
function ZPerl_Unit_OnEnter(self)
	XPerl_PlayerTip(self)
	if (self.highlight) then
		self.highlight:Select()
	end

	if (self.statsFrame and self.statsFrame.healthBar and self.statsFrame.healthBar.text and not self.statsFrame.healthBar.text:IsShown()) then
		self.hideValues = true
		self.statsFrame.healthBar.text:Show()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Show()
		end
		if (self.statsFrame.xpBar and self.statsFrame.xpBar:IsShown()) then
			self.statsFrame.xpBar.text:Show()
		end
		if (self.statsFrame.repBar and self.statsFrame.repBar:IsShown()) then
			self.statsFrame.repBar.text:Show()
		end
	end
end

-- ZPerl_Unit_OnLeave
function ZPerl_Unit_OnLeave(self)
	XPerl_PlayerTipHide()
	if (self.highlight) then
		self.highlight:Deselect()
	end

	if (self.hideValues) then
		self.hideValues = nil

		self.statsFrame.healthBar.text:Hide()
		if (self.statsFrame.manaBar) then
			self.statsFrame.manaBar.text:Hide()
		end
		if (self.statsFrame.xpBar and self.statsFrame.xpBar:IsShown()) then
			self.statsFrame.xpBar.text:Hide()
		end
		if (self.statsFrame.repBar and self.statsFrame.repBar:IsShown()) then
			self.statsFrame.repBar.text:Hide()
		end
	end
end

-- XPerl_Unit_SetBuffTooltip
function XPerl_Unit_SetBuffTooltip(self)
	if (conf and conf.tooltip.enableBuffs and XPerl_TooltipModiferPressed(true)) then
		if (not conf.tooltip.buffHideInCombat or not InCombatLockdown()) then
			local frame = self:GetParent():GetParent()
			local partyid = frame.partyid
			if (partyid) then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 0)
				XPerl_TooltipSetUnitBuff(GameTooltip, partyid, self:GetID(), self.filter)
			end
		end
	end
end

-- XPerl_Unit_SetDeBuffTooltip
function XPerl_Unit_SetDeBuffTooltip(self)
	if (conf and conf.tooltip.enableBuffs and XPerl_TooltipModiferPressed(true)) then
		if (not conf.tooltip.hideInCombat or not InCombatLockdown()) then
			local frame = self:GetParent():GetParent()
			local partyid = frame.partyid
			if (partyid) then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT", 0, 0)
				XPerl_TooltipSetUnitDebuff(GameTooltip, partyid, self:GetID(), self.filter)
			end
		end
	end
end

-- XPerl_Unit_UpdateReadyState
function XPerl_Unit_UpdateReadyState(self)
	local status = conf.showReadyCheck and self.partyid and GetReadyCheckStatus(self.partyid)
	if status then
		self.statsFrame.ready:Show()
		if status == "ready" then
			if IsRetail then
				self.statsFrame.ready.check:SetAtlas(READY_CHECK_READY_TEXTURE)
			else
				self.statsFrame.ready.check:SetTexture(READY_CHECK_READY_TEXTURE)
			end
		elseif status == "waiting" then
			if IsRetail then
				self.statsFrame.ready.check:SetAtlas(READY_CHECK_WAITING_TEXTURE)
			else
				self.statsFrame.ready.check:SetTexture(READY_CHECK_WAITING_TEXTURE)
			end
		elseif status == "notready" then
			if IsRetail then
				self.statsFrame.ready.check:SetAtlas(READY_CHECK_NOT_READY_TEXTURE)
			else
				self.statsFrame.ready.check:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
			end
		else
			self.statsFrame.ready:Hide()
		end
	else
		self.statsFrame.ready:Hide()
	end
end

-- XPerl_SwitchAnchor(self, new)
-- Changes anchored corner without actually moving the frame

-- XPerl_SwitchAnchor
function XPerl_SwitchAnchor(self, New)
	if (not self:GetPoint(2)) then
		local a1, f, a2, x, y = self:GetPoint(1)

		if (a1 == a2 and New ~= a1) then
			local parent = self:GetParent()
			local newV = strmatch(New, "TOP") or strmatch(New, "BOTTOM")
			local newH = strmatch(New, "LEFT") or strmatch(New, "RIGHT")

			if (newV == "TOP") then
				y = -(768 - (self:GetTop() * self:GetEffectiveScale())) / self:GetEffectiveScale()
			elseif (newV == "BOTTOM") then
				y = self:GetBottom()
			else
				y = self:GetBottom() + self:GetHeight() / 2
			end

			if (newH == "LEFT") then
				x = self:GetLeft()
			elseif (newV == "RIGHT") then
				x = self:GetRight()
			else
				x = self:GetLeft() + self:GetWidth() / 2
			end

			self:ClearAllPoints()
			self:SetPoint(New, f, New, x, y)
		end
	end
end

---------------------------------
-- Scaling frame corner thingy --
---------------------------------
-- Seems a convoluted way of doing things, rather than just anchoring bottomleft, topright.. but
-- doing that introduces a really ugly latency between the anchor moving and the frame scaling because
-- the OnSizeChanged event is fired on the frame after the actual resize took place.

local scaleIndication

local function scaleMouseDown(self)

	GameTooltip:Hide()

	if (self.resizable and IsShiftKeyDown()) then
		self.sizing = true
	elseif (self.scalable) then
		self.scaling = true
	end

	if (not scaleIndication) then
		scaleIndication = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		scaleIndication:SetWidth(100)
		scaleIndication:SetHeight(18)
		scaleIndication.text = scaleIndication:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		scaleIndication.text:SetAllPoints()
		scaleIndication.text:SetJustifyH("LEFT")
	end

	scaleIndication:Show()
	scaleIndication:ClearAllPoints()
	scaleIndication:SetPoint("LEFT", self, "RIGHT", 4, 0)

	if (self.scaling) then
		scaleIndication.text:SetFormattedText("%.1f%%", self.frame:GetScale() * 100)
	else
		scaleIndication.text:SetFormattedText("%dx%d", self.frame:GetWidth(), self.frame:GetHeight())
	end

	self.anchor:StartSizing(self.resizeTop and "TOPRIGHT")

	self.oldBdBorder = {self.frame:GetBackdropBorderColor()}
	self.frame:SetBackdropBorderColor(1, 1, 0.5, 1)
end

local function scaleMouseUp(self)
	self.anchor:StopMovingOrSizing()

	scaleIndication:Hide()

	XPerl_SavePosition(self.anchor)

	if self.resizeTop then
		XPerl_SwitchAnchor(self.anchor, "BOTTOMLEFT")
	end

	if self.scaling then
		if self.onScaleChanged then
			self:onScaleChanged(self.frame:GetScale())
		end
	end

	if self.sizing then
		if self.onSizeChanged then
			self:onSizeChanged(self.frame:GetWidth(), self.frame:GetHeight())
		end
	end

	if self.oldBdBorder then
		self.frame:SetBackdropBorderColor(unpack(self.oldBdBorder))
		self.oldBdBorder = nil
	end

	self.scaling = nil
	self.sizing = nil
end

local function scaleMouseChange(self)
	if (self.corner.sizing) then
		self.corner.frame:SetWidth(self:GetWidth() / self.corner.frame:GetScale())
		self.corner.frame:SetHeight(self:GetHeight() / self.corner.frame:GetScale())

		self.corner.startSize.w = self.corner.frame:GetWidth()
		self.corner.startSize.h = self.corner.frame:GetHeight()

		if (scaleIndication and scaleIndication:IsShown()) then
			scaleIndication.text:SetFormattedText("|c00FFFF80%d|c00808080x|c00FFFF80%d", self.corner.frame:GetWidth(), self.corner.frame:GetHeight())
		end

	elseif (self.corner.scaling) then
		local w = self:GetWidth()
		if (w) then
			self.corner.scaling = nil
			local ratio = self.corner.frame:GetWidth() / self.corner.frame:GetHeight()
			local s = min(self.corner.maxScale, max(self.corner.minScale, w / self.corner.startSize.w))	-- New Scale

			w = self.corner.startSize.w * s		-- Set height and width of anchor window to match ratio of actual
			if (self.corner.resizeTop) then
				XPerl_SwitchAnchor(self, "BOTTOMLEFT")
				local bottom, left = self:GetBottom(), self:GetLeft()
				self:SetWidth(w)
				self:SetHeight(w / ratio)
			else
				self:SetWidth(w)
				self:SetHeight(w / ratio)
			end

			if (scaleIndication and scaleIndication:IsShown()) then
				scaleIndication.text:SetFormattedText("%.1f%%", s * 100)
			end

			self.corner.frame:SetScale(s)
			self.corner.scaling = true
		end
	end
end

-- scaleMouseEnter
local function scaleMouseEnter(self)
	self.tex:SetVertexColor(1, 1, 1, 1)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if (self.scalable) then
		GameTooltip:SetText(XPERL_DRAGHINT1, nil, nil, nil, nil, true)
	end
	if (self.resizable) then
		GameTooltip:AddLine(XPERL_DRAGHINT2, nil, nil, nil, true)
	end
	GameTooltip:Show()
end

-- scaleMouseLeave
local function scaleMouseLeave(self)
	self.tex:SetVertexColor(1, 1, 1, 0.5)
	GameTooltip:Hide()
end

-- XPerl_RegisterScalableFrame
function XPerl_RegisterScalableFrame(self, anchorFrame, minScale, maxScale, resizeTop, resizable, scalable)
	if (scalable == nil) then
		scalable = true
	end

	if (not self.corner) then
		self.corner = CreateFrame("Frame", nil, self)
		self.corner:SetFrameLevel(self:GetFrameLevel() + 3)
		self.corner:EnableMouse(true)
		self.corner:SetScript("OnMouseDown", scaleMouseDown)
		self.corner:SetScript("OnMouseUp", scaleMouseUp)
		self.corner:SetScript("OnEnter", scaleMouseEnter)
		self.corner:SetScript("OnLeave", scaleMouseLeave)
		self.corner:SetHeight(12)
		self.corner:SetWidth(12)

		anchorFrame:SetScript("OnSizeChanged", scaleMouseChange)
		anchorFrame.corner = self.corner

		self.corner.tex = self.corner:CreateTexture(nil, "BORDER")
		self.corner.tex:SetTexture("Interface\\Addons\\ZPerl\\Images\\XPerl_Elements")
		self.corner.tex:SetAllPoints()
		self.corner.tex:SetVertexColor(1, 1, 1, 0.5)

		self.corner.anchor = anchorFrame
		self.corner.frame = self
	end

	if self.SetResizeBounds then
		self:SetResizeBounds(10, 10)
	else
		self:SetMinResize(10, 10)
	end

	self.corner.scalable = scalable
	self.corner.resizable = resizable
	self.corner.resizeTop = resizeTop
	self.corner.minScale = minScale or 0.4
	self.corner.maxScale = maxScale or 5
	self.corner.startSize = {w = self:GetWidth(), h = self:GetHeight()}

	local bgDef = self:GetBackdrop()

	self.corner:ClearAllPoints()
	if (resizeTop) then
		self.corner.tex:SetTexCoord(0.78125, 1, 0.5, 0.703125)
		self.corner:SetPoint("TOPRIGHT", -bgDef.insets.right, -bgDef.insets.top)
		self.corner:SetHitRectInsets(0, -6, -6, 0)		-- So the click area extends over the tooltip border
	else
		self.corner.tex:SetTexCoord(0.78125, 1, 0.78125, 1)
		self.corner:SetPoint("BOTTOMRIGHT", -bgDef.insets.right, bgDef.insets.bottom)
		self.corner:SetHitRectInsets(0, -6, 0, -6)		-- So the click area extends over the tooltip border
	end

	self.corner.scaling = true
	scaleMouseChange(anchorFrame)
	self.corner.scaling = nil
end

-- XPerl_SetExpectedAbsorbs
function XPerl_SetExpectedAbsorbs(self)
	local bar
	if self.statsFrame and self.statsFrame.expectedAbsorbs then
		bar = self.statsFrame.expectedAbsorbs
	else
		bar = self.expectedAbsorbs
	end
	if (bar) then
		local unit = self.partyid

		if not unit then
			unit = self:GetParent().targetid
		end

		local amount = not IsClassic and UnitGetTotalAbsorbs(unit)
		if (amount and amount > 0 and not UnitIsDeadOrGhost(unit)) then
			local healthMax = UnitHealthMax(unit)
			local health = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit))

			if UnitIsAFK(unit) then
				bar:SetStatusBarColor(0.2, 0.2, 0.2, 0.7)
			else
				if not conf.colour.bar.absorb then
					conf.colour.bar.absorb = { }
					conf.colour.bar.absorb.r = 0.14
					conf.colour.bar.absorb.g = 0.33
					conf.colour.bar.absorb.b = 0.7
					conf.colour.bar.absorb.a = 0.7
				end

				bar:SetStatusBarColor(conf.colour.bar.absorb.r, conf.colour.bar.absorb.g, conf.colour.bar.absorb.b, conf.colour.bar.absorb.a)
			end

			bar:Show()
			bar:SetMinMaxValues(0, healthMax)

			local healthBar
			if self.statsFrame and self.statsFrame.healthBar then
				healthBar = self.statsFrame.healthBar
			else
				healthBar = self.healthBar
			end
			local min, max = healthBar:GetMinMaxValues()
			local position = ((max - healthBar:GetValue()) / max) * healthBar:GetWidth()

			if healthBar:GetWidth() <= 0 or healthBar:GetWidth() == position then
				return
			end

			bar:SetValue(amount * (healthBar:GetWidth() / (healthBar:GetWidth() - position)))

			bar:SetPoint("TopRight", healthBar, "TopRight", -position, 0)
			bar:SetPoint("BottomRight", healthBar, "BottomRight", -position, 0)
			return
		end
		bar:Hide()
	end
end

-- XPerl_SetExpectedHots
function XPerl_SetExpectedHots(self)
	if WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then
		return
	end
	local bar
	if self.statsFrame and self.statsFrame.expectedHots then
		bar = self.statsFrame.expectedHots
	else
		bar = self.expectedHots
	end
	if (bar) then
		local unit = self.partyid

		if not unit then
			unit = self:GetParent().targetid
		end

		local amount
		if IsVanillaClassic then
			local guid = UnitGUID(unit)
			amount = (HealComm:GetHealAmount(guid, HealComm.OVERTIME_HEALS, GetTime() + 3) or 0) * HealComm:GetHealModifier(guid)
		end

		if (amount and amount > 0 and not UnitIsDeadOrGhost(unit)) then
			local healthMax = UnitHealthMax(unit)
			local health = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit))

			if UnitIsAFK(unit) then
				bar:SetStatusBarColor(0.2, 0.2, 0.2, 0.7)
			else
				bar:SetStatusBarColor(conf.colour.bar.hot.r, conf.colour.bar.hot.g, conf.colour.bar.hot.b, conf.colour.bar.hot.a)
			end

			bar:Show()
			bar:SetMinMaxValues(0, healthMax)
			bar:SetValue(min(healthMax, health + amount))

			return
		end
		bar:Hide()
	end
end

-- XPerl_SetExpectedHealth
function XPerl_SetExpectedHealth(self)
	local bar
	if self.statsFrame and self.statsFrame.expectedHealth then
		bar = self.statsFrame.expectedHealth
	else
		bar = self.expectedHealth
	end
	if (bar) then
		local unit = self.partyid

		if not unit then
			unit = self:GetParent().targetid
		end

		local amount
		if IsVanillaClassic then
			local guid = UnitGUID(unit)
			amount = (HealComm:GetHealAmount(guid, HealComm.CASTED_HEALS, GetTime() + 3) or 0) * HealComm:GetHealModifier(guid)
		else
			amount = UnitGetIncomingHeals(unit)
		end
		if (amount and amount > 0 and not UnitIsDeadOrGhost(unit)) then
			local healthMax = UnitHealthMax(unit)
			local health = UnitIsGhost(unit) and 1 or (UnitIsDead(unit) and 0 or UnitHealth(unit))
			if not conf.colour.bar.healprediction then
				conf.colour.bar.healprediction = { }
				conf.colour.bar.healprediction.r = 0
				conf.colour.bar.healprediction.g = 1
				conf.colour.bar.healprediction.b = 1
				conf.colour.bar.healprediction.a = 1
			end

			bar:SetStatusBarColor(conf.colour.bar.healprediction.r, conf.colour.bar.healprediction.g, conf.colour.bar.healprediction.b, conf.colour.bar.healprediction.a)

			bar:Show()
			bar:SetMinMaxValues(0, healthMax)
			bar:SetValue(min(healthMax, health + amount))

			return
		end
		bar:Hide()
	end
end

-- Threat Display
local function DrawHand(self, percent)
	local angle = 360 - (percent * 2.7 - 135)
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = rotate(angle)
	self.needle:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end

local function DrawSlider(self, percent)
	local offset = (self:GetWidth() - 9) / 100 * percent
	self.needle:ClearAllPoints()
	self.needle:SetPoint("CENTER", self, "TOPLEFT", offset + 5, -2)

	local r, g, b
	if (percent <= 70) then
		r, g, b = 0, 1, 0
	else
		r, g, b = smoothColor(abs((percent - 100) / 30))
	end

	self.needle:SetVertexColor(r, g, b)
end

-- XPerl_ThreatDisplayOnLoad
function XPerl_ThreatDisplayOnLoad(self, mode)
	XPerl_SetChildMembers(self)
	self:SetFrameLevel(self:GetParent():GetFrameLevel() + 4)
	self.text:SetWidth(100)
	self.current, self.target = 0, 0
	self.mode = mode

	if (mode == "nameFrame") then
		self.Draw = DrawSlider
	else
		self.Draw = DrawHand
	end
	self:Draw(0)
end

-- threatOnUpdate
local function threatOnUpdate(self, elapsed)
	local diff = (self.target - self.current) * 0.2
	self.current = min(100, max(0, self.current + diff))
	if (abs(self.current - self.target) <= 0.01) then
		self.current = self.target
		self:SetScript("OnUpdate", nil)
	end

	self:Draw(self.current)
end

-- XPerl_Unit_ThreatStatus
function XPerl_Unit_ThreatStatus(self, relative, immediate)
	if (IsClassic or not self.partyid or not self.conf) then
		return
	end

	local mode = self.conf.threatMode or (self.conf.portrait and "portraitFrame" or "nameFrame")
	local t = self.threatFrames and self.threatFrames[mode]
	if (not self.conf.threat) then
		if (t) then
			t:Hide()
		end
		return
	end

	if (not t) then
		if (self.threatFrames) then
			for mode,frame in pairs(self.threatFrames) do
				frame:SetScript("OnUpdate", nil)
				frame.current, frame.target = 0, 0
				frame:Hide()
			end
		else
			self.threatFrames = {}
		end
		if (self[mode]) then -- If desired parent frame exists
			t = CreateFrame("Frame", self:GetName().."Threat"..mode, self[mode], BackdropTemplateMixin and "BackdropTemplate,XPerl_ThreatTemplate"..mode or "XPerl_ThreatTemplate"..mode)
			t:SetAllPoints()
			self.threatFrames[mode] = t
		end

		self.threat = self.threatFrames[mode]
	end

	if (t) then
		local isTanking, state, scaledPercent, rawPercent, threatValue
		local one, two
		if (UnitAffectingCombat(self.partyid) or (relative and UnitAffectingCombat(relative))) then
			if (relative and UnitCanAttack(relative, self.partyid)) then
				one, two = relative, self.partyid
			else
				if (UnitExists("target") and UnitCanAttack(self.partyid, "target")) then
					one, two = self.partyid, "target"
				elseif (UnitCanAttack("player", self.partyid)) then
					one, two = "player", self.partyid
				elseif (UnitCanAttack(self.partyid, self.partyid.."target")) then
					one, two = self.partyid, self.partyid.."target"
				end
			end

			if (one) then
				-- scaledPercent is 0% - 100%, 100 means you pull agro
				-- rawPercent is before normalization so can go up to 110% or 130% before you pull agro
				isTanking, state, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation(one, two)
			end
		end

		if (scaledPercent) then
			if (scaledPercent ~= t.target) then
				t.target = scaledPercent
				if (immediate) then
					t.current = scaledPercent
				end
				t.one = one
				t.two = two
				t:SetScript("OnUpdate", threatOnUpdate)
			end

			t.text:SetFormattedText("%d%%", scaledPercent)
			local r, g, b = smoothColor(scaledPercent)
			t.text:SetTextColor(r, g, b)

			t:Show()
			return
		end

		t:Hide()
	end
end

function XPerl_Register_Prediction(self, conf, guidToUnit, ...)
	if not self then
		return
	end

	if not IsVanillaClassic then
		if conf.healprediction then
			self:RegisterUnitEvent("UNIT_HEAL_PREDICTION", ...)
		else
			self:UnregisterEvent("UNIT_HEAL_PREDICTION")
		end

		if not IsPandaClassic then
			if conf.absorbs then
				self:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", ...)
			else
				self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
			end
		--[[else
			-- HoT predictions do not work properly on Wrath/Cata Classic so use HealComm
			if conf.hotPrediction then
				local UpdateHealth = function(event, ...)
					local unit = guidToUnit(select(select("#", ...), ...))
					if unit then
						local f = self:GetScript("OnEvent")
						f(self, "UNIT_HEAL_PREDICTION", unit)
					end
				end
				HealComm.RegisterCallback(self, "HealComm_HealStarted", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_HealStopped", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_HealDelayed", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_HealUpdated", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_ModifierChanged", UpdateHealth)
				HealComm.RegisterCallback(self, "HealComm_GUIDDisappeared", UpdateHealth)
			else
				HealComm.UnregisterCallback(self, "HealComm_HealStarted")
				HealComm.UnregisterCallback(self, "HealComm_HealStopped")
				HealComm.UnregisterCallback(self, "HealComm_HealDelayed")
				HealComm.UnregisterCallback(self, "HealComm_HealUpdated")
				HealComm.UnregisterCallback(self, "HealComm_ModifierChanged")
				HealComm.UnregisterCallback(self, "HealComm_GUIDDisappeared")
			end--]]
		end
	else
		if conf.healprediction then
			local UpdateHealth = function(event, ...)
				local unit = guidToUnit(select(select("#", ...), ...))
				if unit then
					local f = self:GetScript("OnEvent")
					f(self, "UNIT_HEAL_PREDICTION", unit)
				end
			end
			HealComm.RegisterCallback(self, "HealComm_HealStarted", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_HealStopped", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_HealDelayed", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_HealUpdated", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_ModifierChanged", UpdateHealth)
			HealComm.RegisterCallback(self, "HealComm_GUIDDisappeared", UpdateHealth)
		else
			HealComm.UnregisterCallback(self, "HealComm_HealStarted")
			HealComm.UnregisterCallback(self, "HealComm_HealStopped")
			HealComm.UnregisterCallback(self, "HealComm_HealDelayed")
			HealComm.UnregisterCallback(self, "HealComm_HealUpdated")
			HealComm.UnregisterCallback(self, "HealComm_ModifierChanged")
			HealComm.UnregisterCallback(self, "HealComm_GUIDDisappeared")
		end
	end
end
