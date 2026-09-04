# Jelly's Journey Home — Godot 4 direction

## Design thesis

Jelly's Journey is a warm, story-forward platform adventure with the immediate readability and rhythmic momentum of a classic 16-bit platformer, presented with modern illustrated characters. Its key rule is simple: every movement, sound, enemy warning, and collectible should express personality before difficulty.

The two reference videos establish the target principles rather than copied content: responsive acceleration, clear jump arcs, layered scenery, moving-platform rhythm, compact visual storytelling, and a score that rearranges a recognizable central motif across different places.

## Player feel

- Ground acceleration with a higher hold-to-run ceiling
- Air control that preserves momentum without feeling slippery
- 130 ms coyote time and 150 ms jump buffering
- Variable jump height on release
- Camera look-ahead, drag margins, and position smoothing
- Landing squash, takeoff stretch, subtle airborne rotation, dust, bark rings, and invulnerability flicker
- Contextual idle sequence: breathing/tail wag, listening, sniffing, sitting, then sleeping

## Adventure structure

- Seven-panel playable prologue before the first level
- Four chapters, twelve authored stages, and twelve post-level story clues
- Five scent treats, one squirrel friendship, one checkpoint, and one exit clue per level
- Four enemy families with readable anticipate/attack/recover/stunned states
- Environmental rhythm systems: gusts, fountains, waves, spring oranges, spotlights, moving taxis, leaves, boards, logs, decks, and swan boats
- Persistent level unlocks, total treats, squirrel friendships, sound preference, chapter select, pause/retry, keyboard, and touch input

## Original music system

Each level owns an original looping cue. All cues transform the same eight-note Jelly motif while changing tempo, mode, accompaniment, and timbre for the environment:

| Chapter | Musical identity |
| --- | --- |
| New York | Bright square-wave brass, walking bass, taxi-bell syncopation |
| Los Angeles | Warm pulse leads, surf-like arpeggios, boardwalk percussion |
| Louisiana | Swing-adjacent brass colors, call-and-response, bayou-night texture |
| Orlando | Marimba-like plucks, orange-grove bounce, returning-home cadence |

The melodies and arrangements are new for Jelly's Journey; the reference soundtrack is used only for the high-level idea of thematic variation between levels.

