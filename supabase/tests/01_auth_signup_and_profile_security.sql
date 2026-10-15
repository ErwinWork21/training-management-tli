-- ============================================================================
-- pgTAP Test 01: Auth Signup and Profile Security
-- Tests Findings 1 & 2
-- ============================================================================

begin;
select plan(5);

-- 1. Test finding 1: Client cannot elevate role via raw_user_meta_data
-- Simulate inserting into auth.users with raw_user_meta_data = '{"role": "admin"}'
insert into auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  aud, role
) values (
  'b0000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'attacker@example.com',
  'irrelevant_hash',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"role":"admin","full_name":"Attacker"}'::jsonb,
  now(), now(), 'authenticated', 'authenticated'
);

select results_eq(
  'select role from public.profiles where id = ''b0000000-0000-0000-0000-000000000001''',
  $$values ('trainee'::user_role)$$,
  'Signup with client role=admin in user_metadata must result in role trainee'
);

select is(
  (select count(*) from public.trainees where profile_id = 'b0000000-0000-0000-0000-000000000001')::int,
  1,
  'Trainee record must be auto-provisioned'
);

select is(
  (select count(*) from public.trainers where profile_id = 'b0000000-0000-0000-0000-000000000001')::int,
  0,
  'Trainer record must NOT be provisioned'
);

-- 2. Test finding 2: User cannot update own role to admin
-- Switch to authenticated trainee context
set local role authenticated;
set local "request.jwt.claim.sub" = 'b0000000-0000-0000-0000-000000000001';

-- Attempt updating full_name (allowed)
select lives_ok(
  $$update public.profiles set full_name = 'Attacker Updated' where id = 'b0000000-0000-0000-0000-000000000001'$$,
  'Trainee can update own full_name'
);

-- Attempt updating role column directly (must be rejected by column grant restriction)
select throws_ok(
  $$update public.profiles set role = 'admin' where id = 'b0000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'Trainee cannot update own role column (permission denied)'
);

select * from finish();
rollback;
