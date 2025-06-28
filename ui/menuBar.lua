-- MenuBar UI component for Power Grid Digital
-- A menu bar that can contain menus and menu items

local class = require "lib.middleclass"

local MenuBar = class('MenuBar')

-- Create a new menu bar
function MenuBar.new(options)
    local menuBar = MenuBar()
    menuBar:initialize(options)
    return menuBar
end

-- Initialize the menu bar
function MenuBar:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.2, 0.8}
    this.options.borderColor = this.options.borderColor or {0.3, 0.3, 0.3, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.hoverColor = this.options.hoverColor or {0.3, 0.3, 0.3, 0.8}
    this.options.pressColor = this.options.pressColor or {0.4, 0.4, 0.4, 0.8}
    this.options.fontSize = this.options.fontSize or 14
    this.options.padding = this.options.padding or 5
    this.options.itemSpacing = this.options.itemSpacing or 10
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Menu bar state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    
    -- Menus
    this.menus = {}
    this.selectedMenuIndex = 0
    this.hoveredMenuIndex = 0
    
    return this
end

-- Set menu bar position
function MenuBar:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set menu bar size
function MenuBar:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set menu bar visibility
function MenuBar:setVisible(visible)
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

-- Get menu bar visibility
function MenuBar:isVisible()
    return this.visible
end

-- Add a menu
function MenuBar:addMenu(title, items)
    table.insert(this.menus, {
        title = title,
        items = items or {}
    })
end

-- Remove a menu
function MenuBar:removeMenu(index)
    if index >= 1 and index <= #this.menus then
        table.remove(this.menus, index)
        if this.selectedMenuIndex == index then
            this.selectedMenuIndex = 0
        elseif this.selectedMenuIndex > index then
            this.selectedMenuIndex = this.selectedMenuIndex - 1
        end
        if this.hoveredMenuIndex == index then
            this.hoveredMenuIndex = 0
        elseif this.hoveredMenuIndex > index then
            this.hoveredMenuIndex = this.hoveredMenuIndex - 1
        end
    end
end

-- Clear all menus
function MenuBar:clearMenus()
    this.menus = {}
    this.selectedMenuIndex = 0
    this.hoveredMenuIndex = 0
end

-- Get all menus
function MenuBar:getMenus()
    return this.menus
end

-- Set background color
function MenuBar:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function MenuBar:setBorderColor(color)
    this.options.borderColor = color
end

-- Set text color
function MenuBar:setTextColor(color)
    this.options.textColor = color
end

-- Set hover color
function MenuBar:setHoverColor(color)
    this.options.hoverColor = color
end

-- Set press color
function MenuBar:setPressColor(color)
    this.options.pressColor = color
end

-- Set font size
function MenuBar:setFontSize(size)
    this.options.fontSize = size
end

-- Set padding
function MenuBar:setPadding(padding)
    this.options.padding = padding
end

-- Set item spacing
function MenuBar:setItemSpacing(spacing)
    this.options.itemSpacing = spacing
end

-- Set fade in duration
function MenuBar:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function MenuBar:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update menu bar
function MenuBar:update(dt)
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

-- Draw the menu bar
function MenuBar:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw background
    love.graphics.setColor(this.options.backgroundColor[1], this.options.backgroundColor[2],
        this.options.backgroundColor[3], this.options.backgroundColor[4] * this.alpha)
    love.graphics.rectangle("fill", this.x, this.y, this.width, this.height)
    
    -- Draw border
    love.graphics.setColor(this.options.borderColor[1], this.options.borderColor[2],
        this.options.borderColor[3], this.options.borderColor[4] * this.alpha)
    love.graphics.rectangle("line", this.x, this.y, this.width, this.height)
    
    -- Draw menus
    local menuX = this.x + this.options.padding
    for i, menu in ipairs(this.menus) do
        -- Calculate menu width
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(menu.title)
        local menuWidth = textWidth + (2 * this.options.padding)
        
        -- Set menu colors
        local isSelected = i == this.selectedMenuIndex
        local isHovered = i == this.hoveredMenuIndex
        local backgroundColor = isSelected and this.options.pressColor or
            (isHovered and this.options.hoverColor or this.options.backgroundColor)
        
        -- Draw menu background
        love.graphics.setColor(backgroundColor[1], backgroundColor[2],
            backgroundColor[3], backgroundColor[4] * this.alpha)
        love.graphics.rectangle("fill", menuX, this.y, menuWidth, this.height)
        
        -- Draw menu text
        love.graphics.setColor(this.options.textColor[1], this.options.textColor[2],
            this.options.textColor[3], this.options.textColor[4] * this.alpha)
        love.graphics.printf(menu.title, menuX, this.y + (this.height - font:getHeight()) / 2,
            menuWidth, "center")
        
        menuX = menuX + menuWidth + this.options.itemSpacing
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function MenuBar:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is on a menu
    local menuX = this.x + this.options.padding
    for i, menu in ipairs(this.menus) do
        -- Calculate menu width
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(menu.title)
        local menuWidth = textWidth + (2 * this.options.padding)
        
        if x >= menuX and x <= menuX + menuWidth and
            y >= this.y and y <= this.y + this.height then
            this.selectedMenuIndex = i
            return true
        end
        
        menuX = menuX + menuWidth + this.options.itemSpacing
    end
    
    return false
end

-- Handle mouse move
function MenuBar:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Update hovered menu
    local menuX = this.x + this.options.padding
    this.hoveredMenuIndex = 0
    
    for i, menu in ipairs(this.menus) do
        -- Calculate menu width
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(menu.title)
        local menuWidth = textWidth + (2 * this.options.padding)
        
        if x >= menuX and x <= menuX + menuWidth and
            y >= this.y and y <= this.y + this.height then
            this.hoveredMenuIndex = i
            break
        end
        
        menuX = menuX + menuWidth + this.options.itemSpacing
    end
    
    return false
end

-- Handle mouse release
function MenuBar:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if release is on a menu
    local menuX = this.x + this.options.padding
    for i, menu in ipairs(this.menus) do
        -- Calculate menu width
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(menu.title)
        local menuWidth = textWidth + (2 * this.options.padding)
        
        if x >= menuX and x <= menuX + menuWidth and
            y >= this.y and y <= this.y + this.height and
            i == this.selectedMenuIndex then
            -- Menu was clicked
            this.selectedMenuIndex = 0
            return true
        end
        
        menuX = menuX + menuWidth + this.options.itemSpacing
    end
    
    return false
end

-- Handle key press
function MenuBar:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    return false
end

-- Handle text input
function MenuBar:textinput(text)
    if not this.visible then return false end
    return false
end

return MenuBar 