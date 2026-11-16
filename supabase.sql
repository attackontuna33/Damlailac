-- DAMLA LOGIN'SIZ ORTAK TAKİP
-- Bu sürümde kullanıcı hesabı yoktur. Rastgele erişim anahtarı URL'de taşınır.
create extension if not exists pgcrypto;

create table if not exists public.damla_shared_trackers (
  id uuid primary key default gen_random_uuid(),
  access_token text not null unique,
  state jsonb not null default '{"medicines":[],"rewards":[{"id":"r1","name":"Birlikte kahve","cost":100},{"id":"r2","name":"Film gecesi","cost":200},{"id":"r3","name":"Küçük bir sürpriz","cost":350}],"points":0,"reminded":{},"redemptions":[]}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.damla_shared_trackers enable row level security;
revoke all on public.damla_shared_trackers from anon, authenticated;

create or replace function public.damla_public_create()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare v_token text;
begin
  v_token := encode(gen_random_bytes(24),'hex');
  insert into public.damla_shared_trackers(access_token) values(v_token);
  return v_token;
end;
$$;

create or replace function public.damla_public_get(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare v_state jsonb;
begin
  select state into v_state
  from public.damla_shared_trackers
  where access_token = p_token;
  if not found then raise exception 'Takip bağlantısı geçersiz'; end if;
  return v_state;
end;
$$;

create or replace function public.damla_public_save(p_token text,p_state jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.damla_shared_trackers
  set state = p_state, updated_at = now()
  where access_token = p_token;
  if not found then raise exception 'Takip bağlantısı geçersiz'; end if;
end;
$$;

revoke all on function public.damla_public_create() from public;
revoke all on function public.damla_public_get(text) from public;
revoke all on function public.damla_public_save(text,jsonb) from public;
grant execute on function public.damla_public_create() to anon, authenticated;
grant execute on function public.damla_public_get(text) to anon, authenticated;
grant execute on function public.damla_public_save(text,jsonb) to anon, authenticated;
