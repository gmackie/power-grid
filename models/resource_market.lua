local ResourceMarket = {}
ResourceMarket.__index = ResourceMarket

function ResourceMarket.new()
    local self = setmetatable({}, ResourceMarket)
    self.resources = {
        coal = {available = 24, price = 1},
        oil = {available = 18, price = 1},
        garbage = {available = 6, price = 1},
        uranium = {available = 2, price = 1}
    }
    return self
end

function ResourceMarket:getPrice(type)
    local resource = self.resources[type:lower()]
    if not resource then return nil end
    
    -- Price increases as resources become scarce
    local total = self:getTotal(type)
    if total <= 3 then return 8
    elseif total <= 6 then return 7
    elseif total <= 9 then return 6
    elseif total <= 12 then return 5
    elseif total <= 15 then return 4
    elseif total <= 18 then return 3
    elseif total <= 21 then return 2
    else return 1 end
end

function ResourceMarket:getTotal(type)
    local resource = self.resources[type:lower()]
    return resource and resource.available or 0
end

function ResourceMarket:buy(type, amount)
    local resource = self.resources[type:lower()]
    if not resource then return false end
    
    if resource.available >= amount then
        resource.available = resource.available - amount
        return true
    end
    return false
end

function ResourceMarket:refill()
    -- Reset market based on player count
    -- This would be called during the bureaucracy phase
    for type, resource in pairs(self.resources) do
        resource.available = resource.available + 3
    end
end

return ResourceMarket 