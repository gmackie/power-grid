-- Button UI component for Power Grid Digital
-- A button that can be clicked

local Button = {}
Button.__index = Button

function Button.new(text, x, y, w, h)
    local self = setmetatable({}, Button)
    self.text = text
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.hovered = false
    self.down = false
    self.visible = true
    self.enabled = true
    self.backgroundColor = {0.3, 0.7, 0.3, 1}
    self.hoverColor = {0.4, 0.8, 0.4, 1}
    self.pressColor = {0.2, 0.5, 0.2, 1}
    self.textColor = {1, 1, 1, 1}
    self.cornerRadius = 8
    self.onClick = nil
    return self
end

function Button:update(mx, my)
    self.hovered = self:isHovered(mx, my)
end

function Button:draw()
    if not self.visible then return end
    
    local bgColor, textColor
    if self.down then
        bgColor = self.pressColor
        textColor = self.textColor
    elseif self.hovered then
        bgColor = self.hoverColor
        textColor = self.textColor
    else
        bgColor = self.backgroundColor
        textColor = self.textColor
    end
    
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, self.cornerRadius)
    
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, self.cornerRadius)
    
    -- Draw button text
    love.graphics.setColor(textColor)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf(self.text, self.x, self.y + self.h/2 - 12, self.w, "center")
end

function Button:isHovered(mx, my)
    return mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
end

function Button:mousepressed(x, y, button)
    if not self.visible or not self.enabled then return false end
    
    if self:isHovered(x, y) then
        self.down = true
        return true
    end
    return false
end

function Button:mousereleased(x, y, button)
    if not self.visible or not self.enabled then return false end
    
    if self.down and self:isHovered(x, y) then
        self.down = false
        if self.onClick then
            self.onClick()
        end
        return true
    end
    
    self.down = false
    return false
end

function Button:mousemoved(x, y)
    if not self.visible or not self.enabled then return false end
    
    self.hovered = self:isHovered(x, y)
    return self.hovered
end

function Button:setOnClick(handler)
    self.onClick = handler
end

function Button:setEnabled(enabled)
    self.enabled = enabled
end

function Button:setVisible(visible)
    self.visible = visible
end

return Button 