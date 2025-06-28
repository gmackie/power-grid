-- Tooltip UI component for Power Grid Digital
-- A tooltip that appears when hovering over a component

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Label = require "src.ui.label"

local Tooltip = class('Tooltip')

-- Create a new tooltip
function Tooltip.new(options)
    local tooltip = Tooltip()
    tooltip:initialize(options)
    return tooltip
end

-- Initialize the tooltip
function Tooltip:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.font = this.options.font or love.graphics.newFont(this.options.fontSize)
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    this.options.text = this.options.text or ""
    this.options.textAlignment = this.options.textAlignment or "left"
    this.options.offsetX = this.options.offsetX or 10
    this.options.offsetY = this.options.offsetY or 10
    
    -- Tooltip state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.targetX = 0
    this.targetY = 0
    
    -- Create text label
    if this.options.text ~= "" then
        this.text = Label.new({
            text = this.options.text,
            alignment = this.options.textAlignment,
            fontSize = this.options.fontSize
        })
    end
    
    return this
end

-- Set tooltip position
function Tooltip:setPosition(x, y)
    this.x = x
    this.y = y
    if this.text then
        this.text:setPosition(x + this.options.padding, y + this.options.padding)
    end
end

-- Set tooltip size
function Tooltip:setSize(width, height)
    this.width = width
    this.height = height
    if this.text then
        this.text:setSize(width - (2 * this.options.padding), height - (2 * this.options.padding))
    end
end

-- Set tooltip visibility
function Tooltip:setVisible(visible)
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

-- Get tooltip visibility
function Tooltip:isVisible()
    return this.visible
end

-- Set target position
function Tooltip:setTargetPosition(x, y)
    this.targetX = x
    this.targetY = y
    -- Update tooltip position
    this:setPosition(x + this.options.offsetX, y + this.options.offsetY)
end

-- Set background color
function Tooltip:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function Tooltip:setBorderColor(color)
    this.options.borderColor = color
end

-- Set text color
function Tooltip:setTextColor(color)
    this.options.textColor = color
end

-- Set font size
function Tooltip:setFontSize(size)
    this.options.fontSize = size
    this.options.font = love.graphics.newFont(size)
    if this.text then
        this.text:setFontSize(size)
    end
end

-- Set padding
function Tooltip:setPadding(padding)
    this.options.padding = padding
    if this.text then
        this.text:setPosition(this.x + padding, this.y + padding)
        this.text:setSize(this.width - (2 * padding), this.height - (2 * padding))
    end
end

-- Set corner radius
function Tooltip:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function Tooltip:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function Tooltip:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Set text
function Tooltip:setText(text)
    this.options.text = text
    if this.text then
        this.text:setText(text)
    end
end

-- Set text alignment
function Tooltip:setTextAlignment(alignment)
    this.options.textAlignment = alignment
    if this.text then
        this.text:setAlignment(alignment)
    end
end

-- Set offset
function Tooltip:setOffset(x, y)
    this.options.offsetX = x
    this.options.offsetY = y
    -- Update tooltip position
    this:setPosition(this.targetX + x, this.targetY + y)
end

-- Update tooltip
function Tooltip:update(dt)
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
    
    -- Update text
    if this.text then
        this.text:update(dt)
    end
end

-- Draw the tooltip
function Tooltip:draw()
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
    
    -- Draw text
    if this.text then
        this.text:draw()
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Tooltip:mousepressed(x, y, button)
    return false
end

-- Handle mouse move
function Tooltip:mousemoved(x, y, dx, dy)
    return false
end

-- Handle mouse release
function Tooltip:mousereleased(x, y, button)
    return false
end

-- Handle key press
function Tooltip:keypressed(key, scancode, isrepeat)
    return false
end

-- Handle text input
function Tooltip:textinput(text)
    return false
end

-- Handle window resize
function Tooltip:resize(width, height)
    -- Update tooltip position if it's the main tooltip
    if this.x == 0 and this.y == 0 then
        this:setPosition(width / 2, height / 2)
    end
end

return Tooltip 