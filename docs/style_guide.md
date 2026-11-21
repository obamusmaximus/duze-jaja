# Visual style guide (outline)

The look of the game, UI first. This is an outline: it fixes the principles and the palette, and each section says what is still open. Hex values are the proposed palette; the code's colours should come from here (`UnitLook.TEAM_COLORS` and `RING_COLOR` already do).

## Principles
1. **Saturated, synthetic colour on neutral bases.** Accents are loud and artificial; everything around them is quiet, so an accent always means something.
2. **Readable at all times.** Contrast beats decoration. A player must read team, selection, health and orders at a glance, in a busy fight, at any zoom.
3. **Flat, hard-edged, geometric.** Surfaces are flat fills. Forms are rectangles, modular panels and grids. Rounded, organic shapes are rare and deliberate.

## Palette
**Accents** (meaning, never decoration):

| Role | Colour | Hex | Used for |
|---|---|---|---|
| Electric cyan | | `#00D9FF` | Player team, friendly information |
| UV violet | | `#9933FF` | Opposing team |
| Safety orange | | `#FF7300` | Warnings, damage, hostile orders, third team |
| Acid green | | `#B8FF00` | Selection, confirm, focus, fourth team |

**Bases:**

| Role | Hex | Used for |
|---|---|---|
| Deep black | `#0D0D10` | Panel backgrounds, text on light and on accents, the void around the map |
| Concrete grey | `#8A8A86` | Ground, secondary panels, disabled states |
| Bone | `#E3DDCB` | Panel fills in light mode, dividers |
| Off-white | `#F2F0E9` | Text on dark, highlights, bright surfaces |

Rules:
- Accents sit on a base, never on another accent. Text is deep black or off-white only.
- Keep text contrast at 4.5:1 or better against its background (check each accent/base pair when the theme is built; adjust the hex, not the rule).
- One accent colour per meaning. If two things need the same colour, one of them is wrong.
- Team colours are the first four accents in the order above; they also tint nothing but flat marks (base plates, bars, outlines), so models stay readable.

## UI
- **Surfaces:** flat fills, no gradients, no drop shadows, no glow, no blur. Depth comes from stacking tones (black, concrete, bone), not effects.
- **Shape:** rectangles with hard corners. Panels are modular and snap to a grid (one base unit for spacing; every margin and size is a multiple of it). Circles only where the thing is round by nature (a radar blip, a selection ring).
- **Borders:** thin, solid, one weight. Emphasis is a colour change or a heavier bar on one edge, not a bigger border.
- **Layout:** grids of equal cells for build and command buttons; the HUD is a frame around the map, not a layer of floating widgets.
- **Text:** one sans-serif family, upper case for labels, tabular figures for numbers. Sizes on a short scale (a few steps, not free choice).
- **States:** normal, hover, pressed, disabled, active are each a distinct flat colour pair from the palette, never opacity alone.
- **Motion:** short and linear (snaps, wipes, slides along the grid). No bounce or easing flourishes.
- **Implementation:** one Godot `Theme` resource holds the palette, `StyleBoxFlat` styles and fonts; scenes use theme variants, never per-node colour overrides. Palette values live in one place.

## In the world (placeholder art for now)
- **Models:** low-poly flat-shaded placeholders (Kenney Space Kit, `assets/README.md`); their white, grey and orange suit the neutral bases and the safety-orange accent.
- **Ground:** concrete grey with a thin panel grid (`levels/sandbox/ground_grid.gdshader`), which also shows scale. The void beyond is deep black.
- **Light:** neutral and bright, one shadow-casting sun; shading stays flat enough that the team marks read.
- **Team and selection marks:** a flat square base plate in the team colour under each unit; selection is the acid-green ring. Both are hard-edged and unshaded.

## Open
- Final hex values (the proposal above is untested against real screens and for colour-blind players; the team pair cyan/violet needs a colour-blind check, and a shape or pattern cue may be needed besides colour).
- Font choice and the type scale.
- The base spacing unit.
- Whether the HUD is dark, light, or switchable.
- Minimap, health bar and order-marker styling (bars today are the first pass).
- Whether the world art should later be recoloured or replaced to match the UI more closely.
