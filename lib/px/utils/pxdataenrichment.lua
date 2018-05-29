local M = {}

function M.load(px_config)
    local _M = {}

    local px_config = px_config
    local px_logger = require("px.utils.pxlogger").load(px_config)
    local px_common_utils = require("px.utils.pxcommonutils")
    local hmac = require "resty.nettle.hmac"
    local cjson = require "cjson"

    -- Processing pxde and validating its hmac
    -- @pxde - string extracted from _pxde
    function _M.process(pxde)
        px_logger.debug('pxde ' ..  pxde)
        local splitted_cookie = px_common_utils.split_string(pxde, "[^:]+")

        if table.getn(splitted_cookie) > 1 then
            ngx.ctx.de_verified = false

            local pxde_hash, pxde
            pxde_hash = splitted_cookie[1]
            pxde = splitted_cookie[2]

            local hash_digest = hmac("sha256", px_config.cookie_secret, pxde)
            hash_digest = px_common_utils.to_hex(hash_digest)
            px_logger.debug('hash_digest [' .. hash_digest .. "] pxde_hash [" .. string.upper(pxde_hash) .."]")
            if hash_digest == string.upper(pxde_hash) then
                ngx.ctx.pxde_verified = true
                px_logger.debug("pxde hmac validation success")
            end

            local success, decoded_pxde = pcall(ngx.decode_base64, pxde)
            if not success then
                px_logger.debug("error while decoding pxde")
                return
            end
            px_logger.debug("pxde decoded: " .. decoded_pxde)

            local success, pxde_json = pcall(cjson.decode, decoded_pxde)
            if not success then
                px_logger.debug("error while encoding pxde to json")
                ngx.ctx.pxde = decoded_pxde
                return
            end
            px_logger.debug("pxde json encoding success")
            ngx.ctx.pxde = pxde_json
        end
    end

    return _M
end

return M
