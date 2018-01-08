local PXCookie = require('px.utils.pxcookie')

PXCookieV3 = PXCookie:new{}

function PXCookieV3:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function PXCookieV3:validate(data)
    local request_data = data .. ngx.var.http_user_agent
    local digest = self.hmac("sha256", self.cookie_secret, request_data)
    digest = self:to_hex(digest)

    -- policy with ip
    if digest == string.upper(ngx.ctx.px_cookie_hmac) then
        return true
    end
    self.px_logger.debug('Cookie HMAC validation failed, hmac: '.. digest ..', user-agent: ' .. self.px_headers.get_header("User-Agent"));
    return false
end

function PXCookieV3:process()
    cookie = ngx.ctx.px_orig_cookie
    if not cookie then
        error({ message = "no_cookie" })
    end


    if self.cookie_encrypted == true then
        self.px_logger.debug("cookie is encyrpted")
        -- self:decrypt(cookie, self.cookie_secret)
        local success, result = pcall(self.decrypt, self, cookie, self.cookie_secret)
        if not success then
            self.px_logger.debug("Could not decrpyt px cookie v3")
            error({ message = "cookie_decryption_failed" })
        end
        data = result['plaintext']
        orig_cookie = result['cookie']
    else
        hash, orig_cookie = self:split_decoded_cookie(cookie);
        local success, result = pcall(ngx.decode_base64, orig_cookie)
        if not success then
            self.px_logger.debug("Could not decode b64 cookie - " .. result)
            error({ message = "cookie_decryption_failed" })
        end
        data = result
    end

    -- Deserialize the JSON payload
    local success, result = pcall(self.decode, self, data)
    if not success then
        self.px_logger.debug("Could not decode cookie")
        error({ message = "cookie_decryption_failed" })
    end

    local fields = result
    ngx.ctx.px_cookie = data
    if fields.u then
        ngx.ctx.uuid = fields.u
    end
    if fields.v then
        ngx.ctx.vid = fields.v
    end
    if fields.a then
        ngx.ctx.px_action = fields.a
    end

    -- cookie expired
    ngx.ctx.cookie_timestamp = fields.t

    if fields.t and fields.t > 0 and fields.t / 1000 < os.time() then
        self.px_logger.debug('Cookie TTL is expired, value: '.. data ..', age: ' .. fields.t / 1000 - os.time())
        error({ message = "cookie_expired" })
    end

    -- Set the score header for upstream applications
    self.px_headers.set_score_header(fields.s)
    -- Set the score variable for logging

    -- Check bot score and block if it is >= to the configured block score
    if fields.s and fields.a then
        ngx.ctx.block_score = fields.s
    end

    if fields.s >= self.blocking_score then
        self.px_logger.debug("Visitor score is higher than allowed threshold: " .. fields.s)
        return false
end

    -- Validate the cookie integrity
    local success, result = pcall(self.validate, self, orig_cookie)
    if success == false or result == false then
        self.px_logger.debug("Could not validate cookie v3 signature - " .. orig_cookie)
        error({ message = "cookie_validation_failed" })
    end

    if self:is_sensitive_route() then
        self.px_logger.debug("cookie verification passed, risk api triggered by sensitive route")
        error({ message = "sensitive_route" })
    end

    return true
end

return PXCookieV3
