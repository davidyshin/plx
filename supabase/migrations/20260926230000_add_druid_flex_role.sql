alter table public.guild_preferences
  drop constraint if exists guild_preferences_role_name_check;

alter table public.guild_preferences
  add constraint guild_preferences_role_name_check
  check (role_name in ('Tank', 'Healer', 'Melee DPS', 'Ranged DPS', 'Flex'));
