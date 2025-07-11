# Power Grid Digital - Priority Asset List

## **IMMEDIATE IMPACT ASSETS** 🚀
*These will dramatically improve the game's visual appeal with minimal effort*

### **1. Power Plant Cards** ⚡ *CRITICAL - START HERE*
**Impact**: Transforms the most important game element
```
Required: 7 card background templates + 42 unique plant illustrations
Sizes: 180×120px (@1x), 270×180px (@1.5x), 360×240px (@2x)
Files: power_plant_[type]_[number]_[resolution].png
```

**Quick Win Approach:**
- Create 7 beautiful card background templates (one per resource type)
- Use procedural or simple geometric plant illustrations initially
- Add detailed illustrations in Phase 2

### **2. Resource Icons** 💎 *HIGH IMPACT*
**Impact**: Makes resource management intuitive and attractive
```
Required: 5 resource type icons
Sizes: 32×32px (@1x), 48×48px (@1.5x), 64×64px (@2x)
Files: resource_[type]_[resolution].png
Types: coal, oil, garbage, uranium, hybrid
```

### **3. Primary Buttons** 🔘 *HIGH IMPACT*
**Impact**: Professional UI appearance across all screens
```
Required: 4 button states × 3 sizes = 12 assets
States: normal, hover, pressed, disabled
Sizes: large (300×60px), medium (200×50px), small (150×40px)
Files: button_[size]_[state]_[resolution].png
```

---

## **PHASE 1: Core Game Elements** (Week 1)
*Focus on gameplay-critical visual elements*

### **City Markers and Map Elements**
```
Cities: 30×30px base, 6 regional variants
Connection indicators: 20×20px circular badges
Map legend elements: Various sizes
```

### **Player Color System**
```
Color picker swatches: 40×40px
Player badges: 64×64px  
Ownership flags: 24×24px
```

### **Basic Panel Backgrounds**
```
Game info panels: 350×300px (9-patch design)
Modal dialogs: 600×400px
Side panels: 250×400px
```

---

## **PHASE 2: UI Enhancement** (Week 2)
*Polish the user interface*

### **Input Fields and Form Elements**
```
Text inputs: 300×40px (9-patch)
Checkboxes: 24×24px (checked/unchecked)
Dropdowns: Variable width, 40px height
```

### **Game Phase Indicators**
```
Phase icons: 32×32px each
Turn indicators: 48×48px
Status badges: 24×24px
```

### **Navigation and Menu Icons**
```
Standard icons: 24×24px
Large touch icons: 48×48px
Menu decorative elements: Various sizes
```

---

## **PHASE 3: Polish and Effects** (Week 3)
*Add visual flair and mobile optimization*

### **Menu Graphics and Branding**
```
Game logo/title: 600×150px
Background patterns: Tileable textures
Decorative elements: Various sizes
```

### **Visual Effects**
```
Particle textures: 16×16px to 64×64px
Animation frames: Sprite sheets
Transition elements: Various sizes
```

### **Mobile-Specific Assets**
```
Touch feedback: Ripple effect textures
Large touch targets: 60×60px minimum
Safe area decorations: Edge-aware graphics
```

---

## **Asset Creation Tools and Workflow**

### **Recommended Tools**
- **Vector Graphics**: Adobe Illustrator, Figma, or Inkscape
- **Pixel Art/Details**: Photoshop, GIMP, or Aseprite  
- **Batch Export**: TexturePacker, Figma plugins, or custom scripts

### **Workflow**
1. **Design in Vector** (SVG) at high resolution
2. **Export Multiple Sizes** (@1x, @1.5x, @2x)
3. **Optimize PNG Files** (TinyPNG, ImageOptim)
4. **Test in Game** (Love2D hot-reload)
5. **Iterate Based on Feedback**

---

## **Quick Start Guide** 🏃‍♂️

### **Day 1: Power Plant Cards**
1. Create 7 card background templates using the resource colors
2. Add basic plant silhouettes/icons for each type
3. Implement card rendering system with new sprites
4. Test on mobile and desktop

### **Day 2: Resources and Buttons** 
1. Design 5 resource icons (coal, oil, garbage, uranium, hybrid)
2. Create button sprite set (normal, hover, pressed states)
3. Update UI components to use new sprites
4. Polish and test responsive scaling

### **Day 3: Map and Cities**
1. Design city markers for 6 regions
2. Create connection line styles and cost indicators
3. Add player ownership visual indicators
4. Test map readability and touch targets

---

## **Success Metrics** 📊

### **Visual Quality Improvements**
- [ ] Power plant cards look professional and distinct
- [ ] Resource types are immediately recognizable
- [ ] UI feels modern and polished
- [ ] Map is clear and easy to navigate
- [ ] Player ownership is obvious at a glance

### **Technical Performance**
- [ ] All sprites load within 2 seconds
- [ ] Game maintains 60fps with full sprite set
- [ ] Mobile devices handle all assets smoothly
- [ ] Total asset size under 50MB

### **User Experience**
- [ ] Touch targets are comfortable on mobile
- [ ] Visual hierarchy guides player attention
- [ ] Color accessibility meets WCAG standards
- [ ] Game feels premium and professional

---

## **File Size Budget** 💾

### **Target Sizes**
- **Power Plant Cards**: ~2MB total (42 cards × 3 resolutions)
- **UI Elements**: ~5MB total (buttons, panels, icons)
- **Map Elements**: ~1MB total (cities, connections)
- **Effects/Polish**: ~2MB total
- **Total Target**: Under 10MB for core assets

### **Optimization Strategy**
1. **Use PNG-8** for simple graphics (solid colors, icons)
2. **Use PNG-24** only for gradients and complex illustrations
3. **Compress sprites** with tools like TinyPNG
4. **Consider sprite sheets** for small repeated elements
5. **Load assets on-demand** for non-critical elements

This priority list focuses on maximum visual impact with efficient resource allocation, ensuring the game looks professional while maintaining excellent performance on all target devices.