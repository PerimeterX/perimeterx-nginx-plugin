----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

function M.load(px_config)
    local _M = {}

    local px_logger = require ("px.utils.pxlogger").load(px_config)
    local px_headers = require ("px.utils.pxheaders").load(px_config)
    local string_sub = string.sub
    local string_find = string.find
    local string_len = string.len
    local string_gsub = string.gsub

    _M.Whitelist = {};

    -- Full URI filter
    -- will filter requests where the uri starts with any of the list below.
    -- example:
    -- filter: example.com/api_server_full?data=data
    -- will not filter: example.com/api_server?data=data
    -- _M.Whitelist['uri_full'] = {'/', '/api_server_full' }
    -- Note: px_config.custom_block_url should not be removed from here if using custom_block_url configuration
    -- _M.Whitelist['uri_full'] = { px_config.custom_block_url }
    _M.Whitelist['uri_full'] = px_config.whitelist_uri_full and px_config.whitelist_uri_full or { }
    -- URI Prefixes filter
    -- will filter requests where the uri starts with any of the list below.
    -- example:
    -- filter: example.com/api_server_full?data=data
    -- will not filter: example.com/full_api_server?data=data
    -- _M.Whitelist['uri_prefixes'] = {'/api_server'}
    _M.Whitelist['uri_prefixes'] = px_config.whitelist_uri_prefixes and px_config.whitelist_uri_prefixes or {}

    -- URI Suffixes filter
    -- will filter requests where the uri starts with any of the list below.
    -- example:
    -- filter: example.com/mystyle.css?data=data
    -- _M.Whitelist['uri_suffixes'] = {'.css'}
    _M.Whitelist['uri_suffixes'] = px_config.whitelist_uri_suffixes and px_config.whitelist_uri_suffixes or {}

    -- IP Addresses filter
    -- will filter requests coming from the ip in the list below
    -- _M.Whitelist['ip_addresses'] = {'192.168.99.1'}
    _M.Whitelist['ip_addresses'] = px_config.whitelist_ip_addresses and px_config.whitelist_ip_addresses or {}

    -- Full useragent
    -- will filter requests coming with a full user agent
    --_M.Whitelist['ua_full'] = {'Mozilla/5.0 (compatible; pingbot/2.0;  http://www.pingdom.com/)'}
    _M.Whitelist['ua_full'] = px_config.whitelist_ua_full and px_config.whitelist_ua_full or {}

    -- filter by user agent substring
    --_M.Whitelist['ua_sub'] = {'Inspectlet', 'GoogleCloudMonitoring'}
    _M.Whitelist['ua_sub'] = px_config.whitelist_ua_sub and px_config.whitelist_ua_sub or {}

    -- Escape Lua magic chars in a string
    local function escape_magic_chars(pattern)
        local magic_chars = { '%', '(',  ')' , '.',  '+' , '-', '*', '?', '[' ,']' ,'^', '$' }
        for i = 1 , #magic_chars do
            pattern = string_gsub(pattern, "%" .. magic_chars[i], "%%%1")
        end
        return pattern
    end

    -- Process the whitelist
    function _M.process()
        -- by user agent - pattern match
        local ua = ngx.var.http_user_agent

        if ua then
            --  By user agent - strict match
            local wluaf = _M.Whitelist['ua_full']
            if #wluaf > 0 then
                for i = 1, #wluaf do
                    if wluaf[i] == ua then
                        px_logger.debug("Whitelisted: UA strict match " .. wluaf[i])
                        return true
                    end
                end
            end

            local wluas = _M.Whitelist['ua_sub']
            if #wluas > 0 then
                for i = 1, #wluas do
                    local k,j = string_find(ua, escape_magic_chars(wluas[i]))
                    if k then
                        px_logger.debug("Whitelisted: UA partial match " .. wluas[i])
                        return true
                    end
                end
            end
        end

        -- By IP address
        local ip_address = px_headers.get_ip()
        local wlips = _M.Whitelist['ip_addresses']
        for i = 1, #wlips do
            if ip_address == wlips[i] then
                px_logger.debug("Whitelisted: IP address  " .. wlips[i])
                return true
            end
        end

        -- By URI
        local uri = ngx.var.uri
        if uri == px_config.custom_block_url then
            px_logger.debug("Whitelisted: custom_block_url.")
            return true
        end

        local wlfuri = _M.Whitelist['uri_full']
        for i = 1, #wlfuri do
            if uri == wlfuri[i] then
                px_logger.debug("Whitelisted: uri_full. " .. wlfuri[i])
                return true
            end
        end

        local wluri = _M.Whitelist['uri_prefixes']
        for i = 1, #wluri do
            if string_sub(uri, 1, string_len(wluri[i])) == wluri[i] then
                px_logger.debug("Whitelisted: uri_prefixes. " .. wluri[i])
                return true
            end
        end

        local wluris = _M.Whitelist['uri_suffixes']
        for i = 1, #wluris do
            if string_sub(uri, -string_len(wluris[i])) == wluris[i] then
                px_logger.debug("Whitelisted: uri_suffix. " .. wluris[i])
                return true
            end
        end

        return false
    end
    return _M
end
return M
