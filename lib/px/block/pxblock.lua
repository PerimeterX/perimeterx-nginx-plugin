local ngx_HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN
local ngx_say = ngx.say
local ngx_exit = ngx.exit

local _M = {}

function _M.block()
    ngx.status = ngx_HTTP_FORBIDDEN
    ngx.header["Content-Type"] = 'text/html'
    ngx_say("<H1>You are not authorized to view this page.</H1>")
    ngx.exit(ngx.OK)
end

return _M


