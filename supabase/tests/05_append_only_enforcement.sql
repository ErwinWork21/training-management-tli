-- ============================================================================
-- pgTAP Test 05: Append-Only and Immutability Enforcement
-- Tests Findings 9 & 10: Immutable tables cannot be updated or deleted even by admin
-- ============================================================================

begin;
select plan(4);

-- Setup test entities
insert into public.levels (id, name, code, sequence_order) values ('e0000000-0000-0000-0000-000000000001', 'AppLevel', 'APPLEV', 1) on conflict do nothing;
insert into public.training_tracks (id, level_id, name, code, sequence_order) values ('e0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'AppTrack', 'APPTRK', 1) on conflict do nothing;
insert into public.training_units (id, track_id, name, code, sequence_order) values ('e0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000002', 'AppUnit', 'APPUNT', 1) on conflict do nothing;
insert into public.training_materials (id, unit_id, title, sequence_order) values ('e0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000003', 'AppMat', 1) on conflict do nothing;
insert into public.competencies (id, name) values ('e0000000-0000-0000-0000-000000000005', 'AppComp') on conflict do nothing;

insert into auth.users (id, email, raw_app_meta_data) values
  ('e0000000-0000-0000-0000-000000000010', 'admin_app@example.com', '{"role":"admin"}'::jsonb),
  ('e0000000-0000-0000-0000-000000000011', 'trainer_app@example.com', '{"role":"trainer"}'::jsonb),
  ('e0000000-0000-0000-0000-000000000012', 'trainee_app@example.com', '{"role":"trainee"}'::jsonb)
on conflict do nothing;

-- Create records
insert into public.competency_assessments (id, trainee_id, trainer_id, competency_id, material_id, score)
values (
  'e0000000-0000-0000-0000-000000000020',
  (select id from public.trainees where profile_id = 'e0000000-0000-0000-0000-000000000012'),
  (select id from public.trainers where profile_id = 'e0000000-0000-0000-0000-000000000011'),
  'e0000000-0000-0000-0000-000000000005',
  'e0000000-0000-0000-0000-000000000004',
  85.00
);

insert into public.verification_records (id, trainee_id, trainer_id, material_id, status)
values (
  'e0000000-0000-0000-0000-000000000021',
  (select id from public.trainees where profile_id = 'e0000000-0000-0000-0000-000000000012'),
  (select id from public.trainers where profile_id = 'e0000000-0000-0000-0000-000000000011'),
  'e0000000-0000-0000-0000-000000000004',
  'verified'
);

insert into public.observations (id, trainee_id, trainer_id, material_id, overall_score, status)
values (
  'e0000000-0000-0000-0000-000000000022',
  (select id from public.trainees where profile_id = 'e0000000-0000-0000-0000-000000000012'),
  (select id from public.trainers where profile_id = 'e0000000-0000-0000-0000-000000000011'),
  'e0000000-0000-0000-0000-000000000004',
  90.00,
  'submitted'
);

-- Connect as authenticated admin
set local role authenticated;
set local "request.jwt.claim.sub" = 'e0000000-0000-0000-0000-000000000010';

-- 1. Attempt UPDATE on competency_assessments must raise exception
select throws_ok(
  $$update public.competency_assessments set score = 95.00 where id = 'e0000000-0000-0000-0000-000000000020'$$,
  '42501',
  null,
  'Admin cannot update competency_assessments (append-only trigger)'
);

-- 2. Attempt DELETE on competency_assessments must raise exception
select throws_ok(
  $$delete from public.competency_assessments where id = 'e0000000-0000-0000-0000-000000000020'$$,
  '42501',
  null,
  'Admin cannot delete competency_assessments (append-only trigger)'
);

-- 3. Attempt UPDATE on verification_records must raise exception
select throws_ok(
  $$update public.verification_records set status = 'needs_review' where id = 'e0000000-0000-0000-0000-000000000021'$$,
  '42501',
  null,
  'Admin cannot update verification_records (append-only trigger)'
);

-- 4. Attempt UPDATE on submitted observation must raise exception
select throws_ok(
  $$update public.observations set overall_score = 99.00 where id = 'e0000000-0000-0000-0000-000000000022'$$,
  '42501',
  null,
  'Admin cannot modify submitted observations (lock trigger)'
);

select * from finish();
rollback;
