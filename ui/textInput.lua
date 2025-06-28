-- TextInput UI component for Power Grid Digital
-- A text input field with optional background and border

local class = require "lib.middleclass"
local Component = require "src.ui.component"

local TextInput = class('TextInput', Component)

-- Initialize the text input
function TextInput:initialize(x, y, width, height, options)
    Component.initialize(self, x, y, width, height)
    
    -- Text input state
    self.text = ""
    self.cursor = 0
    self.focused = false
    self.alpha = 1.0
    
    -- Default options
    self.options = {
        placeholder = options and options.placeholder or "Enter text...",
        backgroundColor = options and options.backgroundColor or {0.1, 0.1, 0.2, 1},
        borderColor = options and options.borderColor or {0.3, 0.3, 0.4, 1},
        textColor = options and options.textColor or {1, 1, 1, 1},
        padding = options and options.padding or 5,
        fontSize = options and options.fontSize or 16,
        cornerRadius = options and options.cornerRadius or 0,
        password = options and options.password or false,
        maxLength = options and options.maxLength or 0,
        focusedBorderColor = options and options.focusedBorderColor or {0.4, 0.4, 0.6, 1}
    }
    
    -- Callbacks
    self.onChange = options and options.onChange
    self.onEnter = options and options.onEnter
    
    -- Selection state
    self.selectionStart = nil
    self.selectionEnd = nil
    
    -- Create font
    self.font = love.graphics.newFont(self.options.fontSize)
    
    return self
end

-- Set text
function TextInput:setText(text)
    if text ~= self.text then
        self.text = text or ""
        self.cursor = #self.text
        if self.onChange then
            self.onChange(self.text)
        end
    end
end

-- Get text
function TextInput:getText()
    return self.text
end

-- Set placeholder
function TextInput:setPlaceholder(placeholder)
    self.options.placeholder = placeholder
end

-- Set max length
function TextInput:setMaxLength(length)
    self.options.maxLength = length
    if length > 0 and #self.text > length then
        self.text = self.text:sub(1, length)
        self.cursor = #self.text
    end
end

-- Set password mode
function TextInput:setPassword(password)
    self.options.password = password
end

-- Set change handler
function TextInput:setOnChange(handler)
    self.onChange = handler
end

-- Set enter handler
function TextInput:setOnEnter(handler)
    self.onEnter = handler
end

-- Set background color
function TextInput:setBackgroundColor(color)
    self.options.backgroundColor = color
end

-- Set border color
function TextInput:setBorderColor(color)
    self.options.borderColor = color
end

-- Set text color
function TextInput:setTextColor(color)
    self.options.textColor = color
end

-- Set font size
function TextInput:setFontSize(size)
    self.options.fontSize = size
    self.font = love.graphics.newFont(size)
end

-- Focus the input
function TextInput:focus()
    self.focused = true
end

-- Unfocus the input
function TextInput:unfocus()
    self.focused = false
end

-- Check if input is focused
function TextInput:isFocused()
    return self.focused
end

-- Draw the text input
function TextInput:draw()
    if not self.visible then return end
    
    -- Save current color and font
    local r, g, b, a = love.graphics.getColor()
    local prevFont = love.graphics.getFont()
    
    -- Set font
    love.graphics.setFont(self.font)
    
    -- Draw background
    local backgroundColor = self.options.backgroundColor
    if not self:isEnabled() then
        backgroundColor = {0.5, 0.5, 0.5, 0.5} -- Disabled color
    end
    love.graphics.setColor(backgroundColor)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height,
        self.options.cornerRadius)
    
    -- Draw border
    local borderColor = self.focused and self.options.focusedBorderColor or self.options.borderColor
    if not self:isEnabled() then
        borderColor = {0.3, 0.3, 0.3, 0.5} -- Disabled border color
    end
    love.graphics.setColor(borderColor)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height,
        self.options.cornerRadius)
    
    -- Draw text or placeholder
    local textColor = self.options.textColor
    if not self:isEnabled() then
        textColor = {0.7, 0.7, 0.7, 0.7} -- Disabled text color
    end
    love.graphics.setColor(textColor)
    
    local displayText = self.text
    if self.options.password then
        displayText = string.rep("*", #self.text)
    end
    
    if displayText == "" and not self.focused then
        displayText = self.options.placeholder
        love.graphics.setColor(0.5, 0.5, 0.5, self.alpha)
    end
    
    -- Draw selection if any
    if self.focused and self.selectionStart and self.selectionEnd then
        local start = math.min(self.selectionStart, self.selectionEnd)
        local finish = math.max(self.selectionStart, self.selectionEnd)
        local selectedText = displayText:sub(start + 1, finish)
        local preText = displayText:sub(1, start)
        local startX = self.x + self.options.padding + self.font:getWidth(preText)
        local width = self.font:getWidth(selectedText)
        
        love.graphics.setColor(0.2, 0.4, 0.8, 0.3)
        love.graphics.rectangle("fill", startX, self.y + 2,
            width, self.height - 4)
    end
    
    -- Draw text
    love.graphics.setColor(textColor)
    love.graphics.printf(displayText,
        self.x + self.options.padding,
        self.y + (self.height - self.font:getHeight()) / 2,
        self.width - self.options.padding * 2,
        "left")
    
    -- Draw cursor if focused
    if self.focused and love.timer.getTime() % 1 < 0.5 then
        local cursorX = self.x + self.options.padding
        if self.cursor > 0 then
            local textBeforeCursor = displayText:sub(1, self.cursor)
            cursorX = cursorX + self.font:getWidth(textBeforeCursor)
        end
        
        love.graphics.setColor(textColor)
        love.graphics.rectangle("fill", cursorX,
            self.y + (self.height - self.font:getHeight()) / 2,
            1, self.font:getHeight())
    end
    
    -- Restore original color and font
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(prevFont)
end

-- Handle mouse press
function TextInput:mousepressed(x, y, button)
    if not self.visible or not self.enabled or button ~= 1 then return false end
    
    -- Convert global coordinates to local
    local lx, ly = self:globalToLocal(x, y)
    
    -- Check if click is inside input
    if self:containsPoint(x, y) then
        self.focused = true
        
        -- Calculate cursor position based on click position
        local textX = lx - self.options.padding
        local displayText = self.options.password and string.rep("*", #self.text) or self.text
        
        -- Find cursor position based on click position
        local newCursor = 0
        local currentWidth = 0
        
        for i = 1, #displayText do
            local charWidth = self.font:getWidth(displayText:sub(i,i))
            if currentWidth + (charWidth/2) > textX then
                break
            end
            currentWidth = currentWidth + charWidth
            newCursor = i
        end
        
        self.cursor = newCursor
        
        -- Start selection if shift is held
        if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
            if not self.selectionStart then
                self.selectionStart = self.cursor
            end
            self.selectionEnd = self.cursor
        else
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        
        return true
    else
        self.focused = false
    end
    
    return false
end

-- Handle mouse move
function TextInput:mousemoved(x, y, dx, dy)
    if not self.visible or not self.enabled then return false end
    return self:containsPoint(x, y)
end

-- Handle mouse release
function TextInput:mousereleased(x, y, button)
    if not self.visible or not self.enabled then return false end
    return false
end

-- Handle key press
function TextInput:keypressed(key, scancode, isrepeat)
    if not self.visible or not self.enabled or not self.focused then return false end
    
    if key == "backspace" then
        if self.selectionStart and self.selectionEnd then
            local start = math.min(self.selectionStart, self.selectionEnd)
            local finish = math.max(self.selectionStart, self.selectionEnd)
            self.text = self.text:sub(1, start) .. self.text:sub(finish + 1)
            self.cursor = start
            self.selectionStart = nil
            self.selectionEnd = nil
            if self.onChange then
                self.onChange(self.text)
            end
        elseif self.cursor > 0 then
            self.text = self.text:sub(1, self.cursor - 1) .. self.text:sub(self.cursor + 1)
            self.cursor = self.cursor - 1
            if self.onChange then
                self.onChange(self.text)
            end
        end
        return true
    elseif key == "delete" then
        if self.selectionStart and self.selectionEnd then
            local start = math.min(self.selectionStart, self.selectionEnd)
            local finish = math.max(self.selectionStart, self.selectionEnd)
            self.text = self.text:sub(1, start) .. self.text:sub(finish + 1)
            self.cursor = start
            self.selectionStart = nil
            self.selectionEnd = nil
            if self.onChange then
                self.onChange(self.text)
            end
        elseif self.cursor < #self.text then
            self.text = self.text:sub(1, self.cursor) .. self.text:sub(self.cursor + 2)
            if self.onChange then
                self.onChange(self.text)
            end
        end
        return true
    elseif key == "left" then
        if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
            if not self.selectionStart then
                self.selectionStart = self.cursor
            end
        else
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        
        if self.cursor > 0 then
            self.cursor = self.cursor - 1
            if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
                self.selectionEnd = self.cursor
            end
        end
        return true
    elseif key == "right" then
        if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
            if not self.selectionStart then
                self.selectionStart = self.cursor
            end
        else
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        
        if self.cursor < #self.text then
            self.cursor = self.cursor + 1
            if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
                self.selectionEnd = self.cursor
            end
        end
        return true
    elseif key == "home" then
        if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
            if not self.selectionStart then
                self.selectionStart = self.cursor
            end
            self.selectionEnd = 0
        else
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        self.cursor = 0
        return true
    elseif key == "end" then
        if love.keyboard.isDown('lshift') or love.keyboard.isDown('rshift') then
            if not self.selectionStart then
                self.selectionStart = self.cursor
            end
            self.selectionEnd = #self.text
        else
            self.selectionStart = nil
            self.selectionEnd = nil
        end
        self.cursor = #self.text
        return true
    elseif key == "return" or key == "kpenter" then
        if self.onEnter then
            self.onEnter(self.text)
        end
        return true
    elseif key == "c" and (love.keyboard.isDown('lgui') or love.keyboard.isDown('rgui')) then
        -- Copy
        if self.selectionStart and self.selectionEnd then
            local start = math.min(self.selectionStart, self.selectionEnd)
            local finish = math.max(self.selectionStart, self.selectionEnd)
            love.system.setClipboardText(self.text:sub(start + 1, finish))
        end
        return true
    elseif key == "v" and (love.keyboard.isDown('lgui') or love.keyboard.isDown('rgui')) then
        -- Paste
        local text = love.system.getClipboardText()
        if text then
            if self.selectionStart and self.selectionEnd then
                local start = math.min(self.selectionStart, self.selectionEnd)
                local finish = math.max(self.selectionStart, self.selectionEnd)
                self.text = self.text:sub(1, start) .. text .. self.text:sub(finish + 1)
                self.cursor = start + #text
            else
                self.text = self.text:sub(1, self.cursor) .. text .. self.text:sub(self.cursor + 1)
                self.cursor = self.cursor + #text
            end
            self.selectionStart = nil
            self.selectionEnd = nil
            if self.onChange then
                self.onChange(self.text)
            end
        end
        return true
    elseif key == "x" and (love.keyboard.isDown('lgui') or love.keyboard.isDown('rgui')) then
        -- Cut
        if self.selectionStart and self.selectionEnd then
            local start = math.min(self.selectionStart, self.selectionEnd)
            local finish = math.max(self.selectionStart, self.selectionEnd)
            love.system.setClipboardText(self.text:sub(start + 1, finish))
            self.text = self.text:sub(1, start) .. self.text:sub(finish + 1)
            self.cursor = start
            self.selectionStart = nil
            self.selectionEnd = nil
            if self.onChange then
                self.onChange(self.text)
            end
        end
        return true
    elseif key == "a" and (love.keyboard.isDown('lgui') or love.keyboard.isDown('rgui')) then
        -- Select all
        self.selectionStart = 0
        self.selectionEnd = #self.text
        self.cursor = #self.text
        return true
    end
    
    return false
end

-- Handle text input
function TextInput:textinput(text)
    if not self.visible or not self.enabled or not self.focused then return false end
    
    -- Check max length
    if self.options.maxLength > 0 and #self.text >= self.options.maxLength then
        return false
    end
    
    -- Replace selected text if any
    if self.selectionStart and self.selectionEnd then
        local start = math.min(self.selectionStart, self.selectionEnd)
        local finish = math.max(self.selectionStart, self.selectionEnd)
        self.text = self.text:sub(1, start) .. text .. self.text:sub(finish + 1)
        self.cursor = start + #text
        self.selectionStart = nil
        self.selectionEnd = nil
    else
        -- Insert text at cursor position
        self.text = self.text:sub(1, self.cursor) .. text .. self.text:sub(self.cursor + 1)
        self.cursor = self.cursor + #text
    end
    
    -- Call change handler
    if self.onChange then
        self.onChange(self.text)
    end
    
    return true
end

return TextInput 