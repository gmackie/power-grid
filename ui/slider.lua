-- Slider UI component for Power Grid Digital
-- A slider with optional text and background

local class = require "lib.middleclass"

local Slider = class('Slider')

-- Create a new slider
function Slider.new(x, y, width, height, options)
    local slider = Slider()
    slider:initialize(x, y, width, height, options)
    return slider
end

-- Initialize the slider
function Slider:initialize(x, y, width, height, options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.2, 0.8}
    this.options.borderColor = this.options.borderColor or {0.3, 0.3, 0.3, 1}
    this.options.sliderColor = this.options.sliderColor or {0.4, 0.6, 0.8, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 5
    this.options.showText = this.options.showText or true
    this.options.textFormat = this.options.textFormat or "%d%%"
    this.options.sliderSize = this.options.sliderSize or 20
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Set position and size
    this.x = x or 0
    this.y = y or 0
    this.width = width or 200
    this.height = height or 20
    
    -- Slider state
    this.visible = true
    this.alpha = 1
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.value = 0
    this.maxValue = 100
    this.dragging = false
    this.onChange = nil
    
    return this
end

-- Set slider position
function Slider:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set slider size
function Slider:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set slider visibility
function Slider:setVisible(visible)
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

-- Get slider visibility
function Slider:isVisible()
    return this.visible
end

-- Set value
function Slider:setValue(value)
    value = math.max(0, math.min(value, this.maxValue))
    if value ~= this.value then
        this.value = value
        if this.onChange then
            this.onChange(value)
        end
    end
end

-- Get value
function Slider:getValue()
    return this.value
end

-- Set max value
function Slider:setMaxValue(maxValue)
    this.maxValue = maxValue
    this.value = math.min(this.value, maxValue)
end

-- Get max value
function Slider:getMaxValue()
    return this.maxValue
end

-- Set change handler
function Slider:setOnChange(handler)
    this.onChange = handler
end

-- Set background color
function Slider:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function Slider:setBorderColor(color)
    this.options.borderColor = color
end

-- Set slider color
function Slider:setSliderColor(color)
    this.options.sliderColor = color
end

-- Set text color
function Slider:setTextColor(color)
    this.options.textColor = color
end

-- Set font size
function Slider:setFontSize(size)
    this.options.fontSize = size
end

-- Set show text
function Slider:setShowText(show)
    this.options.showText = show
end

-- Set text format
function Slider:setTextFormat(format)
    this.options.textFormat = format
end

-- Set slider size
function Slider:setSliderSize(size)
    this.options.sliderSize = size
end

-- Set fade in duration
function Slider:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function Slider:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update slider
function Slider:update(dt)
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

-- Draw the slider
function Slider:draw()
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
    
    -- Draw slider
    local sliderX = this.x + (this.value / this.maxValue) * (this.width - this.options.sliderSize)
    love.graphics.setColor(this.options.sliderColor[1], this.options.sliderColor[2],
        this.options.sliderColor[3], this.options.sliderColor[4] * this.alpha)
    love.graphics.rectangle("fill", sliderX, this.y, this.options.sliderSize, this.height,
        this.options.cornerRadius)
    
    -- Draw text if enabled
    if this.options.showText then
        local text = string.format(this.options.textFormat, this.value)
        love.graphics.setColor(this.options.textColor[1], this.options.textColor[2],
            this.options.textColor[3], this.options.textColor[4] * this.alpha)
        love.graphics.printf(text, this.x + this.options.padding,
            this.y + (this.height - this.options.fontSize) / 2,
            this.width - (2 * this.options.padding), "center")
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Slider:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside slider
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        this.dragging = true
        this:updateValueFromMouse(x)
        return true
    end
    
    return false
end

-- Handle mouse move
function Slider:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Update value if dragging
    if this.dragging then
        this:updateValueFromMouse(x)
        return true
    end
    
    -- Check if mouse is inside slider
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        return true
    end
    
    return false
end

-- Handle mouse release
function Slider:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Stop dragging
    if this.dragging then
        this.dragging = false
        return true
    end
    
    return false
end

-- Handle key press
function Slider:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Sliders don't handle keyboard input
    return false
end

-- Handle text input
function Slider:textinput(text)
    if not this.visible then return false end
    
    -- Sliders don't handle text input
    return false
end

-- Update value from mouse position
function Slider:updateValueFromMouse(x)
    local sliderX = math.max(this.x, math.min(x, this.x + this.width))
    local progress = (sliderX - this.x) / this.width
    this:setValue(progress * this.maxValue)
end

return Slider 