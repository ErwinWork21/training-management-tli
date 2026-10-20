-- ============================================================================
-- 00008: Progress Calculation Engine and Triggers
-- ============================================================================

-- Single source of truth for trainee progress per material
create table trainee_material_progress (
  id            uuid primary key default gen_random_uuid(),
  trainee_id    uuid not null references trainees(id) on delete cascade,
  material_id   uuid not null references training_materials(id) on delete cascade,
  status        material_status not null default 'not_started',
  percentage    numeric(5,2) not null default 0 check (percentage between 0 and 100),
  started_at    timestamptz,
  completed_at  timestamptz,
  verified_at   timestamptz,
  latest_score  numeric(5,2),
  trainer_id    uuid references trainers(id) on delete set null,
  notes         text,
  updated_at    timestamptz not null default now(),
  unique (trainee_id, material_id)
);

create index idx_progress_trainee on trainee_material_progress(trainee_id);
create index idx_progress_material on trainee_material_progress(material_id);
create index idx_progress_status on trainee_material_progress(status);

-- Core calculation function: evaluative, deterministic, and idempotent
create or replace function recalculate_material_progress(p_trainee_id uuid, p_material_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total_mandatory int := 0;
  v_satisfied_mandatory int := 0;
  v_req record;
  v_obs record;
  v_comp record;
  v_assess record;
  v_all_comps_satisfied boolean;
  v_quiz record;
  v_quiz_attempt record;
  v_all_quizzes_satisfied boolean;
  v_quiz_count int;
  v_comp_count int;

  v_latest_score numeric(5,2) := null;
  v_trainer_id uuid := null;
  v_latest_evidence_ts timestamptz := null;

  v_existing record;
  v_verification record;
  v_percentage numeric(5,2) := 0;
  v_status material_status := 'not_started';
  v_started_at timestamptz := null;
  v_completed_at timestamptz := null;
  v_verified_at timestamptz := null;
begin
  -- 1. Fetch current progress record if it exists
  select * into v_existing
  from public.trainee_material_progress
  where trainee_id = p_trainee_id and material_id = p_material_id;

  -- 2. Count total mandatory requirements
  select count(*) into v_total_mandatory
  from public.material_requirements
  where material_id = p_material_id and is_mandatory = true;

  -- If there are no mandatory requirements configured, progress cannot be computed
  if v_total_mandatory = 0 then
    if v_existing.id is not null then
      update public.trainee_material_progress
      set percentage = 0, status = 'not_started', completed_at = null, verified_at = null, updated_at = now()
      where id = v_existing.id;
    end if;
    return;
  end if;

  -- 3. Evaluate each mandatory requirement
  for v_req in
    select requirement_type, min_score
    from public.material_requirements
    where material_id = p_material_id and is_mandatory = true
  loop
    -- OBSERVATION
    if v_req.requirement_type = 'observation' then
      -- Get latest submitted observation
      select overall_score, observation_date, created_at, trainer_id into v_obs
      from public.observations
      where trainee_id = p_trainee_id
        and material_id = p_material_id
        and status = 'submitted'
      order by observation_date desc, created_at desc
      limit 1;

      if v_obs.overall_score is not null then
        v_latest_score := coalesce(v_latest_score, v_obs.overall_score);
        v_trainer_id := coalesce(v_trainer_id, v_obs.trainer_id);
        if v_latest_evidence_ts is null or v_obs.created_at > v_latest_evidence_ts then
          v_latest_evidence_ts := v_obs.created_at;
        end if;

        if v_req.min_score is null or v_obs.overall_score >= v_req.min_score then
          v_satisfied_mandatory := v_satisfied_mandatory + 1;
        end if;
      end if;

    -- COMPETENCY_ASSESSMENT
    elsif v_req.requirement_type = 'competency_assessment' then
      select count(*) into v_comp_count
      from public.material_competencies
      where material_id = p_material_id;

      if v_comp_count > 0 then
        v_all_comps_satisfied := true;

        for v_comp in
          select competency_id
          from public.material_competencies
          where material_id = p_material_id
        loop
          -- Find latest assessment for this specific competency
          select score, assessment_date, created_at, trainer_id into v_assess
          from public.competency_assessments
          where trainee_id = p_trainee_id
            and material_id = p_material_id
            and competency_id = v_comp.competency_id
          order by assessment_date desc, created_at desc
          limit 1;

          if v_assess.score is null or (v_req.min_score is not null and v_assess.score < v_req.min_score) then
            v_all_comps_satisfied := false;
          else
            v_latest_score := coalesce(v_latest_score, v_assess.score);
            v_trainer_id := coalesce(v_trainer_id, v_assess.trainer_id);
            if v_latest_evidence_ts is null or v_assess.created_at > v_latest_evidence_ts then
              v_latest_evidence_ts := v_assess.created_at;
            end if;
          end if;
        end loop;

        if v_all_comps_satisfied then
          v_satisfied_mandatory := v_satisfied_mandatory + 1;
        end if;
      end if;

    -- QUIZ
    elsif v_req.requirement_type = 'quiz' then
      select count(*) into v_quiz_count
      from public.quizzes
      where material_id = p_material_id and is_active = true;

      if v_quiz_count > 0 then
        v_all_quizzes_satisfied := true;

        for v_quiz in
          select id
          from public.quizzes
          where material_id = p_material_id and is_active = true
        loop
          -- Get latest quiz attempt
          select score, passed, attempted_at, trainer_id into v_quiz_attempt
          from public.quiz_attempts
          where quiz_id = v_quiz.id and trainee_id = p_trainee_id
          order by attempted_at desc
          limit 1;

          if v_quiz_attempt.score is null or not v_quiz_attempt.passed then
            v_all_quizzes_satisfied := false;
          else
            v_latest_score := coalesce(v_latest_score, v_quiz_attempt.score);
            v_trainer_id := coalesce(v_trainer_id, v_quiz_attempt.trainer_id);
            if v_latest_evidence_ts is null or v_quiz_attempt.attempted_at > v_latest_evidence_ts then
              v_latest_evidence_ts := v_quiz_attempt.attempted_at;
            end if;
          end if;
        end loop;

        if v_all_quizzes_satisfied then
          v_satisfied_mandatory := v_satisfied_mandatory + 1;
        end if;
      end if;
    end if;
  end loop;

  -- 4. Calculate percentage
  v_percentage := round((v_satisfied_mandatory::numeric / v_total_mandatory::numeric) * 100, 2);

  -- 5. Determine status and verification state
  if v_satisfied_mandatory = 0 then
    v_status := 'not_started';
    v_started_at := null;
    v_completed_at := null;
    v_verified_at := null;
  elsif v_satisfied_mandatory < v_total_mandatory then
    v_status := 'in_progress';
    v_started_at := coalesce(v_existing.started_at, now());
    v_completed_at := null;
    v_verified_at := null;
  else
    -- All mandatory requirements are met!
    v_started_at := coalesce(v_existing.started_at, now());
    v_completed_at := coalesce(v_existing.completed_at, now());

    -- Look up latest verification record
    select * into v_verification
    from public.verification_records
    where trainee_id = p_trainee_id and material_id = p_material_id
    order by verification_date desc, created_at desc
    limit 1;

    -- Verification is valid only if recorded AFTER or AT latest evidence
    if v_verification.id is not null
       and (v_latest_evidence_ts is null or v_verification.created_at >= v_latest_evidence_ts) then
      if v_verification.status = 'verified' then
        v_status := 'verified';
        v_verified_at := coalesce(v_existing.verified_at, now());
      elsif v_verification.status = 'needs_review' then
        v_status := 'needs_review';
        v_verified_at := null;
      else
        v_status := 'completed';
        v_verified_at := null;
      end if;
    else
      -- Stale verification or no verification
      v_status := 'completed';
      v_verified_at := null;
    end if;
  end if;

  -- 6. Upsert into trainee_material_progress
  insert into public.trainee_material_progress (
    trainee_id,
    material_id,
    status,
    percentage,
    started_at,
    completed_at,
    verified_at,
    latest_score,
    trainer_id,
    updated_at
  )
  values (
    p_trainee_id,
    p_material_id,
    v_status,
    v_percentage,
    v_started_at,
    v_completed_at,
    v_verified_at,
    v_latest_score,
    v_trainer_id,
    now()
  )
  on conflict (trainee_id, material_id) do update set
    status = excluded.status,
    percentage = excluded.percentage,
    started_at = excluded.started_at,
    completed_at = excluded.completed_at,
    verified_at = excluded.verified_at,
    latest_score = coalesce(excluded.latest_score, trainee_material_progress.latest_score),
    trainer_id = coalesce(excluded.trainer_id, trainee_material_progress.trainer_id),
    updated_at = now();
end;
$$;

-- Revoke execute from public/anon/authenticated to prevent arbitrary RPC calls
revoke execute on function recalculate_material_progress(uuid, uuid) from public, anon, authenticated;

-- ============================================================================
-- Evidence Triggers
-- ============================================================================

-- Observations
create or replace function trg_obs_recalculate()
returns trigger
language plpgsql
security definer
as $$
begin
  perform recalculate_material_progress(
    coalesce(new.trainee_id, old.trainee_id),
    coalesce(new.material_id, old.material_id)
  );
  return null;
end;
$$;

create trigger trg_obs_recalculate_progress
  after insert or update or delete on observations
  for each row execute function trg_obs_recalculate();

-- Competency Assessments
create or replace function trg_assess_recalculate()
returns trigger
language plpgsql
security definer
as $$
begin
  perform recalculate_material_progress(
    coalesce(new.trainee_id, old.trainee_id),
    coalesce(new.material_id, old.material_id)
  );
  return null;
end;
$$;

create trigger trg_assess_recalculate_progress
  after insert or update or delete on competency_assessments
  for each row execute function trg_assess_recalculate();

-- Quiz Attempts
create or replace function trg_quiz_recalculate()
returns trigger
language plpgsql
security definer
as $$
declare
  v_material_id uuid;
begin
  select material_id into v_material_id
  from public.quizzes
  where id = coalesce(new.quiz_id, old.quiz_id);

  if v_material_id is not null then
    perform recalculate_material_progress(
      coalesce(new.trainee_id, old.trainee_id),
      v_material_id
    );
  end if;
  return null;
end;
$$;

create trigger trg_quiz_recalculate_progress
  after insert or update or delete on quiz_attempts
  for each row execute function trg_quiz_recalculate();

-- Verification Records
create or replace function trg_verify_recalculate()
returns trigger
language plpgsql
security definer
as $$
begin
  perform recalculate_material_progress(
    coalesce(new.trainee_id, old.trainee_id),
    coalesce(new.material_id, old.material_id)
  );
  return null;
end;
$$;

create trigger trg_verify_recalculate_progress
  after insert or update or delete on verification_records
  for each row execute function trg_verify_recalculate();

-- ============================================================================
-- Configuration / Hierarchy Change Triggers
-- ============================================================================

-- Material Requirements changed
create or replace function trg_req_recalculate()
returns trigger
language plpgsql
security definer
as $$
declare
  v_material_id uuid := coalesce(new.material_id, old.material_id);
  v_trainee record;
begin
  for v_trainee in
    select distinct trainee_id
    from public.trainee_material_progress
    where material_id = v_material_id
  loop
    perform recalculate_material_progress(v_trainee.trainee_id, v_material_id);
  end loop;
  return null;
end;
$$;

create trigger trg_req_recalculate_progress
  after insert or update or delete on material_requirements
  for each row execute function trg_req_recalculate();

-- Material Competencies changed
create or replace function trg_matcomp_recalculate()
returns trigger
language plpgsql
security definer
as $$
declare
  v_material_id uuid := coalesce(new.material_id, old.material_id);
  v_trainee record;
begin
  for v_trainee in
    select distinct trainee_id
    from public.trainee_material_progress
    where material_id = v_material_id
  loop
    perform recalculate_material_progress(v_trainee.trainee_id, v_material_id);
  end loop;
  return null;
end;
$$;

create trigger trg_matcomp_recalculate_progress
  after insert or update or delete on material_competencies
  for each row execute function trg_matcomp_recalculate();

-- Quizzes changed
create or replace function trg_quizzes_recalculate()
returns trigger
language plpgsql
security definer
as $$
declare
  v_material_id uuid := coalesce(new.material_id, old.material_id);
  v_trainee record;
begin
  for v_trainee in
    select distinct trainee_id
    from public.trainee_material_progress
    where material_id = v_material_id
  loop
    perform recalculate_material_progress(v_trainee.trainee_id, v_material_id);
  end loop;
  return null;
end;
$$;

create trigger trg_quizzes_recalculate_progress
  after insert or update or delete on quizzes
  for each row execute function trg_quizzes_recalculate();
