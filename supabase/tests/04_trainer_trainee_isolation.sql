-- ============================================================================
-- pgTAP Test 04: Trainer - Trainee Isolation and Assignment Lifecycles
-- Tests Finding 5 & 5b: Trainers can only insert for active assigned trainees
-- ============================================================================

begin;
select plan(5);

-- Setup test curriculum
insert into public.levels (id, name, code, sequence_order)
values ('d0000000-0000-0000-0000-000000000001', 'IsoLevel', 'ISOLEV', 1) on conflict do nothing;
insert into public.training_tracks (id, level_id, name, code, sequence_order)
values ('d0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000001', 'IsoTrack', 'ISOTRK', 1) on conflict do nothing;
insert into public.training_units (id, track_id, name, code, sequence_order)
values ('d0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000002', 'IsoUnit', 'ISOUNT', 1) on conflict do nothing;
insert into public.training_materials (id, unit_id, title, sequence_order)
values ('d0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000003', 'IsoMaterial', 1) on conflict do nothing;

-- Users: Trainer A, Trainer B, Trainee A, Trainee B
insert into auth.users (id, email, raw_app_meta_data) values
  ('d0000000-0000-0000-0000-000000000010', 'trainerA@example.com', '{"role":"trainer"}'::jsonb),
  ('d0000000-0000-0000-0000-000000000011', 'trainerB@example.com', '{"role":"trainer"}'::jsonb),
  ('d0000000-0000-0000-0000-000000000020', 'traineeA@example.com', '{"role":"trainee"}'::jsonb),
  ('d0000000-0000-0000-0000-000000000021', 'traineeB@example.com', '{"role":"trainee"}'::jsonb)
on conflict do nothing;

-- Assignments: Trainer A -> Trainee A (active); Trainer B -> Trainee B (active)
insert into public.trainer_trainee_assignments (trainer_id, trainee_id, status)
values
  (
    (select id from public.trainers where profile_id = 'd0000000-0000-0000-0000-000000000010'),
    (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000020'),
    'active'
  ),
  (
    (select id from public.trainers where profile_id = 'd0000000-0000-0000-0000-000000000011'),
    (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000021'),
    'active'
  );

-- Connect as Trainer A
set local role authenticated;
set local "request.jwt.claim.sub" = 'd0000000-0000-0000-0000-000000000010';

-- 1. Trainer A creates session for assigned Trainee A (Success)
select lives_ok(
  $$insert into public.training_sessions (
      trainer_id, trainee_id, material_id, planned_date, status
    ) values (
      (select id from public.trainers where profile_id = 'd0000000-0000-0000-0000-000000000010'),
      (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000020'),
      'd0000000-0000-0000-0000-000000000004',
      current_date,
      'planned'
    )$$,
  'Trainer A can create session for assigned Trainee A'
);

-- 2. Trainer A attempts to create session for unassigned Trainee B (Must fail RLS)
select throws_ok(
  $$insert into public.training_sessions (
      trainer_id, trainee_id, material_id, planned_date, status
    ) values (
      (select id from public.trainers where profile_id = 'd0000000-0000-0000-0000-000000000010'),
      (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000021'),
      'd0000000-0000-0000-0000-000000000004',
      current_date,
      'planned'
    )$$,
  '42501',
  null,
  'Trainer A cannot create session for Trainee B (RLS check failed)'
);

-- 3. Trainer A attempts to insert observation for Trainee B (Must fail RLS)
select throws_ok(
  $$insert into public.observations (
      trainer_id, trainee_id, material_id, overall_score, status
    ) values (
      (select id from public.trainers where profile_id = 'd0000000-0000-0000-0000-000000000010'),
      (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000021'),
      'd0000000-0000-0000-0000-000000000004',
      85.00,
      'submitted'
    )$$,
  '42501',
  null,
  'Trainer A cannot insert observation for Trainee B (RLS check failed)'
);

-- 4. End assignment between Trainer A and Trainee A
reset role;
update public.trainer_trainee_assignments
set status = 'ended', end_date = current_date
where trainer_id = (select id from public.trainers where profile_id = 'd0000000-0000-0000-0000-000000000010')
  and trainee_id = (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000020');

-- Switch back to Trainer A
set local role authenticated;
set local "request.jwt.claim.sub" = 'd0000000-0000-0000-0000-000000000010';

-- Historical SELECT must succeed
select is(
  (select count(*) from public.training_sessions
   where trainee_id = (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000020'))::int,
  1,
  'Trainer A can read historical sessions of formerly assigned Trainee A'
);

-- But new INSERT must fail since assignment is no longer active
select throws_ok(
  $$insert into public.training_sessions (
      trainer_id, trainee_id, material_id, planned_date, status
    ) values (
      (select id from public.trainers where profile_id = 'd0000000-0000-0000-0000-000000000010'),
      (select id from public.trainees where profile_id = 'd0000000-0000-0000-0000-000000000020'),
      'd0000000-0000-0000-0000-000000000004',
      current_date,
      'planned'
    )$$,
  '42501',
  null,
  'Trainer A cannot create new sessions after assignment is ended'
);

select * from finish();
rollback;
