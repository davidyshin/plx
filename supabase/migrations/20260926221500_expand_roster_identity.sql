alter table public.guild_preferences
  drop constraint if exists guild_preferences_player_name_check;

alter table public.guild_preferences
  add constraint guild_preferences_player_name_check
  check (char_length(player_name) between 2 and 40);
