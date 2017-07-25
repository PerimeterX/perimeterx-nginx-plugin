---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------
local M = {}

function M.load(config_file)

    local _M = {}

    local px_config = require(config_file)
    local lustache = require "lustache"
    local px_logger = require("px.utils.pxlogger").load(config_file)

    local function get_props(px_config, uuid, vid)
        local logo_css_style = 'visible'
        if (px_config.custom_logo == nil) then
            logo_css_style = 'hidden'
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
            hostUrl = collectorUrl
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
            px_logger.error("the template " .. string.format("%s.mustache", template) .. " was not found")
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
