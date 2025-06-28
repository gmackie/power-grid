-- ProgressBar UI component for Power Grid Digital
-- A progress bar that can show progress from 0 to 100

local class = require "lib.middleclass"

local ProgressBar = class('ProgressBar')

-- Create a new progress bar
function ProgressBar.new(options)
    local progressBar = ProgressBar()
    progressBar:initialize(options)
    return progressBar
end

-- Initialize the progress bar
function ProgressBar:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.fillColor = this.options.fillColor or {0.4, 0.8, 0.4, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.font = this.options.font or love.graphics.newFont(this.options.fontSize)
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    this.options.minValue = this.options.minValue or 0
    this.options.maxValue = this.options.maxValue or 100
    this.options.value = this.options.value or 0
    this.options.showValue = this.options.showValue or true
    this.options.showPercentage = this.options.showPercentage or true
    this.options.text = this.options.text or ""
    
    -- Progress bar state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.value = this.options.value
    this.onChange = this.options.onChange
    
    return this
end

-- Set progress bar position
function ProgressBar:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set progress bar size
function ProgressBar:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set progress bar visibility
function ProgressBar:setVisible(visible)
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

-- Get progress bar visibility
function ProgressBar:isVisible()
    return this.visible
end

-- Set background color
function ProgressBar:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function ProgressBar:setBorderColor(color)
    this.options.borderColor = color
end

-- Set fill color
function ProgressBar:setFillColor(color)
    this.options.fillColor = color
end

-- Set text color
function ProgressBar:setTextColor(color)
    this.options.textColor = color
end

-- Set font size
function ProgressBar:setFontSize(size)
    this.options.fontSize = size
    this.options.font = love.graphics.newFont(size)
end

-- Set padding
function ProgressBar:setPadding(padding)
    this.options.padding = padding
end

-- Set corner radius
function ProgressBar:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function ProgressBar:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function ProgressBar:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Set minimum value
function ProgressBar:setMinValue(value)
    this.options.minValue = value
    this.value = math.max(value, this.value)
end

-- Get minimum value
function ProgressBar:getMinValue()
    return this.options.minValue
end

-- Set maximum value
function ProgressBar:setMaxValue(value)
    this.options.maxValue = value
    this.value = math.min(value, this.value)
end

-- Get maximum value
function ProgressBar:getMaxValue()
    return this.options.maxValue
end

-- Set value
function ProgressBar:setValue(value)
    value = math.max(this.options.minValue, math.min(this.options.maxValue, value))
    if value ~= this.value then
        this.value = value
        if this.onChange then
            this.onChange(value)
        end
    end
end

-- Get value
function ProgressBar:getValue()
    return this.value
end

-- Set show value
function ProgressBar:setShowValue(show)
    this.options.showValue = show
end

-- Get show value
function ProgressBar:isShowValue()
    return this.options.showValue
end

-- Set show percentage
function ProgressBar:setShowPercentage(show)
    this.options.showPercentage = show
end

-- Get show percentage
function ProgressBar:isShowPercentage()
    return this.options.showPercentage
end

-- Set text
function ProgressBar:setText(text)
    this.options.text = text
end

-- Get text
function ProgressBar:getText()
    return this.options.text
end

-- Set onChange callback
function ProgressBar:setOnChange(callback)
    this.onChange = callback
end

-- Update progress bar
function ProgressBar:update(dt)
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

-- Draw the progress bar
function ProgressBar:draw()
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
    
    -- Draw fill
    if this.options.fillColor[4] > 0 then
        love.graphics.setColor(this.options.fillColor[1], this.options.fillColor[2],
            this.options.fillColor[3], this.options.fillColor[4] * this.alpha)
        local fillWidth = (this.value - this.options.minValue) /
            (this.options.maxValue - this.options.minValue) * this.width
        love.graphics.rectangle("fill", this.x, this.y, fillWidth, this.height,
            this.options.cornerRadius)
    end
    
    -- Draw text
    if this.options.text ~= "" or (this.options.showValue and this.options.showPercentage) then
        love.graphics.setColor(this.options.textColor[1], this.options.textColor[2],
            this.options.textColor[3], this.options.textColor[4] * this.alpha)
        love.graphics.setFont(this.options.font)
        
        local text = this.options.text
        if this.options.showValue and this.options.showPercentage then
            local percentage = (this.value - this.options.minValue) /
                (this.options.maxValue - this.options.minValue) * 100
            if text ~= "" then
                text = text .. " "
            end
            text = text .. string.format("%.1f%%", percentage)
        end
        
        local textWidth = this.options.font:getWidth(text)
        local textHeight = this.options.font:getHeight()
        love.graphics.print(text, this.x + (this.width - textWidth) / 2,
            this.y + (this.height - textHeight) / 2)
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function ProgressBar:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside progress bar
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        local value = this.options.minValue + (x - this.x) / this.width *
            (this.options.maxValue - this.options.minValue)
        this:setValue(value)
        return true
    end
    
    return false
end

-- Handle mouse move
function ProgressBar:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside progress bar
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        return true
    end
    
    return false
end

-- Handle mouse release
function ProgressBar:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside progress bar
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        return true
    end
    
    return false
end

-- Handle key press
function ProgressBar:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    if key == "left" then
        this:setValue(this.value - 1)
        return true
    elseif key == "right" then
        this:setValue(this.value + 1)
        return true
    end
    
    return false
end

-- Handle text input
function ProgressBar:textinput(text)
    return false
end

return ProgressBar 