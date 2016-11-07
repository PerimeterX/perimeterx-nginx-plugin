----------------------------------------------
---- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
------------------------------------------------

local cjson = require "cjson"
local _M = {}

local events = {}
local lock = false

-- lockBuffer sets the lock to true
function _M.lockBuffer()
    lock = true
    return
end

-- unlockBuffer sets the lock to false
function _M.unlockBuffer()
    lock = false
    return
end

-- getBufferLock returns the lock status
function _M.getBufferLock()
    return lock
end

-- getBufferLength returns the amount of events in the event table
function _M.getBufferLength()
    return #events
end

-- addEvent puts and event into the events table
function _M.addEvent(event)
    local lock = _M.getBufferLock()
    repeat
        if lock == false then
            events[#events + 1] = event
            return
        end
        lock = _M.getBufferLock()
    until true
    return
end

-- resetBuffer sets events to be empty
local function resetBuffer()
    events = {}
end

-- dumpEvents returns a json encoded array of data from the events table
function _M.dumpEvents()
    _M.lockBuffer()
    local tempEvents = events
    resetBuffer()
    _M.unlockBuffer()
    local jsonEvents = cjson.encode(tempEvents)
    return jsonEvents
end

return _M
