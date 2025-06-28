-- ListView UI component for Power Grid Digital
-- A list view with items

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Button = require "src.ui.button"

local ListView = class('ListView')

-- Create a new list view
function ListView.new(x, y, width, height, options)
    local listView = ListView()
    listView:initialize(x, y, width, height, options)
    return listView
end

-- Initialize the list view
function ListView:initialize(x, y, width, height, options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.3, 0.8}
    this.options.borderColor = this.options.borderColor or {0.4, 0.4, 0.5, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 5
    this.options.itemHeight = this.options.itemHeight or 30
    this.options.itemSpacing = this.options.itemSpacing or 5
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Set position and size
    this.x = x or 0
    this.y = y or 0
    this.width = width or 200
    this.height = height or 200
    
    -- Create panel
    this.panel = Panel.new(x, y, width, this.height, {
        backgroundColor = this.options.backgroundColor,
        borderColor = this.options.borderColor,
        cornerRadius = this.options.cornerRadius
    })
    
    -- List view state
    this.visible = true
    this.alpha = 1
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.items = {}
    this.selectedItem = nil
    this.scrollY = 0
    
    return this
end

-- Set list view position
function ListView:setPosition(x, y)
    this.x = x
    this.y = y
    this.panel:setPosition(x, y)
    this:updateItemPositions()
end

-- Set list view size
function ListView:setSize(width, height)
    this.width = width
    this.height = height
    this.panel:setSize(width, height)
    this:updateItemPositions()
end

-- Set list view visibility
function ListView:setVisible(visible)
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

-- Get list view visibility
function ListView:isVisible()
    return this.visible
end

-- Add item
function ListView:addItem(text, options)
    options = options or {}
    options.backgroundColor = options.backgroundColor or {0.3, 0.3, 0.4, 0.8}
    options.borderColor = options.borderColor or {0.4, 0.4, 0.5, 1}
    options.textColor = options.textColor or this.options.textColor
    options.fontSize = options.fontSize or this.options.fontSize
    options.padding = options.padding or this.options.padding
    options.cornerRadius = options.cornerRadius or this.options.cornerRadius
    options.hoverColor = options.hoverColor or {0.4, 0.4, 0.5, 0.8}
    options.pressColor = options.pressColor or {0.2, 0.2, 0.3, 0.8}
    
    local item = {
        text = text,
        button = Button.new(text,
            this.x + this.options.padding,
            this.y + this.options.padding + (#this.items * (this.options.itemHeight + this.options.itemSpacing)),
            this.width - (2 * this.options.padding),
            this.options.itemHeight, options)
    }
    
    item.button:setOnClick(function()
        this:selectItem(#this.items + 1)
    end)
    
    table.insert(this.items, item)
    this:updateItemPositions()
    
    return #this.items
end

-- Remove item
function ListView:removeItem(index)
    if index >= 1 and index <= #this.items then
        table.remove(this.items, index)
        this:updateItemPositions()
        
        -- Deselect item if needed
        if this.selectedItem == index then
            this.selectedItem = nil
        elseif this.selectedItem > index then
            this.selectedItem = this.selectedItem - 1
        end
    end
end

-- Clear items
function ListView:clearItems()
    this.items = {}
    this.selectedItem = nil
    this.scrollY = 0
end

-- Get all items
function ListView:getItems()
    return this.items
end

-- Select item
function ListView:selectItem(index)
    if index >= 1 and index <= #this.items then
        this.selectedItem = index
    end
end

-- Get selected item
function ListView:getSelectedItem()
    return this.selectedItem
end

-- Set background color
function ListView:setBackgroundColor(color)
    this.options.backgroundColor = color
    this.panel:setBackgroundColor(color)
end

-- Set border color
function ListView:setBorderColor(color)
    this.options.borderColor = color
    this.panel:setBorderColor(color)
end

-- Set text color
function ListView:setTextColor(color)
    this.options.textColor = color
    for _, item in ipairs(this.items) do
        item.button:setTextColor(color)
    end
end

-- Set font size
function ListView:setFontSize(size)
    this.options.fontSize = size
    for _, item in ipairs(this.items) do
        item.button:setFontSize(size)
    end
end

-- Set item height
function ListView:setItemHeight(height)
    this.options.itemHeight = height
    for _, item in ipairs(this.items) do
        item.button:setSize(item.button.width, height)
    end
    this:updateItemPositions()
end

-- Set item spacing
function ListView:setItemSpacing(spacing)
    this.options.itemSpacing = spacing
    this:updateItemPositions()
end

-- Set fade in duration
function ListView:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function ListView:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update item positions
function ListView:updateItemPositions()
    for i, item in ipairs(this.items) do
        item.button:setPosition(
            this.x + this.options.padding,
            this.y + this.options.padding + ((i - 1) * (this.options.itemHeight + this.options.itemSpacing)))
    end
end

-- Update list view
function ListView:update(dt)
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
    
    -- Update buttons
    for _, item in ipairs(this.items) do
        item.button:update(dt)
    end
end

-- Draw the list view
function ListView:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw panel
    this.panel:draw()
    
    -- Draw buttons
    for _, item in ipairs(this.items) do
        item.button:draw()
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function ListView:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside buttons
    for _, item in ipairs(this.items) do
        if item.button:mousepressed(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function ListView:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside buttons
    for _, item in ipairs(this.items) do
        if item.button:mousemoved(x, y, dx, dy) then
            return true
        end
    end
    
    return false
end

-- Handle mouse release
function ListView:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside buttons
    for _, item in ipairs(this.items) do
        if item.button:mousereleased(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle key press
function ListView:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Check if key is handled by buttons
    for _, item in ipairs(this.items) do
        if item.button:keypressed(key, scancode, isrepeat) then
            return true
        end
    end
    
    return false
end

-- Handle text input
function ListView:textinput(text)
    if not this.visible then return false end
    
    -- Check if text is handled by buttons
    for _, item in ipairs(this.items) do
        if item.button:textinput(text) then
            return true
        end
    end
    
    return false
end

-- Handle window resize
function ListView:resize(width, height)
    -- Update list view position if it's the main list view
    if this.x == 0 and this.y == 0 then
        this:setPosition(0, 0)
    end
end

return ListView 