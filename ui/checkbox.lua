-- CheckBox UI component for Power Grid Digital
-- A checkbox that can be checked and unchecked

local class = require "lib.middleclass"

local CheckBox = class('CheckBox')

-- Create a new checkbox
function CheckBox.new(options)
    local checkBox = CheckBox()
    checkBox:initialize(options)
    return checkBox
end

-- Initialize the checkbox
function CheckBox:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.checkColor = this.options.checkColor or {1, 1, 1, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.hoverColor = this.options.hoverColor or {0.7, 0.7, 0.7, 0.7}
    this.options.pressColor = this.options.pressColor or {0.9, 0.9, 0.9, 0.9}
    this.options.fontSize = this.options.fontSize or 14
    this.options.font = this.options.font or love.graphics.newFont(this.options.fontSize)
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    this.options.size = this.options.size or 20
    this.options.checked = this.options.checked or false
    this.options.text = this.options.text or ""
    
    -- Checkbox state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.checked = this.options.checked
    this.hovered = false
    this.pressed = false
    this.onChange = this.options.onChange
    
    return this
end

-- Set checkbox position
function CheckBox:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set checkbox size
function CheckBox:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set checkbox visibility
function CheckBox:setVisible(visible)
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

-- Get checkbox visibility
function CheckBox:isVisible()
    return this.visible
end

-- Set background color
function CheckBox:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function CheckBox:setBorderColor(color)
    this.options.borderColor = color
end

-- Set check color
function CheckBox:setCheckColor(color)
    this.options.checkColor = color
end

-- Set text color
function CheckBox:setTextColor(color)
    this.options.textColor = color
end

-- Set hover color
function CheckBox:setHoverColor(color)
    this.options.hoverColor = color
end

-- Set press color
function CheckBox:setPressColor(color)
    this.options.pressColor = color
end

-- Set font size
function CheckBox:setFontSize(size)
    this.options.fontSize = size
    this.options.font = love.graphics.newFont(size)
end

-- Set padding
function CheckBox:setPadding(padding)
    this.options.padding = padding
end

-- Set corner radius
function CheckBox:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function CheckBox:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function CheckBox:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Set size
function CheckBox:setSize(size)
    this.options.size = size
end

-- Get size
function CheckBox:getSize()
    return this.options.size
end

-- Set checked
function CheckBox:setChecked(checked)
    if checked ~= this.checked then
        this.checked = checked
        if this.onChange then
            this.onChange(checked)
        end
    end
end

-- Get checked
function CheckBox:isChecked()
    return this.checked
end

-- Set text
function CheckBox:setText(text)
    this.options.text = text
end

-- Get text
function CheckBox:getText()
    return this.options.text
end

-- Set hovered
function CheckBox:setHovered(hovered)
    this.hovered = hovered
end

-- Get hovered
function CheckBox:isHovered()
    return this.hovered
end

-- Set pressed
function CheckBox:setPressed(pressed)
    this.pressed = pressed
end

-- Get pressed
function CheckBox:isPressed()
    return this.pressed
end

-- Set onChange callback
function CheckBox:setOnChange(callback)
    this.onChange = callback
end

-- Update checkbox
function CheckBox:update(dt)
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

-- Draw the checkbox
function CheckBox:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw background
    if this.options.backgroundColor[4] > 0 then
        love.graphics.setColor(this.options.backgroundColor[1], this.options.backgroundColor[2],
            this.options.backgroundColor[3], this.options.backgroundColor[4] * this.alpha)
        love.graphics.rectangle("fill", this.x, this.y, this.options.size, this.options.size,
            this.options.cornerRadius)
    end
    
    -- Draw border
    if this.options.borderColor[4] > 0 then
        love.graphics.setColor(this.options.borderColor[1], this.options.borderColor[2],
            this.options.borderColor[3], this.options.borderColor[4] * this.alpha)
        love.graphics.rectangle("line", this.x, this.y, this.options.size, this.options.size,
            this.options.cornerRadius)
    end
    
    -- Draw check
    if this.checked then
        love.graphics.setColor(this.options.checkColor[1], this.options.checkColor[2],
            this.options.checkColor[3], this.options.checkColor[4] * this.alpha)
        local checkSize = this.options.size * 0.6
        local checkX = this.x + (this.options.size - checkSize) / 2
        local checkY = this.y + (this.options.size - checkSize) / 2
        love.graphics.rectangle("fill", checkX, checkY, checkSize, checkSize,
            this.options.cornerRadius)
    end
    
    -- Draw text
    if this.options.text ~= "" then
        love.graphics.setColor(this.options.textColor[1], this.options.textColor[2],
            this.options.textColor[3], this.options.textColor[4] * this.alpha)
        love.graphics.setFont(this.options.font)
        local textWidth = this.options.font:getWidth(this.options.text)
        local textHeight = this.options.font:getHeight()
        love.graphics.print(this.options.text, this.x + this.options.size + this.options.padding,
            this.y + (this.options.size - textHeight) / 2)
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function CheckBox:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside checkbox
    if x >= this.x and x <= this.x + this.options.size and
        y >= this.y and y <= this.y + this.options.size then
        this.pressed = true
        return true
    end
    
    return false
end

-- Handle mouse move
function CheckBox:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside checkbox
    if x >= this.x and x <= this.x + this.options.size and
        y >= this.y and y <= this.y + this.options.size then
        this.hovered = true
        return true
    end
    
    this.hovered = false
    return false
end

-- Handle mouse release
function CheckBox:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside checkbox
    if x >= this.x and x <= this.x + this.options.size and
        y >= this.y and y <= this.y + this.options.size then
        this.pressed = false
        this:setChecked(not this.checked)
        return true
    end
    
    this.pressed = false
    return false
end

-- Handle key press
function CheckBox:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    if key == "return" or key == "space" then
        this:setChecked(not this.checked)
        return true
    end
    
    return false
end

-- Handle text input
function CheckBox:textinput(text)
    return false
end

return CheckBox 