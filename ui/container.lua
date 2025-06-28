-- Container UI component for Power Grid Digital
-- A container that can hold other UI components

local class = require "lib.middleclass"

local Container = class('Container')

-- Create a new container
function Container.new(options)
    local container = Container()
    container:initialize(options)
    return container
end

-- Initialize the container
function Container:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.padding = this.options.padding or 0
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Container state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.children = {}
    
    return this
end

-- Set container position
function Container:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set container size
function Container:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set container visibility
function Container:setVisible(visible)
    if visible ~= this.visible then
        this.visible = visible
        if visible then
            this.fadeInTimer = this.options.fadeInDuration
            this.fadeOutTimer = 0
        else
            this.fadeInTimer = 0
            this.fadeOutTimer = this.options.fadeOutDuration
        end
    end
end

-- Get container visibility
function Container:isVisible()
    return this.visible
end

-- Add a child component
function Container:addChild(child)
    table.insert(this.children, child)
end

-- Remove a child component
function Container:removeChild(child)
    for i, c in ipairs(this.children) do
        if c == child then
            table.remove(this.children, i)
            break
        end
    end
end

-- Clear all child components
function Container:clearChildren()
    this.children = {}
end

-- Get all child components
function Container:getChildren()
    return this.children
end

-- Set background color
function Container:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function Container:setBorderColor(color)
    this.options.borderColor = color
end

-- Set padding
function Container:setPadding(padding)
    this.options.padding = padding
end

-- Set corner radius
function Container:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function Container:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function Container:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update container
function Container:update(dt)
    if not this.visible then
        if this.fadeOutTimer > 0 then
            this.fadeOutTimer = math.max(0, this.fadeOutTimer - dt)
            this.alpha = this.fadeOutTimer / this.options.fadeOutDuration
        end
        return
    end
    
    if this.fadeInTimer > 0 then
        this.fadeInTimer = math.max(0, this.fadeInTimer - dt)
        this.alpha = 1 - (this.fadeInTimer / this.options.fadeInDuration)
    end
    
    -- Update children
    for _, child in ipairs(this.children) do
        if child.update then
            child:update(dt)
        end
    end
end

-- Draw the container
function Container:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw background
    if this.options.backgroundColor[4] > 0 then
        love.graphics.setColor(this.options.backgroundColor[1], this.options.backgroundColor[2],
            this.options.backgroundColor[3], this.options.backgroundColor[4] * this.alpha)
        love.graphics.rectangle("fill", this.x, this.y, this.width, this.height,
            this.options.cornerRadius)
    end
    
    -- Draw border
    if this.options.borderColor[4] > 0 then
        love.graphics.setColor(this.options.borderColor[1], this.options.borderColor[2],
            this.options.borderColor[3], this.options.borderColor[4] * this.alpha)
        love.graphics.rectangle("line", this.x, this.y, this.width, this.height,
            this.options.cornerRadius)
    end
    
    -- Draw children
    for _, child in ipairs(this.children) do
        if child.draw then
            child:draw()
        end
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Container:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside container
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Forward event to children
        for _, child in ipairs(this.children) do
            if child.mousepressed then
                if child:mousepressed(x, y, button) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle mouse move
function Container:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside container
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Forward event to children
        for _, child in ipairs(this.children) do
            if child.mousemoved then
                if child:mousemoved(x, y, dx, dy) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle mouse release
function Container:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside container
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Forward event to children
        for _, child in ipairs(this.children) do
            if child.mousereleased then
                if child:mousereleased(x, y, button) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle key press
function Container:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Forward event to children
    for _, child in ipairs(this.children) do
        if child.keypressed then
            if child:keypressed(key, scancode, isrepeat) then
                return true
            end
        end
    end
    
    return false
end

-- Handle text input
function Container:textinput(text)
    if not this.visible then return false end
    
    -- Forward event to children
    for _, child in ipairs(this.children) do
        if child.textinput then
            if child:textinput(text) then
                return true
            end
        end
    end
    
    return false
end

return Container 