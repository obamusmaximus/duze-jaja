# Performance ground rules

Cross-cutting rules that keep the game light. Read this before building anything that runs every tick, scales with unit count or map size, or draws a lot. Each mechanic doc records its own measured cost; this file holds the rules and the budgets' owners. Most of this lands in `docs/plans/battlefield.md` step 0.

## Target
- **Weak hardware first.** The reference machine is the dev machine (Apple M1, 8 GB): a full match must run smoothly on it with the editor open. Anything that only runs well on a strong GPU is a bug.
- **Memory counts as much as frame time** on 8 GB: per-cell and per-sample data stays compact (below), and nothing holds a full-map structure it doesn't need.

## Renderer
- **Mobile renderer** (switched from Compatibility in step 0). It is built for weak GPUs and has reversed Z (no z-fighting at kilometre zoom) and the engine's depth of field.
- **No compute shaders** in gameplay or rendering paths, so the Compatibility fallback stays possible for the weakest machines.

## The tick
- **Physics runs at 60 Hz; the unit simulation runs at 30 Hz,** half the units on even ticks and half on odd ones, so every tick carries an even load. Views use the engine's physics interpolation, so motion stays smooth at any frame rate.
- **Every tick:** the inhabited (first-person) unit, projectiles, and anything a player steers directly.
- **One loop per system, not per unit.** The registry steps the units (targeting, movement, weapon) from one `_physics_process`; units have none of their own. Slow work (target scans, re-paths) is staggered over ticks.
- **Every deferrable job has a per-tick budget,** as paths already do: terrain and map-grid rebuilds, water bakes, war-table redraws.

## Units
- **No physics movement for RTS units.** They move kinematically: height from the terrain data, walls and buildings from the map grid, other units from the spatial hash. `move_and_slide` was about a third of the per-unit tick cost (`pathing.md`, "Measured").
- **A collision shape stays on every unit** (Unit layer) for queries only: picking, first-person hits, projectiles. The body is moved, never solved.
- **The inhabited unit** swaps to a physics controller (`move_and_slide`) for first-person feel, and back when released.
- **Flyers never use the map grid:** straight flight over the terrain data.
- **Long-lived state holds unit ids, not node references** (selection, control groups, squads, orders, targets). An id survives a unit leaving the world and coming back, and goes over the network.
- **Carried units are data, not nodes.** Loading a unit into a carryall stores its id, type, health, squad and controller, and removes the node the way death does (without the death event). Para-drop or landing spawns it again with the same id. Nothing else needs a "carried" state.

## Pathing at scale
- **Reachability first.** Every walkable cell carries a land-region id (a connected land mass, per clearance), refreshed locally on map changes. A ground move to another region is refused when the order is issued: an O(1) check, no search. Amphibious units, and later the carryall route, are the exceptions.
- **The grid covers land only,** in chunks (below). Sea cells don't exist in it.
- **Searches stay local.** A path never leaves its region; with carryalls doing the long hauls, ground moves are mostly within one island. A coarse chunk-to-chunk level is added only if one island is measured too big for one search.
- **One copy of the map model,** shared by every unit; units hold only their own path.
- **Big group moves to one point** can use a flow field per goal instead of one search per unit (`GAME_DESIGN.md`, "Pathing").

## Shared chunk grid
- **One chunk size and index for every map-sized system:** terrain mesh and collision, map grid, land regions, water depth bake, war-table redraw, fog of war later. A map change names its chunks once and each system rebuilds those.
- **Compact data:** heights as 16-bit values; surface role, walkability and clearance as bytes in `PackedByteArray`s per chunk; no per-cell objects, no one-float-per-metre arrays.

## Drawing
- **Same things share one draw call:** one `MultiMesh` per unit type for far zoom, props, trees, projectiles; health bars drawn by one control (already so).
- **Levels of detail by zoom:** full models near, `MultiMesh` stand-ins far (visibility ranges), war-table tokens farthest. The far stand-ins and the tokens are the same assets.
- **Team colour through per-instance data,** not separate materials. Materials come from `WorldMaterials`.
- **Shadows only at near zoom;** far views rely on flat shading and haze. Haze follows the camera distance.
- **Water is dense only near the camera;** far water is a flat plane or coarse rings.

## Measuring
- **A standing benchmark:** a headless scene runs a fixed number of units for a fixed number of ticks and prints milliseconds per system in one summary line (`docs/testing.md`). Run it at the end of every step that touches a per-tick system, and write the result in that mechanic's doc under "Measured".
- **Measure before optimising,** and keep the numbers in the mechanic docs, not here.
