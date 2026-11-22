-- The value logic of the options window (the ZPerl_Options addon): get and store per list entry, the appliers, the shared controls and the
-- layout and raid functions the rows call. List format: the header of ZPerl_SettingsList.lua. The window reads this file's
-- functions through ZPerl.SettingsCore (end of file).
--
-- Every getter and setter re-resolves ZPerl.layout, which is replaced on a profile switch. A stored nil and false
-- read the same.
--
-- A shared control (list entry with `each`, General's Shown on frames and Auras sections) has no key of its own: its
-- setter calls the store of each ticked frame's own entry (the "Apply to" picker, a bitmask kept in `masks`, session
-- state), its getter reads the first ticked frame's entry, its tooltip names the ticked frames that differ.

-- Upvalues
local floor = math.floor
local format = string.format
local L = ZPerl.OptionsL -- the drawn text by its English wording (Localization/Localization.lua)
-- Pages other addons add: {key, name, create}. The options window makes each a tab with a frame it keeps in `frame`;
-- create(frame) runs the first time the tab is shown.
ZPerl.SettingsPages = ZPerl.SettingsPages or {}

local function norm(v) return v or false end
local byId = nil -- byId: built on first use, the list file loads after this one
local function rowById(id)
	if not byId then
		byId = {}
		for _, e in ipairs(ZPerl.SettingsList) do byId[e.id] = e end
	end
	return byId[id]
end
local function refresh() if ZPerl.Options then ZPerl.Options.Refresh() end end -- re-reads every control of the open window
local sharedValue, sharedStore, setMask, maskOf -- shared controls, below

-- Parent table and last key of a dotted path (an integer key is its own last key). create: build missing tables.
-- The split of each path is cached: the options window reads every row's value on each open and refresh, and a
-- gmatch per read left an iterator and substrings behind each time.
local splitCache = {}
local function split(key)
	local parts = splitCache[key]
	if not parts then
		parts = {}
		for k in string.gmatch(key, "[^%.]+") do parts[#parts + 1] = k end
		splitCache[key] = parts
	end
	return parts
end
local function parentOf(root, key, create)
	if type(key) == "number" then return root, key end
	local parts = split(key)
	local n = #parts
	local t = root
	for i = 1, n - 1 do
		local k = parts[i]
		local nx = t[k]
		if type(nx) ~= "table" then
			if not create then return nil end
			nx = {}
			t[k] = nx
		end
		t = nx
	end
	return t, parts[n]
end
local function read(root, path)
	local p, k = parentOf(root, path)
	return p and p[k]
end
local function baseTable(root, e, create)
	if e.base == "" then return root end
	local t = read(root, e.base)
	if type(t) ~= "table" and create then
		local p, k = parentOf(root, e.base, true)
		t = {}
		p[k] = t
	end
	return type(t) == "table" and t or nil
end

------------------------------------------------------------------------------------------------ apply
-- ZPerl.Apply (ZPerl_Init.lua) runs the entry's appliers and defers itself in combat. A slider or color calls it on
-- every step; an entry with `throttle` (appliers slower than a frame) at most once per 0.1 s, with a trailing call so
-- the last value always applies.
local lastRun, trailing, latest = 0, false, nil
local collect -- while a shared control writes: the appliers its frames' entries want, name -> true
local function applyNow(names)
	lastRun = GetTime()
	ZPerl.Apply(names)
end
local function applyThrottled(names)
	latest = names
	local wait = lastRun + 0.1 - GetTime()
	if wait <= 0 then
		applyNow(names)
	elseif not trailing then
		trailing = true
		C_Timer.After(wait, function()
			trailing = false
			applyNow(latest)
		end)
	end
end
-- A name whose module has no applier (a raid tool not loaded) is skipped, not raised.
local function loaded(names)
	local out = {}
	for _, n in ipairs(names) do
		if n == "full" or ZPerl.Appliers[n] then out[#out + 1] = n end
	end
	return out
end
local function apply(e, names)
	names = names or e.apply
	if collect then
		for _, n in ipairs(names) do collect[n] = true end
		return
	end
	names = loaded(names)
	if #names == 0 then return end
	if e.throttle then applyThrottled(names) else applyNow(names) end
end

------------------------------------------------------------------------------------------------ values
local function hexOf(c)
	if type(c) ~= "table" then return "FFFFFFFF" end
	local function b(x) return floor((x or 1) * 255 + 0.5) end
	return format("%02X%02X%02X%02X", b(c.a), b(c.r), b(c.g), b(c.b))
end

-- A stored check value: X-Perl readers test `== 1` or truthiness, and the defaults store 0 for off.
local function on(v) return v ~= nil and v ~= false and v ~= 0 end

-- The setting's value for an entry, read from root (ZPerl.layout, or a default profile).
local function valueOf(e, root)
	local t = e.type
	if e.each then
		return sharedValue(e, root)
	elseif t == "frames" then
		return maskOf(e.section)
	elseif e.get then
		local v = e.get()
		if t == "check" then return on(v) end
		return v == nil and "" or v
	elseif t == "check" then
		return on(read(root, e.path))
	elseif t == "slider" then
		local v = tonumber(read(root, e.path))
		if v == nil then v = e.default end
		if v == nil then v = e.min end
		return v
	elseif t == "color" then
		return hexOf(read(root, e.path))
	elseif type(e.options) == "function" then
		return ""
	elseif e.map then
		local base = baseTable(root, e)
		if base then
			for i, entry in ipairs(e.map) do
				local ok = true
				for k, want in pairs(entry[3] or entry[2]) do
					local p, last = parentOf(base, k)
					local good = false
					if p then
						if type(want) == "table" then
							for _, w in ipairs(want) do good = good or norm(p[last]) == norm(w) end
						else
							good = norm(p[last]) == norm(want)
						end
					end
					if not good then
						ok = false
						break
					end
				end
				if ok then return i end
			end
		end
		return 0
	else
		local v = norm(read(root, e.path))
		for i, o in ipairs(e.options) do
			if norm(o[1]) == v then return i end
		end
		return 0
	end
end

local function write(path, v)
	local p, k = parentOf(ZPerl.layout, path, true)
	p[k] = v
end

-- Store the setting's value v for an entry.
---@param e table
---@param v any
local function store(e, v)
	local t = e.type
	if e.each then
		return sharedStore(e, v)
	elseif t == "frames" then
		return setMask(e.section, v)
	elseif e.set then
		e.set(v)
	elseif t == "check" then
		write(e.path, v and e.on or e.off)
		if e.with then for _, w in ipairs(e.with) do write(w, v and e.on or e.off) end end
	elseif t == "slider" then
		v = e.min + floor((v - e.min) / e.step + 0.5) * e.step
		v = tonumber(format("%.6f", v))
		write(e.path, v)
		if e.with then for _, w in ipairs(e.with) do write(w, v) end end
	elseif t == "color" then
		local a, r, g, b = string.match(v, "^(%x%x)(%x%x)(%x%x)(%x%x)$")
		if not a then return end
		local p, k = parentOf(ZPerl.layout, e.path, true)
		local c = p[k]
		if type(c) ~= "table" then
			c = {}
			p[k] = c
		end
		-- the swatch has no opacity: the stored alpha stays
		c.r, c.g, c.b = tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
	elseif e.map then
		local entry = e.map[v]
		if not entry then return end
		local base = baseTable(ZPerl.layout, e, true)
		for k, want in pairs(entry[2]) do
			local p, last = parentOf(base, k, true)
			p[last] = want
		end
	else
		local o = e.options[v]
		if o then write(e.path, o[1]) end
	end
	-- Blizzard's Defaults button sets every setting to its default in no fixed order: the side effect would undo one
	-- refresh only on a change: a color drag stores every step, and refreshing the whole panel each step lags the game
	if e.also then
		local changed
		for path, want in pairs(e.also) do
			if norm(read(ZPerl.layout, path)) ~= norm(want) then
				write(path, want)
				changed = true
			end
		end
		if changed then refresh() end
	end
	apply(e)
end

------------------------------------------------------------------------------------------------ shared
-- ZPerl.SettingsFrames is set by the list file, which loads after this one: read it at run time
local function full() return 2 ^ #ZPerl.SettingsFrames - 1 end
local masks = {} -- section -> bitmask of the ticked frames; session state, not saved
local function ticked(mask, i) return bit.band(mask, bit.lshift(1, i - 1)) ~= 0 end
function maskOf(section) return masks[section] or full() end

-- A choice of a per-frame dropdown entry by index or label; a shared dropdown's labels are the frames' labels, renamed
-- for a frame by the entry's `alias`.
local function choiceOf(fe, i)
	local c = fe.map and fe.map[i] and fe.map[i][1] or (type(fe.options) == "table" and fe.options[i] and fe.options[i][2])
	return c or nil
end
local function indexOfChoice(fe, label)
	for i = 1, fe.map and #fe.map or #fe.options do
		if choiceOf(fe, i) == label then return i end
	end
end
local function toShared(e, fl, label)
	for s, f in pairs(e.alias and e.alias[fl] or {}) do
		if f == label then return s end
	end
	return label
end
local function toFrame(e, fl, label)
	local a = e.alias and e.alias[fl]
	return a and a[label] or label
end
local function sameValue(a, b)
	if type(a) == "number" and type(b) == "number" then return math.abs(a - b) < 1e-6 end
	return a == b
end

-- The value of a frame's entry in the shared control's terms: a boolean, a number, or a choice label.
local function frameForm(e, fl, root)
	local v = valueOf(rowById(e.each[fl]), root)
	if e.type == "dropdown" then
		local c = choiceOf(rowById(e.each[fl]), v)
		return c and toShared(e, fl, c) or nil
	end
	return v
end
-- The first ticked frame that has an entry (any frame of the profile `root` when it is not the live one: the defaults).
local function firstFrame(e, anyFrame)
	local mask = anyFrame and full() or maskOf(e.section)
	for i, fl in ipairs(ZPerl.SettingsFrames) do
		if e.each[fl] and ticked(mask, i) then return fl end
	end
end
function sharedValue(e, root)
	local fl = firstFrame(e, root ~= ZPerl.layout)
	if not fl then return e.type == "check" and false or (e.type == "slider" and e.min or 0) end
	local v = frameForm(e, fl, root)
	if e.type == "dropdown" then
		for i, o in ipairs(e.options) do
			if o[2] == v then return i end
		end
		return 0
	elseif e.type == "slider" then
		return math.max(e.min, math.min(e.max, v))
	end
	return v
end

-- Write v through the entry of each ticked frame (overwriting its value), then run the appliers they want once. The Defaults
-- button would push one frame's default into all of them: it leaves shared controls alone.
function sharedStore(e, v)
	local mask = maskOf(e.section)
	collect = {}
	local ok, err = pcall(function()
		for i, fl in ipairs(ZPerl.SettingsFrames) do
			local id = e.each[fl]
			if id and ticked(mask, i) then
				local fe = rowById(id)
				local fv
				if e.type == "dropdown" then
					local o = e.options[v]
					fv = o and indexOfChoice(fe, toFrame(e, fl, o[2]))
				elseif e.type == "slider" then
					fv = math.max(fe.min, math.min(fe.max, v))
				else
					fv = v
				end
				if fv ~= nil and not sameValue(valueOf(fe, ZPerl.layout), fv) then store(fe, fv) end
			end
		end
	end)
	local names = {}
	for n in pairs(collect) do names[#names + 1] = n end
	collect = nil
	if not ok then error(err, 0) end
	apply(e, names)
end

-- The picker's setter: the shared controls of the section show the first ticked frame's value.
function setMask(section, v)
	masks[section] = v
	refresh()
end

-- The tooltip: the entry's text, the ticked frames whose value differs from the shown one, and, for a dropdown, the ticked
-- frames that have no choice for the shown value (they are left alone when it is picked).
local function sharedTip(e)
	return function()
		local first = firstFrame(e)
		if not first then return L[e.tip] .. "\n" .. L["No frame with this setting is ticked in Apply to."] end
		local mask, shown = maskOf(e.section), frameForm(e, first, ZPerl.layout)
		local differ, skipped = {}, {}
		for i, fl in ipairs(ZPerl.SettingsFrames) do
			if e.each[fl] and ticked(mask, i) then
				if fl ~= first and not sameValue(frameForm(e, fl, ZPerl.layout), shown) then differ[#differ + 1] = L[fl] end
				if e.type == "dropdown" and shown and not indexOfChoice(rowById(e.each[fl]), toFrame(e, fl, shown)) then skipped[#skipped + 1] = L[fl] end
			end
		end
		local text = L[e.tip]
		if #differ > 0 then text = text .. "\n" .. format(L["Differs: %s"], table.concat(differ, ", ")) end
		if #skipped > 0 then text = text .. "\n" .. format(L["Not changed: %s"], table.concat(skipped, ", ")) end
		return text
	end
end

------------------------------------------------------------------------------------------------ popup
StaticPopupDialogs["ZPERL_SETTINGS_CONFIRM"] = {
	text = "%s",
	button1 = ACCEPT,
	button2 = CANCEL,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, data) data() end,
}
local function confirm(text, fn)
	StaticPopup_Show("ZPERL_SETTINGS_CONFIRM", text, nil, fn)
end

------------------------------------------------------------------------------------------------ core functions
-- Reset to defaults and the layout rows change the whole profile; the old window disabled them in combat.
local function refuseInCombat()
	if InCombatLockdown() then
		ZPerl.Notice(L["Not available in combat."])
		return true
	end
end

-- The layout rows act through ZPerl.SelectLayout, ZPerl.NewLayout, ZPerl.CopyLayout, ZPerl.RenameLayout and
-- ZPerl.DeleteLayout (ZPerl_Globals.lua), which refuse in combat and on bad names with a notice.
function ZPerl.SettingsLayoutList()
	local ret = {}
	for _, name in ipairs(ZPerl.LayoutNames()) do ret[#ret + 1] = {name, name} end
	return ret
end
function ZPerl.SettingsDeleteList()
	local ret = {{"", L["Select a layout"]}}
	local active = ZPerl.ActiveLayout()
	for _, name in ipairs(ZPerl.LayoutNames()) do
		if name ~= "Default" and name ~= active then ret[#ret + 1] = {name, name} end
	end
	return ret
end
function ZPerl.SettingsGetLayout() return ZPerl.ActiveLayout() or "Default" end

-- Bar texture: Z-Perl's ten, then LibSharedMedia's status bar textures (read when the menu opens, so textures other
-- addons register later are in it). Saved as before: bar.texture = {name, file}, the file read by the frames.
local function sharedMedia()
	return LibStub and LibStub("LibSharedMedia-3.0", true)
end
function ZPerl.SettingsBarTextureList()
	local ret, seen = {}, {}
	for _, t in ipairs(ZPerl.BarTextures) do
		ret[#ret + 1] = {t[1], t[1], t[2]}
		seen[t[1]] = true
	end
	local media = sharedMedia()
	if media then
		for _, name in ipairs(media:List("statusbar")) do
			local file = media:Fetch("statusbar", name, true)
			if file and not seen[name] then
				ret[#ret + 1] = {name, name, file}
				seen[name] = true
			end
		end
	end
	return ret
end
function ZPerl.SettingsGetBarTexture()
	local t = ZPerl.layout and ZPerl.layout.bar and ZPerl.layout.bar.texture
	return type(t) == "table" and t[1] or ""
end
function ZPerl.SettingsSetBarTexture(name)
	for _, t in ipairs(ZPerl.SettingsBarTextureList()) do
		if t[1] == name then
			ZPerl.layout.bar = ZPerl.layout.bar or {}
			ZPerl.layout.bar.texture = {t[1], t[3]}
			return
		end
	end
end

-- Range spells: rangeFinder.<part>.spell (assist) and .spell2 (attack), set by the spell slot rows. 0 is empty (the key
-- cleared: the spellbook spell with the longest range is used). The old window stored spell names: they read as their spell ID.
local function rangeSpellKey(part, kind) return "rangeFinder." .. part .. "." .. (kind == "harm" and "spell2" or "spell") end
function ZPerl.SettingsGetRangeSpell(part, kind)
	local v = read(ZPerl.layout, rangeSpellKey(part, kind))
	if type(v) == "string" then
		local info = C_Spell.GetSpellInfo(v)
		return info and info.spellID or 0
	end
	return v or 0
end
function ZPerl.SettingsSetRangeSpell(part, kind, id)
	write(rangeSpellKey(part, kind), id ~= 0 and id or nil)
end

function ZPerl.SettingsSelectLayout(name)
	if name ~= ZPerl.ActiveLayout() then ZPerl.SelectLayout(name) end
	refresh()
end

-- Name entry: Blizzard's generic input box; its callback gets the typed text.
local function askName(text, arg, callback)
	StaticPopup_ShowCustomGenericInputBox({text = text, text_arg1 = arg, callback = callback, maxLetters = 32})
end
function ZPerl.SettingsNewLayout()
	askName(L["Name of the new layout (default settings):"], nil, ZPerl.NewLayout)
end
function ZPerl.SettingsCopyLayout()
	askName(L["Name of the copy of layout %s:"], ZPerl.ActiveLayout(), ZPerl.CopyLayout)
end
function ZPerl.SettingsRenameLayout()
	local old = ZPerl.ActiveLayout()
	if old == "Default" then
		ZPerl.Notice(L["The Default layout cannot be renamed."])
		return
	end
	askName(L["New name of layout %s:"], old, function(name) ZPerl.RenameLayout(old, name) end)
end

function ZPerl.SettingsDeleteLayout(name)
	if name == "" or refuseInCombat() then return end
	confirm(format(L["Delete layout %s?"], name), function()
		ZPerl.DeleteLayout(name)
		refresh()
	end)
end

-- Aura blacklist...: the blacklist editor is a tab of the options window (AuraBlacklist/ adds it through ZPerl.SettingsPages).
function ZPerl.SettingsOpenBlacklist() ZPerl.OpenSettings("Aura blacklist") end
-- Edit zone list...: the custom highlight list editor, a tab CustomHighlight/ZPerl_CustomHighlightConfig.lua adds the same way.
function ZPerl.SettingsOpenCustomZones() ZPerl.OpenSettings("Custom highlights") end

-- Reset colors: every color default, the frame backdrop and border, and the transparency.
function ZPerl.ResetColors()
	ZPerl.DefaultFrameAppearance()
	ZPerl.layout.color.gradient = ZPerl.DefaultGradientColors()
	ZPerl.layout.color.reaction = ZPerl.DefaultReactionColors()
	ZPerl.layout.color.bar = ZPerl.DefaultBarColors()
	ZPerl.OptionActions()
end

-- Reset position of a frame's aura blocks (key: the frame's profile table): the four offsets back to 0.
function ZPerl.SettingsResetAuraPos(key)
	for _, kind in ipairs({"buffs", "debuffs"}) do
		write(key .. "." .. kind .. ".x", 0)
		write(key .. "." .. kind .. ".y", 0)
	end
end

-- Raid page. While the switch is on Blizzard's raid frames are hidden (read when the raid frames load, so it takes effect after
-- a reload). Each group box is a numeric key of raid.group, which a dotted path cannot name.
-- Unlock frames: session state (ZPerl.Locked), not a profile key.
function ZPerl.SettingsGetUnlock() return ZPerl.Locked == 0 end
function ZPerl.SettingsSetUnlock(v)
	if refuseInCombat() then refresh() return end
	if v then ZPerl.UnlockFrames() else ZPerl.LockFrames() end
end
function ZPerl.SettingsGetRaid() return ZPerl.layout.raid.enable and true or false end
function ZPerl.SettingsSetRaid(v)
	ZPerl.layout.raid.enable = v and 1 or false
end
-- Raid Helper's own per-character table (1 on, 0 off); read where the warning shows, so nothing to apply
function ZPerl.SettingsGetAggroWarning() return ZPerlRaidHelperDB ~= nil and ZPerlRaidHelperDB.AggroWarning == 1 end
function ZPerl.SettingsSetAggroWarning(v)
	if ZPerlRaidHelperDB then ZPerlRaidHelperDB.AggroWarning = v and 1 or 0 end
end
-- Raid Monitor's own per-character table ZPerlRaidMonitorDB; its rows show while the addon is loaded. Enable, the classes
-- and Grow upwards re-run its setup (Init), which sets the secure header's attributes: they refuse in combat.
local function raidMon() return _G.ZPerl_RaidMonitor_Frame end
local RAIDMON_DEFAULT = {UnitWidth = 120, UnitHeight = 12, TargetWidth = 80, LowMana = 20, HighMana = 80, Alpha = 1, BackgroundAlpha = 0.8}
function ZPerl.SettingsHasRaidMonitor() return raidMon() ~= nil and type(ZPerlRaidMonitorDB) == "table" end
function ZPerl.SettingsRaidMonGet(key)
	local db = ZPerlRaidMonitorDB
	local v = type(db) == "table" and db[key]
	if v == nil or v == false then v = RAIDMON_DEFAULT[key] or false end
	return v
end
function ZPerl.SettingsRaidMonClassGet(class)
	local db = ZPerlRaidMonitorDB
	return type(db) == "table" and type(db.classes) == "table" and db.classes[class] and true or false
end
-- a switch that re-runs the setup (enabled, GrowUp, or a class with class set): refused in combat
function ZPerl.SettingsRaidMonSetSwitch(key, v, class)
	local f, db = raidMon(), ZPerlRaidMonitorDB
	if not f or type(db) ~= "table" then return end
	if refuseInCombat() then refresh() return end
	if class then
		if type(db.classes) ~= "table" then db.classes = {} end
		db.classes[class] = v and true or false
	else
		db[key] = v and 1 or false
	end
	f:Init()
end
-- a value read as the monitor draws: sizes re-lay the frame (deferred in combat by the monitor), alphas restyle it
function ZPerl.SettingsRaidMonSet(key, step, after, v)
	local f, db = raidMon(), ZPerlRaidMonitorDB
	if not f or type(db) ~= "table" then return end
	db[key] = floor(v / step + 0.5) * step
	if after == "sizes" then
		f:SetUnitSizes()
		f:SetFrameSizes()
	elseif after == "alpha" then
		f:SetupAlpha()
	end
end

-- Raid Helper (ZPerlRaidHelperDB) and Raid Admin (ZPerlRaidAdminDB): their own per-character tables, switches stored 1/0.
-- Their rows show while the addon is loaded. The Raid Helper's own functions wait for the end of combat to touch its
-- secure frames, so its rows work in combat; `after` names what to redraw once the value is stored.
local ADDON = {
	helper = {db = "ZPerlRaidHelperDB", frame = "ZPerl_RaidHelper_Frame",
		default = {UnitWidth = 100, UnitHeight = 26, MaxMainTanks = 10, Targets_Transparency = 0.8, Background_Transparency = 1,
			AssistsFrame_Transparency = 0.8, Assists_BackTransparency = 1, TooltipsWhich = 2}},
	admin = {db = "ZPerlRaidAdminDB", frame = "ZPerl_AdminFrame", default = {Transparency = 0.8}},
}
local function addonDB(which)
	local a = ADDON[which]
	local db = a and _G[a.db]
	if _G[a.frame] and type(db) == "table" then return db end
end
local function helper(fn, ...)
	local RH = ZPerl.RaidHelper
	if RH and RH[fn] then ZPerl.Pcall(RH[fn], ...) end
end
---@type table<string, fun(db: table)>
local AFTER = {
	enable = function() helper("EnableDisable") end, -- also rebuilds the tank list (MTRosterChanged)
	frame = function() helper("SetFrameSizes") end,
	sizes = function() helper("MTListApplyUnitSizes") helper("SetFrameSizes") end,
	tanks = function() helper("MakeTankList") helper("SetTitle") helper("SetFrameSizes") end,
	-- the counters redraw on target and roster events only: recount and redraw now (the Assists window's own refresh)
	counters = function() helper("UpdateAssists") helper("ShowAssists") end,
	alpha = function(db) ZPerl_RaidHelper_Frame:SetAlpha(db.Targets_Transparency) end,
	back = function(db) helper("SetupFrameSimple", ZPerl_RaidHelper_Frame, db.Background_Transparency) end,
	assistalpha = function(db) if ZPerl_Assists_Frame then ZPerl_Assists_Frame:SetAlpha(db.AssistsFrame_Transparency) end end,
	assistback = function(db)
		if ZPerl_Assists_Frame then helper("SetupFrameSimple", ZPerl_Assists_Frame, db.Assists_BackTransparency) end
		if ZPerl_ScrollSeperator then ZPerl_ScrollSeperator:SetAlpha(db.Assists_BackTransparency) end
	end,
	adminauto = function() if ZPerl.RaidAdmin and ZPerl.RaidAdmin.AdminCheckMyRank then ZPerl.Pcall(ZPerl.RaidAdmin.AdminCheckMyRank) end end,
	adminalpha = function(db)
		if ZPerl_Check then ZPerl_Check:SetAlpha(db.Transparency) end
		ZPerl_AdminFrame:SetAlpha(db.Transparency)
	end,
}
function ZPerl.SettingsHasAddon(which) return addonDB(which) ~= nil end
-- a switch (1 on, 0 off)
function ZPerl.SettingsAddonGetSwitch(which, key)
	local db = addonDB(which)
	return db ~= nil and db[key] == 1
end
function ZPerl.SettingsAddonSetSwitch(which, key, after, v)
	local db = addonDB(which)
	if not db then return end
	db[key] = v and 1 or 0
	if AFTER[after] then AFTER[after](db) end
end
-- a number (a slider, or a dropdown of numbers)
function ZPerl.SettingsAddonGet(which, key)
	local db = addonDB(which)
	local v = db and tonumber(db[key])
	if v == nil then v = ADDON[which].default[key] or 0 end
	return v
end
---@param which string
---@param key string
---@param step number?
---@param after string?
---@param v number
function ZPerl.SettingsAddonSet(which, key, step, after, v)
	local db = addonDB(which)
	if not db then return end
	db[key] = step and floor(v / step + 0.5) * step or v
	if AFTER[after] then AFTER[after](db) end
end
-- Raid Helper health text: HealerMode 1 shows the deficit, HealerModeType 1 adds the maximum (ZPerl_RaidHelper.lua)
function ZPerl.SettingsHelperHealerGet()
	local db = addonDB("helper")
	if not db or db.HealerMode ~= 1 then return 0 end
	return db.HealerModeType == 1 and 2 or 1
end
function ZPerl.SettingsHelperHealerSet(v)
	local db = addonDB("helper")
	if not db then return end
	db.HealerMode = v ~= 0 and 1 or 0
	if v ~= 0 then db.HealerModeType = v == 2 and 1 or 0 end
	AFTER.tanks(db)
end

local function groupGet(i) return function() return ZPerl.layout.raid.group[i] and true or false end end
local function groupSet(i) return function(v) ZPerl.layout.raid.group[i] = v and 1 or false end end
ZPerl.SettingsGetRaidGroup1 = groupGet(1)
ZPerl.SettingsSetRaidGroup1 = groupSet(1)
ZPerl.SettingsGetRaidGroup2 = groupGet(2)
ZPerl.SettingsSetRaidGroup2 = groupSet(2)
ZPerl.SettingsGetRaidGroup3 = groupGet(3)
ZPerl.SettingsSetRaidGroup3 = groupSet(3)
ZPerl.SettingsGetRaidGroup4 = groupGet(4)
ZPerl.SettingsSetRaidGroup4 = groupSet(4)
ZPerl.SettingsGetRaidGroup5 = groupGet(5)
ZPerl.SettingsSetRaidGroup5 = groupSet(5)
ZPerl.SettingsGetRaidGroup6 = groupGet(6)
ZPerl.SettingsSetRaidGroup6 = groupSet(6)
ZPerl.SettingsGetRaidGroup7 = groupGet(7)
ZPerl.SettingsSetRaidGroup7 = groupSet(7)
ZPerl.SettingsGetRaidGroup8 = groupGet(8)
ZPerl.SettingsSetRaidGroup8 = groupSet(8)
-- 9-13: the class columns of Sort by Class
for i = 9, 13 do
	ZPerl["SettingsGetRaidGroup" .. i] = groupGet(i)
	ZPerl["SettingsSetRaidGroup" .. i] = groupSet(i)
end
-- All and None set every group and class box, as the old window's buttons did (a class box shows a class column of Sort by Class).
local function raidGroupsAll(show)
	local r = ZPerl.layout.raid
	for i = 1, #r.group do r.group[i] = show and 1 or false end
	for _, c in ipairs(r.class) do c.enable = show and 1 or false end
	ZPerl.Apply({"raidheaders", "raid"})
end
function ZPerl.SettingsRaidGroupsAll() raidGroupsAll(true) end
function ZPerl.SettingsRaidGroupsNone() raidGroupsAll(false) end

------------------------------------------------------------------------------------------------ click
local function click(e)
	if e.nocombat and refuseInCombat() then return end
	local function run()
		if e.nocombat and refuseInCombat() then return end
		local f = e.func
		if f then f(e.arg) end
		if e.arg then apply(e) end -- a button with an arg re-runs its appliers
		refresh()
	end
	if e.confirm then confirm((L[e.confirm]:gsub("{layout}", function() return ZPerl.ActiveLayout() or "Default" end)), run) else run() end
end

-- The panel row's own write path, for other callers (the frame menu): the value write, then the row's appliers.
function ZPerl.SettingsSetRow(id, v)
	store(rowById(id), v)
end
function ZPerl.SettingsGetRow(id) return valueOf(rowById(id), ZPerl.layout) end
function ZPerl.SettingsRefresh() refresh() end -- the layout and profile changes

-- What the options window (ZPerl_OptionsControls.lua, ZPerl_OptionsWindow.lua) uses: the value logic stays here.
ZPerl.SettingsCore = {
	valueOf = valueOf, store = store, rowById = rowById, sharedTip = sharedTip, click = click, maskOf = maskOf, setMask = setMask,
	read = read, norm = norm, on = on, hexOf = hexOf, ticked = ticked,
}
