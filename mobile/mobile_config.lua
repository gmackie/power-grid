-- Mobile Configuration and Utilities

local MobileConfig = {}

-- Platform detection
function MobileConfig.isMobile()
    local os = love.system.getOS()
    return os == "iOS" or os == "Android"
end

-- Screen configuration
function MobileConfig.getScreenConfig()
    local width, height = love.graphics.getDimensions()
    local os = love.system.getOS()
    
    local config = {
        width = width,
        height = height,
        os = os,
        isMobile = MobileConfig.isMobile(),
        isTablet = false,
        orientation = width > height and "landscape" or "portrait",
        density = love.window.getDPIScale(),
        safeArea = {x = 0, y = 0, w = width, h = height}
    }
    
    -- Detect tablet
    local diagonal = math.sqrt(width^2 + height^2) / config.density
    if diagonal > 600 then  -- Roughly 7" or larger
        config.isTablet = true
    end
    
    -- Get safe area (for notches, home indicators)
    if love.window.getSafeArea then
        local sx, sy, sw, sh = love.window.getSafeArea()
        config.safeArea = {x = sx, y = sy, w = sw, h = sh}
    end
    
    return config
end

-- UI Scaling
function MobileConfig.getUIScale()
    local config = MobileConfig.getScreenConfig()
    local baseWidth = 1920  -- Base design width
    
    -- Calculate scale based on width
    local scale = config.width / baseWidth
    
    -- Adjust for mobile
    if config.isMobile then
        if config.isTablet then
            scale = scale * 1.2  -- Slightly larger UI on tablets
        else
            scale = scale * 1.5  -- Much larger UI on phones
        end
    end
    
    return scale
end

-- Touch target sizes
function MobileConfig.getTouchTargetSize()
    local config = MobileConfig.getScreenConfig()
    local density = config.density
    
    if config.os == "iOS" then
        return 44 * density  -- iOS HIG recommends 44pt
    elseif config.os == "Android" then
        return 48 * density  -- Material Design recommends 48dp
    else
        return 40  -- Desktop default
    end
end

-- Font sizes
function MobileConfig.getFontSizes()
    local scale = MobileConfig.getUIScale()
    local config = MobileConfig.getScreenConfig()
    
    local sizes = {
        small = 12,
        medium = 16,
        large = 20,
        xlarge = 24,
        title = 32
    }
    
    -- Scale all fonts
    for key, size in pairs(sizes) do
        sizes[key] = math.floor(size * scale)
    end
    
    -- Ensure minimum readable sizes on mobile
    if config.isMobile then
        sizes.small = math.max(sizes.small, 14)
        sizes.medium = math.max(sizes.medium, 16)
    end
    
    return sizes
end

-- Button configurations
function MobileConfig.getButtonConfig()
    local minSize = MobileConfig.getTouchTargetSize()
    local scale = MobileConfig.getUIScale()
    
    return {
        minWidth = minSize * 3,    -- Reasonable minimum width
        minHeight = minSize,
        padding = 10 * scale,
        cornerRadius = 8 * scale,
        fontSize = MobileConfig.getFontSizes().medium
    }
end

-- Gesture thresholds
function MobileConfig.getGestureThresholds()
    local config = MobileConfig.getScreenConfig()
    local density = config.density
    
    return {
        tapMaxDistance = 10 * density,     -- Maximum movement for a tap
        tapMaxDuration = 0.3,              -- Maximum duration for a tap
        longPressTime = 0.5,               -- Time for long press
        doubleTapTime = 0.3,               -- Maximum time between taps
        swipeMinDistance = 50 * density,   -- Minimum swipe distance
        swipeMaxTime = 0.5,                -- Maximum swipe duration
        pinchMinDistance = 10 * density    -- Minimum pinch distance
    }
end

-- Layout helpers
function MobileConfig.getLayout()
    local config = MobileConfig.getScreenConfig()
    local scale = MobileConfig.getUIScale()
    
    return {
        margin = 20 * scale,
        spacing = 10 * scale,
        headerHeight = 60 * scale,
        footerHeight = 80 * scale,
        sidebarWidth = config.isTablet and 300 * scale or 0,
        useSafeArea = config.isMobile
    }
end

-- Performance settings
function MobileConfig.getPerformanceSettings()
    local config = MobileConfig.getScreenConfig()
    
    return {
        targetFPS = config.isMobile and 30 or 60,
        enableParticles = not config.isMobile or config.isTablet,
        enableShadows = not config.isMobile or config.isTablet,
        textureQuality = config.isMobile and "medium" or "high",
        maxTextureSize = config.isMobile and 1024 or 2048
    }
end

-- Storage paths
function MobileConfig.getStoragePaths()
    local config = MobileConfig.getScreenConfig()
    
    return {
        saves = "saves/",
        settings = "settings.json",
        cache = "cache/",
        useCloudSave = config.isMobile  -- Enable cloud saves on mobile
    }
end

-- Network settings
function MobileConfig.getNetworkSettings()
    local config = MobileConfig.getScreenConfig()
    
    return {
        timeout = config.isMobile and 10 or 5,  -- Longer timeout on mobile
        reconnectAttempts = config.isMobile and 10 or 5,
        compressMessages = config.isMobile,
        warnOnCellular = config.isMobile
    }
end

-- Initialize mobile settings
function MobileConfig.initialize()
    local config = MobileConfig.getScreenConfig()
    
    if config.isMobile then
        -- Set mobile-specific window settings
        love.window.setMode(config.width, config.height, {
            fullscreen = true,
            fullscreentype = "exclusive",
            resizable = false,
            borderless = true,
            centered = true,
            displayindex = 1,
            highdpi = true,
            usedpiscale = true
        })
        
        -- Disable screen dimming
        if love.window.setDisplaySleepEnabled then
            love.window.setDisplaySleepEnabled(false)
        end
        
        -- Set orientation
        if config.os == "iOS" or config.os == "Android" then
            -- Power Grid is best in landscape
            if love.window.setOrientation then
                love.window.setOrientation("landscape")
            end
        end
    end
end

return MobileConfig