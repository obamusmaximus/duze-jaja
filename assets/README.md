# Assets

Third-party art. Each pack lives in its own folder with its license file next to it. Only use CC0 or similarly unencumbered packs, so no credits have to be tracked.

| Folder | Source | License | Used for |
|---|---|---|---|
| `kenney_space_kit/` | Kenney, "Space Kit" 2.0 (https://kenney.nl/assets/space-kit), the glTF (`.glb`) models only | CC0 1.0 (`License.txt`) | Placeholder units, buildings and map scenery (`props.md`, `UnitStats` "Look") |

- **Scale:** Kenney's kits are not built to one scale (a rover is 0.35 m, a hangar 3 m, in model units). Each use sets its own `model_scale` in its stats `.tres`.
- **Origins:** the meshes sit offset from their origin on a tile grid. Always show a model through `ModelFit` (`props/model_fit.gd`), which centres it and puts its base on the ground.
- **Adding a pack:** put it in `assets/<pack>/` with its license, add a row here, run `godot --headless --import`.
