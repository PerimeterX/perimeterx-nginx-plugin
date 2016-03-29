----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------
local pxFilters = require "px.pxfilters"

-- ## Configuration Block ##
local px_token = 'my_temporary_token';
local pxserver = 'collector.a.pxi.pub'
local pxport = 80
local px_appId = 'PX3tHq532g';
local cookie_lifetime = 600 -- cookie lifetime, value in seconds
local pxdebug = false
-- ## END - Configuration block ##

local req_method = ngx.var.request_method
if req_method == 'OPTIONS' or req_method == 'HEAD' then
    return 0
end

-- Check for whitelisted request
-- White By Substring in User Agent
local wluas = pxFilters.Whitelist['ua_sub']
-- reverse client string builder
for i = 1, #wluas do
    if ngx.var.http_user_agent and wluas[i] then
        local k = string.find(ngx.var.http_user_agent, wluas[i])
        if k == 1 then
            ngx.log(ngx.INFO, "Whitelisted: ua_full")
            return 0
        end
    end
end

-- Whitelist By Full User Agent
local wluaf = pxFilters.Whitelist['ua_full']
-- reverse client string builder
for i = 1, #wluaf do
    if ngx.var.http_user_agent and wluaf[i] and ngx.var.http_user_agent == wluaf[i] then
        ngx.log(ngx.INFO, "Whitelisted: ua_sub")
        return 0
    end
end

-- Check for whitelisted request
-- By IP
local wlips = pxFilters.Whitelist['ip_addresses']
-- reverse client string builder
for i = 1, #wlips do
    if ngx.var.remote_addr == wlips[i] then
        ngx.log(ngx.INFO, "Whitelisted: ip_addresses")
        return 0
    end
end

local wlfuri = pxFilters.Whitelist['uri_full']
-- reverse client string builder
for i = 1, #wlfuri do
    if ngx.var.uri == wlfuri[i] then
        ngx.log(ngx.INFO, "Whitelisted: uri_full")
        return 0
    end
end

local wluri = pxFilters.Whitelist['uri_prefixes']
-- reverse client string builder
for i = 1, #wluri do
    if string.sub(ngx.var.uri, 1, string.len(wluri[i])) == wluri[i] then
        ngx.log(ngx.INFO, "Whitelisted: uri_prefixes")
        return 0
    end
end


ngx.log(ngx.INFO, "Passed whitelisting filter")
-- Generate an encrypted user-unique key
function gen_pxIdentifier()
    local sec_now_str = tostring(ngx.time());
    local ip = '';
    if ngx.var.remote_addr then
        local ip = ngx.var.remote_addr;
    end

    local ua = '';
    if ngx.var.http_user_agent then
        ua = ngx.var.http_user_agent;
    end
    local identifier = ngx.hmac_sha1(px_token, px_appId .. ip .. ua);
    return ngx.encode_base64(identifier .. sec_now_str);
end

-- Validating the user key came from px-cookie and match against the locally generated one
function validate_pxIdentifier(identifier, px_cookie)
    local re_pxcook = ''

    -- if no cookie we stop validation
    if px_cookie == nil or #px_cookie == 0 then
        return false
    end

    -- reverse client string builder
    for i = 1, #px_cookie do
        if not (i % 5 == 0) then
            local c = px_cookie:sub(i, i)
            re_pxcook = re_pxcook .. c
        end
    end

    -- no need to continure and check if length doesnt match
    if not (#re_pxcook == #identifier) then
        return false
    end

    -- extract sha key from identifier and cookie
    re_pxcook = ngx.decode_base64(re_pxcook)
    identifier = ngx.decode_base64(identifier)

    -- separting the timestamp and key from the cookie value
    local re_pxcook_time = re_pxcook:sub(#re_pxcook - 9, #re_pxcook)
    local re_pxcook_key = re_pxcook:sub(1, #re_pxcook - 10)
    local identifier_key = identifier:sub(1, #re_pxcook - 10)

    -- validate time is still in range
    if tonumber(re_pxcook_time) + cookie_lifetime < ngx.time() then
        return false
    end

    -- validate key and cookie key
    if not (identifier_key == re_pxcook_key) then
        return false
    end
    return true
end

-- initilize identifier, cookie to perform check, vars that are not allowed in async API must be set in the ctx
ngx.ctx.pxdebug = pxdebug
ngx.ctx.px_app_id = px_appId
ngx.ctx.pxserver = pxserver
ngx.ctx.pxport = pxport
ngx.ctx.px_token = px_token
ngx.ctx.method = ngx.req.get_method()
ngx.ctx.headers = ngx.req.get_headers()
ngx.ctx.host = ngx.var.host
ngx.ctx.uri = ngx.var.uri
ngx.ctx.remote_addr = ngx.var.remote_addr
ngx.ctx.user_agent = ngx.var.http_user_agent

ngx.ctx.pxidentifier = gen_pxIdentifier()
local pxcook = ngx.var.cookie__pxcook

if not validate_pxIdentifier(ngx.ctx.pxidentifier, pxcook) then
    return 1
end

return 0
