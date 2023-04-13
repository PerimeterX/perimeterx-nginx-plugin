---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

function M.load(px_config)
    local _M = {}

    local px_logger = require("px.utils.pxlogger").load(px_config)
    local cjson = require("cjson")
    local px_constants = require("px.utils.pxconstants")
    local px_common_utils = require("px.utils.pxcommonutils")

    function _M.extract()
        local jwt = nil
        local user_id_field_name = nil
        local additional_field_names = {}

        if px_config.px_jwt_cookie_name then
            local cookie_name = "cookie_" .. px_config.px_jwt_cookie_name
            jwt = ngx.var[cookie_name]
            user_id_field_name = px_config.px_jwt_cookie_user_id_field_name
            additional_field_names = px_config.px_jwt_cookie_additional_field_names
        elseif px_config.px_jwt_header_name then
            jwt = ngx.req.get_headers()[px_config.px_jwt_header_name]
            user_id_field_name = px_config.px_jwt_header_user_id_field_name
            additional_field_names = px_config.px_jwt_header_additional_field_names
        end

        return _M.excract_jwt(jwt, user_id_field_name, additional_field_names)
    end

    function _M.excract_jwt(jwt, user_id_field_name, additional_field_names)
        local jwt_res = {}

        local cts_cookie_name = "cookie_" .. px_constants.CTS_COOKIE
        jwt_res["cts"] = ngx.var[cts_cookie_name]

        if not jwt then
            return jwt_res
        end

        local payload = jwt:match("%.(.-)%.")
        if not payload then
            return
        end

        local success, payload_b64 = pcall(ngx.decode_base64, payload)
        if not success then
            return jwt_res
        end


        local success, payload_json  = pcall(cjson.decode, payload_b64)
        if not success then
            return jwt_res
        end

        jwt_res["user_id"] = payload_json[user_id_field_name]
        jwt_res["additional_fields"] = {}
        if additional_field_names then
            for _, f in ipairs(additional_field_names) do
                if payload_json[f] ~= nil then
                    jwt_res["additional_fields"][f] = payload_json[f]
                end
            end
        end

        return jwt_res
    end

    return _M
end

return M

