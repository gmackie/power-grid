-- ListBox UI component for Power Grid Digital
-- A list box control with optional label and scrollbar

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Slider = require "src.ui.slider"

local ListBox = class('ListBox')

-- Create a new list box
function ListBox.new(text, x, y, width, height, options)
    local listBox = ListBox()
    listBox:initialize(text, x, y, width, height, options)
    return listBox
end

-- Initialize the list box
function ListBox:initialize(text, x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.2, 0.2, 0.3, 0.8}
    self.options.borderColor = self.options.borderColor or {0.4, 0.4, 0.5, 1}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 14
    self.options.padding = self.options.padding or 5
    self.options.cornerRadius = self.options.cornerRadius or 5
    self.options.itemHeight = self.options.itemHeight or 25
    self.options.itemColor = self.options.itemColor or {0.3, 0.3, 0.4, 0.8}
    self.options.itemBorderColor = self.options.itemBorderColor or {0.4, 0.4, 0.5, 1}
    self.options.itemTextColor = self.options.itemTextColor or {1, 1, 1, 1}
    self.options.selectedItemColor = self.options.selectedItemColor or {0.5, 0.5, 0.6, 0.8}
    self.options.selectedItemBorderColor = self.options.selectedItemBorderColor or {0.6, 0.6, 0.7, 1}
    self.options.selectedItemTextColor = self.options.selectedItemTextColor or {1, 1, 1, 1}
    self.options.scrollbarWidth = self.options.scrollbarWidth or 16
    self.options.scrollbarColor = self.options.scrollbarColor or {0.3, 0.3, 0.4, 0.8}
    self.options.scrollbarBorderColor = self.options.scrollbarBorderColor or {0.4, 0.4, 0.5, 1}
    self.options.scrollbarHandleColor = self.options.scrollbarHandleColor or {0.5, 0.5, 0.6, 1}
    self.options.scrollbarHandleBorderColor = self.options.scrollbarHandleBorderColor or {0.6, 0.6, 0.7, 1}
    
    -- Set position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 200
    self.height = height or 200
    
    -- Create panel
    self.panel = Panel.new(x, y, width, height, {
        backgroundColor = self.options.backgroundColor,
        borderColor = self.options.borderColor,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create label if text is provided
    if text then
        self.label = Label.new(text, x + self.options.padding, y + self.options.padding,
            width - (2 * self.options.padding), self.options.itemHeight, {
                backgroundColor = {0, 0, 0, 0},
                borderColor = {0, 0, 0, 0},
                textColor = self.options.textColor,
                fontSize = self.options.fontSize,
                padding = 0,
                cornerRadius = 0,
                alignment = "left",
                verticalAlignment = "center"
            })
    end
    
    -- Create scrollbar
    self.scrollbar = Slider.new("", x + width - self.options.scrollbarWidth - self.options.padding,
        y + (text and (self.options.itemHeight + self.options.padding) or self.options.padding),
        self.options.scrollbarWidth, height - (text and (self.options.itemHeight + 2 * self.options.padding) or 2 * self.options.padding), {
            backgroundColor = self.options.scrollbarColor,
            borderColor = self.options.scrollbarBorderColor,
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = 0,
            cornerRadius = 0,
            sliderColor = self.options.scrollbarHandleColor,
            handleColor = self.options.scrollbarHandleColor,
            handleSize = self.options.scrollbarWidth,
            orientation = "vertical",
            minValue = 0,
            maxValue = 100,
            step = 1
        })
    
    -- List box state
    self.visible = true
    self.text = text or ""
    self.items = {}
    self.selectedIndex = 1
    self.scrollOffset = 0
    self.onChange = nil
    
    return self
end

-- Set list box position
function ListBox:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    if this.label then
        this.label:setPosition(x + this.options.padding, y + this.options.padding)
    end
    this.scrollbar:setPosition(x + this.width - this.options.scrollbarWidth - this.options.padding,
        y + (this.text and (this.options.itemHeight + this.options.padding) or this.options.padding))
end

-- Set list box size
function ListBox:setSize(width, height)
    this.width = width
    this.height = height
    this.panel:setSize(width, height)
    if this.label then
        this.label:setSize(width - (2 * this.options.padding), this.options.itemHeight)
    end
    this.scrollbar:setSize(this.options.scrollbarWidth,
        height - (this.text and (this.options.itemHeight + 2 * this.options.padding) or 2 * this.options.padding))
end

-- Set list box visibility
function ListBox:setVisible(visible)
    this.visible = visible
    this.panel:setVisible(visible)
    if this.label then
        this.label:setVisible(visible)
    end
    this.scrollbar:setVisible(visible)
end

-- Get list box visibility
function ListBox:isVisible()
    return this.visible
end

-- Set list box text
function ListBox:setText(text)
    this.text = text
    if this.label then
        this.label:setText(text)
    end
end

-- Set list box items
function ListBox:setItems(items)
    this.items = items or {}
    this.selectedIndex = math.min(this.selectedIndex, #this.items)
    this.scrollOffset = 0
    this.scrollbar:setValue(0)
end

-- Set selected index
function ListBox:setSelectedIndex(index)
    if index >= 1 and index <= #this.items then
        this.selectedIndex = index
        if this.onChange then
            this.onChange(this.items[index])
        end
    end
end

-- Get selected index
function ListBox:getSelectedIndex()
    return this.selectedIndex
end

-- Get selected item
function ListBox:getSelectedItem()
    return this.items[this.selectedIndex]
end

-- Set change handler
function ListBox:setOnChange(handler)
    this.onChange = handler
end

-- Set background color
function ListBox:setBackgroundColor(color)
    this.options.backgroundColor = color
    this.panel:setBackgroundColor(color)
end

-- Set border color
function ListBox:setBorderColor(color)
    this.options.borderColor = color
    this.panel:setBorderColor(color)
end

-- Set text color
function ListBox:setTextColor(color)
    this.options.textColor = color
    if this.label then
        this.label:setTextColor(color)
    end
end

-- Set font size
function ListBox:setFontSize(size)
    this.options.fontSize = size
    if this.label then
        this.label:setFontSize(size)
    end
end

-- Set item height
function ListBox:setItemHeight(height)
    this.options.itemHeight = height
    if this.label then
        this.label:setSize(this.width - (2 * this.options.padding), height)
    end
end

-- Set item color
function ListBox:setItemColor(color)
    this.options.itemColor = color
end

-- Set item border color
function ListBox:setItemBorderColor(color)
    this.options.itemBorderColor = color
end

-- Set item text color
function ListBox:setItemTextColor(color)
    this.options.itemTextColor = color
end

-- Set selected item color
function ListBox:setSelectedItemColor(color)
    this.options.selectedItemColor = color
end

-- Set selected item border color
function ListBox:setSelectedItemBorderColor(color)
    this.options.selectedItemBorderColor = color
end

-- Set selected item text color
function ListBox:setSelectedItemTextColor(color)
    this.options.selectedItemTextColor = color
end

-- Set scrollbar width
function ListBox:setScrollbarWidth(width)
    this.options.scrollbarWidth = width
    this.scrollbar:setSize(width,
        this.height - (this.text and (this.options.itemHeight + 2 * this.options.padding) or 2 * this.options.padding))
end

-- Set scrollbar color
function ListBox:setScrollbarColor(color)
    this.options.scrollbarColor = color
    this.scrollbar:setBackgroundColor(color)
end

-- Set scrollbar border color
function ListBox:setScrollbarBorderColor(color)
    this.options.scrollbarBorderColor = color
    this.scrollbar:setBorderColor(color)
end

-- Set scrollbar handle color
function ListBox:setScrollbarHandleColor(color)
    this.options.scrollbarHandleColor = color
    this.scrollbar:setSliderColor(color)
    this.scrollbar:setHandleColor(color)
end

-- Set scrollbar handle border color
function ListBox:setScrollbarHandleBorderColor(color)
    this.options.scrollbarHandleBorderColor = color
end

-- Draw the list box
function ListBox:draw()
    if not this.visible then return end
    
    -- Draw panel
    this.panel:draw()
    
    -- Draw label if exists
    if this.label then
        this.label:draw()
    end
    
    -- Draw items
    local startIndex = 1
    local endIndex = #this.items
    local visibleItems = math.floor((this.height - (this.text and (this.options.itemHeight + 2 * this.options.padding) or 2 * this.options.padding)) / this.options.itemHeight)
    
    for i = startIndex, endIndex do
        local item = this.items[i]
        local itemY = this.y + (this.text and (this.options.itemHeight + this.options.padding) or this.options.padding) + (i - 1) * this.options.itemHeight
        
        -- Draw item background
        if i == this.selectedIndex then
            love.graphics.setColor(this.options.selectedItemColor)
            love.graphics.rectangle("fill", this.x + this.options.padding, itemY,
                this.width - (this.options.scrollbarWidth + 3 * this.options.padding), this.options.itemHeight)
            love.graphics.setColor(this.options.selectedItemBorderColor)
            love.graphics.rectangle("line", this.x + this.options.padding, itemY,
                this.width - (this.options.scrollbarWidth + 3 * this.options.padding), this.options.itemHeight)
            love.graphics.setColor(this.options.selectedItemTextColor)
        else
            love.graphics.setColor(this.options.itemColor)
            love.graphics.rectangle("fill", this.x + this.options.padding, itemY,
                this.width - (this.options.scrollbarWidth + 3 * this.options.padding), this.options.itemHeight)
            love.graphics.setColor(this.options.itemBorderColor)
            love.graphics.rectangle("line", this.x + this.options.padding, itemY,
                this.width - (this.options.scrollbarWidth + 3 * this.options.padding), this.options.itemHeight)
            love.graphics.setColor(this.options.itemTextColor)
        end
        
        -- Draw item text
        love.graphics.setFont(love.graphics.newFont(this.options.fontSize))
        love.graphics.printf(item,
            this.x + (2 * this.options.padding),
            itemY + (this.options.itemHeight - this.options.fontSize) / 2,
            this.width - (this.options.scrollbarWidth + 4 * this.options.padding),
            "left")
    end
    
    -- Draw scrollbar
    this.scrollbar:draw()
end

-- Handle mouse press
function ListBox:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside scrollbar
    if this.scrollbar:mousepressed(x, y, button) then
        return true
    end
    
    -- Check if click is inside items
    local startIndex = 1
    local endIndex = #this.items
    local visibleItems = math.floor((this.height - (this.text and (this.options.itemHeight + 2 * this.options.padding) or 2 * this.options.padding)) / this.options.itemHeight)
    
    for i = startIndex, endIndex do
        local itemY = this.y + (this.text and (this.options.itemHeight + this.options.padding) or this.options.padding) + (i - 1) * this.options.itemHeight
        
        if x >= this.x + this.options.padding and x <= this.x + this.width - this.options.scrollbarWidth - this.options.padding and
           y >= itemY and y <= itemY + this.options.itemHeight then
            this:setSelectedIndex(i)
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function ListBox:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside scrollbar
    if this.scrollbar:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside items
    local startIndex = 1
    local endIndex = #this.items
    local visibleItems = math.floor((this.height - (this.text and (this.options.itemHeight + 2 * this.options.padding) or 2 * this.options.padding)) / this.options.itemHeight)
    
    for i = startIndex, endIndex do
        local itemY = this.y + (this.text and (this.options.itemHeight + this.options.padding) or this.options.padding) + (i - 1) * this.options.itemHeight
        
        if x >= this.x + this.options.padding and x <= this.x + this.width - this.options.scrollbarWidth - this.options.padding and
           y >= itemY and y <= itemY + this.options.itemHeight then
            return true
        end
    end
    
    return false
end

-- Handle mouse release
function ListBox:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside scrollbar
    if this.scrollbar:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside items
    local startIndex = 1
    local endIndex = #this.items
    local visibleItems = math.floor((this.height - (this.text and (this.options.itemHeight + 2 * this.options.padding) or 2 * this.options.padding)) / this.options.itemHeight)
    
    for i = startIndex, endIndex do
        local itemY = this.y + (this.text and (this.options.itemHeight + this.options.padding) or this.options.padding) + (i - 1) * this.options.itemHeight
        
        if x >= this.x + this.options.padding and x <= this.x + this.width - this.options.scrollbarWidth - this.options.padding and
           y >= itemY and y <= itemY + this.options.itemHeight then
            return true
        end
    end
    
    return false
end

-- Handle key press
function ListBox:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    return false
end

-- Handle text input
function ListBox:textinput(text)
    if not this.visible then return false end
    return false
end

-- Handle window resize
function ListBox:resize(width, height)
    -- Update list box size if it's the main list box
    if this.x == 0 and this.y == 0 then
        this:setSize(width, height)
    end
end

return ListBox 