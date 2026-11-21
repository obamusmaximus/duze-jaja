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
- **Opponent:** AI skirmish, campaign missions, multiplayer (multiplayer forces a deterministic lockstep model early)?
- **Pathing:** NavigationServer3D agents vs flow fields; how many units on screen at once? The groundwork starts on NavigationServer3D (`docs/plans/groundwork.md`).

## Parked
