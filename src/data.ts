export const CLASS_RACES: Record<string, string[]> = {
  'Death Knight': ['Blood Elf','Draenei','Dwarf','Gnome','Goblin','Human','Night Elf','Orc','Tauren','Troll','Undead','Worgen'],
  'Demon Hunter': ['Blood Elf','Night Elf'],
  Druid: ['Night Elf','Tauren','Troll','Worgen'],
  Hunter: ['Blood Elf','Draenei','Dwarf','Gnome','Goblin','Human','Night Elf','Orc','Tauren','Troll','Undead','Worgen'],
  Mage: ['Blood Elf','Draenei','Dwarf','Gnome','Goblin','Human','Night Elf','Orc','Troll','Undead','Worgen'],
  Monk: ['Blood Elf','Draenei','Dwarf','Gnome','Human','Night Elf','Orc','Tauren','Troll','Undead'],
  Paladin: ['Blood Elf','Draenei','Dwarf','Human','Tauren'],
  Priest: ['Blood Elf','Draenei','Dwarf','Gnome','Goblin','Human','Night Elf','Tauren','Troll','Undead','Worgen'],
  Rogue: ['Blood Elf','Dwarf','Gnome','Goblin','Human','Night Elf','Orc','Troll','Undead','Worgen'],
  Shaman: ['Draenei','Dwarf','Goblin','Orc','Tauren','Troll'],
  Warlock: ['Blood Elf','Dwarf','Gnome','Goblin','Human','Orc','Troll','Undead','Worgen'],
  Warrior: ['Blood Elf','Draenei','Dwarf','Gnome','Goblin','Human','Night Elf','Orc','Tauren','Troll','Undead','Worgen'],
}

export const CLASS_COLORS: Record<string, string> = {'Death Knight':'#c41e3a','Demon Hunter':'#a330c9',Druid:'#ff7c0a',Hunter:'#aad372',Mage:'#3fc7eb',Monk:'#00ff98',Paladin:'#f48cba',Priest:'#f4f4f4',Rogue:'#fff468',Shaman:'#0070dd',Warlock:'#8788ee',Warrior:'#c69b6d'}
export const ROLES = ['Tank','Healer','Melee DPS','Ranged DPS']
export const AVAILABILITY = ['Weeknights','Weekends','Late night','Flexible']
export const ICONS: Record<string,string> = Object.fromEntries(Object.keys(CLASS_RACES).map(name => [name, `https://wow.zamimg.com/images/wow/icons/large/classicon_${name.toLowerCase().replace('death knight','deathknight').replace('demon hunter','demonhunter')}.jpg`]))
