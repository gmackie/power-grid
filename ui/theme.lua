-- Power Grid Digital - Visual Theme System
-- Centralized theme configuration for consistent visuals

local Theme = {}

-- Color Palette (matching the power grid industrial theme)
Theme.colors = {
    -- Primary colors
    primary = {0.13, 0.50, 0.80, 1},      -- Electric blue (#2196F3)
    primaryDark = {0.10, 0.35, 0.60, 1},  -- Darker blue
    primaryLight = {0.40, 0.70, 0.90, 1}, -- Light blue
    
    -- Secondary colors
    secondary = {1.00, 0.60, 0.00, 1},    -- Orange (#FF9800)
    secondaryDark = {0.90, 0.45, 0.00, 1},
    secondaryLight = {1.00, 0.75, 0.40, 1},
    
    -- Background colors
    backgroundDark = {0.08, 0.08, 0.11, 1},    -- Dark blue-gray (#141520)
    background = {0.12, 0.12, 0.16, 1},        -- Medium dark (#1F1F29)
    backgroundLight = {0.18, 0.18, 0.23, 1},   -- Lighter panel (#2E2E3B)
    
    -- Surface colors
    surface = {0.22, 0.22, 0.28, 1},      -- Card/panel background (#383847)
    surfaceLight = {0.28, 0.28, 0.35, 1}, -- Hover state
    
    -- Text colors
    textPrimary = {1.00, 1.00, 1.00, 1},     -- White text
    textSecondary = {0.75, 0.75, 0.80, 1},   -- Gray text
    textDisabled = {0.50, 0.50, 0.55, 1},    -- Disabled text
    
    -- Game-specific colors
    success = {0.30, 0.80, 0.30, 1},    -- Green
    warning = {1.00, 0.75, 0.00, 1},    -- Yellow
    error = {0.90, 0.30, 0.30, 1},      -- Red
    
    -- Resource colors (from spec)
    coal = {0.20, 0.20, 0.20, 1},       -- Dark gray
    oil = {0.80, 0.80, 0.20, 1},        -- Yellow
    garbage = {0.40, 0.60, 0.40, 1},    -- Green-gray
    uranium = {0.20, 0.80, 0.20, 1},    -- Bright green
    hybrid = {0.80, 0.40, 0.20, 1},     -- Orange
    wind = {0.60, 0.80, 1.00, 1},       -- Light blue
    solar = {1.00, 0.80, 0.20, 1},      -- Gold
    
    -- Player colors
    playerRed = {0.80, 0.20, 0.20, 1},
    playerBlue = {0.20, 0.50, 0.80, 1},
    playerGreen = {0.20, 0.70, 0.20, 1},
    playerYellow = {0.90, 0.80, 0.20, 1},
    playerPurple = {0.60, 0.20, 0.80, 1},
    playerOrange = {0.90, 0.50, 0.10, 1},
    
    -- Region colors
    regionYellow = {1.00, 0.92, 0.23, 1},
    regionPurple = {0.61, 0.15, 0.69, 1},
    regionBlue = {0.13, 0.59, 0.95, 1},
    regionBrown = {0.47, 0.33, 0.28, 1},
    regionRed = {0.96, 0.26, 0.21, 1},
    regionGreen = {0.30, 0.69, 0.31, 1}
}

-- Typography
Theme.fonts = {
    -- Font sizes (base sizes, will be scaled for mobile)
    tiny = 12,
    small = 14,
    medium = 16,
    large = 20,
    huge = 28,
    title = 48,
    
    -- Font families (you can add custom fonts here)
    regular = nil,  -- Will use default
    bold = nil,     -- Will use default bold
    mono = nil      -- For numbers/stats
}

-- Spacing and sizing
Theme.layout = {
    padding = 16,
    margin = 20,
    spacing = 12,
    
    -- Border radius
    radiusSmall = 4,
    radiusMedium = 8,
    radiusLarge = 12,
    
    -- Common sizes
    buttonHeight = 48,
    buttonHeightSmall = 36,
    buttonHeightLarge = 60,
    
    iconSize = 32,
    iconSizeSmall = 24,
    iconSizeLarge = 48
}

-- Shadows and effects
Theme.effects = {
    shadowColor = {0, 0, 0, 0.3},
    shadowOffset = {2, 2},
    glowColor = {1, 1, 1, 0.1},
    
    -- Animation durations
    transitionFast = 0.15,
    transitionNormal = 0.3,
    transitionSlow = 0.5
}

-- Button styles
Theme.button = {
    primary = {
        normal = {
            bg = Theme.colors.primary,
            text = Theme.colors.textPrimary,
            border = Theme.colors.primaryLight
        },
        hover = {
            bg = Theme.colors.primaryLight,
            text = Theme.colors.textPrimary,
            border = Theme.colors.primaryLight
        },
        pressed = {
            bg = Theme.colors.primaryDark,
            text = Theme.colors.textPrimary,
            border = Theme.colors.primaryDark
        },
        disabled = {
            bg = Theme.colors.surface,
            text = Theme.colors.textDisabled,
            border = Theme.colors.surface
        }
    },
    secondary = {
        normal = {
            bg = Theme.colors.surface,
            text = Theme.colors.textPrimary,
            border = Theme.colors.surfaceLight
        },
        hover = {
            bg = Theme.colors.surfaceLight,
            text = Theme.colors.textPrimary,
            border = Theme.colors.primary
        },
        pressed = {
            bg = Theme.colors.backgroundLight,
            text = Theme.colors.textPrimary,
            border = Theme.colors.primaryDark
        },
        disabled = {
            bg = Theme.colors.backgroundLight,
            text = Theme.colors.textDisabled,
            border = Theme.colors.backgroundLight
        }
    }
}

-- Panel styles
Theme.panel = {
    default = {
        bg = Theme.colors.surface,
        border = Theme.colors.surfaceLight,
        headerBg = Theme.colors.backgroundLight,
        headerText = Theme.colors.textPrimary
    },
    elevated = {
        bg = Theme.colors.surfaceLight,
        border = Theme.colors.primary,
        headerBg = Theme.colors.primary,
        headerText = Theme.colors.textPrimary
    },
    transparent = {
        bg = {0, 0, 0, 0.7},
        border = Theme.colors.surfaceLight,
        headerBg = {0, 0, 0, 0.9},
        headerText = Theme.colors.textPrimary
    }
}

-- Helper functions
function Theme.getPlayerColor(index)
    local colors = {
        Theme.colors.playerRed,
        Theme.colors.playerBlue,
        Theme.colors.playerGreen,
        Theme.colors.playerYellow,
        Theme.colors.playerPurple,
        Theme.colors.playerOrange
    }
    return colors[((index - 1) % #colors) + 1]
end

function Theme.getResourceColor(resourceType)
    local type = string.lower(resourceType)
    return Theme.colors[type] or Theme.colors.surface
end

function Theme.getRegionColor(region)
    local regionName = "region" .. region:sub(1,1):upper() .. region:sub(2):lower()
    return Theme.colors[regionName] or Theme.colors.surface
end

-- Apply theme colors
function Theme.setColor(colorName, alpha)
    local color = Theme.colors[colorName]
    if color then
        if alpha then
            love.graphics.setColor(color[1], color[2], color[3], alpha)
        else
            love.graphics.setColor(color)
        end
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Draw helpers
function Theme.drawPanel(x, y, w, h, style)
    style = style or "default"
    local panelStyle = Theme.panel[style]
    
    -- Draw shadow
    love.graphics.setColor(Theme.effects.shadowColor)
    love.graphics.rectangle("fill", x + 2, y + 2, w, h, Theme.layout.radiusMedium)
    
    -- Draw background
    love.graphics.setColor(panelStyle.bg)
    love.graphics.rectangle("fill", x, y, w, h, Theme.layout.radiusMedium)
    
    -- Draw border
    love.graphics.setColor(panelStyle.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, Theme.layout.radiusMedium)
end

function Theme.drawButton(x, y, w, h, state, type)
    type = type or "primary"
    state = state or "normal"
    
    local buttonStyle = Theme.button[type][state]
    
    -- Draw shadow for elevated buttons
    if state ~= "disabled" then
        love.graphics.setColor(Theme.effects.shadowColor)
        love.graphics.rectangle("fill", x + 1, y + 1, w, h, Theme.layout.radiusSmall)
    end
    
    -- Draw background
    love.graphics.setColor(buttonStyle.bg)
    love.graphics.rectangle("fill", x, y, w, h, Theme.layout.radiusSmall)
    
    -- Draw border
    love.graphics.setColor(buttonStyle.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, Theme.layout.radiusSmall)
end

return Theme