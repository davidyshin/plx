const fs = require('node:fs');
const path = require('node:path');
const lua = require('luaparse');
const root = path.join(__dirname, '..', 'addon', 'PlxTogether');
for (const file of fs.readdirSync(root).filter(f => f.endsWith('.lua'))) {
  lua.parse(fs.readFileSync(path.join(root, file), 'utf8'), {luaVersion: '5.1'});
}
for (const file of fs.readdirSync(__dirname).filter(f => f.endsWith('.lua'))) {
  lua.parse(fs.readFileSync(path.join(__dirname, file), 'utf8'), {luaVersion: '5.1'});
}
console.log('Lua 5.1 syntax checks passed.');
