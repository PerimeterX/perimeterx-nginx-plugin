local PXPayload = require "px.utils.pxpayload"

PXCookie = PXPayload:new{}

function PXCookie:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

return PXCookie