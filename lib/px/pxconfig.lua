----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local _M = {}

_M.px_enabled = true

-- ## Required Parameters ##
_M.px_appId = 'PX_APP_ID'
_M.cookie_secret = 'COOKIE_KEY'
_M.auth_token = 'PX_AUTH_TOKEN'

return _M
