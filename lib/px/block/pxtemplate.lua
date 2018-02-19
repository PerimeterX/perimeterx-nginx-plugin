---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------
local M = {}

function M.load(config_file)

    local _M = {}

    local px_config = require(config_file)
    local lustache = require "lustache"
    local px_constants = require "px.utils.pxconstants"

    local px_logger = require("px.utils.pxlogger").load(config_file)

    local function get_props(px_config, uuid, vid)
        local logo_css_style = 'visible'
        if (px_config.custom_logo == nil) then
            logo_css_style = 'hidden'
        end

        local js_client_src = string.format('//client.perimeterx.net/%s/main.min.js', px_config.px_appId)
        if px_config.first_party_enabled then
            local reverse_prefix = string.sub(px_config.px_appId, 3, string.len(px_config.px_appId))
            js_client_src = string.format('/%s%s',reverse_prefix, px_constants.FIRST_PARTY_VENDOR_PATH)
        end

        local collectorUrl = 'https://collector-' .. string.lower(px_config.px_appId) .. '.perimeterx.net'

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

    local function get_path()
        return string.sub(debug.getinfo(1).source, 2, string.len("/pxtemplate.lua") * -1)
    end

    local function get_content(template)
        local __dirname = get_path()
        local template_path = string.format("%stemplates/%s.mustache",__dirname,template)

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

        return lustache:render(templateStr, props)
    end

    return _M
end

return M
