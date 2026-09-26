create extension if not exists pgcrypto;

create table if not exists public.guild_preferences (
  id uuid primary key default gen_random_uuid(),
  player_name text not null check (char_length(player_name) between 2 and 24),
  discord_name text not null default '' check (char_length(discord_name) <= 40),
  class_name text not null,
  race_name text not null,
  role_name text not null check (role_name in ('Tank','Healer','Melee DPS','Ranged DPS')),
  priority int not null default 1 check (priority between 1 and 5),
  availability text not null default 'Flexible',
  notes text not null default '' check (char_length(notes) <= 180),
  created_at timestamptz not null default now()
);

alter table public.guild_preferences enable row level security;

create policy "Public can read roster"
  on public.guild_preferences for select
  to anon, authenticated using (true);

create policy "Public can add preferences"
  on public.guild_preferences for insert
  to anon, authenticated with check (true);

create policy "Public can remove preferences"
  on public.guild_preferences for delete
  to anon, authenticated using (true);

alter publication supabase_realtime add table public.guild_preferences;
