# Visual style guide (outline)

The look of the game, UI first. This is an outline: it fixes the principles and the palette, and each section says what is still open. Hex values are the proposed palette; the code takes every colour from `UiTokens`, which mirrors it.

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

**Bases** (and two dark tones between black and concrete, `GRAPHITE` for raised surfaces and `RULE` for thin lines, both in `UiTokens`):

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
- Team colours are the first four accents in the order above. On the world they tint flat marks (base plates, bars, outlines) and, while `WorldLookStats.team_livery` is on, a unit's livery parts; never a whole model.

## UI
- **Surfaces:** flat fills, no gradients, no drop shadows, no glow, no blur. Depth comes from stacking tones (black, concrete, bone), not effects.
- **Shape:** rectangles with hard corners. Panels are modular and snap to a grid (one base unit for spacing; every margin and size is a multiple of it). Circles only where the thing is round by nature (a radar blip, a selection ring).
- **Borders:** thin, solid, one weight. Emphasis is a colour change or a heavier bar on one edge, not a bigger border.
- **Layout:** grids of equal cells for build and command buttons; the HUD is a frame around the map, not a layer of floating widgets.
- **Text:** one neo-brutalist sans family with a width axis (Anybody): tall and narrow for labels and captions, wide and heavy for names and headings, condensed heavy for big figures. Upper case for labels, tabular figures for numbers. Sizes on a short scale (a few steps, not free choice).
- **Colour in use:** accents appear as solid fills, not only as lines: a header strip, a selected card, a team stripe. Light (bone, off-white) cards sit on dark panels for contrast. Empty or unavailable slots are hatched (thin diagonal lines), not greyed out.
- **Placement:** every HUD piece is a module that can sit in any corner, edge or the centre; edges can be framed as solid bands (the bottom bar, a sidebar).
- **States:** normal, hover, pressed, disabled, active are each a distinct flat colour pair from the palette, never opacity alone.
- **Motion:** short and linear (snaps, wipes, slides along the grid). No bounce or easing flourishes.
- **Implementation:** one Godot `Theme` resource holds the palette, `StyleBoxFlat` styles and fonts; scenes use theme variants, never per-node colour overrides. Palette values live in one place.

## Reference: Marathon (Bungie)
Marathon's look, which Bungie calls "graphic realism", is the main reference for the world. We take its principles, not its content.
- **Two halves:** a grounded side (realistic proportions and scale, objects that look like they do something) and a graphic side (flat colour blocking, bold markings, type and glyphs on objects, loud accents on quiet neutrals).
- **Why it suits low poly:** the look comes from silhouettes, big clean surfaces, colour blocks and markings, not from texture detail. A low-poly model with good proportions and colour blocking can carry it.
- **Livery, not paint jobs:** colour sits in deliberate blocks and stripes (race livery, in the spirit of WipEout and Formula 1), not spread across the whole model.
- **Make our own marks.** Never copy Marathon's graphics, glyphs or layouts; they're a reference for the approach only. Every marking, symbol and logo here is our own.

## In the world (placeholder art for now)
- **Models:** low-poly flat-shaded placeholders (Kenney Space Kit, `assets/README.md`), plus our own primitive-built models (rules below).
- **World palette and shared materials:** models are coloured in a few roles, not free colours. The role colours live in `UiTokens` (`WORLD_*`); `WorldMaterials` (`materials/world_materials.gd`) holds one shared material per role (one livery material per team), and its shading (roughness, specular, team livery on or off) is `WorldLookStats` (`tuning/world_look_default.tres`, Map tab). `ModelFit` recolours every imported model into the roles by its material names (`WorldMaterials.IMPORTED_ROLES`), so the Kenney kit's salmon rocks and orange trim come out in the palette.

| Role | Colour | Used for | Kenney material |
|---|---|---|---|
| `HULL` | bone | most of every model | `metal`, `_defaultMat` |
| `HULL_MID` | concrete | secondary panels | `metalDark` |
| `HULL_DARK` | rule grey | machinery, decks, recesses | `dark` |
| `TRIM` | graphite | vents, openings, edges | |
| `LIVERY` | team colour (dark hull tone without a team or with livery off) | a unit's accent parts | `metalRed` |
| `WARNING` | safety orange | hazard markings | |
| `STONE`, `STONE_DARK` | desaturated warm greys | rock and earth | `rock`, `rockTrack`, `rockDark` |
| `MINERAL` | off-white | crystals | `crystal` |
| `GRASS` | sage | grass, low ground cover (tinted terrain tiles) | |
| `LEAF`, `BARK` | olive, dark stone | tree canopies and trunks | `leaves`, `bark` (our tree models) |
| `SAND` | pale greyed sand | beaches, pale cliffs | |
| `SOIL` | greyed rust brown | Mars and other rust ground | |

- **Nature is muted and greyed**, so the accents always stand out against it: the sea is a dark slate (`WORLD_SEA_DEEP`, `WORLD_SEA_SHALLOW`), never cyan; plants are sage and olive, never acid green; soil is brown, never orange. Water reads its colours from the palette directly; terrain picks roles (`TerrainStats.tile_role`, `cliff_role`).
- **Marks** (plates, rings, deck lines) use `WorldMaterials.mark(color)`: unshaded, so they read the same in any light.
- **Ground:** concrete grey with a thin panel grid (`levels/sandbox/ground_grid.gdshader`), which also shows scale. The void beyond is deep black.
- **Light and air:** every level instances `WorldLight` (`lighting/world_light.tscn`) with a shared `LightStats` preset (Map tab): `light_day` (a pale sky fading to the haze colour at the horizon, haze over distance) or `light_void` (the black void, distance fading to black). One shadow-casting sun in the sun colour, haze-coloured ambient light, filmic tonemap with the exposure kept low enough that bone hulls don't blow out. Colours are palette roles (`WORLD_SKY`, `WORLD_HAZE`, `WORLD_SUN`, `WORLD_VOID`).
- **Team and selection marks:** a flat square base plate in the team colour under each unit; selection is the acid-green ring. Both are hard-edged and unshaded.
- **Scale is part of the look** (`GAME_DESIGN.md`, "A typical match"). Big things read as big through true proportions, many small parts next to large surfaces, haze with distance and slow, heavy motion.
- **Tilt-shift is part of the look:** the strategy view is a war table, a model of the battle seen from above, and a heavy tilt-shift blur sells that on purpose. A lighter blur fades in as the RTS camera zooms out, so the two views blend. Near RTS zoom and first person stay sharp.

## Prototyping rules (for anyone building world visuals, agents included)
Prototype art is built so the artist pass can replace it without touching gameplay, and so that everything already looks like one game.
1. **Colours come from the palette, through shared materials.** Never write a `Color` literal or make a new `StandardMaterial3D` in a model; use `WorldMaterials.role()` for surfaces and `WorldMaterials.mark()` for marks. Imported models get this through `ModelFit`. A colour that isn't in the palette is a style-guide question, not a local choice.
2. **Flat-shaded, matte, untextured.** Lit, high roughness, no metal, no textures, no normal maps, no emission (except effects). The Mobile renderer (`docs/performance.md`) must show it the same way.
3. **Mostly neutral.** A model is mostly base tones (off-white, concrete, graphite, black), with accent colour only in a few deliberate blocks. Team colour appears only in the team livery slot and on the base plate, never on the whole model.
4. **Build from hard-edged primitives.** Boxes, wedges and low-sided cylinders, joined at hard edges. Spheres and smooth curves only where the thing is round by nature (a radar dish, a tank).
5. **The silhouette comes first.** Each unit type must be told apart by shape alone at the farthest RTS zoom. Check that before adding detail.
6. **True scale, in metres.** Size things against the 2 m scale marker and what they'd be in the world; parts that imply function (hatches, rails, deck lines, ladders) show the scale. Don't scale a model up to make it read; that's the base plate's and the symbol's job.
7. **One scene per model, swappable.** A prototype model is a scene in its feature's `models/` folder, named `*_proto.tscn`, plugged in through the stats' `model` like an imported one (`ModelFit`). Gameplay never refers to a model's inner nodes, except named attachment points (muzzles, spawn points) the artist's version will also provide.
8. **Functional markings only.** Flat geometry or decals in palette colours may show what something does (landing pad outlines, capture rings, hazard edges, deck lanes). Type, logos, insignia and decorative graphics wait for the artist pass.
9. **One environment per level, from a shared set.** Every level instances `WorldLight` with a `LightStats` preset; never a WorldEnvironment or sun of its own. A level that needs different light gets a new preset `.tres`.
10. **Check in every view it'll be seen from:** far and near RTS zoom, and up close if the unit can be inhabited.

## Kept for the artist pass
Prototypes build working stand-ins for all of these; the real versions wait:
- Final models for the mothership, forward bases, carryalls, capture points and units, and the mothership interior. Stand-ins until then: the mothership, IFV and tank are primitive prototypes, and the carryall is the Space Kit's `craft_cargoA` at true scale (`docs/plans/battlefield.md` steps 6, 7 and 9).
- The war table's final look (table model of the map, unit tokens).
- The graphic layer: type on objects (hull numbers, labels), faction insignia, logos, decal sheets.
- Texturing approach (if any beyond flat colour), wear and dirt.
- Faction identity: how the sides differ in shape and livery.
- Final strategy-view symbols, cursors and icons.
- Final effects, animation (catapult launches, forward bases detaching), sky, water and terrain.
- The final colour grade, and the final hex values.

## Decided
- Base spacing unit: 8 px at the 1920x1080 base size. HUD is dark. The values live in `UiTokens` (`docs/mechanics/ui.md`).
- Font: Anybody (OFL, `assets/fonts/`), one variable file for every face.

## Open
- Final hex values (the proposal above is untested against real screens and for colour-blind players; the team pair cyan/violet needs a colour-blind check, and a shape or pattern cue may be needed besides colour).
- The type scale steps (in use, untested on real screens).
- Minimap, health bar and order-marker styling (bars today are the first pass).
- Whether the world art should later be recoloured or replaced to match the UI more closely.
- **The world palette.** Is bone right as the main hull tone (in use; concrete is the alternative)? The nature tones are a first pass, checked on the green island and the space demo only.
- **Team colour on models:** livery parts in the team colour (in use) or plates and marks only? `WorldLookStats.team_livery` switches between them live.
- **Scale policy:** units at true scale with plates and symbols carrying readability, or units exaggerated as now?
- **World effects:** is any glow, bloom or emission allowed in the world (muzzle flashes, engines, shields), or is the no-glow rule universal?
- **Haze and light:** whether haze should change with zoom, and whether level types need more presets (time of day, Mars dust).
- **Still off the palette:** the Mars level's ground grid colours (literals in `mars_outpost.tscn`) and the Kenney terrain tiles where they aren't tinted (Mars), the unit portrait's own light, and the debug ground grid's default colours.
- **How models get their colour:** one shared material per role (in use), or one small palette texture shared by all models (one swatch per colour), which also makes team colours and the final palette one swap.
- **Strategy-view symbols:** the symbol language (shapes per unit class, how team and state show).
- **Low-poly budget:** what "low poly" means in numbers per class (unit, building, mothership), so the artist pass matches.
