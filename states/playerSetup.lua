local utf8 = require("utf8")

local playerSetup = {}
local MobileButton = require("ui.mobile_button")
local MobileConfig = require("mobile.mobile_config")

local players = {}
local nameInput = ""
local selectedColor = {1, 0, 0, 1}
local colors = {
    {1, 0, 0, 1}, {0, 0, 1, 1}, {0, 1, 0, 1}, {1, 1, 0, 1}, {1, 0.5, 0, 1}, {0.5, 0, 1, 1}
}
local colorRects = {}
local inputBox = {x = 0, y = 0, w = 260, h = 40, focused = false, hover = false}
local colorHover = nil
local removeRects = {}

-- Mobile buttons
local addPlayerButton = nil
local startGameButton = nil
local removeButtons = {}

function playerSetup:enter()
    players = {}
    nameInput = ""
    selectedColor = colors[1]
    inputBox.focused, inputBox.hover = false, false
    colorHover = nil
    
    -- Initialize mobile buttons
    local screenConfig = MobileConfig.getScreenConfig()
    local buttonConfig = MobileConfig.getButtonConfig()
    local layout = MobileConfig.getLayout()
    
    local buttonWidth = math.min(buttonConfig.minWidth * 2, screenConfig.width - layout.margin * 2)
    local buttonHeight = buttonConfig.minHeight
    local centerX = screenConfig.width / 2
    
    addPlayerButton = MobileButton.new("Add Player", 
        centerX - buttonWidth/2, 0, buttonWidth, buttonHeight)  -- Y will be set in draw
    addPlayerButton.onTap = function() self:addPlayer() end
    
    startGameButton = MobileButton.new("Start Game", 
        centerX - buttonWidth/2, 0, buttonWidth, buttonHeight)  -- Y will be set in draw
    startGameButton.onTap = function() self:startGame() end
    
    removeButtons = {}
end

function playerSetup:update(dt)
    -- Update mobile buttons
    if addPlayerButton then
        addPlayerButton:update(dt)
    end
    if startGameButton then
        startGameButton:update(dt)
    end
    for _, btn in ipairs(removeButtons) do
        btn:update(dt)
    end
end

function playerSetup:draw()
    local screenConfig = MobileConfig.getScreenConfig()
    local fontSizes = MobileConfig.getFontSizes()
    local layout = MobileConfig.getLayout()
    
    local cx = screenConfig.width / 2
    local topY = screenConfig.height * 0.1
    
    -- Responsive layout
    local inputWidth = math.min(300, screenConfig.width - layout.margin * 2)
    inputBox.x = cx - inputWidth/2
    inputBox.y = topY + fontSizes.title + layout.spacing * 3
    inputBox.w = inputWidth
    inputBox.h = MobileConfig.getTouchTargetSize()
    
    local colorY = inputBox.y + inputBox.h + layout.spacing * 2
    local buttonY = colorY + 60 + layout.spacing * 2
    local listY = buttonY + MobileConfig.getTouchTargetSize() * 2 + layout.spacing * 3
    
    -- Update button positions
    if addPlayerButton then
        addPlayerButton:setPosition(cx - addPlayerButton.width/2, buttonY)
    end
    if startGameButton then
        startGameButton:setPosition(cx - startGameButton.width/2, buttonY + MobileConfig.getTouchTargetSize() + layout.spacing)
        startGameButton:setEnabled(#players >= 2)
    end

    love.graphics.clear(0.12, 0.12, 0.15)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(fontSizes.title))
    love.graphics.printf("Player Setup", 0, topY, screenConfig.width, "center")

    -- Name input
    love.graphics.setFont(love.graphics.newFont(fontSizes.medium))
    love.graphics.setColor(inputBox.focused and {0.3, 0.3, 0.5, 1} or inputBox.hover and {0.25, 0.25, 0.35, 1} or {0.2, 0.2, 0.3, 1})
    love.graphics.rectangle("fill", inputBox.x, inputBox.y, inputBox.w, inputBox.h, 8)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(inputBox.focused and 3 or 1)
    love.graphics.rectangle("line", inputBox.x, inputBox.y, inputBox.w, inputBox.h, 8)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
    local textY = inputBox.y + (inputBox.h - fontSizes.medium) / 2
    love.graphics.printf(nameInput == "" and (inputBox.focused and "" or "Enter name...") or nameInput, inputBox.x+10, textY, inputBox.w-20, "left")

    -- Color selector - larger touch targets for mobile
    colorRects = {}
    local usedColors = {}
    for _, p in ipairs(players) do
        for i, c in ipairs(colors) do
            if c[1] == p.color[1] and c[2] == p.color[2] and c[3] == p.color[3] and c[4] == p.color[4] then
                usedColors[i] = true
            end
        end
    end
    
    local colorSize = screenConfig.isMobile and 44 or 32  -- Larger on mobile
    local colorSpacing = screenConfig.isMobile and 52 or 38
    local totalWidth = #colors * colorSpacing - (colorSpacing - colorSize)
    
    for i, color in ipairs(colors) do
        local x = cx - totalWidth/2 + (i-1)*colorSpacing
        local y = colorY
        if usedColors[i] then
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        else
            love.graphics.setColor(color)
        end
        love.graphics.rectangle("fill", x, y, colorSize, colorSize, 6)
        if color == selectedColor and not usedColors[i] then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", x-2, y-2, colorSize+4, colorSize+4, 8)
        elseif colorHover == i and not usedColors[i] then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x-2, y-2, colorSize+4, colorSize+4, 8)
        end
        colorRects[i] = {x=x, y=y, w=colorSize, h=colorSize, color=color, disabled=usedColors[i]}
    end
    love.graphics.setLineWidth(1)

    -- Draw mobile buttons
    if addPlayerButton then
        addPlayerButton:draw()
    end
    if startGameButton then
        startGameButton:draw()
    end

    -- Player list with remove buttons
    love.graphics.setFont(love.graphics.newFont(fontSizes.medium))
    local y = listY
    removeRects = {}
    removeButtons = {}
    
    local removeButtonSize = screenConfig.isMobile and MobileConfig.getTouchTargetSize() or 28
    local rowHeight = removeButtonSize + layout.spacing
    
    for i, p in ipairs(players) do
        local colorSize = removeButtonSize
        love.graphics.setColor(p.color)
        love.graphics.rectangle("fill", cx-100, y, colorSize, colorSize, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(p.name, cx-100 + colorSize + 10, y + (colorSize - fontSizes.medium) / 2)
        
        -- Create remove button if needed
        if not removeButtons[i] then
            removeButtons[i] = MobileButton.new("×", cx+80, y, removeButtonSize, removeButtonSize)
            removeButtons[i]:setBackgroundColor(0.7, 0.2, 0.2, 1)
            removeButtons[i].onTap = function() 
                table.remove(players, i)
                removeButtons[i] = nil
            end
        else
            removeButtons[i]:setPosition(cx+80, y)
        end
        
        removeButtons[i]:draw()
        y = y + rowHeight
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

-- Helper functions
function playerSetup:addPlayer()
    if nameInput ~= "" then
        table.insert(players, {name=nameInput, color=selectedColor})
        nameInput = ""
    end
end

function playerSetup:startGame()
    if #players >= 2 then
        changeState("game", players)
    end
end

function playerSetup:mousemoved(x, y, dx, dy)
    -- Input box hover
    inputBox.hover = x >= inputBox.x and x <= inputBox.x+inputBox.w and y >= inputBox.y and y <= inputBox.y+inputBox.h
    
    -- Mobile button hover
    if addPlayerButton then
        addPlayerButton:mousemoved(x, y, dx, dy)
    end
    if startGameButton then
        startGameButton:mousemoved(x, y, dx, dy)
    end
    for _, btn in ipairs(removeButtons) do
        if btn then
            btn:mousemoved(x, y, dx, dy)
        end
    end
    
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
        
        -- Mobile buttons
        if addPlayerButton and addPlayerButton:mousepressed(x, y, button) then
            return
        end
        if startGameButton and startGameButton:mousepressed(x, y, button) then
            return
        end
        for _, btn in ipairs(removeButtons) do
            if btn and btn:mousepressed(x, y, button) then
                return
            end
        end
    end
end

function playerSetup:mousereleased(x, y, button)
    if button == 1 then
        -- Mobile buttons
        if addPlayerButton then
            addPlayerButton:mousereleased(x, y, button)
        end
        if startGameButton then
            startGameButton:mousereleased(x, y, button)
        end
        for _, btn in ipairs(removeButtons) do
            if btn then
                btn:mousereleased(x, y, button)
            end
        end
    end
end

-- Touch input handlers
function playerSetup:touchpressed(id, x, y, dx, dy, pressure)
    -- Handle input box touch
    inputBox.focused = x >= inputBox.x and x <= inputBox.x+inputBox.w and y >= inputBox.y and y <= inputBox.y+inputBox.h
    
    -- Color selection
    for i, rect in ipairs(colorRects) do
        if not rect.disabled and x >= rect.x and x <= rect.x+rect.w and y >= rect.y and y <= rect.y+rect.h then
            selectedColor = rect.color
            return
        end
    end
    
    -- Mobile buttons
    if addPlayerButton and addPlayerButton:touchpressed(id, x, y, dx, dy, pressure) then
        return
    end
    if startGameButton and startGameButton:touchpressed(id, x, y, dx, dy, pressure) then
        return
    end
    for _, btn in ipairs(removeButtons) do
        if btn and btn:touchpressed(id, x, y, dx, dy, pressure) then
            return
        end
    end
end

function playerSetup:touchmoved(id, x, y, dx, dy, pressure)
    -- Mobile buttons
    if addPlayerButton then
        addPlayerButton:touchmoved(id, x, y, dx, dy, pressure)
    end
    if startGameButton then
        startGameButton:touchmoved(id, x, y, dx, dy, pressure)
    end
    for _, btn in ipairs(removeButtons) do
        if btn then
            btn:touchmoved(id, x, y, dx, dy, pressure)
        end
    end
end

function playerSetup:touchreleased(id, x, y, dx, dy, pressure)
    -- Mobile buttons
    if addPlayerButton then
        addPlayerButton:touchreleased(id, x, y, dx, dy, pressure)
    end
    if startGameButton then
        startGameButton:touchreleased(id, x, y, dx, dy, pressure)
    end
    for _, btn in ipairs(removeButtons) do
        if btn then
            btn:touchreleased(id, x, y, dx, dy, pressure)
        end
    end
end

return playerSetup 