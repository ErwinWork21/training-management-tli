-- ============================================================================
-- pgTAP Test 06: Recalculate Material Progress Edge Cases
-- Tests Finding 6: Progress calculation logic, edge cases, and triggers
-- ============================================================================

begin;
select plan(6);

-- Setup test material
insert into public.levels (id, name, code, sequence_order) values ('f0000000-0000-0000-0000-000000000001', 'ProgLevel', 'PRGLEV', 1) on conflict do nothing;
insert into public.training_tracks (id, level_id, name, code, sequence_order) values ('f0000000-0000-0000-0000-000000000002', 'f0000000-0000-0000-0000-000000000001', 'ProgTrack', 'PRGTRK', 1) on conflict do nothing;
insert into public.training_units (id, track_id, name, code, sequence_order) values ('f0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000002', 'ProgUnit', 'PRGUNT', 1) on conflict do nothing;
insert into public.training_materials (id, unit_id, title, sequence_order) values ('f0000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000003', 'EdgeMaterial', 1) on conflict do nothing;

-- Users
insert into auth.users (id, email, raw_app_meta_data) values
  ('f0000000-0000-0000-0000-000000000010', 'trainer_edge@example.com', '{"role":"trainer"}'::jsonb),
  ('f0000000-0000-0000-0000-000000000011', 'trainee_edge@example.com', '{"role":"trainee"}'::jsonb)
on conflict do nothing;

-- 1. Setup single mandatory requirement: Observation with min_score 70
insert into public.material_requirements (material_id, requirement_type, is_mandatory, min_score)
values ('f0000000-0000-0000-0000-000000000004', 'observation', true, 70.00);

-- Insert passing observation (score 80)
insert into public.observations (trainee_id, trainer_id, material_id, overall_score, observation_date, status)
values (
  (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011'),
  (select id from public.trainers where profile_id = 'f0000000-0000-0000-0000-000000000010'),
  'f0000000-0000-0000-0000-000000000004',
  80.00,
  current_date - 2,
  'submitted'
);

select results_eq(
  $$select status, percentage from public.trainee_material_progress
    where trainee_id = (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011')
      and material_id = 'f0000000-0000-0000-0000-000000000004'$$,
  $$values ('completed'::material_status, 100.00::numeric)$$,
  'Trainee with passing observation must have progress completed at 100%'
);

-- Edge Case 1: Trainee receives newer submitted observation that FAILS (score 40)
insert into public.observations (trainee_id, trainer_id, material_id, overall_score, observation_date, status)
values (
  (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011'),
  (select id from public.trainers where profile_id = 'f0000000-0000-0000-0000-000000000010'),
  'f0000000-0000-0000-0000-000000000004',
  40.00,
  current_date,
  'submitted'
);

select results_eq(
  $$select status, percentage from public.trainee_material_progress
    where trainee_id = (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011')
      and material_id = 'f0000000-0000-0000-0000-000000000004'$$,
  $$values ('not_started'::material_status, 0.00::numeric)$$,
  'When latest observation fails, status must drop from completed to not_started (0%)'
);

-- Edge Case 2: Stale Verification
-- Submit passing observation again (date = current_date + 1)
insert into public.observations (trainee_id, trainer_id, material_id, overall_score, observation_date, status)
values (
  (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011'),
  (select id from public.trainers where profile_id = 'f0000000-0000-0000-0000-000000000010'),
  'f0000000-0000-0000-0000-000000000004',
  85.00,
  current_date + 1,
  'submitted'
);

-- Verification record created now
insert into public.verification_records (trainee_id, trainer_id, material_id, status, created_at)
values (
  (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011'),
  (select id from public.trainers where profile_id = 'f0000000-0000-0000-0000-000000000010'),
  'f0000000-0000-0000-0000-000000000004',
  'verified',
  now()
);

select results_eq(
  $$select status from public.trainee_material_progress
    where trainee_id = (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011')
      and material_id = 'f0000000-0000-0000-0000-000000000004'$$,
  $$values ('verified'::material_status)$$,
  'Verification record promotes progress to verified'
);

-- Newer observation is submitted AFTER verification -> verification becomes stale!
insert into public.observations (trainee_id, trainer_id, material_id, overall_score, observation_date, status, created_at)
values (
  (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011'),
  (select id from public.trainers where profile_id = 'f0000000-0000-0000-0000-000000000010'),
  'f0000000-0000-0000-0000-000000000004',
  90.00,
  current_date + 2,
  'submitted',
  now() + interval '1 minute'
);

select results_eq(
  $$select status from public.trainee_material_progress
    where trainee_id = (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011')
      and material_id = 'f0000000-0000-0000-0000-000000000004'$$,
  $$values ('completed'::material_status)$$,
  'Newer evidence after verification must revert status from verified back to completed'
);

-- Edge Case 3: Admin adds second mandatory requirement (Competency Assessment)
insert into public.competencies (id, name) values ('f0000000-0000-0000-0000-000000000020', 'EdgeComp') on conflict do nothing;
insert into public.material_competencies (material_id, competency_id) values ('f0000000-0000-0000-0000-000000000004', 'f0000000-0000-0000-0000-000000000020');
insert into public.material_requirements (material_id, requirement_type, is_mandatory, min_score)
values ('f0000000-0000-0000-0000-000000000004', 'competency_assessment', true, 75.00);

select results_eq(
  $$select status, percentage from public.trainee_material_progress
    where trainee_id = (select id from public.trainees where profile_id = 'f0000000-0000-0000-0000-000000000011')
      and material_id = 'f0000000-0000-0000-0000-000000000004'$$,
  $$values ('in_progress'::material_status, 50.00::numeric)$$,
  'Adding second mandatory requirement triggers recompute: 1 of 2 satisfied -> in_progress 50%'
);

-- Edge Case 4: RPC Lockdown
-- Authenticated trainee calling recalculate_material_progress directly must fail
set local role authenticated;
set local "request.jwt.claim.sub" = 'f0000000-0000-0000-0000-000000000011';

select throws_ok(
  $$select public.recalculate_material_progress('f0000000-0000-0000-0000-000000000011'::uuid, 'f0000000-0000-0000-0000-000000000004'::uuid)$$,
  '42501',
  null,
  'Trainee cannot execute recalculate_material_progress directly (RPC revoked)'
);

select * from finish();
rollback;
