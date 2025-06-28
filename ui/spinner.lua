-- Spinner UI component for Power Grid Digital
-- A spinner that can show loading state

local class = require "lib.middleclass"

local Spinner = class('Spinner')

-- Create a new spinner
function Spinner.new(options)
    local spinner = Spinner()
    spinner:initialize(options)
    return spinner
end

-- Initialize the spinner
function Spinner:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.spinnerColor = this.options.spinnerColor or {1, 1, 1, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.font = this.options.font or love.graphics.newFont(this.options.fontSize)
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    this.options.size = this.options.size or 20
    this.options.text = this.options.text or ""
    this.options.speed = this.options.speed or 2
    this.options.angle = this.options.angle or 0
    
    -- Spinner state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.angle = this.options.angle
    
    return this
end

-- Set spinner position
function Spinner:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set spinner size
function Spinner:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set spinner visibility
function Spinner:setVisible(visible)
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

-- Get spinner visibility
function Spinner:isVisible()
    return this.visible
end

-- Set background color
function Spinner:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function Spinner:setBorderColor(color)
    this.options.borderColor = color
end

-- Set spinner color
function Spinner:setSpinnerColor(color)
    this.options.spinnerColor = color
end

-- Set text color
function Spinner:setTextColor(color)
    this.options.textColor = color
end

-- Set font size
function Spinner:setFontSize(size)
    this.options.fontSize = size
    this.options.font = love.graphics.newFont(size)
end

-- Set padding
function Spinner:setPadding(padding)
    this.options.padding = padding
end

-- Set corner radius
function Spinner:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function Spinner:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function Spinner:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Set size
function Spinner:setSize(size)
    this.options.size = size
end

-- Get size
function Spinner:getSize()
    return this.options.size
end

-- Set text
function Spinner:setText(text)
    this.options.text = text
end

-- Get text
function Spinner:getText()
    return this.options.text
end

-- Set speed
function Spinner:setSpeed(speed)
    this.options.speed = speed
end

-- Get speed
function Spinner:getSpeed()
    return this.options.speed
end

-- Set angle
function Spinner:setAngle(angle)
    this.angle = angle
end

-- Get angle
function Spinner:getAngle()
    return this.angle
end

-- Update spinner
function Spinner:update(dt)
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
    
    -- Update angle
    this.angle = this.angle + this.options.speed * dt
    if this.angle >= 2 * math.pi then
        this.angle = this.angle - 2 * math.pi
    end
end

-- Draw the spinner
function Spinner:draw()
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
    
    -- Draw spinner
    if this.options.spinnerColor[4] > 0 then
        love.graphics.setColor(this.options.spinnerColor[1], this.options.spinnerColor[2],
            this.options.spinnerColor[3], this.options.spinnerColor[4] * this.alpha)
        local centerX = this.x + this.width / 2
        local centerY = this.y + this.height / 2
        local radius = math.min(this.width, this.height) / 2 - this.options.padding
        
        -- Draw spinner segments
        local segments = 8
        local segmentAngle = 2 * math.pi / segments
        for i = 1, segments do
            local startAngle = this.angle + (i - 1) * segmentAngle
            local endAngle = startAngle + segmentAngle * 0.7
            love.graphics.arc("fill", centerX, centerY, radius, startAngle, endAngle)
        end
    end
    
    -- Draw text
    if this.options.text ~= "" then
        love.graphics.setColor(this.options.textColor[1], this.options.textColor[2],
            this.options.textColor[3], this.options.textColor[4] * this.alpha)
        love.graphics.setFont(this.options.font)
        local textWidth = this.options.font:getWidth(this.options.text)
        local textHeight = this.options.font:getHeight()
        love.graphics.print(this.options.text, this.x + (this.width - textWidth) / 2,
            this.y + this.height + this.options.padding)
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Spinner:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside spinner
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        return true
    end
    
    return false
end

-- Handle mouse move
function Spinner:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside spinner
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        return true
    end
    
    return false
end

-- Handle mouse release
function Spinner:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside spinner
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        return true
    end
    
    return false
end

-- Handle key press
function Spinner:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    return false
end

-- Handle text input
function Spinner:textinput(text)
    return false
end

return Spinner 