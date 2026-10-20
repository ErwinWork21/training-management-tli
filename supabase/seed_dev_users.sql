-- ============================================================================
-- SQL Seed for Development Users (Admin, Supervisor, Trainer, Trainee)
-- Correctly provisions auth.users AND auth.identities with valid UUIDs
-- for local Postgres / Supabase CLI testing.
-- ============================================================================

do $$
declare
  v_admin_id uuid := 'a0000000-0000-0000-0000-000000000001';
  v_sup_id   uuid := 'a0000000-0000-0000-0000-000000000002';
  v_trn_id   uuid := 'a0000000-0000-0000-0000-000000000003';
  v_tne_id   uuid := 'a0000000-0000-0000-0000-000000000004';

  v_enc_password text := crypt('DevPassword@123!', gen_salt('bf'));
  v_kinder_id uuid;
  v_trainer_entity_id uuid;
  v_trainee_entity_id uuid;

  v_trainee_status text;
  v_assign_status  text;
begin
  -- 1. Create or update auth.users
  -- ADMIN
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    aud, role
  ) values (
    v_admin_id, '00000000-0000-0000-0000-000000000000', 'admin@thelab.local',
    v_enc_password, now(), '{"provider":"email","providers":["email"],"role":"admin"}'::jsonb,
    '{"full_name":"System Administrator"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ) on conflict (id) do update set
    raw_app_meta_data = excluded.raw_app_meta_data,
    encrypted_password = excluded.encrypted_password;

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  ) values (
    v_admin_id, v_admin_id, jsonb_build_object('sub', v_admin_id::text, 'email', 'admin@thelab.local'),
    'email', v_admin_id::text, now(), now(), now()
  ) on conflict (provider, provider_id) do nothing;

  -- SUPERVISOR
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    aud, role
  ) values (
    v_sup_id, '00000000-0000-0000-0000-000000000000', 'supervisor@thelab.local',
    v_enc_password, now(), '{"provider":"email","providers":["email"],"role":"supervisor"}'::jsonb,
    '{"full_name":"Lead Supervisor"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ) on conflict (id) do update set
    raw_app_meta_data = excluded.raw_app_meta_data,
    encrypted_password = excluded.encrypted_password;

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  ) values (
    v_sup_id, v_sup_id, jsonb_build_object('sub', v_sup_id::text, 'email', 'supervisor@thelab.local'),
    'email', v_sup_id::text, now(), now(), now()
  ) on conflict (provider, provider_id) do nothing;

  -- TRAINER
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    aud, role
  ) values (
    v_trn_id, '00000000-0000-0000-0000-000000000000', 'trainer@thelab.local',
    v_enc_password, now(), '{"provider":"email","providers":["email"],"role":"trainer"}'::jsonb,
    '{"full_name":"Master Trainer"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ) on conflict (id) do update set
    raw_app_meta_data = excluded.raw_app_meta_data,
    encrypted_password = excluded.encrypted_password;

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  ) values (
    v_trn_id, v_trn_id, jsonb_build_object('sub', v_trn_id::text, 'email', 'trainer@thelab.local'),
    'email', v_trn_id::text, now(), now(), now()
  ) on conflict (provider, provider_id) do nothing;

  -- TRAINEE
  insert into auth.users (
    id, instance_id, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    aud, role
  ) values (
    v_tne_id, '00000000-0000-0000-0000-000000000000', 'trainee@thelab.local',
    v_enc_password, now(), '{"provider":"email","providers":["email"],"role":"trainee"}'::jsonb,
    '{"full_name":"Salwa Trainee"}'::jsonb, now(), now(), 'authenticated', 'authenticated'
  ) on conflict (id) do update set
    raw_app_meta_data = excluded.raw_app_meta_data,
    encrypted_password = excluded.encrypted_password;

  insert into auth.identities (
    id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
  ) values (
    v_tne_id, v_tne_id, jsonb_build_object('sub', v_tne_id::text, 'email', 'trainee@thelab.local'),
    'email', v_tne_id::text, now(), now(), now()
  ) on conflict (provider, provider_id) do nothing;

  -- 2. Verify / update profiles
  update public.profiles set role = 'admin', full_name = 'System Administrator' where id = v_admin_id;
  update public.profiles set role = 'supervisor', full_name = 'Lead Supervisor' where id = v_sup_id;
  update public.profiles set role = 'trainer', full_name = 'Master Trainer' where id = v_trn_id;
  update public.profiles set role = 'trainee', full_name = 'Salwa Trainee' where id = v_tne_id;

  -- 3. Provision entity rows
  select enumlabel into v_trainee_status
  from pg_type t join pg_enum e on e.enumtypid = t.oid
  where t.typname = 'trainee_status' and lower(e.enumlabel) = 'active'
  order by case when e.enumlabel = 'active' then 1 else 2 end limit 1;
  if v_trainee_status is null then v_trainee_status := 'active'; end if;

  select enumlabel into v_assign_status
  from pg_type t join pg_enum e on e.enumtypid = t.oid
  where t.typname = 'assignment_status' and lower(e.enumlabel) = 'active'
  order by case when e.enumlabel = 'active' then 1 else 2 end limit 1;
  if v_assign_status is null then v_assign_status := 'active'; end if;

  insert into public.trainers (profile_id, employee_code, bio)
  values (v_trn_id, 'TRN-001', 'Experienced Master Trainer')
  on conflict (profile_id) do update set employee_code = excluded.employee_code
  returning id into v_trainer_entity_id;

  select id into v_kinder_id from public.levels where code = 'KINDER';

  execute '
    insert into public.trainees (profile_id, employee_code, branch, current_level_id, join_date, status)
    values ($1, ''TNE-001'', ''Jakarta Barat'', $2, current_date, cast($3 as trainee_status))
    on conflict (profile_id) do update set employee_code = excluded.employee_code
    returning id'
  into v_trainee_entity_id
  using v_tne_id, v_kinder_id, v_trainee_status;

  -- 4. Active trainer - trainee assignment
  execute '
    insert into public.trainer_trainee_assignments (trainer_id, trainee_id, start_date, status, notes)
    values ($1, $2, current_date, cast($3 as assignment_status), ''Initial onboarding assignment'')
    on conflict do nothing'
  using v_trainer_entity_id, v_trainee_entity_id, v_assign_status;

end $$;
