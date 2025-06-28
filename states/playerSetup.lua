local utf8 = require("utf8")

local playerSetup = {}

local players = {}
local nameInput = ""
local selectedColor = {1, 0, 0, 1}
local colors = {
    {1, 0, 0, 1}, {0, 0, 1, 1}, {0, 1, 0, 1}, {1, 1, 0, 1}, {1, 0.5, 0, 1}, {0.5, 0, 1, 1}
}
local colorRects = {}
local addButton = {x = 0, y = 0, w = 160, h = 48, hover = false, down = false}
local inputBox = {x = 0, y = 0, w = 260, h = 40, focused = false, hover = false}
local colorHover = nil
local startButton = {x = 0, y = 0, w = 160, h = 48, hover = false, down = false, enabled = false}
local removeRects = {}

function playerSetup:enter()
    players = {}
    nameInput = ""
    selectedColor = colors[1]
    addButton.hover, addButton.down = false, false
    inputBox.focused, inputBox.hover = false, false
    colorHover = nil
end

function playerSetup:update(dt)
    -- No-op for now
end

function playerSetup:draw()
    local ww, wh = love.graphics.getWidth(), love.graphics.getHeight()
    local cx = ww/2
    local topY = 80
    -- Layout
    inputBox.x = cx - inputBox.w/2
    inputBox.y = topY + 60
    local colorY = inputBox.y + inputBox.h + 20
    addButton.x = cx - addButton.w/2
    addButton.y = colorY + 60
    startButton.x = cx - startButton.w/2
    startButton.y = addButton.y + addButton.h + 16
    local listY = startButton.y + startButton.h + 30
    startButton.enabled = #players >= 2

    love.graphics.clear(0.12, 0.12, 0.15)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("Player Setup", 0, topY, ww, "center")

    -- Name input
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(inputBox.focused and {0.3, 0.3, 0.5, 1} or inputBox.hover and {0.25, 0.25, 0.35, 1} or {0.2, 0.2, 0.3, 1})
    love.graphics.rectangle("fill", inputBox.x, inputBox.y, inputBox.w, inputBox.h, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(inputBox.focused and 3 or 1)
    love.graphics.rectangle("line", inputBox.x, inputBox.y, inputBox.w, inputBox.h, 8)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(nameInput == "" and (inputBox.focused and "" or "Enter name...") or nameInput, inputBox.x+10, inputBox.y+10, inputBox.w-20, "left")

    -- Color selector
    colorRects = {}
    local usedColors = {}
    for _, p in ipairs(players) do
        for i, c in ipairs(colors) do
            if c[1] == p.color[1] and c[2] == p.color[2] and c[3] == p.color[3] and c[4] == p.color[4] then
                usedColors[i] = true
            end
        end
    end
    for i, color in ipairs(colors) do
        local x = cx - (#colors*38)/2 + (i-1)*38
        local y = colorY
        if usedColors[i] then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        else
            love.graphics.setColor(color)
        end
        love.graphics.rectangle("fill", x, y, 32, 32, 4)
        if color == selectedColor and not usedColors[i] then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x-2, y-2, 36, 36, 6)
        elseif colorHover == i and not usedColors[i] then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x-2, y-2, 36, 36, 6)
        end
        colorRects[i] = {x=x, y=y, w=32, h=32, color=color, disabled=usedColors[i]}
    end
    love.graphics.setLineWidth(1)

    -- Add Player button
    love.graphics.setColor(addButton.down and {0.2, 0.5, 0.2, 1} or addButton.hover and {0.4, 0.8, 0.4, 1} or {0.3, 0.7, 0.3, 1})
    love.graphics.rectangle("fill", addButton.x, addButton.y, addButton.w, addButton.h, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf("Add Player", addButton.x, addButton.y+12, addButton.w, "center")

    -- Start Game button
    love.graphics.setColor(
        not startButton.enabled and {0.4, 0.4, 0.4, 1} or startButton.down and {0.2, 0.5, 0.8, 1} or startButton.hover and {0.4, 0.7, 1, 1} or {0.3, 0.5, 0.8, 1}
    )
    love.graphics.rectangle("fill", startButton.x, startButton.y, startButton.w, startButton.h, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf("Start Game", startButton.x, startButton.y+12, startButton.w, "center")

    -- Player list with remove buttons
    love.graphics.setFont(love.graphics.newFont(18))
    local y = listY
    removeRects = {}
    for i, p in ipairs(players) do
        love.graphics.setColor(p.color)
        love.graphics.rectangle("fill", cx-100, y, 28, 28, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(p.name, cx-60, y+4)
        -- Draw remove button
        local rx, ry, rw, rh = cx+80, y, 28, 28
        love.graphics.setColor(0.7, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", rx, ry, rw, rh, 6)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.printf("X", rx, ry+4, rw, "center")
        removeRects[i] = {x=rx, y=ry, w=rw, h=rh}
        y = y + 36
    end
end

function playerSetup:textinput(t)
    if inputBox.focused then
        nameInput = nameInput .. t
    end
end

function playerSetup:keypressed(key)
    if inputBox.focused and key == "backspace" then
        local byteoffset = utf8.offset(nameInput, -1)
        if byteoffset then
            nameInput = string.sub(nameInput, 1, byteoffset - 1)
        end
    end
end

function playerSetup:mousemoved(x, y, dx, dy)
    -- Input box hover
    inputBox.hover = x >= inputBox.x and x <= inputBox.x+inputBox.w and y >= inputBox.y and y <= inputBox.y+inputBox.h
    -- Button hover
    addButton.hover = x >= addButton.x and x <= addButton.x+addButton.w and y >= addButton.y and y <= addButton.y+addButton.h
    startButton.hover = x >= startButton.x and x <= startButton.x+startButton.w and y >= startButton.y and y <= startButton.y+startButton.h
    -- Color hover
    colorHover = nil
    for i, rect in ipairs(colorRects) do
        if not rect.disabled and x >= rect.x and x <= rect.x+rect.w and y >= rect.y and y <= rect.y+rect.h then
            colorHover = i
        end
    end
end

function playerSetup:mousepressed(x, y, button)
    if button == 1 then
        -- Input box focus
        inputBox.focused = x >= inputBox.x and x <= inputBox.x+inputBox.w and y >= inputBox.y and y <= inputBox.y+inputBox.h
        -- Color selection
        for i, rect in ipairs(colorRects) do
            if not rect.disabled and x >= rect.x and x <= rect.x+rect.w and y >= rect.y and y <= rect.y+rect.h then
                selectedColor = rect.color
                return
            end
        end
        -- Add player
        if x >= addButton.x and x <= addButton.x+addButton.w and y >= addButton.y and y <= addButton.y+addButton.h then
            addButton.down = true
        end
        -- Start game
        if startButton.enabled and x >= startButton.x and x <= startButton.x+startButton.w and y >= startButton.y and y <= startButton.y+startButton.h then
            startButton.down = true
        end
        -- Remove player
        for i, rect in ipairs(removeRects) do
            if x >= rect.x and x <= rect.x+rect.w and y >= rect.y and y <= rect.y+rect.h then
                table.remove(players, i)
                return
            end
        end
    end
end

function playerSetup:mousereleased(x, y, button)
    if button == 1 then
        if addButton.down then
            addButton.down = false
            if x >= addButton.x and x <= addButton.x+addButton.w and y >= addButton.y and y <= addButton.y+addButton.h then
                if nameInput ~= "" then
                    table.insert(players, {name=nameInput, color=selectedColor})
                    nameInput = ""
                end
            end
        end
        if startButton.down then
            startButton.down = false
            if startButton.enabled and x >= startButton.x and x <= startButton.x+startButton.w and y >= startButton.y and y <= startButton.y+startButton.h then
                changeState("game", players)
            end
        end
    end
end

return playerSetup 