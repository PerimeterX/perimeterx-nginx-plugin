local ngx_HTTP_FORBIDDEN = ngx.HTTP_FORBIDDEN
local ngx_say = ngx.say
local ngx_exit = ngx.exit
local _M = {}

function _M.block()
    local full_url = ngx.var.scheme .. "://" .. ngx.var.host .. '/' .. ngx.var.uri;
    ngx.status = ngx_HTTP_FORBIDDEN
    ngx.header["Content-Type"] = 'text/html'
    ngx_say('<!DOCTYPE html> <html lang="en"> <head> <link type="text/css" rel="stylesheet" media="screen, print" href="//fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800"> <meta charset="UTF-8"> <title>Title</title> <style> p { width: 60%; margin: 0 auto; font-size: 35px; } body { background-color: #a2a2a2; font-family: "Open Sans"; margin: 5%; } img { widht: 180px; } a { text-decoration: blink; } a:hover { color: #6496C6; } </style> </head> <body> <div> <img src="http://storage.googleapis.com/instapage-thumbnails/035ca0ab/e94de863/1460594818-1523851-467x110-perimeterx.png"> </div> <span style="color: white; font-size: 34px;">Access to this page has been Blocked</span> <div style="font-size: 24px"> <br/> Access to ' .. full_url .. ' is blocked according to the site security policy. <br/> Your browsing behaviour fingerprinting made us think you may be a bot. <br/> <br/> This may happen as a result of the following: <ul> <li>JavaScript is disabled or not running properly.</li> <li>Your browsing behaviour fingerprinting are not likely to be a regular user.</li> </ul> To read more about the bot defender solution: <a href="https://www.perimeterx.com/bot-defender">https://www.perimeterx.com/bot-defender</a> <br/> If you think the blocking was done by mistake, contact the site administrator. </div> </body> </html>')
    ngx.exit(ngx.OK)
end

return _M


