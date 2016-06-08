#!/usr/bin/env bash
docker rm -f nginx
mv lib/px/pxconfig.lua lib/px/pxconfig.lua.tmp
mv lib/px/utils/pxfilters.lua lib/px/utils/pxfilterx.lua.tmp
cp dev/pxconfig.lua lib/px/
cp dev/pxfilters.lua lib/px/utils/
docker build -t pxnginx .
mv lib/px/pxconfig.lua.tmp lib/px/pxconfig.lua
mv lib/px/utils/pxfilterx.lua.tmp lib/px/utils/pxfilters.lua
docker run --rm --name nginx -p 8888:80 pxnginx