create extension if not exists pgcrypto;

create table if not exists public.guild_preferences (
  id uuid primary key default gen_random_uuid(),
  player_name text not null check (char_length(player_name) between 2 and 40),
  discord_name text not null default '' check (char_length(discord_name) <= 40),
  discord_user_id text,
  discord_avatar_url text,
  class_name text not null,
  race_name text not null,
  role_name text not null check (role_name in ('Tank','Healer','Melee DPS','Ranged DPS')),
  priority int not null default 1 check (priority between 1 and 3),
  availability text not null default 'Flexible',
  notes text not null default '' check (char_length(notes) <= 180),
  created_at timestamptz not null default now()
);

alter table public.guild_preferences enable row level security;
drop policy if exists "Public can read roster" on public.guild_preferences;
drop policy if exists "Public can add preferences" on public.guild_preferences;
drop policy if exists "Public can remove preferences" on public.guild_preferences;
create policy "Public can read roster" on public.guild_preferences for select to anon, authenticated using (true);
create policy "Authenticated users can add preferences" on public.guild_preferences for insert to authenticated with check (discord_user_id = auth.uid()::text);
create policy "Users can remove their preferences" on public.guild_preferences for delete to authenticated using (discord_user_id = auth.uid()::text);

create unique index if not exists guild_preferences_user_priority_idx
  on public.guild_preferences (discord_user_id, priority)
  where discord_user_id is not null;

alter publication supabase_realtime add table public.guild_preferences;
