---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

function M.load(px_config)
    local _M = {}

    local cjson = require "cjson"
    local px_logger = require ("px.utils.pxlogger").load(px_config)
    local px_headers = require ("px.utils.pxheaders").load(px_config)
    local px_common_utils = require("px.utils.pxcommonutils")
    local upload = require("px.utils.resty_upload")
    local px_constants = require("px.utils.pxconstants")
    local buffer = require "px.utils.pxbuffer"
    local ngx_time = ngx.time

    -- return table with hashed username and password
    function _M.creds_encode(user, pass)
        local creds = {}
        local user_hash = nil
        local pass_hash = nil

        if px_config.px_credentials_intelligence_version == px_constants.CI_VERSION1 then

            if px_common_utils.isempty(user) or px_common_utils.isempty(pass) then
                return nil
            end

            user_hash = px_common_utils.sha256_hash(user)
            pass_hash = px_common_utils.sha256_hash(pass)
        elseif px_config.px_credentials_intelligence_version == px_constants.CI_VERSION_MULTISTEP_SSO then

            if not px_common_utils.isempty(user) then
                user_hash = px_common_utils.sha256_hash(user)
                creds["sso_step"] = "user"
            end
            if not px_common_utils.isempty(pass) then
                pass_hash = px_common_utils.sha256_hash(pass)
                creds["sso_step"] = "pass"
            end
        else
            return nil
        end

        creds["user"] = user_hash
        creds["pass"] = pass_hash
        creds["raw_user"] = user
        creds["ci_version"] = px_config.px_credentials_intelligence_version
        return creds
    end

    -- extract login information from a table
    -- return table or nil
    function _M.creds_extract_from_table(ci, t, parent)
        local user = nil
        local pass = nil
        for k, v in pairs(t) do

            if (type(v) ~= "table") then
                if parent ~= nil then
                    k = parent .. "." .. k
                end

                if k == ci.user_field then
                    user = v
                elseif k == ci.pass_field then
                    pass = v
                end
            end
        end

        return _M.creds_encode(user, pass)
    end

    function _M.creds_extract_from_headers(ci)
        local user = px_headers.get_header(ci.user_field)
        local pass = px_headers.get_header(ci.pass_field)

        return _M.creds_encode(user, pass)
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

        local creds = _M.creds_extract_from_table(ci, body_json)
        if not creds then
            for k, v in pairs(body_json) do
                if (type(v) == "table") then
                    creds = _M.creds_extract_from_table(ci, v, k)
                    if creds then
                        return creds
                    end
                end
            end
        end

        return creds
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
        -- maximal single string length
        local max_string_size = 512
        local form, err = upload:new(chunk_size, max_string_size, true)

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

        return _M.creds_encode(user, pass)
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
        local ctype = ngx.req.get_headers()["content-type"]
        if not ctype then
            return nil
        end

        -- JSON body type
        if string.find(ctype, px_constants.JSON_CONTENT_TYPE, 1, true) then
            return _M.creds_extract_from_body_json(ci)
        elseif string.find(ctype, px_constants.MULTIPART_FORM_CONTENT_TYPE, 1, true) then
            return _M.creds_extract_from_body_formdata(ci)
        elseif string.find(ctype, px_constants.URL_ENCODED_CONTENT_TYPE, 1, true) then
            return _M.creds_extract_from_body_form_urlencoded(ci)
        else
            return nil
        end
    end

    function _M.creds_has_uri_path()
        local uri = ngx.var.uri
        local method = ngx.req.get_method()
        method = method:lower()
        for k, v in pairs(px_config.creds) do
            if v.path == uri and v.method == method then
                return true
            end
        end
        return false
    end

    -- return true if login successful
    function _M.creds_is_login_successful()
        if px_config.px_login_successful_reporting_method == "none" then
            return false
        end

        if px_config.px_login_successful_reporting_method == "header" and px_config.px_login_successful_header_name then
            local login_successful_value = ngx.resp.get_headers()[px_config.px_login_successful_header_name]
            if login_successful_value then
                return tonumber(login_successful_value) == 1
            end
        end


        if px_config.px_login_successful_reporting_method == "status" then
            if #px_config.px_login_successful_status > 0 then
                for i = 1, #px_config.px_login_successful_status do
                    if px_config.px_login_successful_status[i] == tonumber(ngx.var.upstream_status) then
                        return true
                    end
                end
            end
        end

--[[  Reading response body
        if px_config.px_login_successful_reporting_method == "body" and not px_common_utils.isempty(px_config.px_login_successful_body_regex) then
            local data = ngx.arg[1]
            if not data then
                return false
            end

            local from, to, err = ngx.re.find(data, px_config.px_login_successful_body_regex)
            if from then
                return true
            end
        end
]]--
        return false
    end

    function _M.create_additional_s2s(is_login_successful, is_header)
        local buflen = buffer.getBufferLength()
        local maxbuflen = px_config.px_maxbuflen
        local full_url = ngx.var.scheme .. "://" .. ngx.var.host .. ngx.var.request_uri

        local details = {}
        details['request_id'] = ngx.ctx.client_uuid
        if ngx.ctx.uuid then
            details['client_uuid'] = ngx.ctx.uuid
        end
        details['ci_version'] = ngx.ctx.ci_version

        if ngx.ctx.credentials_compromised then
            details['credentials_compromised'] = ngx.ctx.credentials_compromised
        else
            details['credentials_compromised'] = 0
        end

        if not is_header then
            details['http_status_code'] = tonumber(ngx.var.upstream_status)
            details['login_successful'] = is_login_successful

            if px_config.px_send_raw_username_on_additional_s2s_activity and
                ngx.ctx.credentials_compromised and
                is_login_successful and
                ngx.ctx.ci_raw_user then

                details['raw_username'] = ngx.ctx.ci_raw_user
            end
        end

        local pxdata = {}
        pxdata['type'] = 'additional_s2s'
        pxdata['timestamp'] = ngx_time()
        pxdata['socket_ip'] = px_headers.get_ip()
        pxdata['px_app_id'] = px_config.px_appId
        pxdata['url'] = full_url
        pxdata['details'] = details

        -- add to shared buffer
        buffer.addEvent(pxdata)
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
        elseif ci.sent_through == "query-param" then
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
