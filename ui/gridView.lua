-- GridView UI component for Power Grid Digital
-- A grid view with cells

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Button = require "src.ui.button"

local GridView = class('GridView')

-- Create a new grid view
function GridView.new(x, y, width, height, options)
    local gridView = GridView()
    gridView:initialize(x, y, width, height, options)
    return gridView
end

-- Initialize the grid view
function GridView:initialize(x, y, width, height, options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.3, 0.8}
    this.options.borderColor = this.options.borderColor or {0.4, 0.4, 0.5, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 5
    this.options.cellWidth = this.options.cellWidth or 100
    this.options.cellHeight = this.options.cellHeight or 100
    this.options.cellSpacing = this.options.cellSpacing or 5
    this.options.columns = this.options.columns or 3
    this.options.fadeInDuration = this.options.fadeInDuration or 0.2
    this.options.fadeOutDuration = this.options.fadeOutDuration or 0.2
    
    -- Set position and size
    this.x = x or 0
    this.y = y or 0
    this.width = width or 200
    this.height = height or 200
    
    -- Create panel
    this.panel = Panel.new(x, y, width, this.height, {
        backgroundColor = this.options.backgroundColor,
        borderColor = this.options.borderColor,
        cornerRadius = this.options.cornerRadius
    })
    
    -- Grid view state
    this.visible = true
    this.alpha = 1
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.cells = {}
    this.selectedCell = nil
    this.scrollY = 0
    
    return this
end

-- Set grid view position
function GridView:setPosition(x, y)
    this.x = x
    this.y = y
    this.panel:setPosition(x, y)
    this:updateCellPositions()
end

-- Set grid view size
function GridView:setSize(width, height)
    this.width = width
    this.height = height
    this.panel:setSize(width, height)
    this:updateCellPositions()
end

-- Set grid view visibility
function GridView:setVisible(visible)
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

-- Get grid view visibility
function GridView:isVisible()
    return this.visible
end

-- Add cell
function GridView:addCell(text, options)
    options = options or {}
    options.backgroundColor = options.backgroundColor or {0.3, 0.3, 0.4, 0.8}
    options.borderColor = options.borderColor or {0.4, 0.4, 0.5, 1}
    options.textColor = options.textColor or this.options.textColor
    options.fontSize = options.fontSize or this.options.fontSize
    options.padding = options.padding or this.options.padding
    options.cornerRadius = options.cornerRadius or this.options.cornerRadius
    options.hoverColor = options.hoverColor or {0.4, 0.4, 0.5, 0.8}
    options.pressColor = options.pressColor or {0.2, 0.2, 0.3, 0.8}
    
    local cell = {
        text = text,
        button = Button.new(text,
            this.x + this.options.padding + ((#this.cells % this.options.columns) * (this.options.cellWidth + this.options.cellSpacing)),
            this.y + this.options.padding + (math.floor(#this.cells / this.options.columns) * (this.options.cellHeight + this.options.cellSpacing)),
            this.options.cellWidth,
            this.options.cellHeight, options)
    }
    
    cell.button:setOnClick(function()
        this:selectCell(#this.cells + 1)
    end)
    
    table.insert(this.cells, cell)
    this:updateCellPositions()
    
    return #this.cells
end

-- Remove cell
function GridView:removeCell(index)
    if index >= 1 and index <= #this.cells then
        table.remove(this.cells, index)
        this:updateCellPositions()
        
        -- Deselect cell if needed
        if this.selectedCell == index then
            this.selectedCell = nil
        elseif this.selectedCell > index then
            this.selectedCell = this.selectedCell - 1
        end
    end
end

-- Clear cells
function GridView:clearCells()
    this.cells = {}
    this.selectedCell = nil
    this.scrollY = 0
end

-- Get all cells
function GridView:getCells()
    return this.cells
end

-- Select cell
function GridView:selectCell(index)
    if index >= 1 and index <= #this.cells then
        this.selectedCell = index
    end
end

-- Get selected cell
function GridView:getSelectedCell()
    return this.selectedCell
end

-- Set background color
function GridView:setBackgroundColor(color)
    this.options.backgroundColor = color
    this.panel:setBackgroundColor(color)
end

-- Set border color
function GridView:setBorderColor(color)
    this.options.borderColor = color
    this.panel:setBorderColor(color)
end

-- Set text color
function GridView:setTextColor(color)
    this.options.textColor = color
    for _, cell in ipairs(this.cells) do
        cell.button:setTextColor(color)
    end
end

-- Set font size
function GridView:setFontSize(size)
    this.options.fontSize = size
    for _, cell in ipairs(this.cells) do
        cell.button:setFontSize(size)
    end
end

-- Set cell width
function GridView:setCellWidth(width)
    this.options.cellWidth = width
    for _, cell in ipairs(this.cells) do
        cell.button:setSize(width, cell.button.height)
    end
    this:updateCellPositions()
end

-- Set cell height
function GridView:setCellHeight(height)
    this.options.cellHeight = height
    for _, cell in ipairs(this.cells) do
        cell.button:setSize(cell.button.width, height)
    end
    this:updateCellPositions()
end

-- Set cell spacing
function GridView:setCellSpacing(spacing)
    this.options.cellSpacing = spacing
    this:updateCellPositions()
end

-- Set columns
function GridView:setColumns(columns)
    this.options.columns = columns
    this:updateCellPositions()
end

-- Set fade in duration
function GridView:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function GridView:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update cell positions
function GridView:updateCellPositions()
    for i, cell in ipairs(this.cells) do
        cell.button:setPosition(
            this.x + this.options.padding + (((i - 1) % this.options.columns) * (this.options.cellWidth + this.options.cellSpacing)),
            this.y + this.options.padding + (math.floor((i - 1) / this.options.columns) * (this.options.cellHeight + this.options.cellSpacing)))
    end
end

-- Update grid view
function GridView:update(dt)
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
    
    -- Update buttons
    for _, cell in ipairs(this.cells) do
        cell.button:update(dt)
    end
end

-- Draw the grid view
function GridView:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw panel
    this.panel:draw()
    
    -- Draw buttons
    for _, cell in ipairs(this.cells) do
        cell.button:draw()
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function GridView:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside buttons
    for _, cell in ipairs(this.cells) do
        if cell.button:mousepressed(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle mouse move
function GridView:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside buttons
    for _, cell in ipairs(this.cells) do
        if cell.button:mousemoved(x, y, dx, dy) then
            return true
        end
    end
    
    return false
end

-- Handle mouse release
function GridView:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside buttons
    for _, cell in ipairs(this.cells) do
        if cell.button:mousereleased(x, y, button) then
            return true
        end
    end
    
    return false
end

-- Handle key press
function GridView:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Check if key is handled by buttons
    for _, cell in ipairs(this.cells) do
        if cell.button:keypressed(key, scancode, isrepeat) then
            return true
        end
    end
    
    return false
end

-- Handle text input
function GridView:textinput(text)
    if not this.visible then return false end
    
    -- Check if text is handled by buttons
    for _, cell in ipairs(this.cells) do
        if cell.button:textinput(text) then
            return true
        end
    end
    
    return false
end

-- Handle window resize
function GridView:resize(width, height)
    -- Update grid view position if it's the main grid view
    if this.x == 0 and this.y == 0 then
        this:setPosition(0, 0)
    end
end

return GridView 