-- Damla shared tracker: run this entire file in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.damla_trackers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  member_id uuid references auth.users(id) on delete set null,
  invite_code text not null unique,
  state jsonb not null default '{"medicines":[],"rewards":[],"points":0,"reminded":{}}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint damla_one_member_only check (member_id is null or member_id <> owner_id)
);

alter table public.damla_trackers enable row level security;

drop policy if exists "Members can read their tracker" on public.damla_trackers;
create policy "Members can read their tracker"
on public.damla_trackers for select to authenticated
using (auth.uid() = owner_id or auth.uid() = member_id);

create or replace function public.damla_create_tracker()
returns table(tracker_id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  new_code text;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if exists(select 1 from public.damla_trackers where owner_id = auth.uid() or member_id = auth.uid()) then
    raise exception 'You already belong to a tracker';
  end if;
  loop
    new_code := upper(encode(gen_random_bytes(5), 'hex'));
    exit when not exists(select 1 from public.damla_trackers where damla_trackers.invite_code = new_code);
  end loop;
  insert into public.damla_trackers(owner_id, invite_code)
  values(auth.uid(), new_code)
  returning id into new_id;
  return query select new_id, new_code;
end;
$$;

create or replace function public.damla_join_tracker(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  joined_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  if exists(select 1 from public.damla_trackers where owner_id = auth.uid() or member_id = auth.uid()) then
    raise exception 'You already belong to a tracker';
  end if;
  update public.damla_trackers
  set member_id = auth.uid(), updated_at = now()
  where invite_code = upper(trim(p_invite_code)) and member_id is null
  returning id into joined_id;
  if joined_id is null then raise exception 'Invite code is invalid or already used'; end if;
  return joined_id;
end;
$$;

create or replace function public.damla_get_tracker()
returns table(tracker_id uuid, state jsonb, invite_code text, is_owner boolean, member_joined boolean)
language sql
security definer
set search_path = public
as $$
  select t.id, t.state, t.invite_code, (t.owner_id = auth.uid()), (t.member_id is not null)
  from public.damla_trackers t
  where auth.uid() = t.owner_id or auth.uid() = t.member_id
  limit 1;
$$;

create or replace function public.damla_save_state(p_state jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  update public.damla_trackers
  set state = p_state, updated_at = now()
  where auth.uid() = owner_id or auth.uid() = member_id;
  if not found then raise exception 'Tracker not found'; end if;
end;
$$;

revoke all on function public.damla_create_tracker() from public;
revoke all on function public.damla_join_tracker(text) from public;
revoke all on function public.damla_get_tracker() from public;
revoke all on function public.damla_save_state(jsonb) from public;

grant execute on function public.damla_create_tracker() to authenticated;
grant execute on function public.damla_join_tracker(text) to authenticated;
grant execute on function public.damla_get_tracker() to authenticated;
grant execute on function public.damla_save_state(jsonb) to authenticated;
grant select on public.damla_trackers to authenticated;
