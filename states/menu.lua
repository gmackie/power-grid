local menu = {}
local State = require("state")
local UI = require("ui")

function menu:enter()
    print("Menu state entered")
end

function menu:update(dt)
    -- No-op for now
end

function menu:draw()
    love.graphics.clear(0.15, 0.15, 0.18)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.printf("Power Grid Digital", 0, 100, love.graphics.getWidth(), "center")
    
    -- Draw button
    love.graphics.setColor(0.3, 0.7, 0.3, 1)
    love.graphics.rectangle("fill", 400, 300, 200, 50, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Pass and Play", 400, 310, 200, "center")
end

function menu:mousepressed(x, y, button)
    if button == 1 then
        if x >= 400 and x <= 600 and y >= 300 and y <= 350 then
            changeState("playerSetup")
        end
    end
end

return menu 