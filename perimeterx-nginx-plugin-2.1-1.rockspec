 package = "perimeterx-nginx-plugin"
 version = "2.1-1"
 source = {
    url = "git://github.com/PerimeterX/perimeterx-nginx-plugin.git",
    tag = "v2.1.1",
 }
 description = {
    summary = "PerimeterX NGINX Lua Middleware.",
    detailed = [[
    ]],
    homepage = "http://www.perimeterx.com",
    license = "MIT/PerimeterX"
 }
 dependencies = {
    "lua-cjson",
    "lua-resty-http",
    "lua-resty-nettle"
 }

 build = {
    type = "make"
 }