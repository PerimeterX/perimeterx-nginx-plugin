---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

function M.load(px_config)
    local _M = {}

    local cjson = require "cjson"
    local px_logger = require ("px.utils.pxlogger").load(px_config)
    local px_headers = require ("px.utils.pxheaders").load(px_config)
    local sha2 = require "resty.nettle.sha2"
    local px_common_utils = require("px.utils.pxcommonutils")
    local upload = require "resty.upload"

    -- return table with hashed username and password
    function _M.creds_encode(user, pass)
        local creds = {}
        local user_hash = sha2.sha256.new()
        user_hash:update(user)
        local pass_hash = sha2.sha256.new()
        pass_hash:update(pass)

        creds["user"] = px_common_utils.to_hex(user_hash:digest())
        creds["pass"] = px_common_utils.to_hex(pass_hash:digest())
        return creds
    end

    -- extract login information from a table
    -- return table or nil
    function _M.creds_extract_from_table(ci, t)
        local user = nil
        local pass = nil
        for k, v in pairs(t) do
            if k == ci.user_field then
                user = v
            elseif k == ci.pass_field then
                pass = v
            end
        end

        if user and pass then
            return _M.creds_encode(user, pass)
        end

        return nil
    end

    function _M.creds_extract_from_headers(ci)
        local user = px_headers.get_header(ci.user_field)
        local pass = px_headers.get_header(ci.pass_field)

        if user and pass then
            return _M.creds_encode(user, pass)
        end

        return nil
    end

    function _M.creds_extract_from_query(ci)
        local params = ngx.req.get_uri_args()
        if not params then
            return nil
        end

        return _M.creds_extract_from_table(ci, params)
    end

    function _M.creds_extract_from_body_json(ci)
        -- force Nginx to read body data
        ngx.req.read_body()
        local data = ngx.req.get_body_data()
        if not data then
            return nil
        end

        local success, body_json  = pcall(cjson.decode, data)
        if not success then
            px_logger.debug("Could not decode JSON body")
            return nil
        end

        return _M.creds_extract_from_table(ci, body_json)
    end

    -- parse lines similar to:  form-data; name1=val1; name2=val2
    local function decode_content_disposition(value)
        local result
        local disposition_type, params = string.match(value, "([%w%-%._]+);(.+)")
        if disposition_type then
            result = {}
            if params then
                for index, param in pairs(px_common_utils.split(params, ";")) do
                    local key, value = param:match('([%w%.%-_]+)="(.+)"$')
                    local key = px_common_utils.trim(key)
                    if key then
                        result[key] = px_common_utils.trim(value)
                    end
                end
            end
        end

        return result
    end

    function _M.creds_extract_from_body_formdata(ci)
        -- maximal POST field size to read
        local chunk_size = 4096
        local form, err = upload:new(chunk_size)
        if not form then
            return nil
        end

        local user = nil
        local pass = nil

        form:set_timeout(1000)

        local field_name = "none"
        while true do
            local t, res, err = form:read()
            if not t then
                return nil
            end

            if t == "header" then
                -- return:  name = [key name]
                local kv = decode_content_disposition(res[2])

                if kv.name == ci.user_field then
                    field_name = "user"
                elseif kv.name == ci.pass_field then
                    field_name = "pass"
                else
                    field_name = "none"
                end
            elseif t == "body" then
                if field_name == "user"  then
                    user = res
                elseif field_name == "pass"  then
                    pass = res
                end
            elseif t == "eof" then
                field_name = "none"
                break
            end
        end

        if user and pass then
             return _M.creds_encode(user, pass)
        end

        return nil
    end

    function _M.creds_extract_from_body_form_urlencoded(ci)
        -- force Nginx to read body data
        ngx.req.read_body()
        local args, err = ngx.req.get_post_args()

        if err or not args then
            return nil
        end

        return _M.creds_extract_from_table(ci, args)
    end

    function _M.creds_extract_from_body(ci)
        -- JSON body type
        if ci.content_type == "json" then
            return _M.creds_extract_from_body_json(ci)
        elseif ci.content_type == "form-data" then
            return _M.creds_extract_from_body_formdata(ci)
        elseif ci.content_type == "form-urlencoded" then
            return _M.creds_extract_from_body_form_urlencoded(ci)
        else
            return nil
        end
    end

    -- extract login information from client request
    -- return table or nil
    function _M.px_credentials_extract()
        if px_config.creds == nil then
            return nil
        end

        local method = ngx.req.get_method()
        method = method:lower()
        local ci = nil

        -- check creds path and method
        local uri = ngx.var.uri
        for k, v in pairs(px_config.creds) do
            if v.path == uri and v.method == method then
                ci = v
                break
            end
        end

        if not ci then
            return nil
        end

        if ci.sent_through == "header" then
            return _M.creds_extract_from_headers(ci)
        elseif ci.sent_through == "url" then
            return _M.creds_extract_from_query(ci)
        elseif ci.sent_through == "body" then
            return _M.creds_extract_from_body(ci)
        end

        return nil
    end

    -- check if login credentials feature is enabled
    if not px_config.px_enable_login_creds_extraction or px_config.px_login_creds_settings_filename == nil then
        return _M
    end

    -- check if login credentials settings are already loaded
    if px_config.creds then
        return _M
    end

    -- try to load JSON with creds information
    local f, err = io.open(px_config.px_login_creds_settings_filename, "r")
    if not f then
        px_logger.error("Failed to load login credentials JSON file: " .. err)
        return _M
    end

    local content = f:read("*a")
    f:close()

    local success, creds_json  = pcall(cjson.decode, content)
    if not success then
        px_logger.error("Could not decode login credentials JSON file")
    else
        px_config.creds = creds_json.features.credentials.items
    end

    return _M
end

return M
