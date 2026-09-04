import { readFile, writeFile } from 'node:fs/promises';
import vm from 'node:vm';

const context = { window: {} };
vm.createContext(context);
vm.runInContext(await readFile(new URL('../src/level-data.js', import.meta.url), 'utf8'), context);

const secrets = {
  'ny-taxi': [[1240, 288, 'Rooftop scent cache'], [2560, 290, 'Fire-escape shortcut']],
  'ny-park': [[930, 246, 'Fountain rainbow'], [2360, 280, 'Tree-top acorn']],
  'ny-bridge': [[1040, 265, 'Cable path'], [3060, 255, 'Ferry-view perch']],
  'la-boardwalk': [[1070, 338, 'Skate-ramp loft'], [2535, 300, 'Mural ledge']],
  'la-studio': [[955, 220, 'Hidden soundstage'], [2660, 248, 'Spotlight catwalk']],
  'la-sunset': [[1040, 275, 'Ferris-wheel glint'], [3080, 250, 'Sunset telescope']],
  'la-jazz': [[1090, 255, 'Balcony rhythm room'], [2500, 240, 'Brass-note trail']],
  'la-bayou': [[1010, 240, 'Firefly hollow'], [3060, 230, 'Cypress canopy']],
  'la-riverboat': [[1030, 225, 'Paddlewheel loft'], [3130, 220, 'Captain deck']],
  'or-grove': [[1120, 255, 'Orange blossom arch'], [2500, 225, 'Windmill cache']],
  'or-lake': [[1010, 235, 'Fountain rainbow'], [3070, 220, 'Swan lookout']],
  'or-home': [[1030, 220, 'Memory ribbon'], [3150, 205, 'Porch-light path']],
};

const levels = context.window.JELLY_LEVELS.map((level, index) => ({
  ...level,
  level_number: index + 1,
  music: `${level.id}.ogg`,
  secrets: secrets[level.id],
  target_time_seconds: 115 + (index % 3) * 18,
}));

await writeFile(new URL('../data/levels.json', import.meta.url), `${JSON.stringify(levels, null, 2)}\n`);
console.log(`Exported ${levels.length} Godot levels with ${levels.reduce((sum, level) => sum + level.secrets.length, 0)} secret routes.`);

