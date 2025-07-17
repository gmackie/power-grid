-- Styled Panel Component with theme and visual effects
local StyledPanel = {}
StyledPanel.__index = StyledPanel

local Theme = require("ui.theme")
local AssetLoader = require("assets.asset_loader")

function StyledPanel.new(x, y, width, height, options)
    local self = setmetatable({}, StyledPanel)
    
    options = options or {}
    
    -- Basic properties
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    
    -- Style options
    self.style = options.style or "default"  -- default, elevated, transparent
    self.title = options.title
    self.showHeader = options.showHeader ~= false and self.title ~= nil
    self.headerHeight = options.headerHeight or 40
    
    -- Visual properties
    self.visible = true
    self.alpha = options.alpha or 1.0
    self.targetAlpha = self.alpha
    self.scale = 1.0
    self.targetScale = 1.0
    
    -- Animation
    self.animationSpeed = options.animationSpeed or 5.0
    
    -- Content padding
    self.padding = options.padding or Theme.layout.padding
    
    -- Glow effect
    self.glowAlpha = 0
    self.glowColor = options.glowColor or Theme.colors.primary
    
    -- Load panel asset if available
    local size = width > 400 and "large" or (width > 300 and "medium" or "small")
    self.backgroundAsset = AssetLoader.load("panel_" .. size)
    
    -- Fonts
    self.titleFont = love.graphics.newFont(Theme.fonts.large)
    self.contentFont = love.graphics.newFont(Theme.fonts.medium)
    
    -- Content
    self.content = {}
    
    return self
end

function StyledPanel:update(dt)
    if not self.visible then return end
    
    -- Update animations
    self.alpha = self.alpha + (self.targetAlpha - self.alpha) * self.animationSpeed * dt
    self.scale = self.scale + (self.targetScale - self.scale) * self.animationSpeed * dt
    
    -- Update glow effect
    if self.glowAlpha > 0 then
        self.glowAlpha = math.max(0, self.glowAlpha - dt)
    end
end

function StyledPanel:draw()
    if not self.visible or self.alpha <= 0 then return end
    
    love.graphics.push()
    
    -- Apply scale
    local centerX = self.x + self.width / 2
    local centerY = self.y + self.height / 2
    love.graphics.translate(centerX, centerY)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-centerX, -centerY)
    
    -- Draw glow effect
    if self.glowAlpha > 0 then
        love.graphics.setColor(self.glowColor[1], self.glowColor[2], self.glowColor[3], self.glowAlpha * 0.3)
        for i = 1, 3 do
            love.graphics.rectangle("line", self.x - i*2, self.y - i*2, 
                                  self.width + i*4, self.height + i*4, 
                                  Theme.layout.radiusMedium + i)
        end
    end
    
    -- Draw panel background
    if self.backgroundAsset then
        -- Use asset with 9-slice scaling
        love.graphics.setColor(1, 1, 1, self.alpha)
        local scaleX = self.width / self.backgroundAsset:getWidth()
        local scaleY = self.height / self.backgroundAsset:getHeight()
        love.graphics.draw(self.backgroundAsset, self.x, self.y, 0, scaleX, scaleY)
    else
        -- Use theme drawing
        local panelStyle = Theme.panel[self.style]
        
        -- Shadow
        love.graphics.setColor(Theme.effects.shadowColor[1], Theme.effects.shadowColor[2], 
                              Theme.effects.shadowColor[3], Theme.effects.shadowColor[4] * self.alpha)
        love.graphics.rectangle("fill", self.x + 3, self.y + 3, self.width, self.height, Theme.layout.radiusMedium)
        
        -- Background
        love.graphics.setColor(panelStyle.bg[1], panelStyle.bg[2], panelStyle.bg[3], panelStyle.bg[4] * self.alpha)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, Theme.layout.radiusMedium)
        
        -- Inner shadow (top)
        love.graphics.setColor(0, 0, 0, 0.2 * self.alpha)
        love.graphics.rectangle("fill", self.x, self.y, self.width, 2, Theme.layout.radiusMedium, Theme.layout.radiusMedium)
        
        -- Border
        love.graphics.setColor(panelStyle.border[1], panelStyle.border[2], 
                              panelStyle.border[3], panelStyle.border[4] * self.alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, Theme.layout.radiusMedium)
    end
    
    -- Draw header if present
    if self.showHeader then
        local panelStyle = Theme.panel[self.style]
        
        -- Header background
        love.graphics.setColor(panelStyle.headerBg[1], panelStyle.headerBg[2], 
                              panelStyle.headerBg[3], panelStyle.headerBg[4] * self.alpha)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.headerHeight, 
                               Theme.layout.radiusMedium, Theme.layout.radiusMedium)
        
        -- Header separator
        love.graphics.setColor(panelStyle.border[1], panelStyle.border[2], 
                              panelStyle.border[3], panelStyle.border[4] * self.alpha * 0.5)
        love.graphics.line(self.x, self.y + self.headerHeight, 
                          self.x + self.width, self.y + self.headerHeight)
        
        -- Title text
        if self.title then
            love.graphics.setFont(self.titleFont)
            love.graphics.setColor(panelStyle.headerText[1], panelStyle.headerText[2], 
                                  panelStyle.headerText[3], panelStyle.headerText[4] * self.alpha)
            love.graphics.printf(self.title, self.x + self.padding, 
                               self.y + (self.headerHeight - self.titleFont:getHeight()) / 2,
                               self.width - self.padding * 2, "center")
        end
    end
    
    -- Draw content
    self:drawContent()
    
    love.graphics.pop()
end

function StyledPanel:drawContent()
    -- Override this method in subclasses or set content items
    love.graphics.setScissor(self.x + self.padding, 
                            self.y + (self.showHeader and self.headerHeight or 0) + self.padding,
                            self.width - self.padding * 2,
                            self.height - (self.showHeader and self.headerHeight or 0) - self.padding * 2)
    
    -- Draw any registered content
    for _, item in ipairs(self.content) do
        if item.draw then
            item:draw()
        end
    end
    
    love.graphics.setScissor()
end

function StyledPanel:addContent(item)
    table.insert(self.content, item)
end

function StyledPanel:clearContent()
    self.content = {}
end

function StyledPanel:flash(color)
    self.glowColor = color or Theme.colors.primary
    self.glowAlpha = 1.0
end

function StyledPanel:show(animated)
    self.visible = true
    if animated then
        self.alpha = 0
        self.targetAlpha = 1.0
        self.scale = 0.9
        self.targetScale = 1.0
    else
        self.alpha = 1.0
        self.targetAlpha = 1.0
        self.scale = 1.0
        self.targetScale = 1.0
    end
end

function StyledPanel:hide(animated)
    if animated then
        self.targetAlpha = 0
        self.targetScale = 0.9
    else
        self.visible = false
        self.alpha = 0
    end
end

function StyledPanel:getContentBounds()
    local contentY = self.y + (self.showHeader and self.headerHeight or 0) + self.padding
    return self.x + self.padding, 
           contentY,
           self.width - self.padding * 2,
           self.height - (contentY - self.y) - self.padding
end

return StyledPanel