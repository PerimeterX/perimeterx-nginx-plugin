---------------------------------------------
-- PerimeterX(www.perimeterx.com) Nginx plugin
----------------------------------------------

local M = {}

local function generate_mask_tables()
    local bin_masks = {}
    local inverted_bin_masks = {}
    for i=0, 32 do
        table.insert(bin_masks, bit.lshift((2^i)-1, 32-i))
    end
    for i=1, 33 do
        table.insert(inverted_bin_masks, bit.bxor(bin_masks[i], bin_masks[33]))
    end
    return {bin_masks, inverted_bin_masks}
end

function M.load(px_config)
    -- local variables
    local bit = require("bit")

    local px_logger = require("px.utils.pxlogger").load(px_config)
    local px_common_utils = require("px.utils.pxcommonutils")
    local masks = generate_mask_tables()
    local _M = {}

    local function unsign(num)
        if num < 0 then
            num = 4294967296 + num
        end
        return num
    end

    local function split_ip_to_octets(ip)
        local octets = {}
        local index = 1
        local _, delimiterCount = string.gsub(ip, "%.", "")
        if (delimiterCount ~= 3) then
            px_logger.debug("IP is invalid.")
            return octets
        end

        for octet in string.gmatch(ip, "(%d+)%.?") do
            octets[index] = octet
            index = index + 1
        end

        return octets
    end

    local function ip_to_decimal(ip)
        local octets = split_ip_to_octets(ip)
        local result = 0

        if not octets or #octets ~= 4 then
            px_logger.debug("Octets count is invalid")
            return nil
        end

        for i,octet in ipairs(octets) do
            result = bit.bor(bit.lshift(octet, 8*(4-i)), result)
        end

        return unsign(result)
    end

    local function parse_cidr(mask_table)
        local result = {}
        local net = mask_table[1]
        local maskString = mask_table[2] or "32"
        local mask = tonumber(maskString)

        if mask < 0 or mask > 32 then
            px_logger.debug("Invalid mask: " .. mask)
            return result
        end

         -- cidr is valid
        local decimal_net = ip_to_decimal(net)
        if not decimal_net then
            px_logger.debug("Invalid ip: " .. net)
            return result
        end

        local decimal_mask = masks[1][mask+1]
        local inverted_decimal_mask = masks[2][mask+1]

        local lower = unsign(bit.band(decimal_net, decimal_mask))
        local upper = unsign(bit.bor(lower, inverted_decimal_mask))

        table.insert(result, lower)
        table.insert(result, upper)

        return result
    end


    function _M.prepare_cidrs(whitelisted_ips)
        local result = {}
        for _, v in pairs(whitelisted_ips) do
            local splitted_mask = px_common_utils.split_string(v, '[^/]+')
            if (splitted_mask ~= nil) then
                local cidr_object = parse_cidr(splitted_mask)
                table.insert(result, cidr_object)
            end
        end
        return result
    end

    function _M.is_ip_whitelisted(whitelisted_ips, ip)
        if type(ip) ~= "string" then
            px_logger.debug("IP must be of type string")
            return nil
        end
        local ip_sum = ip_to_decimal(ip)
        if ip_sum ~= nil then
            for _, cidr in ipairs(whitelisted_ips) do
                if ip_sum >= cidr[1] and ip_sum <= cidr[2] then
                    return true
                end
            end
        end
        return false
    end

    return _M
end
return M