-- Component base class for Power Grid Digital UI elements
-- Provides core functionality for all UI components

local class = require "lib.middleclass"

local Component = class('Component')

-- Initialize the component
function Component:initialize(x, y, width, height)
    -- Position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
    
    -- State
    self.visible = true
    self.enabled = true
    self.children = {}
    self.parent = nil
    
    -- Transform
    self.scale = 1
    self.rotation = 0
    
    return self
end

-- Add a child component
function Component:addChild(child)
    if child then
        child.parent = self
        table.insert(self.children, child)
    end
end

-- Remove a child component
function Component:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            child.parent = nil
            table.remove(self.children, i)
            break
        end
    end
end

-- Clear all children
function Component:clearChildren()
    for _, child in ipairs(self.children) do
        child.parent = nil
    end
    self.children = {}
end

-- Get all child components
function Component:getChildren()
    return self.children
end

-- Set component position
function Component:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Get component position
function Component:getPosition()
    return self.x, self.y
end

-- Set component size
function Component:setSize(width, height)
    self.width = width
    self.height = height
end

-- Get component size
function Component:getSize()
    return self.width, self.height
end

-- Set component visibility
function Component:setVisible(visible)
    self.visible = visible
end

-- Get component visibility
function Component:isVisible()
    return self.visible
end

-- Set component enabled state
function Component:setEnabled(enabled)
    self.enabled = enabled
end

-- Get component enabled state
function Component:isEnabled()
    return self.enabled
end

-- Set component scale
function Component:setScale(scale)
    self.scale = scale
end

-- Get component scale
function Component:getScale()
    return self.scale
end

-- Set component rotation
function Component:setRotation(rotation)
    self.rotation = rotation
end

-- Get component rotation
function Component:getRotation()
    return self.rotation
end

-- Convert local coordinates to global coordinates
function Component:localToGlobal(x, y)
    local gx, gy = x, y
    local current = self
    
    while current do
        gx = gx + current.x
        gy = gy + current.y
        current = current.parent
    end
    
    return gx, gy
end

-- Convert global coordinates to local coordinates
function Component:globalToLocal(x, y)
    local lx, ly = x, y
    local current = self
    
    while current do
        lx = lx - current.x
        ly = ly - current.y
        current = current.parent
    end
    
    return lx, ly
end

-- Check if a point is inside the component
function Component:containsPoint(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

-- Update component
function Component:update(dt)
    if not self.visible or not self.enabled then
        return
    end
    
    -- Update children
    for _, child in ipairs(self.children) do
        child:update(dt)
    end
end

-- Draw component
function Component:draw()
    if not self.visible then
        return
    end
    
    -- Draw children
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

-- Handle mouse press
function Component:mousepressed(x, y, button)
    if not self.visible or not self.enabled then
        return false
    end
    
    -- Check children first (in reverse order for proper z-ordering)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child:mousepressed(x - self.x, y - self.y, button) then
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function Component:mousemoved(x, y, dx, dy)
    if not self.visible or not self.enabled then
        return false
    end
    
    -- Check children first (in reverse order for proper z-ordering)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child:mousemoved(x - self.x, y - self.y, dx, dy) then
            return true
        end
    end
    
    return false
end

-- Handle mouse release
function Component:mousereleased(x, y, button)
    if not self.visible or not self.enabled then
        return false
    end
    
    -- Check children first (in reverse order for proper z-ordering)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child:mousereleased(x - self.x, y - self.y, button) then
            return true
        end
    end
    
    return false
end

-- Handle key press
function Component:keypressed(key, scancode, isrepeat)
    if not self.visible or not self.enabled then
        return false
    end
    
    -- Check children first
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child:keypressed(key, scancode, isrepeat) then
            return true
        end
    end
    
    return false
end

-- Handle text input
function Component:textinput(text)
    if not self.visible or not self.enabled then
        return false
    end
    
    -- Check children first
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child:textinput(text) then
            return true
        end
    end
    
    return false
end

-- Handle window resize
function Component:resize(width, height)
    -- Update children
    for _, child in ipairs(self.children) do
        child:resize(width, height)
    end
end

return Component 