-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local init_done, gradient, conf, doneOptions
local errorCount = 0
ZPerl.RequestConfig(function(new)
	conf = new
end, "$Revision:  $")

-- Upvalues
local error = error
local format = format
local geterrorhandler = geterrorhandler
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local max = max
local min = min
local pairs = pairs
local pcall = pcall
local sort = sort
local tinsert = tinsert
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe

local CreateColor = CreateColor
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local IsAltKeyDown = IsAltKeyDown
local IsInRaid = IsInRaid
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid

local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE

local GameFontNormal = GameFontNormal
local GameFontNormalSmall = GameFontNormalSmall
local GameTooltip = GameTooltip
local WorldFrame = WorldFrame

local classOrder = {"WARRIOR", "ROGUE", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "PRIEST", "MAGE", "WARLOCK"}
-- the classes newer than Classic, on the clients that have them
for _, class in ipairs({"DEATHKNIGHT", "MONK", "DEMONHUNTER", "EVOKER"}) do
	if (LOCALIZED_CLASS_NAMES_MALE[class]) then
		tinsert(classOrder, class)
	end
end

-- SetTexCreateColor
local highlightPositions = {
	{0, 0.25, 0, 0.5},
	{0.25, 0.75, 0, 0.5},
	{0, 1, 0.5, 1},
	{0.75, 1, 0, 0.5}
}

local function SetTex(self, num)
	local p = highlightPositions[num]
	if ((self.GetFrameType or self.GetObjectType)(self) == "Button") then
		if (conf.highlightSelection == 1) then
			self:SetHighlightTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_Highlight", "ADD")
			local tex = self:GetHighlightTexture()
			tex:SetTexCoord(unpack(p))
			tex:SetVertexColor(0.86, 0.82, 0.41)
		else
			self:SetHighlightTexture("")
		end

	elseif ((self.GetFrameType or self.GetObjectType)(self) == "Frame") then
		if (self.tex) then
			-- SetTexture's second argument is a wrap mode, not a blend mode
			self.tex:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_Highlight")
			self.tex:SetBlendMode("ADD")
			self.tex:SetTexCoord(unpack(p))
			self.tex:SetVertexColor(0.86, 0.82, 0.41)
			if ZPerl_Highlight then
				ZPerl_Highlight:SetHighlight(self:GetParent())
			end
		end
	end
end

-- RegisterHighlight
local HighlightFrames = { }
function ZPerl.RegisterHighlight(frame, ratio)
	HighlightFrames[frame] = ratio
	if (init_done) then
		SetTex(frame, ratio)
	end
end

-- ZPerl.SetHighlights
function ZPerl.SetHighlights()
	for k, v in pairs(HighlightFrames) do
		SetTex(k, v)
	end
end

-- ZPerl_MakeGradient(self)
function ZPerl.DoGradient(self, force)
	if ((force or (conf and conf.color.gradient.enable)) and not self.tfade) then
		if (gradient) then
			if (not self.gradient) then
				local w = self:GetWidth()
				if (w and w > 10) then
					self.gradient = self:CreateTexture(nil, "ARTWORK")
					self.gradient:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
					self.gradient:SetBlendMode("ADD")

					local bd = self:GetBackdrop()

					if (bd) then
						self.gradient:SetPoint("TOPLEFT", bd.insets.left, -bd.insets.top)
						self.gradient:SetPoint("BOTTOMRIGHT", -bd.insets.right, bd.insets.bottom)
					else
						self.gradient:SetAllPoints()
					end
				end
			end
			if (self.gradient) then
				local orient, r, g, b, a, r2, g2, b2, a2 = unpack(gradient)
				---@diagnostic disable-next-line: type-mismatch
				self.gradient:SetGradient(orient, CreateColor(r, g, b, a), CreateColor(r2, g2, b2, a2))
				self.gradient:Show()
			end
			return true
		end
	else
		if (self.gradient) then
			self.gradient:Hide()
		end
	end
end

-- SetupUnitFrame
local function SetupUnitFrame(self)
	self:SetBackdropBorderColor(conf.color.border.r, conf.color.border.g, conf.color.border.b, conf.color.border.a)
	self:SetBackdropColor(conf.color.frame.r, conf.color.frame.g, conf.color.frame.b, conf.color.frame.a)
	ZPerl.DoGradient(self)
end

-- SetupUnitFrameList
local function SetupUnitFrameList(frame, subList, keepAlpha)

	if (conf.color.gradient.enable) then
		local o
		if (conf.color.gradient.horizontal) then
			o = "HORIZONTAL"
		else
			o = "VERTICAL"
		end

		gradient = {o, conf.color.gradient.e.r, conf.color.gradient.e.g, conf.color.gradient.e.b, conf.color.gradient.e.a, conf.color.gradient.s.r, conf.color.gradient.s.g, conf.color.gradient.s.b, conf.color.gradient.s.a}
	end

	if (type(subList) == "table") then
		if (not keepAlpha) then
			frame:SetAlpha(conf.transparency.frame)
		end
		for k,v in pairs(subList) do
			SetupUnitFrame(v)
		end
	else
		SetupUnitFrame(frame)
	end
end

-- ZPerl_RegisterUnitFrame(frame)
local UnitFrames = {}
function ZPerl.RegisterPerlFrames(frame, subList)
	if (not subList) then
		subList = true
	end
	UnitFrames[frame] = subList

	-- Once per frame: a frame that inherits ZPerl_BackdropTemplate and a second template with the
	-- backdropInfo gets no backdrop at load. No option changes a backdrop, so no re-apply is needed.
	if (type(subList) == "table") then
		for k, v in pairs(subList) do
			v:OnBackdropLoaded()
		end
	else
		frame:OnBackdropLoaded()
	end

	if (init_done) then
		SetupUnitFrameList(frame, subList)
	end
end

-- ZPerl.SetupAllPerlFrames
-- keepAlpha: leave the frame alpha alone (the range fader owns it between option changes)
function ZPerl.SetupAllPerlFrames(frame, keepAlpha)
	for k, v in pairs(UnitFrames) do
		SetupUnitFrameList(k, v, keepAlpha)
	end
end

-- ZPerl.SetPerlFramesAlpha: the alpha part of ZPerl.SetupAllPerlFrames
function ZPerl.SetPerlFramesAlpha()
	for k, v in pairs(UnitFrames) do
		if (type(v) == "table") then
			k:SetAlpha(conf.transparency.frame)
		end
	end
end

-- ZPerl.SetAllFrames
function ZPerl.SetAllFrames()
	ZPerl.SetupAllPerlFrames()
	ZPerl.SetHighlights()
end

-- ZPerl.Pcall
function ZPerl.Pcall(...)
	local success, err = pcall(...)
	if (not success) then
		errorCount = errorCount + 1
		if (not doneOptions) then
			-- the message goes in as an argument: Notice formats its first one, and an error text can hold a %
			ZPerl.Notice("Error: %s", tostring(err))
		end
		geterrorhandler()(err)
	end
	return success
end

-- GetNamesWithoutBuff
local lastNamesList
local lastName
local lastWith
local lastNamesCount
local lastFilter, lastSort, lastTime
-- the list follows the group's auras, so a cached one is reused only for the same query within a second
-- (the tooltip asks again while it stays open)
local NAMES_CACHE_TIME = 1
local function GetNamesWithoutBuff(spellName, with, filter)
	-- aura names can be secret in restricted content and can
	-- then neither be compared nor cached
	if (not ZPerl.CanAccess(spellName)) then
		return
	end
	if spellName == lastName and with == lastWith and filter == lastFilter and conf.buffHelper.sort == lastSort
		and lastNamesList and lastTime and GetTime() - lastTime < NAMES_CACHE_TIME then
		return lastNamesList, lastNamesCount
	end

	local count = 0
	local names

	--local withList = ZPerl.GetReusableTable()
	local withList = { }
	for unitid, unitName, unitClass, group, zone, online, dead in ZPerl.NextMember do
		local use

		if not conf.buffHelper.visible then
			use = true
		else
			if conf.raid.sortByClass then
				-- one column per class: the member counts when its class's column is enabled and shown
				if (unitClass and ZPerl.CanAccess(unitClass)) then
					for i, c in ipairs(conf.raid.class) do
						if (c.name == unitClass) then
							use = c.enable and conf.raid.group[i]
							break
						end
					end
				end
			else
				use = conf.raid.group[group]
			end
		end

		if unitName and use and online and not dead then
			local hasBuff
			for i = 1, 40 do
				local name = ZPerl.UnitAuraByIndex(unitid, i, filter)
				if not name then
					break
				end

				if ZPerl.CanAccess(name) and name == spellName then
					hasBuff = true
				end
			end

			if (with and hasBuff) or (not with and not hasBuff) then
				count = count + 1

				if conf.buffHelper.sort == "group" then
					if (not withList[group]) then
						--withList[group] = ZPerl.GetReusableTable()
						withList[group] = { }
					end
					tinsert(withList[group], {class = unitClass, name = unitName})
				elseif conf.buffHelper.sort == "class" then
					-- a member whose class is not known yet has no column (nil cannot be a table key): counted, not listed
					if unitClass then
						if not withList[unitClass] then
							--withList[unitClass] = ZPerl.GetReusableTable()
							withList[unitClass] = { }
						end
						tinsert(withList[unitClass], unitName)
					end
				else
					--local n = ZPerl.GetReusableTable()
					local n = { }
					tinsert(withList, n)
					n.class = unitClass
					n.name = unitName
				end
			end
		end
	end

	if conf.buffHelper.sort == "group" then
		for i = 1, 8 do
			local list = withList[i]
			if list then
				sort(list, function(a, b) return a.name < b.name end)

				names = (names or "").."|r"..i..": "
				for i, item in ipairs(list) do
					-- a member whose class is not known yet still gets listed, in grey
					names = names..(item.class and ZPerl.ColorTable[item.class] or "|c00808080")..item.name.." "
				end
				names = names.."|r\r"
			end
			--ZPerl.FreeTable(list)
		end
	elseif conf.buffHelper.sort == "class" then
		for j, class in ipairs(classOrder) do
			local list = withList[class]
			if list then
				sort(list)

				for i, name in ipairs(list) do
					if i == 1 then
						names = (names or "")..ZPerl.ColorTable[class]
					end
					names = (names or "")..name.." "
				end

				names = (names or "").."|r\r"
			end
			--ZPerl.FreeTable(list)
		end
	else
		sort(withList, function(a, b) return a.name < b.name end)
		for i, item in ipairs(withList) do
			names = (names or "")..(item.class and ZPerl.ColorTable[item.class] or "|c00808080")..item.name.." "
			--ZPerl.FreeTable(item)
		end

		names = (names or "").."\r"
	end

	--ZPerl.FreeTable(withList)

	lastNamesList = names
	lastName = spellName
	lastWith = with
	lastNamesCount = count
	lastFilter, lastSort, lastTime = filter, conf.buffHelper.sort, GetTime()

	return names, count
end

-- ToolTipAddBuffDuration
local function ToolTipAddBuffDuration(self, partyid, buffID, filter)
	if IsInRaid() or UnitInParty("player") then
		local name = ZPerl.UnitAuraByIndex(partyid, buffID, filter)

		if conf.buffHelper.enable and partyid and (UnitInParty(partyid) or UnitInRaid(partyid)) then
			if name and ZPerl.CanAccess(name) then
				local names, count = GetNamesWithoutBuff(name, IsAltKeyDown(), filter)
				if names then
					if IsAltKeyDown() then
						self:AddLine(format(L["RAID_TOOLTIP_WITHBUFF"], count), 0.3, 1, 0.2)
					else
						self:AddLine(format(L["RAID_TOOLTIP_WITHOUTBUFF"], count), 1, 0.3, 0.1)
					end

					if conf.buffHelper.sort then
						self:AddLine(names, 0.5, 0.5, 0.5)
					else
						self:AddLine(names, 0.5, 0.5, 0.5, true)
					end
				end
			end
		end
	end

	GameTooltip:Show()
end

-- Buff Tooltip Hook
local function GameTooltipSetUnitAura(self, unitId, buffId, filter)
	ToolTipAddBuffDuration(self, unitId, buffId, filter)
end

local function GameTooltipSetUnitBuff(self, unitId, buffId)
	ToolTipAddBuffDuration(self, unitId, buffId, "HELPFUL")
end

local function GameTooltipSetUnitDebuff(self, unitId, buffId)
	ToolTipAddBuffDuration(self, unitId, buffId, "HARMFUL")
end

-- ZPerl.Init()
function ZPerl.Init()
	init_done = true
	if GameTooltip.SetUnitAura then
		hooksecurefunc(GameTooltip, "SetUnitAura", GameTooltipSetUnitAura)
		hooksecurefunc(GameTooltip, "SetUnitBuff", GameTooltipSetUnitBuff)
		hooksecurefunc(GameTooltip, "SetUnitDebuff", GameTooltipSetUnitDebuff)
	end

	local f = CreateFrame("Frame")
	local tx = f:CreateTexture()
	tx:SetPoint("CENTER", WorldFrame)
	tx:SetAlpha(0)
	f:SetAllPoints(tx)
	f:SetScript("OnSizeChanged", function(self, width, height)
		local size = format("%.0f%.0f", width, height)
		if size == "11" then
			conf.bar.texture[1] = "Perl v2"
			conf.bar.texture[2] = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_StatusBar"
			ZPerl.SetBarTextures()
		end
	end)
	tx:SetTexture(conf.bar.texture[2])
	tx:SetSize(0, 0)

	ZPerl.Pcall(ZPerl.OptionActions)

	--PartyMemberFrame:UnregisterEvent("UNIT_NAME_UPDATE")

	--ZPerl.RegisterSMBarTextures()

	ZPerl.Pcall(ZPerl.DebufHighlightInit)

	ZPerl.Init = nil
end

-- ZPerl.StatsFrameOnLoad
-- Power events call this; the list of other bars is one table reused per call (the function does not
-- re-enter and keeps no reference to it).
local otherBars = {}
function ZPerl.StatsFrameSetup(self, others, offset)
	if (not self) then
		return
	end
	local StatsFrame = self.statsFrame
	if (not StatsFrame) then
		return
	end

	local healthBar = StatsFrame.healthBar
	local healthBarText = healthBar.text
	local healthBarPercent = healthBar.percent
	local manaBar = StatsFrame.manaBar
	local manaBarPercent = manaBar.percent
	wipe(otherBars)
	local secondaryBarsShown = 0
	local percentSize = 0
	if (healthBarPercent:IsShown() or manaBarPercent:IsShown()) then
		percentSize = 35
	end

	offset = (offset or 0)

	healthBar:SetWidth(0)

	if (manaBar:IsShown()) then
		secondaryBarsShown = secondaryBarsShown + 1
		manaBar:SetWidth(0)
	end

	local needTicker = 0
	if (StatsFrame.energyTicker) then
		needTicker = 1
	end

	if (others) then
		for i, bar in pairs(others) do
			if (bar) then
				tinsert(otherBars, bar)
				if (bar:IsShown()) then
					secondaryBarsShown = secondaryBarsShown + 1
					bar:SetWidth(0)
				end
			end
		end
	end

	if (conf.bar.fat) then
		if (StatsFrame == ZPerl_Player_PetstatsFrame) then
			healthBarText:SetFontObject(GameFontNormalSmall)
		else
			healthBarText:SetFontObject(GameFontNormal)
		end
		healthBarText:SetTextColor(1, 1, 1)

		local x = 10

		local frameName = self:GetName()
		if frameName == "ZPerl_partypet1" or frameName == "ZPerl_partypet2" or frameName == "ZPerl_partypet3" or frameName == "ZPerl_partypet4" or frameName == "ZPerl_partypet5" then
			x = 7
		end

		healthBar:ClearAllPoints()
		healthBar:SetPoint("TOPLEFT", 5, -5)
		healthBar:SetPoint("BOTTOMRIGHT", -(5 + percentSize), 5 + needTicker + (secondaryBarsShown * x))

		manaBar:ClearAllPoints()
		manaBar:SetPoint("BOTTOMLEFT", 5, -5 + needTicker + (secondaryBarsShown * 10))
		manaBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)

		local lastBar = manaBar
		local tickerSpace = needTicker * 1.5
		for i,bar in pairs(otherBars) do
			if (bar:IsShown()) then
				bar:ClearAllPoints()

				bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, -tickerSpace)
				bar:SetPoint("BOTTOMRIGHT", lastBar, "BOTTOMRIGHT", 0, -10 - tickerSpace)

				lastBar = bar
				tickerSpace = 0
			end
		end
	else
		healthBarText:SetFontObject(GameFontNormalSmall)
		healthBarText:SetTextColor(1, 1, 1)

		healthBar:ClearAllPoints()
		healthBar:SetPoint("TOPLEFT", 8, -9 + offset)
		healthBar:SetPoint("BOTTOMRIGHT", StatsFrame, "TOPRIGHT", -(8 + percentSize), -19 + offset)

		manaBar:ClearAllPoints()
		manaBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -2)
		manaBar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, -12)

		local lastBar = manaBar
		for i, bar in pairs(otherBars) do
			if (bar:IsShown()) then
				bar:ClearAllPoints()

				bar:SetPoint("TOPLEFT", lastBar, "BOTTOMLEFT", 0, -2)
				bar:SetPoint("BOTTOMRIGHT", lastBar, "BOTTOMRIGHT", 0, -12)

				lastBar = bar
			end
		end
	end
end

-- ZPerl.RegisterUnitText(self)
local unitText = {}
function ZPerl.RegisterUnitText(self)
	tinsert(unitText, self)
end

-- ZPerl.SetTextTransparency()
function ZPerl.SetTextTransparency()
	local t = conf.transparency.text
	for k, v in pairs(unitText) do
		if (v.GetTextColor) then
			local r, g, b = v:GetTextColor()
			v:SetTextColor(r, g, b, t)
		end
	end
	if ZPerl_Player_TargettingFrametext then
		local r, g, b = ZPerl_Player_TargettingFrametext:GetTextColor()
		ZPerl_Player_TargettingFrametext:SetTextColor(r, g, b, t)
	end
	if ZPerl_Target_AssistFrametext then
		local r, g, b = ZPerl_Target_AssistFrametext:GetTextColor()
		ZPerl_Target_AssistFrametext:SetTextColor(r, g, b, t)
	end
end

-- Set1Bar
local function Set1Bar(bar, tex)
	if (bar.tex) then
		bar.tex:SetTexture(tex)
		bar.tex:SetHorizTile(false)
		bar.tex:SetVertTile(false)
	end
	if (bar.bg) then
		if (conf.bar.background) then
			bar.bg:SetTexture(tex)
		else
			bar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
		end
		bar.bg:SetHorizTile(false)
		bar.bg:SetVertTile(false)
	end
end

-- ZPerl.RegisterBar
local Bars = {}
function ZPerl.RegisterBar(bar)
	tinsert(Bars, bar)
	if (init_done) then
		local tex = ZPerl.GetBarTexture()
		Set1Bar(bar, tex)
	end
end

-- ZPerl.SetBarTextures
function ZPerl.SetBarTextures()
	local tex = ZPerl.GetBarTexture()
	for k, v in pairs(Bars) do
		Set1Bar(v, tex)
	end
end

-- ZPerl.RegisterOptionChanger(f, s, name)
-- name makes the changer an applier (ZPerl.Appliers) the settings panel can run on its own.
local optionFuncs = {}
ZPerl.OptionChangers = optionFuncs -- exported for the test harness
local appliers = {}
ZPerl.Appliers = appliers -- applier name -> function; the panel's `apply` names (ZPerl_SettingsList.lua)
function ZPerl.RegisterOptionChanger(f, s, name)
	local v = {func = f, slf = s, name = name}
	if name then
		v.run = function()
			ZPerl.NoFadeBars(true)
			ZPerl.Pcall(v.func, v.slf)
			ZPerl.NoFadeBars()
		end
		appliers[name] = v.run
	end
	tinsert(optionFuncs, v)
end

-- ZPerl.RegisterApplier(name, f)
-- An applier the settings panel can run that ZPerl.OptionActions does not: work the old window did after a setting changed
-- but a full re-apply never did (the raid header attributes). Runs first: it can create the frames the others restyle.
local plain = {}
function ZPerl.RegisterApplier(name, f)
	plain[name] = function() ZPerl.Pcall(f) end
	appliers[name] = plain[name]
end

local function clampTransparency()
	conf.transparency.frame	= min(max(tonumber(conf.transparency.frame or 1), 0), 1)
	conf.transparency.text	= min(max(tonumber(conf.transparency.text or 1), 0), 1)
end

-- The pieces of ZPerl.OptionActions that are not changers. Wrapped, as the functions load later.
appliers.barcolors = function() ZPerl.ResetBarColorCache() end
appliers.bartextures = function() ZPerl.Pcall(ZPerl.SetBarTextures) end
appliers.skin = function() ZPerl.Pcall(ZPerl.SetupAllPerlFrames, nil, true) end
appliers.framealpha = function() ZPerl.Pcall(ZPerl.SetPerlFramesAlpha) end
appliers.custom = function() -- the custom raid highlights (CustomHighlight/)
	local c = _G.ZPerl_Custom
	if c then ZPerl.Pcall(c.Refresh, c) end
end
appliers.highlighttex = function() ZPerl.Pcall(ZPerl.SetHighlights) end
appliers.texttransparency = function() ZPerl.Pcall(ZPerl.SetTextTransparency) end
ZPerl.RegisterOptionChanger(function()
	if ZPerl_MinimapButton_Frame then ZPerl_MinimapButton_Frame:SetShown(conf.minimap.enable and true or false) end
end, nil, "minimap")
local headAppliers = {"barcolors", "bartextures", "skin", "framealpha", "highlighttex", "custom"}

-- ZPerl.Apply(names): runs the named appliers, core pieces first, then the changers in registration order,
-- then the text transparency; "full" is ZPerl.OptionActions. Deferred whole until combat ends, as
-- ZPerl.OptionActions is; names asked for during combat are merged into one run.
local queued
local function applyQueued()
	local names = queued
	queued = nil
	ZPerl.Apply(names)
end
-- ZPerl.HasApplier(name): whether the applier is registered (its addon is loaded).
function ZPerl.HasApplier(name)
	return appliers[name] ~= nil
end

function ZPerl.Apply(names)
	local want = {}
	for _, n in ipairs(names) do
		if n ~= "full" and not appliers[n] then error("unknown applier " .. tostring(n), 2) end
		want[n] = true
	end
	if InCombatLockdown() then
		queued = queued or {}
		for n in pairs(want) do tinsert(queued, n) end
		ZPerl.AfterCombat(applyQueued)
		return
	end
	local d = ZPerl.Dev; if d and d.listener then d.Emit("apply", unpack(names)) end
	if want.full then
		ZPerl.OptionActions()
		return
	end
	clampTransparency()
	for n, run in pairs(plain) do
		if want[n] then run() end
	end
	for _, n in ipairs(headAppliers) do
		if want[n] then appliers[n]() end
	end
	for _, v in ipairs(optionFuncs) do
		if v.name and want[v.name] then v.run() end
	end
	if want.texttransparency then appliers.texttransparency() end
end

-- ZPerl.OptionActions()
function ZPerl.OptionActions(which)

	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.OptionActions, which)
		return
	end
	local d = ZPerl.Dev; if d and d.listener then d.Emit("optionactions") end

	ZPerl.ResetBarColorCache() -- the health color curve reads the color options

	clampTransparency()

	ZPerl.Pcall(ZPerl.SetBarTextures)

	ZPerl.Pcall(ZPerl.SetAllFrames)

	for k, v in pairs(optionFuncs) do
		ZPerl.NoFadeBars(true)
		ZPerl.Pcall(v.func, v.slf, which)
	end
	ZPerl.NoFadeBars()

	ZPerl.Pcall(ZPerl.SetTextTransparency)
	doneOptions = true

end
