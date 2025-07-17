-- Asset Loader for Power Grid Digital
-- Loads and manages placeholder assets

local AssetLoader = {}

-- Asset cache
local loadedAssets = {}

-- Asset paths
local ASSET_PATHS = {
    -- UI Buttons
    button_primary_large_normal = "assets/ui/buttons/button_primary_large_normal.png",
    button_primary_large_hover = "assets/ui/buttons/button_primary_large_hover.png",
    button_primary_large_pressed = "assets/ui/buttons/button_primary_large_pressed.png",
    button_primary_large_disabled = "assets/ui/buttons/button_primary_large_disabled.png",
    
    button_primary_medium_normal = "assets/ui/buttons/button_primary_medium_normal.png",
    button_primary_medium_hover = "assets/ui/buttons/button_primary_medium_hover.png",
    button_primary_medium_pressed = "assets/ui/buttons/button_primary_medium_pressed.png",
    button_primary_medium_disabled = "assets/ui/buttons/button_primary_medium_disabled.png",
    
    button_primary_small_normal = "assets/ui/buttons/button_primary_small_normal.png",
    button_primary_small_hover = "assets/ui/buttons/button_primary_small_hover.png",
    button_primary_small_pressed = "assets/ui/buttons/button_primary_small_pressed.png",
    button_primary_small_disabled = "assets/ui/buttons/button_primary_small_disabled.png",
    
    -- Secondary buttons
    button_secondary_medium_normal = "assets/ui/buttons/button_secondary_medium_normal.png",
    button_secondary_medium_hover = "assets/ui/buttons/button_secondary_medium_hover.png",
    button_secondary_medium_pressed = "assets/ui/buttons/button_secondary_medium_pressed.png",
    button_secondary_medium_disabled = "assets/ui/buttons/button_secondary_medium_disabled.png",
    
    -- UI Panels
    panel_small = "assets/ui/panels/panel_small.png",
    panel_medium = "assets/ui/panels/panel_medium.png",
    panel_large = "assets/ui/panels/panel_large.png",
    
    -- UI Icons
    icon_settings = "assets/ui/icons/icon_settings.png",
    icon_close = "assets/ui/icons/icon_close.png",
    icon_back = "assets/ui/icons/icon_back.png",
    
    -- Resource Icons
    resource_coal = "assets/game/resources/resource_coal.png",
    resource_oil = "assets/game/resources/resource_oil.png",
    resource_garbage = "assets/game/resources/resource_garbage.png",
    resource_uranium = "assets/game/resources/resource_uranium.png",
    resource_hybrid = "assets/game/resources/resource_hybrid.png",
    
    -- Power Plant Cards
    card_template_coal = "assets/game/power_plants/card_template_coal.png",
    card_template_oil = "assets/game/power_plants/card_template_oil.png",
    card_template_garbage = "assets/game/power_plants/card_template_garbage.png",
    card_template_uranium = "assets/game/power_plants/card_template_uranium.png",
    card_template_hybrid = "assets/game/power_plants/card_template_hybrid.png",
    card_template_wind = "assets/game/power_plants/card_template_wind.png",
    card_template_solar = "assets/game/power_plants/card_template_solar.png",
    
    -- City Markers
    city_yellow = "assets/game/cities/city_yellow.png",
    city_purple = "assets/game/cities/city_purple.png",
    city_blue = "assets/game/cities/city_blue.png",
    city_brown = "assets/game/cities/city_brown.png",
    city_red = "assets/game/cities/city_red.png",
    city_green = "assets/game/cities/city_green.png",
    
    -- Player Colors
    color_red = "assets/players/colors/color_red.png",
    color_blue = "assets/players/colors/color_blue.png",
    color_green = "assets/players/colors/color_green.png",
    color_yellow = "assets/players/colors/color_yellow.png",
    color_purple = "assets/players/colors/color_purple.png",
    color_orange = "assets/players/colors/color_orange.png"
}

-- Load a single asset
function AssetLoader.load(assetName)
    if loadedAssets[assetName] then
        return loadedAssets[assetName]
    end
    
    local path = ASSET_PATHS[assetName]
    if not path then
        print("Warning: Unknown asset name: " .. tostring(assetName))
        return nil
    end
    
    local success, image = pcall(love.graphics.newImage, path)
    if success then
        loadedAssets[assetName] = image
        print("Loaded asset: " .. assetName .. " from " .. path)
        return image
    else
        print("Failed to load asset: " .. assetName .. " from " .. path)
        return nil
    end
end

-- Load multiple assets
function AssetLoader.loadMultiple(assetNames)
    local results = {}
    for _, name in ipairs(assetNames) do
        results[name] = AssetLoader.load(name)
    end
    return results
end

-- Load all assets (for preloading)
function AssetLoader.loadAll()
    print("Loading all placeholder assets...")
    local loaded = 0
    local failed = 0
    
    for assetName, _ in pairs(ASSET_PATHS) do
        if AssetLoader.load(assetName) then
            loaded = loaded + 1
        else
            failed = failed + 1
        end
    end
    
    print(string.format("Asset loading complete: %d loaded, %d failed", loaded, failed))
    return loaded, failed
end

-- Get button asset for specific state
function AssetLoader.getButton(size, type, state)
    size = size or "medium"  -- small, medium, large
    type = type or "primary"  -- primary, secondary
    state = state or "normal"  -- normal, hover, pressed, disabled
    
    local assetName = string.format("button_%s_%s_%s", type, size, state)
    return AssetLoader.load(assetName)
end

-- Get resource icon
function AssetLoader.getResource(resourceType)
    local assetName = "resource_" .. string.lower(resourceType)
    return AssetLoader.load(assetName)
end

-- Get power plant card template
function AssetLoader.getPowerPlantCard(plantType)
    local assetName = "card_template_" .. string.lower(plantType)
    return AssetLoader.load(assetName)
end

-- Get city marker
function AssetLoader.getCity(regionColor)
    local assetName = "city_" .. string.lower(regionColor)
    return AssetLoader.load(assetName)
end

-- Get player color swatch
function AssetLoader.getPlayerColor(colorName)
    local assetName = "color_" .. string.lower(colorName)
    return AssetLoader.load(assetName)
end

-- Check if assets are available
function AssetLoader.checkAssets()
    local available = 0
    local total = 0
    
    for assetName, path in pairs(ASSET_PATHS) do
        total = total + 1
        local info = love.filesystem.getInfo(path)
        if info and info.type == "file" then
            available = available + 1
        end
    end
    
    return available, total
end

return AssetLoader