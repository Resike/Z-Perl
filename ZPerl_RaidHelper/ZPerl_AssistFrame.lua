-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local conf
ZPerl.RequestConfig(function(new)
	conf = new
end, "$Revision:  $")

local myClass
local playerAggro, petAggro
local doUpdate					-- In cases where we get multiple UNIT_TARGET events in 1 frame, we just set a flag and do during OnUpdate
local friendlyUnitList = {"player", "pet"}
local enemyUnitList = {}			-- Players with mobs targetted that target me
local wholeEnemyUnitList = { }			-- Players with mobs targetted
local currentPlayerAggro = { }

-- Upvalues
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers

-- ZPerl.RaidHelper.AssistsOnLoad(self)
function ZPerl.RaidHelper.AssistsOnLoad(self)
	if self.SetResizeBounds then
		self:SetResizeBounds(170, 40, 1000, 600)
	else
		self:SetMinResize(170, 40)
		self:SetMaxResize(1000, 600)
	end

	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")

	self:SetScript("OnEvent", ZPerl.RaidHelper.AssistsOnEvent)
	self:SetScript("OnMouseDown", ZPerl.RaidHelper.AssistsMouseDown)
	self:SetScript("OnMouseUp", ZPerl.RaidHelper.AssistsMouseUp)

	ZPerl.RaidHelper.AssistsOnLoad = nil
end

-- ZPerl.RaidHelper.SetFrameSides
function ZPerl.RaidHelper.SetFrameSides()
	if (ZPerl_Assists_Frame.LastSetView and ZPerl_Assists_Frame.LastSetView[1] == ZPerlRaidHelperDB.AssistsFrame and ZPerl_Assists_Frame.LastSetView[2] == ZPerlRaidHelperDB.TargettingFrame) then
		-- Frames the same from last time
		return
	end

	if (ZPerlRaidHelperDB.AssistsFrame == 1 or ZPerlRaidHelperDB.TargettingFrame == 1) then
		ZPerl_Assists_Frame:Show()

		ZPerl_Target_Targetting_ScrollFrame:ClearAllPoints()
		ZPerl_Target_Assists_ScrollFrame:ClearAllPoints()

		if (ZPerlRaidHelperDB.AssistsFrame == 1 and ZPerlRaidHelperDB.TargettingFrame == 1) then
			ZPerl_Target_Targetting_ScrollFrame:SetPoint("TOPLEFT", 4, -5)
			ZPerl_Target_Targetting_ScrollFrame:SetPoint("BOTTOMRIGHT", ZPerl_Assists_Frame, "BOTTOM", -0.5, 5)
			ZPerl_Target_Targetting_ScrollFrame:Show()

			ZPerl_Target_Assists_ScrollFrame:SetPoint("TOPLEFT", ZPerl_Assists_Frame, "TOP", 0.5, -5)
			ZPerl_Target_Assists_ScrollFrame:SetPoint("BOTTOMRIGHT", -4, 5)
			ZPerl_Target_Assists_ScrollFrame:Show()

			ZPerl_ScrollSeperator:Show()
			ZPerl_ScrollSeperator:ClearAllPoints()
			ZPerl_ScrollSeperator:SetPoint("TOPLEFT", ZPerl_Target_Targetting_ScrollFrame, "TOPRIGHT", 0, 0)
			ZPerl_ScrollSeperator:SetPoint("BOTTOMRIGHT", ZPerl_Target_Assists_ScrollFrame, "BOTTOMLEFT", 0, 0)
		else
			ZPerl_ScrollSeperator:Hide()

			if (ZPerlRaidHelperDB.AssistsFrame == 1) then
				ZPerl_Target_Assists_ScrollFrame:SetPoint("TOPLEFT", 4, -5)
				ZPerl_Target_Assists_ScrollFrame:SetPoint("BOTTOMRIGHT", -4, 5)
				ZPerl_Target_Assists_ScrollFrame:Show()
				ZPerl_Target_Targetting_ScrollFrame:Hide()
			else
				ZPerl_Target_Targetting_ScrollFrame:SetPoint("TOPLEFT", 4, -5)
				ZPerl_Target_Targetting_ScrollFrame:SetPoint("BOTTOMRIGHT", -4, 5)
				ZPerl_Target_Targetting_ScrollFrame:Show()
				ZPerl_Target_Assists_ScrollFrame:Hide()
			end
		end
	else
		ZPerl_Assists_Frame:Hide()
	end

	---@diagnostic disable-next-line: inject-field
	ZPerl_Assists_Frame.LastSetView = {ZPerlRaidHelperDB.AssistsFrame, ZPerlRaidHelperDB.TargettingFrame}
end

-- ToggleAssistsFrame()
function ZPerl.RaidHelper.ToggleAssistsFrame(param)
	if (param == "assists") then
		if (ZPerlRaidHelperDB.AssistsFrame == 1) then
			ZPerlRaidHelperDB.AssistsFrame = 0
		else
			ZPerlRaidHelperDB.AssistsFrame = 1
		end
	else
		if (ZPerlRaidHelperDB.TargettingFrame == 1) then
			ZPerlRaidHelperDB.TargettingFrame = 0
		else
			ZPerlRaidHelperDB.TargettingFrame = 1
		end
	end
end

-- ZPerl.RaidHelper.AssistsViewClose
function ZPerl.RaidHelper.AssistsViewOpen()
	ZPerlRaidHelperDB.AssistsFrame = 1
	ZPerlRaidHelperDB.TargettingFrame = 1
	ZPerl.RaidHelper.SetFrameSides()
	return true
end

function ZPerl.RaidHelper.AssistsViewClose()
	ZPerlRaidHelperDB.AssistsFrame = 0
	ZPerlRaidHelperDB.TargettingFrame = 0
	ZPerl.RaidHelper.SetFrameSides()
end

-- SortByClass(t1, t2)
local function SortByClass(t1, t2)
	-- enemy names are secret inside instances and cannot be
	-- compared, so they keep their scan order
	if (not ZPerl.CanAccess(t1[1]) or not ZPerl.CanAccess(t2[1])) then
		return false
	end
	if (t1[2] == t2[2]) then
		return t1[1] < t2[1]
	else
		local t1c = t1[2]
		local t2c = t2[2]
		if (t1c == myClass) then
			t1c = "A"..t1c
		elseif (t1c ~= "") then
			t1c = "B"..t1c
		else
			t1c = "Z"
		end
		if (t2c == myClass) then
			t2c = "A"..t2c
		elseif (t2c ~= "") then
			t2c = "B"..t2c
		else
			t2c = "Z"
		end

		return t1c..t1[1] < t2c..t2[1]
	end
end

-- ZPerl.RaidHelper.MakeAssistsString
function ZPerl.RaidHelper.MakeAssistsString(List, title)
	local text = title

	if (List ~= nil) then
		local lastClass
		local any = false
		local nAssists = #List
		if (nAssists > 0) then
			text = text.." "..nAssists
		end
		text = text.."\13"

		sort(List, SortByClass)

		for i, entry in ipairs(List) do
			-- a secret name (enemies inside instances) or class cannot be concatenated or used as a key
			local unit = {
				ZPerl.CanAccess(entry[1]) and entry[1] or UNKNOWNOBJECT,
				ZPerl.CanAccess(entry[2]) and entry[2] or "",
			}
			if (not any) then
				if (unit[2] == "") then
					text = text.."|c00FF0000"..unit[1]
				else
					text = text..ZPerl.ColorTable[unit[2]]..unit[1]
				end
				lastClass, any = unit[2], true
			else
				if (lastClass) then
					if (unit[2] == "" or lastClass ~= unit[2]) then
						lastClass = unit[2]

						if (unit[2] == "") then
							text = text.."\r|c00FF0000"..unit[1]
						else
							text = text.."\r"..ZPerl.ColorTable[unit[2]]..unit[1]
						end
					else
						text = text.." "..unit[1]
					end
				else
					text = text.." "..unit[1]

					lastClass = unit[2]
				end
			end
		end
	end

	return (text)
end

-- FillList
local function FillList(List, cFrame, title)
	local text = ZPerl.RaidHelper.MakeAssistsString(List, title)
	_G["ZPerl_Target_Assists_ScrollChild_"..cFrame.."Text"]:SetText(text)
end

-- ZPerl.RaidHelper.ShowAssists()
function ZPerl.RaidHelper.ShowAssists()
	if (ZPerlRaidHelperDB and (ZPerlRaidHelperDB.AssistsFrame == 1 or ZPerlRaidHelperDB.TargettingFrame == 1)) then
		if (ZPerlRaidHelperDB.AssistsFrame == 1 and ZPerl_Assists_Frame.assists ~= nil) then
			FillList(ZPerl_Assists_Frame.assists, "Assists", L["TOOLTIP_ASSISTING"])
		end

		if (ZPerlRaidHelperDB.TargettingFrame == 1 and ZPerl_Assists_Frame.targetting ~= nil) then
			local title
			---@diagnostic disable-next-line: secret-comparison
			if (#ZPerl_Assists_Frame.targetting > 0 and ZPerl_Assists_Frame.targetting[1][2] == "") then
				title = L["TOOLTIP_ENEMYONME"]
			else
				if (ZPerlRaidHelperDB.TargetCountersSelf == 0) then
					title = L["TOOLTIP_ALLONME"]
				else
					title = L["TOOLTIP_HEALERS"]
				end
			end

			FillList(ZPerl_Assists_Frame.targetting, "Targetting", title)
		end
	end
end

-- ZPerl.RaidHelper.AssistsMouseDown
function ZPerl.RaidHelper.AssistsMouseDown(self, button, param)
	if (button == "LeftButton") then
		if (not ZPerlRaidHelperDB or not ZPerlRaidHelperDB.AssistPinned or (IsAltKeyDown() and IsControlKeyDown() and IsShiftKeyDown())) then
			--if (param and (param == "TOPLEFT" or param == "BOTTOMLEFT" or param == "BOTTOMRIGHT")) then
			--	self:StartSizing(param)
			--else
				ZPerl_Assists_FrameAnchor:StartMoving()
			--end
		end

	elseif (button == "RightButton") then
		local n = self:GetName()
		if (n and strfind (n, "ZPerl_Target_Assists_ScrollChild_Targetting")) then
			param = "targetFrame"
		end

		if (param and param == "targetFrame") then
			if (ZPerlRaidHelperDB.TargetCountersSelf == 1) then
				ZPerlRaidHelperDB.TargetCountersSelf = 0
			else
				ZPerlRaidHelperDB.TargetCountersSelf = 1
			end
			ZPerl.RaidHelper.UpdateAssists()
			ZPerl.RaidHelper.ShowAssists()
		end
	end
end

-- ZPerl.RaidHelper.AssistsMouseUp
function ZPerl.RaidHelper.AssistsMouseUp(self, button)
	--ZPerl_Assists_Frame:StopMovingOrSizing()
	ZPerl_Assists_FrameAnchor:StopMovingOrSizing()
	if (ZPerl.SavePosition) then
		ZPerl.SavePosition(ZPerl_Assists_FrameAnchor)
	end

	-- ZPerl.RegisterScalableFrame(self, ZPerl_Assists_FrameAnchor, nil, nil, nil, true, true)
end

-- MakeFriendlyUnitList
local function MakeFriendlyUnitList()
	local start, prefix, total
	if IsInRaid() then
		start, prefix, total = 1, "raid", GetNumGroupMembers()
	else
		start, prefix, total = 0, "party", GetNumSubgroupMembers()
	end

	--friendlyUnitList = {"player", "pet"}
	--ZPerl.FreeTable(friendlyUnitList)
	--friendlyUnitList = ZPerl.GetReusableTable()
	friendlyUnitList = { }
	tinsert(friendlyUnitList, "player")
	tinsert(friendlyUnitList, "pet")

	local name, petname
	for i = start, total do
		if (i == 0) then
			name, petname = "player", "pet"
		else
			name, petname = prefix..i, prefix.."pet"..i
		end

		if (not ZPerl.SafeBool(UnitIsUnit(name, "player"), false)) then
			if (UnitExists(name)) then
				tinsert(friendlyUnitList, name)
			end
			if (UnitExists(petname)) then
				tinsert(friendlyUnitList, petname)
			end
		end
	end
end

-- Events
function ZPerl.RaidHelper.AssistsOnEvent(self, event, unit)
	-- UNIT_TARGET's own unit argument can itself be an
	-- indirect unit like "targettarget" (Confirmed crashing
	-- exactly there) -- this was wrongly judged low-risk earlier in this
	-- session on the assumption unit would always be a direct party/raid
	-- member; the live crash disproves that.
	if (event == "PLAYER_TARGET_CHANGED" or (event == "UNIT_TARGET" and not ZPerl.SafeBool(UnitIsUnit(unit, "player"), true))) then
		doUpdate = true
	elseif (event == "VARIABLES_LOADED") then
		MakeFriendlyUnitList()
		ZPerl.RaidHelper.UpdateAssists()
		ZPerl.RaidHelper.ShowAssists()

		ZPerl.RegisterScalableFrame(self, ZPerl_Assists_FrameAnchor, nil, nil, nil, true, true)
		self.corner.onSizeChanged = function(_, x, y)
			ZPerlRaidHelperDB.sizeAssistsX = x
			ZPerlRaidHelperDB.sizeAssistsY = y
		end
		self.corner.onScaleChanged = function(_, s)
			ZPerlRaidHelperDB.sizeAssistsS = s
		end
		ZPerl_AssistPin:SetButtonTex()
	elseif (event == "GROUP_ROSTER_UPDATE") then
		MakeFriendlyUnitList()
		doUpdate = true
	elseif (event == "PLAYER_DEAD" or event == "PLAYER_REGEN_ENABLED") then
		--ZPerl.FreeTable(currentPlayerAggro)
		--currentPlayerAggro = ZPerl.GetReusableTable()
		currentPlayerAggro = { }
		if (ZPerl_Highlight) then
			ZPerl_Highlight:ClearAll("AGGRO")
		end
		ZPerl.RaidHelper.UpdateAssists()
		ZPerl.RaidHelper.ShowAssists()
	elseif (event == "PLAYER_ENTERING_WORLD") then
		if (ZPerl_Highlight) then
			ZPerl_Highlight:ClearAll("AGGRO")
		end

		MakeFriendlyUnitList()
		doUpdate = true
	end
end

-- ZPerl.RaidHelper.AssistsOnUpdate
local UpdateTime = 0
function ZPerl.RaidHelper.AssistsOnUpdate(self, arg1)
	UpdateTime = arg1 + UpdateTime
	if (doUpdate or UpdateTime >= 0.2) then
		if (doUpdate or #enemyUnitList > 0) then
			doUpdate = false
			ZPerl.RaidHelper.UpdateAssists()
			ZPerl.RaidHelper.ShowAssists()
		end
		UpdateTime = 0
	end
end

---------------------------------
-- Targetting counters         --
---------------------------------

local assists
local targetting

-- FoundEnemyBefore
local function FoundEnemyBefore(FoundEnemy, name)
	-- same indirect-unit secret-boolean risk as the rest of
	-- this file; this helper is called from every site already fixed above.
	for previous in pairs(FoundEnemy) do
		if (ZPerl.SafeBool(UnitIsUnit(previous.."target", name.."target"), false)) then
			return true
		end
	end
	return false
end

-- AddEnemy
local function AddEnemy(anyEnemy, FoundEnemy, name)
	local namet = name.."target"
	local namett = namet.."target"
	if (not FoundEnemyBefore(wholeEnemyUnitList, name)) then
		if (UnitExists(namet)) then
			wholeEnemyUnitList[name] = true

			if (ZPerl_Highlight and conf and conf.highlight.AGGRO) then
				-- same doubly-indirect secret-boolean risk as
				-- below; fixed proactively alongside the confirmed crash.
				if (ZPerl.SafeBool(UnitInRaid(namett), false) or ZPerl.SafeBool(UnitInParty(namett), false)) then
					local aggroName = UnitName(namett)
					if (aggroName and ZPerl.CanAccess(aggroName)) then
						---@diagnostic disable-next-line: secret-table-key
						currentPlayerAggro[aggroName] = UnitGUID(namett)
					end
				end
			end
		end
	end

	-- namett (name.."target".."target") is doubly indirect --
	-- an even higher secret-boolean risk than the single-indirect units
	-- already fixed above (section 3). Confirmed crashing on
	-- UnitIsUnit("target", "playertargettarget").
	if (ZPerl.SafeBool(UnitIsUnit("player", namett), false)) then
		if (not FoundEnemyBefore(FoundEnemy, name)) then
			if (not playerAggro and ZPerlRaidHelperDB.AggroWarning == 1) then
				playerAggro = true
				ZPerl_AggroPlayer:Show()
			end

			FoundEnemy[name] = true
			tinsert(targetting, {UnitName(namet), ""})
			return true
		end
	-- 1.8.3 Added check to see if mob is targetting our target, and add to that list
	elseif (UnitExists("target") and ZPerl.SafeBool(UnitIsUnit("target", namett), false)) then
		-- We can still use the FoundEnemy list, because it's not too important if
		-- we're targetting ourself and the mob doesn't show on both self and target lists
		if (not FoundEnemyBefore(FoundEnemy, name)) then
			FoundEnemy[name] = true
			tinsert(assists, {UnitName(namet), ""})
			return true
		end
	elseif (not petAggro and ZPerlRaidHelperDB.AggroWarning == 1 and UnitExists(namett) and ZPerl.SafeBool(UnitIsUnit("pet", namett), false)) then
		petAggro = true
		--petFadeStart = GetTime()
		ZPerl_AggroPet:Show()
	end

	return false
end

local HealerClasses = {PRIEST = true, SHAMAN = true, PALADIN = true, DRUID = true}

-- ZPerl.RaidHelper.UpdateAssists
function ZPerl.RaidHelper.UpdateAssists()
	--ZPerl.FreeTable(wholeEnemyUnitList)
	--wholeEnemyUnitList = ZPerl.GetReusableTable()
	wholeEnemyUnitList = { }

	local oldPlayerAggro = currentPlayerAggro
	--currentPlayerAggro = ZPerl.GetReusableTable()
	currentPlayerAggro = { }
	if ZPerlRaidHelperDB and ZPerlRaidHelperDB.TargetCounters == 0 then
		if (ZPerl_Target_AssistFrame) then
			ZPerl_Target_AssistFrame:Hide()
		end
		if (ZPerl_Player_TargettingFrame) then
			ZPerl_Player_TargettingFrame:Hide()
		end
		return
	end

	local selfFlag, enemyFlag
	if ZPerlRaidHelperDB then
		selfFlag = ZPerlRaidHelperDB.TargetCountersSelf == 1
		enemyFlag = ZPerlRaidHelperDB.TargetCountersEnemy == 1
	end

	local assistCount, targettingCount, anyEnemy = 0, 0, false
	--local start, i, total, prefix, name, petname

	--local FoundEnemy = ZPerl.GetReusableTable()
	local FoundEnemy = { }

	-- Re-use all the old tables from last pass
	--assists = ZPerl_Assists_Frame.assists
	--targetting = ZPerl_Assists_Frame.targetting
	--ZPerl.FreeTable(assists)
	--ZPerl.FreeTable(targetting)
	--assists = { }
	--targetting = { }

	-- Get new tables
	--assists = ZPerl.GetReusableTable()
	assists = { }
	--targetting = ZPerl.GetReusableTable()
	targetting = { }

	playerAggro, petAggro = false, false

	local targetname = UnitName("target")
	for i, name in pairs(friendlyUnitList) do
		if (UnitExists(name.."target") and not UnitIsDeadOrGhost(name)) then
			local _, engClass = UnitClass(name)

			-- name.."target" is an indirect unit -- these
			-- three UnitIsUnit/UnitCanAttack booleans can be secret (section
			-- 3), Confirmed crashing on UnitIsUnit("target",
			-- "playertarget").
			if (targetname) then
				if (ZPerl.SafeBool(UnitIsUnit("target", name.."target"), false)) then
					assistCount = assistCount + 1
					tinsert(assists, {UnitName(name), engClass})
				end
			end

			-- 0 for Anyone, 1 for Healers
			---@diagnostic disable-next-line: secret-table-key
			if (not selfFlag or (ZPerl.CanAccess(engClass) and HealerClasses[engClass])) then
				if (ZPerl.SafeBool(UnitIsUnit("player", name.."target"), false)) then
					targettingCount = targettingCount + 1
					tinsert(targetting, {UnitName(name), engClass})
				end
			end

			-- Count enemy targetting us?
			if (enemyFlag) then
				if (ZPerl.SafeBool(UnitCanAttack("player", name.."target"), false)) then	-- not UnitIsFriend("player", name.."target")) then
					if (AddEnemy(anyEnemy, FoundEnemy, name)) then
						anyEnemy = true
						targettingCount = targettingCount + 1
					end
				end
			end
		end
	end

	if (enemyFlag) then
		-- same indirect-unit secret-boolean shape as above;
		-- "focustarget" is indirect too. Default to "friend"/"not a match" so
		-- an unreadable state just skips the aggro warning rather than
		-- risking a false one.
		if (not ZPerl.SafeBool(UnitIsFriend("player", "focus"), true)) then
			if (ZPerl.SafeBool(UnitIsUnit("player", "focustarget"), false)) then
				if (ZPerl_Highlight and conf and conf.highlight.AGGRO) then
					currentPlayerAggro[UnitName("player")] = UnitGUID("player")
				end

				if (not FoundEnemyBefore(FoundEnemy, "focus")) then
					if (not playerAggro and ZPerlRaidHelperDB.AggroWarning == 1) then
						playerAggro = true
						ZPerl_AggroPlayer:Show()
					end

					FoundEnemy["focus"] = true
					tinsert(targetting, {UnitName("focus"), ""})
					-- counted as the raid loop counts an AddEnemy hit; returning here (as AddEnemy does) skipped
					-- the rest of the update: the lists, the aggro highlights and the counters stayed stale
					anyEnemy = true
					targettingCount = targettingCount + 1
				end
			end
		end
	end

	---@diagnostic disable-next-line: inject-field
	ZPerl_Assists_Frame.assists, ZPerl_Assists_Frame.targetting = assists, targetting

	if (playerAggro or petAggro) then
		ZPerl_Aggro:Show()
	end

	enemyUnitList = FoundEnemy

	if (ZPerl_Highlight and conf and conf.highlight.AGGRO) then
		for k, v in pairs(oldPlayerAggro) do
			---@diagnostic disable-next-line: secret-table-key
			if (not currentPlayerAggro[k]) then
				ZPerl_Highlight:Remove(v, "AGGRO")
			end
		end
		for k, v in pairs(currentPlayerAggro) do
			if (not oldPlayerAggro[k]) then
				ZPerl_Highlight:Add(v, "AGGRO", 0)
			end
		end
	end

	if ZPerlRaidHelperDB and ZPerlRaidHelperDB.ShowTargetCounters == 1 then
		if (ZPerl_Player_TargettingFrame) then
			if (ZPerl_Player) then
				local color = (conf and conf.color.border) or (ZPerlRaidHelperDB and ZPerlRaidHelperDB.BorderColor) or {r = 0.5, g = 0.5, b = 0.5}

				if (anyEnemy) then
					ZPerl_Player_TargettingFrame:SetBackdropBorderColor(1, 0.2, 0.2, color.a)
				else
					ZPerl_Player_TargettingFrame:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
				end

				if (targettingCount == 0) then
					ZPerl_Player_TargettingFrametext:SetTextColor(1, 0.5, 0.5, conf.transparency.text)
				elseif (targettingCount > 5) then
					ZPerl_Player_TargettingFrametext:SetTextColor(0.5, 1, 0.5, conf.transparency.text)
				else
					ZPerl_Player_TargettingFrametext:SetTextColor(0.5, 0.5, 1, conf.transparency.text)
				end

				ZPerl_Player_TargettingFrame:SetText(tostring(targettingCount))
				ZPerl_Player_TargettingFrame:Show()
			else
				ZPerl_Player_TargettingFrame:Hide()
			end
		end

		if (ZPerl_Target_AssistFrame) then
			if (ZPerl_Target) then
				if (assistCount < 2) then
					ZPerl_Target_AssistFrametext:SetTextColor(1, 0.5, 0.5, conf.transparency.text)
				elseif (assistCount > (#friendlyUnitList / 2)) then
					ZPerl_Target_AssistFrametext:SetTextColor(0.5, 1, 0.5, conf.transparency.text)
				else
					ZPerl_Target_AssistFrametext:SetTextColor(0.5, 0.5, 1, conf.transparency.text)
				end

				if (targetname) then
					ZPerl_Target_AssistFrame:SetText(tostring(assistCount))
				end
				ZPerl_Target_AssistFrame:Show()
			else
				ZPerl_Target_AssistFrame:Hide()
			end
		end
	else
		ZPerl_Player_TargettingFrame:Hide()
		ZPerl_Target_AssistFrame:Hide()
	end

	--ZPerl.FreeTable(oldPlayerAggro)
	--ZPerl.FreeTable(FoundEnemy)
end

-- ZPerl.RaidHelper.AssistsGetEnemyUnitList
function ZPerl.RaidHelper.AssistsGetEnemyUnitList()
	return wholeEnemyUnitList
end

-- ZPerl.RaidHelper.StartAssists
function ZPerl.RaidHelper.StartAssists()
	local _
	_, myClass = UnitClass("player")

	ZPerl.ColorTable.pet = "|c008080FF"

	if (ZPerl.RegisterPerlFrames) then
		ZPerl.RegisterPerlFrames(ZPerl_Assists_Frame)
	end

	ZPerl.RaidHelper.SetFrameSides()
end

-- ZPerl.RaidHelper.RefreshAggro
function ZPerl.RaidHelper.RefreshAggro(self)
	if (playerAggro) then
		ZPerl_AggroPlayer:SetVertexColor(1, 0, 0, 1)
	else
		if (self.playerFadeStart) then
			local elapsed = GetTime() - self.playerFadeStart
			if (elapsed < 1) then
				ZPerl_AggroPlayer:SetVertexColor(0, 1, 0, 1 - elapsed)
			else
				ZPerl_AggroPlayer:Hide()
				self.playerFadeStart = nil
				if (not ZPerl_AggroPet:IsShown()) then
					self:Hide()
				end
			end
		else
			self.playerFadeStart = GetTime()
		end
	end
	if (petAggro) then
		ZPerl_AggroPet:SetVertexColor(1, 0, 0, 1)
	else
		if (self.petFadeStart) then
			local elapsed = GetTime() - self.petFadeStart
			if (elapsed < 1) then
				ZPerl_AggroPet:SetVertexColor(0, 1, 0, 1 - elapsed)
			else
				ZPerl_AggroPet:Hide()
				self.petFadeStart = nil
				if (not ZPerl_AggroPlayer:IsShown()) then
					self:Hide()
				end
			end
		else
			self.petFadeStart = GetTime()
		end
	end
end
