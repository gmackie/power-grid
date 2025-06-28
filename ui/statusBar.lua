-- StatusBar UI component for Power Grid Digital
-- A status bar that displays information at the bottom of the window

local class = require "lib.middleclass"

local StatusBar = class('StatusBar')

-- Create a new status bar
function StatusBar.new(options)
    local statusBar = StatusBar()
    statusBar:initialize(options)
    return statusBar
end

-- Initialize the status bar
function StatusBar:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.2, 0.8}
    this.options.borderColor = this.options.borderColor or {0.3, 0.3, 0.3, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.padding = this.options.padding or 5
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Status bar state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    
    -- Status items
    this.items = {}
    
    return this
end

-- Set status bar position
function StatusBar:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set status bar size
function StatusBar:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set status bar visibility
function StatusBar:setVisible(visible)
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

-- Get status bar visibility
function StatusBar:isVisible()
    return this.visible
end

-- Add a status item
function StatusBar:addItem(text, alignment)
    table.insert(this.items, {
        text = text,
        alignment = alignment or "left"
    })
end

-- Remove a status item
function StatusBar:removeItem(index)
    if index >= 1 and index <= #this.items then
        table.remove(this.items, index)
    end
end

-- Clear all status items
function StatusBar:clearItems()
    this.items = {}
end

-- Get all status items
function StatusBar:getItems()
    return this.items
end

-- Set background color
function StatusBar:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function StatusBar:setBorderColor(color)
    this.options.borderColor = color
end

-- Set text color
function StatusBar:setTextColor(color)
    this.options.textColor = color
end

-- Set font size
function StatusBar:setFontSize(size)
    this.options.fontSize = size
end

-- Set padding
function StatusBar:setPadding(padding)
    this.options.padding = padding
end

-- Set fade in duration
function StatusBar:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function StatusBar:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update status bar
function StatusBar:update(dt)
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
end

-- Draw the status bar
function StatusBar:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw background
    love.graphics.setColor(this.options.backgroundColor[1], this.options.backgroundColor[2],
        this.options.backgroundColor[3], this.options.backgroundColor[4] * this.alpha)
    love.graphics.rectangle("fill", this.x, this.y, this.width, this.height)
    
    -- Draw border
    love.graphics.setColor(this.options.borderColor[1], this.options.borderColor[2],
        this.options.borderColor[3], this.options.borderColor[4] * this.alpha)
    love.graphics.rectangle("line", this.x, this.y, this.width, this.height)
    
    -- Draw status items
    local font = love.graphics.getFont()
    local itemX = this.x + this.options.padding
    local itemY = this.y + (this.height - font:getHeight()) / 2
    
    for _, item in ipairs(this.items) do
        -- Calculate item width
        local textWidth = font:getWidth(item.text)
        local itemWidth = textWidth + (2 * this.options.padding)
        
        -- Draw item text
        love.graphics.setColor(this.options.textColor[1], this.options.textColor[2],
            this.options.textColor[3], this.options.textColor[4] * this.alpha)
        
        if item.alignment == "left" then
            love.graphics.printf(item.text, itemX, itemY, itemWidth, "left")
        elseif item.alignment == "center" then
            love.graphics.printf(item.text, itemX, itemY, itemWidth, "center")
        else -- right
            love.graphics.printf(item.text, itemX, itemY, itemWidth, "right")
        end
        
        itemX = itemX + itemWidth
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function StatusBar:mousepressed(x, y, button)
    if not this.visible then return false end
    return false
end

-- Handle mouse move
function StatusBar:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    return false
end

-- Handle mouse release
function StatusBar:mousereleased(x, y, button)
    if not this.visible then return false end
    return false
end

-- Handle key press
function StatusBar:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    return false
end

-- Handle text input
function StatusBar:textinput(text)
    if not this.visible then return false end
    return false
end

return StatusBar 