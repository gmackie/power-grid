-- TreeView UI component for Power Grid Digital
-- A tree view with expandable nodes

local class = require "lib.middleclass"
local Panel = require "src.ui.panel"
local Button = require "src.ui.button"

local TreeView = class('TreeView')

-- Create a new tree view
function TreeView.new(x, y, width, height, options)
    local treeView = TreeView()
    treeView:initialize(x, y, width, height, options)
    return treeView
end

-- Initialize the tree view
function TreeView:initialize(x, y, width, height, options)
    -- Set default options
    this.options = options or {}
    this.options.backgroundColor = this.options.backgroundColor or {0.2, 0.2, 0.3, 0.8}
    this.options.borderColor = this.options.borderColor or {0.4, 0.4, 0.5, 1}
    this.options.textColor = this.options.textColor or {1, 1, 1, 1}
    this.options.fontSize = this.options.fontSize or 14
    this.options.padding = this.options.padding or 5
    this.options.cornerRadius = this.options.cornerRadius or 5
    this.options.nodeHeight = this.options.nodeHeight or 30
    this.options.nodeSpacing = this.options.nodeSpacing or 5
    this.options.indentSize = this.options.indentSize or 20
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
    
    -- Tree view state
    this.visible = true
    this.alpha = 1
    this.fadeInTimer = 0
    this.fadeOutTimer = 0
    this.nodes = {}
    this.selectedNode = nil
    this.scrollY = 0
    
    return this
end

-- Set tree view position
function TreeView:setPosition(x, y)
    this.x = x
    this.y = y
    this.panel:setPosition(x, y)
end

-- Set tree view size
function TreeView:setSize(width, height)
    this.width = width
    this.height = height
    this.panel:setSize(width, height)
end

-- Set tree view visibility
function TreeView:setVisible(visible)
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

-- Get tree view visibility
function TreeView:isVisible()
    return this.visible
end

-- Add node
function TreeView:addNode(text, parent, options)
    options = options or {}
    options.backgroundColor = options.backgroundColor or {0.3, 0.3, 0.4, 0.8}
    options.borderColor = options.borderColor or {0.4, 0.4, 0.5, 1}
    options.textColor = options.textColor or this.options.textColor
    options.fontSize = options.fontSize or this.options.fontSize
    options.padding = options.padding or this.options.padding
    options.cornerRadius = options.cornerRadius or this.options.cornerRadius
    options.hoverColor = options.hoverColor or {0.4, 0.4, 0.5, 0.8}
    options.pressColor = options.pressColor or {0.2, 0.2, 0.3, 0.8}
    
    local node = {
        text = text,
        parent = parent,
        children = {},
        expanded = false,
        level = parent and (parent.level + 1) or 0,
        button = Button.new(text,
            this.x + this.options.padding + (this.options.indentSize * (parent and (parent.level + 1) or 0)),
            this.y + this.options.padding + (#this.nodes * (this.options.nodeHeight + this.options.nodeSpacing)),
            this.width - (2 * this.options.padding) - (this.options.indentSize * (parent and (parent.level + 1) or 0)),
            this.options.nodeHeight, options)
    }
    
    node.button:setOnClick(function()
        this:selectNode(node)
    end)
    
    if parent then
        table.insert(parent.children, node)
    else
        table.insert(this.nodes, node)
    end
    
    return node
end

-- Remove node
function TreeView:removeNode(node)
    if node.parent then
        for i, child in ipairs(node.parent.children) do
            if child == node then
                table.remove(node.parent.children, i)
                break
            end
        end
    else
        for i, rootNode in ipairs(this.nodes) do
            if rootNode == node then
                table.remove(this.nodes, i)
                break
            end
        end
    end
    
    -- Deselect node if needed
    if this.selectedNode == node then
        this.selectedNode = nil
    end
end

-- Clear nodes
function TreeView:clearNodes()
    this.nodes = {}
    this.selectedNode = nil
    this.scrollY = 0
end

-- Get all nodes
function TreeView:getNodes()
    return this.nodes
end

-- Select node
function TreeView:selectNode(node)
    this.selectedNode = node
    node.expanded = not node.expanded
end

-- Get selected node
function TreeView:getSelectedNode()
    return this.selectedNode
end

-- Set background color
function TreeView:setBackgroundColor(color)
    this.options.backgroundColor = color
    this.panel:setBackgroundColor(color)
end

-- Set border color
function TreeView:setBorderColor(color)
    this.options.borderColor = color
    this.panel:setBorderColor(color)
end

-- Set text color
function TreeView:setTextColor(color)
    this.options.textColor = color
    for _, node in ipairs(this.nodes) do
        node.button:setTextColor(color)
        for _, child in ipairs(node.children) do
            child.button:setTextColor(color)
        end
    end
end

-- Set font size
function TreeView:setFontSize(size)
    this.options.fontSize = size
    for _, node in ipairs(this.nodes) do
        node.button:setFontSize(size)
        for _, child in ipairs(node.children) do
            child.button:setFontSize(size)
        end
    end
end

-- Set node height
function TreeView:setNodeHeight(height)
    this.options.nodeHeight = height
    for _, node in ipairs(this.nodes) do
        node.button:setSize(node.button.width, height)
        node.button:setPosition(node.button.x,
            this.y + this.options.padding + (node.level * (height + this.options.nodeSpacing)))
        for _, child in ipairs(node.children) do
            child.button:setSize(child.button.width, height)
            child.button:setPosition(child.button.x,
                this.y + this.options.padding + (child.level * (height + this.options.nodeSpacing)))
        end
    end
end

-- Set node spacing
function TreeView:setNodeSpacing(spacing)
    this.options.nodeSpacing = spacing
    for _, node in ipairs(this.nodes) do
        node.button:setPosition(node.button.x,
            this.y + this.options.padding + (node.level * (this.options.nodeHeight + spacing)))
        for _, child in ipairs(node.children) do
            child.button:setPosition(child.button.x,
                this.y + this.options.padding + (child.level * (this.options.nodeHeight + spacing)))
        end
    end
end

-- Set indent size
function TreeView:setIndentSize(size)
    this.options.indentSize = size
    for _, node in ipairs(this.nodes) do
        node.button:setPosition(this.x + this.options.padding + (size * node.level),
            node.button.y)
        node.button:setSize(this.width - (2 * this.options.padding) - (size * node.level),
            node.button.height)
        for _, child in ipairs(node.children) do
            child.button:setPosition(this.x + this.options.padding + (size * child.level),
                child.button.y)
            child.button:setSize(this.width - (2 * this.options.padding) - (size * child.level),
                child.button.height)
        end
    end
end

-- Set fade in duration
function TreeView:setFadeInDuration(duration)
    this.options.fadeInDuration = duration
end

-- Set fade out duration
function TreeView:setFadeOutDuration(duration)
    this.options.fadeOutDuration = duration
end

-- Update tree view
function TreeView:update(dt)
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
    for _, node in ipairs(this.nodes) do
        node.button:update(dt)
        for _, child in ipairs(node.children) do
            child.button:update(dt)
        end
    end
end

-- Draw the tree view
function TreeView:draw()
    if not this.visible and this.alpha == 0 then return end
    
    -- Set alpha
    local oldColor = {love.graphics.getColor()}
    love.graphics.setColor(oldColor[1], oldColor[2], oldColor[3], oldColor[4] * this.alpha)
    
    -- Draw panel
    this.panel:draw()
    
    -- Draw buttons
    for _, node in ipairs(this.nodes) do
        node.button:draw()
        if node.expanded then
            for _, child in ipairs(node.children) do
                child.button:draw()
            end
        end
    end
    
    -- Reset color
    love.graphics.setColor(oldColor)
end

-- Handle mouse press
function TreeView:mousepressed(x, y, button)
    if not this.visible then return false end
    
    -- Check if click is inside buttons
    for _, node in ipairs(this.nodes) do
        if node.button:mousepressed(x, y, button) then
            return true
        end
        if node.expanded then
            for _, child in ipairs(node.children) do
                if child.button:mousepressed(x, y, button) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle mouse move
function TreeView:mousemoved(x, y, dx, dy)
    if not this.visible then return false end
    
    -- Check if mouse is inside buttons
    for _, node in ipairs(this.nodes) do
        if node.button:mousemoved(x, y, dx, dy) then
            return true
        end
        if node.expanded then
            for _, child in ipairs(node.children) do
                if child.button:mousemoved(x, y, dx, dy) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle mouse release
function TreeView:mousereleased(x, y, button)
    if not this.visible then return false end
    
    -- Check if mouse is inside buttons
    for _, node in ipairs(this.nodes) do
        if node.button:mousereleased(x, y, button) then
            return true
        end
        if node.expanded then
            for _, child in ipairs(node.children) do
                if child.button:mousereleased(x, y, button) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle key press
function TreeView:keypressed(key, scancode, isrepeat)
    if not this.visible then return false end
    
    -- Check if key is handled by buttons
    for _, node in ipairs(this.nodes) do
        if node.button:keypressed(key, scancode, isrepeat) then
            return true
        end
        if node.expanded then
            for _, child in ipairs(node.children) do
                if child.button:keypressed(key, scancode, isrepeat) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle text input
function TreeView:textinput(text)
    if not this.visible then return false end
    
    -- Check if text is handled by buttons
    for _, node in ipairs(this.nodes) do
        if node.button:textinput(text) then
            return true
        end
        if node.expanded then
            for _, child in ipairs(node.children) do
                if child.button:textinput(text) then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Handle window resize
function TreeView:resize(width, height)
    -- Update tree view position if it's the main tree view
    if this.x == 0 and this.y == 0 then
        this:setPosition(0, 0)
    end
end

return TreeView 