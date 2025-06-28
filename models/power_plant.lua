local PowerPlant = {}
PowerPlant.__index = PowerPlant
local enums = require("models.enums")

function PowerPlant.new(id, cost, capacity, resourceType, resourceCost)
    local self = setmetatable({}, PowerPlant)
    self.id = id
    self.cost = cost
    self.capacity = capacity
    self.resourceType = resourceType
    self.resourceCost = resourceCost
    self.resources = 0
    return self
end

function PowerPlant:addResource(amount)
    self.resources = math.min(self.resources + amount, self.resourceCost * 2)
end

function PowerPlant:removeResource(amount)
    self.resources = math.max(0, self.resources - amount)
end

function PowerPlant:canPower()
    return self.resources >= self.resourceCost
end

function PowerPlant:getResourceStoredCount()
    return self.resources or 0
end

function PowerPlant:getResourceColor()
    local colors = {
        [enums.ResourceType.COAL] = {0.2, 0.2, 0.2, 1},
        [enums.ResourceType.OIL] = {0.8, 0.8, 0.2, 1},
        [enums.ResourceType.HYBRID] = {0.8, 0.4, 0.2, 1},
        [enums.ResourceType.GARBAGE] = {0.4, 0.4, 0.4, 1},
        [enums.ResourceType.URANIUM] = {0.2, 0.8, 0.2, 1},
        [enums.ResourceType.WIND] = {0.6, 0.8, 1.0, 1},
        [enums.ResourceType.SOLAR] = {1.0, 0.8, 0.2, 1}
    }
    return colors[self.resourceType] or {1, 1, 1, 1}
end

-- Checks if this plant can store the given resource type.
function PowerPlant:canStoreResource(resourceType)
    if self.resourceType == enums.ResourceType.HYBRID then
        -- Hybrid plants can store coal or oil. This needs specific enum values if HYBRID is a general type.
        -- For now, let's assume HYBRID means it can take COAL or OIL.
        -- This might need to be more robust if power_plants.json defines what a hybrid can take.
        return resourceType == enums.ResourceType.COAL or resourceType == enums.ResourceType.OIL
    end
    return self.resourceType == resourceType
end

-- Checks if the plant has capacity to store a certain amount of a resource type.
function PowerPlant:hasCapacityForResource(resourceType, amount)
    if not self:canStoreResource(resourceType) then
        return false
    end
    return (self.resources + amount) <= (self.resourceCost * 2)
end

-- Renamed from addResource(amount) to addSpecificResource(resourceType, amount)
-- and now checks type.
function PowerPlant:addSpecificResource(resourceType, amount)
    if not self:canStoreResource(resourceType) then
        print("Error: Plant #"..self.id.." cannot store resource type "..resourceType)
        return false
    end
    if not self:hasCapacityForResource(resourceType, amount) then
         print("Error: Plant #"..self.id.." does not have capacity for "..amount.." of "..resourceType)
        return false
    end
    self.resources = self.resources + amount
    print("Plant #"..self.id.." stored "..amount.." of "..resourceType..". Total stored: "..self.resources)
    return true
end

return PowerPlant 