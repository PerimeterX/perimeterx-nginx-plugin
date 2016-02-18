----------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
-- Version 1.1.0
-- Release date: 21.02.2015
----------------------------------------------
local pxClient = require "px.pxclient"
pxClient.sendTo_Perimeter('challenge_sent');

ngx.header["Content-type"] = "text/html"
ngx.say('<H1 style="display: none;">You are not authorized to view this page - PerimeterX.</H1><script>var str = "' .. ngx.ctx.pxidentifier .. '";var strx = "";for (var i = 0; i < str.length; i++) {    strx += str[i];    if ((i + 1) % 4 == 0) {        strx += Math.random().toString(36).substring(3, 4);    }};document.cookie = "_pxcook=" + strx;window.location.reload();</script>');
