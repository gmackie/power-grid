-- Window UI component for Power Grid Digital
-- A draggable window with title bar and optional close button

local class = require "lib.middleclass"

local Window = class('Window')

-- Create a new window
function Window.new(x, y, width, height, title, options)
    local window = Window()
    window:initialize(x, y, width, height, title, options)
    return window
end

-- Initialize the window
function Window:initialize(x, y, width, height, title, options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.2, 0.8}
    this.options.borderColor = this.options.borderColor or {0.3, 0.3, 0.3, 1}
    this.options.titleColor = this.options.titleColor or {1, 1, 1, 1}
    this.options.titleHeight = this.options.titleHeight or 30
    this.options.cornerRadius = this.options.cornerRadius or 5
    this.options.showCloseButton = this.options.showCloseButton or true
    this.options.closeButtonColor = this.options.closeButtonColor or {1, 1, 1, 1}
    this.options.closeButtonHoverColor = this.options.closeButtonHoverColor or {1, 0, 0, 1}
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Set position and size
    this.x = x or 0
    this.y = y or 0
    this.width = width or 400
    this.height = height or 300
    
    -- Window state
    this.visible = true
    this.alpha = 1
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.title = title or ""
    this.dragging = false
    this.dragOffsetX = 0
    this.dragOffsetY = 0
    this.closeButtonHovered = false
    
    -- Child components
    this.children = {}
    
    return this
end

-- Set window position
function Window:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set window size
function Window:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set window visibility
function Window:setVisible(visible)
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

-- Get window visibility
function Window:isVisible()
    return this.visible
end

-- Set window title
function Window:setTitle(title)
    this.title = title
end

-- Get window title
function Window:getTitle()
    return this.title
end

-- Add child component
function Window:addChild(child)
    table.insert(this.children, child)
end

-- Remove child component
function Window:removeChild(child)
    for i, c in ipairs(this.children) do
        if c == child then
            table.remove(this.children, i)
            break
        end
    end
end

-- Clear all child components
function Window:clearChildren()
    this.children = {}
end

-- Get child components
function Window:getChildren()
    return this.children
end

-- Set background color
function Window:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function Window:setBorderColor(color)
    this.options.borderColor = color
end

-- Set title color
function Window:setTitleColor(color)
    this.options.titleColor = color
end

-- Set title height
function Window:setTitleHeight(height)
    this.options.titleHeight = height
end

-- Set corner radius
function Window:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set close button visibility
function Window:setShowCloseButton(show)
    this.options.showCloseButton = show
end

-- Set close button color
function Window:setCloseButtonColor(color)
    this.options.closeButtonColor = color
end

-- Set close button hover color
function Window:setCloseButtonHoverColor(color)
    this.options.closeButtonHoverColor = color
end

-- Set fade in duration
function Window:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function Window:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update window
function Window:update(dt)
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

-- Draw the window
function Window:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw background
    love.graphics.setColor(this.options.backgroundColor[1], this.options.backgroundColor[2],
        this.options.backgroundColor[3], this.options.backgroundColor[4] * this.alpha)
    love.graphics.rectangle("fill", this.x, this.y, this.width, this.height,
        this.options.cornerRadius)
    
    -- Draw border
    love.graphics.setColor(this.options.borderColor[1], this.options.borderColor[2],
        this.options.borderColor[3], this.options.borderColor[4] * this.alpha)
    love.graphics.rectangle("line", this.x, this.y, this.width, this.height,
        this.options.cornerRadius)
    
    -- Draw title bar
    love.graphics.setColor(this.options.titleColor[1], this.options.titleColor[2],
        this.options.titleColor[3], this.options.titleColor[4] * this.alpha)
    love.graphics.rectangle("fill", this.x, this.y, this.width, this.options.titleHeight)
    
    -- Draw title text
    love.graphics.setColor(this.options.titleColor[1], this.options.titleColor[2],
        this.options.titleColor[3], this.options.titleColor[4] * this.alpha)
    love.graphics.printf(this.title, this.x + 10, this.y + (this.options.titleHeight - 20) / 2,
        this.width - 20, "left")
    
    -- Draw close button if enabled
    if this.options.showCloseButton then
        local closeButtonColor = this.closeButtonHovered and this.options.closeButtonHoverColor or this.options.closeButtonColor
        love.graphics.setColor(closeButtonColor[1], closeButtonColor[2],
            closeButtonColor[3], closeButtonColor[4] * this.alpha)
        love.graphics.rectangle("line", this.x + this.width - 30, this.y + 5, 20, 20)
        love.graphics.line(this.x + this.width - 25, this.y + 10,
            this.x + this.width - 15, this.y + 20)
        love.graphics.line(this.x + this.width - 15, this.y + 10,
            this.x + this.width - 25, this.y + 20)
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
function Window:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside window
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Check if click is in title bar
        if y <= this.y + this.options.titleHeight then
            -- Check if click is on close button
            if this.options.showCloseButton and
                x >= this.x + this.width - 30 and x <= this.x + this.width - 10 and
                y >= this.y + 5 and y <= this.y + 25 then
                this:setVisible(false)
                return true
            end
            -- Start dragging
            this.dragging = true
            this.dragOffsetX = x - this.x
            this.dragOffsetY = y - this.y
            return true
        end
        
        -- Forward to children
        for _, child in ipairs(this.children) do
            if child.mousepressed then
                if child:mousepressed(x, y, button) then
                    return true
                end
            end
        end
        return true
    end
    
    return false
end

-- Handle mouse move
function Window:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Handle dragging
    if this.dragging then
        this.x = x - this.dragOffsetX
        this.y = y - this.dragOffsetY
        return true
    end
    
    -- Check if mouse is inside window
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Check if mouse is over close button
        if this.options.showCloseButton and
            x >= this.x + this.width - 30 and x <= this.x + this.width - 10 and
            y >= this.y + 5 and y <= this.y + 25 then
            this.closeButtonHovered = true
        else
            this.closeButtonHovered = false
        end
        
        -- Forward to children
        for _, child in ipairs(this.children) do
            if child.mousemoved then
                if child:mousemoved(x, y, dx, dy) then
                    return true
                end
            end
        end
        return true
    end
    
    this.closeButtonHovered = false
    return false
end

-- Handle mouse release
function Window:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Stop dragging
    if this.dragging then
        this.dragging = false
        return true
    end
    
    -- Check if click is inside window
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Forward to children
        for _, child in ipairs(this.children) do
            if child.mousereleased then
                if child:mousereleased(x, y, button) then
                    return true
                end
            end
        end
        return true
    end
    
    return false
end

-- Handle key press
function Window:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Forward to children
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
function Window:textinput(text)
    if not this.visible then return false end
    
    -- Forward to children
    for _, child in ipairs(this.children) do
        if child.textinput then
            if child:textinput(text) then
                return true
            end
        end
    end
    
    return false
end

return Window 