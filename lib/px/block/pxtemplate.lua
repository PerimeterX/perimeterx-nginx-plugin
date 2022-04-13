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
        local captcha_params = string.format('/captcha.js?a=%s&m=%s&u=%s&v=%s', action, (ngx.ctx.px_is_mobile and '1' or '0'), uuid, vid)
        if action ~= 'r' then
            captcha_src = captcha_url_prefix .. '/' .. px_config.px_appId .. captcha_params
        end
        local alt_block_script = px_constants.BACKUP_CAPTCHA_HOST .. "/" .. px_config.px_appId .. captcha_params
        return {
            refId = uuid,
            vid = vid,
            uuid = uuid,
            appId = px_config.px_appId,
            hostUrl = collectorUrl,
            customLogo = px_config.custom_logo,
            jsClientSrc = js_client_src,
            firstPartyEnabled = first_party_enabled,
            blockScript = captcha_src,
            altBlockScript = alt_block_script,
            jsRef = px_config.js_ref,
            cssRef = px_config.css_ref
        }
    end


    function _M.get_hsc_props(px_config, uuid, vid, action)
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
        local jsTemplateScriptSrc = px_config.hypesale_host .. "/" .. px_config.px_appId .. "/checkpoint.js"
        local captcha_src = ''
        local captcha_params = string.format('/captcha.js?a=%s&m=%s&u=%s&v=%s', action, (ngx.ctx.px_is_mobile and '1' or '0'), uuid, vid)
        if action ~= 'r' then
            captcha_src = captcha_url_prefix .. '/' .. px_config.px_appId .. captcha_params
        end

        local alt_block_script = px_constants.BACKUP_CAPTCHA_HOST .. "/" .. px_config.px_appId .. captcha_params

        local isMobile = ""
        if ngx.ctx.px_is_mobile then
            isMobile = "1"
        else
            isMobile = "0"
        end

        return {
            refId = uuid,
            vid = vid,
            appId = px_config.px_appId,
            uuid = uuid,
            customLogo = px_config.custom_logo,
            cssRef = px_config.css_ref,
            jsRef = px_config.js_ref,
            hostUrl = collectorUrl,
            jsClientSrc = js_client_src,
            firstPartyEnabled = first_party_enabled,
            blockScript = captcha_src,
            altBlockScript = alt_block_script,
            jsTemplateScriptSrc = jsTemplateScriptSrc,
            isMobile = isMobile
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
        elseif action == px_constants.HSC_BLOCK_ACTION then
            path = 'hypesale_template'
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

    function _M.get_hsc_template(action, uuid, vid)
        local props = _M.get_hsc_props(px_config, uuid, vid, action)
        local templateStr = get_content(action)

        return lustache:render(templateStr, props)
    end

    return _M
end

return M
