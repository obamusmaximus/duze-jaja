# Vision (detection)

The user calls all of this (detection, fog of war, coverage, last known) the **scanner overlay**.

Which enemy units each team knows of. Design: `GAME_DESIGN.md` ("Fog of war"). Build order: `docs/plans/match_flow.md` step 5. Tunables: `VisionStats` (`tuning/vision_default.tres`, Units tab), `UnitStats` "Vision" (`sensor_range`, `signature`), `AirfieldStats` and `MothershipStats` `sensor_range` (the airfield also `sensor_height`), `ExplorerStats.base_sensor_range`.

**Scripts:** `vision/vision.gd` (`Vision`), `awareness.gd`, `team_vision.gd`, `vision_contact.gd`, `last_known.gd`, `vision_sensor.gd`, `line_of_sight.gd`, `coverage_map.gd` (`CoverageMap`), `coverage_view.gd` (`CoverageView`, view side), `last_known_heat.gd` (`LastKnownHeat`, view side), `last_known_ghosts.gd` (`LastKnownGhosts`, view side), `ghost_lines.gd`, `ghost.gdshader`, `last_known_cross.gdshader`, `terrain/ground.gdshader` (draws the overlay and the heat), `fog_view.gd` (`FogView`, view side; fading meshes in `materials/fade_materials.gd`); `debug/vision_view/vision_view.gd`; wired in `levels/match_level.gd` (`MatchLevel.vision`) and `levels/atoll/atoll_level.gd` (base sensors).

**Units react only to what they know (5b), and the views draw only what is known (5c).**

## How it works
- **Detection** is checked observer to target: the flat distance is within the observer's `sensor_range` × the target's `signature`, raised by up to `height_bonus` for standing above it (all of it at `height_full`), never past `max_detect_range`; and `LineOfSight.clear` finds no ground above the straight line, sampled every `sight_step`. Both ends are the top of the body plus `eye_lift` (`Vision.eye_of`). Only terrain blocks sight. `Vision.detects(observer, target)` answers it for one unit, now, with no memory or sharing (for 5b). Light never plays a part.
- **Sensors besides units** (`VisionSensor`): each ground airfield (from `sensor_height` over its deck) and each mothership (from its underside; deck pads have none of their own). They read place and numbers live. A deployed Explorer (`is_base()`) uses `base_sensor_range`.
- **Checks:** every unit is checked against each other team every `check_interval`, spread over the ticks by id. Whoever saw it last is tried first, then the sensors, then the observers near it (a spatial hash per team, searched as far as that team's longest sensor could see this signature). The first that sees it ends the search, so a contact records only one observer.
- **Contacts** (`TeamVision.contacts`, `VisionContact`): `level` rises over `gain_time` while seen and falls over `lose_time` while not. The enemy is `known` from level 1 until level 0. Place and facing are those of the last check that saw it. Read with `Vision.of_team(team).knows(id)` and `level(id)`; signals `contact_gained` and `contact_lost`.
- **Last known** (`TeamVision.memory`, `LastKnown`): made when a known contact fades out, cleared when the unit is known again. A unit that dies or is carried off while seen leaves nothing; one that goes unseen keeps its record, since the team can't know. A record ends after `memory_time` (`ghost_time` for a type with `UnitStats.leaves_ghost`), or when its spot is watched again after going unwatched (`hidden`) and the unit isn't there: each record is checked once a `check_interval` against the team's sensors and units at the unit's own signature. A unit lost at the edge of sight leaves from a spot still watched, so watching alone doesn't clear it. Signal `memory_changed(team)`, once a tick. Commander views only; units never read it.
- **Awareness** (`Awareness`, `Vision.unit_knows`, `Unit.knows`): a unit knows an enemy its team knows that it detects itself, a member of its squad (`squad_id`) detects, or the deployed Explorer whose base area it stands in detects. While a contact fades, the units linked to whoever saw it last still know it. It asks the contact's recorded observer first (free), then checks the unit, its base and its squad members (a sight line each) and records the one that sees as the observer. Airfields and motherships link no units yet: they get base areas in step 4. `Unit.team_knows` is the cheap team check (the commander's view).
- **Who reads it:** `UnitTargeting` searches only known enemies (so return fire, idle fire, move fire and attack-move engagements) and drops its picks once the team loses them; the carryall's side gunners; the pilot's lock-on (`PilotWeapon`: picked from known enemies, dropped when the team loses it) and the commando's tracking (`JetTracking`: new pickups only). Commander orders read the team's contacts: `CommandIssuer` refuses an attack on an enemy the team doesn't know, an attack order ends when the team loses its target, and so does an attack-move engagement; targeted abilities accept only known enemies. With no `Vision` in the match (`UnitRegistry.vision` null) every unit knows everything.
- **Debug view:** `debug_show_vision` (7): a ring on each contact (sized by level), a cross at each last-known spot, base and selected units' sensor rings (range against signature 1), sight lines from selected units, and counts.

## Coverage (watched ground)
What ground the local player's team watches (`MatchLevel.coverage`, `CoverageMap`; made only for that team and only on a level with `TerrainChunks`). It describes the ground and **never decides detection**: range depends on the target's signature.
- **Grid:** each terrain chunk (the shared chunk grid, `performance.md`) cut into `coverage_per_chunk` blocks a side from the terrain's corner, each into `coverage_detail` cells a side. One byte per cell.
- **Watched:** a unit or sensor of the team would detect a standing target of signature 1 at the cell's centre (`Vision.sees_point`, the same range, height and sight-line code as detection), so ridges leave shadows. Over sea the point is on the surface.
- **Sweep:** on a `WorkerThreadPool` task, at most one per `coverage_interval`, published on the main thread when done. Block centres are checked first, then cell by cell only in blocks that differ from a neighbouring block (the edge of watched ground); the rest take their block's answer, so a watched or hidden patch smaller than a block, away from any edge, is missed. Observers are copied as data when a sweep starts (units die and board carryalls during it) and listed per chunk; a point asks the last successful observer first. While a sweep runs the worker reads the terrain heights, `Vision.sees_point` and `VisionStats`: keep that path free of writes and node-tree access.
- **Read:** `is_watched(point)`, `watched` (bytes), `texture`, signal `changed`.
- **Drawn** (`CoverageView`, parameters on the `WorldMaterials.ground()` materials): in the RTS and bird's-eye views unwatched ground darkens by `coverage_dim` under a fine, faint wireframe in `UiTokens.HUD_LINE`: hairlines every `coverage_divisions`th of a block (`coverage_line`), small crosses on the block corners (`coverage_tick`), and a contour where watched ground ends (`coverage_edge`). Each part fades where it would crowd on screen. The ground crossfades from the previous sweep to the new one (as long as the sweep took to arrive, at most `coverage_fade`), so the edge slides. Off while the team has a pilot. Only the ground: the sea, bases, props and the minimap are not marked.

## Last known (drawn)
Commander views only (off while the team has a pilot), from the player's team's records; rebuilt only on `memory_changed`.
- **Heat** (`LastKnownHeat`): records without a ghost splat heat (`heat_radius`, `heat_weight`) into a texture of `heat_cell` texels over the terrain. Each texel stores its heat and how fast it cools, so the ground shader fades it over `memory_time` with no rebuild. Drawn on unwatched ground only, in the enemy team's colour, as a faint fill cut into `heat_bands` contour bands (`heat_strength`). Rebuilt at most four times a second.
- **Crosses:** a thin × with an open centre and a dot at each of those spots (`cross_size`, one multimesh), in the unit's team colour; a ring pings out once when the contact is lost, then the cross fades with the record.
- **Ghosts** (`LastKnownGhosts`): a `leaves_ghost` type (Explorer, carryall) leaves its model's feature edges (`GhostLines`: outline and creases, cached per type) as additive lines in its team colour at the spot and facing it was lost, with a drop line and footprint brackets on the ground, and a label with its type and how long ago it was lost. A scan band climbs it; as it ages it dims and breaks into dashes; when the record ends it dissolves upward over `ghost_dissolve` (`ghost_strength`).

## What is drawn
`FogView` (`MatchLevel.fog`) gives every unit a `view_level` (0 to 1) and `in_view` each frame (`Unit.show_in_view`); views read those, the simulation never does. Own units are always whole; a new enemy starts hidden.
- **Commander views** (RTS, bird's-eye): `view_level` is the team's contact level (so a gaining contact already shows faintly) and `in_view` is `knows`.
- **First person:** the inhabited unit's awareness (`Vision.unit_has`, which unlike `unit_knows` records nothing; asked every `check_interval`), plus whatever it has locked or is tracking. It fades over `gain_time` and `lose_time`.
- **Fading:** meshes take alpha-hashed material copies in a few steps (`FadeMaterials`); lamps, the Explorer's lights, beam and bubble, health bars, minimap dots and bird's-eye blips fade with them. War table tokens and strategy outlines only appear or go. At 0 the whole look is hidden.
- **Picking needs `in_view`:** clicks pass through other units, flyer picks and strategy figures skip them, and an inspection ends when its unit is lost. A squad figure is its drawn members only (centre and count).
- **Effects and sound:** muzzle flashes, tracers, beams, projectiles and gunfire show only from a drawn shooter (projectiles already seen fly on after it dies). Sparks and hit sounds show on a drawn target, even from an unseen shooter; a miss follows its shooter. Deaths show only if the unit was drawn.
- Bases (airfields, motherships) are always drawn. `FogView.reveal_all` draws everything (the night check uses it).
- **A new view of units** (or effect, or sound) must check `Unit.in_view` to pick and `view_level` / `is_drawn()` to draw.

## Settled
- A fading unit is drawn where it really is, not at its last seen place, for the `lose_time` it takes to go.
- Headless (scratchpad harness, atoll): the view matches the team picture, new enemies start hidden, the first-person view shows only what its unit knows, a lost unit fades, ends its inspection and goes.
- Headless (scratchpad harness): unlinked units don't know what a team-mate sees, squad members and a deployed Explorer's base area share, a fading contact stays known through the squad, a dead squad member links nothing, attacks on unknown enemies are refused; on the atoll an unseen shooter gets no return fire until the victim can see it.
- Ordered attacks follow the team's knowledge (the commander told them), not the unit's own.
- The coverage grid only draws what is watched; it never decides detection, since range depends on the target's signature.
- Headless (scratchpad harness, atoll): every coverage cell matched a brute-force check against the same sweep's observers; deaths in the middle of a sweep are safe; a new `coverage_per_chunk` remakes the grid. Windowed: the overlay shows in the RTS and bird's-eye views and goes off in the cockpit.

- Last known: a record clears when its spot is watched again after going unwatched, not just watched (the user's rule: recalculated only when the area is revealed again or the unit is spotted elsewhere). Small units' heat and crosses last `memory_time`, ghosts `ghost_time`.
- Headless (scratchpad harness, atoll): a record by a watched spot stays and isn't hidden, one on unwatched ground is hidden and clears when a unit reveals it, records expire, ghost lines build for the Explorer and carryall, ghosts and heat build. Windowed: heat bands, crosses, ghosts and the fainter coverage wireframe checked in the RTS view.

## Tried and passed on
- Coverage swept on the main thread under a per-tick cell budget: it only allowed 32 m cells swapped about once a second, so the fog moved in big jumps.

## Measured
- Headless M1, `--fixed-fps 60`: about 0.3 ms per tick in the benchmark (100 ground units and the level's test units, almost no contact). About 508 units, half per team, in two bands in contact by one airfield: about 1.8 ms (190 contacts each way), and 1.9 ms with the bands farther apart (mostly one side seen). The worst case is many units in range but hidden: each check then walks lines from all of them. If it grows, raise `check_interval` first.
- Awareness costs nothing measurable in the benchmark (same unit loop with it switched off).
- `FogView`, headless, 145 units in a firefight: about 0.1 ms per frame in a commander view, 0.2 ms in first person.

- Last known: one heat rebuild with 41 records about 2.3 ms (8 m texels on the atoll); at most four a second, only while records change. Reviewing records is one pass over the memory a tick plus a sight check per record each `check_interval`.
- Coverage, headless M1, atoll (8 m cells in 32 m blocks, 110k cells, 61 observers): about 150 ms of one worker thread per sweep, 3.8 sweeps a second at a `coverage_interval` of 0.25; main thread 0.02 ms per tick, 0.5 ms peak. 20 cells differ from checking every cell (which takes about 310 ms). Not measured with several hundred units; hidden points near many observers cost the most. If it costs too much, raise `coverage_interval` or lower `coverage_detail`.

## Known issues
- Starting sensor and signature values are untuned.
- A big signature carries far: a rover on high ground detects the enemy Explorer across the strait as the match starts.
- Sight ignores buildings, hangars, walls, motherships and bubbles.
- Coverage is tested at points (cell centres, or the block's centre away from the edge): a unit can be detected on a dimmed cell (a big signature, or a spot off centre) and missed on a clear one.
- `coverage_dim` is subtle on the night map; the wireframe carries most of the reading. Both want a feel pass.
- Heat draws only on the terrain: spots over the sea show their cross only. Heat colour follows whichever enemy team has most records (fine with two teams).
