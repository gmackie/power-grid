-- ScrollView UI component for Power Grid Digital
-- A container that can be scrolled vertically and horizontally

local class = require "lib.middleclass"

local ScrollView = class('ScrollView')

-- Create a new scroll view
function ScrollView.new(options)
    local scrollView = ScrollView()
    scrollView:initialize(options)
    return scrollView
end

-- Initialize the scroll view
function ScrollView:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0, 0, 0, 0}
    this.options.borderColor = this.options.borderColor or {0, 0, 0, 0}
    this.options.scrollBarColor = this.options.scrollBarColor or {0.5, 0.5, 0.5, 0.5}
    this.options.scrollBarHoverColor = this.options.scrollBarHoverColor or {0.7, 0.7, 0.7, 0.7}
    this.options.scrollBarPressColor = this.options.scrollBarPressColor or {0.9, 0.9, 0.9, 0.9}
    this.options.scrollBarWidth = this.options.scrollBarWidth or 10
    this.options.padding = this.options.padding or 0
    this.options.cornerRadius = this.options.cornerRadius or 0
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Scroll view state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    this.contentWidth = 0
    this.contentHeight = 0
    this.scrollX = 0
    this.scrollY = 0
    this.children = {}
    
    -- Scroll bar state
    this.horizontalScrollBarVisible = false
    this.verticalScrollBarVisible = false
    this.horizontalScrollBarHovered = false
    this.verticalScrollBarHovered = false
    this.horizontalScrollBarPressed = false
    this.verticalScrollBarPressed = false
    this.horizontalScrollBarX = 0
    this.horizontalScrollBarY = 0
    this.horizontalScrollBarWidth = 0
    this.horizontalScrollBarHeight = 0
    this.verticalScrollBarX = 0
    this.verticalScrollBarY = 0
    this.verticalScrollBarWidth = 0
    this.verticalScrollBarHeight = 0
    
    return this
end

-- Set scroll view position
function ScrollView:setPosition(x, y)
    this.x = x
    this.y = y
    this:updateScrollBars()
end

-- Set scroll view size
function ScrollView:setSize(width, height)
    this.width = width
    this.height = height
    this:updateScrollBars()
end

-- Set scroll view visibility
function ScrollView:setVisible(visible)
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

-- Get scroll view visibility
function ScrollView:isVisible()
    return this.visible
end

-- Add a child component
function ScrollView:addChild(child)
    table.insert(this.children, child)
    this:updateContentSize()
end

-- Remove a child component
function ScrollView:removeChild(child)
    for i, c in ipairs(this.children) do
        if c == child then
            table.remove(this.children, i)
            break
        end
    end
    this:updateContentSize()
end

-- Clear all child components
function ScrollView:clearChildren()
    this.children = {}
    this:updateContentSize()
end

-- Get all child components
function ScrollView:getChildren()
    return this.children
end

-- Set background color
function ScrollView:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function ScrollView:setBorderColor(color)
    this.options.borderColor = color
end

-- Set scroll bar color
function ScrollView:setScrollBarColor(color)
    this.options.scrollBarColor = color
end

-- Set scroll bar hover color
function ScrollView:setScrollBarHoverColor(color)
    this.options.scrollBarHoverColor = color
end

-- Set scroll bar press color
function ScrollView:setScrollBarPressColor(color)
    this.options.scrollBarPressColor = color
end

-- Set scroll bar width
function ScrollView:setScrollBarWidth(width)
    this.options.scrollBarWidth = width
    this:updateScrollBars()
end

-- Set padding
function ScrollView:setPadding(padding)
    this.options.padding = padding
    this:updateContentSize()
end

-- Set corner radius
function ScrollView:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function ScrollView:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function ScrollView:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Set scroll position
function ScrollView:setScrollPosition(x, y)
    this.scrollX = math.max(0, math.min(x, this.contentWidth - this.width))
    this.scrollY = math.max(0, math.min(y, this.contentHeight - this.height))
    this:updateScrollBars()
end

-- Get scroll position
function ScrollView:getScrollPosition()
    return this.scrollX, this.scrollY
end

-- Update content size
function ScrollView:updateContentSize()
    this.contentWidth = 0
    this.contentHeight = 0
    
    for _, child in ipairs(this.children) do
        if child.width and child.height then
            this.contentWidth = math.max(this.contentWidth, child.x + child.width)
            this.contentHeight = math.max(this.contentHeight, child.y + child.height)
        end
    end
    
    this.contentWidth = this.contentWidth + (2 * this.options.padding)
    this.contentHeight = this.contentHeight + (2 * this.options.padding)
    
    this:updateScrollBars()
end

-- Update scroll bars
function ScrollView:updateScrollBars()
    -- Update horizontal scroll bar
    this.horizontalScrollBarVisible = this.contentWidth > this.width
    if this.horizontalScrollBarVisible then
        this.horizontalScrollBarX = this.x
        this.horizontalScrollBarY = this.y + this.height - this.options.scrollBarWidth
        this.horizontalScrollBarWidth = this.width
        this.horizontalScrollBarHeight = this.options.scrollBarWidth
    end
    
    -- Update vertical scroll bar
    this.verticalScrollBarVisible = this.contentHeight > this.height
    if this.verticalScrollBarVisible then
        this.verticalScrollBarX = this.x + this.width - this.options.scrollBarWidth
        this.verticalScrollBarY = this.y
        this.verticalScrollBarWidth = this.options.scrollBarWidth
        this.verticalScrollBarHeight = this.height
    end
end

-- Update scroll view
function ScrollView:update(dt)
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
    
    -- Update children
    for _, child in ipairs(this.children) do
        if child.update then
            child:update(dt)
        end
    end
end

-- Draw the scroll view
function ScrollView:draw()
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
    
    -- Set scissor for content
    love.graphics.setScissor(this.x, this.y, this.width, this.height)
    
    -- Draw children
    for _, child in ipairs(this.children) do
        if child.draw then
            child:draw()
        end
    end
    
    -- Reset scissor
    love.graphics.setScissor()
    
    -- Draw horizontal scroll bar
    if this.horizontalScrollBarVisible then
        local color = this.options.scrollBarColor
        if this.horizontalScrollBarPressed then
            color = this.options.scrollBarPressColor
        elseif this.horizontalScrollBarHovered then
            color = this.options.scrollBarHoverColor
        end
        love.graphics.setColor(color[1], color[2], color[3], color[4] * this.alpha)
        love.graphics.rectangle("fill", this.horizontalScrollBarX, this.horizontalScrollBarY,
            this.horizontalScrollBarWidth, this.horizontalScrollBarHeight)
    end
    
    -- Draw vertical scroll bar
    if this.verticalScrollBarVisible then
        local color = this.options.scrollBarColor
        if this.verticalScrollBarPressed then
            color = this.options.scrollBarPressColor
        elseif this.verticalScrollBarHovered then
            color = this.options.scrollBarHoverColor
        end
        love.graphics.setColor(color[1], color[2], color[3], color[4] * this.alpha)
        love.graphics.rectangle("fill", this.verticalScrollBarX, this.verticalScrollBarY,
            this.verticalScrollBarWidth, this.verticalScrollBarHeight)
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function ScrollView:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside scroll view
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Check horizontal scroll bar
        if this.horizontalScrollBarVisible and
            x >= this.horizontalScrollBarX and x <= this.horizontalScrollBarX + this.horizontalScrollBarWidth and
            y >= this.horizontalScrollBarY and y <= this.horizontalScrollBarY + this.horizontalScrollBarHeight then
            this.horizontalScrollBarPressed = true
            return true
        end
        
        -- Check vertical scroll bar
        if this.verticalScrollBarVisible and
            x >= this.verticalScrollBarX and x <= this.verticalScrollBarX + this.verticalScrollBarWidth and
            y >= this.verticalScrollBarY and y <= this.verticalScrollBarY + this.verticalScrollBarHeight then
            this.verticalScrollBarPressed = true
            return true
        end
        
        -- Forward event to children
        for _, child in ipairs(this.children) do
            if child.mousepressed then
                if child:mousepressed(x - this.scrollX, y - this.scrollY, button) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle mouse move
function ScrollView:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside scroll view
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Check horizontal scroll bar
        if this.horizontalScrollBarVisible then
            this.horizontalScrollBarHovered = x >= this.horizontalScrollBarX and
                x <= this.horizontalScrollBarX + this.horizontalScrollBarWidth and
                y >= this.horizontalScrollBarY and y <= this.horizontalScrollBarY + this.horizontalScrollBarHeight
        end
        
        -- Check vertical scroll bar
        if this.verticalScrollBarVisible then
            this.verticalScrollBarHovered = x >= this.verticalScrollBarX and
                x <= this.verticalScrollBarX + this.verticalScrollBarWidth and
                y >= this.verticalScrollBarY and y <= this.verticalScrollBarY + this.verticalScrollBarHeight
        end
        
        -- Handle scrolling
        if this.horizontalScrollBarPressed then
            local scrollWidth = this.contentWidth - this.width
            local barWidth = this.horizontalScrollBarWidth
            local ratio = (x - this.horizontalScrollBarX) / barWidth
            this.scrollX = ratio * scrollWidth
            this:updateScrollBars()
            return true
        end
        
        if this.verticalScrollBarPressed then
            local scrollHeight = this.contentHeight - this.height
            local barHeight = this.verticalScrollBarHeight
            local ratio = (y - this.verticalScrollBarY) / barHeight
            this.scrollY = ratio * scrollHeight
            this:updateScrollBars()
            return true
        end
        
        -- Forward event to children
        for _, child in ipairs(this.children) do
            if child.mousemoved then
                if child:mousemoved(x - this.scrollX, y - this.scrollY, dx, dy) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle mouse release
function ScrollView:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside scroll view
    if x >= this.x and x <= this.x + this.width and
        y >= this.y and y <= this.y + this.height then
        -- Reset scroll bar states
        this.horizontalScrollBarPressed = false
        this.verticalScrollBarPressed = false
        
        -- Forward event to children
        for _, child in ipairs(this.children) do
            if child.mousereleased then
                if child:mousereleased(x - this.scrollX, y - this.scrollY, button) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle key press
function ScrollView:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Forward event to children
    for _, child in ipairs(this.children) do
        if child.keypressed then
            if child:keypressed(key, scancode, isrepeat) then
                return true
            end
        end
    end
    
    return false
end

-- Handle text input
function ScrollView:textinput(text)
    if not this.visible then return false end
    
    -- Forward event to children
    for _, child in ipairs(this.children) do
        if child.textinput then
            if child:textinput(text) then
                return true
            end
        end
    end
    
    return false
end

return ScrollView 