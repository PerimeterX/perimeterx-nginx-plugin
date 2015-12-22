----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.0.0
-- Release date: 15.12.2015
----------------------------------------------

-- ## Configuration Block ##
local px_token = 'my_temporary_token';
local px_appId = 'PXAPPCODE';
local px_apiServer = 'https://pxcollector.a.pxi.pub';
local cookie_lifetime = 600 -- cookie lifetime, value in seconds
-- ## END - Configuration block ##

-- Generate an encrypted user-unique key
function gen_pxIdentifier()
    local sec_now_str = tostring(ngx.time());
    local ip = ngx.var.remote_addr;
    local ua = ngx.var.http_user_agent;
    local identifier = ngx.hmac_sha1(px_token, px_appId .. ip .. ua);
    return ngx.encode_base64(identifier .. sec_now_str);
end

-- Validating the user key came from px-cookie and match against the locally generated one
function validate_pxIdentidier(identifier, px_cookie)
    local re_pxcook = ''

    -- if no cookie we stop validation
    if px_cookie == nil or #px_cookie == 0 then
        return false;
    end

    -- reverse client string builder
    for i = 1, #px_cookie do
        if not (i % 5 == 0) then
            local c = px_cookie:sub(i, i)
            re_pxcook = re_pxcook .. c;
        end
    end

    -- no need to continure and check if length doesnt match
    if not (#re_pxcook == #identifier) then
        return false;
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
        return false;
    end

    -- validate key and cookie key
    if not (identifier_key == re_pxcook_key) then
        return false;
    end
    return true;
end

-- initilize identifier and cookie to perform check
ngx.ctx.pxidentifier = gen_pxIdentifier();
ngx.ctx.px_app_id = px_appId;
ngx.ctx.px_apiServer = px_apiServer;
ngx.ctx.px_token = px_token;
local pxcook = ngx.var.cookie__pxcook;

if not validate_pxIdentidier(ngx.ctx.pxidentifier, pxcook) then
    return 1;
end

return 0;
