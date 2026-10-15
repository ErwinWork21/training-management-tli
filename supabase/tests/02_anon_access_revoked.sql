-- ============================================================================
-- pgTAP Test 02: Zero Anon Access Lockdown
-- Tests Finding 3: Anon access must be completely revoked across tables and views
-- ============================================================================

begin;
select plan(6);

-- Switch to anon role
set local role anon;

select throws_ok(
  'select * from public.profiles',
  '42501',
  null,
  'Anon cannot select from profiles'
);

select throws_ok(
  'select * from public.trainees',
  '42501',
  null,
  'Anon cannot select from trainees'
);

select throws_ok(
  'select * from public.training_materials',
  '42501',
  null,
  'Anon cannot select from training_materials'
);

select throws_ok(
  'select * from public.v_session_monitoring',
  '42501',
  null,
  'Anon cannot select from v_session_monitoring view'
);

select throws_ok(
  'select * from public.v_pending_verification',
  '42501',
  null,
  'Anon cannot select from v_pending_verification view'
);

select throws_ok(
  'select * from public.v_trainees_requiring_attention',
  '42501',
  null,
  'Anon cannot select from v_trainees_requiring_attention view'
);

select * from finish();
rollback;
