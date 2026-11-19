-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

local L = ZPerl.L

local AddonName = ...

ZPerl.SetModuleRevision("$Revision:  $")

local SavedRoster = nil
local XswapCount = 0
local XmoveCount = 0
local XPendingRosters = 0
local WaitingForRoster
local XFinishedLoad

-- AdminCommands
local function AdminCommands(msg)
	local args = {}
	for value in string.gmatch(msg, "[^ ]+") do
		tinsert(args, string.lower(value))
	end

	if (not args[1]) then
			ZPerl_AdminFrame:Show()
	else
		if (not ZPerl.RaidAdmin.AdminCommands[args[1]] or not ZPerl.RaidAdmin.AdminCommands[args[1]](args[2], args[3], args[4])) then
			ZPerl.RaidAdmin.AdminCommands.help()
		end
	end
end

-- DefaultVar
local function DefaultVar(name, value)
	if (ZPerlRaidAdminDB[name] == nil or (type(value) ~= type(ZPerlRaidAdminDB[name]))) then
		ZPerlRaidAdminDB[name] = value
	end
end

-- Defaults
local function Defaults()

	if (not ZPerlRaidAdminDB) then
		ZPerlRaidAdminDB = {}
	end

	DefaultVar("AutoHideShow",	1)
	DefaultVar("SavedRosters",	{})
	DefaultVar("Transparency",	0.8)

	ZPerlRaidAdminDB.Scale_ItemCheck = nil
	ZPerlRaidAdminDB.Scale_Admin = nil
end

-- ZPerl.RaidAdmin.AdminOnLoad
function ZPerl.RaidAdmin.AdminOnLoad(self)
	self:RegisterForDrag("LeftButton")

	ZPerlRaidAdminDB = { }

	SlashCmdList["ZPERLRAIDADMIN"] = AdminCommands
	SLASH_ZPERLRAIDADMIN1 = "/rad"
	SLASH_ZPERLRAIDADMIN2 = "/zpadmin"
	SLASH_ZPERLRAIDADMIN3 = "/zpad"

	--self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	self:OnBackdropLoaded()
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

	self.Expand = function()
		ZPerl_AdminFrame_Controls:Show()
		ZPerl_AdminFrame_TitleBar_LockOpen:Show()
		self:SetWidth(140)
		self:SetHeight(150)
	end

	self.Collapse = function()
		ZPerl_AdminFrame_Controls:Hide()
		ZPerl_AdminFrame_TitleBar_LockOpen:Hide()
		self:SetWidth(140)
		self:SetHeight(18)
	end
	self:SetScript("OnEvent", ZPerl.RaidAdmin.AdminOnEvent)

	ZPerl.RaidAdmin.AdminOnLoad = nil
end

-- ZPerl.RaidAdmin.AdminStartup
local function AdminStartup(self)
	ZPerl.MigrateSavedNames(AddonName)
	Defaults()
	ZPerl_AdminFrame_TitleBar_Pin:SetButtonTex()

	ZPerl.RaidAdmin.CheckSetup()
	ZPerl.RaidAdmin.AdminSetupFrames()

	ZPerl.RegisterScalableFrame(self, ZPerl_AdminFrameAnchor)
	self.corner:SetParent(ZPerl_AdminFrame_Controls)

	self:SetWidth(140)
	self:SetHeight(18)

	AdminStartup = nil
end

-- SetupFrameSimple: local, RaidHelper defines a global of the same name with other defaults
local function SetupFrameSimple(self, alpha)
	self:OnBackdropLoaded()
	self:SetBackdropColor(0, 0, 0, alpha or 1)
	self:SetBackdropBorderColor(0.5, 0.5, 0.5, alpha or 1)
end

-- ZPerl.RaidAdmin.AdminSetupFrames()
function ZPerl.RaidAdmin.AdminSetupFrames()
	SetupFrameSimple(ZPerl_Check)
	SetupFrameSimple(ZPerl_CheckListItems)
	SetupFrameSimple(ZPerl_CheckListPlayers)

	SetupFrameSimple(ZPerl_AdminFrame)

	ZPerl_Check:SetAlpha(ZPerlRaidAdminDB.Transparency)
	ZPerl_AdminFrame:SetAlpha(ZPerlRaidAdminDB.Transparency)

	ZPerl.RaidAdmin.AdminSetupFrames = nil
end

-- Help
local function Help()
	ZPerl.Message("/rad [save | load name] [auto]")
end

-- ZPerl.RaidAdmin.AdminCheckMyRank
function ZPerl.RaidAdmin.AdminCheckMyRank()
	if (ZPerlRaidAdminDB.AutoHideShow == 1) then
		if (IsInRaid()) then
			local me = UnitName("player")
			for i = 1,GetNumGroupMembers() do
				local name, rank = GetRaidRosterInfo(i)
				if (name == me) then
					if (rank > 0) then
						ZPerl_AdminFrame:Show()
					else
						ZPerl_AdminFrame:Hide()
					end
					break
				end
			end
		else
			ZPerl_AdminFrame:Hide()
		end
	end
end

-- ToggleAuto
local function ToggleAuto()
	if (ZPerlRaidAdminDB.AutoHideShow == 1) then
		ZPerlRaidAdminDB.AutoHideShow = 0
	else
		ZPerlRaidAdminDB.AutoHideShow = 1
	end
	ZPerl.RaidAdmin.AdminCheckMyRank()
end

-- ZPerl.RaidAdmin.SaveRoster
function ZPerl.RaidAdmin.SaveRoster(saveName)

	if (not saveName or saveName == "") then
		local hours, mins = GetGameTime()
		saveName = hours..":"..mins
	end

	local Roster = {}

	for i = 1,GetNumGroupMembers() do
		local name, _, subgroup, _, _, fileName = GetRaidRosterInfo(i)
		Roster[name] = {group = subgroup, class = fileName}
	end

	if (not ZPerlRaidAdminDB.SavedRosters) then
		ZPerlRaidAdminDB.SavedRosters = {}
	end
	ZPerlRaidAdminDB.SavedRosters[saveName] = Roster

	ZPerl.Message(format(L["SAVED_ROSTER"], saveName))

	return true
end

local function LoadRoster()
	local swapCount = 0
	local moveCount = 0
	local CurrentRoster = {}
	local FreeFloating = {}

	-- Store the current raid roster, and a list of players in the raid, but not in the saved roster
	for i = 1,GetNumGroupMembers() do
		local name, _, subgroup, _, _, fileName = GetRaidRosterInfo(i)
		CurrentRoster[name] = {index = i, group = subgroup, class = fileName}

		if (not SavedRoster[name]) then
			-- Not in the saved roster, so doesn't matter where
			FreeFloating[name] = {group = subgroup, class = fileName}
		end
	end

	local function Swap(a, b)
	if (CurrentRoster[a] and CurrentRoster[b]) then
		SwapRaidSubgroup(CurrentRoster[a].index, CurrentRoster[b].index)
		local save = CurrentRoster[b].group
		CurrentRoster[b].group = CurrentRoster[a].group
		CurrentRoster[b].moved = true
		CurrentRoster[a].group = save
		CurrentRoster[a].moved = true

		if (FreeFloating[a]) then
			FreeFloating[a].group = CurrentRoster[a].group
		end
		if (FreeFloating[b]) then
			FreeFloating[b].group = CurrentRoster[b].group
		end

		swapCount = swapCount + 1
	end
	end

	local function Move(name, target)
		SetRaidSubgroup(CurrentRoster[name].index, target)
		CurrentRoster[name].group = target
		CurrentRoster[name].moved = true
		if (FreeFloating[name]) then
			FreeFloating[name].group = target
		end

		moveCount = moveCount + 1
	end

	local function GroupCount(grp)
		local count = 0
		for name,entry in pairs(CurrentRoster) do
			if (entry.group == grp) then
				count = count + 1
			end
		end
		return count
	end

	for nameSaved, saved in pairs(SavedRoster) do
	local name = nameSaved
	local group = saved.group

		if (not CurrentRoster[name]) then
		-- Saved player not in raid, so find someone of the same class in the free floater list
		for floaterName,floater in pairs(FreeFloating) do
			if (floater.class == saved.class) then
				name = floaterName
				FreeFloating[name] = nil
				break
			end
		end
	end

		if (CurrentRoster[name] and not CurrentRoster[name].moved) then
			if (CurrentRoster[name].group == group) then
				CurrentRoster[name].moved = true -- They're in right group already
			elseif (not FreeFloating[name]) then
			-- First see if we can directly swap any 2 players
				local swapName
				for name2, saved2 in pairs(SavedRoster) do
					if (name ~= name2) then
						if (CurrentRoster[name] and CurrentRoster[name].group == saved2.group) then
							if (CurrentRoster[name2] and CurrentRoster[name2].group == group) then
								swapName = name2
								break
							end
						end

					end
				end

				if (swapName) then
					Swap(name, swapName)
				--break
				else
				local done
					-- Nothing suitable found to swap, see if target group has space
					if (GroupCount(group) < 5) then
						Move(name, group)
					done = true
						--break
					end

					-- No space in target group, put them anywhere
					if (not done) then
						for i = 1,8 do
							if (CurrentRoster[name].group ~= i and GroupCount(i) < 5) then
								Move(name, i)
							done = true
								break
							end
						end
					end

					if (not done) then
					-- Nothing done yet, see if we can swap a free floater
					local free
					for name2, freeGroup in pairs(FreeFloating) do
						if (freeGroup ~= CurrentRoster[name2].group) then
							free = name2
							break
						end
					end
						if (free) then
							Swap(CurrentRoster[name].index, CurrentRoster[free].index)
						--break
						else
						-- Couldn't put them anywhere, add them to floater list
							FreeFloating[name] = group
						end
				--else
				--	break
					end
				end
			end
		end

		--if (moveCount > 0) then		-- or swapCount > 0) then
		--	break
		--end
		end

	if (moveCount == 0 and swapCount == 0) then
		--ChatFrame7:AddMessage("Finished!")
		ZPerl.RaidAdmin.StopLoad()
	else
		WaitingForRoster = GetTime()
		XswapCount = XswapCount + swapCount
		XmoveCount = XmoveCount + moveCount
		XPendingRosters = XPendingRosters + swapCount
		XPendingRosters = XPendingRosters + moveCount
	end
	--ChatFrame7:AddMessage("Done arranging (swaps: "..swapCount..")  (moves: "..moveCount..")")
end

-- UpdateDetails: shows how many players differ from the roster named in the edit box
local function UpdateDetails()
	local name = ZPerl_AdminFrame_Controls_Edit:GetText()
	local diff
	if (name) then
		diff = ZPerl.RaidAdmin.AdminCountDifferences(name)
	end

	if (diff) then
		ZPerl_AdminFrame_Controls_DetailsText:SetFormattedText(L["ADMIN_DIFFERENCES"], diff)
		ZPerl_AdminFrame_Controls_Details:Show()
	else
		ZPerl_AdminFrame_Controls_Details:Hide()
	end
end

-- ZPerl.RaidAdmin.AdminOnEvent
function ZPerl.RaidAdmin.AdminOnEvent(self, event, ...)
	ZPerl.RaidAdmin.AdminCheckMyRank()

	if (event == "GROUP_ROSTER_UPDATE") then
		UpdateDetails()

		if (WaitingForRoster) then
			if (not XFinishedLoad) then
				XPendingRosters = XPendingRosters - 1
				if (XPendingRosters < 1) then
					LoadRoster()
				end
			end
		end

	elseif (event == "ADDON_LOADED") then
		local addon = ...

		if addon == AddonName then
			AdminStartup(self)

			self:UnregisterEvent(event)
		end
	end
end

-- ZPerl.RaidAdmin.AdminOnUpdate
function ZPerl.RaidAdmin.AdminOnUpdate(self, elapsed)
	if (WaitingForRoster) then
		if (GetTime() > WaitingForRoster + 5) then
			ZPerl.RaidAdmin.StopLoad()
		end
	end
end

-- ZPerl.RaidAdmin.LoadRoster
function ZPerl.RaidAdmin.LoadRoster(loadName)
	if (not ZPerlRaidAdminDB.SavedRosters) then
		return
	end

	SavedRoster = ZPerlRaidAdminDB.SavedRosters[loadName]
	if (SavedRoster) then
		ZPerl_AdminFrame_Controls_StopLoad:Show()
		ZPerl_AdminFrame_Controls_LoadRoster:Hide()

		XFinishedLoad = false
		WaitingForRoster = nil
		XPendingRosters = 0
		LoadRoster()
	else
		if (not loadName) then
			ZPerl.Message(L["NO_ROSTER_NAME_GIVEN"])
		else
			ZPerl.Message(format(L["NO_ROSTER_CALLED"], loadName))
		end
	end

	return true
end

-- ZPerl.RaidAdmin.StopLoad
function ZPerl.RaidAdmin.StopLoad()
	ZPerl_AdminFrame_Controls_StopLoad:Hide()
	ZPerl_AdminFrame_Controls_LoadRoster:Show()

	XFinishedLoad = true
	WaitingForRoster = nil
	SavedRoster = nil
	XPendingRosters = 0

	UpdateDetails()
end

function ZPerl.Message(...)
	DEFAULT_CHAT_FRAME:AddMessage(L["MSG_PREFIX"].."- "..format(...))
end

ZPerl.RaidAdmin.AdminCommands = {
	save = ZPerl.RaidAdmin.SaveRoster,
	load = ZPerl.RaidAdmin.LoadRoster,
	auto = ToggleAuto,
	help = Help
}

-- ZPerl.RaidAdmin.AdminCountDifferences
function ZPerl.RaidAdmin.AdminCountDifferences(rosterName)
	if (not ZPerlRaidAdminDB.SavedRosters) then
		return
	end

	local count = 0

	SavedRoster = ZPerlRaidAdminDB.SavedRosters[rosterName]
	if (SavedRoster) then
		for i = 1,GetNumGroupMembers() do
			local name, _, subgroup = GetRaidRosterInfo(i)
			if (SavedRoster[name]) then
				if (SavedRoster[name].group ~= subgroup) then
					count = count + 1
				end
			else
				count = count + 1
			end
		end

		return count
	end
end

function ZPerl.RaidAdmin.AdminControlsOnLoad(self)
	self.Details = UpdateDetails

	self.MakeList = function()
		local index = 1
		local line = 1
		local find = ZPerl_AdminFrame_Controls_Edit:GetText()

		local Offset = _G.ZPerl_AdminFrame_Controls_RosterScrollBarScrollBar:GetValue() + 1
		for name,roster in pairs(ZPerlRaidAdminDB.SavedRosters) do
			if (index >= Offset) then
				local f = _G["ZPerl_AdminFrame_Controls_Roster"..line]
				if (f) then
					if (name == find) then
						f:LockHighlight()
					else
						f:UnlockHighlight()
					end
					f:SetText(name)
					f:Show()
				end
				line = line + 1
			end
			index = index + 1
		end
		for i = line,5 do
			local f = _G["ZPerl_AdminFrame_Controls_Roster"..i]
			if (f) then
				f:SetText("")
				f:UnlockHighlight()
				f:Hide()
			end
		end

		if (FauxScrollFrame_Update(ZPerl_AdminFrame_Controls_RosterScrollBar, index - 1, 5, 1)) then
			ZPerl_AdminFrame_Controls_RosterScrollBar:Show()
		else
			ZPerl_AdminFrame_Controls_RosterScrollBar:Hide()
		end

		UpdateDetails()
	end

	self.Validate = function()
		---@diagnostic disable-next-line: inject-field
		ZPerl_AdminFrame.Valid = false
		ZPerl_AdminFrame_Controls_LoadRoster:Disable()
		ZPerl_AdminFrame_Controls_DeleteRoster:Disable()

		local index = 1
		local line = 1
		local find = ZPerl_AdminFrame_Controls_Edit:GetText()
		local Offset = _G.ZPerl_AdminFrame_Controls_RosterScrollBarScrollBar:GetValue()
			for name,roster in pairs(ZPerlRaidAdminDB.SavedRosters) do
				if (index - 1 >= Offset) then
					local f = _G["ZPerl_AdminFrame_Controls_Roster"..line]
					if (not f) then
						break
					end
					if (name == find) then
						f:LockHighlight()
						ZPerl_AdminFrame.Valid = true
						if (UnitIsGroupAssistant("player") or UnitIsGroupLeader("player")) then
							ZPerl_AdminFrame_Controls_LoadRoster:Enable()
						end
						ZPerl_AdminFrame_Controls_DeleteRoster:Enable()
					else
						f:UnlockHighlight()
					end
				line = line + 1
			end
		   index = index + 1
		end
	end
end
