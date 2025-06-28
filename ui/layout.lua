-- Layout helper for Power Grid Digital
-- Assists with positioning and arranging UI elements

local Layout = {}

-- Create a horizontal layout
function Layout.horizontal(x, y, width, height, elements, options)
    options = options or {}
    local spacing = options.spacing or 5
    local padding = options.padding or 0
    local alignment = options.alignment or "left"
    
    -- Calculate available width after padding
    local availWidth = width - (padding * 2)
    
    -- Calculate total width of fixed elements and count flexible elements
    local totalFixedWidth = 0
    local flexCount = 0
    
    for _, element in ipairs(elements) do
        if element.width then
            totalFixedWidth = totalFixedWidth + element.width
        else
            flexCount = flexCount + 1
        end
    end
    
    -- Calculate spacing
    local totalSpacing = spacing * (#elements - 1)
    
    -- Calculate width for flexible elements
    local flexWidth = 0
    if flexCount > 0 then
        flexWidth = math.max(0, (availWidth - totalFixedWidth - totalSpacing) / flexCount)
    end
    
    -- Position elements
    local currentX = x + padding
    if alignment == "center" then
        local contentWidth = totalFixedWidth + (flexWidth * flexCount) + totalSpacing
        currentX = x + ((width - contentWidth) / 2)
    elseif alignment == "right" then
        local contentWidth = totalFixedWidth + (flexWidth * flexCount) + totalSpacing
        currentX = x + width - contentWidth - padding
    end
    
    for i, element in ipairs(elements) do
        local elementWidth = element.width or flexWidth
        
        -- Set element position
        element.x = currentX
        element.y = y + padding
        
        -- Set element size if not already set
        if not element.width then
            element.width = elementWidth
        end
        
        if not element.height then
            element.height = height - (padding * 2)
        end
        
        -- Move to next position
        currentX = currentX + elementWidth + spacing
    end
    
    return elements
end

-- Create a vertical layout
function Layout.vertical(x, y, width, height, elements, options)
    options = options or {}
    local spacing = options.spacing or 5
    local padding = options.padding or 0
    local alignment = options.alignment or "top"
    
    -- Calculate available height after padding
    local availHeight = height - (padding * 2)
    
    -- Calculate total height of fixed elements and count flexible elements
    local totalFixedHeight = 0
    local flexCount = 0
    
    for _, element in ipairs(elements) do
        if element.height then
            totalFixedHeight = totalFixedHeight + element.height
        else
            flexCount = flexCount + 1
        end
    end
    
    -- Calculate spacing
    local totalSpacing = spacing * (#elements - 1)
    
    -- Calculate height for flexible elements
    local flexHeight = 0
    if flexCount > 0 then
        flexHeight = math.max(0, (availHeight - totalFixedHeight - totalSpacing) / flexCount)
    end
    
    -- Position elements
    local currentY = y + padding
    if alignment == "middle" then
        local contentHeight = totalFixedHeight + (flexHeight * flexCount) + totalSpacing
        currentY = y + ((height - contentHeight) / 2)
    elseif alignment == "bottom" then
        local contentHeight = totalFixedHeight + (flexHeight * flexCount) + totalSpacing
        currentY = y + height - contentHeight - padding
    end
    
    for i, element in ipairs(elements) do
        local elementHeight = element.height or flexHeight
        
        -- Set element position
        element.x = x + padding
        element.y = currentY
        
        -- Set element size if not already set
        if not element.width then
            element.width = width - (padding * 2)
        end
        
        if not element.height then
            element.height = elementHeight
        end
        
        -- Move to next position
        currentY = currentY + elementHeight + spacing
    end
    
    return elements
end

-- Create a grid layout
function Layout.grid(x, y, width, height, elements, columns, options)
    options = options or {}
    local spacing = options.spacing or 5
    local padding = options.padding or 0
    
    -- Calculate rows based on element count and columns
    local rows = math.ceil(#elements / columns)
    
    -- Calculate cell dimensions
    local cellWidth = (width - (padding * 2) - (spacing * (columns - 1))) / columns
    local cellHeight = (height - (padding * 2) - (spacing * (rows - 1))) / rows
    
    -- Position elements
    for i, element in ipairs(elements) do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)
        
        -- Set element position
        element.x = x + padding + (col * (cellWidth + spacing))
        element.y = y + padding + (row * (cellHeight + spacing))
        
        -- Set element size if not already set
        if not element.width then
            element.width = cellWidth
        end
        
        if not element.height then
            element.height = cellHeight
        end
    end
    
    return elements
end

-- Position an element to center in a given area
function Layout.center(element, x, y, width, height)
    element.x = x + (width - element.width) / 2
    element.y = y + (height - element.height) / 2
    return element
end

-- Position multiple elements in a centered stack
function Layout.centerStack(x, y, width, height, elements, options)
    options = options or {}
    local spacing = options.spacing or 5
    
    -- First arrange elements in a vertical layout
    Layout.vertical(x, y, width, height, elements, options)
    
    -- Then center each element horizontally
    for _, element in ipairs(elements) do
        element.x = x + (width - element.width) / 2
    end
    
    return elements
end

return Layout 