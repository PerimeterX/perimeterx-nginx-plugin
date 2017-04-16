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
    local px_config = require(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local px_headers = require("px.utils.pxheaders").load(config_file)
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
        return a[1], a[2], a[3], a[4]
    end

    -- split_decoded_cookie --
    -- takes one argument - an encrypted px cookie
    -- returns three values - salt, iterations, ciphertext
    local function split_decoded_cookie(cookie)
        local a = {}
        local b = 1
        for i in string_gmatch(cookie, "[^:]+") do
            a[b] = i
            b = b + 1
        end
        return a[1], a[2]
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

    -- c23f3abce5fca71188d573b426fe3bfef60f2f0304857704f33709633cefea80:
    -- -- SYQvmamLpOGNOS1zlUhNDe7fJcMR+s1TS/qMqLyHBLiYchYFTtq/yGCi2SdiSI7KkaXEzrw+pbU4alxrfgNrUg==:1000:
    -- -- w7WiJq8BtRPBbdEMpwqS3WAFCZPFetS1Jcu2+hn0D+yhSkFiABfaAp/h9NdT8x3EIqsYIfK4XXZIbgc+jWhQxL1k537UoJkkdV5hnLwtBTyx6BbyWZcgw8IgXwYwhHXswURKrcxOwGg8dim2XkLT2oRICUAvjIT+C1hcLohcJxs=
    -- decrypt --
    -- takes two arguments - one encrypted _px cookie (string) , one secret key (string)
    -- returns one string - plaintext cookie
    local function decrypt(cookie, key)
        -- Split the cookie into three parts - salt , iterations, ciphertext

        local hash, orig_salt, orig_iterations, orig_ciphertext = split_cookie(cookie)
        local iterations = tonumber(orig_iterations)
        if iterations > 5000 then
            error('PX: Received cookie with too many iterations: ', iterations)
        end
        local salt = ngx_decode_base64(orig_salt)
        local ciphertext = ngx_decode_base64(orig_ciphertext)

        -- Decrypt
        local keydata = pbkdf2.hmac_sha256(key, iterations, salt, 48)
        keydata = to_hex(keydata)

        local secret_key = from_hex(string_sub(keydata, 1, 64))
        local iv = from_hex(string_sub(keydata, 65, 96))

        local aes256 = aes.new(secret_key, "cbc", iv)
        local plaintext = aes256:decrypt(ciphertext)

        plaintext = unpad(plaintext)
        local retval = {}
        retval['plaintext'] = plaintext
        retval['hash'] = hash
        retval['cookie'] = orig_salt .. ':' .. orig_iterations .. ':' .. orig_ciphertext
        return retval
    end

    -- decode --
    -- tales one argument - string
    -- returns one value - table
    local function decode(data)
        local fields = cjson.decode(data)
        return fields
    end

    local function validate(data, hash)
        local request_data = data .. ngx.var.http_user_agent
        local digest = hmac("sha256", cookie_secret, request_data)
        digest = to_hex(digest)

        -- policy with ip
        if digest == string_upper(hash) then
            return true
        end

        px_logger.error('Failed to verify cookie v3 content ' .. data);
        return false
    end

    -- process --
    -- takes one argument - cookie
    -- returns boolean,
    function _M.process(cookie)
        if not cookie then
            error({ message = "no_cookie" })
        end

        -- Decrypt AES-256 or base64 decode cookie
        local data, hash, orig_cookie
        if cookie_encrypted == true then
            local success, result = pcall(decrypt, cookie, cookie_secret)
            if not success then
                px_logger.error("Could not decrpyt px cookie v3")
                error({ message = "cookie_decryption_failed" })
            end
            data = result['plaintext']
            hash = result['hash']
            orig_cookie = result['cookie']
        else
            hash, orig_cookie = split_decoded_cookie(cookie);
            local success, result = pcall(ngx_decode_base64, orig_cookie)
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
        ngx.ctx.px_cookie = data
        ngx.ctx.px_cookie_hmac = hash
        if fields.u then
            ngx.ctx.uuid = fields.u
        end
        if fields.v then
            ngx.ctx.vid = fields.v
        end
        if fields.a then
            ngx.ctx.px_action = fields.a
        end

        -- cookie expired
        if fields.t and fields.t > 0 and fields.t / 1000 < os_time() then
            px_logger.debug("Cookie expired - " .. data)
            error({ message = "cookie_expired" })
        end

        -- Set the score header for upstream applications
        px_headers.set_score_header(fields.s)
        -- Check bot score and block if it is >= to the configured block score
        if fields.s and fields.s >= blocking_score then
            ngx.ctx.block_score = fields.s
            ngx.ctx.block_action = fields.a
            return false
        end

        -- Validate the cookie integrity
        local success, result = pcall(validate, orig_cookie, hash)
        if not success or result == false then
            px_logger.error("Could not validate cookie v3 signature - " .. orig_cookie)
            error({ message = "cookie_validation_failed" })
        end

        return true
    end

    return _M
end

return M
