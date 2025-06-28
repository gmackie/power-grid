-- TabView UI component for Power Grid Digital
-- A container that displays content in tabs

local class = require "lib.middleclass"

local TabView = class('TabView')

-- Create a new tab view
function TabView.new(options)
    local tabView = TabView()
    tabView:initialize(options)
    return tabView
end

-- Initialize the tab view
function TabView:initialize(options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.2, 0.8}
    this.options.borderColor = this.options.borderColor or {0.3, 0.3, 0.3, 1}
    this.options.tabBackgroundColor = this.options.tabBackgroundColor or {0.3, 0.3, 0.3, 0.8}
    this.options.tabBorderColor = this.options.tabBorderColor or {0.4, 0.4, 0.4, 1}
    this.options.tabTextColor = this.options.tabTextColor or {1, 1, 1, 1}
    this.options.selectedTabBackgroundColor = this.options.selectedTabBackgroundColor or {0.4, 0.4, 0.4, 0.8}
    this.options.selectedTabBorderColor = this.options.selectedTabBorderColor or {0.5, 0.5, 0.5, 1}
    this.options.selectedTabTextColor = this.options.selectedTabTextColor or {1, 1, 1, 1}
    this.options.tabHeight = this.options.tabHeight or 30
    this.options.tabPadding = this.options.tabPadding or 10
    this.options.cornerRadius = this.options.cornerRadius or 5
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Tab view state
    this.visible = false
    this.alpha = 0
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.x = 0
    this.y = 0
    this.width = 0
    this.height = 0
    
    -- Tabs
    this.tabs = {}
    this.selectedTabIndex = 1
    
    return this
end

-- Set tab view position
function TabView:setPosition(x, y)
    this.x = x
    this.y = y
end

-- Set tab view size
function TabView:setSize(width, height)
    this.width = width
    this.height = height
end

-- Set tab view visibility
function TabView:setVisible(visible)
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

-- Get tab view visibility
function TabView:isVisible()
    return this.visible
end

-- Add a tab
function TabView:addTab(title, content)
    table.insert(this.tabs, {
        title = title,
        content = content
    })
end

-- Remove a tab
function TabView:removeTab(index)
    if index >= 1 and index <= #this.tabs then
        table.remove(this.tabs, index)
        if this.selectedTabIndex > #this.tabs then
            this.selectedTabIndex = #this.tabs
        end
    end
end

-- Clear all tabs
function TabView:clearTabs()
    this.tabs = {}
    this.selectedTabIndex = 1
end

-- Get all tabs
function TabView:getTabs()
    return this.tabs
end

-- Set selected tab
function TabView:setSelectedTab(index)
    if index >= 1 and index <= #this.tabs then
        this.selectedTabIndex = index
    end
end

-- Get selected tab
function TabView:getSelectedTab()
    return this.tabs[this.selectedTabIndex]
end

-- Set background color
function TabView:setBackgroundColor(color)
    this.options.backgroundColor = color
end

-- Set border color
function TabView:setBorderColor(color)
    this.options.borderColor = color
end

-- Set tab background color
function TabView:setTabBackgroundColor(color)
    this.options.tabBackgroundColor = color
end

-- Set tab border color
function TabView:setTabBorderColor(color)
    this.options.tabBorderColor = color
end

-- Set tab text color
function TabView:setTabTextColor(color)
    this.options.tabTextColor = color
end

-- Set selected tab background color
function TabView:setSelectedTabBackgroundColor(color)
    this.options.selectedTabBackgroundColor = color
end

-- Set selected tab border color
function TabView:setSelectedTabBorderColor(color)
    this.options.selectedTabBorderColor = color
end

-- Set selected tab text color
function TabView:setSelectedTabTextColor(color)
    this.options.selectedTabTextColor = color
end

-- Set tab height
function TabView:setTabHeight(height)
    this.options.tabHeight = height
end

-- Set tab padding
function TabView:setTabPadding(padding)
    this.options.tabPadding = padding
end

-- Set corner radius
function TabView:setCornerRadius(radius)
    this.options.cornerRadius = radius
end

-- Set fade in duration
function TabView:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function TabView:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update tab view
function TabView:update(dt)
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
    
    -- Update selected tab content
    local selectedTab = this:getSelectedTab()
    if selectedTab and selectedTab.content then
        selectedTab.content:update(dt)
    end
end

-- Draw the tab view
function TabView:draw()
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
    
    -- Draw tabs
    local tabX = this.x
    for i, tab in ipairs(this.tabs) do
        -- Calculate tab width
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(tab.title)
        local tabWidth = textWidth + (2 * this.options.tabPadding)
        
        -- Set tab colors
        local isSelected = i == this.selectedTabIndex
        local backgroundColor = isSelected and this.options.selectedTabBackgroundColor or this.options.tabBackgroundColor
        local borderColor = isSelected and this.options.selectedTabBorderColor or this.options.tabBorderColor
        local textColor = isSelected and this.options.selectedTabTextColor or this.options.tabTextColor
        
        -- Draw tab background
        love.graphics.setColor(backgroundColor[1], backgroundColor[2],
            backgroundColor[3], backgroundColor[4] * this.alpha)
        love.graphics.rectangle("fill", tabX, this.y, tabWidth, this.options.tabHeight,
            this.options.cornerRadius, this.options.cornerRadius, 0, 0)
        
        -- Draw tab border
        love.graphics.setColor(borderColor[1], borderColor[2],
            borderColor[3], borderColor[4] * this.alpha)
        love.graphics.rectangle("line", tabX, this.y, tabWidth, this.options.tabHeight,
            this.options.cornerRadius, this.options.cornerRadius, 0, 0)
        
        -- Draw tab text
        love.graphics.setColor(textColor[1], textColor[2],
            textColor[3], textColor[4] * this.alpha)
        love.graphics.printf(tab.title, tabX, this.y + (this.options.tabHeight - font:getHeight()) / 2,
            tabWidth, "center")
        
        tabX = tabX + tabWidth
    end
    
    -- Draw selected tab content
    local selectedTab = this:getSelectedTab()
    if selectedTab and selectedTab.content then
        selectedTab.content:draw()
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function TabView:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is on a tab
    local tabX = this.x
    for i, tab in ipairs(this.tabs) do
        -- Calculate tab width
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(tab.title)
        local tabWidth = textWidth + (2 * this.options.tabPadding)
        
        if x >= tabX and x <= tabX + tabWidth and
            y >= this.y and y <= this.y + this.options.tabHeight then
            this.selectedTabIndex = i
            return true
        end
        
        tabX = tabX + tabWidth
    end
    
    -- Forward click to selected tab content
    local selectedTab = this:getSelectedTab()
    if selectedTab and selectedTab.content then
        return selectedTab.content:mousepressed(x, y, button)
    end
    
    return false
end

-- Handle mouse move
function TabView:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Forward mouse move to selected tab content
    local selectedTab = this:getSelectedTab()
    if selectedTab and selectedTab.content then
        return selectedTab.content:mousemoved(x, y, dx, dy)
    end
    
    return false
end

-- Handle mouse release
function TabView:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Forward mouse release to selected tab content
    local selectedTab = this:getSelectedTab()
    if selectedTab and selectedTab.content then
        return selectedTab.content:mousereleased(x, y, button)
    end
    
    return false
end

-- Handle key press
function TabView:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Forward key press to selected tab content
    local selectedTab = this:getSelectedTab()
    if selectedTab and selectedTab.content then
        return selectedTab.content:keypressed(key, scancode, isrepeat)
    end
    
    return false
end

-- Handle text input
function TabView:textinput(text)
    if not this.visible then return false end
    
    -- Forward text input to selected tab content
    local selectedTab = this:getSelectedTab()
    if selectedTab and selectedTab.content then
        return selectedTab.content:textinput(text)
    end
    
    return false
end

return TabView 