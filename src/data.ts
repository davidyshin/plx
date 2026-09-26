export const CLASS_RACES: Record<string, string[]> = {
  'Death Knight': ['Blood Elf','Goblin','Orc','Tauren','Troll','Undead'],
  'Demon Hunter': ['Blood Elf'],
  Druid: ['Tauren','Troll'],
  Hunter: ['Blood Elf','Goblin','Orc','Tauren','Troll','Undead'],
  Mage: ['Blood Elf','Goblin','Orc','Troll','Undead'],
  Monk: ['Blood Elf','Orc','Tauren','Troll','Undead'],
  Paladin: ['Blood Elf','Tauren'],
  Priest: ['Blood Elf','Goblin','Tauren','Troll','Undead'],
  Rogue: ['Blood Elf','Goblin','Orc','Troll','Undead'],
  Shaman: ['Goblin','Orc','Tauren','Troll'],
  Warlock: ['Blood Elf','Goblin','Orc','Troll','Undead'],
  Warrior: ['Blood Elf','Goblin','Orc','Tauren','Troll','Undead'],
}

export const CLASS_COLORS: Record<string, string> = {'Death Knight':'#c41e3a','Demon Hunter':'#a330c9',Druid:'#ff7c0a',Hunter:'#aad372',Mage:'#3fc7eb',Monk:'#00ff98',Paladin:'#f48cba',Priest:'#f4f4f4',Rogue:'#fff468',Shaman:'#0070dd',Warlock:'#8788ee',Warrior:'#c69b6d'}
export const ROLES = ['Tank','Healer','Melee DPS','Ranged DPS']
export const AVAILABILITY = ['Weeknights','Weekends','Late night','Flexible']
export const ICONS: Record<string,string> = Object.fromEntries(Object.keys(CLASS_RACES).map(name => [name, `https://wow.zamimg.com/images/wow/icons/large/classicon_${name.toLowerCase().replace('death knight','deathknight').replace('demon hunter','demonhunter')}.jpg`]))
