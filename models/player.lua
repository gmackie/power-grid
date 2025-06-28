local Player = {}
Player.__index = Player
local enums = require("models.enums")

function Player.new(name, money)
    local self = {}
    
    -- Basic properties
    self.name = name
    self.money = money or 50
    self.color = {math.random(), math.random(), math.random(), 1}
    
    -- Resources
    self.resources = {
        [enums.ResourceType.COAL] = 0,
        [enums.ResourceType.OIL] = 0,
        [enums.ResourceType.HYBRID] = 0,
        [enums.ResourceType.GARBAGE] = 0,
        [enums.ResourceType.URANIUM] = 0,
        [enums.ResourceType.WIND] = 0,
        [enums.ResourceType.SOLAR] = 0
    }
    
    -- Power plants and cities
    self.powerPlants = {}
    self.cities = {}
    
    return setmetatable(self, {__index = Player})
end

function Player:addMoney(amount)
    self.money = self.money + amount
end

function Player:removeMoney(amount)
    if self.money >= amount then
        self.money = self.money - amount
        return true
    end
    return false
end

function Player:getResourceCount(resourceType)
    return self.resources[resourceType] or 0
end

function Player:addResource(resourceType, amount)
    self.resources[resourceType] = (self.resources[resourceType] or 0) + amount
end

function Player:removeResource(resourceType, amount)
    self.resources[resourceType] = math.max(0, (self.resources[resourceType] or 0) - amount)
end

function Player:getResourceColor(resourceType)
    local colors = {
        [enums.ResourceType.COAL] = {0.2, 0.2, 0.2, 1},
        [enums.ResourceType.OIL] = {0.8, 0.8, 0.2, 1},
        [enums.ResourceType.HYBRID] = {0.8, 0.4, 0.2, 1},
        [enums.ResourceType.GARBAGE] = {0.4, 0.4, 0.4, 1},
        [enums.ResourceType.URANIUM] = {0.2, 0.8, 0.2, 1},
        [enums.ResourceType.WIND] = {0.6, 0.8, 1.0, 1},
        [enums.ResourceType.SOLAR] = {1.0, 0.8, 0.2, 1}
    }
    return colors[resourceType] or {1, 1, 1, 1}
end

function Player:addPowerPlant(plant)
    table.insert(self.powerPlants, plant)
    print("Player " .. self.name .. ": Added power plant #" .. plant.id .. ". Total plants: " .. #self.powerPlants)
    for i, p in ipairs(self.powerPlants) do
        print("  - Plant in list: #" .. p.id)
    end
end

function Player:removePowerPlant(plant)
    for i, p in ipairs(self.powerPlants) do
        if p.id == plant.id then
            table.remove(self.powerPlants, i)
            break
        end
    end
end

function Player:addCity(city)
    table.insert(self.cities, city)
end

function Player:removeCity(city)
    for i, c in ipairs(self.cities) do
        if c.id == city.id then
            table.remove(self.cities, i)
            break
        end
    end
end

function Player:getCityCount()
    return #self.cities
end

function Player:getPowerPlantCount()
    return #self.powerPlants
end

function Player:getTotalCapacity()
    local total = 0
    for _, plant in ipairs(self.powerPlants) do
        total = total + plant.capacity
    end
    return total
end

return Player 