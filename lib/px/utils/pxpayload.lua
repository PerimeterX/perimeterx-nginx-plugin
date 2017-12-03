PXPayload = {}

function PXPayload:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function PXPayload:handleHeader(header)
    if string.match(header, ":") then
        local version = string.sub(header, 1,1);
        local cookie = string.sub(header, 3);
        return version, cookie
    else
        return nil,header
    end
end

function PXPayload:load(config_file)
    -- localized config
    self.px_config = require (config_file)
    self.px_logger = require ("px.utils.pxlogger").load(config_file)
    self.px_headers = require ("px.utils.pxheaders").load(config_file)
    self.cookie_encrypted = self.px_config.cookie_encrypted
    self.blocking_score = self.px_config.blocking_score
    self.cookie_secret = self.px_config.cookie_secret
    self.cookie_v3 = require "px.utils.pxcookiev3"
    self.cookie_v1 = require "px.utils.pxcookiev1"
    self.token_v3 = require "px.utils.pxtokenv3"
    self.token_v1 = require "px.utils.pxtokenv1"

    -- localized modules
    self.cjson = require "cjson"
    self.aes = require "resty.nettle.aes"
    self.pbkdf2 = require "resty.nettle.pbkdf2"
    self.hmac = require "resty.nettle.hmac"
end

function PXPayload:get_payload()
    ngx.ctx.px_cookie_origin = "cookie"
    local px_header = ngx.req.get_headers()['X-PX-AUTHORIZATION'] or nil

    if (px_header) then
        self.px_logger.debug("Mobile SDK token detected")
        local version, cookie = self:handleHeader(px_header)
        ngx.ctx.px_orig_cookie = cookie
        ngx.ctx.px_header = px_header
        ngx.ctx.px_cookie_origin = "header"
        if version == "3" then
            ngx.ctx.px_cookie_version = "v3";
            self.px_logger.debug("Token V3 found - Evaluating")
            return self.token_v3:new{}
        else
            ngx.ctx.px_cookie_version = "v1";
            self.px_logger.debug("Token V1 found - Evaluating")
            return self.token_v1:new{}
        end
    elseif ngx.var.cookie__px3 then
        ngx.ctx.px_orig_cookie = ngx.var.cookie__px3
        ngx.ctx.px_cookie_version = "v3";
        self.px_logger.debug("Cookie V3 found - Evaluating")
        return self.cookie_v3:new{}
    else
        ngx.ctx.px_orig_cookie = ngx.var.cookie__px
        ngx.ctx.px_cookie_version = "v1";
        self.px_logger.debug("Cookie V1 found - Evaluating")
        return self.cookie_v1:new{}
    end
    -- check for cookie, and if found return the right object
    self.px_logger.debug("Cookie is missing")
end

-- split_cookie --
-- takes one argument - an encrypted px cookie
-- returns three values - salt, iterations, ciphertext
function PXPayload:split_cookie(cookie)
    local a = {}
    local b = 1
    for i in string.gmatch(cookie, "[^:]+") do
        a[b] = i
        b = b + 1
    end

    if a[4] ~= nil then
        ngx.ctx.px_cookie_hmac = a[1]
        return a[2],a[3],a[4]
    end
    return a[1], a[2], a[3]
end

function PXPayload:split_decoded_cookie(cookie)
    local a = {}
    local b = 1
    for i in string.gmatch(cookie, "[^:]+") do
        a[b] = i
        b = b + 1
    end
    return a[1], a[2]
end

-- to_hex --
-- takes one argument - a string
-- returns one value - a hex formated representation of the string bytes
function PXPayload:to_hex(str)
    return (string.gsub(str, "(.)", function(c)
        return string.format("%02X%s", string.byte(c), "")
    end))
end

-- from_hex --
-- takes one argument - a string of hex values
-- returns one value - char representation of the string
function PXPayload:from_hex(str)
    return (str:gsub('..', function(cc)
        return string.char(tonumber(cc, 16))
    end))
end

-- unpad --
-- takes one arguement - a string
-- returns one string
function PXPayload:unpad(str)
    local a = string.sub(str, #str, #str)

    if string.byte(a) <= 16 then
        return string.sub(str, 1, #str - string.byte(a))
    end
    return str
end


function PXPayload:pre_decrypt(cookie, key)
    local cjson = require('cjson')
    local px_header = ngx.ctx.px_header
    if not px_header or px_header == "" then
        self.px_logger.debug("Mobile empty token not allowed")
        error({ message = "cookie_decryption_failed" })
    end

    if px_header == "1" then
        self.px_logger.debug("Mobile special token - no token")
        error({ message = "no_cookie" })
    end

    if px_header == "2" then
        self.px_logger.debug("Mobile special token - connection error")
        error({ message = "mobile_sdk_connection_error" })
    end

    if px_header == "3" then
        self.px_logger.debug("Mobile special token - pinning issue")
        error({ message = "mobile_sdk_pinning_error" })
    end

    local success, result = pcall(self.decrypt, self, cookie, key)
    if not success then
        self.px_logger.debug("Cookie decryption failed, value: " .. cookie)
        error({ message = "cookie_decryption_failed" })
    end

    return result
end


function PXPayload:decrypt(cookie, key)

    -- Split the cookie into three parts - salt , iterations, ciphertext
    local orig_salt, orig_iterations, orig_ciphertext = self:split_cookie(cookie)
    local iterations = tonumber(orig_iterations)
    if iterations > 5000 then
        error('PX: Received cookie with too many iterations: ', iterations)
    end
    local salt = ngx.decode_base64(orig_salt)
    local ciphertext = ngx.decode_base64(orig_ciphertext)

    -- Decrypt
    local keydata = self.pbkdf2.hmac_sha256(key, iterations, salt, 48)

    keydata = self:to_hex(keydata)

    local secret_key = self:from_hex(string.sub(keydata, 1, 64))
    local iv = self:from_hex(string.sub(keydata, 65, 96))

    local aes256 = self.aes.new(secret_key, "cbc", iv)

    local plaintext = aes256:decrypt(ciphertext)

    plaintext = self:unpad(plaintext)
    local retval = {}
    retval['plaintext'] = plaintext
    retval['cookie'] = orig_salt .. ':' .. orig_iterations .. ':' .. orig_ciphertext
    return retval
end

-- decode --
-- takes one argument - string
-- returns one value - table
function PXPayload:decode(data)
    local fields = self.cjson.decode(data)
    return fields
end

-- validate --
-- abstract method, to be implemeneted by child object
function PXPayload:validate(cookie)
    return nil
end

function PXPayload:is_sensitive_route()
    if self.px_config.sensitive_routes_prefix ~= nil then
        -- find if any of the sensitive routes is the start of the URI
        for i, prefix in ipairs(self.px_config.sensitive_routes_prefix) do
            if string.sub(ngx.var.uri, 1, string.len(prefix)) == prefix then
                self.px_logger.debug("Sensitive route match, sending Risk API. path:: " .. ngx.var.uri)
                return true
            end
        end
    end
    if self.px_config.sensitive_routes_suffix ~= nil then
        -- find if any of the sensitive routes is the end of the URI
        for i, suffix in ipairs(self.px_config.sensitive_routes_suffix) do
            if string.sub(ngx.var.uri, -string.len(suffix)) == suffix then
                self.px_logger.debug("Sensitive route match, sending Risk API. path:: " .. ngx.var.uri)
                return true
            end
        end
    end
    return false
end

-- validate --
-- abstract method, to be implemeneted by child object
function PXPayload:process(cookie)
    return nil
end

return PXPayload