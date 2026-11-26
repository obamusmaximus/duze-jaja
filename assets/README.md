# Assets

Third-party art. Each pack lives in its own folder with its license file next to it. Only use CC0 or similarly unencumbered packs, so no credits have to be tracked.

| Folder | Source | License | Used for |
|---|---|---|---|
| `kenney_audio/` | Kenney: Interface Sounds, UI Audio, Digital Audio, Sci-fi Sounds, Impact Sounds (one folder each, each with its `License.txt`), a trimmed subset | CC0 1.0 | UI, order, selection and combat sounds (`audio.md`) |
| `synth/` | Written by `tools/audio_synth/synth.py` | Ours | Placeholder sounds no pack covers: order blips, select chirp, hit spark, Mars wind, flight engine, wind and stall warning |
| `kenney_space_kit/` | Kenney, "Space Kit" 2.0 (https://kenney.nl/assets/space-kit), the glTF (`.glb`) models only | CC0 1.0 (`License.txt`) | Placeholder units, buildings and map scenery (`props.md`, `UnitStats` "Look") |

| `fonts/` | "Anybody" by Etcetera Type Co (https://github.com/Etcetera-Type-Co/Anybody), variable font `anybody_variable.ttf` from google/fonts | SIL OFL 1.1 (`OFL.txt`; keep it next to the font) | The UI's one type family (`docs/mechanics/ui.md`) |
| `fonts/` | "IBM Plex Sans" by IBM (https://github.com/IBM/plex), variable font `ibm_plex_sans_variable.ttf` from google/fonts | SIL OFL 1.1 (`OFL_IBM_Plex_Sans.txt`) | Reading face of dev tools (the tuning panel); Anybody stays for structure |

- **Scale:** Kenney's kits are not built to one scale (a rover is 0.35 m, a hangar 3 m, in model units). Each use sets its own `model_scale` in its stats `.tres`.
- **Origins:** the meshes sit offset from their origin on a tile grid. Always show a model through `ModelFit` (`props/model_fit.gd`), which centres it and puts its base on the ground.
- **Downloads fail** (Kenney links often give 404s to agents). Before downloading, check `~/Downloads` for packs the user already has, and copy from there. If a pack isn't there, ask the user to download it.
- **Planned imports:**
  - Kenney Nature Kit, for atoll plants and rocks (battlefield step 5). It's in `~/Downloads/kenney_nature-kit`.
  - Kenney Space Station Kit, interior pieces for the mothership interior once first person comes. It's in `~/Downloads/kenney_space-station-kit.zip`.
  - A boat pack for naval units, later. The user downloads it.
  - Mothership, IFV and tank are primitive prototypes, not packs (`docs/plans/battlefield.md` steps 6 and 7).
- **Adding a pack:** put it in `assets/<pack>/` with its license, add a row here, run `godot --headless --import`.
