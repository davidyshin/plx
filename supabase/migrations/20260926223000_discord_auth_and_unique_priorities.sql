drop policy if exists "Public can add preferences" on public.guild_preferences;
drop policy if exists "Public can remove preferences" on public.guild_preferences;

create policy "Authenticated users can add preferences"
  on public.guild_preferences
  for insert
  to authenticated
  with check (discord_user_id = auth.uid()::text);

create policy "Users can remove their preferences"
  on public.guild_preferences
  for delete
  to authenticated
  using (discord_user_id = auth.uid()::text);

create unique index guild_preferences_user_priority_idx
  on public.guild_preferences (discord_user_id, priority)
  where discord_user_id is not null;
