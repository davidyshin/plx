const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.join(__dirname, '..', 'addon', 'PlxTogether');
const toc = fs.readFileSync(path.join(root, 'PlxTogether.toc'), 'utf8');
const files = toc.split(/\r?\n/).map(s => s.trim()).filter(s => s && !s.startsWith('#'));
assert.deepEqual(files, ['Planner.lua', 'Protocol.lua', 'Provider.lua', 'Demo.lua', 'Core.lua', 'Map.lua', 'Guide.lua', 'Window.lua', 'Tracker.lua']);
for (const file of files) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  assert(source.startsWith('local _, HT = ...'), `${file}: shared namespace missing`);
  assert(!source.includes('\u0000'), `${file}: unexpected null bytes`);
}
console.log('Manifest checks passed: load order, referenced files, shared namespace.');
