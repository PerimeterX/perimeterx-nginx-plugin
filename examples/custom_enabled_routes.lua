local function wildcard_search(text, pat)
   local pattern = pat:gsub("*", "\0"):gsub("%p", "%%%0"):gsub("%z", ".-")
   if text:find(pattern) ~= nil then
       return true
    else
        return false
    end
end

-- file must have 2 fields, separated by a single whitespace.
-- first field is a Method, second field is a Route (could contains wildcard)
local ROUTES_FILE="/tmp/urls.txt"
local REFRESH_SEC = 60

local routes={}
local last_updated = 0
local routes_file_not_found = false

-- return `true` if `ROUTES_FILE` contains a method and a path matching `uri` and request method
-- content from `ROUTES_FILE` file is reloaded every `REFRESH_SEC` seconds
-- if the file doesn't exist: enable for all routes
_M.custom_enabled_routes = function(uri)
    --  the file doesn't exist: enable for all routes
    if routes_file_not_found == true then
        return true
    end

    -- periodically reload the file
    local now = os.time(os.date("!*t"))
    if now - last_updated >= REFRESH_SEC then
        last_updated = now
        -- check if the file exists
        local f = io.open(ROUTES_FILE, "r")
        if f ~= nil then
            io.close(f)
        else
            --  the file doesn't exist: enable for all routes
            ngx.log(ngx.ERR, "Enabled routes file does not exist: " .. ROUTES_FILE)
            routes_file_not_found = true
            return true
        end

        ngx.log(ngx.DEBUG, "Reloading enabled routes..")

        -- empty routes table
        for i, _ in ipairs(routes) do routes[i] = nil end
        -- read the file, fill the routes table
        for line in io.lines(ROUTES_FILE) do
            -- split the line
            local words = {}
            for w in line:gmatch("%S+") do
                table.insert(words, w)
            end
            if #words >=2 and words[1] ~= nil and words[2] ~= nil then
                local val = {}
                val["method"] = words[1]:upper()
                val["path"] = words[2]
                table.insert(routes, val)
            end
        end
    end

    -- check for method / path
    local method = ngx.req.get_method()
    for _, r in ipairs(routes) do
        if r["method"] == method and wildcard_search(uri, r["path"]) then
            return true
        end
    end

    return false
end
