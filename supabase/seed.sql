-- ============================================================================
-- The Lab — Idempotent Database Seed Script
-- Safe for repeated runs via: supabase db reset / psql < seed.sql
-- ============================================================================

do $$
declare
  v_kinder_id uuid;
  v_junior_id uuid;
  v_coder_id  uuid;

  v_track_id  uuid;
  v_unit_id   uuid;
  v_mat_id    uuid;
  v_first_mat_id uuid;

  v_comp_class_id uuid;
  v_comp_delivery_id uuid;
  v_comp_engage_id uuid;
  v_comp_safety_id uuid;

  v_quiz_id   uuid;
  v_q1_id     uuid;
  v_q2_id     uuid;
begin
  -- --------------------------------------------------------------------------
  -- 1. Levels (Kinder, Junior, Coder)
  -- --------------------------------------------------------------------------
  insert into public.levels (name, code, sequence_order, description)
  values ('Kinder', 'KINDER', 1, 'Kinder level for early childhood training')
  on conflict (code) do update set name = excluded.name
  returning id into v_kinder_id;

  insert into public.levels (name, code, sequence_order, description)
  values ('Junior', 'JUNIOR', 2, 'Junior level for primary school age training')
  on conflict (code) do update set name = excluded.name
  returning id into v_junior_id;

  insert into public.levels (name, code, sequence_order, description)
  values ('Coder', 'CODER', 3, 'Coder level — configurable curriculum')
  on conflict (code) do update set name = excluded.name
  returning id into v_coder_id;

  -- --------------------------------------------------------------------------
  -- 2. Training Tracks (Foundation, Core)
  -- --------------------------------------------------------------------------
  -- Kinder Foundation
  insert into public.training_tracks (level_id, name, code, sequence_order, description)
  values (v_kinder_id, 'Foundation', 'FOUNDATION', 1, 'Kinder Foundation track')
  on conflict (level_id, code) do update set name = excluded.name
  returning id into v_track_id;

  -- Kinder Foundation Terms 1 & 2
  for term_no in 1..2 loop
    insert into public.training_units (track_id, name, code, sequence_order, description)
    values (v_track_id, 'Term ' || term_no, 'TERM_' || term_no, term_no, 'Kinder Foundation Term ' || term_no)
    on conflict (track_id, code) do update set name = excluded.name
    returning id into v_unit_id;

    for mat_no in 1..10 loop
      select id into v_mat_id
      from public.training_materials
      where unit_id = v_unit_id and sequence_order = mat_no;

      if v_mat_id is null then
        insert into public.training_materials (unit_id, title, description, sequence_order)
        values (
          v_unit_id,
          'Kinder Foundation Term ' || term_no || ' - Material ' || mat_no,
          'Core curriculum training material ' || mat_no,
          mat_no
        )
        returning id into v_mat_id;
      end if;

      if v_first_mat_id is null then
        v_first_mat_id := v_mat_id;
      end if;
    end loop;
  end loop;

  -- Kinder Core
  insert into public.training_tracks (level_id, name, code, sequence_order, description)
  values (v_kinder_id, 'Core', 'CORE', 2, 'Kinder Core track')
  on conflict (level_id, code) do update set name = excluded.name
  returning id into v_track_id;

  for term_no in 1..4 loop
    insert into public.training_units (track_id, name, code, sequence_order, description)
    values (v_track_id, 'Term ' || term_no, 'TERM_' || term_no, term_no, 'Kinder Core Term ' || term_no)
    on conflict (track_id, code) do update set name = excluded.name
    returning id into v_unit_id;

    for mat_no in 1..10 loop
      if not exists (select 1 from public.training_materials where unit_id = v_unit_id and sequence_order = mat_no) then
        insert into public.training_materials (unit_id, title, description, sequence_order)
        values (
          v_unit_id,
          'Kinder Core Term ' || term_no || ' - Material ' || mat_no,
          'Core curriculum training material ' || mat_no,
          mat_no
        );
      end if;
    end loop;
  end loop;

  -- Junior Foundation
  insert into public.training_tracks (level_id, name, code, sequence_order, description)
  values (v_junior_id, 'Foundation', 'FOUNDATION', 1, 'Junior Foundation track')
  on conflict (level_id, code) do update set name = excluded.name
  returning id into v_track_id;

  for term_no in 1..2 loop
    insert into public.training_units (track_id, name, code, sequence_order, description)
    values (v_track_id, 'Term ' || term_no, 'TERM_' || term_no, term_no, 'Junior Foundation Term ' || term_no)
    on conflict (track_id, code) do update set name = excluded.name
    returning id into v_unit_id;

    for mat_no in 1..10 loop
      if not exists (select 1 from public.training_materials where unit_id = v_unit_id and sequence_order = mat_no) then
        insert into public.training_materials (unit_id, title, description, sequence_order)
        values (
          v_unit_id,
          'Junior Foundation Term ' || term_no || ' - Material ' || mat_no,
          'Core curriculum training material ' || mat_no,
          mat_no
        );
      end if;
    end loop;
  end loop;

  -- --------------------------------------------------------------------------
  -- 3. Standard Competencies
  -- --------------------------------------------------------------------------
  insert into public.competencies (name, category, description, expected_level)
  values ('Classroom Management', 'Pedagogy', 'Ability to maintain engagement and structured classroom flow', 'Proficient')
  on conflict (name) do update set category = excluded.category
  returning id into v_comp_class_id;

  insert into public.competencies (name, category, description, expected_level)
  values ('Lesson Delivery', 'Pedagogy', 'Clear instruction, pacing, and explanation of concepts', 'Proficient')
  on conflict (name) do update set category = excluded.category
  returning id into v_comp_delivery_id;

  insert into public.competencies (name, category, description, expected_level)
  values ('Student Engagement', 'Pedagogy', 'Interactive questioning and inclusive participation', 'Basic')
  on conflict (name) do update set category = excluded.category
  returning id into v_comp_engage_id;

  insert into public.competencies (name, category, description, expected_level)
  values ('Safety & Protocol', 'Operations', 'Adherence to safety procedures and classroom protocol', 'Proficient')
  on conflict (name) do update set category = excluded.category
  returning id into v_comp_safety_id;

  -- --------------------------------------------------------------------------
  -- 4. Sample Material Requirements & Competencies (Attached to first material)
  -- --------------------------------------------------------------------------
  if v_first_mat_id is not null then
    -- Requirements: Observation, Competency Assessment, Quiz
    insert into public.material_requirements (material_id, requirement_type, is_mandatory, min_score, notes)
    values
      (v_first_mat_id, 'observation', true, 70.00, 'Trainer classroom observation (min 70%)'),
      (v_first_mat_id, 'competency_assessment', true, 75.00, 'Assessment across linked core competencies (min 75%)'),
      (v_first_mat_id, 'quiz', true, 80.00, 'Material understanding quiz (min 80%)')
    on conflict (material_id, requirement_type) do nothing;

    -- Link competencies to this material
    insert into public.material_competencies (material_id, competency_id)
    values
      (v_first_mat_id, v_comp_class_id),
      (v_first_mat_id, v_comp_delivery_id)
    on conflict (material_id, competency_id) do nothing;

    -- --------------------------------------------------------------------------
    -- 5. Sample Quiz, Questions, and Options
    -- --------------------------------------------------------------------------
    select id into v_quiz_id from public.quizzes where material_id = v_first_mat_id limit 1;
    if v_quiz_id is null then
      insert into public.quizzes (material_id, title, passing_score, is_active)
      values (v_first_mat_id, 'Kinder Foundation Term 1 Evaluation Quiz', 80.00, true)
      returning id into v_quiz_id;

      -- Question 1
      insert into public.quiz_questions (quiz_id, question_text, sequence_order)
      values (v_quiz_id, 'What is the primary focus of Term 1 introductory sessions?', 1)
      returning id into v_q1_id;

      insert into public.quiz_question_options (question_id, option_text, is_correct, sequence_order)
      values
        (v_q1_id, 'Building classroom rapport and establishing routines', true, 1),
        (v_q1_id, 'Grading advanced independent projects', false, 2),
        (v_q1_id, 'Testing algorithmic complexity without supervision', false, 3);

      -- Question 2
      insert into public.quiz_questions (quiz_id, question_text, sequence_order)
      values (v_quiz_id, 'When should constructive observation feedback be delivered to a trainee?', 2)
      returning id into v_q2_id;

      insert into public.quiz_question_options (question_id, option_text, is_correct, sequence_order)
      values
        (v_q2_id, 'Promptly during the post-session debrief', true, 1),
        (v_q2_id, 'At the end of the academic year only', false, 2),
        (v_q2_id, 'Never, trainees should self-reflect exclusively', false, 3);
    end if;
  end if;
end $$;
