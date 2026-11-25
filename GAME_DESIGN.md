# GAME DESIGN (working outline)

**Optional reading.** Not needed at the start of a session; `CLAUDE.md` and `STATUS.md` are enough for coding work. Open this when discussing game design, level structure or progression. It records where a design discussion got to, so it holds decisions, leanings and open questions. Nothing here is final unless marked **Decided**. No tunable values belong here (name the parameter, the value lives in `tuning/`).

_Last updated: 2026-11-22_

## Vision
A top-down 3D real-time strategy game built, to start with, along the lines of Red Alert 3 and C&C3: Tiberium Wars: their camera, their control scheme, army-and-base play.

## Decided
- **Reference games: Red Alert 3 and C&C3: Tiberium Wars.** When a detail isn't settled here, do what they do, and note it here once it's built.
- **Army and base scale** in the command views, not hero or squad play (first-person players lead at most a squad, below, "Roles").
- **Camera: free, in the RA3 / C&C3 style** (below).
- **Control scheme: the RA3 / C&C3 left-click scheme** (below).
- **Maps change during a match** (below): this rules out anything that assumes a fixed map.
- **Three views of one match** (below): the RTS view, a whole-map strategy view, and first-person in any unit.
- **Multiplayer is required** (below, "Multiplayer and simulation").
- **About 100 units at most in one battle** or one spot on the map. The whole map may hold more, spread out.
- **Pathing on our own grid** (below).
- **AI commanders are layered and hand-authored** (below). No LLM or learned layer: out of scope.
- **Single player can pause.** A slow-time control exists as a dev tool from the start, and may become a mechanic.
- **Setting: mothership warfare over islands** (below, "A typical match"). Battlefield 2142's Titan mode is a main inspiration.
- **Roles split command** between a strategist, company commanders and first-person players (below, "Roles").
- **Squads are the tactical unit** and **carryalls deliver them** (below, "Squads", "Carryalls").
- **Tilt-shift is part of the look:** the strategy view is a war table (below, "Views").
- **First-person flight is a main source of fun** (below, "Flight").
- **Every unit type has an ability on F** (below, "Unit abilities").

## A typical match (Decided unless marked)
The reference level is the battlefield level (`levels/atoll/`, built by `docs/plans/battlefield.md`): an atoll and islands in open sea, a mothership per side far out. The green island was its first draft.
- **Each side's main base is a hovering mothership**, standing off from the islands. Its distance sets how long reinforcements take to arrive, so map layout is mostly a question of travel times; the map size is picked on a scale reference level. Squads are produced aboard and flown in by carryall. It's where the commander "is".
- **Hovering** is mostly for the look now, but it's what later lets the mothership drop naval units onto the water, split off hovering forward bases, and relocate itself (as Titans do in BF2142). Its position is game state from the start.
- **No land link between mothership and island.** Everything reaches the island by air or sea, and so will the eventual mothership assault.
- **The mothership in each view:** a simple base object in the command views; a detailed, futuristic, multifunctional space in first person (air units launched from internal catapults, carryalls loading in hangars, ships dropped from below). The interior is a view: the simulation only knows where and when a unit appears.
- **Forward bases:** the mothership can detach two pieces of itself that fly quickly to a point on the map and become hovering forward bases, as huge as the mothership.
- **Scale is emphasised:** the mothership should look like it could host a whole force (within reason).
- **The island battle is over capture points** (radar arrays, launch platforms). Capturing one gives static defences and a forward spawn point.
- **Win condition (for now): tickets.** Holding points earns tickets; the first side to reach the target wins.
- **Later:** a mothership assault, in the style of Battlefield 2142's Titan mode (holding points lets you take the fight to the enemy mothership), possibly including infiltrating it in first person. So the mothership should become a unit with separate parts (hangars, production bays, carryall pads, forward-base pieces) that each have their own health, rather than one health bar.
- **Snowballing is a known risk.** Points are not the economy (yet) for that reason, and the defences and forward spawn they give must not make a held point too hard to retake.

## Economy (Leaning: flat income, no harvesting)
- **Both sides get the same flat income per minute.** No resource harvesting and no economy micro. The skill is in how the income is spent: which units go into which squads, and later how much goes into forward bases, to suit the commander's strategy and the battlefield's needs. Think Clash Royale more than C&C.
- Open: a bank cap, and whether unspent income carries over.

## Squads (Decided)
- **A squad is made of individual units**, and in the RTS view each unit can still be micro'd on its own (with the right clearances), or taken over in first person.
- **Above that, the squad is the smallest tactical unit**, and it usually has one job: scouting, patrol, guard duty, a hail-mary covert operation. A big battle over a control point is rarely just one squad.
- **Fully custom, with presets:** the commander composes a squad from unit types, or starts from a preset (fireteam, anti-air, motorized division, covert insertion, and so on). The rule is one squad per carryall; a less granular strategy may call for bigger single squads.
- Squads are produced on the mothership in several parallel production lines, paid from the income.
- Squads are also the natural unit the strategist hands to company commanders ("Roles") and the AI's squad layer ("Commander AI").

## Carryalls (Decided)
- **Big air transports** that carry squads from the mothership to the islands.
- **Cargo:** infantry slots and machinery slots (twice as many infantry slots as machinery ones; the counts are tunables). An IFV takes half the machinery slots, a tank-type unit all of them.
- **Para-drop** everything it carries anywhere; it **must land to pick units up**.
- **Two carried units can act as side gunners**, firing from the carryall.
- **A player can pilot it** (first person); otherwise an autopilot (not an AI infantry unit) carries out RTS-view orders.
- **Cargo is stored as data** (type, health, squad), not as units riding along; dropped or unloaded units come back as themselves.
- Open: whether its cargo dies when it's shot down, and whether units can be shot while descending.

## Roles (Decided: compartmentalized command; first-person squads are a leaning)
In multiplayer one side can be several players, each in one role:
1. **Strategist** (strategy view): decides strategy and how units are distributed among the commanders.
2. **Company commanders** (RTS view): run their part of the battlefield with the units assigned to them.
3. **First-person players:** take over a single unit, possibly leading an AI squad, for Battlefield-style play. A player-controlled unit will nearly always outplay its AI equivalent, and that's intended.

What this means for the build:
- **Every role can be a player or the AI.** The AI commander's layers line up with the roles (strategy layer, managers and squads, single unit brains), so empty roles and single player are covered by the same AI.
- **Ordering rights sit below the team:** a unit belongs to a team and is assigned to a controller (a player or an AI). `CommandIssuer`'s team check becomes "may this controller order this unit".

## Changing maps (Decided)
Parts of the map can appear and disappear, walls can block the way, and elevation can change, all during a match.
- **Pathing must update locally and cheaply.** A change rebuilds only the area it touches, units whose path crosses it re-path, and nothing assumes a map baked once at load.
- **Terrain is game data, not a static mesh.** Height and passability live in a map model that the game changes, and the terrain mesh, collision and pathing all rebuild from it in chunks. This model is also what the strategy view draws, and what building placement and fog of war read.
- Units standing on ground that vanishes or rises need defined outcomes (fall, die, get pushed out); decide when the first such feature is built.

## Views (Decided: three views of one match)
In one match the commander switches freely between:
1. **RTS view:** the camera and controls below. A tactical, company-commander view, for micro.
2. **Strategy view (Decided, v1): a war table.** A tilt-shift view of about two thirds of the map at its farthest, for big-picture command and unit distribution. It need not show the live level: it's a model of the map with low-res, scaled-up unit models (as in Homeworld) or icons. Zooming in hands over to the live battle in the RTS view. Its HUD overlay builds squads, assigns landing zones, places map markers allies can see, and sets general strategy outlines (the guidelines, below). A lighter tilt-shift fades in as the RTS camera zooms out, so the two views blend.
3. **First-person:** inhabit any own unit on the map and control it directly.

What this means for the build:
- **The match is independent of any view.** Units, orders, pathing and combat run the same whatever is being watched. A view is just a camera, an input scheme and a HUD on top, and switching views never changes game state. Nothing in gameplay code may read the RTS camera.
- **One way to command.** Every view issues orders through the same `CommandIssuer` (the AI uses it too).
- **Units carry two levels of detail:** a strategy-view symbol and a full model that holds up at first-person distance.
- **An inhabited unit** swaps its order-following brain for player input and keeps everything else (stats, weapon, health, team). It still moves through the same world rules, so the movement code must also support direct control.
- The match keeps running in every view. **While the player is in first person, a friendly AI commander runs the rest of their army, following the guidelines (Leitlinien) the player set in the strategy view** (below, "Commander AI").

## Multiplayer and simulation (Decided: multiplayer; leaning: server-authoritative)
**Why most RTS games use lockstep:** every machine runs the identical simulation and only the players' orders are sent, so the network traffic doesn't grow with unit count (it was built for hundreds of units over dial-up), and replays are just the order log. The costs: the simulation must be bit-for-bit deterministic on every machine (no physics engine, careful floats, a fixed tick), every order waits out a delay before it runs, a single divergence (desync) breaks the game and is painful to debug, joining a game in progress is hard, and every client holds the full state, so map hacks are easy.

**Why server-authoritative fits us better:**
- **First-person mode needs it.** Lockstep's built-in delay feels fine for RTS clicks and terrible for direct control. Client-side prediction for the inhabited unit is a client-server technique.
- **About 100 units per battle** is small enough to sync state over a modern connection, especially when each client only receives what it can see (which also stops map hacks).
- **Physics and floats are fine:** only the server's simulation counts; clients interpolate what it sends.
- Godot's built-in multiplayer (RPCs, `MultiplayerSynchronizer`) is built around one authority, and the server can be a hosting player or a headless export.

**Rules from now on, even before networking exists:**
- The simulation (units, orders, pathing, combat, map changes) runs on a fixed tick in `_physics_process` and never reads views, cameras, the mouse or the HUD, so it can run headless on a server.
- Players and AI change the game only by sending **orders** (plain data) through `CommandIssuer`. Views send orders; they never touch units directly.
- Game state lives in a few plain values per unit and per map change, so it can be sent over the network and saved.
- Effects that are only for show (projectile trails, selection rings, death effects) sit apart from the simulation.
- **The unit simulation ticks at half the physics rate** (the inhabited unit and projectiles every tick), and views interpolate. Rules and reasons: `docs/performance.md`.

## Pathing (Decided: our own grid)
The map model holds a grid of cells (height, passability, cost). Single paths use the engine's `AStarGrid2D` (cells can be blocked and reweighted at runtime); big group moves to one point can use flow fields; units steer around each other locally. A map change updates its cells, and units whose path crosses them re-path. Not Godot's navmesh: it is baked, handles changing maps poorly, and would be a second map model to keep in sync. Later: unit sizes (clearance), and whether anything needs two levels (bridges over paths).
- **Flyers never pathfind:** they fly straight over the terrain.
- **Ground moves stay on their land mass.** A ground unit ordered to a point it can't reach by land (another island) ignores the order; amphibious units are the exception, and crossing water is the carryalls' job. Pathing is therefore always local to one island.
- **The strategy view rarely micro-manages:** it sets squads, landing zones and outlines; unit-level moves come from the RTS commander or the AI. Long searches across the whole map shouldn't exist.

## Commander AI (Decided: layered and hand-authored)
One AI commander design serves both the enemy and the player's own delegate while they're in first person.
- **Strategy layer:** chooses goals by scoring them (utility AI). For the friendly commander, the player's **guidelines (Leitlinien)** from the strategy view are its goals and limits.
- **Managers:** economy, production and army, turning goals into work.
- **Squads:** groups of units carrying out tactics (attack, defend, retreat) with simple state machines.
- **Influence maps:** threat and control grids built from the map grid, read by every layer.
- Orders only through `CommandIssuer`, like a player. Difficulty comes from reaction time and decision quality before resource cheats.

## Camera (Decided)
A perspective camera that orbits a focus point on the ground. Tunables: `CameraStats` (`tuning/camera_default.tres`).
- **Free rotation** around the focus point, with a reset back to `default_yaw` (north up). Because the view can turn, every model and building must read from all sides, and the minimap needs a view cone showing where the camera faces.
- **Wide zoom**, with the **pitch tied to the zoom**: flatter (`pitch_near`) when close, steeper (`pitch_far`) when far. Zoomed in is for watching the action; zoomed out is for commanding.
- **Pan** by keys, the screen edge and a held-button drag, faster when zoomed out (`pan_scales_with_zoom`). The focus point rides the ground height smoothly.
- **Jumps:** double-tapping a control group's number centres on it; a key jumps to the latest alert; clicking the minimap moves the camera there.
- **Lopsided view:** a tilted camera sees further up the screen than down it. Rotation lets the player fix that themselves, so maps don't need to work around it.

## Flight (Decided)
Build order: `docs/plans/flight.md`.
- **First-person flight is a main source of fun** and where many later mechanics live, so it gets real feel work.
- **Between Ace Combat and a sim:** arcade controls on our own simple aerodynamics (speed, angle of attack, lift, drag, gravity, stall). Planes can crash, though not easily: there's a learning curve.
- **Two models:** RTS and AI flyers fly a cheap, always-safe autopilot model on the air layer of the map; an inhabited flyer runs the full flight model. The full model's wider envelope is the reward for flying in person.
- **Always from the cockpit:** no chase camera. A dynamic helmet-style HUD (horizon, pitch ladder, flight path marker, angle of attack).
- **Controls:** the plane steers toward a mouse reticle (mouse aim); WASD is a secondary direct control; B is the air brake; no throttle for now. J inhabits the selected unit and leaves it.
- **All aircraft but carryalls** use the flight model. Carryalls are big flying ships with their own simpler controls.
- **Roster ideas:** a VTOL; a fast, fragile fighter whose prism ray links with a second fighter for a deadly strafing run; a VTOL that turns into artillery when landed.

## Unit abilities (Decided)
- **Every unit type has an ability, a gimmick, on F**, from the most basic infantry to the biggest units. It works on the selection in the RTS view and on the inhabited unit in first person. Design each unit type around it.

## Controls (Decided: the RA3 / C&C3 left-click scheme)
Left-click selects and right-click gives orders (the StarCraft scheme, changed from RA3 left-click orders); clicking empty ground clears the selection. RA3 and C&C3 also offered a right-click-orders scheme as an option; we may add that later as a setting.

| Input | Does |
|---|---|
| Left-click a unit | Select it (replaces the selection) |
| Left-drag | Box select own units |
| Shift + left-click / drag | Add to or remove from the selection |
| Double-click a unit | Select all own units of that type on screen |
| Left-click ground / enemy (with a selection) | Move there / attack it (the cursor shows which) |
| Right-click | Order: move, attack an enemy (attack-move when armed) |
| Right-hold + pull | RTS: fly the view toward the pull, faster the farther (C&C style). Strategy views: drag-pan the map |
| Middle-drag | Rotate the camera |
| Mouse wheel | Zoom |
| Arrow keys, screen edge | Pan |
| Ctrl + number / number / number twice | Make a control group / select it / centre the camera on it |
| Ctrl + left-click | Force-fire at a spot or unit |
| Alt + left-click | Queue a waypoint |
| Attack-move key, then left-click | Attack-move |
| Stop key | Stop |
| Space | Jump to the latest alert |
| Camera-reset key | Reset yaw and zoom |

The hotkeys in this table follow how we remember RA3 and C&C3; the exact keys and the less common ones (scatter, select all of a type across the map, reverse move, formation move) still need checking against those games' manuals before they're bound. Any key is just an Input Map action, so it's cheap to change.

**Production (leaning: the C&C model):** construction and unit production are queued from a sidebar, not by selecting the building, and new structures are placed near existing ones. This shapes the HUD layout, but it isn't part of the groundwork.

## Open questions
- **Economy:** the flat income is a leaning (above, "Economy"); how the strategist hands it out to commanders is open.
- **Look:** the setting is decided; how the world art shows scale (haze, detail density, slow heavy motion) against the style guide's flat look is open.
- **Map scale:** a mothership that could host a force is likely a few hundred metres long, so a match map is likely kilometres, not hundreds of metres. That affects grid size and network relevance. Picked on the scale reference level (`docs/plans/battlefield.md`, step 1).
- **Capture points:** how capturing works (presence, timers, contesting); whether radar arrays and launch platforms do different things; whether a point's defences switch sides on capture or must be rebuilt.
- **Forward bases:** can they be shot down in transit, moved once placed, or rebuilt after they're lost? Where may they be placed? How much income do they cost?
- **Mothership relocation and naval drops:** when and how a mothership moves, and what it drops on the water.
- **Mothership assault:** how points open it up, and what "winning" the assault means (destroyed, boarded, captured).
- **Modes besides multiplayer:** AI skirmish, campaign missions?
- **Networking model:** server-authoritative is the leaning (above); confirm before networking is built. Hosting: a player hosts, or dedicated servers, or both?
- **Strategy view:** what exactly can the strategy outlines (guidelines, Leitlinien) say, and how does the AI read them?
- **Time:** what pause and slow time do in multiplayer, and whether slow time becomes a mechanic.
- **Ground changing under units:** fall, die or get pushed out?

## Parked
