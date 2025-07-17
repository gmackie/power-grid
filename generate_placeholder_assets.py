#!/usr/bin/env python3
"""
Power Grid Digital - Placeholder Asset Generator
Generates simple geometric placeholder assets for development
"""

import os
from PIL import Image, ImageDraw, ImageFont

# Create directories
def ensure_directories():
    directories = [
        "assets/ui/buttons",
        "assets/ui/panels", 
        "assets/ui/icons",
        "assets/game/power_plants",
        "assets/game/resources",
        "assets/game/cities",
        "assets/players/colors"
    ]
    for dir in directories:
        os.makedirs(dir, exist_ok=True)

# Color definitions
COLORS = {
    'primary_button': (51, 128, 204),  # Blue
    'secondary_button': (153, 153, 153),  # Gray
    'panel_bg': (51, 51, 77, 230),  # Dark blue with transparency
    'panel_border': (128, 128, 153),
    
    # Resource colors
    'coal': (51, 51, 51),
    'oil': (204, 204, 51),
    'garbage': (102, 153, 102),
    'uranium': (51, 204, 51),
    'hybrid': (204, 102, 51),
    'wind': (153, 204, 255),
    'solar': (255, 204, 51),
    
    # Region colors
    'yellow_region': (255, 235, 59),
    'purple_region': (156, 39, 176),
    'blue_region': (33, 150, 243),
    'brown_region': (121, 85, 72),
    'red_region': (244, 67, 54),
    'green_region': (76, 175, 80),
    
    # Player colors
    'player_red': (204, 51, 51),
    'player_blue': (51, 102, 204),
    'player_green': (51, 178, 51),
    'player_yellow': (230, 204, 51),
    'player_purple': (153, 51, 204),
    'player_orange': (230, 128, 26)
}

def create_button(width, height, color, state):
    """Create a button with rounded corners"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Adjust color for state
    r, g, b = color
    if state == 'hover':
        r, g, b = min(255, int(r * 1.2)), min(255, int(g * 1.2)), min(255, int(b * 1.2))
    elif state == 'pressed':
        r, g, b = int(r * 0.8), int(g * 0.8), int(b * 0.8)
    elif state == 'disabled':
        r, g, b = 128, 128, 128
    
    # Draw rounded rectangle
    radius = 8
    draw.rounded_rectangle([0, 0, width-1, height-1], radius=radius, fill=(r, g, b, 255), outline=(0, 0, 0, 77), width=2)
    
    return img

def create_panel(width, height):
    """Create a panel with rounded corners and semi-transparency"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background
    draw.rounded_rectangle([0, 0, width-1, height-1], radius=12, 
                          fill=COLORS['panel_bg'], 
                          outline=COLORS['panel_border'], width=2)
    
    return img

def create_icon(size, icon_type):
    """Create simple icons"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    color = (51, 51, 51, 255)
    center = size // 2
    
    if icon_type == 'settings':
        # Gear shape (simplified)
        draw.ellipse([size*0.2, size*0.2, size*0.8, size*0.8], fill=color)
        draw.ellipse([size*0.35, size*0.35, size*0.65, size*0.65], fill=(255, 255, 255, 255))
    
    elif icon_type == 'close':
        # X shape
        thickness = 3
        draw.line([size*0.25, size*0.25, size*0.75, size*0.75], fill=color, width=thickness)
        draw.line([size*0.75, size*0.25, size*0.25, size*0.75], fill=color, width=thickness)
    
    elif icon_type == 'back':
        # Arrow left
        points = [
            (size*0.7, size*0.3),
            (size*0.3, size*0.5),
            (size*0.7, size*0.7)
        ]
        draw.polygon(points, fill=color)
    
    return img

def create_resource_icon(size, resource_type):
    """Create resource icons"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    color = COLORS.get(resource_type.lower(), (128, 128, 128))
    
    if resource_type == 'coal':
        # Cubic chunks
        draw.rectangle([size*0.2, size*0.2, size*0.8, size*0.8], fill=color)
    
    elif resource_type == 'oil':
        # Oil barrel
        draw.ellipse([size*0.2, size*0.1, size*0.8, size*0.9], fill=color)
    
    elif resource_type == 'uranium':
        # Radioactive symbol
        draw.ellipse([size*0.2, size*0.2, size*0.8, size*0.8], fill=color)
        draw.ellipse([size*0.4, size*0.4, size*0.6, size*0.6], fill=(0, 0, 0, 255))
    
    elif resource_type == 'garbage':
        # Recycling symbol (simplified)
        draw.rectangle([size*0.2, size*0.1, size*0.8, size*0.9], fill=color)
    
    elif resource_type == 'hybrid':
        # Combined elements
        draw.rectangle([size*0.1, size*0.2, size*0.45, size*0.8], fill=COLORS['coal'])
        draw.rectangle([size*0.55, size*0.2, size*0.9, size*0.8], fill=COLORS['oil'])
    
    return img

def create_power_plant_card(width, height, plant_type):
    """Create power plant card templates"""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Get color for plant type
    color = COLORS.get(plant_type.lower(), (128, 128, 128))
    bg_color = color + (230,)  # Add transparency
    
    # Card background
    draw.rounded_rectangle([0, 0, width-1, height-1], radius=8, fill=bg_color, outline=(0, 0, 0, 204), width=2)
    
    # Plant icon area
    draw.rounded_rectangle([width*0.1, height*0.1, width*0.9, height*0.65], 
                          radius=4, fill=(26, 26, 26, 77))
    
    # Resource cost area
    draw.rounded_rectangle([width*0.1, height*0.75, width*0.45, height*0.95], 
                          radius=4, fill=(255, 255, 255, 230))
    
    # Capacity area
    draw.rounded_rectangle([width*0.55, height*0.75, width*0.9, height*0.95], 
                          radius=4, fill=(255, 255, 255, 230))
    
    return img

def create_city_marker(size, region_color):
    """Create city markers"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    radius = int(size * 0.4)
    
    # City circle
    draw.ellipse([center-radius, center-radius, center+radius, center+radius], 
                fill=region_color, outline=(0, 0, 0, 255), width=2)
    
    # Inner dot
    inner_radius = int(size * 0.15)
    draw.ellipse([center-inner_radius, center-inner_radius, 
                 center+inner_radius, center+inner_radius], 
                fill=(255, 255, 255, 255))
    
    return img

def create_player_color_swatch(size, color):
    """Create player color swatches"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=4, 
                          fill=color + (255,), outline=(0, 0, 0, 255), width=2)
    
    return img

def generate_all_assets():
    """Generate all placeholder assets"""
    print("Generating placeholder assets...")
    ensure_directories()
    
    # Generate buttons
    button_sizes = [
        ('large', 300, 60),
        ('medium', 200, 50),
        ('small', 150, 40)
    ]
    states = ['normal', 'hover', 'pressed', 'disabled']
    
    for size_name, width, height in button_sizes:
        for state in states:
            # Primary buttons
            img = create_button(width, height, COLORS['primary_button'], state)
            img.save(f"assets/ui/buttons/button_primary_{size_name}_{state}.png")
            
            # Secondary buttons
            img = create_button(width, height, COLORS['secondary_button'], state)
            img.save(f"assets/ui/buttons/button_secondary_{size_name}_{state}.png")
    
    # Generate icons
    icons = ['settings', 'close', 'back']
    for icon in icons:
        img = create_icon(48, icon)
        img.save(f"assets/ui/icons/icon_{icon}.png")
    
    # Generate panels
    panel_sizes = [
        ('small', 250, 200),
        ('medium', 350, 300),
        ('large', 500, 400)
    ]
    for size_name, width, height in panel_sizes:
        img = create_panel(width, height)
        img.save(f"assets/ui/panels/panel_{size_name}.png")
    
    # Generate resource icons
    resources = ['coal', 'oil', 'garbage', 'uranium', 'hybrid']
    for resource in resources:
        img = create_resource_icon(32, resource)
        img.save(f"assets/game/resources/resource_{resource}.png")
    
    # Generate power plant card templates
    plant_types = ['coal', 'oil', 'garbage', 'uranium', 'hybrid', 'wind', 'solar']
    for plant_type in plant_types:
        img = create_power_plant_card(180, 120, plant_type)
        img.save(f"assets/game/power_plants/card_template_{plant_type}.png")
    
    # Generate city markers
    regions = [
        ('yellow', COLORS['yellow_region']),
        ('purple', COLORS['purple_region']),
        ('blue', COLORS['blue_region']),
        ('brown', COLORS['brown_region']),
        ('red', COLORS['red_region']),
        ('green', COLORS['green_region'])
    ]
    for region_name, color in regions:
        img = create_city_marker(30, color)
        img.save(f"assets/game/cities/city_{region_name}.png")
    
    # Generate player color swatches
    player_colors = [
        ('red', COLORS['player_red']),
        ('blue', COLORS['player_blue']),
        ('green', COLORS['player_green']),
        ('yellow', COLORS['player_yellow']),
        ('purple', COLORS['player_purple']),
        ('orange', COLORS['player_orange'])
    ]
    for color_name, color in player_colors:
        img = create_player_color_swatch(40, color)
        img.save(f"assets/players/colors/color_{color_name}.png")
    
    print("✓ Placeholder assets generated successfully!")
    print("✓ Assets created in: assets/ directory")
    print("\nNext steps:")
    print("1. Run the game to see the placeholders in action")
    print("2. Replace these with professional artwork when available")
    print("3. Consider creating @1.5x and @2x versions for high-DPI displays")

if __name__ == "__main__":
    try:
        from PIL import Image, ImageDraw
        generate_all_assets()
    except ImportError:
        print("Error: Pillow (PIL) is required to generate assets.")
        print("Install it with: pip install Pillow")
        print("\nAlternatively, you can create these assets manually using any graphics editor.")
        print("See SPRITE_ASSET_SPECIFICATIONS.md for detailed requirements.")