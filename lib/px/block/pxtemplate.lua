---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------
local M = {}

function M.load(px_config)

    local _M = {}

    local lustache = require "lustache"
    local px_constants = require "px.utils.pxconstants"
    local px_logger = require("px.utils.pxlogger").load(px_config)

    function _M.get_props(px_config, uuid, vid, action)
        local logo_css_style = 'visible'
        if (px_config.custom_logo == nil) then
            logo_css_style = 'hidden'
        end

        local js_client_src = string.format('//client.perimeterx.net/%s/main.min.js', px_config.px_appId)
        local collectorUrl = '//' .. px_config.collector_host
        local captcha_url_prefix = '//' .. px_config.captcha_script_host
        local first_party_enabled = false
        -- in case we are in first party mode (not relevant for mobile), change the base paths to use first party
        if px_config.first_party_enabled and not ngx.ctx.px_is_mobile then
            local reverse_prefix_appid = string.sub(px_config.px_appId, 3, string.len(px_config.px_appId))
            local reverse_prefix = px_config.first_party_prefix ~= nil and px_config.first_party_prefix .. '/' .. reverse_prefix_appid or reverse_prefix_appid
            js_client_src = string.format('/%s%s', reverse_prefix, px_constants.FIRST_PARTY_VENDOR_PATH)
            collectorUrl = string.format('/%s%s', reverse_prefix, px_constants.FIRST_PARTY_XHR_PATH)
            captcha_url_prefix = string.format('/%s%s', reverse_prefix, px_constants.FIRST_PARTY_CAPTCHA_PATH)
            first_party_enabled = true
        end
        local captcha_src = ''
        if action ~= 'r' then
            captcha_src = captcha_url_prefix .. string.format('/' .. px_config.px_appId .. '/captcha.js?a=%s&m=%s&u=%s&v=%s', action, (ngx.ctx.px_is_mobile and '1' or '0'), uuid, vid)
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
            firstPartyEnabled = first_party_enabled,
            blockScript = captcha_src
        }
    end

    local function get_path()
        return string.sub(debug.getinfo(1).source, 2, string.len("/pxtemplate.lua") * -1)
    end

    local function get_content(action)
        local __dirname = get_path()
        local path = 'block_template'
        if action == 'r' then
            path = 'ratelimit'
        end
        local template_path = string.format("%stemplates/%s.mustache", __dirname, path)

        px_logger.debug("fetching template from: " .. template_path)
        local file = io.open(template_path, "r")
        if (file == nil) then
            px_logger.debug("the template " .. string.format("%s.mustache", template_path) .. " was not found")
        end
        local content = file:read("*all")
        file:close()
        return content
    end

    function _M.get_template(action, uuid, vid)
        local props = _M.get_props(px_config, uuid, vid, action)
        local templateStr = get_content(action)

        return lustache:render(templateStr, props)
    end

    return _M
end

return M
