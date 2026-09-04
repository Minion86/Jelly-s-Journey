# Architecture

The Godot project lives at the repository root so the canonical `assets/`, `audio/`, `data/`, `scenes/`, and `scripts/` directories share one `res://` tree.

- `Main.gd` — story flow, level construction, HUD, chapter map, camera setup, environmental illustration, effects, and progression events
- `Player.gd` — Jelly's movement controller and animation state machine
- `Enemy.gd` — reusable anticipate/attack/recover AI for all four city enemy families
- `Squirrel.gd` — chase-route state machine and friendship reward
- `Platform.gd` — static and sine-driven moving platforms
- `Hazard.gd` — rhythmic springs, water, gusts, ramps, and spotlights
- `AudioDirector.gd` — music crossfades, looping, pooled effects, bark variation, and music ducking
- `GameState.gd` — local save data
- `data/levels.json` — all twelve authored level layouts
- `data/story.json` — prologue, chapter introductions, clues, and finale

The previous dependency-free Canvas version remains under `src/` as historical source. Production builds now come from Godot and are exported to `dist/`.

