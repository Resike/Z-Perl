-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local pconf
ZPerl.RequestConfig(function(new)
	pconf = new.player
end, "$Revision:  $")

--local playerClass

--[===[@debug@
local function d(fmt, ...)
	fmt = fmt:gsub("(%%[sdqxf])", "|cFF60FF60%1|r")
	ChatFrame1:AddMessage("|cFFFF8080PlayerBuffs:|r "..format(fmt, ...), 0.8, 0.8, 0.8)
end
--@end-debug@]===]

-- The aura element (ZPerl_Unit.lua) draws the auras; these are its settings for the player frame.
-- the extra rows under the frame (druid / priest mana bar, reputation, experience) that BOTTOM blocks clear
local function Inset(self, side)
	if (side ~= "BOTTOM" or pconf.extendPortrait) then
		return 0
	end
	local _, playerClass = UnitClass("player")
	local extraBar = ((playerClass == "DRUID" or playerClass == "PRIEST") and UnitPowerType(self.partyid) > 0 and not pconf.noDruidBar) and 1 or 0
	return (extraBar + (pconf.repBar and 1 or 0) + (pconf.xpBar and 1 or 0)) * 13.5
end

local function ApplyPosition(self)
	if (self.playerBuffsOn) then
		ZPerl.AurasPlace(self)
	end
end

-- ZPerl.PlayerBuffs.Position: the anchors are protected; applied after combat from the then-current state
function ZPerl.PlayerBuffs.Position(self)
	ZPerl.AfterCombat(ApplyPosition, self)
end


-- ZPerl.PlayerBuffs.PlayerBuffSetup
function ZPerl.PlayerBuffs.PlayerBuffSetup(self)
	-- Player off: Blizzard's buff frames stay, nothing of ours replaces them
	if (not self or self.off) then
		return
	end

	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.PlayerBuffs.PlayerBuffSetup, self)
		return
	end

	self.playerBuffsOn = true

	-- the aura element; debuffs only show with buffs on
	self.auraInset = Inset
	self.auraDebuffsNeedBuffs = true
	self.auraCancel = true -- right-click cancels a buff, as on Blizzard's buff frame
	ZPerl.UnitFrameEnable(self, "Auras")

	-- (re)build the AuraContainer fallback so it picks up any
	-- option change; no-ops on clients without it, deferred while secret.
	ZPerl.AurasRebuild(self)

	ZPerl.PlayerBuffs.Position(self)
	ZPerl.AurasUpdate(self)

	ZPerl.BlizzFrameHide(BuffFrame, pconf.buffs.hideBlizzard)
	ZPerl.BlizzFrameHide(_G.DebuffFrame, pconf.buffs.hideBlizzard)
	-- Classic Era's weapon enchant icons are a frame of their own
	ZPerl.BlizzFrameHide(_G.TemporaryEnchantFrame, pconf.buffs.hideBlizzard)
end

local function SetBits(self)
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(SetBits, self)
		return
	end

	--local _, class = UnitClass("player")
	--playerClass = class

	ZPerl.PlayerBuffs.PlayerBuffSetup(self)

	ZPerl.PlayerBuffs.Position(self)
	ZPerl.AurasUpdate(self)
end


ZPerl.RegisterOptionChanger(SetBits, ZPerl_Player, "playerbuffs")
