# Mechanic docs

One doc per load-bearing mechanic, listed in the table in `STATUS.md`. Each holds what a fresh session needs to pick the mechanic up without the old conversation: the design intent, how the pieces connect, what is settled, what was tried and passed on, and the open problems. A new load-bearing mechanic gets its own doc and a row in that table.

## Keeping a mechanic doc
- **When a session starts work on a mechanic,** read its doc, then the scripts it lists.
- **When the task ends** (the change lands, or the user closes the session), update the doc before closing:
  - Fix "How it works" so it matches the code.
  - Add one line to "Tried and passed on" for each approach that was built or seriously tried and then dropped: what it was, and why it was dropped.
  - Move anything decided from playtesting into "Settled".
  - Update "Known issues".

## Documenting principles (all docs)
1. **Write for the next session, not as a record.** Keep only what a fresh session needs and can't cheaply get from the code or git.
2. **One home per fact.** Rules go in `CLAUDE.md`, current state and next up in `STATUS.md`, mechanic detail in its doc, test-harness notes in `docs/testing.md`, design in `GAME_DESIGN.md`. Point to the home instead of copying.
3. **Only every-session facts go in `CLAUDE.md` and `STATUS.md`.** Both are loaded into every session, so a line there costs every session. Anything only some sessions need goes in the doc for that work, with a pointer.
4. **Name parameters, never values.** The `.tres` files are the source of truth.
5. **Describe the present.** Rewrite to match the code and delete what's no longer true. No changelog, no dated entries, no "now" or "fixed": git has the history.
6. **"Tried and passed on" is the exception to deleting.** It's what git can't recover. One line per approach: what, and why it was dropped. Remove a line only if the approach is adopted after all.
7. **Evidence in one clause.** A test that settled something gets a short result ("hit 13 of 13 in a headless test"), not its method.
8. **Stay in budget.** A mechanic doc stays around 1,300 words and `STATUS.md` around 600. Over budget, cut before adding: tighten "How it works" first, and split a doc when one part of it grows into its own mechanic.
