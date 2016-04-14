----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------

local _M = {}

_M.Whitelist = {};

-- Full URI filter
-- will filter requests where the uri starts with any of the list below.
-- example:
-- filter: example.com/api_server_full?data=data
-- will not filter: example.com/api_server?data=data
-- _M.Whitelist['uri_full'] = {'/', '/api_server_full' }
_M.Whitelist['uri_full'] = {}

-- URI Prefixes filter
-- will filter requests where the uri starts with any of the list below.
-- example:
-- filter: example.com/api_server_full?data=data
-- will not filter: example.com/full_api_server?data=data
-- _M.Whitelist['uri_prefixes'] = {'/api_server'}
_M.Whitelist['uri_prefixes'] = {}

-- URI Suffixes filter
-- will filter requests where the uri starts with any of the list below.
-- example:
-- filter: example.com/mystyle.css?data=data
-- _M.Whitelist['uri_prefixes'] = {'.css'}
_M.Whitelist['uri_suffixes'] = { '.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', 'webp', '.jar' }

-- IP Addresses filter
-- will filter requests coming from the ip in the list below
-- _M.Whitelist['ip_addresses'] = {'192.168.99.1'}
_M.Whitelist['ip_addresses'] = {}

-- Full useragent
-- will filter requests coming with a full user agent
--_M.Whitelist['ua_full'] = {'Mozilla/5.0 (compatible; pingbot/2.0;  http://www.pingdom.com/)'}
_M.Whitelist['ua_full'] = {}

-- filter by user agent substring
--_M.Whitelist['ua_sub'] = {'Inspectlet', 'GoogleCloudMonitoring'}
_M.Whitelist['ua_sub'] = {}

function _M.process()
    local req_method = ngx.var.request_method
    if req_method ~= 'GET' then
        return true
    end

    -- Check for whitelisted request
    -- White By Substring in User Agent
    local wluas = _M.Whitelist['ua_sub']
    -- reverse client string builder
    for i = 1, #wluas do
        if ngx.var.http_user_agent and wluas[i] then
            local k = string.find(ngx.var.http_user_agent, wluas[i])
            if k == 1 then
                ngx.log(ngx.ERR, "Whitelisted: ua_full")
                return true
            end
        end
    end

    -- Whitelist By Full User Agent
    local wluaf = _M.Whitelist['ua_full']
    -- reverse client string builder
    for i = 1, #wluaf do
        if ngx.var.http_user_agent and wluaf[i] and ngx.var.http_user_agent == wluaf[i] then
            ngx.log(ngx.ERR, "Whitelisted: ua_sub")
            return true
        end
    end

    -- Check for whitelisted request
    -- By IP
    local wlips = _M.Whitelist['ip_addresses']
    -- reverse client string builder
    for i = 1, #wlips do
        if ngx.var.remote_addr == wlips[i] then
            ngx.log(ngx.ERR, "Whitelisted: ip_addresses")
            return true
        end
    end

    local wlfuri = _M.Whitelist['uri_full']
    -- reverse client string builder
    for i = 1, #wlfuri do
        if ngx.var.uri == wlfuri[i] then
            ngx.log(ngx.ERR, "Whitelisted: uri_full")
            return true
        end
    end

    local wluri = _M.Whitelist['uri_prefixes']
    -- reverse client string builder
    for i = 1, #wluri do
        if string.sub(ngx.var.uri, 1, string.len(wluri[i])) == wluri[i] then
            ngx.log(ngx.ERR, "Whitelisted: uri_prefixes")
            return true
        end
    end

    local wluris = _M.Whitelist['uri_suffixes']
    -- reverse client string builder
    for i = 1, #wluris do
        if string.sub(ngx.var.uri, -string.len(wluris[i])) == wluris[i] then
            ngx.log(ngx.ERR, "Whitelisted: uri_suffix")
            return true
        end
    end

    return false
end

return _M