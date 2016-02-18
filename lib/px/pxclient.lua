----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------

local cjson = require "cjson"
local http = require "resty.http"

local CLIENT = {}

function CLIENT.sendTo_Perimeter(type)
    local pxdata = {}
    pxdata['met'] = ngx.req.get_method();
    pxdata['type'] = type;
    pxdata['headers'] = ngx.req.get_headers();
    pxdata['headers1'] = ngx.headers_sent;
    pxdata['px_app_id'] = ngx.ctx.px_app_id;
    pxdata['pxtoken'] = ngx.ctx.pxtoken;
    pxdata['pxidentifier'] = ngx.ctx.pxidentifier;
    pxdata['host'] = ngx.var.host;
    pxdata['timestamp'] = tostring(ngx.time());
    pxdata['uri'] = ngx.var.uri;
    pxdata['user_agent'] = ngx.var.http_user_agent;
    pxdata['socket_ip'] = ngx.var.remote_addr;
    pxdata = cjson.encode(pxdata);
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
                ngx.log(ngx.ERR, "Failed to make HTTP POST: ",err)
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

return CLIENT