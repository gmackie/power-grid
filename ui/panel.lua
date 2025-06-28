-- Panel UI component for Power Grid Digital
-- A container for other UI components with optional background and border

local class = require "lib.middleclass"
local Label = require "src.ui.label"

local Panel = class('Panel')

-- Create a new panel
function Panel.new(options)
    local panel = Panel()
    panel:initialize(options)
    return panel
end

-- Initialize the panel
function Panel:initialize(options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0, 0, 0, 0}
    self.options.borderColor = self.options.borderColor or {0, 0, 0, 0}
    self.options.padding = self.options.padding or 0
    self.options.cornerRadius = self.options.cornerRadius or 0
    self.options.fadeInDuration = 0 -- DEBUG: instant visibility
    self.options.fadeOutDuration = self.options.fadeOutDuration or 0.2
    self.options.titleColor = self.options.titleColor or {1, 1, 1, 1}
    self.options.titleHeight = self.options.titleHeight or 30
    self.options.titleFontSize = self.options.titleFontSize or 18
    self.options.titleFont = self.options.titleFont or love.graphics.newFont(self.options.titleFontSize)
    self.options.title = self.options.title or ""
    self.options.titleAlignment = self.options.titleAlignment or "left"
    
    -- Panel state
    self.visible = false
    self.alpha = 0
    self.fadeInTimer = 0
    self.fadeOutTimer = 0
    self.x = self.options.x or 0
    self.y = self.options.y or 0
    self.width = self.options.width or 0
    self.height = self.options.height or 0
    self.children = {}
    
    return self
end

-- Add a child component
function Panel:addChild(child)
    table.insert(self.children, child)
end

-- Remove a child component
function Panel:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            break
        end
    end
end

-- Clear all child components
function Panel:clearChildren()
    self.children = {}
end

-- Get all child components
function Panel:getChildren()
    return self.children
end

-- Set panel position
function Panel:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Set panel size
function Panel:setSize(width, height)
    self.width = width
    self.height = height
    
    -- Update title size if it exists
    if self.title then
        self.title:setSize(width - 20, self.options.titleHeight)
    end
end

-- Set panel title
function Panel:setTitle(title)
    self.options.title = title
    if self.title then
        self.title:setText(title)
    end
end

-- Set panel visibility
function Panel:setVisible(visible)
    if visible ~= self.visible then
        self.visible = visible
        if visible then
            self.fadeInTimer = self.options.fadeInDuration
            self.fadeOutTimer = 0
        else
            self.fadeInTimer = 0
            self.fadeOutTimer = self.options.fadeOutDuration
        end
    end
end

-- Get panel visibility
function Panel:isVisible()
    return self.visible
end

-- Set background color
function Panel:setBackgroundColor(color)
    self.options.backgroundColor = color
end

-- Set border color
function Panel:setBorderColor(color)
    self.options.borderColor = color
end

-- Set padding
function Panel:setPadding(padding)
    self.options.padding = padding
end

-- Set corner radius
function Panel:setCornerRadius(radius)
    self.options.cornerRadius = radius
end

-- Set fade in duration
function Panel:setFadeInDuration(duration)
    self.options.fadeInDuration = duration
end

-- Set fade out duration
function Panel:setFadeOutDuration(duration)
    self.options.fadeOutDuration = duration
end

-- Update panel
function Panel:update(dt)
    if not self.visible then
        if self.fadeOutTimer > 0 then
            self.fadeOutTimer = math.max(0, self.fadeOutTimer - dt)
            self.alpha = self.fadeOutTimer / self.options.fadeOutDuration
        end
        return
    end
    
    if self.fadeInTimer > 0 then
        self.fadeInTimer = math.max(0, self.fadeInTimer - dt)
        self.alpha = 1 - (self.fadeInTimer / self.options.fadeInDuration)
    end
    
    -- Update children
    for _, child in ipairs(self.children) do
        if child.update then
            child:update(dt)
        end
    end
end

-- Draw the panel
function Panel:draw()
    print('[Panel] draw called for panel at', self.x, self.y, 'visible:', self.visible, 'alpha:', self.alpha)
    if not self.visible and self.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    
    -- Save current graphics state
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    
    -- Draw background
    if self.options.backgroundColor[4] > 0 then
        love.graphics.setColor(self.options.backgroundColor[1], self.options.backgroundColor[2],
            self.options.backgroundColor[3], self.options.backgroundColor[4] * self.alpha)
        love.graphics.rectangle("fill", 0, 0, self.width, self.height,
            self.options.cornerRadius)
    end
    
    -- Draw border
    if self.options.borderColor[4] > 0 then
        love.graphics.setColor(self.options.borderColor[1], self.options.borderColor[2],
            self.options.borderColor[3], self.options.borderColor[4] * self.alpha)
        love.graphics.rectangle("line", 0, 0, self.width, self.height,
            self.options.cornerRadius)
    end
    
    -- Draw title if it exists
    if self.title then
        self.title:draw()
    end
    
    -- Draw children
    for _, child in ipairs(self.children) do
        if child.draw then
            child:draw()
        end
    end
    
    -- Restore graphics state
    love.graphics.pop()
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Panel:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside panel
    if x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height then
        -- Transform coordinates to local space
        local localX = x - self.x
        local localY = y - self.y
        
        -- Forward to children in reverse order (top-most first)
        for i = #self.children, 1, -1 do
            local child = self.children[i]
            if child.mousepressed and child:mousepressed(localX, localY, button) then
                return true
            end
        end
        return true
    end
    
    return false
end

-- Handle mouse move
function Panel:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Check if mouse is inside panel
    if x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height then
        -- Transform coordinates to local space
        local localX = x - self.x
        local localY = y - self.y
        
        -- Forward to children in reverse order (top-most first)
        for i = #self.children, 1, -1 do
            local child = self.children[i]
            if child.mousemoved and child:mousemoved(localX, localY, dx, dy) then
                return true
            end
        end
        return true
    end
    
    return false
end

-- Handle mouse release
function Panel:mousereleased(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside panel
    if x >= self.x and x <= self.x + self.width and
        y >= self.y and y <= self.y + self.height then
        -- Transform coordinates to local space
        local localX = x - self.x
        local localY = y - self.y
        
        -- Forward to children in reverse order (top-most first)
        for i = #self.children, 1, -1 do
            local child = self.children[i]
            if child.mousereleased and child:mousereleased(localX, localY, button) then
                return true
            end
        end
        return true
    end
    
    return false
end

-- Handle key press
function Panel:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    
    -- Forward to children in reverse order (top-most first)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child.keypressed then
            if child:keypressed(key, scancode, isrepeat) then
                return true
            end
        end
    end
    
    return false
end

-- Handle text input
function Panel:textinput(text)
    if not self.visible then return false end
    
    -- Forward to children in reverse order (top-most first)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child.textinput then
            if child:textinput(text) then
                return true
            end
        end
    end
    
    return false
end

-- Handle window resize
function Panel:resize(width, height)
    -- Update panel position if it's the main panel
    if self.x == 0 and self.y == 0 then
        self:setPosition(width / 2 - self.width / 2, height / 2 - self.height / 2)
    end
end

return Panel 