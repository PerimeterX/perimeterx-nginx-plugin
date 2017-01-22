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
    local px_client = require("px.utils.pxclient").load(config_file)
    local px_logger = require("px.utils.pxlogger").load(config_file)
    local px_constants = require "px.utils.pxconstants"
    local ngx_exit = ngx.exit
    local string_gsub = string.gsub

    local function inject_captcha_script(vid, uuid)
        return '<script src="https://www.google.com/recaptcha/api.js"></script><script type="text/javascript">window.px_vid = "' .. vid ..
                '"; function handleCaptcha(response){var vid="' .. vid .. '";var uuid="' .. uuid .. '";var name="_pxCaptcha";var expiryUtc=new Date(Date.now()+1000*10).toUTCString();' ..
                'var cookieParts=[name,"=",response+":"+vid+":"+uuid,"; expires=",expiryUtc,"; path=/"];document.cookie=cookieParts.join("");location.reload()}</script>'
    end

    local function inject_px_snippet()
        local app_id = ''
        if px_config.px_appId then
            app_id = px_config.px_appId
        end
        return '<script type="text/javascript">(function(){window._pxAppId="' .. app_id .. '";var p=document.getElementsByTagName("script")[0],s=document.createElement("script");s.async=1;s.src="//client.perimeterx.net/' .. app_id .. '/main.min.js";p.parentNode.insertBefore(s,p);}());</script>';
    end

    function _M.block(reason)
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
            ref_str = '<span style="font-size: 20px;">Block Reference: <span style="color: #525151;">#' .. uuid .. '</span></span>';
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
            ngx.header["Content-Type"] = 'text/html';
            if px_config.custom_block_url then
                if not px_config.redirect_on_custom_url then
                    local res = ngx.location.capture(px_config.custom_block_url)
                    if res.truncated or res.status >= 300 then
                        ngx.status = 500
                        ngx_say('Unable to fetch custom block url. Status: ' .. tostring(res.status))
                        ngx_exit(ngx.OK)
                    end
                    local body = res.body
                    if px_config.captcha_enabled and ngx.ctx.px_action == 'c' then
                        body = string_gsub(res.body, '</head>', inject_captcha_script(vid, uuid) .. '</head>', 1);
                        body = string_gsub(body, '::BLOCK_REF::', uuid);
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
                if px_config.captcha_enabled and ngx.ctx.px_action == 'c' then
                    local head = '<head><link type="text/css" rel="stylesheet" media="screen, print" href="//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800"> <meta charset="UTF-8"> <title>Access to This Page Has Been Blocked</title> <style> p { width: 60%; margin: 0 auto; font-size: 35px; } body { background-color: #a2a2a2; font-family: "Open Sans"; margin: 5%; } img { widht: 180px; } a { color: #2020B1; text-decoration: blink; } a:hover { color: #2b60c6; } </style> <style type="text/css"></style> ' .. inject_captcha_script(vid, uuid) .. inject_px_snippet() .. ' </head>'
                    local body = '<body cz-shortcut-listen="true"> <div><img src="http://storage.googleapis.com/instapage-thumbnails/035ca0ab/e94de863/1460594818-1523851-467x110-perimeterx.png"> </div> <span style="color: white; font-size: 34px;">Access to This Page Has Been Blocked</span> <div style="font-size: 24px;color: #000042;"><br> Access to this page is blocked according to the website security policy. <br> Your browsing activity made us think you may be a bot. <br> <br> This may happen as a result of the following: <ul> <li>JavaScript is disabled or not running properly.</li> <li>Your browsing behaviour is not likely to be a regular user.</li> </ul> To read more about the bot defender solution: <a href="https://www.perimeterx.com/bot-defender">https://www.perimeterx.com/bot-defender</a> <br> If you think the blocking was done by mistake, contact the site administrator. <br> <div class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div><br> </br> ' .. ref_str .. ' </div>';
                    ngx_say('<html lang="en">' .. head .. body .. '</html>');
                else
                    ngx_say('<html lang="en"><head> <link type="text/css" rel="stylesheet" media="screen, print" href="//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800"> <meta charset="UTF-8"> <title>Access to This Page Has Been Blocked</title> <style> p { width: 60%; margin: 0 auto; font-size: 35px; } body { background-color: #a2a2a2; font-family: "Open Sans"; margin: 5%; } img { widht: 180px; } a { color: #2020B1; text-decoration: blink; } a:hover { color: #2b60c6; } </style> <style type="text/css"></style>' .. inject_px_snippet() .. '</head><body cz-shortcut-listen="true"><div><img src="http://storage.googleapis.com/instapage-thumbnails/035ca0ab/e94de863/1460594818-1523851-467x110-perimeterx.png"></div><span style="color: white; font-size: 34px;">Access to This Page Has Been Blocked</span><div style="font-size: 24px;color: #000042;"><br> Access to this page is blocked according to the website security policy. <br> Your browsing activities made us think you may be a bot. <br> <br> This may happen as a result of the following: <ul> <li>JavaScript is disabled or not running properly.</li> <li>Your browsing behaviour is  not likely to be a regular user.</li> </ul> To read more about the bot defender solution: <a href="https://www.perimeterx.com/bot-defender">https://www.perimeterx.com/bot-defender</a> <br> If you think the blocking was done by mistake, contact the site administrator. <br> <br> </br>' .. ref_str .. '</div></body></html>')
                end
                ngx_exit(ngx.OK);
            end
        else
            return true
        end
    end

    return _M
end

return M
