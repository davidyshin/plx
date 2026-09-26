update public.guild_preferences
set priority = 3
where priority > 3;

alter table public.guild_preferences
  drop constraint if exists guild_preferences_priority_check;

alter table public.guild_preferences
  add constraint guild_preferences_priority_check
  check (priority between 1 and 3);
