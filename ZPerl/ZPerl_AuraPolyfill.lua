-- Author: Resike
-- License: GNU GPL v3, 18 October 2014

------------------------------------------------------------------------------
-- Aura container stand-in
--
-- Z-Perl draws every frame's buffs and debuffs with Blizzard's AuraContainer (CustomAuraContainerTemplate,
-- Blizzard_AuraContainer): see ZPerl.AuraContainerCreate in ZPerl_Values.lua. A client without it (Classic
-- Era) gets this Lua stand-in, which offers the part of the container and button API Z-Perl uses, so the
-- aura code above it runs unchanged:
--   container: SetUnit, GetUnit, AddAuraGroup, HasAuraGroup, IsAuraGroupEnabled, SetAuraGroupEnabled,
--     SetAuraGroupFilterString, SetAuraGroupCandidateFilters, SetAuraGroupMaxFrameCount, SetAuraGroupLayout,
--     GetAuraGroupFrameCount, GetAuraGroupFrame, SetFlowLayoutMaximumLineSize, SetFlowLayoutAxis,
--     SetFlowLayoutAnchorPoint, SetFlowLayoutGrowthDirection, UpdateAllAuras
--   button: SetIcon, SetDurationCooldown, SetDurationText, ClearDurationText, SetApplicationCount,
--     SetCancelAuraButtons
-- Such a client has no secret values, so the auras are read directly (C_UnitAuras.GetAuraDataByIndex, else
-- UnitAura). Groups are filled in layoutIndex order and laid out as one flow: icons along the line from the
-- anchor point in the growth direction, a new line when the next icon passes the maximum line size, lines
-- stacking in the other growth direction. The container takes the size of its icons. Right-click cancel
-- (a buff of the player's) works out of combat, as CancelUnitBuff does for addons.

-- Upvalues
local floor = floor
local max = max

local GetAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local GetTime = GetTime
local UnitAura = UnitAura

-- LibClassicDurations (Classic Era only; the library does not load elsewhere): the target's auras are read
-- through it, which fills in the durations the client leaves at 0 and adds an enemy target's buffs. Its
-- UNIT_BUFF callback (the combat log saw the target's buffs change) refreshes the target frame's auras.
local LCD = LibStub and LibStub("LibClassicDurations", true)
if (LCD) then
	---@diagnostic disable-next-line: undefined-field
	LCD:Register("ZPerl")
	---@diagnostic disable-next-line: undefined-field
	LCD.RegisterCallback("ZPerl", "UNIT_BUFF", function(_, unit)
		local frame = ZPerl_Target
		if (unit == "target" and frame and frame.buffContainer and frame:IsShown()) then
			ZPerl.AurasUpdate(frame)
		end
	end)
end

-- fromUnitAura(...): the returns of UnitAura as an AuraData-like table, or nil past the last aura
local fromPlayer = {player = true, pet = true, vehicle = true}
local function fromUnitAura(name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable, nameplateShowPersonal, spellId)
	if (not name) then
		return nil
	end
	return {name = name, icon = icon, applications = applications, dispelName = dispelName, duration = duration,
		expirationTime = expirationTime, sourceUnit = sourceUnit, isStealable = isStealable,
		nameplateShowPersonal = nameplateShowPersonal, spellId = spellId,
		isFromPlayerOrPlayerPet = sourceUnit ~= nil and fromPlayer[sourceUnit] or false}
end

-- ZPerl.AuraData(unit, index, filter): one aura as an AuraData-like table, or nil past the last one
function ZPerl.AuraData(unit, index, filter)
	if (LCD and unit == "target") then
		---@diagnostic disable-next-line: undefined-field
		return fromUnitAura(LCD.UnitAuraWithBuffs(unit, index, filter))
	end
	if (GetAuraDataByIndex) then
		return GetAuraDataByIndex(unit, index, filter)
	end
	if (not UnitAura) then
		return nil
	end
	return fromUnitAura(UnitAura(unit, index, filter))
end
local AuraData = ZPerl.AuraData

------------------------------------------------------------------------------ Buttons
local Button = {}

function Button:SetIcon(texture)
	self.zIcon = texture
end
function Button:SetDurationCooldown(cooldown)
	self.zCooldown = cooldown
end
function Button:SetDurationText(fontString)
	self.zDuration = fontString
end
function Button:ClearDurationText()
	if (self.zDuration) then
		self.zDuration:SetText("")
	end
	self.zDuration = nil
end
function Button:SetApplicationCount(fontString)
	self.zCount = fontString
end
function Button:SetCancelAuraButtons(buttons)
	self.zCancel = true
	self:RegisterForClicks(buttons or "RightButtonUp")
end

local function durationText(remaining)
	if (remaining >= 3600) then
		return format("%dh", floor(remaining / 3600 + 0.5))
	elseif (remaining >= 60) then
		return format("%dm", floor(remaining / 60 + 0.5))
	end
	return format("%d", floor(remaining + 0.5))
end

local function onEnter(self)
	local container = self:GetParent()
	if (not self.zIndex or not container.unit) then
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnitAura(container.unit, self.zIndex, self.zFilter)
	GameTooltip:Show()
end

local function onLeave()
	GameTooltip:Hide()
end

local function onClick(self, mouse)
	local container = self:GetParent()
	if (self.zCancel and mouse == "RightButton" and self.zIndex and not InCombatLockdown()) then
		CancelUnitBuff(container.unit, self.zIndex, self.zFilter)
	end
end

local function newButton(container, group)
	local b = CreateFrame("Button", nil, container)
	for k, fn in pairs(Button) do
		b[k] = fn
	end
	b:SetSize(group.layout.elementWidth or 20, group.layout.elementHeight or 20)
	b:SetScript("OnEnter", onEnter)
	b:SetScript("OnLeave", onLeave)
	b:SetScript("OnClick", onClick)
	b:Hide()
	group.frames[#group.frames + 1] = b
	if (group.init) then
		group.init(b)
	end
	return b
end

-- show(button, aura, index, filter)
local function show(b, aura, index, filter)
	b.zIndex, b.zFilter = index, filter
	if (b.zIcon) then
		b.zIcon:SetTexture(aura.icon)
	end
	if (b.zCount) then
		local n = aura.applications
		b.zCount:SetText((n and n > 1) and n or "")
	end
	local duration, expiration = aura.duration or 0, aura.expirationTime or 0
	b.zExpiration = (duration > 0 and expiration > 0) and expiration or nil
	if (b.zCooldown) then
		if (b.zExpiration) then
			b.zCooldown:SetCooldown(expiration - duration, duration)
			b.zCooldown:Show()
		else
			if (b.zCooldown.Clear) then
				b.zCooldown:Clear()
			end
			b.zCooldown:Hide()
		end
	end
	if (b.zDuration) then
		b.zDuration:SetText(b.zExpiration and durationText(max(0, b.zExpiration - GetTime())) or "")
	end
	b:Show()
end

------------------------------------------------------------------------------ Container
local Container = {}

function Container:SetUnit(unit)
	self.unit = unit
end
function Container:GetUnit()
	return self.unit
end

function Container:AddAuraGroup(key, filter, opts)
	local group = {key = key, filter = filter, enabled = true, frames = {}, order = #self.order + 1,
		max = opts and opts.maxFrameCount or math.huge, layout = opts and opts.layout or {},
		cand = opts and opts.candidateFilters, init = opts and opts.initializeFrame}
	self.groups[key] = group
	self.order[#self.order + 1] = group
end
function Container:HasAuraGroup(key)
	return self.groups[key] ~= nil
end
function Container:IsAuraGroupEnabled(key)
	return self.groups[key] ~= nil and self.groups[key].enabled
end
function Container:SetAuraGroupEnabled(key, enabled)
	self.groups[key].enabled = enabled and true or false
end
function Container:SetAuraGroupFilterString(key, filter)
	self.groups[key].filter = filter
end
function Container:SetAuraGroupCandidateFilters(key, cand)
	self.groups[key].cand = cand
end
function Container:SetAuraGroupMaxFrameCount(key, count)
	self.groups[key].max = count or math.huge
end
function Container:SetAuraGroupLayout(key, layout)
	self.groups[key].layout = layout or {}
end
function Container:GetAuraGroupFrameCount(key)
	return #self.groups[key].frames
end
function Container:GetAuraGroupFrame(key, i)
	return self.groups[key].frames[i]
end
function Container:SetFlowLayoutMaximumLineSize(size)
	self.lineSize = size
end
function Container:SetFlowLayoutAxis()
	-- Z-Perl lays every block out in rows (horizontal)
end
function Container:SetFlowLayoutAnchorPoint(point)
	self.anchorPoint = point
end
function Container:SetFlowLayoutGrowthDirection(h, v)
	self.growH, self.growV = h, v
end

-- passes(aura, cand): the group's candidate filters (excluded spells, the player's own, stealable)
local function passes(aura, cand)
	if (not cand) then
		return true
	end
	if (cand.excludeSpellIDs and aura.spellId and cand.excludeSpellIDs[aura.spellId]) then
		return false
	end
	if (cand.isFromPlayerOrPlayerPet ~= nil and (aura.isFromPlayerOrPlayerPet or false) ~= cand.isFromPlayerOrPlayerPet) then
		return false
	end
	if (cand.isStealable ~= nil and (aura.isStealable or false) ~= cand.isStealable) then
		return false
	end
	return true
end

local byLayoutIndex = function(a, b)
	local ia, ib = a.layout.layoutIndex or a.order, b.layout.layoutIndex or b.order
	if (ia ~= ib) then
		return ia < ib
	end
	return a.order < b.order
end

function Container:UpdateAllAuras()
	local unit = self.unit
	local placed = {}
	local exists = unit and UnitExists(unit)
	local groups = {}
	for _, g in ipairs(self.order) do
		groups[#groups + 1] = g
	end
	sort(groups, byLayoutIndex)
	for _, g in ipairs(groups) do
		local n = 0
		if (exists and g.enabled) then
			local i = 1
			while (n < g.max) do
				local aura = AuraData(unit, i, g.filter)
				if (not aura) then
					break
				end
				if (passes(aura, g.cand)) then
					n = n + 1
					local b = g.frames[n] or newButton(self, g)
					show(b, aura, i, g.filter)
					placed[#placed + 1] = {b, g.layout}
				end
				i = i + 1
			end
		end
		for k = n + 1, #g.frames do
			g.frames[k]:Hide()
		end
	end

	-- One flow over all groups
	local point = self.anchorPoint or "TOPLEFT"
	local h, v = self.growH or 1, self.growV or -1
	local lineSize = self.lineSize
	local x, y, lineH, width, lineGap = 0, 0, 0, 0, 0
	for _, p in ipairs(placed) do
		local b, layout = p[1], p[2]
		local w, ht = b:GetWidth(), b:GetHeight()
		local spacing = layout.elementSpacing or 3
		if (x > 0 and lineSize and x + w > lineSize) then
			y = y + lineH + lineGap
			x, lineH = 0, 0
		end
		b:ClearAllPoints()
		b:SetPoint(point, self, point, h * x, v * y)
		width = max(width, x + w)
		lineH = max(lineH, ht)
		lineGap = max(lineGap, layout.lineSpacing or 0)
		x = x + w + spacing
	end
	self:SetSize(max(1, width), max(1, y + lineH))
	self.hasTimers = #placed > 0
end

-- Duration texts count down while shown
local function onUpdate(self, elapsed)
	self.zTick = (self.zTick or 0) + elapsed
	if (self.zTick < 0.2 or not self.hasTimers) then
		return
	end
	self.zTick = 0
	local now = GetTime()
	for _, g in ipairs(self.order) do
		for _, b in ipairs(g.frames) do
			if (b:IsShown() and b.zDuration and b.zExpiration) then
				b.zDuration:SetText(durationText(max(0, b.zExpiration - now)))
			end
		end
	end
end

-- ZPerl.CreateAuraContainerStandIn(name, parent)
function ZPerl.CreateAuraContainerStandIn(name, parent)
	local c = CreateFrame("Frame", name, parent)
	for k, fn in pairs(Container) do
		c[k] = fn
	end
	c.groups, c.order = {}, {}
	c:SetScript("OnUpdate", onUpdate)
	return c
end
