--
--This module try to match new clients to pre-defined arguments
--It can be used to override Tyrannical or set special rules 
--when spawning clients. It use both X11 clients and
--FreeDesktop.org Startup notifications for matching commands
--
-- 1) Spawn command, get the PID and SN_ID
-- 2) Wait and listen for SN events
-- 3) When manage come, see if it has an SN_ID
--   3.1) If yes, use it
--   3.2) If no, but the PID match, use the PID
--   3.3) TODO expose the WM_COMMAND property and use it to check recent startup id
-- 4) Wait for timeout, give up
-- 5) Have housekeeping timer to cleaup old SN
--
local print = print
local pairs = pairs
local awful = require("awful")
local tyrannical = require("tyrannical")
local capi = {awesome=awesome,client=client}

local module = {}

local by_pid,by_ns={},{}

local function on_callback(c,startup)
    if not c.startup_id then return false end
    local sn_data = by_ns[c.startup_id]
    by_ns[c.startup_id] = nil
    if sn_data then
        if sn_data.tags or {sn_data.tag} then
            sn_data.intrusive = false
        end
        return sn_data
    end
    return {},{}
end

-- module.spawn = function(args)
--     local args = args or {}
--     local param = {
--         command     = args.command    ,
--         initiated_f = args.initiated_f,
--         canceled_f  = args.canceled_f ,
--         completed_f = args.completed_f,
--         timeout_f   = args.timeout_f  ,
--         screen      = args.screen     ,
--     }
--     local pid,snid = awful.util.spawn(param.command,true)
--     if pid then
--         param.pid = pid
--         by_pid[pid] = param
--     end
--     if snid then
--         param.startup_id = snid
--         by_ns[snid] = param
--         tyrannical.sn_callback[snid] = on_callback
--     end
--     return 100
-- end

module.spawn2 = function(command,args)
    local args = args or {}
--     if type(args) == "boolean"
    local pid,snid = awful.util.spawn(command,true)
    if snid then
        by_ns[snid] = args
        tyrannical.sn_callback[snid] = on_callback
    end
    return pid,snid
end

--------SN Callbacks------

local function on_canceled(sn)
    -- Let the GC collect the array, it wont work
    by_ns[sn] = nil
end

-- local function on_change(sn)
--     print("on_change")
--     for k,v in pairs(sn) do print (k,v) end
-- end

capi.awesome.connect_signal("spawn::canceled" , on_canceled  )
capi.awesome.connect_signal("spawn::timeout"  , on_canceled   )
-- capi.awesome.connect_signal("spawn::change"   , on_change    )

return module