-- Weapon enchants (rogue poisons, oils, stones) at the start of the Player frame's buff line. They are
-- not auras, so the aura container never shows them; Blizzard's buff frame reads them from
-- C_Item.GetWeaponEnchantInfo, and so does this block. Plain addon buttons: shown and cancelled in combat
-- without taint. The block is the frame's aura spacer (ZPerl.AurasPlace): the buff holder hangs off its
-- far end, so sizing the block to its icons moves the buffs, also in combat. When the buffs are not the
-- block nearest the frame, ZPerl.AurasPlace sets no flow and the block sits apart, left of the frame.
-- ponytail: wrapped buff lines shift with the first one, so a full line runs past the frame's edge by the enchants' width.

ZPerl.Enchants = {}

local INV = {[0] = 16, [1] = 17, [2] = 18} -- Enum.WeaponSlot -> inventory slot
local PAD, GAP = 3, 12 -- After each icon; room for the duration text under an icon in a column

local block = CreateFrame("Frame", "ZPerl_PlayerEnchants", ZPerl_Player)
block.buttons = {}
block:SetSize(1, 1)
ZPerl_Player.auraSpacer = block

local function onClick(self, button)
	-- Both are documented HasRestrictions; a refusal raises in the client. Retail 12.1 replaced
	-- C_Spell.CancelItemTempEnchantment(weapon slot, type) with C_PaperDollInfo.CancelTemporaryEnchantment(inventory slot).
	if (button == "RightButton" and self.slot) then
		if (C_Spell and C_Spell.CancelItemTempEnchantment) then
			C_Spell.CancelItemTempEnchantment(self.slot, self.enchantType or 0)
		elseif (C_PaperDollInfo and C_PaperDollInfo.CancelTemporaryEnchantment) then
			C_PaperDollInfo.CancelTemporaryEnchantment(INV[self.slot])
		elseif (CancelItemTempEnchantment and not InCombatLockdown()) then
			-- Classic Era: 1 main hand, 2 off hand, 3 ranged
			CancelItemTempEnchantment(self.slot + 1)
		end
	end
end

local function onEnter(self)
	if (not (ZPerl.layout.tooltip and ZPerl.layout.tooltip.enableBuffs)) then
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetInventoryItem("player", INV[self.slot])
	GameTooltip:Show()
end

local function onLeave()
	GameTooltip:Hide()
end

local function button(i)
	local b = block.buttons[i]
	if (b) then
		return b
	end
	b = CreateFrame("Button", nil, block)
	b:RegisterForClicks("AnyUp")
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints()
	b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
	b.duration = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	b.duration:SetPoint("TOP", b, "BOTTOM")
	b:SetScript("OnClick", onClick)
	b:SetScript("OnEnter", onEnter)
	b:SetScript("OnLeave", onLeave)
	block.buttons[i] = b
	return b
end

-- enchantsOf(slot): the enchants on weapon slot (Enum.WeaponSlot 0 main hand, 1 off hand, 2 ranged) as a list of
-- {hasEnchant, enchantType, charges, timeLeft (ms)}, from whichever API the client has:
-- C_Item.GetWeaponEnchantInfo (Forever), C_PaperDollInfo.GetTemporaryEnchantmentInfo (retail 12.1),
-- or the global GetWeaponEnchantInfo, four values per slot (Classic Era).
local function enchantsOf(slot)
	if (C_Item and C_Item.GetWeaponEnchantInfo) then
		local ok, list = pcall(C_Item.GetWeaponEnchantInfo, slot)
		return ok and type(list) == "table" and list or {}
	end
	if (C_PaperDollInfo and C_PaperDollInfo.GetTemporaryEnchantmentInfo) then
		local ok, info = pcall(C_PaperDollInfo.GetTemporaryEnchantmentInfo, INV[slot])
		if (ok and info) then
			return {{hasEnchant = true, enchantType = 0, charges = info.chargesRemaining, timeLeft = info.remainingTimeMs}}
		end
		return {}
	end
	if (GetWeaponEnchantInfo) then
		local values = {GetWeaponEnchantInfo()}
		local i = slot * 4 + 1
		if (values[i]) then
			return {{hasEnchant = true, enchantType = 0, charges = values[i + 2], timeLeft = values[i + 1]}}
		end
	end
	return {}
end

local function durationText(ms)
	if (not ms or ms <= 0) then
		return ""
	end
	return format(SecondsToTimeAbbrev(ms / 1000))
end

function ZPerl.Enchants.Update()
	---@diagnostic disable-next-line: undefined-field
	local c = ZPerl_Player.conf
	-- The 1 s ticker and the bus events can run before the profile is handed out
	if (not c) then
		return
	end
	local on = not ZPerl_Player.off and c.buffs.enable and c.enchants and c.enchants.enable
	local size = c.buffs.size or 25
	-- Along the buff line (the flow ZPerl.AurasPlace set), or a column left of the frame
	---@diagnostic disable-next-line: undefined-field
	local flow = ZPerl_Player.auraSpacerFlow
	local point, dx, dy
	if (flow) then
		point = flow.point
		dx, dy = flow.rows and flow.h * (size + PAD) or 0, flow.rows and 0 or flow.v * (size + PAD + GAP)
	else
		point, dx, dy = "TOPRIGHT", 0, -(size + PAD + GAP)
		block:ClearAllPoints()
		block:SetPoint("TOPRIGHT", ZPerl_Player, "TOPLEFT", -PAD, 0)
	end
	local n = 0
	if (on) then
		for slot = 0, 2 do
			for _, e in ipairs(enchantsOf(slot)) do
				if (e.hasEnchant) then
					local b = button(n + 1)
					b.slot, b.enchantType = slot, e.enchantType
					b:SetSize(size, size)
					b:ClearAllPoints()
					b:SetPoint(point, block, point, n * dx, n * dy)
					b.icon:SetTexture(GetInventoryItemTexture("player", INV[slot]))
					b.count:SetText(e.charges and e.charges > 0 and e.charges or "")
					b.duration:SetText(durationText(e.timeLeft))
					b:Show()
					n = n + 1
				end
			end
		end
	end
	for i = n + 1, #block.buttons do
		block.buttons[i]:Hide()
		block.buttons[i].slot = nil
	end
	-- The spacer's length along the line is what moves the buffs; the 1 is the step ZPerl.AurasPlace
	-- takes back (a frame of length 0 has no rect)
	if (flow and flow.rows) then
		block:SetSize(n * (size + PAD) + 1, size)
	elseif (flow) then
		block:SetSize(size, n * (size + PAD + GAP) + 1)
	else
		block:SetSize(size, max(n, 1) * (size + PAD + GAP))
	end
end

ZPerl_Player.onAurasPlaced = ZPerl.Enchants.Update
ZPerl.On("UNIT_INVENTORY_CHANGED", function(_, unit)
	if (unit == "player") then
		ZPerl.Enchants.Update()
	end
end)
ZPerl.On("PLAYER_EQUIPMENT_CHANGED", ZPerl.Enchants.Update)
ZPerl.On("PLAYER_ENTERING_WORLD", ZPerl.Enchants.Update)
-- The enchant has no expiry event: the ticker counts the time down and drops an expired one
ZPerl.Every(1, ZPerl.Enchants.Update)

ZPerl.RegisterOptionChanger(ZPerl.Enchants.Update, nil, "playerenchants")
