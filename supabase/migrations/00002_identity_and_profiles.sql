-- ============================================================================
-- 00002: Identity and profiles
-- ============================================================================

create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null unique,
  full_name   text not null,
  role        user_role not null default 'trainee',
  phone       text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index idx_profiles_role on profiles(role);

create trigger trg_profiles_updated_at
  before update on profiles
  for each row execute function set_updated_at();

-- Auto-provision profile row when new auth user signs up.
-- Role is extracted ONLY from raw_app_meta_data (server/admin controlled).
-- Any client-controlled raw_user_meta_data is strictly ignored for role assignment.
create or replace function handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role user_role := 'trainee';
  v_meta_role text;
begin
  -- Only read role from server-controlled raw_app_meta_data
  v_meta_role := new.raw_app_meta_data->>'role';
  
  if v_meta_role in ('admin', 'trainer', 'supervisor', 'trainee') then
    v_role := v_meta_role::user_role;
  end if;

  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    v_role
  );
  return new;
end;
$$;

create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_auth_user();

-- Dedicated admin function to set user role safely
create or replace function admin_set_user_role(p_profile_id uuid, p_role user_role)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_role user_role;
begin
  -- Authorize: caller must be an admin or superuser
  if current_user not in ('postgres', 'supabase_admin') then
    select role into v_caller_role from public.profiles where id = auth.uid();
    if v_caller_role is null or v_caller_role <> 'admin' then
      raise exception 'Only administrators can change user roles'
        using errcode = '42501';
    end if;
  end if;

  -- Update profiles table
  update public.profiles
  set role = p_role, updated_at = now()
  where id = p_profile_id;

  -- Sync raw_app_meta_data in auth.users so Supabase auth tokens reflect the role
  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_role::text)
  where id = p_profile_id;

  -- Ensure role-specific entity records exist if table is present
  if p_role = 'trainer' then
    if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'trainers') then
      execute 'insert into public.trainers (profile_id) values ($1) on conflict (profile_id) do nothing' using p_profile_id;
    end if;
  elsif p_role = 'trainee' then
    if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'trainees') then
      execute 'insert into public.trainees (profile_id) values ($1) on conflict (profile_id) do nothing' using p_profile_id;
    end if;
  end if;
end;
$$;
