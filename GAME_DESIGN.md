# GAME DESIGN (working outline)

**Optional reading.** Not needed at the start of a session; `CLAUDE.md` and `STATUS.md` are enough for coding work. Open this when discussing game design, level structure or progression. It records where a design discussion got to, so it holds decisions, leanings and open questions. Nothing here is final unless marked **Decided**. No tunable values belong here (name the parameter, the value lives in `tuning/`).

_Last updated: 2026-11-21_

## Vision
A top-down 3D real-time strategy game built, to start with, along the lines of Red Alert 3 and C&C3: Tiberium Wars: their camera, their control scheme, army-and-base play.

## Decided
- **Reference games: Red Alert 3 and C&C3: Tiberium Wars.** When a detail isn't settled here, do what they do, and note it here once it's built.
- **Army and base scale**, not hero or squad play.
- **Camera: free, in the RA3 / C&C3 style** (below).
- **Control scheme: the RA3 / C&C3 left-click scheme** (below).
- **Maps change during a match** (below): this rules out anything that assumes a fixed map.
- **Three views of one match** (below): the RTS view, a whole-map strategy view, and first-person in any unit.
- **Multiplayer is required** (below, "Multiplayer and simulation").
- **About 100 units at most in one battle** or one spot on the map. The whole map may hold more, spread out.
- **Pathing on our own grid** (below).
- **AI commanders are layered and hand-authored** (below). No LLM or learned layer: out of scope.
- **Single player can pause.** A slow-time control exists as a dev tool from the start, and may become a mechanic.

## Changing maps (Decided)
Parts of the map can appear and disappear, walls can block the way, and elevation can change, all during a match.
- **Pathing must update locally and cheaply.** A change rebuilds only the area it touches, units whose path crosses it re-path, and nothing assumes a map baked once at load.
- **Terrain is game data, not a static mesh.** Height and passability live in a map model that the game changes, and the terrain mesh, collision and pathing all rebuild from it in chunks. This model is also what the strategy view draws, and what building placement and fog of war read.
- Units standing on ground that vanishes or rises need defined outcomes (fall, die, get pushed out); decide when the first such feature is built.

## Views (Decided: three views of one match)
In one match the commander switches freely between:
1. **RTS view:** the camera and controls below, for micro.
2. **Strategy view:** the whole map at once, simplified (2D or isometric 3D, undecided), for big-picture command.
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

## Pathing (Decided: our own grid)
The map model holds a grid of cells (height, passability, cost). Single paths use the engine's `AStarGrid2D` (cells can be blocked and reweighted at runtime); big group moves to one point can use flow fields; units steer around each other locally. A map change updates its cells, and units whose path crosses them re-path. Not Godot's navmesh: it is baked, handles changing maps poorly, and would be a second map model to keep in sync. Later: unit sizes (clearance), and whether anything needs two levels (bridges over paths).

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

## Controls (Decided: the RA3 / C&C3 left-click scheme)
Left-click both selects and gives orders; right-click clears the selection. RA3 and C&C3 also offered a right-click-orders scheme as an option; we may add that later as a setting.

| Input | Does |
|---|---|
| Left-click a unit | Select it (replaces the selection) |
| Left-drag | Box select own units |
| Shift + left-click / drag | Add to or remove from the selection |
| Double-click a unit | Select all own units of that type on screen |
| Left-click ground / enemy (with a selection) | Move there / attack it (the cursor shows which) |
| Right-click | Clear the selection |
| Right-drag | Drag-pan the camera |
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
- **Economy:** C&C-style harvested resource (leaning, from the reference games), captured points, or both?
- **Setting and look.**
- **Modes besides multiplayer:** AI skirmish, campaign missions?
- **Networking model:** server-authoritative is the leaning (above); confirm before networking is built. Hosting: a player hosts, or dedicated servers, or both?
- **Strategy view:** 2D or isometric 3D? What exactly can the guidelines (Leitlinien) say?
- **Time:** what pause and slow time do in multiplayer, and whether slow time becomes a mechanic.
- **Ground changing under units:** fall, die or get pushed out?

## Parked
