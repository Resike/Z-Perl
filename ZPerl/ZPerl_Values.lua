-- Author: Resike
-- License: GNU GPL v3, 18 October 2014



------------------------------------------------------------------------------
-- restricted API support
--
-- The Forever client is expected to use the Midnight style "secret values".
-- A secret cannot be compared, used in maths, used as a table key or tested as
-- a boolean; it can only be handed to Blizzard widget methods. Everything in
-- this file that touches unit health, power, auras, names or cast times goes
-- through the helpers below, and the new Blizzard helper APIs are only used
-- when the running client actually provides them. On a Classic Era client all
-- of these switches are off and the original code paths run unchanged.
--
-- The whole block is scoped with do/end so the file's main chunk stays under
-- Lua's limit of 200 active local variables. Only the globals defined in here
-- are used by the rest of the file and by the other modules.
do
-- Upvalues
local canaccessvalue = canaccessvalue
local issecretvalue = issecretvalue

local ShouldAurasBeSecret = C_Secrets and C_Secrets.ShouldAurasBeSecret

-- ZPerl.CanAccess(v) - true when addon code may read, compare or index v
function ZPerl.CanAccess(v)
	if (v == nil) then
		return false
	end
	if (canaccessvalue) then
		return canaccessvalue(v)
	end
	if (issecretvalue) then
		return not issecretvalue(v)
	end
	return true
end
local CanAccess = ZPerl.CanAccess

-- ZPerl.IsSecret(v) - true when v exists but addon code may not look inside it
function ZPerl.IsSecret(v)
	return v ~= nil and not CanAccess(v)
end
local IsSecret = ZPerl.IsSecret

-- ZPerl.IsHit(action, damage) - true when a UNIT_COMBAT event dealt damage. The amount is secret on
-- Forever, so a secret amount counts as a hit when the action is a wound.
function ZPerl.IsHit(action, damage)
	if (IsSecret(damage)) then
		return action == "WOUND"
	end
	return damage ~= nil and damage > 0
end

-- Feature switches, evaluated once at load
local HasHealthPercent = type(UnitHealthPercent) == "function" and CurveConstants ~= nil
local HasPowerPercent = type(UnitPowerPercent) == "function" and CurveConstants ~= nil
local HasColorCurves = C_CurveUtil ~= nil and type(C_CurveUtil.CreateColorCurve) == "function"
local HasBooleanCurves = C_CurveUtil ~= nil and type(C_CurveUtil.EvaluateColorValueFromBoolean) == "function"
local HasAuraAPI = C_UnitAuras ~= nil and type(C_UnitAuras.GetUnitAuras) == "function"
-- Detected the same way as the SecureAuraHeaderTemplate probe already used by
-- ZPerl_PlayerBuffs.lua: ask the client whether it knows the template name at
-- all, rather than assuming from an interface/version number.
local HasAuraContainer = C_XMLUtil ~= nil and type(C_XMLUtil.GetTemplateInfo) == "function" and C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") ~= nil
-- ZPerl.IsMasterLoot(method) - C_PartyInfo.GetLootMethod returns Enum.LootMethod, the old API a string
function ZPerl.IsMasterLoot(method)
	return method == "master" or (Enum.LootMethod ~= nil and method == Enum.LootMethod.Masterlooter)
end

-- ZPerl.SafeBool(v, default)
-- A boolean that may be secret cannot be tested or combined; return default then
function ZPerl.SafeBool(v, default)
	if (not CanAccess(v)) then
		return default
	end
	return v
end

-- Shared with the other modules
ZPerl.ForeverAPI = {
	healthPercent = HasHealthPercent,
	powerPercent = HasPowerPercent,
	colorCurves = HasColorCurves,
	booleanCurves = HasBooleanCurves,
	auras = HasAuraAPI,
	auraContainer = HasAuraContainer,
	castDurations = type(UnitCastingDuration) == "function",
	auraSecrecy = C_Secrets ~= nil and type(C_Secrets.ShouldAurasBeSecret) == "function",
	healthEvent = "UNIT_HEALTH",
}

-- Group visibility.
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE"}) do
	ZPerl.On(event, ZPerl.GroupVisibilityUpdate)
end

-- ZPerl.SetAlphaFromBoolean(region, value, alphaTrue, alphaFalse)
-- Shows/dims a region from a boolean that may be secret
function ZPerl.SetAlphaFromBoolean(region, value, alphaTrue, alphaFalse)
	if (not region) then
		return
	end
	if (region.SetAlphaFromBoolean and IsSecret(value)) then
		region:SetAlphaFromBoolean(value, alphaTrue, alphaFalse)
	elseif (value and CanAccess(value)) then
		region:SetAlpha(alphaTrue)
	else
		region:SetAlpha(alphaFalse)
	end
end

-- ZPerl.GetPowerPercent(unit, powerType)
-- Returns a 0..100 value for text display only; secret in the client (UnitPower is always secret).
function ZPerl.GetPowerPercent(unit, powerType)
	if (HasPowerPercent and unit) then
		return UnitPowerPercent(unit, powerType, false, CurveConstants.ScaleTo100)
	end
	return 0
end

-- Aura enumeration -----------------------------------------------------------
-- ZPerl.UnitAuraByIndex(unit, index, filter)
-- Returns name, icon, applications, dispelName, duration, expirationTime, sourceUnit, isStealable,
-- nameplateShowPersonal, spellId, auraInstanceID, isFromPlayerOrPlayerPet.
-- Uses C_UnitAuras.GetUnitAuras when the client has it. The vector is cached for
-- the current frame so index loops do not re-query the client each step.
local auraCacheUnit, auraCacheFilter, auraCacheTime, auraCacheList

-- ZPerl.AurasSecret()
-- True while the client hides aura data from addons (combat, encounters, M+, PvP).
-- Since 12.1 every by-index / by-instance aura query raises a Lua error for addon
-- code in that state, so callers must not even ask.
function ZPerl.AurasSecret()
	return ShouldAurasBeSecret ~= nil and ShouldAurasBeSecret() == true
end

if (HasAuraAPI) then
	-- Drop the cached vector as soon as any aura changes
	ZPerl.On("UNIT_AURA", function()
		auraCacheList = nil
	end)
end
function ZPerl.UnitAuraByIndex(unit, index, filter)
	if (ZPerl.AurasSecret()) then
		auraCacheList = nil
		return nil
	end

	if (not HasAuraAPI) then
		-- a client without GetUnitAuras (Classic Era): one aura by index, no vector to cache
		local aura = ZPerl.AuraData and ZPerl.AuraData(unit, index, filter or "HELPFUL")
		if (not aura) then
			return nil
		end
		return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal, aura.spellId, aura.auraInstanceID, aura.isFromPlayerOrPlayerPet
	end

	local now = GetTime()
	if (auraCacheUnit ~= unit or auraCacheFilter ~= filter or auraCacheTime ~= now or not auraCacheList) then
		auraCacheUnit, auraCacheFilter, auraCacheTime = unit, filter, now
		-- pcall: the secrecy flag can flip between the check above and the query
		local ok, list = pcall(C_UnitAuras.GetUnitAuras, unit, filter or "HELPFUL", 40)
		auraCacheList = ok and list or nil
	end

	local aura = auraCacheList and auraCacheList[index]
	if (not aura) then
		return nil
	end
	return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration, aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal, aura.spellId, aura.auraInstanceID, aura.isFromPlayerOrPlayerPet
end

-- ZPerl.SafeSetWidthFromText(frame, textObject, padding, fallbackWidth)
-- GetStringWidth() can come back a secret number even for a FontString
-- holding plain, non-secret text: taint follows the execution path of the
-- surrounding update, not just the value being measured (section 3) -- a
-- readable source string (e.g. checked via CanAccess) is not enough on
-- its own: UpdateType crashed with its typeReadable check
-- already passed. Guard the width itself.
function ZPerl.SafeSetWidthFromText(frame, textObject, padding, fallbackWidth)
	local width = textObject:GetStringWidth()
	if (IsSecret(width)) then
		frame:SetWidth(fallbackWidth)
	else
		frame:SetWidth(width + (padding or 0))
	end
end

-- ZPerl.HasAuraContainerNow()
-- Blizzard_AuraContainer is load-on-demand, so the one-shot probe at the top of
-- this file can run before it exists and freeze the flag false for the session.
-- Re-check on demand and load it ourselves.
-- A client that does not have it at all (Classic Era) gets Z-Perl's Lua stand-in (ZPerl_AuraPolyfill.lua):
-- ZPerl.AuraStandIn is set once the native container is known to be missing, and ZPerl.AuraContainerCreate
-- builds the stand-in then.
function ZPerl.HasAuraContainerNow()
	if (ZPerl.AuraStandIn) then
		return true
	end
	local hasTemplateInfo = C_XMLUtil ~= nil and type(C_XMLUtil.GetTemplateInfo) == "function"
	if (hasTemplateInfo and C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") ~= nil) then
		ZPerl.ForeverAPI.auraContainer = true
		return true
	end
	-- LoadAddOn is not safe to call in combat lockdown; try again once out.
	if (InCombatLockdown()) then
		return false
	end
	local loader = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
	if (type(loader) == "function") then
		-- pcall, not ZPerl.Pcall: a client without the addon refuses it, which is no error here
		pcall(loader, "Blizzard_AuraContainer")
	end
	local present = hasTemplateInfo and C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") ~= nil
	ZPerl.ForeverAPI.auraContainer = present
	if (not present and ZPerl.CreateAuraContainerStandIn) then
		ZPerl.AuraStandIn = true
		return true
	end
	return present
end

-- Room under an aura row for its duration text (GameFontNormalSmall), used
-- between rows and between a frame's buff and debuff containers.
ZPerl.AuraTextGap = 12

-- ZPerl.AuraGap(c): the room under an aura line for its duration text; 0 while duration text is off
-- (the global buffs.countdown, or c.auraText == false for the frame whose options are c).
function ZPerl.AuraGap(c)
	if (c and c.auraText == false) then
		return 0
	end
	return ZPerl.layout.buffs.countdown and ZPerl.AuraTextGap or 0
end

-- ZPerl.AuraContainerSafeToReconfigure()
-- An already-adopted group/button can reject reconfiguration while secret.
-- Creating one fresh is fine; touching a live one must defer.
function ZPerl.AuraContainerSafeToReconfigure()
	return not ZPerl.AurasSecret()
end

-- ZPerl.AuraContainerGate(frame)
-- The one gate for reconfiguring a live container or its buttons (AddAuraGroup on a live container
-- included): while auras are secret the client rejects it ("forbidden object"), so nothing is touched,
-- the frame is marked pending, and the next ZPerl.AurasUpdate with auras readable applies the spec.
-- Returns true when it is safe to go on.
function ZPerl.AuraContainerGate(frame)
	if (ZPerl.AuraContainerSafeToReconfigure()) then
		return true
	end
	frame.auraContainerPending = true
	return false
end

local function sameFilters(a, b)
	a, b = a or {}, b or {}
	for k, v in pairs(a) do
		if (b[k] ~= v) then
			return false
		end
	end
	for k in pairs(b) do
		if (a[k] == nil) then
			return false
		end
	end
	return true
end

local function groupLayout(g)
	return {
		elementWidth = g.size,
		elementHeight = g.size,
		elementSpacing = 3,
		lineSpacing = g.gap or ZPerl.AuraGap(),
		layoutIndex = g.layoutIndex,
	}
end

-- ZPerl.AuraContainerCreate(self, holderKey, name, groups, lineSize)
-- Builds a holder + AuraContainer pair holding the groups of ZPerl.AurasGroups; caller positions the
-- holder. Every frame goes through here so the five requirements that each silently break rendering
-- live in one place: keep all five when changing anything here.
function ZPerl.AuraContainerCreate(self, holderKey, name, groups, lineSize)
	local level = self:GetFrameLevel() + 10
	local holder = self[holderKey]
	if (not holder) then
		-- the stand-in (ZPerl.AuraStandIn) has no such template, and needs none
		holder = CreateFrame("Frame", nil, self, (not ZPerl.AuraStandIn) and "DisableUntrustedLayoutScriptsTemplate" or nil)
		self[holderKey] = holder
	end
	holder:SetFrameLevel(level)
	holder:Show()

	-- cfg[key] is the group's current spec; its buttons' init reads it
	local container = name and _G[name]
	local cfg
	-- the buttons of a frame whose classic buttons took right-click (Target's buffs) cancel the player's own buff
	local cancel = holderKey == "buffHalfFrame" and self.auraCancel or false
	local function addGroup(g)
		cfg[g.key] = g
		container:AddAuraGroup(g.key, g.filter, {
			maxFrameCount = g.maxFrameCount,
			layout = groupLayout(g),
			candidateFilters = g.candidateFilters,
			initializeFrame = function(button)
				local cg = cfg[g.key]
				ZPerl.AuraContainerInitButtonCommon(button, cg, cancel)
			end,
		})
	end

	-- Frames cannot be destroyed, so a rebuild reconfigures the existing container;
	-- creating a new one each time leaked about 84 frames per container per reset.
	if (container and container.zperlAuraCfg) then
		if (not ZPerl.AuraContainerGate(self)) then
			return container, holder
		end
		cfg = container.zperlAuraCfg
		container:SetFrameLevel(level)
		container:SetUnit(self.partyid)
		-- groups are never removed: those the spec no longer asks for are disabled
		local wanted = {}
		for _, g in ipairs(groups) do
			wanted[g.key] = true
		end
		for key in pairs(cfg) do
			if (not wanted[key] and container:IsAuraGroupEnabled(key)) then
				container:SetAuraGroupEnabled(key, false)
			end
		end
		for _, g in ipairs(groups) do
			if (not container:HasAuraGroup(g.key)) then
				addGroup(g)
			else
				local old = cfg[g.key]
				cfg[g.key] = g
				if (not container:IsAuraGroupEnabled(g.key)) then
					container:SetAuraGroupEnabled(g.key, true)
				end
				container:SetAuraGroupFilterString(g.key, g.filter)
				if (not sameFilters(old and old.candidateFilters, g.candidateFilters)) then
					container:SetAuraGroupCandidateFilters(g.key, g.candidateFilters or {})
				end
				container:SetAuraGroupMaxFrameCount(g.key, g.maxFrameCount)
				container:SetAuraGroupLayout(g.key, groupLayout(g))
				for i = 1, container:GetAuraGroupFrameCount(g.key) do
					ZPerl.AuraContainerInitButtonCommon(container:GetAuraGroupFrame(g.key, i), g, cancel)
				end
			end
		end
		if (container.SetFlowLayoutMaximumLineSize) then
			container:SetFlowLayoutMaximumLineSize(lineSize)
		end
		return container, holder
	end

	cfg = {}
	if (ZPerl.AuraStandIn) then
		container = ZPerl.CreateAuraContainerStandIn(name, holder)
	else
		container = CreateFrame("AuraContainer", name, holder, "CustomAuraContainerTemplate,DisableUntrustedLayoutScriptsTemplate")
	end
	container.zperlAuraCfg = cfg
	container:ClearAllPoints()
	container:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
	container:SetFrameLevel(level)
	container:SetSize(1, 1)
	container:SetUnit(self.partyid)
	for _, g in ipairs(groups) do
		addGroup(g)
	end
	if (container.SetFlowLayoutMaximumLineSize) then
		container:SetFlowLayoutMaximumLineSize(lineSize)
	end
	return container, holder
end

-- ZPerl.HasClassicCooldownCount(): whether the Classic Cooldown Count addon is loaded. Asked as the aura
-- buttons are styled (after login, so a normally loaded addon has loaded by then).
function ZPerl.HasClassicCooldownCount()
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
	return loaded and loaded("ClassicCooldownCount") and true or false
end

-- ZPerl.AuraContainerInitButtonCommon(button, g, cancel)
-- g is the group spec of ZPerl.AurasGroups: size, cooldown (swipe) and countdown (duration text).
-- cancel: right-click cancels the aura. Runs again on every reconfigure.
-- An aura button arrives blank: no icon texture, no cooldown. Skip creating them
-- and it still sizes, lays out and tooltips correctly while drawing nothing at
-- all. Per-aura detail stays Blizzard's to draw.
function ZPerl.AuraContainerInitButtonCommon(button, g, cancel)
	if (not button) then
		return
	end
	local size, showSwipe = g.size, g.cooldown
	if (size) then
		button:SetSize(size, size)
	end
	if (not button.icon and button.SetIcon) then
		button.icon = button:CreateTexture(nil, "ARTWORK")
		button.icon:SetAllPoints(button)
		button:SetIcon(button.icon)
	end
	if (not button.cooldown and button.SetDurationCooldown) then
		button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
		button.cooldown:SetAllPoints(button)
		button.cooldown:SetReverse(true)
		button:SetDurationCooldown(button.cooldown)
	end
	-- Blizzard fills both strings, secret values included: the buff bar's gold
	-- duration text under the icon and its stack count.
	-- (zperlDuration: wowless gives button.durationText Blizzard's own table)
	if (not button.zperlDuration and button.SetDurationText) then
		button.zperlDuration = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		button.zperlDuration:SetPoint("TOP", button, "BOTTOM")
	end
	if (button.zperlDuration) then
		if (g.countdown) then
			button.zperlDuration:Show()
			button:SetDurationText(button.zperlDuration)
		elseif (button.ClearDurationText) then
			button:ClearDurationText()
			button.zperlDuration:Hide()
		end
	end
	-- tooltips off: the button ignores the mouse, and right-click cancel goes with it (the game shows a
	-- tooltip on every aura button that has the mouse)
	button:EnableMouse((ZPerl.layout and ZPerl.layout.tooltip and ZPerl.layout.tooltip.enableBuffs) and true or false)
	if (cancel and button.SetCancelAuraButtons) then
		button:SetCancelAuraButtons("RightButtonUp")
	end
	if (not button.countText and button.SetApplicationCount) then
		-- A region draws under every child frame of its parent, so the count sits
		-- on a frame above the cooldown swipe.
		local carrier = CreateFrame("Frame", nil, button)
		carrier:SetAllPoints(button)
		button.countCarrier = carrier
		button.countText = carrier:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		button.countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
		button:SetApplicationCount(button.countText)
	end
	-- the container moves its buttons to its own level when it is reconfigured: the children follow
	if (button.cooldown) then
		button.cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	end
	if (button.countCarrier) then
		button.countCarrier:SetFrameLevel(button:GetFrameLevel() + 2)
	end
	if (button.cooldown) then
		if (button.cooldown.SetDrawEdge) then
			button.cooldown:SetDrawEdge(false)
		end
		if (button.cooldown.SetDrawSwipe) then
			button.cooldown:SetDrawSwipe(showSwipe and true or false)
		end
		-- Countdown numbers on the cooldown frame, independent of the swipe and of Z-Perl's own
		-- duration text: buffs.blizzard shows Blizzard's numbers, buffs.omnicc lets OmniCC-style
		-- addons (anything that honors noCooldownCount) attach their text.
		-- Classic Cooldown Count restyles the game's own numbers on aura container icons, and leaves an
		-- icon alone while its addon hides them: with it loaded and buffs.omnicc on, the numbers stay shown.
		local bconf = ZPerl.layout and ZPerl.layout.buffs
		local omnicc = bconf and bconf.omnicc
		if (button.cooldown.SetHideCountdownNumbers) then
			local show = bconf and (bconf.blizzard or (omnicc and ZPerl.HasClassicCooldownCount()))
			button.cooldown:SetHideCountdownNumbers(not show)
		end
		button.cooldown.noCooldownCount = not omnicc or nil
	end
end

-- ZPerl.UnitFullName(unit)
-- Forever gives units a mandatory surname in UnitName's second return, joined
-- with a space as Blizzard displays it ("Ana Forever"). Always a space: the
-- player's own name arrives pre-combined, so it can't be used to detect which
-- convention is live. On retail the second return is the realm of a cross-realm
-- player, which Z-Perl leaves off as Blizzard's own unit frames do.
--
-- In combat Forever makes both returns secret for an indirect unit ("targettarget",
-- "focustarget"), while its GUID stays readable. So every full name read while it
-- is readable (through the player's own party, raid or target frame, or before the
-- fight) is kept by GUID, and a secret name is looked up there. Only names the
-- client showed readably are kept, so a lookup cannot show a wrong name. Failing
-- that, the two secret parts are joined (pcall: a client may refuse it); failing
-- that, the first name alone.
local fullNames = {} -- [GUID] = "First Surname"
local function joinSecret(n, s)
	return n .. " " .. s
end
function ZPerl.UnitFullName(unit)
	local n, s = UnitName(unit)
	if (ZPerl.IsRetail) then
		return n
	end
	if (CanAccess(n) and (s == nil or CanAccess(s))) then
		---@diagnostic disable-next-line: secret-comparison
		local full = (s and s ~= "") and (n .. " " .. s) or n
		local guid = UnitGUID(unit)
		if (full and guid and CanAccess(guid)) then
			---@diagnostic disable-next-line: secret-table-key
			fullNames[guid] = full
		end
		return full
	end
	local guid = UnitGUID(unit)
	---@diagnostic disable-next-line: secret-table-key
	if (guid and CanAccess(guid) and fullNames[guid]) then
		---@diagnostic disable-next-line: secret-table-key
		return fullNames[guid]
	end
	if (n and s) then
		local ok, joined = pcall(joinSecret, n, s)
		if (ok) then
			return joined
		end
	end
	return n
end
end -- restricted API support
