 package = "perimeterx-nginx-plugin"
 version = "6.2.2-1"
 source = {
    url = "git://github.com/PerimeterX/perimeterx-nginx-plugin.git",
    tag = "v6.2.2",
 }
 description = {
    summary = "PerimeterX NGINX Lua Middleware.",
    detailed = [[
    ]],
    homepage = "http://www.perimeterx.com",
    license = "MIT/PerimeterX"
 }
 dependencies = {
    "lua-resty-http",
    "lua-resty-nettle",
    "luasocket",
    "lustache"
 }

 build = {
    type = "make"
 }
