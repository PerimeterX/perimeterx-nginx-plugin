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

    function _M.get_operation_type(body)
        local success, body_json  = pcall(cjson.decode, body)
        if not success then
            return px_constants.GRAPHQL_QUERY
        end

        if not body_json["query"] then
            return px_constants.GRAPHQL_QUERY
        end
        local q = body_json["query"]

        local ops = {}
        local i = 0
        for str in string.gmatch(q, "([a-z]+)") do
            if not px_common_utils.isempty(str) then
                table.insert(ops, str)
                i = i + 1
            end
        end

        if i > 0 then
            return ops[1]
        else
            return px_constants.GRAPHQL_QUERY
        end
    end

    function _M.get_operation_name(body)
        local success, body_json  = pcall(cjson.decode, body)
        if not success then
            return nil
        end

        if body_json["operationName"] then
            return body_json["operationName"]
        end

        if not body_json["query"] then
            return nil
        end
        local q = body_json["query"]

        local ops = {}
        local i = 0
        for str in string.gmatch(q, "([A-Za-z0-9_]+)") do
            if not px_common_utils.isempty(str) then
                table.insert(ops, str)
                i = i + 1
            end
        end

        if i > 1 then
            return ops[2]
        else
            return nil
        end
    end

    function _M.is_sensitive_operation(graphql)
        local operationType = graphql["operationType"]
        local operationName = graphql["operationName"]

        for i = 1, #px_config.px_sensitive_graphql_operation_types do
            if px_config.px_sensitive_graphql_operation_types[i] == operationType then
                return true
            end
        end

        for i = 1, #px_config.px_sensitive_graphql_operation_names do
            if px_config.px_sensitive_graphql_operation_names[i] == operationName then
                return true
            end
        end

        return false
    end

    function _M.extract(lower_request_url)
        if next(px_config.px_sensitive_graphql_operation_names) == nil and next(px_config.px_sensitive_graphql_operation_types) == nil then
            return nil
        end

        local method = ngx.req.get_method()
        if not string.find(lower_request_url, px_constants.GRAPHQL_PATH, 1, true) and method:lower() == "post" then
            return nil
        end

        -- force Nginx to read body data
        ngx.req.read_body()
        local body = ngx.req.get_body_data()
        if not body then
            return nil
        end

        local graphql = {}

        graphql["operationType"] = _M.get_operation_type(body)
        graphql["operationName"] = _M.get_operation_name(body)
        graphql["isSensitiveOperation"] = _M.is_sensitive_operation(graphql)

        ngx.ctx.is_graphql_sensitive_operation = graphql["isSensitiveOperation"]

        return graphql
    end

    return _M
end

return M

