# Build plan: the Explorer (flying forward base)

The Explorer is a huge, slow flying ship and our first base-building mechanic: it carries an army, flies to the front, and on F **deploys**: it sinks to a low hover, raises an energy bubble from a beam on its back, unloads what it carries, and the inside of the bubble becomes a **base area** where later base mechanics are tried. F again packs it up. Mechanic doc: `docs/mechanics/explorer.md`. Built on the battlefield level (`levels/atoll/`).

Built in one session at the user's request (steps kept apart so each can be checked and tuned on its own).

## Decided
- **One shared hold volume** for every carrier, counted in infantry: a unit type's `cargo_size` (trooper 1, IFV 2.5, tank 5, flyer 5, carryall 10; 0: can't be carried). The Explorer holds 40 (40 infantry, or 16 IFVs, 8 tanks or flyers, 4 carryalls, or any mix). The carryall's hold is 10 (every squad preset fits). The HUD shows a fill bar and a card per type aboard, not a slot per unit.
- **F in the RTS view** sends `Order.ability` to the selection's main type. This is the input part of `flight.md` step 4b; showing abilities in the HUD stays in 4b.
- **F again packs up:** the bubble folds, the Explorer climbs back to cruise height and takes orders again. A move order to a deployed Explorer packs it up first. Unloaded units stay where they are.
- **The bubble is a look and an area for now:** it doesn't stop shots or units yet.
- Speed about a carryall's; descends in a tunable time (about 5 s) to about half its cruise height.

## Steps
### 1. Shared hold volume  [x]
`UnitStats.cargo_size` replaces `cargo_slots`; `CargoStats.volume` replaces the two pools; new cargo class `AIR` (flyers, carryalls). Squad check, side gunners and `CargoView` follow.

### 2. The Explorer unit and its look  [x]
`unit_explorer.tres` (`craft_cargoB`, scaled so its bay would hold four carryalls), `ExplorerStats`, an Explorer per team on the atoll with a demo hold. Look: three searchlights sweeping the ground beneath while it flies (spot light plus a visible beam), blinking beacon lights round the hull.

### 3. Deploy (F)  [x]
`DeployStats` ability; `Explorer` states (flying, descending, raising, unloading, deployed, packing, climbing); the beam and the bubble unfurling from its top; unload over the bubble's ground; the base area (`Explorer.base_area`). F on the selection in the RTS view.

## After this plan
- Base mechanics inside the bubble (building placement, production, repair, supply).
- The bubble as a real shield (stops shots from outside, has its own health).
- Loading units into the Explorer (walking in under it), and carryalls docking with it.
- An Explorer built by production on the mothership.
