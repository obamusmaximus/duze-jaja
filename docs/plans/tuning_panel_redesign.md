# Tuning panel redesign (readability)

**Built** (steps 1 to 6 below, checked by screenshot at 2560x1440 and 1150x647; the file header and fold arrows are as planned, Back sits in the footer beside Reset and Save, and the optional "changed value" edge was not built). Result documented in `docs/mechanics/debug_tools.md`. Mechanic doc: `docs/mechanics/debug_tools.md`; look rules: `docs/style_guide.md`, tokens and theme: `docs/mechanics/ui.md`.

## What is wrong, and why
The panel was ported unchanged from `../first`, where it was readable by accident of scale. `first` has the stock Godot theme (16 px text) on a **2560x1440** base. Here the project theme applies to the panel, and the HUD type scale (`TEXT_BODY` 36, `TEXT_SMALL` 32, buttons and inputs at 36) is meant for a 1920x1080 HUD that must read in a 1150 px window. Text is about three times larger relative to the screen than in `first`, but the panel's own numbers were never changed:

| Symptom | Cause (file) |
|---|---|
| Row labels clip or collide with the slider | `TuningFields.LABEL_WIDTH` 190 px, `SLIDER_WIDTH` 220, `NUMBER_WIDTH` 110 are sized for 16 px text; "Max turn rate" at 36 px is already wider than 190 |
| Uneven spacing between rows, boxes and labels | Row heights come from each control's own font and theme box (36 px text in a `SpinBox`, a 16 px-era `CheckBox`, `ColorPickerButton` fixed at 24 px high), so nothing shares a baseline or a row height; no row is on the 8 px grid |
| Descriptions and preview title clipped | Preview column is a fixed 360 px, the panel max is 1160 px (a 2560-base number), the description's `custom_minimum_size` 360 plus margins of 20/16 px leave no room once the theme's panel border and content margins are added; the title is hard-clipped |
| Few rows visible | `MAX_TAB_HEIGHT` 460 and `room.y - 220` leave a short window; 36 px rows fill it with about eight lines |
| Off-style | Per-node overrides in the scene and `_fill_tab` (font sizes 18/28, the literal `Color(1.0, 0.8, 0.45)` amber headers, a grey literal): breaks "colours from `UiTokens`, theme variations not overrides" (`ui.md`, Known issues) |
| Wide, tall condensed Anybody at 36 px for a dense list | Anybody's width axis and heavy weights are for headings; as the body face of a 200-row tool it looks loose and unevenly spaced, particularly the tabular figures in the number boxes |

## Design principles for this panel
1. **A tool scale, not the HUD scale.** The tuning panel is a dev tool used at full screen, so it gets its own small type scale (below) and ignores the "readable in a small window" rule that sets the HUD scale. It must stay readable at 1440p and at 1080p; check at both.
2. **One row grid.** Every metric is a multiple of `UiTokens.UNIT` (8 px). All rows share one height; every row element is centred on it. No fixed pixel widths for text.
3. **Proportional layout.** The panel sizes to fractions of the viewport; row columns share space by stretch ratio, so a longer label never pushes the slider.
4. **Same style guide.** Flat fills, hard corners, one 2 px border weight, accents only as solid strips, states as flat colour pairs, hatching for empty/unavailable, no opacity-only states, no glow or shadow.
5. **No new literals.** Every colour, size and face comes from `UiTokens` and the generated theme; the panel uses theme variations.

## Type
Two roles, so the display face stays for structure and a plain face carries the reading:

| Role | Face | Size | Used for |
|---|---|---|---|
| Structure | Anybody, existing faces | `TEXT_TOOL_HEADING` 24 | Panel title, tab names (wide), group titles and resource headers (condensed, upper case) |
| Reading | a plain grotesque (below) | `TEXT_TOOL` 20 | Row labels, descriptions, status, buttons, preview title |
| Figures | same grotesque, tabular figures | `TEXT_TOOL` 20 | Number boxes, slider values |
| Fine print | same grotesque | `TEXT_TOOL_SMALL` 18 | Hints, "no diagram" note. Nothing below 18 |

At a 1920 base on a 1440p screen, 20 px is about 27 px on the panel, which is comfortable; it is roughly the size `first` shows. New tokens in `UiTokens`: `TEXT_TOOL_SMALL`, `TEXT_TOOL`, `TEXT_TOOL_HEADING`, `FACE_TOOL` (the reading face).

**Reading face: needs your decision (it adds an asset).** Candidates, all OFL, hinted for small UI sizes with tabular figures and a straight neutral grotesque skeleton that sits next to Anybody without competing with it:
- **IBM Plex Sans** (recommended): sturdy, rectilinear, designed for dense UI; has a condensed sibling if rows need more room.
- **Archivo**: same neo-grotesque lineage and a width axis, so it is the closest cousin to Anybody; slightly less crisp at 20 px.
- **No new font** (fallback): Anybody at `FACE_TEXT` with the width pulled to normal (about 100) and weight 450, kerning on. Cheapest, but the spacing complaint may partly remain.

Whichever is chosen goes in `assets/fonts/` with its licence and a line in `assets/README.md`.

## Layout
```
Panel: 90% x 88% of the viewport, centred, black fill, 2 px RULE border, 24 px padding
  Title strip:  "TUNING"  (bone strip, black text)                       [Back]
  Tabs:         flat tab bar, active tab acid green / black, others graphite / off-white
  Body (2 columns, 68% / 32%, 24 px gap)
    Left   ScrollContainer, one card per resource
             Resource header: green strip, black condensed caps, file name
             Group: foldable, title = condensed caps concrete, 2 px RULE underline, chevron at the left
             Rows:  [label 40%][ slider 40% ][ number 20% ]   row height 40 (5 units)
    Right  Preview: title (wide face), diagram holder, description (scrolls)
  Footer: status text left, [Reset tab] [Save tab to .tres] right
```
- **Rows:** label, editor and value are `size_flags_stretch_ratio` columns (labels: ellipsis on overflow, full name as the tooltip). Slider is 8 px thick (the theme's rail), number box is a right-aligned `LineEdit` look with the tabular face. Checkbox rows align the box to the editor column, not the label. Colour buttons are a flat swatch the row's height. Array fields: equal-width boxes sharing the editor column.
- **Row states** (flat fills): normal black; hover graphite; focused editor gets the green border the theme already has. Alternating bands are not used; a 1 px RULE line separates rows.
- **Preview:** its title and description sit on a `PanelInset` card with 16 px padding. The description wraps (`autowrap`) inside a fixed-height `ScrollContainer`; the panel never resizes with the hovered row (existing rule in `debug_tools.md`, Settled).
- **Narrow windows:** below about 1200 px width the preview column collapses to a toggle, as `fit_to_screen` does today, but by fraction, not a pixel constant.
- **Optional, nice for tuning:** a value that differs from the saved `.tres` gets an orange 6 px edge on its row (`ACCENT_BAR`), so "what did I change this session" is visible before Save. Cheap to do by comparing against the reload that Reset already makes.

## Theme and code changes (build order)
1. `UiTokens`: add the tool sizes and `FACE_TOOL`; add the font file if chosen (decision above).
2. `UiThemeBuilder` + `build_theme.gd`: add the variations `TuningTitle`, `TuningTab` (via `TabContainer`/`TabBar` colours), `TuningResourceHeader` (green strip), `TuningGroup` (the `FoldableContainer` title style), `TuningRow` (hover fill), `TuningLabel`, `TuningDescription`, `TuningNumber`; override `Label`, `LineEdit`/`SpinBox` font and size under a `TuningPanel` root theme type so the HUD faces are untouched. Regenerate: `godot --headless --script res://ui/theme/build_theme.gd`.
3. `tuning_panel.tscn`: remove every `theme_override_*`; set variations; use the proportional layout above; margins from `UiTokens.UNIT`.
4. `tuning_panel.gd`: replace `MAX_TAB_HEIGHT`, `MAX_WIDTH`, `-220` and `-40` with viewport fractions; `_fill_tab` makes the resource header from the variation, not font/colour overrides.
5. `tuning_fields.gd`: drop the three width constants for stretch ratios and a shared `ROW_HEIGHT` constant of `UiTokens.units(5)`; row builder sets variation, tooltip and ellipsis; checkbox and colour editors sized to the row.
6. `tuning_preview.gd` and the scene: card styling, wrapping, scroll area.
7. Verify by screenshot at 2560x1440 and 1920x1080 and at a 1150 px window, on the Units tab (most rows) and the Audio tab (long descriptions and `SfxCue`), plus a quick drag of a slider and a Reset to confirm nothing jumps.
8. Update `debug_tools.md` and `ui.md` (remove the per-node override issue), tick it in `STATUS.md`.

## Open questions
- Reading face: Plex Sans, Archivo or no new font (see Type).
- Should the panel have its own text-size step (`[` `]`-style, or a Debug-tab tunable) for other monitors, as `first` had `hud_scale`? Not needed if 20 px tests well at both resolutions; add only if it doesn't.
- Per-group "reset this group" buttons and a search box for the 200-odd properties are out of scope here; worth a later plan if scrolling stays slow.
