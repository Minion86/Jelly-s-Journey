# Jelly's Journey Home

An original, installable 2D platform adventure for children. Help Jelly follow her family's trail across New York, Los Angeles, Louisiana, and Orlando—complete with playful squirrel chases, responsive enemies, checkpoints, and lively city set pieces.

## Play and install

The game is a dependency-free progressive web app. Open the hosted game in a modern browser and choose **Install game** or **Add to Home Screen**.

For local development:

```bash
npm run dev
```

Then open `http://localhost:8080`.

## Controls

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move | Arrow keys or A/D | Left/right buttons |
| Jump | Space, W, or Up | Jump button |
| Happy bark | X | Woof button |
| Pause | Escape | Pause button |

## Game structure

- 4 story chapters and 12 hand-authored levels
- 5 optional treats in every level
- A unique squirrel chase in every level: catch up gently to earn a golden acorn and make a new friend
- Animated city-specific enemies with anticipation, patrol, swoop, dash, trumpet, hop, climb, recovery, stun, motion trails, squash-and-stretch, and readable warning behavior
- Moving platforms with level-specific identities: taxis, park leaves, bridge signs, boards, movie slates, surfboards, jazz stages, bayou logs, riverboat decks, orange crates, swan boats, and memory platforms
- Hand-placed landmarks, props, foreground foliage, weather, environmental particles, checkpoint signs, wind zones, puddles, fountains, waves, ramps, sprinklers, and orange bounce pads
- Three courage hearts and child-friendly retry behavior
- Saved local progress, chapter selection, offline caching, keyboard controls, and touchscreen controls
- A coordinated Web Audio score with four city themes and key-matched cues for jumps, landings, barks, pickups, checkpoints, enemies, squirrel chases, and victories

## Level guide

| City | Level 1 | Level 2 | Level 3 |
| --- | --- | --- | --- |
| New York | Taxi Top Tango | Central Park Picnic | Brooklyn Bridge Bounce |
| Los Angeles | Boardwalk Boogie | Studio Lot Hop | Sunset Pier Parade |
| Louisiana | Jazz Street Jamboree | Firefly Bayou | Riverboat Rhythm |
| Orlando | Orange Grove Dash | Lake Eola Leap | The Road Home |

## Source layout

```text
dist/
  index.html            Game shell, menus, HUD, and touch controls
  style.css             Responsive presentation and overlays
  level-data.js         Hand-authored platform, enemy, item, and route data
  game-v2.js            Canvas renderer, physics, enemy AI, input, audio, and progression
  manifest.webmanifest  Installable app metadata
  sw.js                 Offline cache
  assets/               Original generated sprites and supplied family image
tools/
  server.mjs            Zero-dependency local development server
  validate.mjs          Syntax and asset-reference validation
```

## Validate

```bash
npm test
```

All artwork is original to this project and was created from the supplied references of Jelly and her family.

> **GitHub mirror:** The generated PNG artwork is served from the [live game](https://jellys-journey-home.nelsonmartinez86.chatgpt.site) so the repository stays lightweight. The gameplay source is complete and can be run locally with an internet connection.
