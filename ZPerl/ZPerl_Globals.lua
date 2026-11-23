-- Author: Resike
-- License: GNU GPL v3, 29 June 2007

ZPerl.Locked = 1
local conf
local ConfigRequesters = {}
local playerName
local maxRevision
local ValidateClassNames

local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local CLASS_COUNT = 0
for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
	if k ~= "Adventurer" and k ~= "TRAVELER" then
		CLASS_COUNT = CLASS_COUNT + 1
	end
end

ZPerl.TooltipEdge9 = {
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	edgeSize = 9,
	title = true
}

---@diagnostic disable-next-line: create-global
ZPerl_Frame_Backdrop_32_16_3333 = {
	bgFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Frame_Backdrop_32_16_4444 = {
	bgFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Frame_Backdrop_16_16_4444 = {
	bgFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Frame_Backdrop_8_16_3333 = {
	bgFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 8,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Icon_Backdrop_8_16_3333 = {
	bgFile = "",
	edgeFile = "",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 3, right = 4, top = 3, bottom = 3 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Frame_Backdrop_256_10_1211 = {
	bgFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_FrameBack",
	edgeFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_ThinEdge",
	tile = true,
	tileSize = 256,
	edgeSize = 10,
	insets = { left = 1, right = 2, top = 1, bottom = 1 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Raid_Backdrop_16_9_3333 = {
	bgFile = "Interface\\AddOns\\ZPerl_RaidHelper\\Images\\ZPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 16,
	edgeSize = 9,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Raid_Backdrop_32_16_3333 = {
	bgFile = "Interface\\AddOns\\ZPerl_RaidHelper\\Images\\ZPerl_FrameBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Options_Backdrop_256_16_5555 = {
	bgFile = "Interface\\AddOns\\ZPerl\\Images\\ZPerl_FancyBack",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 256,
	edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

---@diagnostic disable-next-line: create-global
ZPerl_Frame_Backdrop_32_16_2222 = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	tile = true,
	tileSize = 8,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

ZPerl_BackdropTemplateMixin = CreateFromMixins(BackdropTemplateMixin)

function ZPerl.SetModuleRevision(rev)
	if (rev) then
		rev = strmatch(rev, "Revision: (%d+)")
		if (rev) then
			rev = tonumber(rev)
			if (not maxRevision or rev > maxRevision) then
				maxRevision = rev
			end
		end
	end
end
local AddRevision = ZPerl.SetModuleRevision

ZPerl.SetModuleRevision("$Revision:  $")

function ZPerl.Notice(...)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage(ZPerl.ProductName.." - |c00FFFF80"..format(...))
	end
end

-- ZPerl.RequestConfig
-- Setup a callback to give config around to local variables
function ZPerl.RequestConfig(getConfig, rev)
	tinsert(ConfigRequesters, getConfig)
	if (ZPerl.layout) then
		getConfig(ZPerl.layout)
	end
	AddRevision(rev)
end

-- CurrentConfig()
-- The active layout of this character (ZPerlDB.active["Realm / Name"]), created from the defaults when
-- absent, else backfilled. A character with no active layout starts on the one the schema 5 migration made
-- for it (ZPerlDB.migrated; a stale per-character profile gives way to Default's settings, positions
-- kept), else on Default. A layout another character deleted gives a notice and Default.
local function CurrentConfig()
	local s = ZPerlDB
	s.layouts = s.layouts or {}
	s.active = s.active or {}
	local layouts, me = s.layouts, GetRealmName() .. " / " .. playerName

	local defaults = {}
	ZPerl.Defaults(defaults)
	if (type(layouts.Default) ~= "table") then
		layouts.Default = ZPerl.CopyTable(defaults)
	end

	local name = s.active[me]
	if (name == nil) then
		local m = s.migrated and s.migrated[me]
		if (m and type(layouts[m]) == "table") then
			name = m
			local shared = false
			for _, n in pairs(s.active) do
				if (n == m) then
					shared = true
				end
			end
			---@diagnostic disable-next-line: undefined-global
			if (not ZPerlPerCharacter and not shared) then
				local positions = layouts[m].positions
				layouts[m] = ZPerl.CopyTable(layouts.Default)
				layouts[m].positions = positions
			end
		else
			if (m) then
				ZPerl.Notice("Layout %s no longer exists, using Default.", tostring(m))
			end
			name = "Default"
		end
		if (s.migrated) then
			s.migrated[me] = nil
		end
	elseif (type(layouts[name]) ~= "table") then
		ZPerl.Notice("Layout %s no longer exists, using Default.", tostring(name))
		name = "Default"
	end
	s.active[me] = name

	local report = ZPerl.Backfill(layouts[name], defaults)
	if (report[1]) then
		ZPerl.Notice("Settings kept as stored, wrong type: %s", table.concat(report, ", ", 1, math.min(#report, 5)))
	end

	return layouts[name]
end

-- GiveConfig
local function GiveConfig()
	conf = CurrentConfig()
	ZPerl.layout = conf

	for k, v in pairs(ConfigRequesters) do
		v(conf)
	end
end

ZPerl.GiveConfig = GiveConfig

-- ZPerl.AfterConfig(fn, ...)
-- fn(...) at once when the profile is handed out, else when the first hand-out has finished (the addon's
-- files run before SavedVariables are read). For an XML OnLoad that builds a frame from the profile.
local afterConfig = {}
function ZPerl.AfterConfig(fn, ...)
	if (ZPerl.layout) then
		return fn(...)
	end
	local args = {...}
	tinsert(afterConfig, function() fn(unpack(args)) end)
end

-- ZPerl.ResetDefaults
-- Resets the active layout: its settings and its frame positions.
function ZPerl.ResetDefaults()
	local fresh = {}

	ZPerl.Defaults(fresh)

	ZPerlDB.layouts[ZPerl.ActiveLayout()] = fresh

	ZPerl.ReapplyLayout()

	ZPerl.ResetFramePositions()
	print("Z-Perl: settings and frame positions reset to defaults.")
end

-- ZPerl.ResetFramePositions
-- Forget this character's saved positions and move every frame to its default anchor now.
-- Also the "Default" entry in the layout list.
function ZPerl.ResetFramePositions()
	if (InCombatLockdown()) then
		ZPerl.AfterCombat(ZPerl.ResetFramePositions)
	else
		local positions = ZPerl.GetSavePositionTable()
		if (positions) then
			wipe(positions)
		end
		for name in pairs(ZPerl.DefaultPoints) do
			local frame = _G[name]
			if (frame) then
				ZPerl.Pcall(ZPerl.PlaceFrame, frame)
			end
		end
	end
end

-- CopyTable
function ZPerl.CopyTable(old)
	if (not old) then
		return
	end

	--local new = ZPerl.GetReusableTable()
	local new = { }

	for k, v in pairs(old) do
		if (type(v) == "table") then
			new[k] = ZPerl.CopyTable(v)
		else
			new[k] = v
		end
	end

	return new
end

-- ZPerl.RegisterLDB
local function RegisterLDB()
	local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
	if (LDB) then
		LDB:NewDataObject("Z-Perl", {
			type = "launcher",
			label = ZPerl.ShortProductName,
			icon = ZPerl.ModMenuIcon,
			OnClick = ZPerl.MinimapButtonOnClick,
			OnTooltipShow = function(tooltip) ZPerl.MinimapButtonDetails(tooltip, true) end,
		})
	end
	RegisterLDB = nil
end


local function settingspart1()
	playerName = UnitName("player")

	if (not ZPerlDB) then
		---@diagnostic disable-next-line: create-global
		ZPerlDB = {}
	end

	ZPerl.MigrateConfig()
	ZPerl.MigrateLayouts()
	ZPerl.MigrateDeadKeys()
	ZPerl.MigrateEngineNames()
	ZPerl.MigrateGroupNine()
	ZPerl.MigratePartyDebuffs()
	ZPerl.MigrateColorNames()
	GiveConfig()

	-- Informational only: settings migrations key on ZPerlDB.schema (ZPerl.MigrateConfig)
	ZPerlDB.ConfigVersion = ZPerl.VersionNumber

	ZPerl.Pcall(ZPerl.ValidateSettings)

	ZPerl.RegisterSMBarTextures()
end

local function startupCheckSettings()
	ZPerl.Pcall(ZPerl.Init)
	RegisterLDB()
end

-- The three login events of this file, on the ZPerl.On bus. ADDON_LOADED filters by addon name; the
-- login pair run once.
local function onAddonLoaded(_, addon)
	-- 0.x saved-variable names to the new ones, before settingspart1 and before AuraBlacklist's own ADDON_LOADED
	ZPerl.Pcall(ZPerl.MigrateSavedNames, addon)
	if (addon == "ZPerl") then
		-- A dev run cut off between Begin and End: the saved settings go back (ZPerl_Migrate.lua)
		ZPerl.Pcall(ZPerl.RestoreAtLoad)
		settingspart1()
		for _, run in ipairs(afterConfig) do
			ZPerl.Pcall(run)
		end
	end
	-- An addon's frames exist, unanchored, when its ADDON_LOADED fires; its own handler
	-- may measure them.
	if (strsub(addon, 1, 5) == "ZPerl") then
		ZPerl.PlaceNewFrames()
	end
end

local function onLogin()
	ZPerl.Off("ADDON_LOADED", onAddonLoaded)
	ZPerl.Off("PLAYER_LOGIN", onLogin)
	ZPerl.PrintRestoreNotice()
	startupCheckSettings()
	ZPerl.MinimapButtonInit(ZPerl_MinimapButton_Frame)
end

local function onEnteringWorld()
	ZPerl.Off("PLAYER_ENTERING_WORLD", onEnteringWorld)
	-- Restore the layout's saved positions (a first install has none: PlaceNewFrames placed the defaults).
	if (ZPerl.GetSavePositionTable()) then
		ZPerl.RestoreAllPositions()
	end
end

ZPerl.On("ADDON_LOADED", onAddonLoaded)
ZPerl.On("PLAYER_LOGIN", onLogin)
ZPerl.On("PLAYER_ENTERING_WORLD", onEnteringWorld)

-- ZPerl.LayoutKey(): this character's key in ZPerlDB.active and .migrated.
function ZPerl.LayoutKey()
	return GetRealmName() .. " / " .. UnitName("player")
end

-- ZPerl.ActiveLayout(): the name of this character's layout.
function ZPerl.ActiveLayout()
	return ZPerlDB.active[ZPerl.LayoutKey()]
end

-- ZPerl.LayoutNames(): all layout names, Default first, the rest sorted ignoring case.
function ZPerl.LayoutNames()
	local names = {}
	for name in pairs(ZPerlDB.layouts) do
		if (name ~= "Default") then
			names[#names + 1] = name
		end
	end
	table.sort(names, function(a, b)
		local la, lb = a:lower(), b:lower()
		if (la ~= lb) then
			return la < lb
		end
		return a < b
	end)
	table.insert(names, 1, "Default")
	return names
end

-- ZPerl.CleanLayoutName(name, except)
-- The trimmed name, or nil and a reason: empty, or taken by a layout other than `except`, ignoring case.
function ZPerl.CleanLayoutName(name, except)
	name = tostring(name or ""):match("^%s*(.-)%s*$")
	if (name == "") then
		return nil, "A layout needs a name."
	end
	for other in pairs(ZPerlDB.layouts) do
		if (other ~= except and other:lower() == name:lower()) then
			return nil, string.format("A layout named %s exists.", other)
		end
	end
	return name
end

-- The layout functions refuse with a notice and return nil; on success they return true.
function ZPerl.LayoutRefuse(reason)
	ZPerl.Notice("%s", reason)
end
function ZPerl.LayoutInCombat()
	if (InCombatLockdown()) then
		ZPerl.LayoutRefuse("Not available in combat.")
		return true
	end
end

-- ZPerl.SelectLayout(name)
-- The one switch, for the panel and the slash command. Prunes the layout in use, makes `name` this
-- character's, and re-applies everything (ZPerl.ReapplyLayout). The Player, Pet and Target
-- enable keys and raid.enable need a reload.
function ZPerl.SelectLayout(name)
	local d = ZPerl.Dev; if d and d.listener then d.Emit("layout.select", name) end
	if (ZPerl.LayoutInCombat()) then
		return
	end
	if (type(ZPerlDB.layouts[name]) ~= "table") then
		ZPerl.LayoutRefuse(string.format("No layout named %s.", tostring(name)))
		return
	end
	local before = ZPerl.layout and ZPerl.CopyTable(ZPerl.layout) -- The outgoing layout as the frames show it, before the prune
	ZPerl.PruneConfig()
	ZPerlDB.active[ZPerl.LayoutKey()] = name
	ZPerl.ReapplyLayout(before)
	return true
end

-- ZPerl.LayoutAppliers(a, b)
-- The appliers needed by the keys that differ between the settings tables a and b, as a set; nil when a differing key has
-- no settings row (then everything runs). Positions are not settings. Keys map to appliers through ZPerl.SettingsList:
-- the union over the rows that save the key: `path`, `with`, `also`, the keys of a `map`, and `keys` (a row with
-- get/set). A color row saves a table: its keys r, g, b, a belong to the row.
-- ZPerl.SettingsList is in ZPerl_Options (load on demand): before the options were first opened there is no list, every
-- key is unmatched and everything runs.
-- ZPerl.LayoutApplyStats counts both outcomes, and holds the keys without a row of the last full run.
ZPerl.LayoutApplyStats = {scoped = 0, full = 0, unmatched = {}}
function ZPerl.LayoutAppliers(a, b)
	local index = {}
	local function add(key, apply)
		local set = index[key]
		if (not set) then
			set = {}
			index[key] = set
		end
		for _, n in ipairs(apply) do
			set[n] = true
		end
	end
	for _, e in ipairs(ZPerl.SettingsList or {}) do
		local apply = e.apply or {"full"}
		if (e.path) then
			add(e.path, apply)
		end
		for _, k in ipairs(e.with or {}) do
			add(k, apply)
		end
		for k in pairs(e.also or {}) do
			add(k, apply)
		end
		for _, k in ipairs(e.keys or {}) do
			add(k, apply)
		end
		for _, m in ipairs(e.map or {}) do
			for _, part in ipairs({m[2] or {}, m[3] or {}}) do
				for k in pairs(part) do
					add((e.base and e.base ~= "" and (e.base .. ".") or "") .. tostring(k), apply)
				end
			end
		end
	end
	local need, unmatched = {}, {}
	local function note(path)
		local key = path
		while (key and not index[key]) do
			key = key:match("^(.*)%.[^.]*$")
		end
		if (not key) then
			unmatched[#unmatched + 1] = path
			return
		end
		for n in pairs(index[key]) do
			need[n] = true
		end
	end
	local function walk(x, y, prefix)
		for k, v in pairs(x) do
			local w, path = y[k], prefix .. tostring(k)
			if (type(v) == "table" and type(w) == "table") then
				walk(v, w, path .. ".")
			elseif (v ~= w) then
				note(path)
			end
		end
		for k in pairs(y) do
			if (x[k] == nil) then
				note(prefix .. tostring(k))
			end
		end
	end
	for k, v in pairs(a) do
		if (k ~= "positions") then
			if (type(v) == "table" and type(b[k]) == "table") then
				walk(v, b[k], k .. ".")
			elseif (v ~= b[k]) then
				note(k)
			end
		end
	end
	for k in pairs(b) do
		if (k ~= "positions" and a[k] == nil) then
			note(k)
		end
	end
	local stats = ZPerl.LayoutApplyStats
	if (unmatched[1]) then
		stats.full = stats.full + 1
		stats.unmatched = unmatched
		return nil
	end
	stats.scoped = stats.scoped + 1
	return need
end

-- ZPerl.ReapplyLayout(before)
-- Applies the active layout everywhere: config consumers, positions (before the scale appliers, which
-- save the position of a frame with no entry), spell range, class list, option changers, the raid
-- header appliers the option changers do not run. Shared by the layout switch and Reset to defaults.
-- before: the settings of the layout just left (a copy). With it only the appliers of the settings
-- that differ run (ZPerl.Apply); without it, or with a differing key no settings row covers, every
-- option changer runs.
function ZPerl.ReapplyLayout(before)
	local d = ZPerl.Dev; if d and d.listener then d.Emit("layout.reapply") end
	ZPerl.GiveConfig()
	ZPerl.RestoreAllPositions()
	ZPerl.StartupSpellRange()
	ValidateClassNames(ZPerl.layout.raid)
	local need = before and ZPerl.LayoutAppliers(before, ZPerl.layout)
	if (need and not need.full) then
		-- These follow the layout or the restored positions whether or not a key differs: the raid headers and widths,
		-- and the raid helper, which anchors its frame after the restore
		need.raidheaders, need.raidwidth, need.raidsizes = true, true, true
		local names = {}
		for n in pairs(need) do
			if (ZPerl.HasApplier(n)) then
				names[#names + 1] = n
			end
		end
		ZPerl.Apply(names)
	else
		ZPerl.OptionActions()
		for _, applier in ipairs({"raidheaders", "raidwidth"}) do
			if (ZPerl.HasApplier(applier)) then
				ZPerl.Apply({applier})
			end
		end
	end
	if (ZPerl.SettingsRefresh) then
		ZPerl.SettingsRefresh()
	end
end

-- ZPerl.NewLayout(name): a layout of the defaults, selected.
function ZPerl.NewLayout(name)
	if (ZPerl.LayoutInCombat()) then
		return
	end
	local clean, reason = ZPerl.CleanLayoutName(name)
	if (not clean) then
		ZPerl.LayoutRefuse(reason)
		return
	end
	local d = {}
	ZPerl.Defaults(d)
	ZPerlDB.layouts[clean] = d
	return ZPerl.SelectLayout(clean)
end

-- ZPerl.CopyLayout(name): a copy of the active layout, positions included, selected.
function ZPerl.CopyLayout(name)
	if (ZPerl.LayoutInCombat()) then
		return
	end
	local clean, reason = ZPerl.CleanLayoutName(name)
	if (not clean) then
		ZPerl.LayoutRefuse(reason)
		return
	end
	ZPerl.PruneConfig()
	ZPerlDB.layouts[clean] = ZPerl.CopyTable(ZPerlDB.layouts[ZPerl.ActiveLayout()])
	return ZPerl.SelectLayout(clean)
end

-- ZPerl.RenameLayout(old, new): not Default; every character on it follows.
function ZPerl.RenameLayout(old, new)
	if (ZPerl.LayoutInCombat()) then
		return
	end
	local s = ZPerlDB
	if (old == "Default") then
		ZPerl.LayoutRefuse("The Default layout cannot be renamed.")
		return
	end
	if (type(s.layouts[old]) ~= "table") then
		ZPerl.LayoutRefuse(string.format("No layout named %s.", tostring(old)))
		return
	end
	local clean, reason = ZPerl.CleanLayoutName(new, old)
	if (not clean) then
		ZPerl.LayoutRefuse(reason)
		return
	end
	if (clean == old) then
		return true
	end
	local layout = s.layouts[old]
	s.layouts[old] = nil
	s.layouts[clean] = layout
	for _, map in ipairs({s.active, s.migrated or {}}) do
		for key, name in pairs(map) do
			if (name == old) then
				map[key] = clean
			end
		end
	end
	if (ZPerl.SettingsRefresh) then
		ZPerl.SettingsRefresh()
	end
	return true
end

-- ZPerl.DeleteLayout(name): not Default, not this character's own layout. A character on it goes back to
-- Default at its next login.
function ZPerl.DeleteLayout(name)
	if (ZPerl.LayoutInCombat()) then
		return
	end
	local s = ZPerlDB
	if (name == "Default") then
		ZPerl.LayoutRefuse("The Default layout cannot be deleted.")
		return
	end
	if (type(s.layouts[name]) ~= "table") then
		ZPerl.LayoutRefuse(string.format("No layout named %s.", tostring(name)))
		return
	end
	if (ZPerl.ActiveLayout() == name) then
		ZPerl.LayoutRefuse("The layout in use cannot be deleted.")
		return
	end
	s.layouts[name] = nil
	if (ZPerl.SettingsRefresh) then
		ZPerl.SettingsRefresh()
	end
	return true
end

-- ZPerl.Backfill(profile, defaults)
-- Copies every key absent from profile out of defaults, recursively (at login, after ZPerl.MigrateConfig:
-- run before it, an unticked option stored as nil would come back ticked). A stored value is never
-- replaced. A list (a table with an array part: raid.class, raid.group) is a leaf: a stored list is not
-- merged with the default one. Where one side is a table and the other is not, the stored value stays.
-- Returns the paths of those mismatches. Keys the defaults lack (savedPositions) are not touched.
function ZPerl.Backfill(profile, defaults, report, path)
	report = report or {}
	for k, d in pairs(defaults) do
		local v = profile[k]
		local name = (path and path .. "." or "") .. tostring(k)
		if (v == nil) then
			profile[k] = (type(d) == "table") and ZPerl.CopyTable(d) or d
		elseif ((type(v) == "table") ~= (type(d) == "table")) then
			report[#report + 1] = name
		elseif (type(d) == "table" and d[1] == nil and v[1] == nil) then
			ZPerl.Backfill(v, d, report, name)
		end
	end
	return report
end

-- ZPerl.Prune(profile, defaults)
-- The inverse of ZPerl.Backfill, run at PLAYER_LOGOUT: deletes every key whose stored value equals the
-- default, so a default changed later reaches a key the profile never changed (the backfill at the next
-- login restores the pruned keys). Walks the defaults only: keys they lack (savedPositions, extra keys)
-- stay. A list is a leaf, compared element by element. A table left empty is deleted because the defaults
-- hold it, and the backfill recreates it.
function ZPerl.Prune(profile, defaults)
	local function same(a, b)
		if (type(a) ~= "table" or type(b) ~= "table") then
			return a == b
		end
		for k, v in pairs(a) do
			if (not same(v, b[k])) then
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

	for k, d in pairs(defaults) do
		local v = profile[k]
		if (type(d) == "table" and type(v) == "table" and d[1] == nil and v[1] == nil) then
			ZPerl.Prune(v, d)
			if (next(v) == nil) then
				profile[k] = nil
			end
		elseif (v ~= nil and same(v, d)) then
			profile[k] = nil
		end
	end
end

-- ZPerl.PruneConfig()
-- Prunes the active profile (ZPerl.layout, set by every GiveConfig: login, profile switch, Reset Defaults,
-- Copy Settings) against freshly built defaults. Only that profile: the defaults hold the logged-in
-- character's class (target.hitIndicator), so another character's profile is not pruned with them.
-- A ConfigDefault function that raises leaves partial defaults, which delete fewer keys, never more.
function ZPerl.PruneConfig()
	if (type(ZPerl.layout) == "table") then
		local defaults = {}
		ZPerl.Pcall(ZPerl.Defaults, defaults)
		-- Defaults by class: a profile shared by characters of different classes keeps the stored value
		if (defaults.target) then
			defaults.target.highlightDebuffs = nil
		end
		ZPerl.Prune(ZPerl.layout, defaults)
	end
end

ZPerl.On("PLAYER_LOGOUT", ZPerl.PruneConfig)


-- ZPerl.Defaults()
function ZPerl.Defaults(new)
	ZPerl.OptionsDefaults(new)
end

-- ZPerl.DefaultRaidClasses
-- Must have one entry per class the client knows about (ZPerl_Raid.lua's
-- CLASS_COUNT counts LOCALIZED_CLASS_NAMES_MALE), or its repair path rebuilds
-- this, still comes up short for the newer classes, and crashes again on the
-- very next lookup -- which aborts raid frame setup entirely.
local allClasses = {"WARRIOR", "ROGUE", "HUNTER", "MAGE", "WARLOCK", "PRIEST", "DRUID", "SHAMAN", "PALADIN",
	"DEATHKNIGHT", "MONK", "DEMONHUNTER", "EVOKER"}

-- ClientClasses(): every class token the client has, in Z-Perl's order, then any the list above does not know
-- (sorted), the same set CLASS_COUNT counts, so the raid code's per-class loops never run past the list
local function ClientClasses()
	local tokens, known = {}, {}
	for _, class in ipairs(allClasses) do
		known[class] = true
		if (LOCALIZED_CLASS_NAMES_MALE[class]) then
			tinsert(tokens, class)
		end
	end
	local extra = {}
	for class in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		if (not known[class] and class ~= "Adventurer" and class ~= "TRAVELER") then
			tinsert(extra, class)
		end
	end
	sort(extra)
	for _, class in ipairs(extra) do
		tinsert(tokens, class)
	end
	return tokens
end

function ZPerl.DefaultRaidClasses()
	local list = {}
	for _, class in ipairs(ClientClasses()) do
		tinsert(list, {enable = true, name = class})
	end
	return list
end

-- ValidateClassNames
function ValidateClassNames(part)
	if not part then
		return
	end
	-- This should never happen, but I'm sure someone will find a way to break it

	-- Every class the client has must be in the list
	local list = {}
	for _, class in ipairs(ClientClasses()) do
		list[class] = false
	end
	local valid
	if (part.class) then
		local classCount = 0
		for i, info in pairs(part.class) do
			if (type(info) == "table" and info.name) then
				classCount = classCount + 1
			end
		end
		if (classCount == CLASS_COUNT) then
			valid = true
		end

		if (valid) then
			for i = 1, CLASS_COUNT do
				if (part.class[i]) then
					list[part.class[i].name] = true
				end
			end
		end
	end

	if (valid) then
		for k, v in pairs(list) do
			if (not v) then
				valid = nil
			end
		end
	end

	if (not valid) then
		part.class = ZPerl.DefaultRaidClasses()
	end

	-- Sort by Class shows one column per class through raid.group 9 and up; a profile saved with fewer
	-- entries than the client has classes (12, before retail's 13th) would keep the last columns hidden
	if (part.group) then
		for i = 9, CLASS_COUNT do
			if (part.group[i] == nil) then
				part.group[i] = 1
			end
		end
	end
end

-- ZPerl.ValidateSettings()
function ZPerl.ValidateSettings()
	ValidateClassNames(ZPerl.layout.raid)

	ZPerl.ValidateSettings = nil
end
