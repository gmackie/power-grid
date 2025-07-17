-- Visual Effects System for Power Grid Digital
-- Centralized system for managing visual effects and animations

local VisualEffects = {}
local Theme = require("ui.theme")

-- Active effects
local activeEffects = {}
local nextEffectId = 1

-- Effect types
local effectTypes = {
    PARTICLE = "particle",
    GLOW = "glow",
    SHAKE = "shake",
    FLOAT = "float",
    FADE = "fade",
    SCALE = "scale",
    ROTATION = "rotation",
    TEXT_POP = "text_pop",
    SPARKLE = "sparkle",
    ENERGY_FLOW = "energy_flow"
}

-- Particle system
local particleTexture = nil

function VisualEffects.init()
    -- Create a simple particle texture
    local imageData = love.image.newImageData(8, 8)
    imageData:mapPixel(function(x, y, r, g, b, a)
        local distance = math.sqrt((x-4)^2 + (y-4)^2)
        local alpha = math.max(0, 1 - distance/4)
        return 1, 1, 1, alpha
    end)
    particleTexture = love.graphics.newImage(imageData)
end

-- Create a new effect
function VisualEffects.create(effectType, x, y, options)
    options = options or {}
    
    local effect = {
        id = nextEffectId,
        type = effectType,
        x = x,
        y = y,
        startTime = love.timer.getTime(),
        duration = options.duration or 1.0,
        active = true
    }
    
    nextEffectId = nextEffectId + 1
    
    -- Type-specific initialization
    if effectType == effectTypes.PARTICLE then
        effect.particles = {}
        effect.count = options.count or 10
        effect.color = options.color or Theme.colors.primary
        effect.spread = options.spread or 50
        effect.speed = options.speed or 100
        effect.gravity = options.gravity or 0
        
        -- Create particles
        for i = 1, effect.count do
            table.insert(effect.particles, {
                x = x + math.random(-10, 10),
                y = y + math.random(-10, 10),
                vx = math.random(-effect.spread, effect.spread),
                vy = math.random(-effect.speed, -effect.speed/2),
                life = 1.0,
                size = math.random(2, 6)
            })
        end
        
    elseif effectType == effectTypes.GLOW then
        effect.color = options.color or Theme.colors.primary
        effect.radius = options.radius or 50
        effect.intensity = options.intensity or 1.0
        
    elseif effectType == effectTypes.SHAKE then
        effect.intensity = options.intensity or 10
        effect.target = options.target  -- Object to shake
        effect.originalX = effect.target and effect.target.x
        effect.originalY = effect.target and effect.target.y
        
    elseif effectType == effectTypes.TEXT_POP then
        effect.text = options.text or "TEXT"
        effect.font = options.font or love.graphics.newFont(Theme.fonts.large)
        effect.color = options.color or Theme.colors.warning
        effect.scale = 0
        effect.targetScale = options.scale or 1.5
        effect.fadeStart = options.fadeStart or 0.7
        
    elseif effectType == effectTypes.SPARKLE then
        effect.sparkles = {}
        effect.count = options.count or 15
        effect.color = options.color or Theme.colors.warning
        effect.area = options.area or 100
        
        -- Create sparkles
        for i = 1, effect.count do
            table.insert(effect.sparkles, {
                x = x + math.random(-effect.area/2, effect.area/2),
                y = y + math.random(-effect.area/2, effect.area/2),
                phase = math.random() * math.pi * 2,
                speed = math.random(2, 5),
                size = math.random(1, 4),
                delay = math.random() * 0.5
            })
        end
        
    elseif effectType == effectTypes.ENERGY_FLOW then
        effect.startX = options.startX or x
        effect.startY = options.startY or y
        effect.endX = options.endX or x + 100
        effect.endY = options.endY or y
        effect.color = options.color or Theme.colors.primary
        effect.particles = {}
        effect.particleCount = options.particleCount or 5
        
        -- Create flow particles
        for i = 1, effect.particleCount do
            table.insert(effect.particles, {
                progress = i / effect.particleCount,
                size = math.random(3, 7),
                alpha = 1.0
            })
        end
    end
    
    table.insert(activeEffects, effect)
    return effect.id
end

-- Update all effects
function VisualEffects.update(dt)
    for i = #activeEffects, 1, -1 do
        local effect = activeEffects[i]
        local elapsed = love.timer.getTime() - effect.startTime
        local progress = elapsed / effect.duration
        
        if progress >= 1.0 then
            -- Effect finished
            if effect.type == effectTypes.SHAKE and effect.target then
                -- Restore original position
                effect.target.x = effect.originalX
                effect.target.y = effect.originalY
            end
            table.remove(activeEffects, i)
        else
            -- Update effect
            VisualEffects.updateEffect(effect, dt, progress)
        end
    end
end

-- Update individual effect
function VisualEffects.updateEffect(effect, dt, progress)
    if effect.type == effectTypes.PARTICLE then
        for _, particle in ipairs(effect.particles) do
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.vy = particle.vy + (effect.gravity or 0) * dt
            particle.life = 1.0 - progress
        end
        
    elseif effect.type == effectTypes.SHAKE and effect.target then
        local intensity = effect.intensity * (1.0 - progress)
        effect.target.x = effect.originalX + math.random(-intensity, intensity)
        effect.target.y = effect.originalY + math.random(-intensity, intensity)
        
    elseif effect.type == effectTypes.TEXT_POP then
        if progress < 0.3 then
            effect.scale = effect.targetScale * (progress / 0.3)
        elseif progress < effect.fadeStart then
            effect.scale = effect.targetScale
        else
            effect.scale = effect.targetScale * (1.0 - (progress - effect.fadeStart) / (1.0 - effect.fadeStart))
        end
        
    elseif effect.type == effectTypes.SPARKLE then
        for _, sparkle in ipairs(effect.sparkles) do
            sparkle.phase = sparkle.phase + sparkle.speed * dt
        end
        
    elseif effect.type == effectTypes.ENERGY_FLOW then
        for _, particle in ipairs(effect.particles) do
            particle.progress = (particle.progress + dt / effect.duration) % 1.0
        end
    end
end

-- Draw all effects
function VisualEffects.draw()
    for _, effect in ipairs(activeEffects) do
        VisualEffects.drawEffect(effect)
    end
end

-- Draw individual effect
function VisualEffects.drawEffect(effect)
    local elapsed = love.timer.getTime() - effect.startTime
    local progress = elapsed / effect.duration
    
    if effect.type == effectTypes.PARTICLE then
        for _, particle in ipairs(effect.particles) do
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.life)
            if particleTexture then
                love.graphics.draw(particleTexture, particle.x - particle.size/2, particle.y - particle.size/2, 0,
                                 particle.size / 8, particle.size / 8)
            else
                love.graphics.circle("fill", particle.x, particle.y, particle.size)
            end
        end
        
    elseif effect.type == effectTypes.GLOW then
        local alpha = math.sin(progress * math.pi) * effect.intensity
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha * 0.3)
        for i = 1, 5 do
            love.graphics.circle("line", effect.x, effect.y, effect.radius + i * 3)
        end
        
    elseif effect.type == effectTypes.TEXT_POP then
        local alpha = 1.0
        if progress > effect.fadeStart then
            alpha = 1.0 - (progress - effect.fadeStart) / (1.0 - effect.fadeStart)
        end
        
        love.graphics.push()
        love.graphics.translate(effect.x, effect.y)
        love.graphics.scale(effect.scale, effect.scale)
        love.graphics.setFont(effect.font)
        love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], alpha)
        
        local textWidth = effect.font:getWidth(effect.text)
        local textHeight = effect.font:getHeight()
        love.graphics.print(effect.text, -textWidth/2, -textHeight/2)
        love.graphics.pop()
        
    elseif effect.type == effectTypes.SPARKLE then
        for _, sparkle in ipairs(effect.sparkles) do
            if elapsed > sparkle.delay then
                local sparkleAlpha = math.sin(sparkle.phase) * 0.5 + 0.5
                sparkleAlpha = sparkleAlpha * (1.0 - progress)
                love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], sparkleAlpha)
                love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
            end
        end
        
    elseif effect.type == effectTypes.ENERGY_FLOW then
        for _, particle in ipairs(effect.particles) do
            local x = effect.startX + (effect.endX - effect.startX) * particle.progress
            local y = effect.startY + (effect.endY - effect.startY) * particle.progress
            
            love.graphics.setColor(effect.color[1], effect.color[2], effect.color[3], particle.alpha)
            love.graphics.circle("fill", x, y, particle.size)
        end
    end
end

-- Convenience functions for common effects
function VisualEffects.explosion(x, y, color, intensity)
    intensity = intensity or 1.0
    return VisualEffects.create(effectTypes.PARTICLE, x, y, {
        count = math.floor(15 * intensity),
        color = color or Theme.colors.warning,
        spread = 80 * intensity,
        speed = 120 * intensity,
        gravity = 50,
        duration = 1.5
    })
end

function VisualEffects.sparkles(x, y, color, area)
    return VisualEffects.create(effectTypes.SPARKLE, x, y, {
        color = color or Theme.colors.primary,
        area = area or 100,
        count = 20,
        duration = 2.0
    })
end

function VisualEffects.textPop(x, y, text, color)
    return VisualEffects.create(effectTypes.TEXT_POP, x, y, {
        text = text,
        color = color or Theme.colors.success,
        duration = 1.5,
        scale = 1.8
    })
end

function VisualEffects.glow(x, y, color, radius, duration)
    return VisualEffects.create(effectTypes.GLOW, x, y, {
        color = color or Theme.colors.primary,
        radius = radius or 50,
        intensity = 0.8,
        duration = duration or 1.0
    })
end

function VisualEffects.shake(target, intensity, duration)
    return VisualEffects.create(effectTypes.SHAKE, 0, 0, {
        target = target,
        intensity = intensity or 10,
        duration = duration or 0.5
    })
end

function VisualEffects.energyFlow(startX, startY, endX, endY, color, duration)
    return VisualEffects.create(effectTypes.ENERGY_FLOW, 0, 0, {
        startX = startX,
        startY = startY,
        endX = endX,
        endY = endY,
        color = color or Theme.colors.primary,
        duration = duration or 1.0,
        particleCount = 8
    })
end

function VisualEffects.moneyGain(x, y, amount)
    VisualEffects.textPop(x, y, "+$" .. amount, Theme.colors.success)
    VisualEffects.sparkles(x, y, Theme.colors.success, 60)
end

function VisualEffects.powerPlantPurchase(x, y)
    VisualEffects.explosion(x, y, Theme.colors.warning, 1.2)
    VisualEffects.glow(x, y, Theme.colors.warning, 80, 1.5)
end

function VisualEffects.cityConnection(x, y)
    VisualEffects.sparkles(x, y, Theme.colors.primary, 50)
    VisualEffects.textPop(x, y + 30, "CONNECTED!", Theme.colors.primary)
end

-- Clean up all effects
function VisualEffects.clear()
    activeEffects = {}
end

-- Get effect count (for debugging)
function VisualEffects.getEffectCount()
    return #activeEffects
end

return VisualEffects