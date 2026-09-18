-- ============================================================================
-- 00012: Row Level Security
--
-- Model:
--   admin       - full access everywhere
--   supervisor  - read-only everywhere (operational + master data)
--   trainer     - full CRUD on evidence for their own assigned trainees;
--                 read-only on master data
--   trainee     - read-only on their own records; read-only on master data
--
-- Helper functions are SECURITY DEFINER + STABLE so they can be used inside
-- policies without triggering RLS recursion on `profiles`.
-- ============================================================================

create or replace function current_role_name()
returns user_role
language sql stable security definer set search_path = public
as $$
  select role from profiles where id = auth.uid();
$$;

create or replace function current_trainer_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select id from trainers where profile_id = auth.uid();
$$;

create or replace function current_teacher_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select id from teachers where profile_id = auth.uid();
$$;

-- Is this trainee currently (or ever) assigned to the calling trainer?
create or replace function is_my_trainee(p_trainee_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from trainer_trainee_assignments
    where trainer_id = current_trainer_id() and trainee_id = p_trainee_id
  );
$$;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
alter table profiles enable row level security;

create policy profiles_select_own_or_staff on profiles for select
  using (
    id = auth.uid()
    or current_role_name() in ('admin', 'supervisor', 'trainer')
  );

create policy profiles_update_own_basic on profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

create policy profiles_admin_all on profiles for all
  using (current_role_name() = 'admin')
  with check (current_role_name() = 'admin');

-- ---------------------------------------------------------------------------
-- Master data: levels, tracks, units, materials, requirements, competencies,
-- material_competencies, progression_rules, progression_requirements.
-- Everyone authenticated can read; only admin can write.
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'levels', 'training_tracks', 'training_units', 'training_materials',
    'material_requirements', 'competencies', 'material_competencies',
    'progression_rules', 'progression_requirements', 'quizzes',
    'quiz_questions', 'quiz_question_options'
  ]
  loop
    execute format('alter table %I enable row level security;', t);
    execute format(
      'create policy %I_read_all on %I for select using (auth.uid() is not null);',
      t, t
    );
    execute format(
      'create policy %I_admin_write on %I for all using (current_role_name() = ''admin'') with check (current_role_name() = ''admin'');',
      t, t
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- trainers / teachers
-- ---------------------------------------------------------------------------
alter table trainers enable row level security;
create policy trainers_read_all on trainers for select using (auth.uid() is not null);
create policy trainers_admin_write on trainers for all
  using (current_role_name() = 'admin') with check (current_role_name() = 'admin');

alter table teachers enable row level security;
create policy teachers_select on teachers for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or (current_role_name() = 'trainer' and is_my_trainee(id))
    or profile_id = auth.uid()
  );
create policy teachers_admin_write on teachers for all
  using (current_role_name() = 'admin') with check (current_role_name() = 'admin');

-- ---------------------------------------------------------------------------
-- trainer_trainee_assignments
-- ---------------------------------------------------------------------------
alter table trainer_trainee_assignments enable row level security;
create policy assignments_select on trainer_trainee_assignments for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy assignments_admin_write on trainer_trainee_assignments for all
  using (current_role_name() = 'admin') with check (current_role_name() = 'admin');

-- ---------------------------------------------------------------------------
-- Generic pattern for trainer-owned evidence tables:
--   training_plans, training_sessions, observations, observation_scores,
--   competency_assessments, quiz_attempts, verification_records,
--   trainer_followups
--
-- admin      : full access
-- supervisor : read-only
-- trainer    : full access to rows for their own assigned trainees
-- trainee    : read-only on their own rows
-- ---------------------------------------------------------------------------

-- training_plans
alter table training_plans enable row level security;
create policy plans_select on training_plans for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy plans_trainer_write on training_plans for all
  using (current_role_name() = 'admin' or trainer_id = current_trainer_id())
  with check (current_role_name() = 'admin' or trainer_id = current_trainer_id());

-- training_sessions
alter table training_sessions enable row level security;
create policy sessions_select on training_sessions for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy sessions_trainer_write on training_sessions for all
  using (current_role_name() = 'admin' or trainer_id = current_trainer_id())
  with check (current_role_name() = 'admin' or trainer_id = current_trainer_id());

-- observations
alter table observations enable row level security;
create policy observations_select on observations for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy observations_trainer_write on observations for all
  using (current_role_name() = 'admin' or trainer_id = current_trainer_id())
  with check (current_role_name() = 'admin' or trainer_id = current_trainer_id());

-- observation_scores (scoped via parent observation)
alter table observation_scores enable row level security;
create policy obs_scores_select on observation_scores for select
  using (
    exists (
      select 1 from observations o where o.id = observation_id
      and (
        current_role_name() in ('admin', 'supervisor')
        or o.trainer_id = current_trainer_id()
        or o.trainee_id = current_teacher_id()
      )
    )
  );
create policy obs_scores_trainer_write on observation_scores for all
  using (
    current_role_name() = 'admin'
    or exists (select 1 from observations o where o.id = observation_id and o.trainer_id = current_trainer_id())
  )
  with check (
    current_role_name() = 'admin'
    or exists (select 1 from observations o where o.id = observation_id and o.trainer_id = current_trainer_id())
  );

-- competency_assessments (insert-only history: no update/delete policy for trainers)
alter table competency_assessments enable row level security;
create policy assessments_select on competency_assessments for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy assessments_trainer_insert on competency_assessments for insert
  with check (current_role_name() = 'admin' or trainer_id = current_trainer_id());
create policy assessments_admin_modify on competency_assessments for update
  using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy assessments_admin_delete on competency_assessments for delete
  using (current_role_name() = 'admin');

-- quiz_attempts (insert-only history)
alter table quiz_attempts enable row level security;
create policy quiz_attempts_select on quiz_attempts for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy quiz_attempts_trainer_insert on quiz_attempts for insert
  with check (current_role_name() = 'admin' or trainer_id = current_trainer_id() or trainee_id = current_teacher_id());

-- verification_records (insert-only history)
alter table verification_records enable row level security;
create policy verification_select on verification_records for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy verification_trainer_insert on verification_records for insert
  with check (current_role_name() = 'admin' or trainer_id = current_trainer_id());

-- trainer_followups
alter table trainer_followups enable row level security;
create policy followups_select on trainer_followups for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
  );
create policy followups_trainer_write on trainer_followups for all
  using (current_role_name() = 'admin' or trainer_id = current_trainer_id())
  with check (current_role_name() = 'admin' or trainer_id = current_trainer_id());

-- ---------------------------------------------------------------------------
-- trainee_material_progress (backend-computed; no direct client writes)
-- ---------------------------------------------------------------------------
alter table trainee_material_progress enable row level security;
create policy progress_select on trainee_material_progress for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_teacher_id()
    or exists (select 1 from teachers t where t.id = trainee_id and is_my_trainee(t.id))
  );
-- No insert/update/delete policy for anyone but admin: rows are written only
-- by recalculate_material_progress(), which runs as SECURITY DEFINER and so
-- bypasses RLS entirely.
create policy progress_admin_write on trainee_material_progress for all
  using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
