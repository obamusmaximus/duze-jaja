# UI layer: tokens, theme, components, HUD

The look of every 2D surface, built from the style guide (`docs/style_guide.md`). Views only: nothing here changes the game except camera jumps from the minimap. Tunables: `UiStats` (`tuning/ui_default.tres`, Controls tab), sizes in base units.

**Scripts:** `ui/ui_tokens.gd`; `ui/theme/ui_theme_builder.gd`, `style_box_hatch.gd`, `build_theme.gd`, `game_theme.tres`; `ui/components/` (`stat_bar.gd`, `stat_row.gd`, `command_grid.gd`, `minimap.gd`, `unit_portrait.gd`); `ui/hud/` (`hud.gd` + `hud.tscn`, `hud_frame.gd`, `hud_layout.gd`, `hud_placement.gd`, `hud_context.gd`, `hud_module.gd`), `ui/hud/modules/*_module.gd` + `.tscn`, `ui/hud/layouts/*.tres`. Font: `assets/fonts/anybody_variable.ttf`. Wired in `levels/sandbox/sandbox.gd` (both levels instance `hud.tscn`).

## How it works
- **`UiTokens`** is the only place with hex values and scales: four accents, four bases, two stacked dark tones (`GRAPHITE` for raised surfaces, `RULE` for thin lines), the world palette roles (`WORLD_*`, used by `WorldMaterials`), `team_color()`, the spacing `UNIT`, the border weight, the type scale (`TEXT_*`), the faces (`FACE_*`), hatch spacing and the low-health threshold. World marks read it too.
- **Type:** one family, Anybody, a variable font. A face is a (width, weight) pair on its axes: condensed (tall and narrow, labels and captions), text, numbers, wide (names, headings, titles), display (big figures). `UiThemeBuilder.face()` makes a `FontVariation` per face, always with tabular figures. OpenType axis and feature keys must be tag integers (`TextServer.name_to_tag`); string keys are silently ignored.
- **The theme** is generated: after changing tokens or the builder run `godot --headless --script res://ui/theme/build_theme.gd`. Flat `StyleBoxFlat`s with hard corners and one border weight, plus `StyleBoxHatch` (diagonal lines on a fill: empty or unavailable slots). Scenes and code use variations, never per-node colours or sizes:
  - Panels: default (graphite), `PanelDeep`, `PanelInset` (black), `PanelLight` (bone), `PanelBright` (off-white), `PanelAccent` (acid green), `PanelHatch`, `PanelClear`; modules: `ModuleFrame`, `ModuleHeader` (bone strip), `ModuleHeaderAccent` (green strip), `ModuleBody`; `HudBandTop/Bottom/Left/Right` (black with a rule on the map side); tags `Tag`, `TagLight`, `TagAccent`.
  - Labels: default (text face), `LabelDark`, `LabelCaption` / `LabelCaptionLight` / `LabelCaptionDark` / `LabelMuted` (condensed), `LabelNumber`, `LabelNumberDark`, `LabelWarning` (orange figures), `LabelHeading`, `LabelHeadingDark`, `LabelTitle` (wide), `LabelDisplay`.
  - Buttons (condensed): graphite/off-white, hover bone/black, pressed green/black, disabled hatched. `CommandCell`: bone/black, hover green/black, pressed black/green, disabled hatched with a "+".
- **Components** are small and theme-driven: `StatBar` (thin rule track with tenth ticks, solid fill, orange when low), `StatRow` (caption, optional bar, figure), `CommandGrid` (equal square `CommandCell`s, `set_cell` / `clear_cell`), `Minimap` (north-up field, rule grid, corner brackets, team blips, the camera's ground footprint; left press or drag calls `CameraRig.focus_on`), `UnitPortrait` (the model turning in its own small 3D world over a transparent background).
- **HUD layout.** `Hud` (`CanvasLayer`) takes a `HudLayout` and `setup(selection, team, area, rig)`, then `HudFrame` builds the screen:
  - The screen is nine sections (`HudPlacement.Section`: corners, edges, centre). A `HudPlacement` puts a module scene in a section, with an `order` and an optional `expand` (take the leftover room along the edge).
  - An edge in `HudLayout.bands` is framed: a solid band across the whole edge that holds its sections and blocks clicks to the map. Unframed sections float, and only modules take clicks. `sides_first` lets side bands run the full height (C&C sidebar) instead of top and bottom running the full width (Generals bar).
  - Layouts: `generals.tres` (bottom band: map, selection expanding, command grid; clock top-left, forces top-right), `sidebar.tres` (full-height right band). `Hud.band_rects()` gives the framed screen areas.
- **Modules** extend `HudModule`: a card with a header strip (title, a note at the right; `set_active` turns it green) over a body. They get a `HudContext` (selection, team, map area, rig, stats) through `bind`, size themselves from `UiStats` and re-apply on its `changed`, and never assume their section. Built: `MinimapModule`; `SelectionModule` (none: hatched slot; one: portrait, wide name, health row, stat chips; several: bone cards per type with count and health, plus the group's health); `CommandModule` (empty grid); `ClockModule` (match time); `ForceModule` (living units and total health per team, yours first). A new module is a `HudModule` script plus a one-node scene, placed by a layout.

## Settled
- Base size is 1920x1080 (the project stretch), unit 8 px, type scale 32/36/44/64/88: text must stay readable in a small play window (about 1150 px wide), so sizes are large relative to the layout. the HUD is dark, with bone and acid-green header strips as the saturated relief.
- Health bars (world and HUD) are the team colour, orange at low health; no traffic-light gradient.
- Hostile orders (attack, attack-move) are orange, move confirm is acid green.

## Tried and passed on
- System fonts (`SystemFont` with a stretch or an x-scaled `variation_transform`): Godot scales outlines but not advances, and no common OS ships a wide face; replaced by Anybody.
- One fixed bottom bar scene: couldn't put modules on other edges or corners; replaced by layouts and modules.

## Known issues
- Labels are upper-cased by hand in code (the theme can't do it).
- The command grid is an empty placeholder; no enemy inspect, no alert area. The selection module's single view leaves room under the chips.
- Attack and attack-move markers share orange; a shape cue is still open. Cyan/violet needs the colour-blind check.
- The camera does not keep clear of framed bands yet (`band_rects()` is there for it).
- The debug tuning panel inherits the theme but its own header colours are per-node overrides.
- Level art off the palette: ground reads bone-white under the sun; sea and foliage on the green island sit near the cyan and green accents (`docs/style_guide.md`, Open).
