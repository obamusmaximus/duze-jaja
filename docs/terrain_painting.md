# Painting terrain in Krita

How-to for sculpting a heightmap by hand: the brush, setting an exact height, and the rules to keep terrain believable and playable. The file format and the in-game keys are in `docs/mechanics/heightmap.md` (Authoring); this page is the working method. Numbers below use the defaults in `HeightmapStats` (-50 m to +150 m over 200 m, 4 m per pixel, sea at 0 m). If a default changes, the formulas still hold; use the values in the stats resource.

## 1. Set up the file

1. Open the heightmap PNG in Krita (the atoll's is `levels/atoll/heightmap.png`; the path is `HeightmapStats.source_path`).
2. Check **Image > Image Properties**: greyscale, 16-bit integer, and the pixel size shown in the game's log or the reference layer. Don't resize or crop; the game refuses a PNG of a different size.
3. Paint on the image's own layer. Add the reference layer (`reference_layer.png`, from key 0 in the game) as a **separate layer above it**, and hide it before you export. Never export with it visible.
4. Export with **File > Export** as PNG: no interlacing, no alpha, keep 16 bits. Save the `.kra` source file too; the PNG is what the game reads.

## 2. Set up the brush

Krita's brush is a **preset** (brush engine + shape + settings). Make two presets and switch between them.

- **Soft (hills, valleys, slopes):** Brush Preset Editor: Hardness 0–40%, Spacing small (10% or so), Flow below 100% so strokes build up.
- **Hard (cliffs, coastlines, plateaus, anything with an exact edge):** Pixel Brush Engine, Hardness 100%, Flow 100%, Opacity 100%. The pixel engine draws whole pixels with no blended edge, so every pixel is exactly the value you chose. A soft brush mixes values at the edge, which is the usual source of stray heights.

Tool Options (Settings > Dockers > Tool Options, if it's hidden):

- **Size:** the diameter in pixels. Press `]` to grow and `[` to shrink, or use the slider. One pixel is 4 m, so the diameter in metres is `size × 4`; a 10-pixel brush is 40 m across.
- **Opacity and Flow:** leave at 100% for exact values (hard brush). Lower Flow on a soft brush to build a slope up in layers.
- **Stabilizer / smoothing:** off. It smooths the stroke and pulls the line off where you clicked.
- **Pressure:** if you use a mouse, turn size and opacity pressure off, or strokes thin out.

Coarse or fine is just size. Use a big soft brush for the broad shape of a hill, then a small hard brush for its edges and any crest. Never paint detail smaller than about two pixels (8 m); the game can't store it.

## 3. Paint an exact height (for example, an outline just above the beach)

The grey value of a pixel is its height:

    grey % = (height in m - min_height) / height_range

With the defaults: grey % = (h + 50) / 200. So sea level (0 m) is 25%, and a beach at +2 m is 26%.

Steps to outline the island at a set height:

1. Find the height you want. Turn on height bands (key 9) and read the contour lines; the reference layer's ruler shows grey patches with their metres.
2. In the Colour Selector docker, set the foreground colour to a **greyscale** value at that percentage (the Value/brightness slider in HSV, with saturation 0). Check the number with the **Colour Picker** tool, which sets the foreground colour from the pixel under the cursor. Click a painted pixel and read it back before you trust the value.
3. Paint the outline with the hard pixel brush. Keep it one or two pixels wide and closed (no gaps).
4. Fill the inside with the **Fill tool** at the same colour (threshold 0 so it stops at the outline) or by painting. For the sea-side of the outline, use the same method with a lower value.
5. Check the edges: in the game, turn on height bands and the map grid (key 8). If the waterline (orange) doesn't sit where the beach should, fix it in Krita and re-import with F6.

**Why this works:** the game reads height from the pixel value, so one value painted over a region is one height across that region. Stray pixels at a different value show as spikes.

## 4. Ground rules

These keep the terrain readable, playable and close to a real coast. The game enforces some of them (slope, see below); the rest are how to judge a painting.

**Scale.** One pixel is 4 m with the defaults. Anything under about 8 m is lost. Plan features at 20 m or more.

**Slope and walkability.** Cells steeper than `MapStats.max_slope_deg` (default 35°) are blocked. With 4 m pixels, 35° is a rise of about 2.8 m over one pixel. Keep most open ground below about 15°, which is about 1.1 m per 4 m. Make a cliff on purpose: a single steep step that you want blocked. Never let a steep slope appear by accident in a place units must cross.

**Passes.** A gap between two blocked areas must stay wide enough for units to walk through, with clearance (`MapStats.path_clearance`). Check chokepoints with the map grid (key 8) and the debug wall (key 7) before you call a pass open.

**Coasts.** The coastline is where the land crosses sea level (0 m, grey 25% by default). Make it irregular: bays, headlands, a few offshore rocks, and a beach band a metre or two above sea level that is gentle enough to walk on. A coast that is a clean line of one value looks like a stamp.

**Islands.** Build the seabed too: a shelf that falls gently under the sea, then deeper. The seabed is in the same image, so a slow fall below 0 m also sets the shallows the water shows.

**Hills.** Round in plan, gentle on every side, with a summit that is not a single point. Use a soft brush and vary the radius. A hill with one flat top and one height is a table.

**Mountains.** Steeper upper slopes than the foothills (mountains are steep high up and easy at the foot). Put ridges and spurs running down from the crest, not a cone. Keep a pass through them, or make them a wall on purpose.

**Valleys and drainage.** Water runs downhill. Valleys should open toward the sea, and ridges should not cross a valley without a dip. A valley with no outlet looks like a mistake.

**Atolls.** A low rim around a lagoon; the lagoon floor sits below sea level and the rim is only just above it. Break the rim with a few gaps so the lagoon is reachable or not, on purpose.

**Avoid:**

- one-pixel spikes and pits (they become cliffs or bumps in the mesh);
- hard straight lines where nature would curve, unless the line is a cliff or a road;
- noise over everything (uniform texture reads as fake; vary the scale instead);
- plateaus with hard edges that aren't cliffs;
- identical hills copied in a row.

**Check in the game.** After each pass: F6 to re-import, then look at the height bands (9), the map grid (8) and a unit path across the new ground. If a unit path goes through a cliff or refuses a gap it should take, fix the image, not the grid.

## 5. Save and recover

- The game does not undo. Save the work in Krita (`.kra`) before you test.
- F7 writes the in-game brush work back to the PNG; F6 re-imports the PNG and discards unsaved in-game edits.
- Keep the `.kra` as the source; treat the PNG as the export.

## Open questions

- The beach height and cliff steepness are design choices, not settled numbers; try a few and keep what plays.
- The Krita colour value display may show percentages from 8-bit values; trust the Colour Picker and the ruler, then confirm with the game's bands.
