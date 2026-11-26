# Brainstorm

What's being mulled over, parked, or still open. **Nothing here is decided**: once something is decided it moves to `GAME_DESIGN.md` and is deleted here. Lessons from other games: `docs/prior_art.md`. Design discussions update this file every turn, in place. No tunable values (name the parameter).

_Last updated: 2026-11-26_

## Build order
Moved to `docs/plans/match_flow.md` (the plan fresh sessions read).

## Open: next decisions
- **Last-known marks** (`match_flow.md` step 5e): how long ghosts and the heatmap last, and whether seeing the spot empty clears them.
- **Lights as territory** (leaning): the lights of carryalls, Explorers and bases as the visual signature of the ground "our" side controls, against the night. A first version is in (`docs/mechanics/lamps.md`): how much further to take it is open, e.g. for capture points and base areas (`match_flow.md` step 4).
- **Terrain shadow on units:** step 3 starts with none. Add a faint one only if units look pasted onto shadowed ground in the cockpit?
- **Operation phases:** what starts each phase: the previous phase finishing, a rendezvous, or the commander's "go code" (Rainbow Six planning)? Maybe all three.
- **Aircraft ammo:** do aircraft land to rearm (gives airfields a purpose, as in RA3), or only to repair?
- **Flight key:** S is `order_stop`; Ctrl+S or another key?
- **The Explorer:** built on the mothership's Explorer pad (decided); no limit for now.
- **Firing and signature:** firing breaks cloak (decided); whether it also raises signature is undecided.
- **Death of an inhabited unit:** what the player does next (pick another unit at once? a delay?), and whether there's any cost.
- **Commander orders on a player's unit:** does an order to a player-inhabited unit show as an objective, override nothing, or get refused?
- **Morale or retreat** (Total War, Company of Heroes): fights end in a rout rather than a wipe; makes last stands readable and slows snowballing.
- **Air by zone mission** (Hearts of Iron): assign flights to a region and a mission (air superiority, close support, interdiction) as macro control, beside direct orders.
- **What channels fights on a big map** (Planetside's lattice): capture point links, lanes, land bridges.
- **AI quality plan:** every AI-filled hybrid is judged by its AI; the AI commander and squad AI likely need their own plan early (`docs/prior_art.md`, section 4).
- **Play Silica** (both roles) before building operations: the closest existing game.
- **The 30-second loops** (decided as a principle in `GAME_DESIGN.md`, "Match pacing"); first sketches to test against:
  - *Grunt-squad leader:* ping a target, your squad engages, you take cover, a teammate drops, you rally them to the next cover, then a lull while advancing.
  - *Pilot:* strafing run, break off, evade anti-air, loop back or land to repair, a calm stretch of flying to the next target.
  - *Commander:* glance at the front lines and alerts, top up production, steer one operation's next phase, then a quiet moment to plan.
- **Comebacks:** a 30-minute match with room to bounce back needs a brake on snowballing (morale, retreat, ticket rules, defences that don't make held points too hard to retake). Which ones?

## Player incentives (parked; multiplayer)
First-person players need reasons to follow the strategy. Real-time "move here, stay here" orders from the commander won't do it (an AI can follow those, so why be in the seat?). What we have: a lone player can't achieve much off-strategy (decided), operations give purpose, leading a squad makes a player matter, special units give agency inside the strategy. Still to design: the squad, company and division play that makes each player feel like part of a well-oiled machine whose task wouldn't get done without them; whether anything is scored or rewarded.

## Special units for players (leaning)
Units meant to nearly always be played by a player, so they feel like a big deal, like the C&C commandos (mow down infantry, special abilities). They still serve the commander's strategy. The AI can drive them (parity), but they're designed around a human's decisions. Open: how many per side, what they cost, what they're good at besides killing infantry (sabotage, demolition, scouting, calling in strikes).

## Capture points (rough idea)
Each team gets one initial capture point on the plateau side of its island, near its mothership; other markers removed for now. A point needs at least one unit in its central zone (about 100 m), takes some seconds to capture, and creates a bubble (about 200 m) that becomes a base area. Later it may produce units. All units can capture (decided). Open: contesting (both sides present), decay when empty, tickets.
- **Base area as one concept:** a captured point, a deployed Explorer and later forward bases each open a base area (`Explorer.base_at` exists). Buildings work only inside one; streams would start from one; a base shares its detection with units linked to it.

## Buildings (undecided)
Options: C&C base building, functional buildings found and captured on the map, or mobile units like the Explorer replacing them. Leaning: preset structures placed only inside a base area, delivered from the mothership by air; capture points come with one prebuilt structure; the Explorer covers mobile basing. A full C&C base build would fight the flat income. For now: primitive building presets with unit production.

## Airfield and pads (steps 1 and 2 of `docs/plans/match_flow.md`)
- An airfield is six helipads with hangars. Flyers land there to repair if a pad is free: left-click on the airfield, or a "seek the nearest airfield" command (also from first person, through the autopilot). Landing: fly to the hover point over a free pad, descend quickly. All flyers count as VTOL for this in v1; runways, takeoff and landing are a second iteration.
- A separate production window loads the Explorer with units, air units included (not carryalls yet).
- A hangar count per airfield could cap air units (C&C).

## Flights (wanted, details open; was "squadrons")
- 2 to 4 jets or VTOLs marked as a flight (a squadron is bigger, several flights) from the RTS or strategy view; selectable as one in the strategy view. One unit is leader; the others follow in a tight V. Idle with fixed-wing jets in it: the whole flight circles.
- J on a selected flight inhabits the leader. Targeting stays per unit, but they attack the same target when ordered in the RTS view, or on a squad command from the first-person leader (later).
- Probably a squad of flyers in `SquadRegistry` plus a leader and formation slots. Open: leader dies (promote), mixed speeds (slowest cruise), player leaves the leader seat.

## Parked
- **Unit stream (MOBA creeps):** forward bases and capture points produce units automatically and send them along an advance marker set by the commander; constant pressure, a fight that's always there, a cushion so a real advance needs effort. Liked, but later. Notes when it's picked up: ground units can't cross water (needs land links); the stream eats the unit budget (needs a live cap per source); free streams per captured point snowball; leaning that stream units are plain basic units. References: Castle Fight, Supreme Commander factory repeat and ferry routes, Hearts of Iron battle plans.
- **Supply lines:** carryalls ferrying stock from the mothership to forward bases automatically, so raiding them matters (the covert-jets idea). We don't know what supply does yet; park.
- **Company commanders:** a rank below the strategist who carries out single operations (the strategist outlines patrol, escort, assault; the company commander's style sees it through). Keeps a chain of command. For now the commander does both.
- **Naval units** that ferry ground units between islands, and naval play of its own.
- **Bridges / a new heightmap map** joined by land.
- **Trees and cover** that lower a unit's signature.

## Moments we want the systems to produce
The target is a sandbox where small, local, dynamic fights happen across a large battlefield and make "trailer moments" naturally, seen at true scale from the ground. Commanders are always a little busy holding the front lines, with the rest of their attention on proactive special operations, which is where first-person players want to be. Test the design against these:
- A night assault on an underdefended Explorer outpost found by scouts: charging in from a distance under its towering silhouette, covering ground before the outpost detects you.
- A last stand at a hardpoint turned by the cavalry: a fighter strafing run takes out most of the attackers.
- An escort: ground units and VTOLs protecting two fragile carryalls flying round the mountain to drop expensive units in the enemy's backline.
- A covert flight of jets sneaking round the map to hit carryalls flying in from the enemy mothership.
- A commander's gamble: an Explorer pushed deep into the enemy half at match start, betting the enemy spent on scouting instead of firepower.

What these need: detection by signature and terrain, night lighting, readable travel times, alerts reaching the commander, expensive cargo that dies with its carryall (open question in `GAME_DESIGN.md`, "Carryalls"), physical traffic worth raiding, a vulnerable Explorer deploy.

## Time-to-kill (direction, not tuned)
Varies by armor matchup. A rifle kills infantry quickly (orient on Battlefield or Destiny); infantry without anti-tank weapons loses to a tank; anti-tank kills a tank quickly. Fight length comes from numbers, cover, formations and reinforcements, not high health. Two squads meeting: settled in 10 to 15 seconds if lucky, a minute or two if not, then reinforcements arrive for both sides.

## Older open questions (moved from `GAME_DESIGN.md`)
- **Economy:** the flat income is a leaning; how it's handed out if there are several commanders is open.
- **Look:** how the world art shows scale (detail density, slow heavy motion) against the style guide's flat look.
- **Map scale** (proposal, 2026-11-26, not decided): size the next atoll by travel-time budgets, not kilometres, since map size and unit speeds are one decision (speeds are compressed now). Budgets: neighbouring capture points 90 to 120 s on foot; carryall from mothership to the nearest point 60 to 90 s; a tank crosses one island in 3 to 5 min; a fighter laps the battle in about 2 min; flank sea wider than twice the sensor reach, so raids can approach unseen. At current speeds that means 7 to 9 points about 600 to 750 m apart in a lattice, land about 2.5 times wider than the first atoll, motherships 1.2 to 1.8 km off the coast, and a map extent about twice as wide and long. If jet speeds rise in the feel pass, the map grows with them. Affects grid size, load time and network relevance.
- **Next atoll's checklist** (proposal): home plateau per team (airfield, home point, flat base area); capture point sites with flat centres and two or three approaches each; two or three fronts with cross links (the lattice); land links or fords between islands, or none (open); high ground overlooking points, and hidden valleys and reverse slopes for sneaking (detection uses terrain); a big mountain to fly round, low-flying canyons, and islets on the flanks of the carryall lanes for raiders; Explorer deploy sites, exposed and sheltered; LZ clearings near each point; gentle beaches and deep channels kept for naval units later; named, distinct landmarks that read from the bird's-eye view; ground left free for trees later.
- **Capture points:** whether radar arrays and launch platforms do different things; whether a point's defences switch sides on capture or must be rebuilt.
- **Forward bases:** can they be shot down in transit, moved once placed, rebuilt after they're lost? Where may they be placed? How much income do they cost?
- **Mothership relocation and naval drops:** when and how a mothership moves, and what it drops on the water.
- **Mothership assault:** how points open it up, and what "winning" it means (destroyed, boarded, captured).
- **Modes besides multiplayer:** AI skirmish, campaign missions?
- **Networking model:** server-authoritative is the leaning; confirm before networking is built. Hosting: a player, dedicated servers, or both?
- **Strategy view:** what the strategy outlines (guidelines, Leitlinien) can say, and how the AI reads them.
- **Time:** what pause and slow time do in multiplayer, and whether slow time becomes a mechanic.
- **Ground changing under units:** fall, die or get pushed out?
