---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------

local M = {}

function M.load(config_file)
    local _M = {}

    -- localized functions
    local string_sub = string.sub
    local string_gsub = string.gsub
    local string_format = string.format
    local string_byte = string.byte
    local string_gmatch = string.gmatch
    local string_char = string.char
    local string_upper = string.upper
    local tonumber = tonumber
    local ngx_decode_base64 = ngx.decode_base64
    local pcall = pcall
    local os_time = os.time

    -- localized config
    local px_config = require (config_file)
    local px_logger = require ("px.utils.pxlogger").load(config_file)
    local px_headers = require ("px.utils.pxheaders").load(config_file)
    local cookie_encrypted = px_config.cookie_encrypted
    local blocking_score = px_config.blocking_score
    local cookie_secret = px_config.cookie_secret
    -- localized modules
    local cjson = require "cjson"
    local aes = require "resty.nettle.aes"
    local pbkdf2 = require "resty.nettle.pbkdf2"
    local hmac = require "resty.nettle.hmac"


    -- split_cookie --
    -- takes one argument - an encrypted px cookie
    -- returns three values - salt, iterations, ciphertext
    local function split_cookie(cookie)
        local a = {}
        local b = 1
        for i in string_gmatch(cookie, "[^:]+") do
            a[b] = i
            b = b + 1
        end
        return a[1], a[2], a[3]
    end

    -- to_hex --
    -- takes one argument - a string
    -- returns one value - a hex formated representation of the string bytes
    local function to_hex(str)
        return (string_gsub(str, "(.)", function(c)
            return string_format("%02X%s", string_byte(c), "")
        end))
    end

    -- from_hex --
    -- takes one argument - a string of hex values
    -- returns one value - char representation of the string
    local function from_hex(str)
        return (str:gsub('..', function(cc)
            return string_char(tonumber(cc, 16))
        end))
    end

    -- unpad --
    -- takes one arguement - a string
    -- returns one string
    local function unpad(str)
        local a = string_sub(str, #str, #str)
        if string_byte(a) <= 16 then
            return string_sub(str, 1, #str - string_byte(a))
        end
        return str
    end

    -- decrypt --
    -- takes two arguments - one encrypted _px cookie (string) , one secret key (string)
    -- returns one string - plaintext cookie
    local function decrypt(cookie, key)
        -- Split the cookie into three parts - salt , iterations, ciphertext
        local salt, iterations, ciphertext = split_cookie(cookie)
        iterations = tonumber(iterations)
        if iterations > 5000 then
            error('PX: Received cookie with too many iterations: ', iterations)
        end
        salt = ngx_decode_base64(salt)
        ciphertext = ngx_decode_base64(ciphertext)

        -- Decrypt
        local keydata = pbkdf2.hmac_sha256(key, iterations, salt, 48)
        keydata = to_hex(keydata)

        local secret_key = from_hex(string_sub(keydata, 1, 64))
        local iv = from_hex(string_sub(keydata, 65, 96))

        local aes256 = aes.new(secret_key, "cbc", iv)
        local plaintext = aes256:decrypt(ciphertext)

        plaintext = unpad(plaintext)
        return plaintext
    end

    -- decode --
    -- tales one argument - string
    -- returns one value - table
    local function decode(data)
        local fields = cjson.decode(data)
        return fields
    end

    local function validate(data)
        local request_data = data.t .. data.s.a .. data.s.b .. data.u;
        if data.v then
            request_data = request_data .. data.v
        end

        if data.a then
            request_data = request_data .. data.a
        end

        local request_data_ip = request_data .. ngx.var.remote_addr .. ngx.var.http_user_agent
        local digest_ip = hmac("sha256", cookie_secret, request_data_ip)
        digest_ip = to_hex(digest_ip)

        -- policy with ip
        if digest_ip == string_upper(data.h) then
            px_logger.debug('cookie verification succeed with IP in signature')
            return true
        end

        local request_data_noip = request_data .. ngx.var.http_user_agent
        local digest_noip = hmac("sha256", cookie_secret, request_data_noip)
        digest_noip = to_hex(digest_noip)

        -- policy with no ip
        if digest_noip == string_upper(data.h) then
            px_logger.debug('cookie verification succeed with no IP in signature')
            return true
        end

        px_logger.error('Failed to verify cookie content ' .. cjson.encode(data));
        return false
    end

    -- process --
    -- takes one argument - cookie
    -- returns boolean,
    function _M.process(cookie)
        if not cookie then
            px_logger.debug("Risk cookie not present")
            error({ message = "no_cookie" })
        end

        -- Decrypt AES-256 or base64 decode cookie
        local data
        if cookie_encrypted == true then
            local success, result = pcall(decrypt, cookie, cookie_secret)
            if not success then
                px_logger.error("Could not decrpyt cookie - " .. result)
                error({ message = "cookie_decryption_failed" })
            end
            data = result
        else
            local success, result = pcall(ngx_decode_base64, cookie)
            if not success then
                px_logger.error("Could not decode b64 cookie - " .. result)
                error({ message = "cookie_decryption_failed" })
            end
            data = result
        end

        -- Deserialize the JSON payload
        local success, result = pcall(decode, data)
        if not success then
            px_logger.error("Could not decode cookie")
            error({ message = "cookie_decryption_failed" })
        end

        local fields = result
        ngx.ctx.px_cookie = data;
        if fields.u then
            ngx.ctx.uuid = fields.u
        end
        if fields.v then
            ngx.ctx.vid = fields.v
        end

        -- cookie expired
        if fields.t and fields.t > 0 and fields.t / 1000 < os_time() then
            px_logger.error("Cookie expired - " .. data)
            error({ message = "cookie_expired" })
        end

        -- Set the score header for upstream applications
        px_headers.set_score_header(fields.s.b)
        -- Check bot score and block if it is >= to the configured block score
        if fields.s and fields.s.b and fields.s.b >= blocking_score then
            px_logger.debug("Visitor score is higher than allowed threshold: " .. fields.s.b)
            ngx.ctx.block_score = fields.s.b
            return false
        end

        -- Validate the cookie integrity
        local success, result = pcall(validate, fields)
        if not success or result == false then
            px_logger.error("Could not validate cookie signature - " .. data)
            error({ message = "cookie_validation_failed" })
        end

        return true
    end

    return _M
end
return M