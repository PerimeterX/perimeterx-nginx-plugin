local _M = {}

-- ##  Configuration Block ##
_M.px_token = 'my_temporary_token'
_M.px_appId = 'PXAPPID'
_M.px_server = 'collector.a.pxi.pub'
_M.px_port = 443
_M.ssl_enabled = true
_M.cookie_lifetime = 600 -- cookie lifetime, value in seconds
_M.px_debug = false
_M.px_maxbuflen = 500
-- -- ## END - Configuration block ##

return _M
