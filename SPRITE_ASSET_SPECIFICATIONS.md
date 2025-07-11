# Power Grid Digital - Sprite Asset Specifications

## Overview
This document provides comprehensive specifications for creating custom sprite assets to enhance the visual appeal of the Power Grid digital game. All assets should maintain the responsive design and mobile compatibility already built into the system.

## Technical Requirements

### **File Formats**
- **PNG with Alpha Channel** - For all UI elements and game sprites
- **SVG Source Files** - For vector-based elements that need scaling
- **Multiple Resolutions** - @1x, @1.5x, @2x for device density support

### **Base Design Specifications**
- **Target Resolution**: 1920×1080 (Full HD) as base design
- **Mobile Scaling**: 1.5x for phones, 1.2x for tablets
- **Touch Targets**: Minimum 44pt (iOS) / 48dp (Android) actual size
- **Safe Areas**: Account for notches and home indicators

### **Color Depth and Quality**
- **Color Mode**: RGB + Alpha
- **Bit Depth**: 32-bit (8-bit per channel + alpha)
- **Compression**: PNG-8 for simple graphics, PNG-24 for complex/gradient elements

---

## Asset Categories

## 1. **Core UI Elements** 🎯 *HIGH PRIORITY*

### **Buttons and Interactive Elements**

#### **Primary Buttons**
- **Base Size**: 200×50px (@1x)
- **States Required**: Normal, Hover, Pressed, Disabled
- **Style**: Rounded corners (8px radius), subtle gradient, drop shadow
- **Variants Needed**:
  - Large (300×60px) - Main menu actions
  - Medium (200×50px) - Standard UI
  - Small (150×40px) - Secondary actions
  - Mobile Touch (240×60px minimum) - Touch-optimized

#### **Icon Buttons** 
- **Base Size**: 48×48px (@1x)
- **States**: Normal, Hover, Pressed, Disabled
- **Icons Needed**:
  - Settings (gear)
  - Back/Close (arrow/X)
  - Refresh (circular arrow)
  - Help (question mark)
  - Volume (speaker)
  - Fullscreen (expand arrows)

#### **Input Fields**
- **Base Size**: 300×40px (@1x)
- **Components**: 9-patch design for scalability
- **States**: Normal, Focus, Error, Disabled
- **Elements**: Border, background, cursor indicator

#### **Checkboxes and Radio Buttons**
- **Checkbox Size**: 24×24px (@1x)
- **Radio Button Size**: 24×24px (@1x)
- **States**: Unchecked, Checked, Hover, Disabled
- **Style**: Modern flat design with subtle animations

### **Panels and Containers**

#### **Game Panel Backgrounds**
- **Sizes**: 
  - Small: 250×200px
  - Medium: 350×300px  
  - Large: 500×400px
- **Design**: 9-patch scalable panels
- **Style**: Semi-transparent with subtle borders
- **Variants**: Information panel, action panel, status panel

#### **Modal Dialog Backgrounds**
- **Base Size**: 600×400px
- **Design**: 9-patch with title area
- **Style**: Dark overlay with rounded panel
- **Elements**: Title bar, content area, button area

---

## 2. **Game-Specific Visual Elements** 🎯 *HIGH PRIORITY*

### **Power Plant Cards** ⚡ *CRITICAL*
*Most important visual element in the game*

#### **Card Framework**
- **Size**: 180×120px (@1x) - fits 2×4 grid layout
- **Design**: Playing card aesthetic with rounded corners
- **Components**:
  - Background template
  - Resource type indicator area
  - Power output number area
  - Resource cost area
  - Plant illustration area

#### **Resource Type Backgrounds** (7 variants)
- **Coal Plants**: Dark industrial theme, smokestack imagery
- **Oil Plants**: Golden/amber theme, oil derrick imagery  
- **Hybrid Plants**: Dual-colored theme, combined imagery
- **Garbage Plants**: Green/brown theme, recycling imagery
- **Uranium Plants**: Bright green theme, atomic symbol
- **Wind Plants**: Light blue theme, wind turbine imagery
- **Solar Plants**: Yellow/gold theme, solar panel imagery

#### **Power Plant Illustrations** (42 unique plants)
Based on `data/power_plants.json`, each plant needs unique artwork:
- **Coal Plants**: Various industrial designs (smokestacks, cooling towers)
- **Oil Plants**: Refineries, oil platforms, generators
- **Hybrid Plants**: Combined visual elements
- **Garbage Plants**: Waste-to-energy facilities, incinerators  
- **Uranium Plants**: Nuclear reactors, cooling towers
- **Wind Plants**: Wind farms, turbine arrays
- **Solar Plants**: Solar panels, solar thermal towers

### **Resource Tokens and Indicators**

#### **Resource Type Icons**
- **Size**: 32×32px (@1x)
- **Style**: Flat design with subtle 3D effect
- **Resources**:
  - Coal: Black cubic chunks
  - Oil: Oil barrel/drop
  - Garbage: Waste bin/recycling symbol
  - Uranium: Radioactive symbol/fuel rod
  - Hybrid: Combined icon

#### **Resource Storage Indicators**
- **Size**: 16×16px (@1x) for compact display
- **Style**: Simple, clear icons for inventory display
- **Animation**: Subtle glow for new resources

### **Map and City Elements**

#### **City Markers**
- **Base Size**: 30×30px (@1x)
- **Regional Variants** (6 different styles):
  - Yellow Region: Industrial/manufacturing theme
  - Purple Region: Technology/modern theme  
  - Blue Region: Coastal/maritime theme
  - Brown Region: Agricultural/rural theme
  - Red Region: Urban/metropolitan theme
  - Green Region: Environmental/renewable theme

#### **City States**
- **Normal**: Standard city marker
- **Selectable**: Highlighted border/glow
- **Owned**: Player color border/flag
- **Buildable**: Construction indicator

#### **Connection Lines and Costs**
- **Line Styles**: Various thickness and patterns for different costs
- **Cost Indicators**: Circular badges with numbers (15-25px diameter)
- **Style**: Clear, readable numbers with contrasting backgrounds

---

## 3. **Player Interface Elements** 🎯 *MEDIUM PRIORITY*

### **Player Color System**
- **Primary Colors**: Red, Blue, Green, Yellow, Purple, Orange
- **Elements Needed**:
  - Color picker swatches (40×40px)
  - Player badges/avatars (64×64px)
  - Ownership indicators (16×16px flags/markers)
  - Turn indicators (highlighting elements)

### **Game Phase Indicators**
- **Phase Icons** (32×32px each):
  - Player Order: Numbered list icon
  - Auction: Gavel/hammer icon
  - Resource Buying: Shopping cart/coins
  - Building: Construction/hammer
  - Bureaucracy: Money/calculator

### **Status and Information Displays**
- **Money Indicators**: Coin/dollar symbols
- **Score Displays**: Trophy/star icons
- **Timer Elements**: Clock/hourglass icons
- **Connection Status**: Wifi/network icons

---

## 4. **Menu and Navigation** 🎯 *MEDIUM PRIORITY*

### **Main Menu Graphics**
- **Logo/Title Treatment**: 
  - High-quality title graphics
  - Power Grid branding elements
  - Electrical/grid themed decorations

### **Background Elements**
- **Menu Backgrounds**: 
  - Subtle electrical grid patterns
  - Power plant silhouettes
  - Industrial landscape themes
- **Animated Elements**: 
  - Subtle power line animations
  - Flowing electricity effects

### **Navigation Icons**
- **Menu Navigation**: Hamburger, arrows, home
- **Game Navigation**: Previous/next, skip, confirm
- **Social Features**: Share, invite, profile

---

## 5. **Mobile-Specific Enhancements** 📱 *MEDIUM PRIORITY*

### **Touch Feedback Elements**
- **Ripple Effects**: Circular expansion animations
- **Highlight States**: Touch-optimized visual feedback
- **Gesture Indicators**: Swipe arrows, pinch indicators

### **Mobile UI Adaptations**
- **Large Touch Targets**: 60×60px minimum for important actions
- **Thumb-Friendly Layouts**: Bottom-accessible primary actions
- **Safe Area Graphics**: Decorative elements that avoid notches

---

## 6. **Visual Effects and Polish** 🎯 *LOW PRIORITY*

### **Particle Effects**
- **Electrical Sparks**: Power plant activation
- **Money Particles**: Income generation
- **Construction Dust**: Building animations
- **Success Celebrations**: Achievement unlocks

### **Transition Animations**
- **Screen Transitions**: Slide, fade, scale effects
- **Card Flip Animations**: Power plant reveals
- **Number Count-ups**: Score and money changes

---

## Art Style Guidelines

### **Overall Aesthetic**
- **Style**: Modern industrial with clean UI design
- **Inspiration**: Industrial infrastructure, electrical systems, clean energy
- **Tone**: Professional, technological, slightly futuristic

### **Color Palette**
#### **Primary Colors**
- **Dark Blue**: #1a237e (Primary UI)
- **Electric Blue**: #2196f3 (Accents)
- **Steel Gray**: #455a64 (Backgrounds)
- **White**: #ffffff (Text/Contrast)

#### **Resource Colors** (from current implementation)
- **Coal**: #333333 (Dark Gray)
- **Oil**: #cccc33 (Yellow) 
- **Hybrid**: #cc6633 (Orange)
- **Garbage**: #666666 (Gray)
- **Uranium**: #33cc33 (Green)
- **Wind**: #99ccff (Light Blue)
- **Solar**: #ffcc33 (Gold)

#### **Regional Colors**
- **Yellow Region**: #ffeb3b
- **Purple Region**: #9c27b0  
- **Blue Region**: #2196f3
- **Brown Region**: #795548
- **Red Region**: #f44336
- **Green Region**: #4caf50

### **Typography Integration**
- **UI Text**: Clean, modern sans-serif
- **Numbers**: Monospace for consistent alignment
- **Titles**: Bold, industrial-style headers

---

## Asset Organization and Naming

### **Directory Structure**
```
assets/
├── ui/
│   ├── buttons/
│   ├── panels/
│   ├── icons/
│   └── inputs/
├── game/
│   ├── power_plants/
│   ├── resources/
│   ├── cities/
│   └── maps/
├── players/
│   ├── colors/
│   └── indicators/
└── effects/
    ├── particles/
    └── animations/
```

### **Naming Convention**
- **Format**: `category_element_state_resolution.png`
- **Examples**:
  - `button_primary_normal_1x.png`
  - `power_plant_coal_03_1x.png`
  - `city_yellow_region_normal_2x.png`

### **Multi-Resolution Exports**
- **@1x**: Base resolution for 1920×1080 screens
- **@1.5x**: 1.5× scale for high-DPI mobile devices  
- **@2x**: 2× scale for retina displays

---

## Implementation Priority

### **Phase 1: Core Gameplay** (Week 1-2)
1. Power plant card backgrounds and templates
2. Resource type icons and indicators  
3. Basic button styling
4. City markers and map elements

### **Phase 2: UI Enhancement** (Week 3-4)
1. Panel backgrounds and containers
2. Player color system
3. Phase indicators
4. Input field styling

### **Phase 3: Polish and Effects** (Week 5-6)
1. Menu graphics and branding
2. Visual effects and animations
3. Mobile-specific enhancements
4. Final polish and optimization

---

## Quality Assurance

### **Testing Requirements**
- **Multiple Resolutions**: Test on 1920×1080, 1366×768, mobile sizes
- **Device Testing**: iOS/Android phones and tablets
- **Performance**: Ensure 60fps with all sprites loaded
- **Accessibility**: Sufficient contrast ratios for text readability

### **Review Checkpoints**
1. **Art Direction Review**: Style consistency and brand alignment
2. **Technical Review**: File size optimization and format validation
3. **User Experience Review**: Usability and visual hierarchy
4. **Performance Review**: Loading times and memory usage

This specification provides a complete roadmap for creating professional-quality sprite assets that will significantly enhance the visual appeal of Power Grid Digital while maintaining excellent performance and mobile compatibility.