-- Image UI component for Power Grid Digital
-- A component that displays an image

local class = require "lib.middleclass"

local Image = class('Image')

-- Create a new image
function Image.new(options)
    local image = Image()
    image:initialize(options)
    return image
end

-- Initialize the image
function Image:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.padding = this.options.padding or 0
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Image state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.image = nil
    this.quad = nil
    
    return this
end

-- Set image position
function Image:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set image size
function Image:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set image visibility
function Image:setVisible(visible)
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

-- Get image visibility
function Image:isVisible()
    return this.visible
end

-- Set image
function Image:setImage(image, quad)
    this.image = image
    this.quad = quad
end

-- Get image
function Image:getImage()
    return this.image, this.quad
end

-- Set background color
function Image:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function Image:setBorderColor(color)
    this.options.borderColor = color
end

-- Set padding
function Image:setPadding(padding)
    this.options.padding = padding
end

-- Set corner radius
function Image:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function Image:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function Image:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update image
function Image:update(dt)
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

-- Draw the image
function Image:draw()
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
    
    -- Draw image
    if this.image then
        love.graphics.setColor(1, 1, 1, this.alpha)
        if this.quad then
            love.graphics.draw(this.image, this.quad, this.x + this.options.padding,
                this.y + this.options.padding, 0, (this.width - (2 * this.options.padding)) / this.quad:getWidth(),
                (this.height - (2 * this.options.padding)) / this.quad:getHeight())
        else
            love.graphics.draw(this.image, this.x + this.options.padding,
                this.y + this.options.padding, 0, (this.width - (2 * this.options.padding)) / this.image:getWidth(),
                (this.height - (2 * this.options.padding)) / this.image:getHeight())
        end
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function Image:mousepressed(x, y, button)
    if not this.visible then return false end
    return false
end

-- Handle mouse move
function Image:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    return false
end

-- Handle mouse release
function Image:mousereleased(x, y, button)
    if not this.visible then return false end
    return false
end

-- Handle key press
function Image:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    return false
end

-- Handle text input
function Image:textinput(text)
    if not this.visible then return false end
    return false
end

return Image 