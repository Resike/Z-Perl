-- ZPerl.HitIndicator(self, action, descriptor, damage, damageType) - the hit text on a frame's portrait or name.
-- A readable amount goes to Blizzard's CombatFeedback_OnCombatEvent. A secret amount cannot (it compares
-- the amount), so the text is set here from the readable action and flags; the amount is only passed to
-- AbbreviateNumbers and SetText, which accept a secret. The damage-type color needs a readable type and
-- is not applied. The fade is CombatFeedback_OnUpdate, which reads only feedbackStartTime.
local IsSecret = ZPerl.IsSecret
-- Upvalues
local AbbreviateNumbers = AbbreviateNumbers
local CombatFeedback_OnCombatEvent = CombatFeedback_OnCombatEvent

local AMOUNT_COLOR = {
	WOUND = {1, 1, 1},
	HEAL = {0, 1, 0},
	ENERGIZE = {0.41, 0.8, 0.94},
}

-- ZPerl.HitTextAnchor(self, conf): where the hit text sits, by conf.hitIndicatorPos. "NAME": the centre of the name
-- frame. Otherwise (default) the centre the portrait has when shown: from the frame's portrait corner (the portrait
-- frame's own top corner, or the unit frame's when the layout has cleared the portrait frame's points; the right corner
-- when conf.flip), half the shown portrait width in and half its height down. Hiding the portrait does not move it.
function ZPerl.HitTextAnchor(self, conf)
	local fs = self.hitIndicator.text
	fs:ClearAllPoints()
	if conf.hitIndicatorPos == "NAME" then
		fs:SetPoint("CENTER", self.nameFrame, "CENTER", 0, 0)
		return
	end
	local pf = self.portraitFrame
	local half = (self.portraitW or 62) / 2
	local flip = conf.flip
	fs:SetPoint("CENTER", pf:GetNumPoints() > 0 and pf or self, flip and "TOPRIGHT" or "TOPLEFT",
		flip and -half or half, -pf:GetHeight() / 2)
end

function ZPerl.HitIndicator(self, action, descriptor, damage, damageType, conf)
	ZPerl.HitTextAnchor(self, conf)
	if not IsSecret(damage) then
		return CombatFeedback_OnCombatEvent(self, action, descriptor, damage, damageType)
	end
	local fs, height = self.feedbackText, self.feedbackFontHeight
	local color = AMOUNT_COLOR[action]
	local text
	if color then
		if descriptor == "CRITICAL" or (action == "WOUND" and descriptor == "CRUSHING") then
			height = height * 1.5
		elseif action == "WOUND" and descriptor == "GLANCING" then
			height = height * 0.75
		end
		text = AbbreviateNumbers(damage)
	else
		color = AMOUNT_COLOR.WOUND
		text = CombatFeedbackText[action] or ""
		if action == "IMMUNE" then
			height = height * 0.5
		elseif action == "BLOCK" then
			height = height * 0.75
		end
	end
	self.feedbackStartTime = GetTime()
	fs:SetTextHeight(height)
	fs:SetText(text)
	fs:SetTextColor(color[1], color[2], color[3])
	fs:SetAlpha(0.0)
	fs:Show()
end
