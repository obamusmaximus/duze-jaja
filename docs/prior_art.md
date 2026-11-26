# Prior art

Lessons from other games for our design. Not decisions: those go in `GAME_DESIGN.md`, ideas in `docs/brainstorm.md`. Facts here are from memory plus a few previews (sources at the end); treat details as approximate.

_Last updated: 2026-11-26_

## 1. Hybrid RTS / first-person games

### "Inhabit any unit" (single player, late 1990s)
- **Urban Assault** (1998), **Machines: Wired for War** (1999), **Hostile Waters: Antaeus Rising** (2001), and the possession spell in **Dungeon Keeper** (1997). You command AI units from above and can jump into any one of them. The closest relatives of our "inhabit" model. Hostile Waters is the best: few units, each with an AI personality, and a strong reason to jump in (the AI is decent, but you're better at the hard bit).
- **Lessons:** dropping into any unit removes respawn downtime and walking back. All stayed cult hits, partly because both halves were thin: the RTS was shallow and the first-person controls were clunky. **You have to build two good games.**

### Commander *is* a unit
- **Battlezone** (1998, remaster 2016) and **Battlezone II** (1999): you're a tank pilot who also builds the base and commands AI units from the cockpit. **Sacrifice** (2000) and **Brütal Legend** (2009): a third-person hero who commands armies.
- **Lessons:**
  - Commanding from inside a unit is clunky. Battlezone works because it's slow and the army is small.
  - Brütal Legend was sold as an action game, and many buyers hated the RTS stage battles. **Set expectations: the box must say "RTS".**
  - Mount & Blade (below) shows the light version that works.

### One human commander, players as soldiers (multiplayer)
- **Savage** (2003), **Natural Selection** (2002) and **NS2** (2012), **Nuclear Dawn** (2011), **Empires** (a Source mod), **Allegiance** (2000, space).
  - One player per team commands from top-down: builds, researches, gives waypoints, drops supplies.
  - Everyone else is a human soldier, with no or few AI units.
- **What went wrong, repeatedly:**
  - **The commander is a single point of failure.** One bad or absent commander loses the game for 15 people. Few want the job, because it's stressful and blamed. NS2 added commander eject votes and a commander-less alien side as fixes.
  - **Players ignore orders.** Waypoints are suggestions, and humans chase kills. Savage and Battlefield (below) paid score for following orders, with mixed results.
  - **The player base splits two ways.** RTS fans and FPS fans want different things, and both games must be good.
  - **They need many players to work,** and they died when the player count dropped. Nuclear Dawn faded within a few years.
  - Savage 2 added officers (squad leaders) as a middle rank. That's evidence for our parked company commanders, and evidence that the middle rank needs a real job.

### Commander as a support role in a shooter
- **Battlefield 2** (2005) and **2142** commander: a map view with artillery, a radar scan, a drone, supply drops, and orders to squad leaders. Dropped in BF3, back as a tablet mode in BF4.
- **Squad**, **Hell Let Loose**: a commander role with abilities and voice chain of command through squad leaders. Everyone is human.
- **Lessons:** the commander works when it's **support and information** (scans, strikes, supply), not puppeteering humans. HLL proves a chain of command can work, but only through voice and with a dedicated, communicating player base.

### AI armies with human leaders, on big maps
- **Arma 2 "Warfare" / CTI (capture the island)** modes, and **Arma 3** (High Command, Warlords):
  - a commander builds the base
  - players lead AI squads
  - the teams capture towns for income on a huge map
  - matches last hours.
- **Lessons:**
  - The closest structural match to us (AI-filled army, players optional, big map, captures). Loved by a niche.
  - **The AI quality makes or breaks it.** Arma's AI is the common complaint.
  - **Travel at real scale is a "walking simulator"** without transport.

### The closest current game: Silica (Bohemia Interactive, early access 2023)
- Up to three sides (two human factions and aliens); a commander in an RTS view; players join as infantry or take over units; **units nobody controls are run by the AI**.
- **Criticism in previews and reviews:**
  - It "struggles to marry its two genres".
  - The RTS side felt thin in multiplayer, and one reviewer found the mix promising for single player but not multiplayer.
  - It's slow: long build times, and infantry taking minutes to walk to the enemy.
  - Janky infantry movement.
  - Factions that are too alike.
- Steam reviews are mostly positive, with a modest player count.
- **This is the game to study:** buy it and play both roles before building operations. It answers "what does an AI-filled hybrid feel like" better than anything we can theorise.

### Commanding while fighting (third person)
- **Mount & Blade** (Warband, Bannerlord): you fight in the battle and give a handful of simple orders to your troops (follow me, hold here, charge, by formation). It works because the order set is tiny and the troops are dumb but predictable. **This is the model for the first-person squadron leader's commands.**

### Cross-game coupling
- **Dust 514** (2013, shut down 2016): EVE players could bombard the FPS battles from orbit. It failed as a game, and the link between the two games was too thin to matter. The commander's influence on the ground must be felt directly.

## 2. Large-scale strategy games: what they decided

### Hearts of Iron IV (grand strategy, pausable)
- **Front lines and battle plans:** draw a front, draw an offensive arrow, and the divisions carry it out. This is the "set it and forget it" macro we want for streams.
  - **The known weakness:** players distrust the plan AI and micro the front anyway. If the executor is dumb, macro collapses into micro. **Our AI must be good enough to trust.**
- **Division templates:** you design a unit composition once, then produce it. These are our squad presets, already built.
- **Air by zone missions:** squadrons are assigned to a region and a mission (air superiority, close air support, interdiction) rather than being moved by hand. A strong option for macro air control alongside our squadrons.
- **Supply:** units far from supply lose strength. A model for the parked supply idea, if we ever want it.

### Total War (real-time battles at scale)
- **Regiments, not soldiers,** are the unit you command. Fights end through **morale and routing**, long before everyone is dead, so battles have readable turning points.
- Flanking, terrain, hidden units in forests, line of sight, a deployment phase.
- **Total War: Arena** (multiplayer, each player one general with a few regiments) shut down in 2019. Giving every player a slice of the army didn't hold an audience.
- **Lesson for us:** consider **morale or a retreat state**. It makes the last stand and cavalry moments readable, and fights end in a rout rather than a total wipe.

### Supreme Commander / Total Annihilation
- **Strategic zoom:** zoom smoothly from a unit to the whole map, with icons at range. We have it (V and B).
- **Factories on repeat with rally points, and ferry routes for air transports.** Macro automation: the reference for the parked stream and supply ideas.
- Matches are long and decided by economy. Known failure modes: turtling, artillery and nuclear stalemates. **Scale invites static play unless something forces movement** (tickets and capture points do).

### Wargame / Steel Division / WARNO (Eugen)
- **Optics against stealth:**
  - every unit has an optics rating and a stealth rating
  - detection depends on both, distance and terrain (forests hide)
  - **units that fire are revealed.**
  - This is our sensor-and-signature model, proven to work.
- **Only command units capture zones** in Wargame. That makes high-value targets; we chose "every unit captures", which is simpler and more forgiving.
- Real-scale ranges, a line-of-sight tool, a separate air layer, and a **live front line** drawn from unit positions (Steel Division).
- **Pitfall:** despite the scale, high-level play is very micro-heavy (APM), with spam of the best unit. Scale alone doesn't make a macro game: **automation and good unit AI do.**

### Company of Heroes
- **Territory points** with supply cut-off, cover, suppression, squads as one selectable unit, retreat to base, veterancy.
- **Lesson:** retreat and suppression stop snowballing and make fights readable. Also: their squad is one selectable thing, while our squad is a command group, so expect players to ask "why can't I select the squad as one".

### Planetside 2 (massive persistent first-person war)
- Free-roaming bases produced aimless zerg fights. A **lattice** (bases linked, only adjacent ones attackable) was added to give fights direction and front lines.
- **Lesson:** large-scale sandboxes need **structure that channels fights** (lanes, links, objectives). Pure freedom spreads players thin or piles them into one blob. Relevant to streams, capture point layout and land links.

### Foxhole
- All-player persistent war with no commander; logistics is a whole player job, and moments emerge naturally from scale.
- **Lesson:** the moments you want really do emerge at scale. Foxhole's are slow and logistics-heavy because nothing is automated, the opposite of our approach.

## 3. Why the RTS + FPS hybrid never went big
1. **The commander bottleneck:** one person carries the whole team; the role is stressful and blamed; it's empty or badly filled half the time.
2. **Humans don't obey:** designs that depend on players following orders break.
3. **Two games of work:** the shooter and the RTS must each stand up. Most hybrids had one weak half, and reviews hit the weak half.
4. **Player counts:** they need a full server, and die when the population drops.
5. **Pace and scale mismatch:**
   - RTS units cross the map in seconds, while true scale means long walks.
   - Silica's five-minute infantry walk is exactly this.
6. **Balance between AI and players:** either players dominate (in Men of War, direct control of a tank beats the AI badly, so play becomes micro), or the AI is so central that players feel pointless.
7. **Feeling insignificant:** one soldier in a 100-unit army.
8. **Readability:** the soldier doesn't know what's going on or why.
9. **Netcode:** hundreds of units plus precise first-person aim.

## 4. How our design answers these, and where it's uncharted
**Already answered by decisions:**
- **Bottleneck and population (1, 4):** every role can be the AI (`GAME_DESIGN.md`, "Roles", "Commander AI"). A match works with zero first-person players. This is the biggest difference from NS2, Savage and Nuclear Dawn.
- **Obedience (2):** we never need humans to obey. AI units carry every order and operation; players opt in to roles they find fun. A player who wanders off costs one unit, not the plan.
- **Balance (6):** the parity rule (a player beats one AI unit of its type, not two; no player-only information or actions).
- **Downtime (5):** inhabiting another unit replaces respawn, and carryalls replace walking. Operations put players where the action is.
- **Netcode (9):** server-authoritative, about 100 units per battle, clients get only what their team knows.

**Uncharted, tread carefully:**
- **AI quality is the whole game.** Every AI-filled hybrid (Arma, Silica) is judged by its AI. Ours must:
  - fill commander seats well
  - run operations without looking dumb
  - be good enough that players trust macro (the Hearts of Iron lesson).
  - This is the largest risk and deserves its own plan early.
- **Operations as the bridge:** commander-planned, phased operations that AI carry out and players join by role. No shipped game does this. The nearest are Rainbow Six's planning phase (single player) and BF2's commander orders (which humans ignored). Unproven, so build a thin version and playtest it early.
- **True scale seen from the ground.** RTS units at real size and real distances, with detection that's fair in both views. Eugen proves the detection model works at RTS level; nobody has checked it in first person.
- **Significance of one player:** we answer it with operations, flight and specialised roles. Watch for the "I'm one of 100" feeling in playtests.
- **Two games of work:** keep the first-person half narrow and excellent first (flight is the pillar), rather than broad (full infantry shooter, vehicles, flight) and mediocre.
- **Pace:** RTS readability against first-person realism. Transport, inhabiting a new unit on death and operations that start near the action keep travel from turning into walking.

**Decisions others made that we still need to make** (tracked in `docs/brainstorm.md`):
- What a player does after their unit dies (Hostile Waters: jump to another at once).
- Whether fights end in a rout (morale and retreat, as in Total War and Company of Heroes) or in a wipe.
- Air control: per squadron, by zone mission (Hearts of Iron), or both.
- What channels fights on a big map (Planetside's lattice): capture point links, lanes, land bridges.
- How commander orders show to a player-inhabited unit (an objective marker, never an override).

## Sources
- [Silica (Wikipedia)](https://www.wikipedia.org/wiki/Silica_(video_game))
- [GamePressure: Silica needs lots of refinement](https://www.gamepressure.com/editorials/silica-early-access-preview/zc62d)
- [Sports Illustrated: Silica needs meat to its bones](https://videogames.si.com/features/silica-early-access-preview)
- [PC Gamer: Silica announcement](https://pcgamer.com/bohemia-has-a-new-rtsfps-hybrid-coming-and-its-giving-me-battlezone-vibes)
- [Steam discussion on Silica's pacing](https://steamcommunity.com/app/1494420/discussions/0/3835424220129436344)
