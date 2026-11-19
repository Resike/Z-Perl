-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local conf, tconf
ZPerl.RequestConfig(function(new)
	conf = new
	tconf = conf.target
end, "$Revision:  $")

local CanAccess = ZPerl.CanAccess
local IsSecret = ZPerl.IsSecret
local SafeBool = ZPerl.SafeBool
-- Upvalues
local ipairs = ipairs
local max = max
local min = min
local pcall = pcall

local GetComboPoints = GetComboPoints
local GetCVar = GetCVar
local SetCVar = SetCVar
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local Enum = Enum

local ComboFrame = ComboFrame

-- Helper frame for the TargetCombo element (below)
local ComboEventFrame = CreateFrame("Frame")
-- Forever protects combo-point values. Reparenting or registering Blizzard's
-- ComboFrame from addon code taints its own update path, so leave that frame
-- entirely under Blizzard control and use Z-Perl's independent displays.
-- Forever still creates Blizzard's legacy combo-point widget, but touching that
-- protected frame from addon code taints its secret-value update path.  The
-- client CVar is the safe, supported way to suppress it while our replacement
-- is active (1 = target, 2 = player, 0 = hidden).
local function ZPerl_HideBlizzardComboDisplay()
	-- Some Forever builds expose this CVar but clamp/ignore its hidden value.
	-- Keep setting it for builds which honor it, then make the legacy artwork
	-- transparent as a fallback.  SetAlpha does not alter the frame's event
	-- registration, parent, unit data, or protected update flow.
	if SetCVar and GetCVar then
		local ok, value = pcall(GetCVar, "comboPointLocation")
		if ok and value ~= nil and value ~= "" and value ~= "0" then
			ZPerl.Pcall(SetCVar, "comboPointLocation", 0)
		end
	end

	if ComboFrame and ComboFrame.SetAlpha then
		ZPerl.Pcall(ComboFrame.SetAlpha, ComboFrame, 0)
	end
end

-- GetComboColor
local function GetComboColor(num)
	if (num == 10) then
		return 0.3, 0, 1
	elseif (num == 9) then
		return 0.5, 0, 1
	elseif (num == 8) then
		return 0.7, 0, 1
	elseif (num == 7) then
		return 1, 0, 1
	elseif (num == 6) then
		return 1, 0, 0.5
	elseif (num == 5) then
		return 1, 0, 0
	elseif (num == 4) then
		return 1, 0.5, 0
	elseif (num == 3) then
		return 1, 1, 0
	elseif (num == 2) then
		return 0.5, 1, 0
	elseif (num == 1) then
		return 0, 1, 0
	end
end
---------------
-- Combo Points
---------------
local function UpdateCombo(self)
	local comboPoints = UnitPower("player", Enum.PowerType.ComboPoints)
	local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
	local hostile = SafeBool(UnitCanAttack(UnitHasVehicleUI("player") and "vehicle" or "player", "target"), true)
	local dead = SafeBool(UnitIsDeadOrGhost("target"), false)
	local showForeverCombo = tconf.combo.enable or tconf.comboindicator.enable or tconf.combo.blizzard

	if self.foreverCombo then
		if showForeverCombo and hostile and not dead then
			local visiblePoints = 5
			if CanAccess(maxComboPoints) then
				visiblePoints = max(1, min(7, maxComboPoints))
			end
			for i, point in ipairs(self.foreverCombo.points) do
				if i <= visiblePoints then
					point:SetMinMaxValues(i - 1, i)
					point:SetValue(comboPoints)
					if i == visiblePoints then
						point:SetStatusBarColor(1, 0.18, 0.05, 1)
					else
						point:SetStatusBarColor(1, 0.78, 0, 1)
					end
					point:Show()
				else
					point:Hide()
				end
			end
			self.foreverCombo:Show()
		else
			self.foreverCombo:Hide()
		end
	end

	-- comboPoints can be secret; GetComboColor's num == n chain can't
	-- run on it, but StatusBar:SetValue / FontString:SetText below accept it raw
	local r, g, b
	if not IsSecret(comboPoints) then
		r, g, b = GetComboColor(comboPoints)
	end
	if tconf.combo.enable and not IsSecret(comboPoints) and not dead and hostile then
		self.nameFrame.cpMeter:SetValue(comboPoints)
		self.nameFrame.cpMeter:Show()
		if r and g and b then
			self.nameFrame.cpMeter:SetStatusBarColor(r, g, b, 0.7)
		else
			self.nameFrame.cpMeter:Hide()
		end
	else
		self.nameFrame.cpMeter:Hide()
	end

	if tconf.comboindicator.enable and not IsSecret(comboPoints) and not dead and hostile then
		self.cpFrame:Show()
		self.cpFrame.text:SetText(comboPoints)
		if r and g and b then
			self.cpFrame.text:SetTextColor(r, g, b)
		else
			self.cpFrame:Hide()
		end
	else
		self.cpFrame:Hide()
	end
end
-- SetComboBar
local function SetComboBar(self)
	if not tconf.combo.enable then
		return
	end

	local comboPoints = GetComboPoints("player", "target")
	local maxComboPoints = UnitPowerMax("player", Enum.PowerType.ComboPoints)
	self.nameFrame.cpMeter:SetMinMaxValues(0, maxComboPoints)
	self.nameFrame.cpMeter:SetValue(comboPoints)
end

-- used by ZPerl_TargetUpdate.lua
ZPerl.Target.UpdateCombo = UpdateCombo

-- RegisterComboEvents
local function RegisterComboEvents(self)
	if not tconf.combo.blizzard and not tconf.combo.enable and not tconf.comboindicator.enable then
		ZPerl.UnitFrameDisable(ComboEventFrame, "TargetCombo")

		self.nameFrame.cpMeter:Hide()
		self.cpFrame:Hide()
		if self.foreverCombo then
			self.foreverCombo:Hide()
		end
		return
	end

	ZPerl.UnitFrameEnable(ComboEventFrame, "TargetCombo")

	ZPerl_HideBlizzardComboDisplay()

	if not tconf.combo.enable then
		self.nameFrame.cpMeter:Hide()
	else
		SetComboBar(self)
	end

	if not tconf.comboindicator.enable then
		self.cpFrame:Hide()
	end
end

ZPerl.Target.RegisterComboEvents = RegisterComboEvents

-- The combo events are unit events for "player" and "vehicle", not for the Target frame's own unit
-- ("target"): a helper frame with its own unit list carries them through the shared dispatcher.
local function comboRefresh(self, withBar)
	if UnitExists("target") and ZPerl_Target:IsShown() then
		if withBar then
			SetComboBar(ZPerl_Target)
		end
		UpdateCombo(ZPerl_Target)
	end
end
local function comboBar(self)
	comboRefresh(self, true)
end
ZPerl.Elements.TargetCombo = {
	events = {
		PLAYER_ENTERING_WORLD = function(self)
			ZPerl_HideBlizzardComboDisplay()
			comboBar(self)
		end,
		UNIT_POWER_FREQUENT = function(self, unit, powerType)
			if powerType == "COMBO_POINTS" then
				comboRefresh(self)
			end
		end,
		UNIT_MAXPOWER = comboBar,
		UNIT_ENTERED_VEHICLE = comboBar,
		UNIT_EXITED_VEHICLE = comboBar,
	},
	units = {UNIT_ENTERED_VEHICLE = {"player"}, UNIT_EXITED_VEHICLE = {"player"}},
}
ZPerl.UnitFrameInit(ComboEventFrame, {"player", "vehicle"}, {})
