# GAME DESIGN (working outline)

**Optional reading.** Not needed at the start of a session; `CLAUDE.md` and `STATUS.md` are enough for coding work. Open this when discussing game design, level structure or progression. It records where a design discussion got to, so it holds decisions, leanings and open questions. Nothing here is final unless marked **Decided**. No tunable values belong here (name the parameter, the value lives in `tuning/`).

_Last updated: 2026-11-21_

## Vision
A top-down real-time strategy game. Everything beyond that is open.

## Decided
- **3D world, top-down view.** Exact camera model is open (below).

## Camera (open)
Reference points the user named: StarCraft II, Red Alert 3 / Command & Conquer, Dota 2. The axes on which they differ:
- **Projection and angle:** all three use a perspective camera at a fixed steep pitch; none is true orthographic.
- **Rotation:** SC2 and Dota 2 lock yaw (north is always up, so map knowledge and minimap stay one-to-one); RA3 lets the player rotate and tilt.
- **Zoom:** SC2 has a narrow zoom band (competitive fairness: everyone sees the same area); RA3 has a wide one; Dota 2 a fixed height.
- **What the camera serves:** an army and a base (free camera, edge pan, hotkeyed locations) vs one hero (camera loosely tied to the hero, with lock on).
- **Screen real estate:** heavy bottom HUD shifts the useful view up and changes where the camera pivot should sit.
- **Visibility rules:** fog of war and how a raised building or cliff hides what's behind it; a steep pitch keeps occlusion low.

**Leaning:** none yet.

## Open questions
- **Scale of play:** army and base (SC2, C&C) vs a few heroes or squads (Dota, Company of Heroes)?
- **Economy:** gathered resources, captured points, or none?
- **Setting and look.**
- **Opponent:** AI skirmish, campaign missions, multiplayer (multiplayer forces a deterministic lockstep model early)?
- **Pathing:** NavigationServer3D agents vs flow fields; how many units on screen at once?

## Parked
