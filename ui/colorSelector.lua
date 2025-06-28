-- Color Selector UI Component for Power Grid Digital
-- Allows players to select their color

local class = require "lib.middleclass"
local Component = require "src.ui.component"

local ColorSelector = class("ColorSelector", Component)

-- Standard player colors
local COLORS = {
    {1, 0, 0, 1},       -- Red
    {0, 0, 1, 1},       -- Blue
    {0, 0.8, 0, 1},     -- Green
    {1, 1, 0, 1},       -- Yellow
    {0.5, 0, 0.5, 1},   -- Purple
    {1, 0.5, 0, 1},     -- Orange
}

-- HTML hex codes for the colors (for export)
local COLOR_CODES = {
    "#FF0000",  -- Red
    "#0000FF",  -- Blue
    "#00CC00",  -- Green
    "#FFFF00",  -- Yellow
    "#800080",  -- Purple
    "#FF8000",  -- Orange
}

-- Initialize the color selector
function ColorSelector:initialize(x, y, width, height, options)
    Component.initialize(self, x, y, width, height)
    
    options = options or {}
    self.backgroundColor = options.backgroundColor or {0.1, 0.1, 0.2, 0.8}
    self.borderColor = options.borderColor or {0.2, 0.2, 0.3, 1}
    self.padding = options.padding or 10
    self.cornerRadius = options.cornerRadius or 5
    self.gridSize = options.gridSize or 3
    self.colorSize = options.colorSize or 40
    self.spacing = options.spacing or 20
    self.selectedColor = nil
    self.selectedIndex = nil
    self.onColorSelected = nil
    
    -- Default colors if not provided
    self.colors = options.colors or COLORS
    
    -- Calculate grid layout
    self:calculateLayout()
end

function ColorSelector:calculateLayout()
    -- Calculate how many colors can fit per row based on width
    local availableWidth = self.width - (2 * self.padding)
    local colorsPerRow = math.floor((availableWidth + self.spacing) / (self.colorSize + self.spacing))
    colorsPerRow = math.max(1, math.min(colorsPerRow, #self.colors))
    
    -- Adjust spacing to distribute colors evenly
    local totalColorWidth = colorsPerRow * self.colorSize
    local remainingSpace = availableWidth - totalColorWidth
    self.effectiveSpacing = remainingSpace / math.max(1, colorsPerRow - 1)
    
    -- Calculate rows needed
    self.rows = math.ceil(#self.colors / colorsPerRow)
    self.colorsPerRow = colorsPerRow
    
    -- Store color positions
    self.colorPositions = {}
    for i, color in ipairs(self.colors) do
        local row = math.floor((i-1) / colorsPerRow)
        local col = (i-1) % colorsPerRow
        
        self.colorPositions[i] = {
            x = self.padding + col * (self.colorSize + self.effectiveSpacing),
            y = self.padding + row * (self.colorSize + self.spacing),
            color = color
        }
    end
end

-- Set color selector position
function ColorSelector:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Set color selector size
function ColorSelector:setSize(width, height)
    self.width = width
    self.height = height
end

-- Set color selector visibility
function ColorSelector:setVisible(visible)
    self.visible = visible
end

-- Get color selector visibility
function ColorSelector:isVisible()
    return self.visible
end

-- Get selected color
function ColorSelector:getSelectedColor()
    if self.selectedIndex then
        return self.colors[self.selectedIndex]
    end
    return nil
end

-- Set color selection handler
function ColorSelector:setOnColorSelected(handler)
    self.onColorSelected = handler
end

-- Get color at position
function ColorSelector:getColorAt(x, y)
    if not self.visible then return nil end
    
    -- Calculate grid position
    local gridX = math.floor((x - self.x - self.padding) / (self.colorSize + self.spacing))
    local gridY = math.floor((y - self.y - self.padding) / (self.colorSize + self.spacing))
    
    -- Check if position is within grid
    if gridX >= 0 and gridX < self.colorsPerRow and
       gridY >= 0 and gridY < self.rows then
        local index = gridY * self.colorsPerRow + gridX + 1
        if index <= #self.colors then
            return self.colors[index]
        end
    end
    
    return nil
end

-- Draw the color selector
function ColorSelector:draw()
    if not self.visible then return end
    
    -- Save current color
    local r, g, b, a = love.graphics.getColor()
    
    -- Draw background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, self.cornerRadius)
    
    -- Draw border
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, self.cornerRadius)
    
    -- Draw color squares
    for i, pos in ipairs(self.colorPositions) do
        local x = self.x + pos.x
        local y = self.y + pos.y
        
        -- Draw selection indicator
        if i == self.selectedIndex then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", 
                x - 2, y - 2, 
                self.colorSize + 4, self.colorSize + 4,
                3
            )
        end
        
        -- Draw color square
        love.graphics.setColor(pos.color)
        love.graphics.rectangle("fill", 
            x, y, 
            self.colorSize, self.colorSize,
            3
        )
        
        -- Draw border
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("line", 
            x, y, 
            self.colorSize, self.colorSize,
            3
        )
    end
    
    -- Restore original color
    love.graphics.setColor(r, g, b, a)
end

-- Handle mouse press
function ColorSelector:mousepressed(x, y, button)
    if not self.visible or not self.enabled or button ~= 1 then return false end
    
    -- Convert global coordinates to local
    local lx, ly = self:globalToLocal(x, y)
    
    -- Check each color square
    for i, pos in ipairs(self.colorPositions) do
        if lx >= pos.x and lx <= pos.x + self.colorSize and
           ly >= pos.y and ly <= pos.y + self.colorSize then
            self.selectedIndex = i
            if self.onColorSelected then
                self.onColorSelected(self.colors[i])
            end
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function ColorSelector:mousemoved(x, y, dx, dy)
    if not self.visible or not self.enabled then return false end
    return self:containsPoint(x, y)
end

-- Handle mouse release
function ColorSelector:mousereleased(x, y, button)
    if not self.visible or not self.enabled then return false end
    return false
end

-- Handle key press
function ColorSelector:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    return false
end

-- Handle text input
function ColorSelector:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function ColorSelector:resize(width, height)
    Component.resize(self, width, height)
    self:calculateLayout()
end

-- Get the currently selected color as RGB values
function ColorSelector:getSelectedColorRGB()
    return COLORS[self.selectedColor]
end

-- Get the currently selected color as a hex code
function ColorSelector:getSelectedColorHex()
    return COLOR_CODES[self.selectedColor]
end

-- Set the selected color by index
function ColorSelector:setSelectedColor(index)
    if type(index) == "number" and index >= 1 and index <= #self.colors then
        self.selectedIndex = index
    elseif type(index) == "table" then
        -- If a color table is provided, find matching color
        for i, color in ipairs(self.colors) do
            if color[1] == index[1] and 
               color[2] == index[2] and 
               color[3] == index[3] and 
               color[4] == index[4] then
                self.selectedIndex = i
                break
            end
        end
    end
end

-- Reset selection
function ColorSelector:reset()
    self.selectedIndex = nil
end

return ColorSelector 