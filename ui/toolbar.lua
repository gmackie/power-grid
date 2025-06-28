-- Toolbar UI component for Power Grid Digital
-- A toolbar that can contain buttons and other controls

local class = require "lib.middleclass"

local Toolbar = class('Toolbar')

-- Create a new toolbar
function Toolbar.new(options)
    local toolbar = Toolbar()
    toolbar:initialize(options)
    return toolbar
end

-- Initialize the toolbar
function Toolbar:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.hoverColor = this.options.hoverColor or {0.7, 0.7, 0.7, 0.7}
    this.options.pressColor = this.options.pressColor or {0.9, 0.9, 0.9, 0.9}
    this.options.fontSize = this.options.fontSize or 14
    this.options.font = this.options.font or love.graphics.newFont(this.options.fontSize)
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    this.options.itemSize = this.options.itemSize or 20
    this.options.itemSpacing = this.options.itemSpacing or 5
    this.options.items = this.options.items or {}
    
    -- Toolbar state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.items = this.options.items
    this.hoveredIndex = -1
    this.pressedIndex = -1
    this.onSelect = this.options.onSelect
    
    return this
end

-- Set toolbar position
function Toolbar:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set toolbar size
function Toolbar:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set toolbar visibility
function Toolbar:setVisible(visible)
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

-- Get toolbar visibility
function Toolbar:isVisible()
    return this.visible
end

-- Set background color
function Toolbar:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function Toolbar:setBorderColor(color)
    this.options.borderColor = color
end

-- Set text color
function Toolbar:setTextColor(color)
    this.options.textColor = color
end

-- Set hover color
function Toolbar:setHoverColor(color)
    this.options.hoverColor = color
end

-- Set press color
function Toolbar:setPressColor(color)
    this.options.pressColor = color
end

-- Set font size
function Toolbar:setFontSize(size)
    this.options.fontSize = size
    this.options.font = love.graphics.newFont(size)
end

-- Set padding
function Toolbar:setPadding(padding)
    this.options.padding = padding
end

-- Set corner radius
function Toolbar:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function Toolbar:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function Toolbar:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Set item size
function Toolbar:setItemSize(size)
    this.options.itemSize = size
end

-- Get item size
function Toolbar:getItemSize()
    return this.options.itemSize
end

-- Set item spacing
function Toolbar:setItemSpacing(spacing)
    this.options.itemSpacing = spacing
end

-- Get item spacing
function Toolbar:getItemSpacing()
    return this.options.itemSpacing
end

-- Set items
function Toolbar:setItems(items)
    this.items = items
end

-- Get items
function Toolbar:getItems()
    return this.items
end

-- Add item
function Toolbar:addItem(item)
    table.insert(this.items, item)
end

-- Remove item
function Toolbar:removeItem(index)
    table.remove(this.items, index)
end

-- Clear items
function Toolbar:clearItems()
    this.items = {}
end

-- Set hovered index
function Toolbar:setHoveredIndex(index)
    this.hoveredIndex = index
end

-- Get hovered index
function Toolbar:getHoveredIndex()
    return this.hoveredIndex
end

-- Set pressed index
function Toolbar:setPressedIndex(index)
    this.pressedIndex = index
end

-- Get pressed index
function Toolbar:getPressedIndex()
    return this.pressedIndex
end

-- Set on select callback
function Toolbar:setOnSelect(callback)
    this.onSelect = callback
end

-- Update toolbar
function Toolbar:update(dt)
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

-- Draw the toolbar
function Toolbar:draw()
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
    
    -- Draw items
    for i, item in ipairs(this.items) do
        local itemX = this.x + this.options.padding + (i - 1) * (this.options.itemSize + this.options.itemSpacing)
        local itemY = this.y + (this.height - this.options.itemSize) / 2
        
        -- Draw item background
        if i == this.hoveredIndex then
            love.graphics.setColor(this.options.hoverColor[1], this.options.hoverColor[2],
                this.options.hoverColor[3], this.options.hoverColor[4] * this.alpha)
            love.graphics.rectangle("fill", itemX, itemY, this.options.itemSize, this.options.itemSize,
                this.options.cornerRadius)
        elseif i == this.pressedIndex then
            love.graphics.setColor(this.options.pressColor[1], this.options.pressColor[2],
                this.options.pressColor[3], this.options.pressColor[4] * this.alpha)
            love.graphics.rectangle("fill", itemX, itemY, this.options.itemSize, this.options.itemSize,
                this.options.cornerRadius)
        end
        
        -- Draw item text
        love.graphics.setColor(this.options.textColor[1], this.options.textColor[2],
            this.options.textColor[3], this.options.textColor[4] * this.alpha)
        love.graphics.setFont(this.options.font)
        local textWidth = this.options.font:getWidth(item)
        local textHeight = this.options.font:getHeight()
        love.graphics.print(item, itemX + (this.options.itemSize - textWidth) / 2,
            itemY + (this.options.itemSize - textHeight) / 2)
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Toolbar:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside toolbar
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        local index = math.floor((x - this.x - this.options.padding) /
            (this.options.itemSize + this.options.itemSpacing)) + 1
        if index >= 1 and index <= #this.items then
            this.pressedIndex = index
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function Toolbar:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside toolbar
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        local index = math.floor((x - this.x - this.options.padding) /
            (this.options.itemSize + this.options.itemSpacing)) + 1
        if index >= 1 and index <= #this.items then
            this.hoveredIndex = index
            return true
        end
    end
    
    this.hoveredIndex = -1
    return false
end

-- Handle mouse release
function Toolbar:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside toolbar
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        local index = math.floor((x - this.x - this.options.padding) /
            (this.options.itemSize + this.options.itemSpacing)) + 1
        if index >= 1 and index <= #this.items and index == this.pressedIndex then
            if this.onSelect then
                this.onSelect(this.items[index])
            end
            this.pressedIndex = -1
            return true
        end
    end
    
    this.pressedIndex = -1
    return false
end

-- Handle key press
function Toolbar:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    if key == "left" then
        if this.hoveredIndex > 1 then
            this.hoveredIndex = this.hoveredIndex - 1
        end
        return true
    elseif key == "right" then
        if this.hoveredIndex < #this.items then
            this.hoveredIndex = this.hoveredIndex + 1
        end
        return true
    elseif key == "return" or key == "space" then
        if this.hoveredIndex >= 1 and this.hoveredIndex <= #this.items then
            if this.onSelect then
                this.onSelect(this.items[this.hoveredIndex])
            end
        end
        return true
    end
    
    return false
end

-- Handle text input
function Toolbar:textinput(text)
    return false
end

return Toolbar 