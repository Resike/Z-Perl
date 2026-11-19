-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local cast
local MonUnits = {}			-- Fixed list of all monitor units
local TableUnits = {}			-- Dynamic list of units indexed by raid id, changed on attr change
ZPerlRaidMonitorDB = {}
local config = ZPerlRaidMonitorDB

-- Upvalues
local ipairs = ipairs
local pairs = pairs
local strfind = strfind
local strmatch = strmatch
local tinsert = tinsert
local type = type
local unpack = unpack

local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsInRaid = IsInRaid
local SecureButton_GetModifiedAttribute = SecureButton_GetModifiedAttribute
local SecureButton_GetUnit = SecureButton_GetUnit
local UnitCastingInfo = UnitCastingInfo
local UnitChannelInfo = UnitChannelInfo
local UnitClass = UnitClass
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitInParty = UnitInParty
local UnitIsConnected = UnitIsConnected
local UnitIsDead = UnitIsDead
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsGhost = UnitIsGhost
local UnitIsUnit = UnitIsUnit
local UnitIsVisible = UnitIsVisible
local UnitName = UnitName
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType

local FAILED = FAILED
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local SPELL_FAILED_INTERRUPTED = SPELL_FAILED_INTERRUPTED

ZPerl.SetModuleRevision("$Revision:  $")

---@diagnostic disable: create-global
ZPERL_RAIDMON_UNIT_WIDTH_MIN = 50
ZPERL_RAIDMON_UNIT_WIDTH_MAX = 150
ZPERL_RAIDMON_UNIT_HEIGHT_MIN = 9
ZPERL_RAIDMON_UNIT_HEIGHT_MAX = 20
ZPERL_RAIDMON_TARGET_WIDTH_MIN = 50
ZPERL_RAIDMON_TARGET_WIDTH_MAX = 150
---@diagnostic enable: create-global

local castColors = {
	main    = {r = 1.0, g = 0.7, b = 0.0},
	channel = {r = 0.0, g = 1.0, b = 0.0},
	success = {r = 0.0, g = 1.0, b = 0.0},
	failure = {r = 1.0, g = 0.0, b = 0.0}
}

-- ZPerl.RaidMonitor.OnLoad
function ZPerl.RaidMonitor.OnLoad(self)
	cast = self
	ZPerl.RaidMonitor.Init(self)

	--self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:SetScript("OnEvent", ZPerl.RaidMonitor.OnEvent)
	self:SetScript("OnUpdate", self.OnUpdate)

	if (ZPerl.RegisterPerlFrames) then
		ZPerl.RegisterPerlFrames(ZPerl_RaidMonitor_Frame)
	end

	ZPerl.RegisterScalableFrame(self, ZPerl_RaidMonitor_Anchor)

	ZPerl.RaidMonitor.OnLoad = nil
end

-- ScaleBarColor
local function ScaleBarColor(self, perc, cOrder)
	if (not cOrder) then
		cOrder = "rgb"
	end

	local c = {0, 0, 0}
	if (perc < 0.5) then
		c[strfind(cOrder, "r")] = 1
		c[strfind(cOrder, "g")] = 2 * perc
		c[strfind(cOrder, "b")] = 0
	else
		c[strfind(cOrder, "r")] = 2 * (1 - perc)
		c[strfind(cOrder, "g")] = 1
		c[strfind(cOrder, "b")] = 0
	end

	self:SetStatusBarColor(unpack(c))
	self.bg:SetVertexColor(c[1], c[2], c[3], 0.5)
end

-- CastBar_OnUpdate
local function CastBar_OnUpdate(self)
	if (self.casting) then
		local status = GetTime()
		if (status > self.maxValue) then
			self.castBar:SetStatusBarColor(castColors.success.r, castColors.success.g, castColors.success.b)
			self.casting = nil

			status = self.maxValue
			self.castBar:SetValue(status)

			self.fadeOut = 1
			return
		end
		self.castBar:SetValue(status)

		local sparkPosition = ((status - self.startTime) / (self.maxValue - self.startTime)) * self.castBar:GetWidth()
		if ( sparkPosition < 0 ) then
			sparkPosition = 0
		end
		self.castBar.spark:SetPoint("CENTER", self.castBar, "LEFT", sparkPosition, 1)

	elseif (self.channeling) then
		local time = GetTime()
		if (time >= self.endTime) then
			self.channeling = nil

			self.holdTime = 0
			self.fadeOut = 1
			return
		end
		local barValue = self.startTime + (self.endTime - time)
		self.castBar:SetValue( barValue )

		local sparkPosition = ((barValue - self.startTime) / (self.endTime - self.startTime)) * self.castBar:GetWidth()
		self.castBar.spark:SetPoint("CENTER", self.castBar, "LEFT", sparkPosition, 1)

	elseif (self.fadeOut) then
		local alpha = self.castBar:GetAlpha() - (_G.CASTING_BAR_ALPHA_STEP or 0.02)
		if (alpha > 0) then
			self.castBar:SetAlpha(alpha)
			self.bar.name:SetAlpha(1 - alpha)
			self.bar.name:Show()
		else
			self.bar.name:SetAlpha(1)
			self.bar.name:Show()
			self.fadeOut = nil
			self.castBar:Hide()
		end
	end
end

-- UpdateTarget
local function UpdateTarget(self)
	local id = SecureButton_GetUnit(self)
	if (id) then
		local subid = strmatch(id, "^(raid%d+)")
		if (ZPerl.SafeBool(UnitIsUnit("player", subid), false)) then
			id = "target"
		end

		local name, reason
		if (not UnitIsConnected(subid)) then
			reason = L["LOC_OFFLINE"]
		elseif (UnitIsDead(subid)) then
			reason = L["LOC_DEAD"]
		elseif (UnitIsGhost(subid)) then
			reason = L["LOC_GHOST"]
		elseif (not UnitIsVisible(subid)) then
			reason = L["LOC_OOR"]
		else
			name = UnitName(id)
			if (not name) then
				reason = L["NO_TARGET"]
			end
		end

		if (not name) then
			self.statusBar.name:SetText(reason)
			self.statusBar.name:SetTextColor(0.5, 0.5, 0.5)

			self.statusBar:SetMinMaxValues(0, 1)
			self.statusBar:SetValue(0)
			self.statusBar:SetStatusBarColor(0, 0, 0)
			self.statusBar.bg:SetVertexColor(0, 0, 0, 0.5)
		else
			self.statusBar.name:SetText(name)
			if (ZPerl.SafeBool(UnitIsUnit("target", id), false)) then
				self.statusBar.name:SetTextColor(0, 1, 0)
			else
				self.statusBar.name:SetTextColor(0.5, 0.5, 0.5)
			end

			-- secret health goes straight into the bar
			local hp, hpMax = UnitHealth(id), UnitHealthMax(id)
			if (ZPerl.CanAccess(hp)) then
				hp = UnitIsGhost(id) and 1 or (UnitIsDead(id) and 0 or hp)
			end
			self.statusBar:SetMinMaxValues(0, hpMax)
			self.statusBar:SetValue(hp)

			local _, class = UnitClass(id)
			if (class and ZPerl.CanAccess(class)) then
				---@diagnostic disable-next-line: secret-table-key
				local c = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
				if (c) then
					self.statusBar:SetStatusBarColor(c.r, c.g, c.b)
					self.statusBar.bg:SetVertexColor(c.r, c.g, c.b, 0.5)
				end
			end
		end
	end
end

-- UpdateUnit
local function UpdateUnit(self)
	local id = SecureButton_GetUnit(self)
	if (id) then
		-- full "First Last" (or "First-Realm") display name
		self.bar.name:SetText(ZPerl.UnitFullName(id))

		self.powerType = UnitPowerType(id)
		self.mana, self.manaMax = UnitPower(id), UnitPowerMax(id)
		self.bar:SetMinMaxValues(0, self.manaMax)
		self.bar:SetValue(self.mana)

		if (UnitInParty(id)) then
			self.groupedIcon:Show()
		else
			self.groupedIcon:Hide()
		end

		if (not UnitIsConnected(id) or UnitIsDeadOrGhost(id) or not UnitIsVisible(id)) then
			self.bar:SetStatusBarColor(0.5, 0.5, 0.5)
			self.bar.bg:SetVertexColor(0.5, 0.5, 0.5, 0.5)
		elseif (ZPerl.CanAccess(self.mana) and ZPerl.CanAccess(self.manaMax) and self.manaMax > 0) then
			ScaleBarColor(self.bar, self.mana / self.manaMax, "rbg")
		else
			-- secret power cannot be graded, use the mana color
			self.bar:SetStatusBarColor(0, 0, 1)
			self.bar.bg:SetVertexColor(0, 0, 1, 0.5)
		end

		local _, class = UnitClass(id)
		if (class and ZPerl.CanAccess(class)) then
			---@diagnostic disable-next-line: secret-table-key
			local c = (_G.CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
			if (c) then
				self.bar.name:SetTextColor(c.r, c.g, c.b)
			end
		end

		UpdateTarget(self.target)
	end
end

-- UpdateAllUnits()
local function UpdateAllUnits()
	for k, v in pairs(MonUnits) do
		UpdateUnit(v)
	end
end

-- SetTableUnit(value, self)
local function SetTableUnit(value, self)
	for k, v in pairs(TableUnits) do
		if (v == self) then
			TableUnits[k] = nil
			break
		end
	end

	TableUnits[value] = self
end

-- onAttrChanged
local function onAttrChanged(self, name, value)
	if (name == "unit") then
		if (value) then
			SetTableUnit(value, self)
			UpdateUnit(self)
		end
	end
end

-- ZPerl.RaidHelper.MTListChildUnits
function ZPerl.RaidMonitor.CastMonChildUnits(self)
	self.mana, self.manaMax = 1, 1

	self:SetScript("OnShow", UpdateUnit)
	ZPerl.RegisterHighlight(self, 3)
	ZPerl.RegisterClickCastFrame(self)
	ZPerl.RegisterClickCastFrame(self.target)

	self:SetScript("OnAttributeChanged", onAttrChanged)

	local _, class = UnitClass("player")
	if (class == "DRUID") then
		self:SetAttribute("type2", "spell")
		self:SetAttribute("spell2", L["MONITOR_INNERVATE"])
	elseif (class == "SHAMAN") then
		self:SetAttribute("type2", "spell")
		self:SetAttribute("spell2", L["MONITOR_MANATIDE"])
	end

	self.target:SetWidth(config.TargetWidth)
	self.target:SetHeight(config.UnitHeight)

	tinsert(MonUnits, self)
end

-- cast:OnEvent
function ZPerl.RaidMonitor.OnEvent(self, event, ...)
	local e = self[event]
	if (e) then
		e(self, ...)
	end
end

-- ZPerl.RaidMonitor.MonitorMakeAction
function ZPerl.RaidMonitor.MonitorMakeAction(self, str, type)
	if (str == "target") then
		return L["MONITOR_CLICKTARGET"]
	elseif (str == "spell") then
		local b
		if (type == 1) then
			b = "LeftButton"
		else
			b = "RightButton"
		end
		local spell = SecureButton_GetModifiedAttribute(self, "spell", b)
		if (spell) then
			return string.format(L["MONITOR_CLICKCAST"], spell)
		end
	end
end

-- ZPerl.RaidMonitor.Init
function ZPerl.RaidMonitor.Init(monitor)
	monitor.updateTimer = 0

	-- cast:DoButtons
	function cast:DoButtons(disable)
		if (disable or InCombatLockdown()) then
			self.Buttons.Totals:Disable()
			self.Buttons.Close:Disable()
			self.corner:EnableMouse(false)
		else
			self.Buttons.Totals:Enable()
			self.Buttons.Close:Enable()
			self.corner:EnableMouse(true)
		end

		self.Buttons.Pin:SetButtonTex()
		self.Buttons.Totals:SetButtonTex()
	end

	-- cast:GROUP_ROSTER_UPDATE
	function cast:GROUP_ROSTER_UPDATE()
		self:SetFrameSizes()

		if self:IsShown() then
			UpdateAllUnits()
		end

		if self:IsShown() and config.Totals then
			if (not self.doneHealth) then
				self:HealthTotals()
			end

			if (not self.doneMana) then
				self:ManaTotals()
			end
		end
	end

	-- cast:ManaTotals
	function cast:ManaTotals()
		self.doneMana = true

		local manaTotal, count, manaHigh, manaLow, allTotal = 0, 0, 0, 0, 0
		for i = 1, GetNumGroupMembers() do
			local v = self.area:GetAttribute("child"..i)
			if (not v) then
				break
			end
			if (v.powerType == 0 and v:IsShown()) then
				local unit = v:GetAttribute("unit")
				-- secret power is left out of the totals
				if (UnitIsConnected(unit) and not ZPerl.SafeBool(UnitIsDeadOrGhost(unit), false) and ZPerl.CanAccess(v.mana) and ZPerl.CanAccess(v.manaMax)) then
					local perc
					if (v.manaMax == 0) then
						perc = 0
					else
						perc = 100 / v.manaMax * v.mana
					end

					if (perc >= config.HighMana) then
						manaHigh = manaHigh + 1
					end

					if (perc <= config.LowMana) then
						manaLow = manaLow + 1
					end

					manaTotal = manaTotal + perc
					count = count + 1
				end
			end
			allTotal = allTotal + 1
		end

		if (count == 0) then
			manaHigh = 0
			manaLow = 0
			manaTotal = 100
			count = 1
		end

		manaTotal = manaTotal / count

		local st = self.totals
		st.RaidMana:SetValue(manaTotal)
		st.HighMana:SetMinMaxValues(0, count)
		st.HighMana:SetValue(manaHigh)
		st.LowMana:SetMinMaxValues(0, count)
		st.LowMana:SetValue(manaLow)

		st.RaidMana.name:SetFormattedText("%d%%", manaTotal)
		st.HighMana.name:SetText(manaHigh)
		st.LowMana.name:SetText(manaLow)

		ScaleBarColor(st.RaidMana, manaTotal / 100, "rbg")
		ScaleBarColor(st.HighMana, manaHigh / count, "rbg")
		ScaleBarColor(st.LowMana, 1 - (manaLow / count), "rbg")
	end

	-- cast:HealthTotals()
	function cast:HealthTotals()
		self.doneHealth = true

		local totalHealth = 0
		local total = 0
		if IsInRaid() then--actually check if we are in a raid
			for i = 1, GetNumGroupMembers() do
				local id = "raid"..i
				-- units with secret health are left out of the total
				if (UnitIsConnected(id) and ZPerl.CanAccess(UnitHealth(id)) and ZPerl.CanAccess(UnitHealthMax(id))) then
					local hp, hpMax = UnitIsGhost(id) and 1 or (UnitIsDead(id) and 0 or UnitHealth(id)), UnitHealthMax(id)
					--Begin 4.3 anti /0 fix.
					local percent
					---@diagnostic disable-next-line: secret-comparison
					if UnitIsDeadOrGhost(id) or (hp == 0 and hpMax == 0) then--They are dead
						percent = 0
					---@diagnostic disable-next-line: secret-comparison
					elseif hp > 0 and hpMax == 0 then --They have more then 1 HP so they have to be alive, so we need to fix hpmax being wrong.
						hpMax = hp --Make max hp equal to current HP
						percent = 1
					else
						---@diagnostic disable-next-line: secret-arithmetic
						percent = hp / hpMax
					end
					--end /0 fix.
					totalHealth = totalHealth + (100 * percent)
					total = total + 1
				end
			end
		elseif GetNumSubgroupMembers() > 0 then--if not a raid see if it's a party
			for i = 1, GetNumSubgroupMembers() do
				local id = "party"..i
				if (UnitIsConnected(id) and ZPerl.CanAccess(UnitHealth(id)) and ZPerl.CanAccess(UnitHealthMax(id))) then
					local hp, hpMax = UnitIsGhost(id) and 1 or (UnitIsDead(id) and 0 or UnitHealth(id)), UnitHealthMax(id)
					--Begin 4.3 anti /0 fix.
					local percent
					---@diagnostic disable-next-line: secret-comparison
					if UnitIsDeadOrGhost(id) or (hp == 0 and hpMax == 0) then--They are dead
						percent = 0
					---@diagnostic disable-next-line: secret-comparison
					elseif hp > 0 and hpMax == 0 then --They have more then 1 HP so they have to be alive, so we need to fix hpmax being wrong.
						hpMax = hp --Make max hp equal to current HP
						percent = 1
					else
						---@diagnostic disable-next-line: secret-arithmetic
						percent = hp / hpMax
					end
					--end /0 fix.
					totalHealth = totalHealth + (100 * percent)
					total = total + 1
				end
			end
			--GetNumSubgroupMembers() doesn't return player, unlike GetNumGroupMembers which does, so we have to manually add player in for 5 mans
			local hp, hpMax = UnitHealth("player"), UnitHealthMax("player")
			if (ZPerl.CanAccess(hp) and ZPerl.CanAccess(hpMax)) then
				hp = UnitIsGhost("player") and 1 or (UnitIsDead("player") and 0 or hp)
				--Begin 4.3 anti /0 fix.
				local percent
				---@diagnostic disable-next-line: secret-comparison
				if UnitIsDeadOrGhost("player") or (hp == 0 and hpMax == 0) then--They are dead
					percent = 0
				---@diagnostic disable-next-line: secret-comparison
				elseif hp > 0 and hpMax == 0 then --They have more then 1 HP so they have to be alive, so we need to fix hpmax being wrong.
					hpMax = hp --Make max hp equal to current HP
					percent = 1
				else
					---@diagnostic disable-next-line: secret-arithmetic
					percent = hp / hpMax
				end
				--end /0 fix.
				totalHealth = totalHealth + (100 * percent)
				total = total + 1
			end
		end
		if totalHealth ~= 0 and total ~= 0 then--Make sure neither is 0, if they are don't bother division, no one is alive.
			totalHealth = totalHealth / total
		end

		self.totals.RaidHealth:SetValue(totalHealth)
		self.totals.RaidHealth.name:SetFormattedText("%d%%", totalHealth)
		if totalHealth ~= 0 then
			ScaleBarColor(self.totals.RaidHealth, totalHealth / 100)
		else--don't divide 0 by 100, if total health is 0 then that's all we need to put in.
			ScaleBarColor(self.totals.RaidHealth, 0)
		end
	end

	-- cast:UNIT_MANA
	function cast:UNIT_MANA(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local u = TableUnits[unit]
		if (u) then
			local id = SecureButton_GetUnit(u)
			if (id) then
				u.powerType = UnitPowerType(id)
				u.mana, u.manaMax = UnitPower(id), UnitPowerMax(id)
				u.bar:SetMinMaxValues(0, u.manaMax)
				u.bar:SetValue(u.mana)
				if (ZPerl.CanAccess(u.mana) and ZPerl.CanAccess(u.manaMax) and u.manaMax > 0) then
					ScaleBarColor(u.bar, u.mana / u.manaMax, "rbg")
				end
				self.doneMana = false

				if (self.lastManaUpdate or 0) >= GetTime() then
					return
				end

				if config.Totals and self:IsShown() then
					self:ManaTotals()
					self.lastManaUpdate = GetTime()
				end
			end
		end
	end

	-- cast:UNIT_POWER_FREQUENT
	function cast:UNIT_POWER_FREQUENT(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local u = TableUnits[unit]
		if (u) then
			local id = SecureButton_GetUnit(u)
			if (id) then
				u.powerType = UnitPowerType(id)
				u.mana, u.manaMax = UnitPower(id), UnitPowerMax(id)
				u.bar:SetMinMaxValues(0, u.manaMax)
				u.bar:SetValue(u.mana)
				if (ZPerl.CanAccess(u.mana) and ZPerl.CanAccess(u.manaMax) and u.manaMax > 0) then
					ScaleBarColor(u.bar, u.mana / u.manaMax, "rbg")
				end
				self.doneMana = false

				if (self.lastManaUpdate or 0) >= GetTime() then
					return
				end

				if config.Totals and self:IsShown() then
					self:ManaTotals()
					self.lastManaUpdate = GetTime()
				end
			end
		end
	end

	-- cast:UNIT_MAXPOWER
	function cast:UNIT_MAXPOWER(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local u = TableUnits[unit]
		if (u) then
			local id = SecureButton_GetUnit(u)
			if (id) then
				u.powerType = UnitPowerType(id)
				u.mana, u.manaMax = UnitPower(id), UnitPowerMax(id)
				u.bar:SetMinMaxValues(0, u.manaMax)
				u.bar:SetValue(u.mana)
				if (ZPerl.CanAccess(u.mana) and ZPerl.CanAccess(u.manaMax) and u.manaMax > 0) then
					ScaleBarColor(u.bar, u.mana / u.manaMax, "rbg")
				end
				self.doneMana = false

				if (self.lastManaUpdate or 0) >= GetTime() then
					return
				end

				if config.Totals and self:IsShown() then
					self:ManaTotals()
					self.lastManaUpdate = GetTime()
				end
			end
		end
	end


	-- cast:PLAYER_REGEN_DISABLED
	function cast:PLAYER_REGEN_DISABLED()
		self:DoButtons(true)
	end

	-- cast:PLAYER_REGEN_ENABLED
	function cast:PLAYER_REGEN_ENABLED()
		self:DoButtons()
	end

	-- cast:PLAYER_ENTERING_WORLD
	function cast:PLAYER_ENTERING_WORLD()
		ZPerl.MigrateSavedNames("ZPerl_RaidMonitor")
		config = ZPerlRaidMonitorDB
		self:Vars()
		self:DoButtons()
		self:SetupAlpha()

		self.area:UnregisterEvent("UNIT_NAME_UPDATE")	-- Fix for WoW 2.1 UNIT_NAME_UPDATE issue

		self.area = _G[self:GetName().."Area"]

		if (config.GrowUp) then
			self.area:SetAttribute("point", "BOTTOM")
		else
			self.area:SetAttribute("point", nil)
		end

		self.area:SetAttribute("template", "ZPerl_RaidMonitor_UnitTemplate")
		self.area:SetAttribute("templateType", "Button")
		self.area:SetAttribute("sortMethod", "NAME")
		self.area:SetAttribute("sortDir", "ASC")
		self.area:SetAttribute("groupBy", "CLASS")		-- For API version 20003
		self.area:SetAttribute("groupingOrder", "PRIEST,DRUID,SHAMAN,PALADIN,MONK,EVOKER,MAGE,WARLOCK,HUNTER,ROGUE,WARRIOR,DEATHKNIGHT,DEMONHUNTER")

		self:SetAttribute("type", "target")
		self:SetAttribute("initial-height", config.UnitHeight)
		self:SetAttribute("initial-width", config.UnitWidth)

		local classes = {}
		for k, v in pairs(config.classes) do
			if (v) then
				tinsert(classes, k)
			end
		end

		self.area:SetAttribute("groupFilter", table.concat(classes, ","))

		if (config.enabled == 1) then
			self:Show()
			self.area:Show()
			self:SetFrameSizes()
		else
			self:Hide()
		end

		-- Fix Secure Header taint in combat
		local maxColumns = self.area:GetAttribute("maxColumns") or 1
		local unitsPerColumn = self.area:GetAttribute("unitsPerColumn") or 40
		local startingIndex = self.area:GetAttribute("startingIndex") or 1
		local maxUnits = maxColumns * unitsPerColumn

		self.area:Show()
		self.area:SetAttribute("startingIndex", - maxUnits + 1)
		self.area:SetAttribute("startingIndex", startingIndex)

		self:SetFrameSizes()

		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end

	-- cast:UNIT_SPELLCAST_START
	function cast:UNIT_SPELLCAST_START(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar:IsShown()) then
			local name, _, texture, startTime, endTime = UnitCastingInfo(unit)
			---@diagnostic disable-next-line: secret-comparison
			if name == nil or not ZPerl.CanAccess(startTime) or not ZPerl.CanAccess(endTime) or startTime >= endTime then
				return
			end
			bar.castBar.name:SetText(name)
			bar.castBar.icon:SetTexture(texture)
			bar.castBar.spark:Show()
			bar.bar.name:Hide()
			---@diagnostic disable-next-line: secret-arithmetic
			bar.startTime = startTime / 1000
			---@diagnostic disable-next-line: secret-arithmetic
			bar.maxValue = endTime / 1000
			bar.castBar:SetStatusBarColor(castColors.main.r, castColors.main.g, castColors.main.b)
			bar.castBar:SetMinMaxValues(bar.startTime, bar.maxValue)
			bar.castBar:SetValue(bar.startTime)
			bar.castBar:Show()
			bar.castBar:SetAlpha(1)
			bar.holdTime = 0
			bar.casting = true
			bar.channeling = nil
			bar.fadeOut = nil
		end
	end

	-- cast:UNIT_SPELLCAST_STOP
	function cast:UNIT_SPELLCAST_STOP(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar.casting and bar:IsShown()) then
			--bar.bar:SetValue(bar.maxValue)
			--bar.bar:SetStatusBarColor(castColors.success.r, castColors.success.g, castColors.success.b)
			bar.castBar.spark:Hide()
			bar.casting = nil
			bar.channeling = nil
			bar.fadeOut = true
		end
	end

	-- cast:UNIT_SPELLCAST_FAILED
	function cast:UNIT_SPELLCAST_FAILED(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar.casting and bar:IsShown()) then
			bar.castBar.name:SetText(FAILED)
			bar.castBar:SetValue(bar.maxValue or 1)
			bar.castBar:SetStatusBarColor(castColors.failure.r, castColors.failure.g, castColors.failure.b)
			bar.castBar.spark:Hide()
			bar.casting = nil
			bar.channeling = nil
			bar.fadeOut = true
		end
	end

	-- cast:UNIT_SPELLCAST_INTERRUPTED
	function cast:UNIT_SPELLCAST_INTERRUPTED(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar.casting and bar:IsShown()) then
			bar.castBar.name:SetText(SPELL_FAILED_INTERRUPTED)
			bar.castBar:SetValue(bar.maxValue or 1)
			bar.castBar:SetStatusBarColor(castColors.failure.r, castColors.failure.g, castColors.failure.b)
			bar.castBar.spark:Hide()
			bar.casting = nil
			bar.channeling = nil
			bar.fadeOut = true
		end
	end

	-- cast:UNIT_SPELLCAST_SUCCEEDED
	function cast:UNIT_SPELLCAST_SUCCEEDED(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar.casting and bar:IsShown()) then
			bar.castBar:SetValue(bar.maxValue or 1)
			bar.castBar:SetStatusBarColor(castColors.success.r, castColors.success.g, castColors.success.b)
			bar.casting = nil
			bar.channeling = nil
			bar.fadeOut = true
			bar.castBar:SetAlpha(1)
		end
	end

	-- cast:UNIT_SPELLCAST_DELAYED
	function cast:UNIT_SPELLCAST_DELAYED(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar.casting and bar:IsShown()) then
			local name, _, _, startTime, endTime = UnitCastingInfo(unit)
			---@diagnostic disable-next-line: secret-comparison
			if name == nil or not ZPerl.CanAccess(startTime) or not ZPerl.CanAccess(endTime) or startTime >= endTime then
				return
			end
			---@diagnostic disable-next-line: secret-arithmetic
			bar.startTime = startTime / 1000
			---@diagnostic disable-next-line: secret-arithmetic
			bar.maxValue = endTime / 1000
			bar.castBar:SetMinMaxValues(bar.startTime, bar.maxValue)
		end
	end

	-- cast:UNIT_SPELLCAST_CHANNEL_START
	function cast:UNIT_SPELLCAST_CHANNEL_START(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar:IsShown()) then
			local name, _, texture, startTime, endTime = UnitChannelInfo(unit)
			---@diagnostic disable-next-line: secret-comparison
			if name == nil or not ZPerl.CanAccess(startTime) or not ZPerl.CanAccess(endTime) or startTime >= endTime then
				return
			end
			bar.castBar:SetStatusBarColor(castColors.channel.r, castColors.channel.g, castColors.channel.b)
			bar.castBar.name:SetText(name)
			bar.castBar.spark:Show()
			bar.bar.name:Hide()
			bar.castBar.icon:SetTexture(texture)
			bar.maxValue = 1
			---@diagnostic disable-next-line: secret-arithmetic
			bar.startTime = startTime / 1000
			---@diagnostic disable-next-line: secret-arithmetic
			bar.endTime = endTime / 1000
			bar.castBar:SetMinMaxValues(bar.startTime, bar.endTime)
			bar.castBar:SetValue(bar.endTime)
			bar.casting = nil
			bar.fadeOut = nil
			bar.channeling = true
			bar.castBar:Show()
			bar.castBar:SetAlpha(1)
		end
	end

	-- cast:UNIT_SPELLCAST_CHANNEL_UPDATE
	function cast:UNIT_SPELLCAST_CHANNEL_UPDATE(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar.channeling and bar:IsShown()) then
			local name, _, _, startTime, endTime = UnitChannelInfo(unit)
			---@diagnostic disable-next-line: secret-comparison
			if name == nil or not ZPerl.CanAccess(startTime) or not ZPerl.CanAccess(endTime) or startTime >= endTime then
				return
			end
			---@diagnostic disable-next-line: secret-arithmetic
			bar.startTime = startTime / 1000
			---@diagnostic disable-next-line: secret-arithmetic
			bar.endTime = endTime / 1000
			bar.maxValue = bar.startTime
			bar.castBar:SetMinMaxValues(bar.startTime, bar.endTime)
		end
	end

	-- cast:UNIT_SPELLCAST_CHANNEL_STOP
	function cast:UNIT_SPELLCAST_CHANNEL_STOP(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar.channeling and bar:IsShown()) then
			bar.castBar:SetValue(bar.maxValue)
			bar.castBar:SetStatusBarColor(castColors.success.r, castColors.success.g, castColors.success.b)
			bar.castBar.spark:Hide()
			bar.casting = nil
			bar.channeling = nil
			bar.fadeOut = true
		end
	end

	-- cast:UNIT_TARGET
	function cast:UNIT_TARGET(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end
		local bar = TableUnits[unit]
		if (bar and bar:IsShown()) then
			UpdateTarget(bar.target)
		end
	end

	-- cast:PLAYER_TARGET_CHANGED
	function cast:PLAYER_TARGET_CHANGED()
		self:OnUpdate(1)
	end

	-- cast:UNIT_HEALTH
	function cast:UNIT_HEALTH(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end

		self.doneHealth = nil
		local bar = self:GetTarget(unit)
		if (bar and bar:IsShown()) then
			UpdateTarget(bar)
		end

		if (self.lastHealthUpdate or 0) >= GetTime() then
			return
		end

		if config.Totals and self:IsShown() then
			self:HealthTotals()
			self.lastHealthUpdate = GetTime()
		end
	end

	-- cast:UNIT_MAXHEALTH
	function cast:UNIT_MAXHEALTH(unit)
		if not unit or not strfind(unit, "^raid%d+$") then
			return
		end

		self.doneHealth = nil
		local bar = self:GetTarget(unit)
		if (bar and bar:IsShown()) then
			UpdateTarget(bar)
		end

		if (self.lastHealthUpdate or 0) >= GetTime() then
			return
		end

		if config.Totals and self:IsShown() then
			self:HealthTotals()
			self.lastHealthUpdate = GetTime()
		end
	end

	-- cast:OnUpdate
	function cast:OnUpdate(elapsed)
		for k, v in pairs(MonUnits) do
			CastBar_OnUpdate(v)
		end

		self.updateTimer = self.updateTimer + elapsed
		if (self.updateTimer > 1) then
			self.updateTimer = 0
			for k, v in pairs(MonUnits) do
				UpdateTarget(v.target)
			end
		end

	end

	-- cast:Vars
	function cast:Vars()

		local function DefaultVar(name, value)
			if (config[name] == nil or (type(value) ~= type(config[name]))) then
				config[name] = value
			end
		end

		if (type(config.classes) ~= "table") then
			config.classes = {PRIEST = true, DRUID = true, SHAMAN = true, PALADIN = true}
		end
		-- the healer classes newer than Classic, on the clients that have them (nil: never set)
		for _, class in ipairs({"MONK", "EVOKER"}) do
			if (config.classes[class] == nil and LOCALIZED_CLASS_NAMES_MALE[class]) then
				config.classes[class] = true
			end
		end

		DefaultVar("UnitWidth", 120)
		DefaultVar("UnitHeight", 12)
		DefaultVar("TargetWidth", 80)

		DefaultVar("LowMana", 20)
		DefaultVar("HighMana", 80)

		DefaultVar("Tooltips", 1)
		DefaultVar("Scale", 1)
		DefaultVar("Alpha", 1)
		DefaultVar("BackgroundAlpha", 0.8)
	end


	-- cast:Init
	function cast:Init()
		self:PLAYER_ENTERING_WORLD()
	end

	-- cast:GetTarget
	function cast:GetTarget(unit)
		for k, v in pairs(MonUnits) do
			local id = v:GetAttribute("unit")
			if (id and ZPerl.SafeBool(UnitIsUnit(id.."target", unit), false)) then
				return v.target
			end
		end
	end

	-- cast:SetUnitSizes
	function cast:SetUnitSizes()
		if (InCombatLockdown()) then
			ZPerl.AfterCombat(cast.SetUnitSizes, self)
			return
		end

		local unitWidth = config.UnitWidth
		local unitHeight = config.UnitHeight
		local targetWidth = config.TargetWidth

		self.area:SetWidth(unitWidth)

		for k, v in pairs(MonUnits) do
			v:SetWidth(unitWidth)
			v:SetHeight(unitHeight)
			v.target:SetWidth(targetWidth)
			v.target:SetHeight(unitHeight)
		end
	end

	-- cast:EnableDisable()
	function cast:EnableDisable()
		local events = {
			"UNIT_POWER_FREQUENT",
			"UNIT_MAXPOWER",
			"UNIT_MANA",
			ZPerl.ForeverAPI.healthEvent,
			"UNIT_MAXHEALTH",
			"UNIT_TARGET",
			"UNIT_SPELLCAST_START",
			"UNIT_SPELLCAST_STOP",
			"UNIT_SPELLCAST_FAILED",
			"UNIT_SPELLCAST_INTERRUPTED",
			"UNIT_SPELLCAST_DELAYED",
			"UNIT_SPELLCAST_CHANNEL_START",
			"UNIT_SPELLCAST_SUCCEEDED",
			"UNIT_SPELLCAST_CHANNEL_UPDATE",
			"UNIT_SPELLCAST_CHANNEL_STOP",
			"PLAYER_TARGET_CHANGED",
			"PLAYER_REGEN_ENABLED",
			"PLAYER_REGEN_DISABLED",
		}

		for k, v in pairs(events) do
			-- never error on an event this client does not have
			if (self:IsShown()) then
				ZPerl.RegisterEventSafe(self, v)
			else
				ZPerl.UnregisterEventSafe(self, v)
			end
		end
	end

	-- cast:SetupAlpha
	function cast:SetupAlpha()
		self:SetAlpha(config.Alpha)
		self:OnBackdropLoaded()
		self:SetBackdropColor(0, 0, 0, config.BackgroundAlpha)
		self:SetBackdropBorderColor(0.5, 0.5, 0.5, config.BackgroundAlpha)
	end

	-- cast:SetFrameSizes
	function cast:SetFrameSizes()
		if (InCombatLockdown()) then
			ZPerl.AfterCombat(cast.SetFrameSizes, self)
			return
		end

		local count = 0
		for i = 1, GetNumGroupMembers() do
			local _, class = UnitClass("raid"..i)
			---@diagnostic disable-next-line: secret-table-key
			if (ZPerl.CanAccess(class) and config.classes[class]) then
				count = count + 1
			end
		end

		self.area:SetHeight(config.UnitHeight * count)
		self:SetWidth(config.UnitWidth + config.TargetWidth + 8)

		local h = config.UnitHeight * count + 20
		if (config.Totals) then
			self:SetHeight(h + 52)
			self.totals:Show()
		else
			self:SetHeight(h)
			self.totals:Hide()
		end

		ZPerl.RegisterScalableFrame(self, ZPerl_RaidMonitor_Anchor, nil, nil, config.GrowUp)

		self:ClearAllPoints()
		self.area:ClearAllPoints()
		self.titleBar:ClearAllPoints()
		self.totals:ClearAllPoints()
		self.totals.sep:ClearAllPoints()
		if (config.GrowUp) then
			ZPerl.SwitchAnchor(ZPerl_RaidMonitor_Anchor, "BOTTOMLEFT")
			self:SetPoint("BOTTOMLEFT", 0, 0)
			self.titleBar:SetPoint("BOTTOMLEFT", 3, 3)
			self.titleBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -3, 13)
			self.area:SetPoint("BOTTOMLEFT", 4, 15)
			self.totals:SetPoint("BOTTOMLEFT", self.area, "TOPLEFT", 0, 6)
			self.totals:SetPoint("TOPRIGHT", -4, -4)
			self.totals.sep:SetPoint("TOPLEFT", self.totals, "BOTTOMLEFT", 0, -1)
			self.totals.sep:SetPoint("BOTTOMRIGHT", self.totals, "BOTTOMRIGHT", 0, -5)
		else
			ZPerl.SwitchAnchor(ZPerl_RaidMonitor_Anchor, "TOPLEFT")
			self:SetPoint("TOPLEFT", 0, 0)
			self.titleBar:SetPoint("TOPLEFT", 3, -3)
			self.titleBar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -3, -13)
			self.area:SetPoint("TOPLEFT", 4, -15)
			self.totals:SetPoint("TOPLEFT", self.area, "BOTTOMLEFT", 0, -6)
			self.totals:SetPoint("BOTTOMRIGHT", -4, 4)
			self.totals.sep:SetPoint("BOTTOMLEFT", self.totals, "TOPLEFT", 0, 1)
			self.totals.sep:SetPoint("TOPRIGHT", self.totals, "TOPRIGHT", 0, 5)
		end

		if (count > 0 and config.enabled == 1) then
			if (not self:IsShown()) then
				self.doneHealth = nil
				self:Show()
			end
			self.area:Show()
		else
			self:Hide()
		end

		if self:IsShown() and config.Totals then
			if (not self.doneHealth) then
				self:HealthTotals()
			end

			if (not self.doneMana) then
				self:ManaTotals()
			end
		end

		self:EnableDisable()
	end


	ZPerl.RaidMonitor.Init = nil
end
