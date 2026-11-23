-- Frame positions. The active layout's `positions` (ZPerl.layout.positions, ZPerl.SavePosition) is the only store and
-- ZPerl.DefaultPoints (below) the only default; the client's layout cache is not used
-- (SetDontSavePosition), so a frame is where ZPerl.PlaceFrame puts it.

local L = ZPerl.L

-- ZPerl.FramePointUI(frame)
-- The frame's top-left times its own scale, and that scale. GetLeft/GetTop and SetPoint offsets are
-- in the frame's own units; these are UIParent units for a frame parented to UIParent. A frame
-- under another parent (the minimap button, the pet target) keeps the units of its saved entries
-- from before they were scaled by the parent. nil if unanchored.

function ZPerl.FramePointUI(frame)
	local left, top = frame:GetLeft(), frame:GetTop()
	if (not left or not top) then
		return
	end
	local ratio = frame:GetScale()
	return left * ratio, top * ratio, ratio
end

-- ZPerl.SetPointUI(frame, left, top)
-- Anchor the frame's top-left at a point in ZPerl.FramePointUI's units (its inverse).
function ZPerl.SetPointUI(frame, left, top)
	local ratio = frame:GetScale()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / ratio, top / ratio)
end

-- ZPerl.SetScale(frame, scale)
-- SetScale that keeps the frame's anchor points where they are on screen. SetPoint offsets are in the
-- frame's own units, so a bare SetScale moves the frame toward or away from what it is anchored to.
-- A root frame's position is saved too: its default offsets would place it elsewhere at the new scale.
function ZPerl.SetScale(frame, scale)
	local old = frame:GetScale()
	if (math.abs(old - scale) < 1e-6) then
		return
	end
	local points = {}
	for i = 1, frame:GetNumPoints() do
		points[i] = {frame:GetPoint(i)}
	end
	frame:SetScale(scale)
	if (#points == 0) then
		return
	end
	local k = old / scale
	frame:ClearAllPoints()
	for _, p in ipairs(points) do
		frame:SetPoint(p[1], p[2], p[3], (p[4] or 0) * k, (p[5] or 0) * k)
	end
	local name = frame:GetName()
	if (name and ZPerl.DefaultPoints[name]) then
		-- Not snapped: a slider step would move the frame to the grid
		ZPerl.AlignmentGridHold(true)
		ZPerl.SavePosition(frame)
		ZPerl.AlignmentGridHold(false)
		ZPerl.PlaceFrame(frame) -- The same spot, anchored as a load anchors it
	end
end

-- ZPerl.PlaceFrame(frame)
-- The saved position, else the default point; sizes of a resizable frame come with the saved one.
-- A protected frame is queued in combat (the unit frames are secure); others are placed at once.
function ZPerl.PlaceFrame(frame)
	if (InCombatLockdown() and frame:IsProtected()) then
		ZPerl.AfterCombatFor(ZPerl.PlaceFrame, frame)
		return
	end
	frame:SetDontSavePosition(true)

	local name = frame:GetName()
	local saved = ZPerl.GetSavePositionTable()
	local pos = saved and saved[name]
	if (pos and pos.left and pos.top) then
		ZPerl.SetPointUI(frame, pos.left, pos.top)
		if (name == "ZPerl_Assists_FrameAnchor") then
			if (ZPerlRaidHelperDB) then
				if (ZPerlRaidHelperDB.sizeAssistsX and ZPerlRaidHelperDB.sizeAssistsY) then
					ZPerl_Assists_Frame:SetWidth(ZPerlRaidHelperDB.sizeAssistsX)
					ZPerl_Assists_Frame:SetHeight(ZPerlRaidHelperDB.sizeAssistsY)
				end
				if (ZPerlRaidHelperDB.sizeAssistsS) then
					ZPerl_Assists_Frame:SetScale(ZPerlRaidHelperDB.sizeAssistsS)
				end
			end
		elseif (pos.height and pos.width) then
			if (frame:IsResizable()) then
				frame:SetHeight(pos.height)
				frame:SetWidth(pos.width)
			else
				pos.height, pos.width = nil, nil
			end
		end
	elseif (ZPerl.DefaultPoints[name]) then
		frame:ClearAllPoints()
		for _, p in ipairs(ZPerl.DefaultPoints[name]) do
			frame:SetPoint(unpack(p))
		end
	end
end

-- ZPerl.PlaceNewFrames
-- Every default frame that exists and has no anchor yet: each Z-Perl addon's ADDON_LOADED. Frames
-- created in Lua place themselves.
function ZPerl.PlaceNewFrames()
	for name in pairs(ZPerl.DefaultPoints) do
		local frame = _G[name]
		if (frame and frame:GetNumPoints() == 0) then
			ZPerl.PlaceFrame(frame)
		end
	end
end

-- Alignment grid and Snap to grid. ZPerl.layout.alignmentGrid and ZPerl.layout.alignmentSnapToGrid are written by the
-- General > Frames rows. The grid is drawn while it is on and the frames are unlocked or the settings panel is
-- open, and never in combat; Snap runs inside ZPerl.SavePosition, which every drag handler ends with.
local GRID_SIZE = 20
local gridFrame
local gridLines = {}
local snapBusy = false

local function gridDB()
	ZPerl.layout.alignmentGrid = ZPerl.layout.alignmentGrid or false
	ZPerl.layout.alignmentSnapToGrid = ZPerl.layout.alignmentSnapToGrid or false
	return ZPerl.layout
end

function ZPerl.AlignmentGridIsShown()
	return gridFrame ~= nil and gridFrame:IsShown()
end

function ZPerl.AlignmentGridHide()
	if (gridFrame) then
		gridFrame:Hide()
	end
end

local function gridShow()
	if (not gridFrame) then
		gridFrame = CreateFrame("Frame", nil, UIParent)
		gridFrame:SetAllPoints(UIParent)
		gridFrame:SetFrameStrata("LOW")
		gridFrame:EnableMouse(false)
	end
	local width, height = UIParent:GetWidth(), UIParent:GetHeight()
	if (not width or not height) then return end

	-- Textures cannot be destroyed: reuse the lines from earlier shows, create only the shortfall.
	local used = 0
	local function nextLine(major)
		used = used + 1
		local line = gridLines[used]
		if (not line) then
			line = gridFrame:CreateTexture(nil, "BACKGROUND")
			gridLines[used] = line
		end
		line:ClearAllPoints()
		line:SetColorTexture(0.25, 0.75, 1, major and 0.28 or 0.12)
		line:Show()
		return line
	end
	for i = 0, math.floor(width / GRID_SIZE) do
		local line = nextLine(i % 5 == 0)
		line:SetWidth(1)
		line:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", i * GRID_SIZE, 0)
		line:SetPoint("BOTTOMLEFT", gridFrame, "BOTTOMLEFT", i * GRID_SIZE, 0)
	end
	for i = 0, math.floor(height / GRID_SIZE) do
		local line = nextLine(i % 5 == 0)
		line:SetHeight(1)
		line:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", 0, -i * GRID_SIZE)
		line:SetPoint("TOPRIGHT", gridFrame, "TOPRIGHT", 0, -i * GRID_SIZE)
	end
	for i = used + 1, #gridLines do
		gridLines[i]:Hide()
	end
	gridFrame:Show()
end

-- Shows or hides the grid for the current state.
function ZPerl.AlignmentGridUpdate()
	local editing = ZPerl.Locked == 0 or (_G.ZPerl_OptionsWindow and _G.ZPerl_OptionsWindow:IsShown())
	if (gridDB().alignmentGrid and editing and not InCombatLockdown()) then
		gridShow()
	else
		ZPerl.AlignmentGridHide()
	end
end

-- The General > Frames button.
function ZPerl.AlignmentGridToggle()
	local db = gridDB()
	db.alignmentGrid = not db.alignmentGrid
	ZPerl.AlignmentGridUpdate()
end

local function snapFrame(frame)
	-- The tip promises a snap to the visible grid: a save while it is hidden stays where it is
	if (not gridDB().alignmentSnapToGrid or InCombatLockdown() or not ZPerl.AlignmentGridIsShown()) then return false end
	local name = frame.GetName and frame:GetName()
	if (name == "ZPerl_MinimapButton_Frame") then return false end
	-- The grid is in UIParent units, drawn from UIParent's top-left.
	local l, t = ZPerl.FramePointUI(frame)
	local top = UIParent:GetTop()
	if (not l or not top) then return false end
	local x = math.floor(l / GRID_SIZE + 0.5) * GRID_SIZE
	local y = top - math.floor((top - t) / GRID_SIZE + 0.5) * GRID_SIZE
	return pcall(ZPerl.SetPointUI, frame, x, y)
end

-- ZPerl.AlignmentGridHold(on): saves while held are not snapped (layouts Z-Perl computes itself, e.g. the raid Gap).
function ZPerl.AlignmentGridHold(on)
	snapBusy = on and true or false
end

-- Called by ZPerl.SavePosition: snap the frame, then save where it landed (the re-entry guard stops the second save snapping again).
function ZPerl.AlignmentGridSnapSaved(frame)
	if (snapBusy or not frame) then return end
	snapBusy = true
	if (snapFrame(frame)) then
		ZPerl.SavePosition(frame)
	end
	snapBusy = false
end

ZPerl.On("PLAYER_REGEN_DISABLED", ZPerl.AlignmentGridHide)
ZPerl.On("PLAYER_REGEN_ENABLED", ZPerl.AlignmentGridUpdate)

-- Upvalues for the code below
local _G = _G

local ipairs = ipairs
local max = max
local min = min
local pairs = pairs
local unpack = unpack

local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local IsShiftKeyDown = IsShiftKeyDown

local BackdropTemplateMixin = BackdropTemplateMixin

local GameTooltip = GameTooltip
local UIParent = UIParent

-- ZPerl.UnlockFrames
function ZPerl.UnlockFrames()
	ZPerl.Locked = 0

	if (ZPerl.Party.Virtual) then
		ZPerl.Party.Virtual(true)
	end

	if (ZPerl.Party.Preview) then
		ZPerl.Party.Preview(true)
	end

	if (ZPerl.PlayerPet.Virtual) then
		ZPerl.PlayerPet.Virtual(true)
	end

	if (ZPerl_AggroAnchor) then
		ZPerl_AggroAnchor:Enable()
	end

	if (ZPerl.Raid.RaidTitles) then
		ZPerl.Raid.RaidTitles()
		if (ZPerl.RaidPets.Titles) then
			ZPerl.RaidPets.Titles()
		end
	end
	ZPerl.AlignmentGridUpdate()
	ZPerl.ArrangeBarUpdate()
	ZPerl.Notice("Frames unlocked: /zperl lock, or General > Frames, locks them.")
end

-- ZPerl.LockFrames
function ZPerl.LockFrames()
	ZPerl.Locked = 1
	ZPerl.AlignmentGridUpdate()
	ZPerl.ArrangeBarUpdate()

	if (ZPerl.Party.Virtual) then
		ZPerl.Party.Virtual()
	end

	if (ZPerl.Party.Preview) then
		ZPerl.Party.Preview(false)
	end

	if (ZPerl.PlayerPet.Virtual) then
		ZPerl.PlayerPet.Virtual()
	end

	if (ZPerl_AggroAnchor) then
		ZPerl_AggroAnchor:Disable()
	end

	if (ZPerl.Raid.RaidTitles) then
		ZPerl.Raid.RaidTitles()
		if (ZPerl.RaidPets.Titles) then
			ZPerl.RaidPets.Titles()
		end
	end
end

-- ZPerl.GetSavePositionTable(create)
-- The active layout's positions, {[frameName] = {left, top, width, height}}; nil when it has none, unless create.
function ZPerl.GetSavePositionTable(create)
	if (not ZPerl.layout) then
		return
	end
	if (not ZPerl.layout.positions and create) then
		ZPerl.layout.positions = {}
	end
	return ZPerl.layout.positions
end


-- The only default layout: ZPerl.PlaceFrame applies it to a frame with no saved position. The
-- frames have no XML anchors. Entries are {point, relativeTo, relativePoint, x, y}; relativeTo is
-- a frame name.
local function TopLeft(x, y) return {{"TOPLEFT", "UIParent", "TOPLEFT", x, y}} end
local function TopRight(x, y) return {{"TOPRIGHT", "UIParent", "TOPRIGHT", x, y}} end
local function Center(x, y) return {{"CENTER", "UIParent", "CENTER", x or 0, y or 0}} end
ZPerl.DefaultPoints = {
	ZPerl_Player = TopLeft(35, -16),
	ZPerl_Player_Pet = TopLeft(92, -156),
	ZPerl_Target = TopLeft(300, -16),
	ZPerl_Focus = TopLeft(701, -360),
	ZPerl_TargetTarget = TopLeft(593, -16),
	ZPerl_Party_Anchor = TopLeft(38, -330),
	ZPerl_Raid_TitlePets = TopLeft(680, -500),
	ZPerl_Assists_FrameAnchor = Center(),
	ZPerl_AggroAnchor = Center(),
	ZPerl_MTList_Anchor = Center(),
	ZPerl_RaidMonitor_Anchor = Center(),
	ZPerl_CheckAnchor = Center(),
	ZPerl_AdminFrameAnchor = Center(),
	ZPerl_RosterTextAnchor = Center(0, -270),
	ZPerl_MinimapButton_Frame = {{"CENTER", "Minimap", "RIGHT", 0, 0}},
	-- Created in ZPerl.TargetTarget.SetBits.
	ZPerl_TargetTargetTarget = {{"TOPLEFT", "ZPerl_TargetTargetstatsFrame", "TOPRIGHT", 44, 0}},
	ZPerl_FocusTarget = {{"TOPLEFT", "ZPerl_FocuslevelFrame", "TOPRIGHT", 48, 0}},
	ZPerl_PetTarget = {{"TOPLEFT", "ZPerl_Player_PetnameFrame", "TOPRIGHT", 57, 0}},
}
for i, x in ipairs({0, 80, 160, 240, 320, 400, 480, 560, 640, 720, 800, 880, 880}) do
	ZPerl.DefaultPoints["ZPerl_Raid_Title"..i] = TopLeft(x, -715)
end
-- The defaults keep clear of Blizzard's default HUD (minimap, buffs and tracker top right, chat bottom left, bars bottom,
-- widgets top centre): unit frames top left, party down the left side above the chat, Focus below the target of target. Raid groups 1-4 in a row
-- right of the party column, 5-8 under them (a group is 80 x 226); titles 9-13 hold no members and keep the row above.
for i = 1, 8 do
	ZPerl.DefaultPoints["ZPerl_Raid_Title"..i] = TopLeft(350 + (i - 1) % 4 * 80, i <= 4 and -405 or -635)
end

-- ZPerl.SavePosition
-- The saved position is the frame's top-left in UIParent units (ZPerl.FramePointUI).
function ZPerl.SavePosition(self)
	local name = self:GetName()
	if (name) then
		local l, t = ZPerl.FramePointUI(self)
		local h = self:IsResizable() and self:GetHeight()
		local w = self:IsResizable() and self:GetWidth()

		local table = ZPerl.GetSavePositionTable(true)
		if (table) then
			if (t and l) then
				if (not table[name]) then
					table[name] = {}
				end
				table[name].top = t
				table[name].left = l
				table[name].height = h
				table[name].width = w
			else
				table[name] = nil
			end
		end
	end
	ZPerl.AlignmentGridSnapSaved(self)
end

-- ZPerl.RestoreAllPositions
-- Places every default frame and every frame with a saved position (ZPerl_Positions.lua).
function ZPerl.RestoreAllPositions()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.RestoreAllPositions)
		return
	end
	local names = {}
	for name in pairs(ZPerl.DefaultPoints) do
		names[name] = true
	end
	local table = ZPerl.GetSavePositionTable()
	if table then
		for k in pairs(table) do
			if k == "ZPerl_Runes" or k == "ZPerl_RaidHelper_Frame" or k == "ZPerl_RaidMonitor_Frame" or k == "ZPerl_Check" or k == "ZPerl_AdminFrame" or k == "ZPerl_Assists_Frame" then
				-- Fix for a wrong name with versions 2.3.2 and 2.3.2a
				-- It was using ZPerl_Frame instead of ZPerl_MTList_Anchor
				-- and ZPerl_RaidMonitor_Frame instead of ZPerl_RaidMonitor_Anchor
				-- And now a change to ZPerl_Check to ZPerl_CheckAnchor and ZPerl_AdminFrame to ZPerl_AdminFrameAnchor
				table[k] = nil
			else
				names[k] = true
			end
		end
	end
	for name in pairs(names) do
		local frame = _G[name]
		if frame then
			ZPerl.PlaceFrame(frame)
		end
	end
	-- The login alignment ran before this placed the title.
	if (ZPerl.RaidPets.Align) then
		ZPerl.RaidPets.Align()
	end
end

---------------------------------
-- Scaling frame corner thingy --
---------------------------------
-- Seems a convoluted way of doing things, rather than just anchoring bottomleft, topright.. but
-- doing that introduces a really ugly latency between the anchor moving and the frame scaling because
-- the OnSizeChanged event is fired on the frame after the actual resize took place.

local scaleIndication

local function scaleMouseDown(self)

	GameTooltip:Hide()

	if (self.resizable and IsShiftKeyDown()) then
		self.sizing = true
	elseif (self.scalable) then
		self.scaling = true
	end

	if (not scaleIndication) then
		scaleIndication = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
		scaleIndication:SetWidth(100)
		scaleIndication:SetHeight(18)
		scaleIndication.text = scaleIndication:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		scaleIndication.text:SetAllPoints()
		scaleIndication.text:SetJustifyH("LEFT")
	end

	scaleIndication:Show()
	scaleIndication:ClearAllPoints()
	scaleIndication:SetPoint("LEFT", self, "RIGHT", 4, 0)

	if (self.scaling) then
		scaleIndication.text:SetFormattedText("%.1f%%", self.frame:GetScale() * 100)
	else
		scaleIndication.text:SetFormattedText("%dx%d", self.frame:GetWidth(), self.frame:GetHeight())
	end

	self.anchor:StartSizing(self.resizeTop and "TOPRIGHT")

	self.oldBdBorder = {self.frame:GetBackdropBorderColor()}
	self.frame:SetBackdropBorderColor(1, 1, 0.5, 1)
end

local function scaleMouseUp(self)
	self.anchor:StopMovingOrSizing()

	scaleIndication:Hide()

	ZPerl.SavePosition(self.anchor)

	if self.resizeTop then
		ZPerl.SwitchAnchor(self.anchor, "BOTTOMLEFT")
	end

	if self.scaling then
		if self.onScaleChanged then
			self:onScaleChanged(self.frame:GetScale())
		end
	end

	if self.sizing then
		if self.onSizeChanged then
			self:onSizeChanged(self.frame:GetWidth(), self.frame:GetHeight())
		end
	end

	if self.oldBdBorder then
		self.frame:SetBackdropBorderColor(unpack(self.oldBdBorder))
		self.oldBdBorder = nil
	end

	self.scaling = nil
	self.sizing = nil
end

local function scaleMouseChange(self)
	if (self.corner.sizing) then
		self.corner.frame:SetWidth(self:GetWidth() / self.corner.frame:GetScale())
		self.corner.frame:SetHeight(self:GetHeight() / self.corner.frame:GetScale())

		self.corner.startSize.w = self.corner.frame:GetWidth()
		self.corner.startSize.h = self.corner.frame:GetHeight()

		if (scaleIndication and scaleIndication:IsShown()) then
			scaleIndication.text:SetFormattedText("|c00FFFF80%d|c00808080x|c00FFFF80%d", self.corner.frame:GetWidth(), self.corner.frame:GetHeight())
		end

	elseif (self.corner.scaling) then
		local w = self:GetWidth()
		if (w) then
			self.corner.scaling = nil
			local ratio = self.corner.frame:GetWidth() / self.corner.frame:GetHeight()
			local s = min(self.corner.maxScale, max(self.corner.minScale, w / self.corner.startSize.w))	-- New Scale

			w = self.corner.startSize.w * s		-- Set height and width of anchor window to match ratio of actual
			if (self.corner.resizeTop) then
				ZPerl.SwitchAnchor(self, "BOTTOMLEFT")
				self:SetWidth(w)
				self:SetHeight(w / ratio)
			else
				self:SetWidth(w)
				self:SetHeight(w / ratio)
			end

			if (scaleIndication and scaleIndication:IsShown()) then
				scaleIndication.text:SetFormattedText("%.1f%%", s * 100)
			end

			self.corner.frame:SetScale(s)
			self.corner.scaling = true
		end
	end
end

-- scaleMouseEnter
local function scaleMouseEnter(self)
	self.tex:SetVertexColor(1, 1, 1, 1)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if (self.scalable) then
		GameTooltip:SetText(L["DRAGHINT1"], nil, nil, nil, nil, true)
	end
	if (self.resizable) then
		GameTooltip:AddLine(L["DRAGHINT2"], nil, nil, nil, true)
	end
	GameTooltip:Show()
end

-- scaleMouseLeave
local function scaleMouseLeave(self)
	self.tex:SetVertexColor(1, 1, 1, 0.5)
	GameTooltip:Hide()
end

-- ZPerl.RegisterScalableFrame
function ZPerl.RegisterScalableFrame(self, anchorFrame, minScale, maxScale, resizeTop, resizable, scalable)
	if (scalable == nil) then
		scalable = true
	end

	if (not self.corner) then
		self.corner = CreateFrame("Frame", nil, self)
		self.corner:SetFrameLevel(self:GetFrameLevel() + 3)
		self.corner:EnableMouse(true)
		self.corner:SetScript("OnMouseDown", scaleMouseDown)
		self.corner:SetScript("OnMouseUp", scaleMouseUp)
		self.corner:SetScript("OnEnter", scaleMouseEnter)
		self.corner:SetScript("OnLeave", scaleMouseLeave)
		self.corner:SetHeight(12)
		self.corner:SetWidth(12)

		anchorFrame:SetScript("OnSizeChanged", scaleMouseChange)
		anchorFrame.corner = self.corner

		self.corner.tex = self.corner:CreateTexture(nil, "BORDER")
		self.corner.tex:SetTexture("Interface\\AddOns\\ZPerl\\Images\\ZPerl_Elements")
		self.corner.tex:SetAllPoints()
		self.corner.tex:SetVertexColor(1, 1, 1, 0.5)

		self.corner.anchor = anchorFrame
		self.corner.frame = self
	end

	if self.SetResizeBounds then
		self:SetResizeBounds(10, 10)
	else
		self:SetMinResize(10, 10)
	end

	self.corner.scalable = scalable
	self.corner.resizable = resizable
	self.corner.resizeTop = resizeTop
	self.corner.minScale = minScale or 0.4
	self.corner.maxScale = maxScale or 5
	self.corner.startSize = {w = self:GetWidth(), h = self:GetHeight()}

	local bgDef = self:GetBackdrop()

	self.corner:ClearAllPoints()
	if (resizeTop) then
		self.corner.tex:SetTexCoord(0.78125, 1, 0.5, 0.703125)
		self.corner:SetPoint("TOPRIGHT", -bgDef.insets.right, -bgDef.insets.top)
		self.corner:SetHitRectInsets(0, -6, -6, 0)		-- So the click area extends over the tooltip border
	else
		self.corner.tex:SetTexCoord(0.78125, 1, 0.78125, 1)
		self.corner:SetPoint("BOTTOMRIGHT", -bgDef.insets.right, bgDef.insets.bottom)
		self.corner:SetHitRectInsets(0, -6, 0, -6)		-- So the click area extends over the tooltip border
	end

	self.corner.scaling = true
	scaleMouseChange(anchorFrame)
	self.corner.scaling = nil
end
