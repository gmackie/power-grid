#!/bin/bash
# Power Grid Digital - SVG Placeholder Asset Generator
# Creates simple SVG placeholders that can be converted to PNG or used directly

echo "Creating placeholder SVG assets..."

# Create directories
mkdir -p assets/ui/buttons
mkdir -p assets/ui/panels
mkdir -p assets/ui/icons
mkdir -p assets/game/power_plants
mkdir -p assets/game/resources
mkdir -p assets/game/cities
mkdir -p assets/players/colors

# Function to create a button SVG
create_button() {
    local width=$1
    local height=$2
    local color=$3
    local state=$4
    local type=$5
    local filename=$6
    
    local fill_color="$color"
    local opacity="1"
    
    case $state in
        "hover")
            opacity="0.8"
            ;;
        "pressed")
            fill_color="#666666"
            ;;
        "disabled")
            fill_color="#999999"
            opacity="0.5"
            ;;
    esac
    
    cat > "$filename" << EOF
<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="$width" height="$height" rx="8" ry="8" 
        fill="$fill_color" opacity="$opacity" stroke="#000000" stroke-width="2" stroke-opacity="0.3"/>
  <text x="50%" y="50%" text-anchor="middle" dy=".3em" 
        font-family="Arial" font-size="14" fill="#FFFFFF">$type</text>
</svg>
EOF
}

# Function to create an icon SVG
create_icon() {
    local size=$1
    local type=$2
    local filename=$3
    
    case $type in
        "settings")
            cat > "$filename" << EOF
<svg width="$size" height="$size" xmlns="http://www.w3.org/2000/svg">
  <circle cx="$((size/2))" cy="$((size/2))" r="$((size/3))" fill="#333333"/>
  <circle cx="$((size/2))" cy="$((size/2))" r="$((size/6))" fill="#FFFFFF"/>
</svg>
EOF
            ;;
        "close")
            cat > "$filename" << EOF
<svg width="$size" height="$size" xmlns="http://www.w3.org/2000/svg">
  <line x1="$((size/4))" y1="$((size/4))" x2="$((3*size/4))" y2="$((3*size/4))" 
        stroke="#333333" stroke-width="3" stroke-linecap="round"/>
  <line x1="$((3*size/4))" y1="$((size/4))" x2="$((size/4))" y2="$((3*size/4))" 
        stroke="#333333" stroke-width="3" stroke-linecap="round"/>
</svg>
EOF
            ;;
        "back")
            cat > "$filename" << EOF
<svg width="$size" height="$size" xmlns="http://www.w3.org/2000/svg">
  <polygon points="$((7*size/10)),$((3*size/10)) $((3*size/10)),$((size/2)) $((7*size/10)),$((7*size/10))" 
           fill="#333333"/>
</svg>
EOF
            ;;
    esac
}

# Function to create a resource icon SVG
create_resource() {
    local size=$1
    local type=$2
    local filename=$3
    local color=""
    
    case $type in
        "coal") color="#333333" ;;
        "oil") color="#CCCC33" ;;
        "garbage") color="#669966" ;;
        "uranium") color="#33CC33" ;;
        "hybrid") color="#CC6633" ;;
    esac
    
    cat > "$filename" << EOF
<svg width="$size" height="$size" xmlns="http://www.w3.org/2000/svg">
  <rect x="$((size/5))" y="$((size/5))" width="$((3*size/5))" height="$((3*size/5))" 
        fill="$color" stroke="#000000" stroke-width="1"/>
  <text x="50%" y="50%" text-anchor="middle" dy=".3em" 
        font-family="Arial" font-size="10" fill="#FFFFFF">${type:0:1}</text>
</svg>
EOF
}

# Function to create a power plant card SVG
create_power_plant() {
    local width=$1
    local height=$2
    local type=$3
    local filename=$4
    local color=""
    
    case $type in
        "coal") color="#4D4D4D" ;;
        "oil") color="#999933" ;;
        "garbage") color="#668866" ;;
        "uranium") color="#339933" ;;
        "hybrid") color="#996633" ;;
        "wind") color="#99CCFF" ;;
        "solar") color="#FFCC33" ;;
    esac
    
    cat > "$filename" << EOF
<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="$width" height="$height" rx="8" ry="8" 
        fill="$color" fill-opacity="0.9" stroke="#000000" stroke-width="2"/>
  <rect x="$((width/10))" y="$((height/10))" width="$((8*width/10))" height="$((6*height/10))" 
        rx="4" ry="4" fill="#1A1A1A" fill-opacity="0.3"/>
  <rect x="$((width/10))" y="$((3*height/4))" width="$((35*width/100))" height="$((height/5))" 
        rx="4" ry="4" fill="#FFFFFF" fill-opacity="0.9"/>
  <rect x="$((55*width/100))" y="$((3*height/4))" width="$((35*width/100))" height="$((height/5))" 
        rx="4" ry="4" fill="#FFFFFF" fill-opacity="0.9"/>
  <text x="50%" y="40%" text-anchor="middle" font-family="Arial" font-size="20" fill="#FFFFFF">$type</text>
</svg>
EOF
}

# Function to create a city marker SVG
create_city() {
    local size=$1
    local region=$2
    local filename=$3
    local color=""
    
    case $region in
        "yellow") color="#FFEB3B" ;;
        "purple") color="#9C27B0" ;;
        "blue") color="#2196F3" ;;
        "brown") color="#795548" ;;
        "red") color="#F44336" ;;
        "green") color="#4CAF50" ;;
    esac
    
    cat > "$filename" << EOF
<svg width="$size" height="$size" xmlns="http://www.w3.org/2000/svg">
  <circle cx="$((size/2))" cy="$((size/2))" r="$((2*size/5))" 
          fill="$color" stroke="#000000" stroke-width="2"/>
  <circle cx="$((size/2))" cy="$((size/2))" r="$((3*size/20))" fill="#FFFFFF"/>
</svg>
EOF
}

# Function to create a panel SVG
create_panel() {
    local width=$1
    local height=$2
    local filename=$3
    
    cat > "$filename" << EOF
<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="$width" height="$height" rx="12" ry="12" 
        fill="#33334D" fill-opacity="0.9" stroke="#808099" stroke-width="2"/>
</svg>
EOF
}

# Generate buttons
echo "Creating buttons..."
for size in "large:300:60" "medium:200:50" "small:150:40"; do
    IFS=':' read -r name width height <<< "$size"
    for state in normal hover pressed disabled; do
        create_button $width $height "#3380CC" $state "Primary" "assets/ui/buttons/button_primary_${name}_${state}.svg"
        create_button $width $height "#999999" $state "Secondary" "assets/ui/buttons/button_secondary_${name}_${state}.svg"
    done
done

# Generate icons
echo "Creating icons..."
for icon in settings close back; do
    create_icon 48 $icon "assets/ui/icons/icon_${icon}.svg"
done

# Generate panels
echo "Creating panels..."
create_panel 250 200 "assets/ui/panels/panel_small.svg"
create_panel 350 300 "assets/ui/panels/panel_medium.svg"
create_panel 500 400 "assets/ui/panels/panel_large.svg"

# Generate resources
echo "Creating resource icons..."
for resource in coal oil garbage uranium hybrid; do
    create_resource 32 $resource "assets/game/resources/resource_${resource}.svg"
done

# Generate power plant cards
echo "Creating power plant cards..."
for plant in coal oil garbage uranium hybrid wind solar; do
    create_power_plant 180 120 $plant "assets/game/power_plants/card_template_${plant}.svg"
done

# Generate city markers
echo "Creating city markers..."
for city in yellow purple blue brown red green; do
    create_city 30 $city "assets/game/cities/city_${city}.svg"
done

# Generate player color swatches
echo "Creating player colors..."
for color in "red:#CC3333" "blue:#3366CC" "green:#33B233" "yellow:#E6CC33" "purple:#9933CC" "orange:#E6801A"; do
    IFS=':' read -r name hex <<< "$color"
    cat > "assets/players/colors/color_${name}.svg" << EOF
<svg width="40" height="40" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="40" height="40" rx="4" ry="4" 
        fill="$hex" stroke="#000000" stroke-width="2"/>
</svg>
EOF
done

echo "✓ SVG placeholder assets created successfully!"
echo ""
echo "Note: These are SVG files. To use them in LÖVE2D, you have options:"
echo "1. Convert to PNG using ImageMagick: convert file.svg file.png"
echo "2. Use an SVG loader library for LÖVE2D"
echo "3. Use these as reference to create proper PNG assets"
echo ""
echo "To batch convert all SVGs to PNGs (requires ImageMagick):"
echo "find assets -name '*.svg' -exec sh -c 'convert \"$1\" \"\${1%.svg}.png\"' _ {} \;"