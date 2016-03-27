local buffer = require "px.pxbuffer"
local pxclient = require "px.pxclient"
local ngx_timer_at = ngx.timer.at
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR

local function submit_on_timer()
    local ok, err = ngx_timer_at(1, submit_on_timer)
    if not ok then
        ngx_log(ngx_ERR, "Failed to schedule submit timer: ".. err)
    end
    local buflen = buffer.getBufferLength()   
    if buflen > 0 then
        pxclient.submit(buffer.dumpEvents())
    end
    return
end

submit_on_timer()
