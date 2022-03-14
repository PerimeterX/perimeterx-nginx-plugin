local socket = require("socket")
local _M = {}

local px_constants = require("px.utils.pxconstants")

local function clone (t) -- deep-copy a table
    if type(t) ~= "table" then return t end
    local meta = getmetatable(t)
    local target = {}
    for k, v in pairs(t) do
        if type(v) == "function" then
            target[k] = string.dump(v)
        elseif type(v) == "table" then
            target[k] = clone(v)
        else
            target[k] = v
        end
    end
    setmetatable(target, meta)
    return target
end

local function hex_to_char(str)
    return string.char(tonumber(str, 16))
end

function _M.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function _M.split(s, sep)
    local fields = {}
    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function connect_proxy(httpc, proxy_uri, scheme, host, port, pool_key, proxy_authorization)
    -- Parse the provided proxy URI
    local parsed_proxy_uri, err = httpc:parse_uri(proxy_uri, false)
    if not parsed_proxy_uri then
        return nil, err
    end

    -- Check that the scheme is http (https is not supported for
    -- connections between the client and the proxy)
    local proxy_scheme = parsed_proxy_uri[1]
    if proxy_scheme ~= "http" then
        return nil, "protocol " .. proxy_scheme .. " not supported for proxy connections"
    end

    -- Make the connection to the given proxy
    local proxy_host, proxy_port = parsed_proxy_uri[2], parsed_proxy_uri[3]
    local c, err = httpc:connect(proxy_host, proxy_port, { pool = pool_key })
    if not c then
        return nil, err
    end

    if scheme == "https" then
        local times = httpc:get_reused_times()
        if times and times > 0 then
            return c, nil
        end
        -- Make a CONNECT request to create a tunnel to the destination through
        -- the proxy. The request-target and the Host header must be in the
        -- authority-form of RFC 7230 Section 5.3.3. See also RFC 7231 Section
        -- 4.3.6 for more details about the CONNECT request
        local destination = host .. ":" .. port
        local res, err = httpc:request({
            method = "CONNECT",
            path = destination,
            headers = {
                ["Host"] = destination,
                ["Proxy-Authorization"] = proxy_authorization,
            }
        })

        if not res then
            return nil, err
        end

        if res.status < 200 or res.status > 299 then
            return nil, "failed to establish a tunnel through a proxy: " .. res.status
        end
    end

    return c, nil
end

function _M.handle_custom_parameters(px_config, px_logger)
    if px_config.enrich_custom_parameters == nil then
        return nil
    end

    local px_custom_params = {}
    -- initialize the px_custom_params table
    for i = 1, 10 do
        px_custom_params["custom_param" .. i] = ""
    end

    local result_table = {}

    px_logger.debug("enrich_custom_parameters was triggered")
    local px_result_custom_params = px_config.enrich_custom_parameters(px_custom_params)
    for key, value in pairs(px_result_custom_params) do
        if string.match(key,"^custom_param%d+$") and value ~= "" then
            result_table[key] = value
        elseif key == px_constants.HYPE_SALE_CUSTOM_PARAM then
            result_table[key] = value
            ngx.ctx.isHypeSale = value
        end
    end

    return result_table
end

function _M.get_time_in_milliseconds()
    return socket.gettime() * 1000
end

function _M.array_index_of(array, item)
    if array == nil then
        return -1
    end

    for i, value in ipairs(array) do
        if string.lower(value) == string.lower(item) then
            return i
        end
    end
    return -1
end

function  _M.filter_config(px_config)
    local config_copy = clone(px_config)
    -- remove
    config_copy.cookie_secret = nil
    config_copy.auth_token = nil
    return config_copy
end

function  _M.filter_headers(sensitive_headers, isRiskRequest)
    local headers = ngx.req.get_headers()
    local request_headers = {}
    for k, v in pairs(headers) do
        -- filter sensitive headers
        if _M.array_index_of(sensitive_headers, k) == -1 then
            if isRiskRequest == true then
                request_headers[#request_headers + 1] = { ['name'] = k, ['value'] = v }
            else
                request_headers[k] = v
            end
        end
    end

    return request_headers
end

function _M.clear_first_party_sensitive_headers(sensitive_headers)
    if not sensitive_headers then
        return
    end

    for i, header in ipairs(sensitive_headers) do
        ngx.req.clear_header(header)
    end
end

-- Splits a string into array
-- @s - string to split
-- @delimeter - delimeiter to use
--
-- @return - splitted string as array
function _M.split_first(s,delimeter)
    local result = {}
    if (s ~= nil) then
        local index = string.find(s,delimeter)
        if (index == nil) then
            result[1] = s
        else
            result[1] = string.sub(s,1, index-1)
            result[2] = string.sub(s,index+1)
        end
    end
    return result
end

-- Formats string bytes into hex string
-- @str - string of hmac
--
-- @return - a hex formated representation of the string bytes
function _M.to_hex(str)
    return (string.gsub(str, "(.)", function(c)
        return string.format("%02X%s", string.byte(c), "")
    end))
end

-- Matches instaces of url encoded text (%<XX>) and decode it back to its original char
function _M.decode_uri_component(str)
    return (str:gsub("%%(%x%x)", hex_to_char))
end

function _M.extract_cookie_names(cookies)
    local t = {}
    local cookies_data = ""
    if cookies ~= nil then
        if type(cookies) == 'table' then
            for k, v in pairs(cookies) do
                local trimmed = _M.trim(v)
                if not ends_with(trimmed, ";") then
                    trimmed = trimmed .. ";"
                end
                cookies_data = cookies_data .. trimmed
            end
        elseif type(cookies) == 'string' then
            cookies_data = cookies
        end

        if (cookies_data ~= "") then
            local index = 1;
            local loopIndex = 0;
            local cookie_name = ""
            while(loopIndex ~= nil) do
              loopIndex = string.find(cookies_data, "=")
              if loopIndex ~= nil then
                cookie_name = string.sub(cookies_data, 0, loopIndex - 1)
                t[index] = cookie_name
                index = index + 1
              end
              loopIndex = string.find(cookies_data, ";")
              if loopIndex ~= nil then
                cookies_data = string.sub(cookies_data,loopIndex + 1)
              end
            end
        else
            return "[]"
        end
    end
    return t
end

function _M.call_px_server(httpc, scheme, host, port, px_config, pool_key)
    if px_config.proxy_url ~= nil then
        return connect_proxy(httpc, px_config.proxy_url, scheme, host, port, pool_key, px_config.proxy_authorization)
    else
        return httpc:connect(host, port)
    end
end

return _M
