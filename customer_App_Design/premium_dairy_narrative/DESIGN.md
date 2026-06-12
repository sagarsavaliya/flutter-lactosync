---
name: Premium Dairy Narrative
colors:
  surface: '#faf9f8'
  surface-dim: '#dbdad9'
  surface-bright: '#faf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f3'
  surface-container: '#efeded'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e3e2e2'
  on-surface: '#1b1c1c'
  on-surface-variant: '#404943'
  inverse-surface: '#303030'
  inverse-on-surface: '#f2f0f0'
  outline: '#707973'
  outline-variant: '#bfc9c1'
  surface-tint: '#2c694e'
  primary: '#0f5238'
  on-primary: '#ffffff'
  primary-container: '#2d6a4f'
  on-primary-container: '#a8e7c5'
  inverse-primary: '#95d4b3'
  secondary: '#57615c'
  on-secondary: '#ffffff'
  secondary-container: '#d8e2dc'
  on-secondary-container: '#5b6560'
  tertiary: '#384c43'
  on-tertiary: '#ffffff'
  tertiary-container: '#4f645b'
  on-tertiary-container: '#c9dfd4'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b1f0ce'
  primary-fixed-dim: '#95d4b3'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#0e5138'
  secondary-fixed: '#dbe5df'
  secondary-fixed-dim: '#bfc9c3'
  on-secondary-fixed: '#151d1a'
  on-secondary-fixed-variant: '#3f4945'
  tertiary-fixed: '#d1e8dc'
  tertiary-fixed-dim: '#b5ccc0'
  on-tertiary-fixed: '#0b1f18'
  on-tertiary-fixed-variant: '#374b42'
  background: '#faf9f8'
  on-background: '#1b1c1c'
  surface-variant: '#e3e2e2'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  title-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  margin-mobile: 20px
  margin-desktop: 40px
  gutter: 16px
---

## Brand & Style
The design system is built for a premium, farm-to-table digital experience that emphasizes freshness, trust, and effortless utility. Drawing inspiration from modern high-utility apps like Google Pay and Uber, it employs a refined **Corporate/Modern** aesthetic with **Material 3** principles.

The target audience seeks quality and reliability. The UI evokes a "breath of fresh air" through generous whitespace, high-contrast legibility, and a tactile sense of depth. It avoids visual clutter, favoring a functional minimalism that feels expensive yet accessible.

## Colors
This design system utilizes a "Nature-Premium" palette. 
- **Emerald Green (#2D6A4F):** Used for primary actions, success states, and brand-heavy components.
- **Sage Green (#D8E2DC):** Used for secondary containers, soft backgrounds, and non-critical highlights.
- **Charcoal (#2D2E2E):** The primary text color, providing softer contrast than pure black for improved readability.
- **Surface/Background:** A pristine white base with very light green-tinted grays for surface elevation tiers to maintain a "fresh" feel.

## Typography
The typography system relies on **Inter** to deliver a systematic, utilitarian, and modern feel. 
- **Hierarchy:** High contrast in scale between headlines and body text is essential for the "Modern 2026" look.
- **Weight:** Headlines use Bold (700) or SemiBold (600) to anchor the page. 
- **Accessibility:** Line heights are generous (minimum 1.4x-1.5x for body text) to ensure legibility for users of all ages.
- **Mobile optimization:** Display styles scale down significantly for mobile devices to prevent awkward text wrapping.

## Layout & Spacing
This design system follows a **fluid grid** model with a base-8 spacing rhythm. 
- **Margins:** A standard 20px horizontal margin is used on mobile to provide breathing room.
- **Touch Targets:** All interactive elements (buttons, icons, list items) must maintain a minimum height/width of 48px.
- **Rhythm:** Vertical spacing between sections should be aggressive (32px+) to emphasize the premium, spacious feel.
- **Consistency:** Use the `lg` (24px) unit for internal card padding to align with the large corner radii.

## Elevation & Depth
In line with Material 3, the system uses **Tonal Layers** combined with **Ambient Shadows**.
- **Level 0 (Flat):** Main background.
- **Level 1 (Soft Elevation):** Primary cards and containers. Use a very soft, diffused shadow: `0px 4px 20px rgba(0, 0, 0, 0.04)`.
- **Level 2 (Active):** Hover or pressed states. Use a slightly deeper shadow: `0px 8px 30px rgba(45, 106, 79, 0.08)` (note the primary color tinting).
- **Surface Tinting:** Elements at higher elevations may take on a slight Sage Green tint to indicate depth rather than relying solely on shadows.

## Shapes
The shape language is defined by **organic, high-radius curves** that feel soft and friendly. 
- **Primary Containers:** Cards, buttons, and input fields use a base of **24px** (rounded-xl) or higher.
- **Contextual Shapes:** Small badges or chips use fully rounded (pill) shapes.
- **Imagery:** Product photos should use the same 24px corner radius to maintain visual harmony with the UI containers.

## Components
- **Buttons:** Large, high-visibility buttons with 24px+ corner radius. Primary buttons use Emerald Green with white text. Secondary buttons use Sage Green with Emerald Green text.
- **Cards:** White or very light Sage backgrounds. No borders; use Level 1 shadows for definition. Internal padding must be at least 24px.
- **Chips:** Used for dairy categories (e.g., "Organic," "A2," "Fermented"). These are pill-shaped with subtle Sage Green backgrounds.
- **Lists:** Clean, spacious rows with a minimum height of 72px for items containing subtitles. Use thin, light-gray dividers (0.5px) or simple whitespace separation.
- **Input Fields:** Filled style (Material 3) with a soft Sage background and no border until focused. Focus state uses a 2px Emerald Green stroke.
- **Quantity Pickers:** Large, tactile "plus/minus" controls with high-contrast icons to ensure accessibility during quick shopping.