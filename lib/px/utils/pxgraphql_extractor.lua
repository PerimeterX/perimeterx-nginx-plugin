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

    function _M.is_valid_graphql_operation_type(op)
        if op == px_constants.GRAPHQL_QUERY then
            return true
        elseif op == px_constants.GRAPHQL_MUTATION then
            return true
        else
            return false
        end
    end

    -- extract field names from string similar to:
    -- "query HeroNameAndFriends {hero {name friends {name}}}" -> {query, HeroNameAndFriends}
    -- return table
    function _M.extract_fields(q)
        local s, e = string.find(q, "{", 1, true)
        if not s then
            return nil
        end

        local part = string.sub(q, 1, s-1)

        local fields = {}
        local i = 0
        for str in string.gmatch(part, "([A-Za-z0-9_]+)") do
            if not px_common_utils.isempty(str) then
                table.insert(fields, str)
                i = i + 1
            end
        end
        return fields
    end

    function _M.get_operation_type(body)
        local success, body_json  = pcall(cjson.decode, body)
        if not success then
            return nil
        end

        if not body_json["query"] then
            return px_constants.GRAPHQL_QUERY
        end

        local fields = _M.extract_fields(body_json["query"])
        if not fields then
            return nil
        end

        if _M.is_valid_graphql_operation_type(fields[1]) then
            return fields[1]
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

        local fields = _M.extract_fields(body_json["query"])
        if not fields then
            return nil
        end

        if fields[2] then
            return fields[2]
        else
            return nil
        end
    end

    function _M.is_sensitive_operation(graphql)
        local operationType = graphql["operationType"]
        local operationName = graphql["operationName"]

        if next(px_config.px_sensitive_graphql_operation_types) ~= nil and operationType then
            for i = 1, #px_config.px_sensitive_graphql_operation_types do
                if px_config.px_sensitive_graphql_operation_types[i] == operationType then
                    return true
                end
            end
        end

        if next(px_config.px_sensitive_graphql_operation_names) ~= nil and operationName then
            for i = 1, #px_config.px_sensitive_graphql_operation_names do
                if px_config.px_sensitive_graphql_operation_names[i] == operationName then
                    return true
                end
            end
        end

        return false
    end

    function _M.extract(lower_request_url)
        local method = ngx.req.get_method()
        if method:lower() ~= "post" then
            return nil
        end

        for i = 1, #px_config.px_graphql_routes do
            if string.match(lower_request_url, px_config.px_graphql_routes[i]) then
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
        end

        return nil
    end

    return _M
end

return M

