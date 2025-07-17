# Asset Integration Examples

This document shows how to integrate the placeholder assets into your existing UI components.

## Quick Test

To verify assets are working, add this to any state file (like `states/menu.lua`):

```lua
-- At the top of the file
local AssetLoader = require("assets.asset_loader")

-- In the love.load() or equivalent initialization function
function love.load()
    -- Test loading a few key assets
    local available, total = AssetLoader.checkAssets()
    print(string.format("Assets available: %d/%d", available, total))
    
    -- Load some test assets
    local button = AssetLoader.getButton("medium", "primary", "normal")
    local coalPlant = AssetLoader.getPowerPlantCard("coal")
    local oilResource = AssetLoader.getResource("oil")
    
    if button then print("✓ Button asset loaded") end
    if coalPlant then print("✓ Power plant asset loaded") end
    if oilResource then print("✓ Resource asset loaded") end
end
```

## Updating Button Component

Here's how to modify your existing button component to use assets:

```lua
-- In ui/button.lua, add near the top:
local AssetLoader = require("assets.asset_loader")

-- Modify the Button.new function to load assets:
function Button.new(text, x, y, w, h, size, type)
    local self = setmetatable({}, Button)
    self.text = text
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    
    -- Determine size category based on width
    size = size or (w > 250 and "large" or (w > 180 and "medium" or "small"))
    type = type or "primary"
    
    -- Load button assets
    self.assets = {
        normal = AssetLoader.getButton(size, type, "normal"),
        hover = AssetLoader.getButton(size, type, "hover"),
        pressed = AssetLoader.getButton(size, type, "pressed"),
        disabled = AssetLoader.getButton(size, type, "disabled")
    }
    
    -- Rest of existing initialization...
    return self
end

-- Modify the draw function to use assets:
function Button:draw()
    if not self.visible then return end
    
    local asset
    if not self.enabled then
        asset = self.assets.disabled
    elseif self.down then
        asset = self.assets.pressed
    elseif self.hovered then
        asset = self.assets.hover
    else
        asset = self.assets.normal
    end
    
    if asset then
        -- Draw the asset image
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(asset, self.x, self.y, 0, 
                          self.w / asset:getWidth(), 
                          self.h / asset:getHeight())
    else
        -- Fallback to existing drawing code
        -- ... existing rectangle drawing code ...
    end
    
    -- Draw text on top
    if self.text and self.text ~= "" then
        love.graphics.setColor(self.textColor)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(self.text)
        local textHeight = font:getHeight()
        love.graphics.print(self.text, 
            self.x + (self.w - textWidth) / 2,
            self.y + (self.h - textHeight) / 2)
    end
end
```

## Adding Resource Icons to Market Display

For resource market displays:

```lua
-- In your market/resource display code:
local AssetLoader = require("assets.asset_loader")

function drawResourceMarket()
    local resources = {"coal", "oil", "garbage", "uranium"}
    local x, y = 100, 100
    
    for i, resourceType in ipairs(resources) do
        local icon = AssetLoader.getResource(resourceType)
        if icon then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(icon, x + (i-1) * 50, y)
            
            -- Draw resource count
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.print(tostring(resourceCount[resourceType] or 0), 
                               x + (i-1) * 50 + 10, y + 35)
        end
    end
end
```

## Power Plant Cards

For power plant displays:

```lua
-- In your power plant display code:
local AssetLoader = require("assets.asset_loader")

function drawPowerPlant(plant, x, y)
    local cardAsset = AssetLoader.getPowerPlantCard(plant.resourceType:lower())
    
    if cardAsset then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(cardAsset, x, y)
        
        -- Draw plant details on top of the card
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("Cost: " .. plant.cost, x + 10, y + 10)
        love.graphics.print("Capacity: " .. plant.capacity, x + 100, y + 10)
        love.graphics.print("Resource: " .. plant.resourceCost, x + 10, y + 90)
    end
end
```

## City Markers on Map

For map city displays:

```lua
-- In your map rendering code:
local AssetLoader = require("assets.asset_loader")

function drawCity(city, x, y)
    local cityAsset = AssetLoader.getCity(city.region:lower())
    
    if cityAsset then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(cityAsset, x - 15, y - 15)  -- Center the 30x30 marker
        
        -- Draw city name
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(city.name, x - 20, y + 20)
    end
end
```

## Testing Integration

1. **Run the normal client**: `love .`
2. **Check console output** for asset loading messages
3. **Navigate to different screens** to see assets in use
4. **Look for any fallbacks** to the old rectangle drawing

## Performance Notes

- Assets are cached after first load
- Use `AssetLoader.loadAll()` in initialization if you want to preload everything
- The fallback drawing code ensures the game works even if assets fail to load

## Next Steps

1. Update your existing UI components one by one
2. Test thoroughly on both desktop and mobile
3. Create @1.5x and @2x versions for high-DPI displays
4. Replace with professional artwork when available