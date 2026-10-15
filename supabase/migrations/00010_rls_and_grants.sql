-- ============================================================================
-- 00010: Permissions, Grants, RLS Helpers, and Row Level Security Policies
-- ============================================================================

-- 1. Zero-Anon Access Lockdown
revoke all on all tables in schema public from anon, public;
revoke all on all routines in schema public from anon, public;
revoke all on all sequences in schema public from anon, public;

-- 2. STABLE SECURITY DEFINER Helpers
create or replace function current_role_name()
returns user_role
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function current_trainer_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.trainers where profile_id = auth.uid();
$$;

create or replace function current_trainee_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.trainees where profile_id = auth.uid();
$$;

create or replace function is_my_trainee(p_trainee_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trainer_trainee_assignments
    where trainer_id = current_trainer_id()
      and trainee_id = p_trainee_id
      and status = 'active'
  );
$$;

create or replace function is_historical_trainee(p_trainee_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.trainer_trainee_assignments
    where trainer_id = current_trainer_id()
      and trainee_id = p_trainee_id
  );
$$;

grant execute on function current_role_name() to authenticated;
grant execute on function current_trainer_id() to authenticated;
grant execute on function current_trainee_id() to authenticated;
grant execute on function is_my_trainee(uuid) to authenticated;
grant execute on function is_historical_trainee(uuid) to authenticated;
grant execute on function admin_set_user_role(uuid, user_role) to authenticated;

-- 3. Explicit Grants to Authenticated
grant select on levels, training_tracks, training_units, training_materials,
  material_requirements, competencies, material_competencies, quizzes,
  quiz_questions, progression_rules, progression_requirements to authenticated;

grant select on profiles to authenticated;
grant update (full_name, phone) on profiles to authenticated;

grant select on quiz_question_options to authenticated;

grant select, insert, update, delete on
  trainers, trainees, trainer_trainee_assignments, training_plans,
  training_sessions, observations, observation_scores, competency_assessments,
  quiz_attempts, verification_records, trainer_followups,
  trainee_material_progress to authenticated;

-- 4. Enable RLS on All Tables
alter table profiles enable row level security;
alter table trainers enable row level security;
alter table trainees enable row level security;
alter table trainer_trainee_assignments enable row level security;
alter table levels enable row level security;
alter table training_tracks enable row level security;
alter table training_units enable row level security;
alter table training_materials enable row level security;
alter table material_requirements enable row level security;
alter table competencies enable row level security;
alter table material_competencies enable row level security;
alter table training_plans enable row level security;
alter table training_sessions enable row level security;
alter table observations enable row level security;
alter table observation_scores enable row level security;
alter table competency_assessments enable row level security;
alter table verification_records enable row level security;
alter table trainer_followups enable row level security;
alter table quizzes enable row level security;
alter table quiz_questions enable row level security;
alter table quiz_question_options enable row level security;
alter table quiz_attempts enable row level security;
alter table trainee_material_progress enable row level security;
alter table progression_rules enable row level security;
alter table progression_requirements enable row level security;

-- ============================================================================
-- 5. RLS Policies
-- ============================================================================

-- PROFILES
create policy profiles_select_authenticated on profiles
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or id = auth.uid()
    or ((select current_role_name()) = 'trainer' and id in (
      select profile_id from trainees where is_historical_trainee(id)
    ))
    or ((select current_role_name()) = 'trainee' and id in (
      select profile_id from trainers where id in (
        select trainer_id from trainer_trainee_assignments
        where trainee_id = current_trainee_id() and status = 'active'
      )
    ))
  );

create policy profiles_update_own on profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy profiles_admin_update on profiles
  for update to authenticated
  using ((select current_role_name()) = 'admin')
  with check ((select current_role_name()) = 'admin');

-- TRAINERS
create policy trainers_select_authenticated on trainers
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor', 'trainer')
    or id in (
      select trainer_id from trainer_trainee_assignments
      where trainee_id = current_trainee_id() and status = 'active'
    )
  );

create policy trainers_admin_all on trainers
  for all to authenticated
  using ((select current_role_name()) = 'admin')
  with check ((select current_role_name()) = 'admin');

-- TRAINEES
create policy trainees_select_authenticated on trainees
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or profile_id = auth.uid()
    or ((select current_role_name()) = 'trainer' and is_historical_trainee(id))
  );

create policy trainees_admin_all on trainees
  for all to authenticated
  using ((select current_role_name()) = 'admin')
  with check ((select current_role_name()) = 'admin');

-- TRAINER_TRAINEE_ASSIGNMENTS
create policy assignments_select_authenticated on trainer_trainee_assignments
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_trainee_id()
  );

create policy assignments_admin_all on trainer_trainee_assignments
  for all to authenticated
  using ((select current_role_name()) = 'admin')
  with check ((select current_role_name()) = 'admin');

-- MASTER CURRICULUM TABLES (Read for all authenticated, write for admin)
create policy levels_select on levels for select to authenticated using (true);
create policy levels_admin_all on levels for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy tracks_select on training_tracks for select to authenticated using (true);
create policy tracks_admin_all on training_tracks for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy units_select on training_units for select to authenticated using (true);
create policy units_admin_all on training_units for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy materials_select on training_materials for select to authenticated using (true);
create policy materials_admin_all on training_materials for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy reqs_select on material_requirements for select to authenticated using (true);
create policy reqs_admin_all on material_requirements for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy comps_select on competencies for select to authenticated using (true);
create policy comps_admin_all on competencies for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy matcomps_select on material_competencies for select to authenticated using (true);
create policy matcomps_admin_all on material_competencies for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy quizzes_select on quizzes for select to authenticated using (true);
create policy quizzes_admin_all on quizzes for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy questions_select on quiz_questions for select to authenticated using (true);
create policy questions_admin_all on quiz_questions for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

-- QUIZ QUESTION OPTIONS (Staff only can view to protect answer keys from trainees)
create policy options_select_staff on quiz_question_options
  for select to authenticated
  using ((select current_role_name()) in ('admin', 'supervisor', 'trainer'));

create policy options_admin_all on quiz_question_options
  for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

-- PROGRESSION RULES & REQUIREMENTS
create policy prog_rules_select on progression_rules for select to authenticated using (true);
create policy prog_rules_admin_all on progression_rules for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

create policy prog_reqs_select on progression_requirements for select to authenticated using (true);
create policy prog_reqs_admin_all on progression_requirements for all to authenticated
  using ((select current_role_name()) = 'admin') with check ((select current_role_name()) = 'admin');

-- TRAINING PLANS
create policy plans_select on training_plans
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_trainee_id()
    or is_historical_trainee(trainee_id)
  );

create policy plans_insert on training_plans
  for insert to authenticated
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy plans_update on training_plans
  for update to authenticated
  using (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  )
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy plans_delete on training_plans
  for delete to authenticated
  using ((select current_role_name()) = 'admin');

-- TRAINING SESSIONS
create policy sessions_select on training_sessions
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_trainee_id()
    or is_historical_trainee(trainee_id)
  );

create policy sessions_insert on training_sessions
  for insert to authenticated
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy sessions_update on training_sessions
  for update to authenticated
  using (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  )
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy sessions_delete on training_sessions
  for delete to authenticated
  using ((select current_role_name()) = 'admin');

-- OBSERVATIONS
create policy observations_select on observations
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_trainee_id()
    or is_historical_trainee(trainee_id)
  );

create policy observations_insert on observations
  for insert to authenticated
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy observations_update on observations
  for update to authenticated
  using (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and status = 'draft'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  )
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy observations_delete on observations
  for delete to authenticated
  using (
    (select current_role_name()) = 'trainer'
    and status = 'draft'
    and trainer_id = current_trainer_id()
    and is_my_trainee(trainee_id)
  );

-- OBSERVATION SCORES
create policy obsscores_select on observation_scores
  for select to authenticated
  using (
    exists (
      select 1 from observations o
      where o.id = observation_scores.observation_id
    )
  );

create policy obsscores_insert on observation_scores
  for insert to authenticated
  with check (
    exists (
      select 1 from observations o
      where o.id = observation_scores.observation_id
        and (
          (select current_role_name()) = 'admin'
          or (
            o.trainer_id = current_trainer_id()
            and o.status = 'draft'
            and is_my_trainee(o.trainee_id)
          )
        )
    )
  );

create policy obsscores_update on observation_scores
  for update to authenticated
  using (
    exists (
      select 1 from observations o
      where o.id = observation_scores.observation_id
        and (
          (select current_role_name()) = 'admin'
          or (
            o.trainer_id = current_trainer_id()
            and o.status = 'draft'
            and is_my_trainee(o.trainee_id)
          )
        )
    )
  );

create policy obsscores_delete on observation_scores
  for delete to authenticated
  using (
    exists (
      select 1 from observations o
      where o.id = observation_scores.observation_id
        and o.trainer_id = current_trainer_id()
        and o.status = 'draft'
        and is_my_trainee(o.trainee_id)
    )
  );

-- COMPETENCY ASSESSMENTS (Append-only)
create policy assessments_select on competency_assessments
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_trainee_id()
    or is_historical_trainee(trainee_id)
  );

create policy assessments_insert on competency_assessments
  for insert to authenticated
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

-- QUIZ ATTEMPTS (Append-only; Trainee cannot direct-insert)
create policy quiz_attempts_select on quiz_attempts
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainee_id = current_trainee_id()
    or trainer_id = current_trainer_id()
    or is_historical_trainee(trainee_id)
  );

create policy quiz_attempts_insert on quiz_attempts
  for insert to authenticated
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

-- VERIFICATION RECORDS (Append-only)
create policy verifications_select on verification_records
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_trainee_id()
    or is_historical_trainee(trainee_id)
  );

create policy verifications_insert on verification_records
  for insert to authenticated
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

-- TRAINER FOLLOWUPS
create policy followups_select on trainer_followups
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainer_id = current_trainer_id()
    or trainee_id = current_trainee_id()
    or is_historical_trainee(trainee_id)
  );

create policy followups_insert on trainer_followups
  for insert to authenticated
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy followups_update on trainer_followups
  for update to authenticated
  using (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  )
  with check (
    (select current_role_name()) = 'admin'
    or (
      (select current_role_name()) = 'trainer'
      and trainer_id = current_trainer_id()
      and is_my_trainee(trainee_id)
    )
  );

create policy followups_delete on trainer_followups
  for delete to authenticated
  using ((select current_role_name()) = 'admin');

-- TRAINEE MATERIAL PROGRESS (Read-only for all, write solely via SECURITY DEFINER function)
create policy progress_select on trainee_material_progress
  for select to authenticated
  using (
    (select current_role_name()) in ('admin', 'supervisor')
    or trainee_id = current_trainee_id()
    or trainer_id = current_trainer_id()
    or is_historical_trainee(trainee_id)
  );
