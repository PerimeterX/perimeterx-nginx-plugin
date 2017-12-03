---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.4
-- Release date: 07.11.2016
----------------------------------------------
local M = {}

function M.load(config_file)
    local _M = {}
    local ngx_HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN
    local ngx_HTTP_TEMPORARY_REDIRECT = 307
    local ngx_redirect = ngx.redirect
    local ngx_say = ngx.say
    local ngx_encode_args = ngx.encode_args
    local ngx_endcode_64 = ngx.encode_base64
    local px_config = require(config_file)

    local px_template = require("px.block.pxtemplate").load(config_file)
    local px_client = require("px.utils.pxclient").load(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local cjson = require "cjson"
    local px_constants = require "px.utils.pxconstants"
    local ngx_exit = ngx.exit
    local string_gsub = string.gsub

    local function inject_captcha_script(vid, uuid)
        return '<script src="https://www.google.com/recaptcha/api.js"></script><script type="text/javascript">window.px_vid = "' .. vid ..
                '"; function handleCaptcha(response){var vid="' .. vid .. '";var uuid="' .. uuid .. '";var name="_pxCaptcha";var expiryUtc=new Date(Date.now()+1000*10).toUTCString();' ..
                'var cookieParts=[name,"=",response+":"+vid+":"+uuid,"; expires=",expiryUtc,"; path=/"];document.cookie=cookieParts.join("");location.reload()}</script>'
    end

    local function parse_action(action)
        if action == "c" then
            return "captcha"
        elseif action == "b" then
            return "block"
        elseif action == "j" then
            return "challenge"
        else
            return "captcha"
        end
    end

    function _M.block(reason)
	ngx.ctx.block_reason = reason
        local details = {}
        local ref_str = ''
        local vid = ''
        local uuid = ''
        local score = 0

        details.module_version = px_constants.MODULE_VERSION
        if reason then
            details.block_reason = reason
        end

        if ngx.ctx.uuid then
            uuid = ngx.ctx.uuid
            details.block_uuid = uuid
        end

        if ngx.ctx.block_score then
            score = ngx.ctx.block_score
            details.block_score = score
        end

        if ngx.ctx.vid then
            vid = ngx.ctx.vid
        end
        px_client.send_to_perimeterx('block', details);
        if px_config.block_enabled then
            if ngx.ctx.px_cookie_origin == "header" then
                local templateName = "block";
                if ngx.ctx.px_action == 'c' then
                    if px_config.captcha_provider == 'funCaptcha' then
                        templateName = 'funcaptcha'
                    else
                        templateName = 'captcha'
                    end
                end
                px_logger.debug("Enforcing action: " .. templateName .. " page is served")
                local html = px_template.get_template(templateName .. ".mobile", details.block_uuid, vid)
                local collectorUrl = 'https://collector-' .. string.lower(px_config.px_appId) .. '.perimeterx.net'
                local result = {
                    action = parse_action(ngx.ctx.px_action),
                    uuid = details.block_uuid,
                    vid = vid,
                    appId = px_config.px_appId,
                    page = ngx.encode_base64(html),
                    collectorUrl = collectorUrl
                }
                ngx.header["Content-Type"] = 'application/json';
                ngx.status = ngx_HTTP_FORBIDDEN;
                ngx.say(cjson.encode(result))
                ngx_exit(ngx.OK)
            else
                ngx.header["Content-Type"] = 'text/html';
                if px_config.custom_block_url then
                    if not px_config.redirect_on_custom_url then
                        local res = ngx.location.capture(px_config.custom_block_url)
                        if res.truncated or res.status >= 300 then
                            ngx.status = 500
                            ngx_say('Unable to fetch custom block url. Status: ' .. tostring(res.status))
                            ngx_exit(ngx.OK)
                        end
                        local body = ''
                        if ngx.ctx.px_action == 'j' then
                            px_logger.debug("challange page is served")
                            body = ngx.ctx.px_action_data
                        else
                            body = res.body
                            if ngx.ctx.px_action == 'c' then
                                body = string_gsub(res.body, '</head>', inject_captcha_script(vid, uuid) .. '</head>', 1);
                                body = string_gsub(body, '::BLOCK_REF::', uuid);
                            end
                        end
                        ngx.status = ngx_HTTP_FORBIDDEN;
                        ngx_say(body);
                        ngx_exit(ngx.OK);
                    else
                        -- handling custom block url: create redirect url with original request url, vid and uuid as query params to use with captcha_api
                        local req_query_param = ngx.req.get_uri_args()
                        local enc_url, enc_args
                        local original_req_url = ngx.var.uri
                        if req_query_param then
                            enc_args = ngx_encode_args(req_query_param)
                            enc_url = ngx_endcode_64(original_req_url .. '?' .. enc_args)
                        end
                        local redirect_url = px_config.custom_block_url .. '?url=' .. enc_url .. '&uuid=' .. uuid .. '&vid=' .. vid
                        px_logger.debug('Redirecting to custom block page: ' .. redirect_url)
                        ngx_redirect(redirect_url, ngx_HTTP_TEMPORARY_REDIRECT)
                    end
                else
                    ngx.status = ngx_HTTP_FORBIDDEN;
                    if px_config.api_protection_mode then
                        local redirect_url = ngx.req.get_headers()['Referer']
                        if redirect_url == nil or redirect_url == '' then
                            redirect_url = px_config.api_protection_default_redirect_url
                        end
                        redirect_url = ngx_endcode_64(redirect_url)
                        local url = px_config.api_protection_block_url .. '?url=' .. redirect_url .. '&uuid=' .. uuid .. '&vid=' .. vid
                        local result = {
                            reason = "blocked",
                            redirect_to = url
                        }
                        ngx.header["Content-Type"] = 'application/json';
                        ngx_say(cjson.encode(result))
                        ngx_exit(ngx.OK)
                    else
                        local html = '';
                        local template = 'block'
                        if ngx.ctx.px_action == 'j' then
                            px_logger.debug("Enforcing action: challange page is served")
                            html = ngx.ctx.px_action_data
                        else
                            if ngx.ctx.px_action == 'c' then
                                if px_config.captcha_provider == 'funCaptcha' then
                                    template = 'funcaptcha'
                                else
                                    template = 'captcha'
                                end
                            end
                            px_logger.debug("Enforcing action: " .. template .. " page is served")
                            html = px_template.get_template(template, uuid, vid)
                        end
                        ngx_say(html);
                        ngx_exit(ngx.OK);
                    end
                end
            end
        end
    end
    return _M
end

return M
