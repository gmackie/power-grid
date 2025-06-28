-- Input UI component for Power Grid Digital
-- A text input field with focus and selection states

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"

local Input = class('Input')

-- Create a new input field
function Input.new(text, x, y, width, height, options)
    local input = Input()
    input:initialize(text, x, y, width, height, options)
    return input
end

-- Initialize the input field
function Input:initialize(text, x, y, width, height, options)
    -- Set default options
    self.options = options or {}
    self.options.backgroundColor = self.options.backgroundColor or {0.2, 0.2, 0.3, 0.8}
    self.options.borderColor = self.options.borderColor or {0.4, 0.4, 0.5, 1}
    self.options.textColor = self.options.textColor or {1, 1, 1, 1}
    self.options.fontSize = self.options.fontSize or 14
    self.options.padding = self.options.padding or 5
    self.options.cornerRadius = self.options.cornerRadius or 5
    self.options.focusColor = self.options.focusColor or {0.5, 0.5, 0.6, 1}
    self.options.placeholderColor = self.options.placeholderColor or {0.5, 0.5, 0.5, 0.8}
    
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
        width - (2 * self.options.padding), height - (2 * self.options.padding), {
            backgroundColor = {0, 0, 0, 0},
            borderColor = {0, 0, 0, 0},
            textColor = self.options.textColor,
            fontSize = self.options.fontSize,
            padding = 0,
            cornerRadius = 0,
            alignment = "left",
            verticalAlignment = "center"
        })
    
    -- Input state
    self.visible = true
    self.text = text or ""
    self.placeholder = self.options.placeholder or ""
    self.focused = false
    self.cursorPosition = #self.text
    self.selectionStart = nil
    self.selectionEnd = nil
    self.onChange = nil
    self.onSubmit = nil
    
    return self
end

-- Set input position
function Input:setPosition(x, y)
    self.x = x
    self.y = y
    self.panel:setPosition(x, y)
    self.label:setPosition(x + self.options.padding, y + self.options.padding)
end

-- Set input size
function Input:setSize(width, height)
    self.width = width
    self.height = height
    self.panel:setSize(width, height)
    self.label:setSize(width - (2 * self.options.padding), height - (2 * self.options.padding))
end

-- Set input visibility
function Input:setVisible(visible)
    self.visible = visible
    self.panel:setVisible(visible)
    self.label:setVisible(visible)
end

-- Get input visibility
function Input:isVisible()
    return self.visible
end

-- Set input text
function Input:setText(text)
    self.text = text or ""
    self.cursorPosition = #self.text
    self.selectionStart = nil
    self.selectionEnd = nil
    self.label:setText(self.text)
end

-- Set placeholder text
function Input:setPlaceholder(text)
    self.placeholder = text or ""
end

-- Set focus state
function Input:setFocused(focused)
    self.focused = focused
end

-- Set change handler
function Input:setOnChange(handler)
    self.onChange = handler
end

-- Set submit handler
function Input:setOnSubmit(handler)
    self.onSubmit = handler
end

-- Set background color
function Input:setBackgroundColor(color)
    self.options.backgroundColor = color
    self.panel:setBackgroundColor(color)
end

-- Set border color
function Input:setBorderColor(color)
    self.options.borderColor = color
    self.panel:setBorderColor(color)
end

-- Set text color
function Input:setTextColor(color)
    self.options.textColor = color
    self.label:setTextColor(color)
end

-- Set font size
function Input:setFontSize(size)
    self.options.fontSize = size
    self.label:setFontSize(size)
end

-- Set focus color
function Input:setFocusColor(color)
    self.options.focusColor = color
end

-- Set placeholder color
function Input:setPlaceholderColor(color)
    self.options.placeholderColor = color
end

-- Draw the input field
function Input:draw()
    if not self.visible then return end
    
    -- Set panel border color based on focus state
    if self.focused then
        self.panel:setBorderColor(self.options.focusColor)
    else
        self.panel:setBorderColor(self.options.borderColor)
    end
    
    -- Draw panel
    self.panel:draw()
    
    -- Draw text or placeholder
    if self.text == "" and self.placeholder ~= "" then
        self.label:setTextColor(self.options.placeholderColor)
        self.label:setText(self.placeholder)
    else
        self.label:setTextColor(self.options.textColor)
        self.label:setText(self.text)
    end
    
    -- Draw label
    self.label:draw()
    
    -- Draw cursor if focused
    if self.focused then
        local cursorX = self.x + self.options.padding + self.label:getTextWidth(self.text:sub(1, self.cursorPosition))
        love.graphics.setColor(self.options.textColor)
        love.graphics.rectangle("fill", cursorX, self.y + self.options.padding, 2, self.height - (2 * self.options.padding))
    end
    
    -- Draw selection if any
    if self.selectionStart and self.selectionEnd then
        local start = math.min(self.selectionStart, self.selectionEnd)
        local finish = math.max(self.selectionStart, self.selectionEnd)
        local startX = self.x + self.options.padding + self.label:getTextWidth(self.text:sub(1, start))
        local endX = self.x + self.options.padding + self.label:getTextWidth(self.text:sub(1, finish))
        local selectionColor = {self.options.textColor[1], self.options.textColor[2], self.options.textColor[3], 0.3}
        love.graphics.setColor(selectionColor)
        love.graphics.rectangle("fill", startX, self.y + self.options.padding,
            endX - startX, self.height - (2 * self.options.padding))
    end
end

-- Handle mouse press
function Input:mousepressed(x, y, button)
    if not self.visible then return false end
    
    -- Check if click is inside input
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        self.focused = true
        -- Set cursor position based on click
        local clickX = x - (self.x + self.options.padding)
        local textWidth = 0
        for i = 1, #self.text do
            local charWidth = self.label:getTextWidth(self.text:sub(i, i))
            if textWidth + (charWidth / 2) > clickX then
                self.cursorPosition = i - 1
                break
            end
            textWidth = textWidth + charWidth
        end
        if textWidth <= clickX then
            self.cursorPosition = #self.text
        end
        return true
    end
    
    self.focused = false
    return false
end

-- Handle mouse move
function Input:mousemoved(x, y, dx, dy)
    if not self.visible then return false end
    
    -- Check if mouse is inside input
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        return true
    end
    
    return false
end

-- Handle mouse release
function Input:mousereleased(x, y, button)
    if not self.visible then return false end
    
    -- Check if mouse is inside input
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        return true
    end
    
    return false
end

-- Handle key press
function Input:keypressed(key, scancode, isrepeat)
    if not self.visible or not self.focused then return false end
    
    if key == "left" then
        self.cursorPosition = math.max(0, self.cursorPosition - 1)
        self.selectionStart = nil
        self.selectionEnd = nil
    elseif key == "right" then
        self.cursorPosition = math.min(#self.text, self.cursorPosition + 1)
        self.selectionStart = nil
        self.selectionEnd = nil
    elseif key == "home" then
        self.cursorPosition = 0
        self.selectionStart = nil
        self.selectionEnd = nil
    elseif key == "end" then
        self.cursorPosition = #self.text
        self.selectionStart = nil
        self.selectionEnd = nil
    elseif key == "backspace" then
        if self.selectionStart and self.selectionEnd then
            local start = math.min(self.selectionStart, self.selectionEnd)
            local finish = math.max(self.selectionStart, self.selectionEnd)
            self.text = self.text:sub(1, start) .. self.text:sub(finish + 1)
            self.cursorPosition = start
            self.selectionStart = nil
            self.selectionEnd = nil
            if self.onChange then
                self.onChange(self.text)
            end
        elseif self.cursorPosition > 0 then
            self.text = self.text:sub(1, self.cursorPosition - 1) .. self.text:sub(self.cursorPosition + 1)
            self.cursorPosition = self.cursorPosition - 1
            if self.onChange then
                self.onChange(self.text)
            end
        end
    elseif key == "delete" then
        if self.selectionStart and self.selectionEnd then
            local start = math.min(self.selectionStart, self.selectionEnd)
            local finish = math.max(self.selectionStart, self.selectionEnd)
            self.text = self.text:sub(1, start) .. self.text:sub(finish + 1)
            self.cursorPosition = start
            self.selectionStart = nil
            self.selectionEnd = nil
            if self.onChange then
                self.onChange(self.text)
            end
        elseif self.cursorPosition < #self.text then
            self.text = self.text:sub(1, self.cursorPosition) .. self.text:sub(self.cursorPosition + 2)
            if self.onChange then
                self.onChange(self.text)
            end
        end
    elseif key == "return" then
        if self.onSubmit then
            self.onSubmit(self.text)
        end
    end
    
    return true
end

-- Handle text input
function Input:textinput(text)
    if not self.visible or not self.focused then return false end
    
    if self.selectionStart and self.selectionEnd then
        local start = math.min(self.selectionStart, self.selectionEnd)
        local finish = math.max(self.selectionStart, self.selectionEnd)
        self.text = self.text:sub(1, start) .. text .. self.text:sub(finish + 1)
        self.cursorPosition = start + #text
        self.selectionStart = nil
        self.selectionEnd = nil
    else
        self.text = self.text:sub(1, self.cursorPosition) .. text .. self.text:sub(self.cursorPosition + 1)
        self.cursorPosition = self.cursorPosition + #text
    end
    
    if self.onChange then
        self.onChange(self.text)
    end
    
    return true
end

-- Handle window resize
function Input:resize(width, height)
    -- Update input size if it's the main input
    if self.x == 0 and self.y == 0 then
        self:setSize(width, height)
    end
end

return Input 