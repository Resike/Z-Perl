-- Z-Perl core: the combat-deferral queue.
-- Loads before ZPerl.lua; at load it uses client APIs only.

-- ZPerl.EventValid(event)
-- Retail treats some removed events (the combat log) as *forbidden*: even a
-- pcall-wrapped RegisterEvent/UnregisterEvent raises ADDON_ACTION_FORBIDDEN and
-- taints the addon. So the client is asked first and such events are never touched.
function ZPerl.EventValid(event)
	-- C_EventUtils.IsEventValid still says "valid" for the combat log on Midnight
	-- because the engine keeps it for Blizzard code. Retail and Forever withhold it
	-- from addons, so never touch it there. Not keyed on issecretvalue: Classic Era
	-- has the secret-value API too and still gives addons the combat log.
	if (event == "COMBAT_LOG_EVENT_UNFILTERED" and (ZPerl.IsRetail or ZPerl.IsForever)) then
		return false
	end
	if (C_EventUtils and C_EventUtils.IsEventValid) then
		return C_EventUtils.IsEventValid(event) and true or false
	end
	return true
end

-- ZPerl.RegisterEventSafe / ZPerl.UnregisterEventSafe / ZPerl.RegisterUnitEventSafe
-- Register/unregister that never errors on an event the client no longer has
function ZPerl.RegisterEventSafe(frame, event)
	if (not ZPerl.EventValid(event)) then
		return false
	end
	return pcall(frame.RegisterEvent, frame, event)
end

function ZPerl.UnregisterEventSafe(frame, event)
	if (not ZPerl.EventValid(event)) then
		return false
	end
	return pcall(frame.UnregisterEvent, frame, event)
end

function ZPerl.RegisterUnitEventSafe(frame, event, ...)
	if (not ZPerl.EventValid(event)) then
		return false
	end
	return pcall(frame.RegisterUnitEvent, frame, event, ...)
end

-- ZPerl.AfterCombat(func, arg)
-- Out of combat: func(arg) at once. In combat: stored and called on PLAYER_REGEN_ENABLED, in the
-- order first queued. One entry per func; a later call replaces arg. A nil arg is stored too, so
-- no call is dropped.
local NO_ARG = {}
local order, pending = {}, {}

function ZPerl.AfterCombat(func, arg)
	if (not InCombatLockdown()) then
		func(arg)
		return
	end
	if (pending[func] == nil) then
		order[#order + 1] = func
	end
	if (arg == nil) then
		arg = NO_ARG
	end
	pending[func] = arg
end

-- ZPerl.AfterCombatFor(func, frame): ZPerl.AfterCombat(func, frame) with one entry per frame, for
-- functions that run on several frames (Target and Focus, the party frames).
local perFrame = {}

function ZPerl.AfterCombatFor(func, frame)
	local byFrame = perFrame[func]
	if (not byFrame) then
		byFrame = {}
		perFrame[func] = byFrame
	end
	local run = byFrame[frame]
	if (not run) then
		run = function() func(frame) end
		byFrame[frame] = run
	end
	ZPerl.AfterCombat(run)
end

-- Lua 5.1 xpcall passes no arguments to the call, so the entry is handed over in these upvalues;
-- the error handler then receives the stack of the failing entry.
local runFunc, runArg
local function run()
	runFunc(runArg)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function()
	-- A call that queues again lands in the new queue, so a failed lockdown check cannot loop.
	local list, args = order, pending
	order, pending = {}, {}
	if (#list > 0) then
		local d = ZPerl.Dev; if d and d.listener then d.Emit("combatqueue.run", #list) end
	end
	for i = 1, #list do
		runFunc = list[i]
		runArg = args[runFunc]
		if (runArg == NO_ARG) then
			runArg = nil
		end
		xpcall(run, geterrorhandler())
	end
end)

-- ZPerl.GroupVisibilityUpdate()
-- The one decision for the party header (the party pet frames hang off it), the raid group headers
-- and the raid pet header, from IsInRaid, the group, party.inRaid and party.smallRaid.
-- Runs out of combat, or after it through ZPerl.AfterCombat.
-- Called on the events below and wherever an option, a raid roster change or setup can change the
-- answer. The modules it touches are optional: a frame that does not exist is skipped.
local function applyGroupVisibility()
	local conf = ZPerl.layout
	local pconf = conf and conf.party
	if (not pconf) then
		return
	end
	local inRaid = IsInRaid()
	-- smallRaid: in a raid of one subgroup the party frames show and the raid groups and raid pets
	-- hide. The raid headers wait for the first raid update (ZPerl.Raid.Initialized); the pet header
	-- does not.
	local small = pconf.smallRaid and ZPerl.Party.SingleGroup and ZPerl.Party.SingleGroup()

	local party = ZPerl_Party_SecureHeader
	if (party) then
		-- Outside a raid the header stays shown, solo too: it shows no member without a group, and a
		-- shown header assigns the members itself when a group forms, in combat too (showing it is protected)
		local show = pconf.enable
		if (show and inRaid) then
			show = small or (pconf.inRaid and not pconf.smallRaid)
		end
		party:SetShown(show and true or false)
	end

	local rconf = conf.raid
	if (ZPerl.Raid.Headers and rconf) then
		local enable = rconf.enable
		if (enable) then
			local _, instanceType = IsInInstance()
			if (instanceType == "pvp") then
				enable = not rconf.notInBG
			end
		end
		for i, header in ipairs(ZPerl.Raid.Headers) do
			header:SetShown(rconf.group[i] and enable and (i < 9 or rconf.sortByClass) and not (small and ZPerl.Raid.Initialized) and true or false)
		end
	end

	local petconf = conf.raidpet
	if (ZPerl.RaidPets.Ready and petconf) then
		if (petconf.enable and not small) then
			ZPerl_Raid_GrpPets:Show()
			ZPerl_RaidPets_Frame:Show()
			ZPerl_Raid_TitlePets:Show()
		else
			ZPerl_RaidPets_Frame:Hide()
			ZPerl_Raid_TitlePets:Hide()
			ZPerl_Raid_GrpPets:Hide()
		end
	end

	if (ZPerl.RaidPets.Align) then
		ZPerl.RaidPets.Align()
	end
end

-- Runs per roster event, not debounced, on purpose: no table is built and a SetShown to the current
-- state changes nothing (about 15 calls); visprobe.lua and the raid frames' first-update flag
-- (ZPerl.Raid.Initialized) expect the decision to be made in the event itself, before the
-- C_Timer.After(0) roster work of the raid module. A debounce would move it a frame later.
function ZPerl.GroupVisibilityUpdate()
	ZPerl.AfterCombat(applyGroupVisibility)
end

-- The events that run it are registered through ZPerl.On in ZPerl.lua.
C_Timer.After(0, ZPerl.GroupVisibilityUpdate)

-- ZPerl.On(event, fn) / ZPerl.Off(event, fn)
-- The event bus for events that are not tied to a unit frame: one frame, one registration per event,
-- fn(event, ...) per listener in the order added. fn must be a function, so an event cannot be
-- registered without a handler. An event the client does not know is skipped by
-- ZPerl.RegisterEventSafe.
local listeners = {}
local bus = CreateFrame("Frame")

function ZPerl.On(event, fn)
	if (type(fn) ~= "function") then
		error("ZPerl.On(" .. tostring(event) .. "): handler is " .. type(fn), 2)
	end
	local list = listeners[event]
	if (not list) then
		list = {}
		listeners[event] = list
		ZPerl.RegisterEventSafe(bus, event)
	end
	list[#list + 1] = fn
end

function ZPerl.Off(event, fn)
	local old = listeners[event]
	if (not old) then
		return
	end
	-- A new list, so a dispatch loop running over the old one is not shifted
	local list, removed = {}, false
	for i = 1, #old do
		if (not removed and old[i] == fn) then
			removed = true
		else
			list[#list + 1] = old[i]
		end
	end
	listeners[event] = list
	if (#list == 0) then
		listeners[event] = nil
		ZPerl.UnregisterEventSafe(bus, event)
	end
end

local function onBusEvent(_, event, ...)
	local list = listeners[event]
	if (list) then
		-- securecallfunction: an error goes to the error handler and the later listeners still run
		for i = 1, #list do
			securecallfunction(list[i], event, ...)
		end
	end
end
bus:SetScript("OnEvent", onBusEvent)

-- The dev API (ZPerl_Dev.lua) reads the listeners and dispatches an event to them.
ZPerl.DevBus = {listeners = listeners, dispatch = function(event, ...) onBusEvent(nil, event, ...) end}

-- ZPerl.Every(interval, fn) / ZPerl.Cancel(fn)
-- The scheduler: one C_Timer.NewTicker per distinct interval, created on first use and cancelled when
-- its bucket empties. fn() runs every interval seconds, in the order added; an error goes to the
-- error handler and the others still run. The same fn can be added to one bucket only once.
local buckets = {} -- Interval -> {fns = {...}, snapshot = {...} or nil, ticker = ...}

local function tick(bucket)
	local snapshot = bucket.snapshot
	if (not snapshot) then
		snapshot = {unpack(bucket.fns)}
		bucket.snapshot = snapshot
	end
	for i = 1, #snapshot do
		xpcall(snapshot[i], geterrorhandler())
	end
end

function ZPerl.Every(interval, fn)
	if (type(fn) ~= "function") then
		error("ZPerl.Every(" .. tostring(interval) .. "): handler is " .. type(fn), 2)
	end
	local bucket = buckets[interval]
	if (not bucket) then
		bucket = {fns = {}}
		buckets[interval] = bucket
		bucket.ticker = C_Timer.NewTicker(interval, function() tick(bucket) end)
	end
	for i = 1, #bucket.fns do
		if (bucket.fns[i] == fn) then
			return
		end
	end
	bucket.fns[#bucket.fns + 1] = fn
	bucket.snapshot = nil
end

function ZPerl.Cancel(fn)
	for interval, bucket in pairs(buckets) do
		for i = #bucket.fns, 1, -1 do
			if (bucket.fns[i] == fn) then
				tremove(bucket.fns, i)
				bucket.snapshot = nil
			end
		end
		if (#bucket.fns == 0) then
			bucket.ticker:Cancel()
			buckets[interval] = nil
		end
	end
end
