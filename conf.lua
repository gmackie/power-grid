-- LÖVE2D configuration for Power Grid Digital
-- Supports both mobile and desktop platforms

function love.conf(t)
    -- Game identity
    t.identity = "power_grid_digital"
    t.title = "Power Grid Digital"
    t.version = "11.4"
    
    -- Window settings (desktop)
    t.window.width = 1600
    t.window.height = 900
    t.window.minwidth = 1200
    t.window.minheight = 800
    t.window.resizable = true
    t.window.vsync = 1
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.highdpi = true
    t.window.usedpiscale = true
    
    -- Graphics
    t.window.icon = nil  -- Set icon path if you have one
    
    -- Audio
    t.audio.mixwithsystem = true
    
    -- Modules
    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false  -- Disable joystick for mobile
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false  -- Not needed for this game
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = true     -- Enable touch for mobile
    t.modules.video = false    -- Not needed
    t.modules.window = true
    
    -- Mobile-specific settings
    if love.system and love.system.getOS then
        local os = love.system.getOS()
        if os == "iOS" or os == "Android" then
            -- Mobile optimizations
            t.window.fullscreen = true
            t.window.fullscreentype = "exclusive"
            t.window.resizable = false
            t.window.borderless = true
            t.window.centered = true
            t.window.displayindex = 1
            
            -- Orientation preference
            t.window.orientation = "landscape"  -- Power Grid works best in landscape
        end
    end
end