-- ============================================================================
-- pgTAP Test 07: Security Invoker Views and Row Isolation
-- Tests Finding 11: Views with security_invoker = true strictly honor RLS
-- ============================================================================

begin;
select plan(3);

-- Setup curriculum
insert into public.levels (id, name, code, sequence_order) values ('g0000000-0000-0000-0000-000000000001', 'ViewLevel', 'VIEWLEV', 1) on conflict do nothing;
insert into public.training_tracks (id, level_id, name, code, sequence_order) values ('g0000000-0000-0000-0000-000000000002', 'g0000000-0000-0000-0000-000000000001', 'ViewTrack', 'VIEWTRK', 1) on conflict do nothing;
insert into public.training_units (id, track_id, name, code, sequence_order) values ('g0000000-0000-0000-0000-000000000003', 'g0000000-0000-0000-0000-000000000002', 'ViewUnit', 'VIEWUNT', 1) on conflict do nothing;
insert into public.training_materials (id, unit_id, title, sequence_order) values ('g0000000-0000-0000-0000-000000000004', 'g0000000-0000-0000-0000-000000000003', 'ViewMat', 1) on conflict do nothing;

-- Users
insert into auth.users (id, email, raw_app_meta_data) values
  ('g0000000-0000-0000-0000-000000000010', 'trainer_view@example.com', '{"role":"trainer"}'::jsonb),
  ('g0000000-0000-0000-0000-000000000011', 'trainee_view1@example.com', '{"role":"trainee"}'::jsonb),
  ('g0000000-0000-0000-0000-000000000012', 'trainee_view2@example.com', '{"role":"trainee"}'::jsonb)
on conflict do nothing;

-- Insert sessions: 1 session for Trainee 1, 1 session for Trainee 2
insert into public.training_sessions (trainer_id, trainee_id, material_id, planned_date, status)
values
  (
    (select id from public.trainers where profile_id = 'g0000000-0000-0000-0000-000000000010'),
    (select id from public.trainees where profile_id = 'g0000000-0000-0000-0000-000000000011'),
    'g0000000-0000-0000-0000-000000000004',
    current_date,
    'planned'
  ),
  (
    (select id from public.trainers where profile_id = 'g0000000-0000-0000-0000-000000000010'),
    (select id from public.trainees where profile_id = 'g0000000-0000-0000-0000-000000000012'),
    'g0000000-0000-0000-0000-000000000004',
    current_date,
    'planned'
  );

-- Connect as Trainee 1
set local role authenticated;
set local "request.jwt.claim.sub" = 'g0000000-0000-0000-0000-000000000011';

-- 1. Trainee 1 querying v_session_monitoring should see EXACTLY 1 row (their own)
select is(
  (select count(*) from public.v_session_monitoring)::int,
  1,
  'Trainee 1 can only see their own row in v_session_monitoring'
);

select results_eq(
  $$select trainee_id from public.v_session_monitoring$$,
  $$(select id from public.trainees where profile_id = 'g0000000-0000-0000-0000-000000000011')$$,
  'Row in v_session_monitoring corresponds to Trainee 1'
);

-- Connect as Trainee 2
set local "request.jwt.claim.sub" = 'g0000000-0000-0000-0000-000000000012';

select is(
  (select count(*) from public.v_session_monitoring)::int,
  1,
  'Trainee 2 can only see their own row in v_session_monitoring'
);

select * from finish();
rollback;
