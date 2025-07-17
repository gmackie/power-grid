# Visual Upgrade Guide

This guide helps you upgrade your Power Grid Digital client with the new visual system.

## What's New

### 1. **Theme System** (`ui/theme.lua`)
- Centralized color palette matching Power Grid's industrial aesthetic
- Consistent spacing, typography, and effects
- Dark theme optimized for extended play

### 2. **Styled Components**
- **StyledButton** (`ui/styled_button.lua`) - Animated buttons with asset support
- **StyledPanel** (`ui/styled_panel.lua`) - Beautiful panels with glow effects
- **Enhanced Menu** (`states/menu_enhanced.lua`) - Polished main menu with animations

### 3. **Visual Features**
- Smooth animations and transitions
- Particle effects and glows
- Gradient backgrounds
- Responsive scaling
- Asset integration

## Quick Integration Steps

### Step 1: Test the Enhanced Menu

To see the visual improvements immediately:

```lua
-- In main.lua, find where states are registered
states.menu = require("states.menu_enhanced")  -- Use enhanced version
```

### Step 2: Update Existing Buttons

Replace `MobileButton` usage with `StyledButton`:

```lua
-- Old way:
local MobileButton = require("ui.mobile_button")
self.playButton = MobileButton.new("Play", x, y, w, h)

-- New way:
local StyledButton = require("ui.styled_button")
self.playButton = StyledButton.new("Play", x, y, w, h, {
    type = "primary",  -- or "secondary"
    icon = "play",     -- optional icon
    onTap = function() ... end
})
```

### Step 3: Use Styled Panels

Replace basic panels with styled ones:

```lua
-- Create a styled panel
local StyledPanel = require("ui.styled_panel")

self.infoPanel = StyledPanel.new(x, y, width, height, {
    title = "Game Information",
    style = "elevated",  -- or "default", "transparent"
})

-- Add content to panel
self.infoPanel:addContent(someComponent)
```

### Step 4: Apply Theme Colors

Use the theme system for consistent colors:

```lua
local Theme = require("ui.theme")

-- Set colors using theme
Theme.setColor("primary")  -- Sets the primary blue
Theme.setColor("textSecondary", 0.8)  -- With alpha

-- Get specific colors
local playerColor = Theme.getPlayerColor(playerIndex)
local resourceColor = Theme.getResourceColor("coal")
```

## Full Example: Upgrading a Screen

Here's how to upgrade a basic screen:

```lua
-- Enhanced game state with visuals
local game = {}
local Theme = require("ui.theme")
local StyledButton = require("ui.styled_button")
local StyledPanel = require("ui.styled_panel")
local AssetLoader = require("assets.asset_loader")

function game:enter()
    -- Load assets
    AssetLoader.loadAll()
    
    -- Create UI with new components
    self.mainPanel = StyledPanel.new(50, 50, 400, 300, {
        title = "Game Board",
        style = "elevated"
    })
    
    self.endTurnButton = StyledButton.new("End Turn", 500, 400, 200, 50, {
        type = "primary",
        onTap = function() self:endTurn() end
    })
end

function game:update(dt)
    self.mainPanel:update(dt)
    self.endTurnButton:update(dt)
end

function game:draw()
    -- Use theme background
    love.graphics.clear(Theme.colors.backgroundDark)
    
    -- Draw components
    self.mainPanel:draw()
    self.endTurnButton:draw()
end
```

## Visual Effects

### Adding Animations

```lua
-- Fade in a panel
panel:show(true)  -- animated = true

-- Flash effect on important events
panel:flash(Theme.colors.success)

-- Button hover/press animations are automatic
```

### Using Resource Icons

```lua
-- Draw resource icons
local coalIcon = AssetLoader.getResource("coal")
if coalIcon then
    love.graphics.draw(coalIcon, x, y)
end
```

### Power Plant Cards

```lua
-- Draw a power plant card
local cardAsset = AssetLoader.getPowerPlantCard("coal")
if cardAsset then
    love.graphics.draw(cardAsset, x, y)
    -- Overlay plant details
    love.graphics.print("Cost: " .. plant.cost, x + 10, y + 10)
end
```

## Performance Tips

1. **Preload Assets**: Call `AssetLoader.loadAll()` once at startup
2. **Reuse Components**: Create UI components once, update them each frame
3. **Batch Draws**: The theme system helps batch similar draw calls

## Gradual Migration

You don't need to upgrade everything at once:

1. Start with the menu (most visible improvement)
2. Upgrade one screen at a time
3. Keep old components as fallbacks
4. Test thoroughly on mobile devices

## Mobile Considerations

The new components maintain mobile compatibility:
- Touch targets remain properly sized
- Animations are optimized for mobile performance
- Assets scale appropriately

## Next Steps

1. Run the enhanced menu to see the improvements
2. Pick one game screen to upgrade
3. Replace buttons and panels gradually
4. Add visual polish as you go

The visual system is designed to work alongside your existing code, so you can upgrade at your own pace while maintaining functionality.