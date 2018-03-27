---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------
local M = {}

function M.load(config_file)

    local _M = {}

    local px_config = require(config_file)
    local lustache = require "lustache"
    local px_constants = require "px.utils.pxconstants"
    local http = require "resty.http"
    local px_logger = require("px.utils.pxlogger").load(config_file)

    local function get_props(px_config, uuid, vid)
        local logo_css_style = 'visible'
        if (px_config.custom_logo == nil) then
            logo_css_style = 'hidden'
        end

        local js_client_src = string.format('//client.perimeterx.net/%s/main.min.js', px_config.px_appId)
        local collectorUrl = 'https://collector-' .. string.lower(px_config.px_appId) .. '.perimeterx.net'
        if px_config.first_party_enabled then
            local reverse_prefix = string.sub(px_config.px_appId, 3, string.len(px_config.px_appId))
            js_client_src = string.format('/%s%s',reverse_prefix, px_constants.FIRST_PARTY_VENDOR_PATH)
            collectorUrl = string.format('/%s%s',reverse_prefix, px_constants.FIRST_PARTY_XHR_PATH)
        end

        return {
            refId = uuid,
            vid = vid,
            appId = px_config.px_appId,
            uuid = uuid,
            customLogo = px_config.custom_logo,
            cssRef = px_config.css_ref,
            jsRef = px_config.js_ref,
            logoVisibility = logo_css_style,
            hostUrl = collectorUrl,
            jsClientSrc = js_client_src,
            firstPartyEnabled = px_config.first_party_enabled
        }
    end

    local function get_script(script_name)
        local timeout = px_config.client_timeout
        -- create new HTTP connection
        local httpc = http.new()
        httpc:set_timeout(5000)
        local ok, err = httpc:connect('sample-go.pxchk.net', 8081)
        if not ok then
            px_logger.error("HTTPC connection error: " .. err)
        end
        -- local session, err = httpc:ssl_handshake()
        -- if not session then
        --     px_logger.debug("HTTPC SSL handshare error: " .. err)
        -- end
        local res, err = httpc:request({
            path = '/' .. script_name .. '.js',
            headers = {
                ["Content-Type"] = "application/javscript",
            }
        })
        if not res then
            px_logger.error("Failed to make HTTP GET: " .. err)
        elseif res.status ~= 200 then
            px_logger.debug("Non 200 response code: " .. res.status)
        else
            px_logger.debug("get script response status: " .. res.status)
        end
        local ok, err = httpc:set_keepalive()
        if not ok then
            px_logger.error("Failed to set keepalive: " .. err)
        end
        local body = ''
        if res == nil then
            return body
        end 
        local reader = res.body_reader

        repeat
            local chunk, err = reader(8192)
            if err then
                ngx.log(ngx.ERR, err)
                break
            end

            if chunk then
                body = body .. chunk
            end
        until not chunk
        return body
    end

    local function get_path()
        return string.sub(debug.getinfo(1).source, 2, string.len("/pxtemplate.lua") * -1)
    end

    local function get_content(template)
        local __dirname = get_path()
        local template_path = string.format("%sblock_template.mustache",__dirname)

        px_logger.debug("fetching template from: " .. template_path)
        local file = io.open(template_path, "r")
        if (file == nil) then
            px_logger.debug("the template " .. string.format("%s.mustache", template) .. " was not found")
        end
        local content = file:read("*all")
        file:close()
        return content
    end

    function _M.get_template(template, uuid, vid)

        local props = get_props(px_config, uuid, vid)
        local templateStr = get_content(template)
        props['blockScript'] = get_script(template)
        return lustache:render(templateStr, props)
    end

    return _M
end

return M
