# Jelly's Journey Home

Jelly's Journey Home is an original, story-rich 2D platform adventure built with **Godot 4.3**. Jelly crosses New York, Los Angeles, Louisiana, and Orlando to find her two humans, following scent clues and befriending the squirrels she cannot resist chasing.

The Godot edition replaces the original JavaScript canvas architecture with real 2D physics, reusable gameplay scenes, animation state machines, moving-body collision, camera smoothing, pooled audio, persistent progression, and desktop/mobile/web export targets.

## Play

The `main` branch is exported automatically as a browser game through GitHub Pages. Godot's Web export is configured as an installable progressive web app.

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | A/D or Left/Right | Left/right buttons |
| Jump | Space, W, or Up | Jump button |
| Run | Hold Shift | Momentum builds naturally |
| Happy bark | X | Woof button |
| Sniff pose | C | Contextual idle animation |
| Pause | Escape or P | Pause menu |

The controller includes 130 ms coyote time, 150 ms jump buffering, variable jump height, separate ground/air acceleration, momentum preservation, landing squash, takeoff stretch, and camera look-ahead.

On touch devices, large multi-touch controls support simultaneous movement and jumping, press-drag continuity, automatic run momentum, a dedicated pause control, safe-area spacing, and browser gesture/scroll suppression. The responsive 960×540 playfield is configured for future native landscape exports to iOS and Android.

## Story and levels

- A six-shot animated Central Park prologue shows Jelly's joyful walk with her humans, the playful squirrel stealing her blue ribbon, the frantic chase, and the parade that separates the family. Camera drifts, crossfades, flying leaves, ribbon trails, timed sound effects, and an original score carry the scene directly into Chapter One.
- Four chapter introductions and eleven post-level clue scenes carry the story into the reunion.
- The ending is a six-stage animated reunion: Jelly's human parents recognize her, kneel, embrace her, lift her into their arms, and finally hold her together beneath the porch lights that never went dark.
- Twelve hand-authored levels contain five scent treats, a staged squirrel chase, checkpoint, rhythmic environmental mechanics, animated enemy encounters, secret routes, and a unique exit clue.
- Five new illustrated regional backdrops—two New York views plus Los Angeles, Louisiana, and Orlando—were developed from supplied travel-photo references and layered beneath weather and gameplay effects.

| Chapter | Level 1 | Level 2 | Level 3 |
| --- | --- | --- | --- |
| New York | Taxi Top Tango | Central Park Picnic | Brooklyn Bridge Bounce |
| Los Angeles | Boardwalk Boogie | Studio Lot Hop | Sunset Pier Parade |
| Louisiana | Jazz Street Jamboree | Firefly Bayou | Riverboat Rhythm |
| Orlando | Orange Grove Dash | Lake Eola Leap | The Road Home |

## Animation and enemies

Jelly has dedicated idle, run, jump, fall, bark, hurt, happy, sniff, sit, and sleep performances. If the player stands still, she breathes, wags, blinks, perks her ears, sniffs, sits, and eventually curls up to sleep.

Each enemy family uses the same readable five-state behavior model—patrol, anticipate, attack, recover, and stunned—with a different attack language:

- New York newspaper pigeons patrol and dive.
- Los Angeles roller raccoons crouch, dash, and skid.
- Louisiana trumpet frogs hop and fire musical gusts.
- Orlando bandana lizards sprint and wall-leap.

Jelly's bark stuns aggressive animals rather than hurting them. Squirrels use a separate taunt/chase/friend state machine and reward a golden acorn when caught.

Enemies now come in three behavioral variants with different size, speed, awareness, patrol range, timing, color treatment, and attack energy. They idle, look around, respect ledges, telegraph attacks, skid or bounce through recovery, emit movement effects, and can be safely pounced on for a spring jump. Every platform is location-dressed with animated grass, windows, lights, vines, flowers, oranges, hardware, or route markings, while two spring pads per level create faster high routes.

## Original soundtrack and effects

Every level has its own original looping cue. The twelve tracks rearrange one new eight-note Jelly motif with different tempo, harmony, instrumentation, and rhythmic character for each place. Separate original intro and finale arrangements bring the score to fourteen cues. The soundtrack reference informed the idea of thematic variation; no reference melody or recording is included.

The effect library contains three randomized bark performances plus jump, landing, treat, checkpoint, hurt, squirrel, victory, and movement sounds. Music ducks briefly under important effects.

Regenerate the data and audio from the editable tools:

```bash
npm run data
npm run audio
```

## Run in Godot

1. Install Godot 4.3 or newer.
2. Import `project.godot` in the Godot Project Manager.
3. Press F6/F5 to play, or export the `Web` preset.

Command-line export:

```bash
GODOT_BIN=/path/to/godot npm run build
```

## Validate

```bash
npm test
godot --headless --path . --editor --quit
```

The Node validation checks all twelve level definitions, every story segment, animation-state source, music loop, effect cue, and required artwork. Godot's headless import catches script/resource errors before export.

## Source layout

```text
project.godot             Godot project and web-friendly renderer settings
export_presets.cfg        Web/PWA and Windows export presets
scenes/main.tscn          Main game scene
scripts/                  Player, enemy, squirrel, world, UI, audio, and save logic
data/levels.json          Twelve level layouts and secret routes
data/story.json           Prologue, chapters, level clues, and epilogue
assets/                   Characters, cinematic sheets, and regional backgrounds
audio/music/              Twelve level loops plus intro and finale scores
audio/sfx/                Bark variants and gameplay effect library
docs/                     Design and architecture notes
tools/                    Data/audio generation, validation, and export helpers
src/                      Preserved source of the earlier Canvas edition
dist/                     Generated browser release
```

All artwork and audio committed to this repository are original to Jelly's Journey and were created for this project.
