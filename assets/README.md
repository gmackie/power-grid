# Power Grid Digital - Placeholder Assets

This directory contains automatically generated placeholder assets for development purposes.

## What's Included

### UI Elements
- **Buttons**: Primary and secondary buttons in 3 sizes (large, medium, small) with 4 states each
- **Panels**: Background panels in 3 sizes for game UI
- **Icons**: Basic icons for settings, close, and back navigation

### Game Assets
- **Power Plant Cards**: Template backgrounds for all 7 plant types (coal, oil, garbage, uranium, hybrid, wind, solar)
- **Resource Icons**: Visual indicators for all 5 resource types
- **City Markers**: Regional city markers in 6 different colors

### Player Elements
- **Color Swatches**: Player color indicators for 6-player games

## File Formats

✅ **PNG files ready to use** - All assets have been converted from SVG to PNG format.
📁 **SVG source files included** - Original vector files for future editing and scaling.

## Ready to Use

All 54 placeholder assets are now available as PNG files and can be immediately loaded in LÖVE2D:

```lua
-- Example loading
local buttonImage = love.graphics.newImage("assets/ui/buttons/button_primary_medium_normal.png")
local resourceIcon = love.graphics.newImage("assets/game/resources/resource_coal.png")
```

## Testing Assets

Run the asset test to verify everything works:
```bash
love . --test-assets
```

This will load and display sample assets to confirm they're working properly.

## Asset Specifications

### Buttons
- **Large**: 300×60px - Main menu actions
- **Medium**: 200×50px - Standard UI interactions  
- **Small**: 150×40px - Secondary actions
- **States**: normal, hover, pressed, disabled

### Power Plant Cards
- **Size**: 180×120px (scales to game board)
- **Templates**: Background designs for each resource type
- **Areas**: Plant illustration, resource cost, power capacity

### Resource Icons
- **Size**: 32×32px base (scales for different UI contexts)
- **Types**: Coal, Oil, Garbage, Uranium, Hybrid
- **Usage**: Market display, player inventory, card details

### City Markers
- **Size**: 30×30px base
- **Regions**: Yellow, Purple, Blue, Brown, Red, Green
- **States**: Normal, selectable, owned, buildable

## Quality Notes

These are **simple geometric placeholders** designed to:
- ✅ Provide immediate visual structure
- ✅ Enable gameplay testing and development
- ✅ Serve as sizing/positioning references
- ✅ Work on all screen resolutions

They are **NOT production-ready** and should be replaced with professional artwork:
- ❌ Limited visual appeal
- ❌ Basic geometric shapes only
- ❌ No detailed illustrations
- ❌ Minimal branding elements

## Next Steps

1. **Test in Game**: Load these assets and verify they work properly
2. **Iterate on Sizes**: Adjust dimensions based on actual gameplay needs
3. **Professional Artwork**: Commission or create high-quality replacements
4. **Multiple Resolutions**: Create @1.5x and @2x versions for high-DPI displays

## Regenerating Assets

To regenerate or modify these placeholders:

```bash
# Regenerate all SVG assets
./generate_svg_assets.sh

# For Python version (requires PIL):
pip install Pillow
python3 generate_placeholder_assets.py
```

## Asset Organization

```
assets/
├── ui/
│   ├── buttons/          # All button states and sizes
│   ├── panels/           # Background panels
│   └── icons/            # UI navigation icons
├── game/
│   ├── power_plants/     # Card templates by type
│   ├── resources/        # Resource type icons
│   └── cities/           # City markers by region
└── players/
    └── colors/           # Player color swatches
```

This structure matches the specifications in `SPRITE_ASSET_SPECIFICATIONS.md` and provides a solid foundation for further development.