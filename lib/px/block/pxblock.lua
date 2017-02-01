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
                local includes = '<link type="text/css" rel="stylesheet" media="screen, print" href="//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800">'
                local styles = ' <style> p { width: 60%; margin: 0 auto; font-size: 35px; } body { background-color: #f4f4f4; font-family: "Open Sans"; } #bodyWrapper { margin: 2%; } img { widht: 180px; } ul { margin: 2px; } a { color: #2020B1; text-decoration: blink; } a:hover { color: #2b60c6; } @media only screen and (min-width: 1000px) { .paraDiv { width: 30%; } } .paraDiv { font-size: 20px; color: #000042; } </style>'
                local px_snippet = '(function () { window._pxAppId = "' .. px_config.px_appId .. '"; var p = document.getElementsByTagName("script")[0], s = document.createElement("script"); s.async = 1; s.src = "//client.perimeterx.net/' .. px_config.px_appId .. '/main.min.js"; p.parentNode.insertBefore(s, p); }());'
                local html = '';

                if px_config.captcha_enabled and ngx.ctx.px_action == 'c' then
                    local captcha_script_include = '<script src="https://www.google.com/recaptcha/api.js"></script>'
                    local captcha_script = 'function handleCaptcha(response) { var vid = "' .. vid .. '"; var uuid = "' .. uuid .. '"; var name = "_pxCaptcha"; var expiryUtc = new Date(Date.now() + 1000 * 10).toUTCString(); var cookieParts = [name, "=", response + ":" + vid + ":" + uuid, "; expires=", expiryUtc, "; path=/"]; document.cookie = cookieParts.join(""); document.cookie=cookieParts.join("");location.reload()}'
                    local captcha_body = '<body> <div id="bodyWrapper"> <span style="font-size: 28px;">Please verify you are not a bot</span> <div class="paraDiv"><br> Access to this page has been blocked because we believe you are violating our Terms of Use by using automation to browse the site. </div> <div class="paraDiv"><br> This may happen as a result of the following: <ul> <li> Javascript is disabled or blocked </li> <li> Your browser does not support cookies </li> </ul> </div> <div class="paraDiv"><br> Please note, Javascript and Cookies must be enabled on your browser to access the website. </div> <div class="paraDiv"> Please verify below that you are not a bot in order to proceed. <br/> <div style="margin: 10px 0px 10px 0px" class="g-recaptcha" data-sitekey="6Lcj-R8TAAAAABs3FrRPuQhLMbp5QrHsHufzLf7b" data-callback="handleCaptcha" data-theme="dark"></div> </div> <div style="font-size: 20px;color: #000042;"> Reference ID: #' .. uuid .. ' </div> </div> <div style="position: fixed; bottom: 20px; width: 100%"> <hr/> Powered by <img style="width: 80px; vertical-align: -5px" src="https://storage.googleapis.com/px-assets/px.png"> </div> </body>'
                    html = '<html><head>' .. captcha_script_include .. includes .. styles .. '<script>' .. captcha_script .. px_snippet .. '</script></head><body>' .. captcha_body .. '</body></html>'
                else
                    local block_body = '<body> <div id="bodyWrapper"> <span style="font-size: 28px;">Please verify you are not a bot</span> <div class="paraDiv"><br> You have been blocked because we believe you are violating our Terms of Use by using automation to browse the website. </div> <div class="paraDiv"><br> Please note, Javascript and Cookies must be enabled on your browser to access the website. </div> <br/> <div class="paraDiv"> If you think you have been blocked by mistake, please contact website administrator. </div> <br/> <div style="font-size: 20px;color: #000042;"> Reference ID: #' .. uuid .. '</div> </div> <div style="position: fixed; bottom: 20px; width: 100%"> <hr/> Powered by <img style="width: 80px; vertical-align: -5px" src="https://storage.googleapis.com/px-assets/px.png"> </div> </body>'
                    html = '<html><head>' .. includes .. styles .. '<script>' .. px_snippet .. '</script></head><body>' .. block_body .. '</body></html>'
                end
                ngx_say(html);
                ngx_exit(ngx.OK);
            end
        else
            return true
        end
    end

    return _M
end

return M
