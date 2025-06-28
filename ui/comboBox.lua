-- ComboBox UI component for Power Grid Digital
-- A dropdown combo box control with optional label

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"
local Button = require "src.ui.button"

local ComboBox = class('ComboBox')

-- Create a new combo box
function ComboBox.new(text, x, y, width, height, options)
    local comboBox = ComboBox()
    comboBox:initialize(text, x, y, width, height, options)
    return comboBox
end

-- Initialize the combo box
function ComboBox:initialize(text, x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.2, 0.2, 0.3, 0.8}
    self.options.borderColor = self.options.borderColor or {0.4, 0.4, 0.5, 1}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 14
    self.options.padding = self.options.padding or 5
    self.options.cornerRadius = self.options.cornerRadius or 5
    self.options.buttonColor = self.options.buttonColor or {0.3, 0.3, 0.4, 0.8}
    self.options.buttonBorderColor = self.options.buttonBorderColor or {0.4, 0.4, 0.5, 1}
    self.options.buttonTextColor = self.options.buttonTextColor or {1, 1, 1, 1}
    self.options.buttonSize = self.options.buttonSize or 20
    self.options.spacing = self.options.spacing or 8
    self.options.itemHeight = self.options.itemHeight or 25
    self.options.maxItems = self.options.maxItems or 5
    
    -- Set position and size
    self.x = x or 0
    self.y = y or 0
    self.width = width or 200
    self.height = height or 30
    
    -- Create panel
    self.panel = Panel.new(x, y, width, height, {
        backgroundColor = self.options.backgroundColor,
        borderColor = self.options.borderColor,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Create label
    self.label = Label.new(text, x + self.options.padding, y + self.options.padding,
        width - (self.options.buttonSize + self.options.spacing + self.options.padding), height - (2 * self.options.padding), {
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0},
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = 0,
            cornerRadius = 0,
            alignment = "left",
            verticalAlignment = "center"
        })
    
    -- Create button
    self.button = Button.new("▼", x + width - self.options.buttonSize - self.options.padding, y + self.options.padding,
        self.options.buttonSize, height - (2 * self.options.padding), {
            backgroundColor = self.options.buttonColor,
            borderColor = self.options.buttonBorderColor,
            textColor = self.options.buttonTextColor,
            fontSize = self.options.fontSize,
            padding = 0,
            cornerRadius = 0
        })
    
    -- Create dropdown panel
    self.dropdownPanel = Panel.new(x, y + height, width, 0, {
        backgroundColor = self.options.backgroundColor,
        borderColor = self.options.borderColor,
        cornerRadius = self.options.cornerRadius
    })
    
    -- Combo box state
    self.visible = true
    self.text = text or ""
    self.items = {}
    self.selectedIndex = 1
    self.dropdownVisible = false
    self.onChange = nil
    
    return self
end

-- Set combo box position
function ComboBox:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.label:setPosition(x + self.options.padding, y + self.options.padding)
    self.button:setPosition(x + self.width - self.options.buttonSize - self.options.padding, y + self.options.padding)
    self.dropdownPanel:setPosition(x, y + self.height)
end

-- Set combo box size
function ComboBox:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.label:setSize(width - (self.options.buttonSize + self.options.spacing + self.options.padding), height - (2 * self.options.padding))
    self.button:setSize(self.options.buttonSize, height - (2 * self.options.padding))
    self.dropdownPanel:setSize(width, #self.items * self.options.itemHeight)
end

-- Set combo box visibility
function ComboBox:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.label:setVisible(visible)
    self.button:setVisible(visible)
    if not visible then
        self.dropdownVisible = false
        self.dropdownPanel:setVisible(false)
    end
end

-- Get combo box visibility
function ComboBox:isVisible()
    return self.visible
end

-- Set combo box text
function ComboBox:setText(text)
    self.text = text
    self.label:setText(text)
end

-- Set combo box items
function ComboBox:setItems(items)
    self.items = items or {}
    self.selectedIndex = math.min(self.selectedIndex, #self.items)
    self.dropdownPanel:setSize(self.width, math.min(#self.items, self.options.maxItems) * self.options.itemHeight)
end

-- Set selected index
function ComboBox:setSelectedIndex(index)
    if index >= 1 and index <= #self.items then
        self.selectedIndex = index
        if self.onChange then
            self.onChange(self.items[index])
        end
    end
end

-- Get selected index
function ComboBox:getSelectedIndex()
    return self.selectedIndex
end

-- Get selected item
function ComboBox:getSelectedItem()
    return self.items[self.selectedIndex]
end

-- Set change handler
function ComboBox:setOnChange(handler)
    self.onChange = handler
end

-- Set background color
function ComboBox:setBackgroundColor(color)
    self.options.backgroundColor = color
    self.panel:setBackgroundColor(color)
    self.dropdownPanel:setBackgroundColor(color)
end

-- Set border color
function ComboBox:setBorderColor(color)
    self.options.borderColor = color
    self.panel:setBorderColor(color)
    self.dropdownPanel:setBorderColor(color)
end

-- Set text color
function ComboBox:setTextColor(color)
    self.options.textColor = color
    self.label:setTextColor(color)
end

-- Set font size
function ComboBox:setFontSize(size)
    self.options.fontSize = size
    self.label:setFontSize(size)
    self.button:setFontSize(size)
end

-- Set button color
function ComboBox:setButtonColor(color)
    self.options.buttonColor = color
    self.button:setBackgroundColor(color)
end

-- Set button border color
function ComboBox:setButtonBorderColor(color)
    self.options.buttonBorderColor = color
    self.button:setBorderColor(color)
end

-- Set button text color
function ComboBox:setButtonTextColor(color)
    self.options.buttonTextColor = color
    self.button:setTextColor(color)
end

-- Set button size
function ComboBox:setButtonSize(size)
    self.options.buttonSize = size
    self.button:setSize(size, self.height - (2 * self.options.padding))
    self.label:setSize(self.width - (size + self.options.spacing + self.options.padding), self.height - (2 * self.options.padding))
end

-- Set spacing
function ComboBox:setSpacing(spacing)
    self.options.spacing = spacing
    self.label:setSize(self.width - (self.options.buttonSize + spacing + self.options.padding), self.height - (2 * self.options.padding))
end

-- Set item height
function ComboBox:setItemHeight(height)
    self.options.itemHeight = height
    self.dropdownPanel:setSize(self.width, math.min(#self.items, self.options.maxItems) * height)
end

-- Set max items
function ComboBox:setMaxItems(max)
    self.options.maxItems = max
    self.dropdownPanel:setSize(self.width, math.min(#self.items, max) * self.options.itemHeight)
end

-- Draw the combo box
function ComboBox:draw()
    if not self.visible then return end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw label
    self.label:draw()
    
    -- Draw button
    self.button:draw()
    
    -- Draw dropdown if visible
    if self.dropdownVisible then
        self.dropdownPanel:draw()
        
        -- Draw items
        local startIndex = 1
        local endIndex = math.min(#self.items, self.options.maxItems)
        
        for i = startIndex, endIndex do
            local item = self.items[i]
            local itemY = self.y + self.height + (i - 1) * self.options.itemHeight
            
            -- Draw item background if selected
            if i == self.selectedIndex then
                love.graphics.setColor(self.options.buttonColor)
                love.graphics.rectangle("fill", self.x + self.options.padding, itemY + self.options.padding,
                    self.width - (2 * self.options.padding), self.options.itemHeight - (2 * self.options.padding))
            end
            
            -- Draw item text
            love.graphics.setColor(self.options.textColor)
            love.graphics.setFont(love.graphics.newFont(self.options.fontSize))
            love.graphics.printf(item,
                self.x + self.options.padding,
                itemY + (self.options.itemHeight - self.options.fontSize) / 2,
                self.width - (2 * self.options.padding),
                "left")
        end
    end
end

-- Handle mouse press
function ComboBox:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside button
    if self.button:mousepressed(x, y, button) then
        self.dropdownVisible = not self.dropdownVisible
        self.dropdownPanel:setVisible(self.dropdownVisible)
        return true
    end
    
    -- Check if click is inside dropdown
    if self.dropdownVisible then
        local startIndex = 1
        local endIndex = math.min(#self.items, self.options.maxItems)
        
        for i = startIndex, endIndex do
            local itemY = self.y + self.height + (i - 1) * self.options.itemHeight
            
            if x >= self.x + self.options.padding and x <= self.x + self.width - self.options.padding and
               y >= itemY + self.options.padding and y <= itemY + self.options.itemHeight - self.options.padding then
                self:setSelectedIndex(i)
                self.dropdownVisible = false
                self.dropdownPanel:setVisible(false)
                return true
            end
        end
    end
    
    return false
end

-- Handle mouse move
function ComboBox:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Check if mouse is inside button
    if self.button:mousemoved(x, y, dx, dy) then
        return true
    end
    
    -- Check if mouse is inside dropdown
    if self.dropdownVisible then
        local startIndex = 1
        local endIndex = math.min(#self.items, self.options.maxItems)
        
        for i = startIndex, endIndex do
            local itemY = self.y + self.height + (i - 1) * self.options.itemHeight
            
            if x >= self.x + self.options.padding and x <= self.x + self.width - self.options.padding and
               y >= itemY + self.options.padding and y <= itemY + self.options.itemHeight - self.options.padding then
                return true
            end
        end
    end
    
    return false
end

-- Handle mouse release
function ComboBox:mousereleased(x, y, button)
    if not self.visible then return false end
    
    -- Check if mouse is inside button
    if self.button:mousereleased(x, y, button) then
        return true
    end
    
    -- Check if mouse is inside dropdown
    if self.dropdownVisible then
        local startIndex = 1
        local endIndex = math.min(#self.items, self.options.maxItems)
        
        for i = startIndex, endIndex do
            local itemY = self.y + self.height + (i - 1) * self.options.itemHeight
            
            if x >= self.x + self.options.padding and x <= self.x + self.width - self.options.padding and
               y >= itemY + self.options.padding and y <= itemY + self.options.itemHeight - self.options.padding then
                return true
            end
        end
    end
    
    return false
end

-- Handle key press
function ComboBox:keypressed(key, scancode, isrepeat)
    if not self.visible then return false end
    
    if key == "escape" and self.dropdownVisible then
        self.dropdownVisible = false
        self.dropdownPanel:setVisible(false)
        return true
    end
    
    return false
end

-- Handle text input
function ComboBox:textinput(text)
    if not self.visible then return false end
    return false
end

-- Handle window resize
function ComboBox:resize(width, height)
    -- Update combo box size if it's the main combo box
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return ComboBox 