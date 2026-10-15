-- ============================================================================
-- pgTAP Test 03: Quiz Security and Attempt Protection
-- Tests Finding 4: Trainee cannot self-pass or read correct option answers
-- ============================================================================

begin;
select plan(3);

-- Setup test material, quiz, questions, and options
insert into public.levels (id, name, code, sequence_order)
values ('c0000000-0000-0000-0000-000000000001', 'TestLevel', 'TESTLEV', 1)
on conflict do nothing;

insert into public.training_tracks (id, level_id, name, code, sequence_order)
values ('c0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'TestTrack', 'TTRK', 1)
on conflict do nothing;

insert into public.training_units (id, track_id, name, code, sequence_order)
values ('c0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000002', 'TestUnit', 'TUNT', 1)
on conflict do nothing;

insert into public.training_materials (id, unit_id, title, sequence_order)
values ('c0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000003', 'QuizTestMat', 1)
on conflict do nothing;

insert into public.quizzes (id, material_id, title, passing_score)
values ('c0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000004', 'Secure Quiz', 75.00)
on conflict do nothing;

insert into public.quiz_questions (id, quiz_id, question_text)
values ('c0000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000005', 'What is 2+2?')
on conflict do nothing;

insert into public.quiz_question_options (id, question_id, option_text, is_correct)
values
  ('c0000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000006', '4', true),
  ('c0000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000006', '5', false)
on conflict do nothing;

-- Create trainee user
insert into auth.users (id, email, raw_app_meta_data)
values ('c0000000-0000-0000-0000-000000000010', 'student@example.com', '{"role":"trainee"}'::jsonb)
on conflict do nothing;

-- Switch to trainee context
set local role authenticated;
set local "request.jwt.claim.sub" = 'c0000000-0000-0000-0000-000000000010';

-- 1. Trainee attempting to read quiz_question_options must see 0 rows
select is(
  (select count(*) from public.quiz_question_options where question_id = 'c0000000-0000-0000-0000-000000000006')::int,
  0,
  'Trainee must NOT be able to select question options or correct answer keys'
);

-- 2. Trainee can see question text
select is(
  (select count(*) from public.quiz_questions where quiz_id = 'c0000000-0000-0000-0000-000000000005')::int,
  1,
  'Trainee can view quiz question text'
);

-- 3. Trainee attempting to insert passing quiz attempt directly must fail RLS with check
select throws_ok(
  $$insert into public.quiz_attempts (quiz_id, trainee_id, score, passed)
    values (
      'c0000000-0000-0000-0000-000000000005',
      (select id from public.trainees where profile_id = 'c0000000-0000-0000-0000-000000000010'),
      100,
      true
    )$$,
  '42501',
  null,
  'Trainee cannot insert quiz_attempts directly (violates RLS check)'
);

select * from finish();
rollback;
