-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

-- The energy ticker: a spark that sweeps the player's energy bar once per server energy tick, so a rogue
-- or a cat druid sees when the next 20 energy lands.
-- Energy comes in 2 s ticks on the Classic-based clients (Classic Era, TBC, Forever). Retail and Mists
-- regenerate it smoothly, so the module does nothing there.
if (ZPerl.IsRetail or ZPerl.IsMists) then
	return
end

local pconf
ZPerl.RequestConfig(function(new)
	pconf = new.player
end, "$Revision:  $")

-- Upvalues
local CreateFrame = CreateFrame
local GetTime = GetTime
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

local CanAccess = ZPerl.CanAccess

local TICK = 2 -- seconds between energy ticks
local ENERGY = Enum.PowerType.Energy

-- The server ticks on its own clock whatever the form or the energy, so the state outlives form changes
-- and full energy: the spark keeps sweeping from the last tick seen.
local lastTick -- GetTime() of the last tick seen; nil until the first one
local lastEnergy -- the energy at the last power event; nil while it is unreadable
-- GetTime() of a tick-sized gain off the current tick clock: Wolfshead Helm (20) and Furor (40) on a shift
-- to Cat Form gain a tick's worth anywhere in the cycle. It moves the clock only once a later tick-sized
-- gain lands a whole number of ticks after it, so one stray gain never moves a clock that is right, and a
-- clock that is wrong (first set by a stray gain) corrects itself on the next two real ticks.
local candidate

local SLACK = 0.25 -- seconds a tick may land off the 2 s grid (event latency)

-- OnGrid(t, from): whether time t is a whole number of ticks after time from, within SLACK
local function OnGrid(t, from)
	local late = (t - from) % TICK
	return late < SLACK or late > TICK - SLACK
end

-- IsTickSize(gain, cur, max): whether an energy gain is the size of a regen tick. A tick is 20 energy (21
-- now and then from rounding), 40 under Adrenaline Rush; Combat Potency (15) and Relentless Strikes (25)
-- are not. A tick that hits the cap gains less, so any capped gain may be one.
local function IsTickSize(gain, cur, max)
	return (gain >= 19 and gain <= 22) or (gain >= 39 and gain <= 42) or (cur >= max and gain < 20)
end

-- TakeGain(gain, cur, max, now): moves the tick clock when the gain is a tick
local function TakeGain(gain, cur, max, now)
	if (not IsTickSize(gain, cur, max)) then
		return
	end
	local capped = cur >= max and gain < 19
	if (not lastTick) then
		-- the first tick seen; a capped gain is too unsure to start the clock on
		if (not capped) then
			lastTick = now
		end
	elseif (OnGrid(now, lastTick)) then
		lastTick, candidate = now, nil -- a tick where one is due: follows the server's small drift
	elseif (candidate and now - candidate > TICK - SLACK and OnGrid(now, candidate)) then
		lastTick, candidate = now, nil -- two gains a tick apart off the old clock: the clock was wrong
	elseif (not capped) then
		candidate = now
	end
end

-- the holder's OnUpdate: places the spark by the time since the last tick
local function SparkOnUpdate(holder)
	local bar = holder.bar
	local phase = ((GetTime() - lastTick) % TICK) / TICK
	holder.spark:SetPoint("CENTER", bar, "LEFT", bar:GetWidth() * phase, 0)
	holder.spark:SetHeight(bar:GetHeight() * 2.4)
end

-- Refresh(self): shows the spark while the player frame shows readable energy and a tick has been seen
local function Refresh(self)
	local holder = self.statsFrame.energyTick
	if (not holder) then
		return
	end
	if (pconf.energyTicker and lastTick and lastEnergy and self.partyid == "player"
		and ZPerl.GetDisplayedPowerType("player") == ENERGY) then
		holder:Show()
		holder.spark:Show()
	else
		holder:Hide()
		holder.spark:Hide()
	end
end

-- ReadEnergy(): the player's energy and max, or nil when they are secret
local function ReadEnergy()
	local cur, max = UnitPower("player", ENERGY), UnitPowerMax("player", ENERGY)
	if (CanAccess(cur) and CanAccess(max)) then
		return cur, max
	end
end

-- UNIT_POWER_FREQUENT: a rise of the player's energy that looks like a tick sets the tick clock
local function OnPower(self, unit, token)
	if (unit ~= "player" or token ~= "ENERGY") then
		return
	end
	local cur, max = ReadEnergy()
	---@diagnostic disable-next-line: secret-comparison
	if (cur and lastEnergy and cur > lastEnergy) then
		---@diagnostic disable-next-line: secret-arithmetic
		TakeGain(cur - lastEnergy, cur, max, GetTime())
	end
	lastEnergy = cur
	Refresh(self)
end

-- UNIT_DISPLAYPOWER: a form change resets the energy (Cat Form's Furor gives 40); take it as the new
-- baseline instead of a gain
local function OnDisplayPower(self)
	lastEnergy = ReadEnergy()
	Refresh(self)
end

-- the events follow the frame's units (the Power element registers the same ones); the handlers check the unit
ZPerl.Elements.PlayerEnergyTick = {
	events = {UNIT_POWER_FREQUENT = OnPower, UNIT_DISPLAYPOWER = OnDisplayPower},
}

-- MakeSpark(self): the spark on the mana bar (the player's power bar), over the fill and under the text
-- (OVERLAY -1 under the text's OVERLAY 0); a child frame only runs the OnUpdate while it is shown
local function MakeSpark(self)
	local bar = self.statsFrame.manaBar
	local spark = bar:CreateTexture(nil, "OVERLAY", nil, -1)
	spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	spark:SetBlendMode("ADD")
	spark:SetWidth(12)
	spark:Hide()
	local holder = CreateFrame("Frame", nil, bar)
	holder:Hide()
	holder.bar = bar
	holder.spark = spark
	holder:SetScript("OnUpdate", SparkOnUpdate)
	self.statsFrame.energyTick = holder
end

-- ZPerl.Player.EnergyTickSetup(self): SetBits calls it; follows the Energy ticker option
function ZPerl.Player.EnergyTickSetup(self)
	if (pconf.energyTicker) then
		if (not self.statsFrame.energyTick) then
			MakeSpark(self)
		end
		ZPerl.UnitFrameEnable(self, "PlayerEnergyTick")
		OnDisplayPower(self)
	else
		ZPerl.UnitFrameDisable(self, "PlayerEnergyTick")
		Refresh(self)
	end
end
