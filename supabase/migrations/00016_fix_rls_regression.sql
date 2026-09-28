-- 00016: Fix RLS Regression

-- The 00015 migration introduced mutual recursion between `teachers` and `trainer_trainee_assignments`
-- which broke queries for all roles.
-- The 00012 migration suffered from the Postgres query planner inlining `LANGUAGE SQL STABLE` 
-- functions before `auth.uid()` was correctly evaluated, sometimes silently returning NULL.

-- We revert to using SECURITY DEFINER helper functions to break RLS recursion,
-- but we change them to `LANGUAGE plpgsql` to prevent the planner from inlining them.

create or replace function current_role_name()
returns user_role
language plpgsql security definer set search_path = public
as $$
declare
  v_role user_role;
begin
  select role into v_role from profiles where id = auth.uid();
  return v_role;
end;
$$;

create or replace function current_trainer_id()
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
begin
  select id into v_id from trainers where profile_id = auth.uid();
  return v_id;
end;
$$;

create or replace function current_teacher_id()
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
begin
  select id into v_id from teachers where profile_id = auth.uid();
  return v_id;
end;
$$;

create or replace function is_my_trainee(p_trainee_id uuid)
returns boolean
language plpgsql security definer set search_path = public
as $$
declare
  v_trainer_id uuid;
begin
  v_trainer_id := current_trainer_id();
  if v_trainer_id is null then
    return false;
  end if;
  
  return exists (
    select 1 from trainer_trainee_assignments
    where trainer_id = v_trainer_id and trainee_id = p_trainee_id
  );
end;
$$;

-- Fix profiles policy
drop policy if exists profiles_select_own_or_staff on profiles;
create policy profiles_select_own_or_staff on profiles for select
  using (
    id = auth.uid()
    or current_role_name() in ('admin', 'supervisor', 'trainer')
  );

-- Fix assignments policy
drop policy if exists assignments_select on trainer_trainee_assignments;
create policy assignments_select on trainer_trainee_assignments for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );

-- Fix teachers policy
drop policy if exists teachers_select on teachers;
create policy teachers_select on teachers for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or profile_id = auth.uid()
    or (
      current_role_name() = 'trainer' 
      and is_my_trainee(id)
    )
  );
