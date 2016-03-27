----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------
local pxClient = require "px.pxclient"
local pxFilters = require "px.pxfilters"
local config = require "px.pxconfig"

-- local functions 
local ngx_decode_base64 = ngx.decode_base64
local ngx_time = ngx.time
local ngx_log = ngx.log
local ngx_req_get_method = ngx.req.get_method
local ngx_req_get_headers = ngx.req.get_headers
local ngx_hmac_sha1 = ngx.hmac_sha1
local ngx_INFO = ngx.INFO
local tostring = tostring
local tonumber = tonumber
local string_sub = string.sub
local string_len = string.len

-- Check for whitelisted request
-- By IP
local wlips = pxFilters.Whitelist['ip_addresses']
-- reverse client string builder
for i = 1, #wlips do
    if ngx.var.remote_addr == wlips[i] then
        ngx_log(ngx_INFO, "Whitelisted: ip_addresses")
        return 0
    end
end

local wlfuri = pxFilters.Whitelist['uri_full']
-- reverse client string builder
for i = 1, #wlfuri do
    if ngx.var.uri == wlfuri[i] then
        ngx_log(ngx_INFO, "Whitelisted: uri_full")
        return 0
    end
end

local wluri = pxFilters.Whitelist['uri_prefixes']
-- reverse client string builder
for i = 1, #wluri do
    if string_sub(ngx.var.uri, 1, string_len(wluri[i])) == wluri[i] then
        ngx_log(ngx_INFO, "Whitelisted: uri_prefixes")
        return 0
    end
end


ngx_log(ngx_INFO, "Passed whitelisting filter")
-- Generate an encrypted user-unique key
local function gen_pxIdentifier()
    local sec_now_str = tostring(ngx_time())
    local ip = ngx.var.remote_addr
    local ua = ngx.var.http_user_agent or ""
    local identifier = ngx_hmac_sha1(config.px_token, config.px_appId .. ip .. ua)
    return ngx.encode_base64(identifier .. sec_now_str)
end

-- Validating the user key came from px-cookie and match against the locally generated one
local function validate_pxIdentifier(identifier, px_cookie)
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
    re_pxcook = ngx_decode_base64(re_pxcook)
    identifier = ngx_decode_base64(identifier)

    -- separting the timestamp and key from the cookie value
    local re_pxcook_time = re_pxcook:sub(#re_pxcook - 9, #re_pxcook)
    local re_pxcook_key = re_pxcook:sub(1, #re_pxcook - 10)
    local identifier_key = identifier:sub(1, #re_pxcook - 10)

    -- validate time is still in range
    if tonumber(re_pxcook_time) + config.cookie_lifetime < ngx_time() then
        return false
    end

    -- validate key and cookie key
    if not (identifier_key == re_pxcook_key) then
        return false
    end
    return true
end

-- initilize identifier, cookie to perform check, vars that are not allowed in async API must be set in the ctx
ngx.ctx.method = ngx_req_get_method()
ngx.ctx.headers = ngx_req_get_headers()
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
