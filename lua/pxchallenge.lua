----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.0.0
-- Release date: 15.12.2015
----------------------------------------------
local json = require "pxlua-json"
local http = require "pxhttp"

function sendTo_Perimeter()
    local pxdata = {}
    pxdata['met'] = ngx.req.get_method();
    pxdata['headers'] = ngx.req.get_headers();
    pxdata['px_app_id'] = ngx.ctx.px_app_id;
    pxdata['pxtoken'] = ngx.ctx.pxtoken;
    pxdata['pxidentifier'] = ngx.ctx.pxidentifier;
    pxdata = json.encode(pxdata);
    local apiServer = ngx.ctx.px_apiServer;
    if apiServer ~= nil and apiServer ~= "" then
        local submit = function()
           local httpc = http.new()
           local res, err = httpc:request_uri(apiServer .. '/api/v1/collector/nginxcollect', {
               method = "POST",
               body = "data=" .. pxdata,
               headers = {
                    ["Content-Type"] = "application/x-www-form-urlencoded",
                }
            })

	if not res then
	    ngx.log(ngx.ERR, "failed to make http post: ",err)
	    return
	elseif res.status ~= 200 then
	    ngx.log(ngx.ERR, "Non 200 response code: ", res.status)
        end
	end

        local ok, err = ngx.timer.at(1, submit)
	if not ok then
	    ngx.log(ngx.ERR, "Failed timer for submit: ", err)
	    return
  	end

    end
end

sendTo_Perimeter();

-- Sending the javascript challenge back to the client - expect a cookie set
ngx.header["Content-type"] = "text/html"
ngx.say('<H1 style="display: none;">You are not authorized to view this page - PerimeterX.</H1><script>var str = "' .. ngx.ctx.pxidentifier .. '";var strx = "";for (var i = 0; i < str.length; i++) {    strx += str[i];    if ((i + 1) % 4 == 0) {        strx += Math.random().toString(36).substring(3, 4);    }};document.cookie = "_pxcook=" + strx;window.location.reload();</script>');
