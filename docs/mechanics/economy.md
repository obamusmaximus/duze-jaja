# Economy and squad production

Flat income, squads and the mothership's production lines. Design: `GAME_DESIGN.md` ("Economy", "Squads"). Build order: `docs/plans/battlefield.md` step 8. Tunables: `EconomyStats` (`tuning/economy_default.tres`, Units tab), `cost` and `build_time` on `UnitStats`, presets `tuning/squad_*.tres` (`SquadStats`).

**Scripts:** `economy/` (`economy.gd`, `production.gd`, `production_line.gd`, `squad_spec.gd`, `squad_record.gd`, `squad_registry.gd`, `squad_presets.gd`, `unit_catalog.gd`), `tuning/economy_stats.gd`, `tuning/squad_stats.gd`, `ui/hud/modules/production_module.gd`; orders in `orders/order.gd` and `command_issuer.gd`.

## How it works
- **`Economy`**: a bank per team, the same flat income for all, paid out on the fixed tick (fractions accrue). `spend`, `deposit` (capped by `bank_cap`, 0 = none). Probe event `income` once a second.
- **`SquadSpec`** is plain data (name, job, unit type ids from `UnitCatalog`); `SquadStats` presets turn into one. `validate()` refuses an empty squad, an unknown or uncarriable type (flyers), or more than `squad_hold` x `squad_carryalls` slots per cargo class. Cost and build time are sums over the units.
- **`Production`** holds a `ProductionLine` per mothership bay (`MothershipStats.production_bays`). `queue` pays upfront and puts the squad on the named line or the shortest queue (`queue_length` per line); lines build in parallel. Cancel refunds `cancel_refund` of the cost. A job at the front of a line gets a free carryall on a mothership pad (`carryall.md`) and builds its units one by one into that carryall's hold, as `CargoEntry` data on the squad's `SquadRecord`; the line waits while no pad is free. A carryall taking off early stops the job and refunds `takeoff_refund` of the unbuilt units. Cancelling a started job scraps the hold.
- **Orders:** `Order.produce(team, spec, line)` and `Order.cancel(team, ticket)` go through `CommandIssuer.issue()`, which sends them to `Production` (refused if there is none, the team has no lines, the squad is invalid, the queue is full or the bank is short). Probe events `produce`, `cancel`, `squad_ready`.
- **`SquadRegistry`** (squad id, team, members, job); `attach(squad_id, unit)` sets `Unit.squad_id` and tracks the live members (carryalls call it as they unload), `mark_deployed` ends the aboard state, `disband` drops a squad. Members are not a selection group.
- **HUD:** `ProductionModule` (left edge in `generals`, right band in `sidebar`): bank and income, preset buttons, a custom builder (type buttons disable when they no longer fit the hold), a row per line with progress and cancel, squads aboard. It finds the services by group and only sends orders.
- **Wiring:** `AtollLevel._build_economy()` creates the four nodes (economy, squads, `CarryallFleet`, production) before the HUD binds and gives the issuer its `production`.

## Settled
- Income is flat and the same for both sides; cost is paid when queued.

## Tried and passed on

## Known issues
- Open from the plan: whether unspent income carries over (it does now, uncapped), the squad cap above one carryall (a tunable, only the squad builder checks it).
- No AA unit yet, so there is no anti-air preset.
- The AI doesn't produce. The production module is unstyled beyond the stock buttons and untested by eye.
