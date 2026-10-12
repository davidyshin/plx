const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.join(__dirname, '..', 'addon', 'PlxTogether');
const toc = fs.readFileSync(path.join(root, 'PlxTogether.toc'), 'utf8');
const files = toc.split(/\r?\n/).map(s => s.trim()).filter(s => s && !s.startsWith('#'));
assert.deepEqual(files, ['Planner.lua', 'Protocol.lua', 'Provider.lua', 'Demo.lua', 'Core.lua', 'Navigation.lua', 'Map.lua', 'Guide.lua', 'Window.lua', 'Tracker.lua']);
for (const file of files) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  assert(source.startsWith('local _, HT = ...'), `${file}: shared namespace missing`);
  assert(!source.includes('\u0000'), `${file}: unexpected null bytes`);
}
console.log('Manifest checks passed: load order, referenced files, shared namespace.');
for (const [name,size] of [['paddington.tga',256],['route-pin.tga',128]]) {
  const bytes=fs.readFileSync(path.join(root,'Media',name));
  assert.equal(bytes.readUInt16LE(12),size); assert.equal(bytes.readUInt16LE(14),size);
  assert.equal(bytes[16],32); assert.equal(bytes.length,18+size*size*4);
}
console.log('Game textures checked: dimensions, alpha format, complete data.');
