local PXToken = require('px.utils.pxtoken')

TokenV1 = PXToken:new{}

function TokenV1:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function TokenV1:validate(data)
    local request_data = data.t .. data.s.a .. data.s.b .. data.u;
    if data.v then
        request_data = request_data .. data.v
    end

    if data.a then
        request_data = request_data .. data.a
    end

    local request_data_ip = request_data .. self.px_headers.get_ip()
    local digest_ip = self.hmac("sha256", self.cookie_secret, request_data_ip)
    digest_ip = self:to_hex(digest_ip)

     -- policy with ip
    if digest_ip == string.upper(data.h) then
        self.px_logger.debug('cookie verification succeed with IP in signature')
        return true
    end

    local request_data_noip = request_data
    local digest_noip = self.hmac("sha256", self.cookie_secret, request_data_noip)
    digest_noip = self:to_hex(digest_noip)

    -- policy with no ip
    if digest_noip == string.upper(data.h) then
        self.px_logger.debug('cookie verification succeed with no IP in signature')
        return true
    end

    self.px_logger.debug('Cookie HMAC validation failed, value without ip: '.. digest_noip ..' with ip: '.. digest_ip ..', user-agent: ' .. self.px_headers.get_header("User-Agent"));
    return false
end

function TokenV1:process()
    local cookie = ngx.ctx.px_orig_cookie
    -- Decrypt AES-256 or base64 decode cookie
    local data
    if self.cookie_encrypted == true then
        local success, result = pcall(self.pre_decrypt, self, cookie, self.cookie_secret)
        if not success then
            self.px_logger.debug("Could not decrpyt cookie - " .. result["message"])
            error({ message = result["message"] })
        end
        data = result["plaintext"]
    else
        local success, result = pcall(ngx.decode_base64, cookie)
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
    ngx.ctx.px_cookie = data;
    ngx.ctx.px_cookie_hmac = fields.h

    if fields.u then
        ngx.ctx.uuid = fields.u
    end

    if fields.v then
        ngx.ctx.vid = fields.v
    end


    -- cookie expired
    ngx.ctx.cookie_timestamp = fields.t

    if fields.t > 0 and fields.t / 1000 < os.time() then
        self.px_logger.debug('Cookie TTL is expired, value: '.. data ..', age: ' .. fields.t / 1000 - os.time())
        error({ message = "cookie_expired" })
    end

    -- Set the score header for upstream applications
    self.px_headers.set_score_header(fields.s.b)

    -- Check bot score and block if it is >= to the configured block score
    if fields.s then
        ngx.ctx.px_action = 'c'
        ngx.ctx.block_score = fields.s.b
    end

    if fields.s.b and fields.s.b >= self.blocking_score then
        self.px_logger.debug("Visitor score is higher than allowed threshold: " .. fields.s.b)
        return false
    end

    -- Validate the cookie integrity
    local success, result = pcall(self.validate, self, fields)
    if not success or result == false then
        self.px_logger.debug("Could not validate cookie v1 signature - " .. data)
        error({ message = "cookie_validation_failed" })
    end

    if self:is_sensitive_route() then
        self.px_logger.debug("cookie verification passed, risk api triggered by sensitive route")
        error({ message = "sensitive_route" })
    end

    return true
end

return TokenV1;
