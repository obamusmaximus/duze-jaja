# Imported models

How imported art (`assets/`) is shown. Look rules: `docs/style_guide.md`. Packs and licenses: `assets/README.md`. Tunables: `UnitStats` "Look" (Units tab). (The static `Prop` type went with the old test levels; it is in git history.)

**Scripts:** `props/model_fit.gd`; units show models through `units/unit_look.gd`.

## How it works
- **`ModelFit.instance(scene, scale, yaw, team)`** returns a node holding the model centred over its origin with its base at y = 0, then scaled and turned about that point, its materials recoloured into the world palette (`WorldMaterials.recolour`, style guide "In the world"; `team` colours livery parts, -1 for none). It exists because the Kenney meshes sit offset from their origin; bounds are measured once per model and cached. Every imported model goes through it, and so should our own primitive models: name a material `leaves` or `bark` and it takes that role.
- **Unit models:** a `UnitStats` with a `model` shows it in `UnitLook` over a flat team-colour base plate (instead of the placeholder cylinder and nose); `radius` and `height` still size the collision and ring. Models face -Z, the unit's forward.

## Settled
- Kenney Space Kit (CC0, glTF) is the placeholder 3D art. Its pieces differ widely in scale, so each type sets `model_scale`; units are scaled up well past the kit's natural size.

## Tried and passed on
- Kenney "Sci-Fi RTS": 2D sprites only, no 3D models.

## Known issues
- Each new model needs a scale (and a yaw if it does not face -Z) set in its `.tres`.
