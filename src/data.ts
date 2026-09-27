export const CLASS_RACES: Record<string, string[]> = {
  Warrior: ["Orc", "Undead", "Tauren", "Troll", "Skyborne"],
  Paladin: ["Undead"],
  Hunter: ["Orc", "Tauren", "Troll", "Skyborne"],
  Rogue: ["Orc", "Undead", "Troll", "Skyborne"],
  Priest: ["Undead", "Troll"],
  Shaman: ["Orc", "Tauren", "Troll", "Skyborne"],
  Mage: ["Orc", "Undead", "Troll"],
  Warlock: ["Orc", "Undead", "Troll"],
  Druid: ["Tauren", "Skyborne"],
};

export const CLASS_ROLES: Record<string, string[]> = {
  Warrior: ["Tank", "Melee DPS"],
  Paladin: ["Tank", "Healer", "Melee DPS"],
  Hunter: ["Ranged DPS"],
  Rogue: ["Melee DPS"],
  Priest: ["Healer", "Ranged DPS"],
  Shaman: ["Healer", "Melee DPS", "Ranged DPS"],
  Mage: ["Ranged DPS"],
  Warlock: ["Ranged DPS"],
  Druid: ["Tank", "Healer", "Melee DPS", "Ranged DPS", "Flex"],
};

export const CLASS_COLORS: Record<string, string> = {
  Druid: "#ff7c0a",
  Hunter: "#aad372",
  Mage: "#3fc7eb",
  Paladin: "#f48cba",
  Priest: "#f4f4f4",
  Rogue: "#fff468",
  Shaman: "#0070dd",
  Warlock: "#8788ee",
  Warrior: "#c69b6d",
};

export const ROLES = ["Tank", "Healer", "Melee DPS", "Ranged DPS", "Flex"];
export const AVAILABILITY = ["Weeknights", "Weekends", "Late night", "Flexible"];

export const ICONS: Record<string, string> = Object.fromEntries(
  Object.keys(CLASS_RACES).map((name) => [
    name,
    `https://wow.zamimg.com/images/wow/icons/large/classicon_${name.toLowerCase()}.jpg`,
  ]),
);

export const RACE_ICONS: Record<string, string> = {
  Orc: "https://warcraft.wiki.gg/images/Orc_Crest.png?6c2f52",
  Tauren: "https://warcraft.wiki.gg/images/Tauren_Crest.png?e638f5",
  Troll: "https://warcraft.wiki.gg/images/Troll_Crest.png?43b8d6",
  Undead: "https://warcraft.wiki.gg/images/Forsaken_Crest.png?a1c59d",
  Skyborne:
    "https://warcraft.wiki.gg/images/Inv_12ph_shop_skyborne_banner01_7645873.png?92cc98",
};
