# Cargo

What a carrier can hold and how units take up room in it. Design: `GAME_DESIGN.md` ("Carryalls"). Build order: `docs/plans/battlefield.md` steps 7 (this) and 9 (the carryall that uses it). Tunables: `CargoStats` (`tuning/cargo_default.tres`, Units tab), plus the Cargo group and `icon` of `UnitStats`.

**Scripts:** `units/cargo.gd`, `units/cargo_entry.gd`, `tuning/cargo_stats.gd`, `ui/components/cargo_view.gd`, `ui/components/unit_icon.gd`, `units/models/` (`proto_parts.gd`, `ifv_proto`, `tank_proto`).

## How it works
- **Cargo class and size:** a unit type's `UnitStats.cargo_class` (none, infantry, machinery, air: what kind of cargo it is, e.g. which can be side gunners) and `cargo_size` (room it takes, counted in infantry). Trooper 1, rover 2, IFV 2.5, tank 5, flyers 5, carryall 10. Class none (boats, the Explorer) can't be carried.
- **The hold:** a type with `UnitStats.cargo` (a `CargoStats`: one shared `volume`) gets a `Cargo` on its `Unit` (`unit.cargo`, else null). Every kind of cargo shares the volume: the carryall's 10 takes any squad preset, the Explorer's 40 takes 40 troopers, 16 IFVs, 8 tanks or flyers, 4 carryalls or a mix.
- **Carried units are data:** `CargoEntry` (unit id, type, health; `land()` puts it back on the map). `Cargo.load_entry` stores it if it fits, `unload(id)`, `remove_entry`, `take_first`, `can_load`, `used`, `free_room`, `capacity`, `fits_all(types)` (does a squad fit an empty hold; the squad builder's check), `type_counts` (for views). `changed` signal for views.
- **Icons:** each type's `UnitStats.icon` is a flat white SVG in `ui/icons/units/` (trooper, rover, ifv, tank, skiff, carryall), tinted by the HUD. Swapping one is replacing the file or the `icon` field. `UnitIcon` draws it (the type's initial if none) and is the one component for every place a type shows as a symbol; the production queue and squad builder (step 8) reuse it.
- **HUD:** selecting a single carrier shows `CargoView` under its stats in the selection module: HOLD used / volume, a fill bar, and a bone card per type aboard with its icon and count (a hatched square when empty). Card height is `UiStats.cargo_slot_units`.
- **Models:** the IFV and tank are primitive prototypes (`units/models/*_proto.tscn`, built in `_init` from `ProtoParts`, at true scale, one livery stripe in the team colour, a `Muzzle` marker). They plug in through `UnitStats.model`, so a `.glb` replaces one by changing that field and, if needed, `model_scale`. The trooper and rover are the Kenney models at true scale now (1.8 m and about 2.5 m tall), the base plate carrying readability.

## Settled
- One shared volume per hold (was separate infantry and machinery pools); sizes and volumes are tunables.

## Tried and passed on

## Known issues
- Units are loaded by production (one by one as they are built, `carryall.md`); the old demo carryalls on the atoll are gone, so a carryall exists only with a queued squad. Taking live units aboard isn't built. The carryall is a flyer, using `craft_cargoA` at `model_scale` 8, not yet checked against a tank's size.
- The wedge parts of the prototypes (glacis plates) haven't been checked by eye.
- The test units are spaced 9 m apart (was 3) so tanks don't overlap at the start, and each team's block grows away from the other's (before, the two blocks overlapped).
