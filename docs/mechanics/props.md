# Props and imported models

Static objects in a level (scenery and building shells) and how imported art (`assets/`) is shown. Look rules: `docs/style_guide.md`. Packs and licenses: `assets/README.md`. Tunables: `PropStats` (`tuning/prop_*.tres`, Map tab); `UnitStats` "Look" (Units tab).

**Scripts:** `props/prop.gd` (+ `prop.tscn`), `props/model_fit.gd`; units show models through `units/unit_look.gd`. Demo level: `levels/sandbox/space_demo.tscn` (uses `sandbox.gd`), ground shader `levels/sandbox/ground_grid.gdshader`.

## How it works
- **`ModelFit.instance(scene, scale, yaw, team)`** returns a node holding the model centred over its origin with its base at y = 0, then scaled and turned about that point, its materials recoloured into the world palette (`WorldMaterials.recolour`, style guide "In the world"; `team` colours livery parts, -1 for none). It exists because the Kenney meshes sit offset from their origin; bounds are measured once per model and cached. Every imported model goes through it, and so do our own primitive models: name a material `leaves` or `bark` (as the trees in `props/models/` do) and it takes that role.
- **`Prop`** (`StaticBody3D`, group `props`) holds a `PropStats` type. It shows the model and, when the type `blocks`, collides on layer 3 (Building) with a box of the footprint and height. The level calls `block_in(map)` for the `props` group once the map is built; the prop then blocks its footprint in the `MapGrid` (`pathing.md`) and re-applies it when its stats change. A prop turned by a multiple of 90 degrees blocks exactly its footprint; other angles block the bounding box of the turned footprint. Scenery types (`blocks` off) have no collision.
- **Unit models:** a `UnitStats` with a `model` shows it in `UnitLook` over a flat team-colour base plate (instead of the placeholder cylinder and nose); `radius` and `height` still size the collision and ring. A unit type per model is a `.tres` (`unit_trooper`, `unit_rover`, `unit_skiff`). Models face -Z, the unit's forward, so no yaw is needed for the three in use.
- **Space demo level:** a small two-base map (cyan team south-west, violet north-east, rock field between) built only from props and unit types, wired like the sandbox. Run it with F6 in the editor.

## Settled
- Kenney Space Kit (CC0, glTF) is the placeholder 3D art. Its pieces differ widely in scale, so each type sets `model_scale`; units are scaled up well past the kit's natural size so they read next to the buildings.

## Tried and passed on
- Kenney "Sci-Fi RTS": 2D sprites only, no 3D models.

## Known issues
- Props are not selectable and have no health or building logic yet; a click on one orders a move to the ground behind it.
- Only the three unit models and the props in the demo have been fitted; each new model needs a scale (and a yaw if it does not face -Z) set in its `.tres`.
