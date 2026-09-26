alter table public.guild_preferences
  add column if not exists discord_user_id text,
  add column if not exists discord_avatar_url text;
