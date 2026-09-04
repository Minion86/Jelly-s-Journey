import { access, readFile, stat } from 'node:fs/promises';

const root = new URL('../', import.meta.url);
const required = [
  'project.godot', 'export_presets.cfg', 'scenes/main.tscn',
  'scripts/Main.gd', 'scripts/Player.gd', 'scripts/Enemy.gd',
  'scripts/Squirrel.gd', 'scripts/AudioDirector.gd',
  'data/levels.json', 'data/story.json',
  'assets/jelly-sprites.png', 'assets/jelly-idle-v4.png',
  'assets/city-enemies.png', 'assets/squirrel-sprites.png', 'assets/family.jpeg',
];
await Promise.all(required.map(path => access(new URL(path, root))));

const levels = JSON.parse(await readFile(new URL('data/levels.json', root), 'utf8'));
if (levels.length !== 12) throw new Error(`Expected 12 Godot levels, found ${levels.length}`);
for (const [index, level] of levels.entries()) {
  for (const field of ['platforms', 'moving', 'treats', 'enemies', 'goal', 'checkpoint', 'hazards', 'props', 'squirrelPath', 'secrets']) {
    if (!Array.isArray(level[field]) || level[field].length === 0) throw new Error(`Level ${index + 1} is missing ${field}`);
  }
  if (level.treats.length !== 5) throw new Error(`${level.id} must have five scent treats`);
  const music = new URL(`audio/music/${level.id}.ogg`, root);
  await access(music);
  if ((await stat(music)).size < 20_000) throw new Error(`${level.id} music appears incomplete`);
}

const story = JSON.parse(await readFile(new URL('data/story.json', root), 'utf8'));
if (story.prologue.length < 6 || story.chapters.length !== 4) throw new Error('Expanded prologue or chapter story is incomplete');
if (Object.keys(story.level_endings).length !== 11) throw new Error('Every non-final level needs a story clue');

for (const name of ['bark_1', 'bark_2', 'bark_3', 'jump', 'land', 'treat', 'checkpoint', 'hurt', 'squirrel', 'win', 'whoosh']) {
  const file = new URL(`audio/sfx/${name}.ogg`, root);
  await access(file);
  if ((await stat(file)).size < 1_000) throw new Error(`${name} effect appears incomplete`);
}

const player = await readFile(new URL('scripts/Player.gd', root), 'utf8');
for (const feature of ['COYOTE_TIME', 'JUMP_BUFFER', 'idle_cycle', 'sleep', 'barked']) {
  if (!player.includes(feature)) throw new Error(`Player controller is missing ${feature}`);
}
const enemy = await readFile(new URL('scripts/Enemy.gd', root), 'utf8');
for (const state of ['ANTICIPATE', 'ATTACK', 'RECOVER', 'STUNNED']) {
  if (!enemy.includes(state)) throw new Error(`Enemy state machine is missing ${state}`);
}

console.log('Validated Godot project: 12 levels, expanded story, animation state machines, 12 original score loops, and 11 effect cues.');

