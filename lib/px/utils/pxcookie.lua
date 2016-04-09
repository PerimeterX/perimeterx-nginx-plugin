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
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
-- localized config
local px_config = require "px.pxconfig"
local cookie_encrypted = px_config.cookie_encrypted
local blocking_score = px_config.blocking_score
local cookie_secret = px_config.cookie_secret
-- localized modules
local aes = require "resty.nettle.aes"
local pbkdf2 = require "resty.nettle.pbkdf2"
local hmac = require "resty.nettle.hmac"


-- split_cookie --
-- takes one argument - an encrypted px cookie
-- returns three values - salt, iterations, ciphertext
local function split_cookie(cookie)
    local a = {}
    local b = 1
    for i in string_gmatch(cookie,"[^:]+") do
        a[b] = i
        b = b + 1
    end
    return a[1], a[2], a[3]
end

-- to_hex --
-- takes one argument - a string
-- returns one value - a hex formated representation of the string bytes
local function to_hex(str)
    return (string_gsub(str, "(.)", function (c)
        return string_format("%02X%s", string_byte(c), "")
    end))
end

-- from_hex --
-- takes one argument - a string of hex values
-- returns one value - char representation of the string
local function from_hex(str)
    return (str:gsub('..', function (cc)
        return string_char(tonumber(cc, 16))
    end))
end

-- unpad --
-- takes one arguement - a string
-- returns one string
local function unpad(str)
    local a = string_sub(str,#str,#str)
    if string_byte(a) <= 16 then
        return string_sub(str,1,#str - string_byte(a))
    end
    return str
end

-- decrypt --
-- takes two arguments - one encrypted _px cookie (string) , one secret key (string)
-- returns one string - plaintext cookie
local function decrypt(cookie, key)
    -- Split the cookie into three parts - salt , iterations, ciphertext
    local salt, iterations, ciphertext  = split_cookie(cookie)
    salt = ngx_decode_base64(salt)
    iterations = tonumber(iterations)
    ciphertext = ngx_decode_base64(ciphertext)

    -- Decrypt
    local keydata  = pbkdf2.hmac_sha256(key, iterations, salt, 48)
    keydata = to_hex(keydata)

    local secret_key = from_hex(string_sub(keydata,1,64))
    local iv =  from_hex(string_sub(keydata,65,96))

    local aes256 = aes.new(secret_key, "cbc", iv)
    local plaintext = aes256:decrypt(ciphertext)

    plaintext = unpad(plaintext)

    return plaintext
end

-- decode --
-- tales one argument - string
-- returns one value - table
local function decode(data)
    local cjson = require "cjson"
    local fields = cjson.decode(data)
    return fields
end

local function validate(data)
    local request_data  = data.t .. data.s.a .. data.s.b .. ngx.var.remote_addr .. ngx.var.http_user_agent
    local digest  = hmac("sha256", cookie_secret, request_data)
    digest = to_hex(digest)

    if digest ~= string_upper(data.h) then
        return false
    end

    return true
end

-- process --
-- takes one argument - cookie
-- returns boolean,
function _M.process(cookie)
    local data

    if cookie_encrypted == true then
        data = decrypt(cookie, cookie_secret)
    else
        data = ngx_decode_base64(cookie)
    end

    local fields = decode(data)
    if fields == nil then
        ngx_log(ngx_ERR,"PX: Could not decode cookie")
        return false
    end

    local result  = validate(fields)
    if result == false then
        ngx_log(ngx_ERR,"PX: Cookie digest is not valid")
        return false
    end

    if fields.s.b >= blocking_score then
        ngx_log(ngx_ERR,"PX: Visitor score is higher than allowed threshold: ", fields.s.b)
        return false
    end

    return true
end

return _M
