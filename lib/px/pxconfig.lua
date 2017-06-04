----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.5.0
-- Release date: 05.04.2016
----------------------------------------------


local _M = {}

_M.px_enabled = true

-- ##  Configuration Block ##
_M.px_appId = 'PXvRfnOj4y'
_M.cookie_secret = 'ijhjKvIpESxAk+eFSOyaI60HzktpsrJeIjIiqEF1HXBIq2zfY0Ziv/bGnWwk/dKR'
_M.auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzY29wZXMiOlsicmlza19zY29yZSIsInJlc3RfYXBpIl0sImlhdCI6MTQ5NTEwNjI5MSwic3ViIjoiUFh2UmZuT2o0eSIsImp0aSI6IjNlZDJjOWIwLTk5MDgtNDQ4OC05MTk3LWY1NzkzZGI1OTBlMSJ9.wrKUnEoUivOcx9e5_cUHXvVlXnHbRJt0Gv4-u95iCFw'
_M.blocking_score = 60
_M.cookie_encrypted = true
_M.enable_server_calls = true
_M.send_page_requested_activity = true
_M.block_enabled = true
_M.captcha_enabled = true
_M.px_debug = true
_M.additional_activity_handler = nil
_M.custom_block_url = '/block.html'
_M.redirect_on_custom_url = false
--_M.additional_activity_handler = function(event_type, ctx, details)
--	local ngx_say = ngx.say
--	local ngx_exit = ngx.exit
--	local cjson = require "cjson"
--
--
--	if ngx.req.get_headers()["x-px-auto-tests"] and ngx.req.get_headers()["x-px-auto-tests"] == "bigbotsdontcry" then
--
--		local context = {}
--		context["px_cookies"] = {}
--		if ngx.var.cookie__px3 then
--			context["px_cookies"]["v1"] = ngx.var.cookie__px3
--		end
--
--		if ngx.var.cookie__px then
--			context["px_cookies"]["v1"] = ngx.var.cookie__px
--		end
--
--		context["decoded_px_cookie"] = ngx.ctx.px_cookie or nil
--		context["px_cookie_hmac"] = ngx.ctx.px_cookie_hmac or nil
--		context["ip"] = ngx.var.remote_addr
--		context["px_captcha"] = ngx.ctx.px_captcha or nil
--		context["http_version"] = ngx.req.http_version()
--		context["http_method"] = ngx.req.get_method()
--		context["headers"] = ngx.req.get_headers()
--		context["hostname"] = ngx.var.host
--		context["uri"] = ngx.var.request_uri
--		context["user_agent"] = ngx.var.http_user_agent
--		context["full_url"] = ngx.var.scheme .. "://" .. ngx.var.host .. ngx.var.uri;
--		context["s2s_call_reason"] = ngx.ctx.s2s_call_reason
--		context["score"] = ngx.ctx.block_score or 0
--		context["vid"] = ngx.ctx.vid or nil
--		context["uuid"] = ngx.ctx.uuid or nil
--		context["block_reason"] = ngx.ctx.block_reason or nil
--		context["is_made_s2s_api_call"] = ngx.ctx.is_made_s2s_api_call or false
--		context["block_action"] = ngx.ctx.block_action or "c"
--		context["block_data"] = ngx.ctx.px_action_data or nil
--		context["sensitive_route"] = ngx.ctx.sensitive_route or false
--
--		ngx_say(cjson.encode(context));
--		ngx_exit(ngx.OK);
--	end
--end

_M.s2s_timeout = 1500
_M.px_maxbuflen = 10
_M.score_header_name = 'X-PX-SCORE'
_M.px_port = 443
_M.ssl_enabled = true
_M.enabled_routes = {}
-- -- ## END - Configuration block ##

-- ## Filter Configuration ##

_M.whitelist = {
    uri_full = { _M.custom_block_url },
    uri_prefixes = {},
    uri_suffixes = { '.css', '.bmp', '.tif', '.ttf', '.docx', '.woff2', '.js', '.pict', '.tiff', '.eot', '.xlsx', '.jpg', '.csv', '.eps', '.woff', '.xls', '.jpeg', '.doc', '.ejs', '.otf', '.pptx', '.gif', '.pdf', '.swf', '.svg', '.ps', '.ico', '.pls', '.midi', '.svgz', '.class', '.png', '.ppt', '.mid', 'webp', '.jar' },
    ip_addresses = {},
    ua_full = {},
    ua_sub = {}
}

return _M
