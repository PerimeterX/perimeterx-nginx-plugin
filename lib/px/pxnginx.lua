----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------
local pxFilters = require "px.pxfilters"
local pxClient = require "px.pxclient"
local config = require "px.pxconfig"

-- local functions
local ngx_encode_base64 = ngx.encode_base64
local ngx_decode_base64 = ngx.decode_base64
local ngx_time = ngx.time
local ngx_log = ngx.log
local ngx_req_get_method = ngx.req.get_method
local ngx_req_get_headers = ngx.req.get_headers
local ngx_hmac_sha1 = ngx.hmac_sha1
local ngx_INFO = ngx.INFO
local ngx_ERROR = ngx.ERR
local tostring = tostring
local tonumber = tonumber
local string_sub = string.sub
local string_len = string.len

local req_method = ngx.var.request_method
if req_method ~= 'GET' then
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
            ngx.log(ngx_ERROR, "Whitelisted: ua_full")
            return 0
        end
    end
end

-- Whitelist By Full User Agent
local wluaf = pxFilters.Whitelist['ua_full']
-- reverse client string builder
for i = 1, #wluaf do
    if ngx.var.http_user_agent and wluaf[i] and ngx.var.http_user_agent == wluaf[i] then
        ngx.log(ngx_ERROR, "Whitelisted: ua_sub")
        return 0
    end
end

-- Check for whitelisted request
-- By IP
local wlips = pxFilters.Whitelist['ip_addresses']
-- reverse client string builder
for i = 1, #wlips do
    if ngx.var.remote_addr == wlips[i] then
        ngx_log(ngx_ERROR, "Whitelisted: ip_addresses")
        return 0
    end
end

local wlfuri = pxFilters.Whitelist['uri_full']
-- reverse client string builder
for i = 1, #wlfuri do
    if ngx.var.uri == wlfuri[i] then
        ngx_log(ngx_ERROR, "Whitelisted: uri_full")
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
    ngx_log(ngx_ERROR, "GEN NEW COOKIE")

    local sec_now_str = tostring(ngx_time())
    ngx_log(ngx_ERROR, "sec_now_str", sec_now_str)

    local ip = ngx.var.remote_addr
    local ua = ngx.var.http_user_agent or ""
    local identifier = ngx_hmac_sha1(config.px_token, config.px_appId .. ip .. ua)
    return ngx_encode_base64(identifier .. sec_now_str)
end

-- Validating the user key came from px-cookie and match against the locally generated one
local function validate_pxIdentifier(identifier, px_cookie)
    local re_pxcook = ''
    ngx_log(ngx_ERROR, "VALIDATE COOKIE")

    -- if no cookie we stop validation
    if px_cookie == nil or #px_cookie == 0 then
        ngx_log(ngx_ERROR, "FAILED: NO COOKIE")
--        return false
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
        ngx_log(ngx_ERROR, "FAILED: BAD LENGTH")
--        return false
    end

    -- extract sha key from identifier and cookie
    re_pxcook = ngx_decode_base64(re_pxcook)
    identifier = ngx_decode_base64(identifier)

    -- separting the timestamp and key from the cookie value
    local re_pxcook_time = re_pxcook:sub(#re_pxcook - 9, #re_pxcook)
    ngx_log(ngx_ERROR, "re_pxcook_time", re_pxcook_time)

    local re_pxcook_key = re_pxcook:sub(1, #re_pxcook - 10)
    ngx_log(ngx_ERROR, "re_pxcook_key", re_pxcook_key)

    local identifier_key = identifier:sub(1, #re_pxcook - 10)
    ngx_log(ngx_ERROR, "identifier_key", identifier_key)

    -- validate time is still in range
    if tonumber(re_pxcook_time) + config.cookie_lifetime < ngx_time() then
        ngx_log(ngx_ERROR, "FAILED: OUT OF TIME RANGE")
--        return false
    end

    -- validate key and cookie key
    if not (identifier_key == re_pxcook_key) then
        ngx_log(ngx_ERROR, "FAILED: DID NOT MATCH")
--        return false
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

--pxClient.sendTo_Perimeter("page_requested")

return 0
