# Audio and combat effects

Sound (UI, orders, selection, combat, ambient) and the combat particle effects. Both are view-side: they listen to simulation signals, the simulation never calls them. Tunables: `AudioStats` (`tuning/audio_default.tres`), one `SfxCue` per sound (`tuning/sfx_*.tres`, listed in `tuning/sfx_library.tres`), `FxStats` (`tuning/fx_default.tres`), all on the Audio tab; `WeaponStats` and `UnitStats` "Sound and effects" name the cues a weapon or unit type uses.

**Scripts:** `audio/sfx.gd` (autoload `Sfx`), `audio/sfx_loop.gd`, `audio/game_sound.gd`; `fx/fx_builder.gd`, `fx/combat_effects.gd`; `tools/audio_synth/synth.py` (writes `assets/synth/`). Sound files: `assets/kenney_audio/`, `assets/synth/` (`assets/README.md`).

## How it works
- **`Sfx`** (autoload, runs while paused): makes the buses SFX, UI, Ambient, Music at start (volumes from `AudioStats`, live). `play_at(cue, point)` plays a world sound from a pool of `AudioStreamPlayer3D`; `play_ui(cue)` plays flat from a pool of `AudioStreamPlayer`; `start_ambient(cue)` / `stop_ambient()` loop a bed. `make_loop(cue)` gives a view its own `SfxLoop` to add to the tree and `drive(gain, pitch)` live (it pauses with the game); loops are outside the pools. The cockpit's engine, wind and stall warning use it (`cockpit.md`). A random variation and pitch per play; a cue's `max_voices` and `min_interval` stop a big battle becoming noise; a full pool drops the sound. `attach_listener(rig)` puts an `AudioListener3D` on the camera rig (its origin is the focus point on the ground), so world sounds are loud near what the player looks at and pan with the view.
- **Buttons:** `Sfx` hooks every `BaseButton` that enters the tree (hover, click, or toggle), so menus and the HUD need no wiring. A button that re-enters the tree (moved to another parent) is hooked only once. Set meta `no_ui_sound` on a button to silence it.
- **`GameSound`** (a node in the level, `setup(shots, registry, issuer, selection, team)`): `Shots.shot_fired` / `shot_hit` play the weapon's `fire_cue` / `hit_cue`; `Unit.died` plays the unit's `death_cue`; the local team's accepted orders play an acknowledgement (move, attack, attack-move, stop); a unit joining the selection plays its `select_cue`.
- **`CombatEffects`** (a node in the level, `setup(shots, registry)` with an `FxStats`): pooled one-shot `GPUParticles3D` built by `FxBuilder`: a muzzle flash per shot, sparks per hit (both scaled by the weapon's `effect_scale`), a fireball + debris + smoke burst per death (scaled by the unit type's `death_effect_scale`). The oldest effect is reused when a pool is full; editing `FxStats` live rebuilds the pools.
- **Levels:** `match_level.gd` wires `GameSound`, `CombatEffects` and the listener when the level has nodes of those names, and starts `ambient_cue` (a level export) if set. A level without them is silent and effect-free.
- **Adding a sound:** a `SfxCue` .tres (`id`, streams, loudness, bus) added to `sfx_library.tres`; point a weapon or unit at it by id. The tuning panel shows a cue's numbers (not its id or streams).
- **Sources:** Kenney CC0 packs (Interface Sounds, UI Audio, Digital Audio, Sci-fi Sounds, Impact Sounds), a trimmed copy; the order acknowledgements, unit select chirp, hit spark, the Mars wind loop and the flight engine, wind and stall warning loops are synthesized placeholders from `synth.py`, replaceable by dropping in a file of the same name.

## Settled
- UI hover and click use the shortest clips (20-60 ms) at low volume, per the "snappy, clean, digital" brief.

## Tried and passed on
- The ffmpeg here has no Vorbis encoder, so the synthesized sounds stay `.wav`.

## Known issues
- No unit voices, engine or footstep loops heard from outside the cockpit, under-attack alerts, or music yet.
- Cue ids and streams are not editable in the tuning panel (it shows numbers, colours and checkboxes only).
- No loudness pass: levels are by ear estimate and need a playtest.
- Slow time does not change audio pitch.
