# Plan: match flow

Build order from the match-flow design discussion (`GAME_DESIGN.md`, `docs/brainstorm.md`). Steps 1 to 3 are written out; later steps are one-line sketches and get written out with the user before they start. No tunable values here: name the parameter, put the number in `tuning/`.

## Steps
1. [x] **Airfield preset.** One per team, placed by the level on the team's island, on the plateau closer to its mothership. Six helipads (a hangar each, placeholder art). Read first: `docs/mechanics/carryall.md` (pads, leaving a pad), `flight_model.md` (autopilot), `orders.md`.
   - **`Pad`**: a reusable landing spot with a reservation (one craft at a time), a hover point above it and a quick descent. The same `Pad` serves every later pad (step 2).
   - **Landing to repair:** a flyer ordered onto the airfield (left-click it in the RTS view) reserves a free pad, flies to its hover point, descends, and repairs while it sits there (rate in the airfield's stats). All pads taken: it waits at a holding point near the airfield.
   - **"Seek the nearest airfield"** order: picks the nearest own airfield with a free pad (later including the mothership's). Usable from the RTS view and from first person (the autopilot flies it in).
   - All flyers land VTOL-style in v1 (runways later).
   - **Done when:** the fighter and the VTOL land on the atoll airfield, repair, take off on the next order; a seventh flyer waits; headless test for reservation and repair.
2. **Mothership pads** (split in two).
   - 2a. [x] **Carryall pads and helipads.** The four carryall pads and six helipads are `Pad`s (`DeckAirfield`, `airfield.md`); carryalls return to a free pad, and the helipads count for "seek the nearest airfield". With it, at the user's request: carryall deploy (F), deploy from the cockpit, and test units spread over the team islands.
   - 2b. [x] **Explorer pad.** The mothership's Explorer pad builds Explorers and loads them with units (no build time for those), from its own strategy HUD panel, through `CommandIssuer`. The test Explorers on the islands stay; no limit per team (`explorer.md`).
3. **Night lighting pass** (split in three). The atoll becomes a night map: an arcade night, not a difficulty setting (`GAME_DESIGN.md`, "Time of day"). For all three:
   - **Light never changes what anyone knows.** Detection and the simulation never read light; moon shadows and lamps neither hide nor reveal. All of this is view code.
   - **Night is a change of hue more than of brightness:** blue fill keeps a floor under shadows; exposure stays near day's, because it also dims the unshaded team plates and effects.
   - **No lamp or real light is needed to read anything:** team plates, blips, bars and outlines carry readability.
   - Units get no terrain shadow. The war table stays as it is.
   - 3a. [x] **Moon and its shadows.** Read first: `docs/mechanics/heightmap.md` ("Baked light"), `water.md`, `docs/style_guide.md` (prototyping rules).
     - `light_night.tres` for the atoll: a low moon from the north or south, across the west-east team axis, so shadows fall mirrored for the two teams. New night colour roles in `UiTokens` for sky, haze, ambient and moon, chosen by the preset (`light_day` stays as it looks now).
     - The sun or moon shadow leaves the terrain's vertex colours (hollows and tint stay) and becomes a **mask texture**, one byte per height sample, that blocks only the directional light: in a new terrain shader (palette roles, vertex colours and overlays as now; omni and spot lights unaffected) and in the sea, whose self-lit body colour also darkens in shadow, or it won't show.
     - The trace reaches the longest shadow: check `light_reach`, and fix `TerrainLight.shadow_reach()`, which assumes less relief than the atoll has, so an edit can leave stale shadows downwind. An edit updates the mask over everything downwind of it.
     - A debug day/night toggle (`debug/`, an input action, listed on the Tab page).
     - **Done when:** from the bird's-eye view the island's shadows read as clear shapes on land and sea; a searchlight lights ground inside a moon shadow as brightly as outside it; screenshots by day and night; headless test that an edit updates the mask downwind; atoll load time and an edit's bake time noted under "Measured".
   - 3b. [x] **Readability by night.** (Built; the user's judgement on their own screen is the open part of "Done when".) Read first: `docs/mechanics/birds_eye.md`, `water.md`.
     - Follows the preset: the sea's self-lit colour, foam glow and glitter (its path must not swamp units or blips), the bird's-eye post haze, the cloud colours, and much weaker cloud shadows (they'd be confused with moon shadows).
     - A debug check that takes the same fixed shots by day and by night (RTS view on lit ground, on shadowed ground and on sea; a ridge line; bird's-eye; cockpit) and reports each test unit's luminance contrast against what's behind it.
     - **Done when:** no pale day colours are left at night; night contrast holds up against day's in every shot (day is the baseline, not proof that day is good enough); the user has judged it on their own screen.
   - 3c. [x] **Lamps** (`docs/mechanics/lamps.md`). Read first: `docs/mechanics/explorer.md` (`ExplorerLook`), `airfield.md`, `units.md`. Wingtips red and green (confirmed).
     - One shared lamp component: billboard points with a minimum screen size, one draw call, blinking in the shader. A unit's lamps are drawn only while the unit is.
     - Aircraft, ground units (small markers), pads, airfields and motherships. The Explorer's beacons move to it.
     - Pools of light under pads and bases are flat additive shapes. Real spot lights stay for searchlights only: check the Mobile renderer's per-mesh light limit against terrain chunks with two Explorers over one chunk.
     - **Done when:** a flyer's team and heading read at night from the RTS view and the cockpit; the 3b check still passes; frame time with every test flyer up is measured.
4. [ ] Capture points and base areas.
5. **Vision v1** (split in five; design: `GAME_DESIGN.md`, "Fog of war"). Detection is checked unit to target; the team visibility grid (5d) only draws coverage and never decides what is detected. Built before step 4: nothing here needs capture points.
   - 5a. [x] **Detection** (simulation, no gameplay change yet). Read first: `docs/mechanics/units.md`, `heightmap.md`, `explorer.md`, `performance.md`.
     - Sensor and signature per unit type, line of sight over the heightmap, height helps the observer.
     - Sensors besides units: team airfields and motherships; a deployed Explorer sees farther.
     - Each team's contacts: quick to gain, slower to lose, with a level views can fade by. Last-known records for lost contacts, kept even if the unit dies unseen.
     - A debug view of contacts and sensors.
     - **Done when:** headless tests cover range, signature, a ridge, gain and loss, the base sensors and last-known records; the benchmark's cost is noted in `vision.md`.
   - 5b. [x] **Awareness.** A unit knows what it detects itself, what its squad detects, and what its base detects while it is inside the base area. Targeting, attack orders, attack-move, return fire and lock-on (cockpit, commando) read it. The AI commander's and player's view is the team's contacts. Read first: `combat.md`, `economy.md` (squads), `orders.md`.
   - 5c. [x] **The client draws only known units:** RTS and bird's-eye views, picking, selection, health bars, blips, outlines, effects, sound and lamps, fading by contact level. First person draws what its unit knows.
   - 5d. [x] **Coverage grid and overlay:** a per-team visibility grid on the shared chunk grid (budgeted, with line-of-sight shadows behind ridges). RTS and bird's-eye views dim unwatched ground and lay a faint wireframe grid over it.
   - 5e. [x] **Last known** (commander views only; units never react to them): big units (the Explorer, carryalls) leave a wireframe ghost of themselves at their last-known spot; other units' last-known spots show as a heatmap on unwatched ground. Settled: heat and crosses last `memory_time`, ghosts `ghost_time`; a mark clears when its spot is revealed again with the unit not there, or when the unit is spotted.
6. [ ] Stances, and squads as shared engagement. Rename `trooper` to grunt.
7. [ ] Player squad leader: the ping wheel (middle mouse marker, drag to a task: rally, attack, escort, follow me), orders to the player's own squad through `CommandIssuer`.
8. [ ] A production structure preset (placed inside a base area).
9. [ ] Radar emplacements, scan, cloak.
10. [ ] Flights (2 to 4 aircraft, a leader and a V), and the Explorer loading window.
11. [ ] Operations: phases, strike teams, the join menu.
12. [x] A first special unit for players (commando-style). Built out of order at the user's request: the commando, jetpack infantry ported from `../first` (`docs/mechanics/commando.md`).
