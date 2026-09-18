-- ============================================================================
-- 00002: profiles — one row per auth.users, carries the app role
-- ============================================================================

create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null unique,
  full_name   text not null,
  role        user_role not null,
  phone       text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_profiles_role on profiles(role);

create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute function set_updated_at();

-- Auto-create a profile row whenever a new auth user is created.
-- Role defaults to 'trainee' and MUST be corrected by an admin — the
-- signup flow never lets a client choose its own role.
create or replace function handle_new_auth_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'trainee')
  );
  return new;
end;
$$;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_auth_user();

comment on function handle_new_auth_user() is
  'Creates a profiles row for every new auth.users row. Admin-provisioned '
  'accounts should pass the intended role via raw_user_meta_data ->> ''role'' '
  'at creation time (service-role only); self-signup should never be trusted '
  'to set anything other than trainee.';
