-- ============================================================================
-- 00011: trainee_material_progress — the single source of truth for a
-- trainee's progress on a material. Never written directly by the frontend;
-- always recomputed server-side by recalculate_material_progress(), which is
-- triggered whenever an observation, assessment, quiz attempt, or
-- verification record changes.
-- ============================================================================

create table trainee_material_progress (
  id            uuid primary key default gen_random_uuid(),
  trainee_id    uuid not null references teachers(id) on delete cascade,
  material_id   uuid not null references training_materials(id) on delete cascade,
  status        material_status not null default 'NOT_STARTED',
  percentage    numeric(5,2) not null default 0 check (percentage between 0 and 100),
  started_at    timestamptz,
  completed_at  timestamptz,
  verified_at   timestamptz,
  latest_score  numeric(5,2),
  trainer_id    uuid references trainers(id),
  notes         text,
  updated_at    timestamptz not null default now(),
  unique (trainee_id, material_id)
);
create index idx_progress_trainee on trainee_material_progress(trainee_id);
create index idx_progress_material on trainee_material_progress(material_id);
create index idx_progress_status on trainee_material_progress(status);

-- ---------------------------------------------------------------------------
-- Core recalculation function.
--
-- For a given (trainee, material):
--   1. Look up the material's required requirement rows.
--   2. For each requirement type, determine whether it is "satisfied":
--        OBSERVATION            -> latest submitted observation exists
--                                   (score >= min_score if one is set)
--        COMPETENCY_ASSESSMENT  -> latest assessment, for any competency
--                                   linked to this material, meets min_score
--        QUIZ                   -> latest quiz attempt for this material's
--                                   quiz(zes) has passed = true
--   3. percentage = satisfied / total required * 100
--   4. status:
--        no requirements satisfied yet          -> NOT_STARTED
--        some but not all required satisfied    -> IN_PROGRESS
--        all required satisfied, not verified   -> COMPLETED
--        all required satisfied, verified       -> VERIFIED
--        latest verification is NEEDS_REVIEW    -> NEEDS_REVIEW
-- ---------------------------------------------------------------------------
create or replace function recalculate_material_progress(p_trainee_id uuid, p_material_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  v_total_required     int;
  v_satisfied           int := 0;
  v_req                 record;
  v_ok                  boolean;
  v_latest_score        numeric(5,2);
  v_started_at          timestamptz;
  v_completed_at        timestamptz;
  v_verified_at         timestamptz;
  v_status              material_status;
  v_trainer_id          uuid;
  v_latest_verification verification_status;
begin
  select count(*) into v_total_required
  from material_requirements
  where material_id = p_material_id and is_mandatory = true;

  -- No mandatory requirements defined yet: nothing to compute.
  if v_total_required = 0 then
    insert into trainee_material_progress (trainee_id, material_id, status, percentage, updated_at)
    values (p_trainee_id, p_material_id, 'NOT_STARTED', 0, now())
    on conflict (trainee_id, material_id)
    do update set status = 'NOT_STARTED', percentage = 0, updated_at = now();
    return;
  end if;

  for v_req in
    select * from material_requirements
    where material_id = p_material_id and is_mandatory = true
  loop
    v_ok := false;

    if v_req.requirement_type = 'OBSERVATION' then
      select true, o.overall_score, o.observation_date::timestamptz
        into v_ok, v_latest_score, v_started_at
      from observations o
      where o.trainee_id = p_trainee_id
        and o.material_id = p_material_id
        and o.status = 'SUBMITTED'
        and (v_req.min_score is null or o.overall_score >= v_req.min_score)
      order by o.observation_date desc
      limit 1;

    elsif v_req.requirement_type = 'COMPETENCY_ASSESSMENT' then
      select true into v_ok
      from competency_assessments ca
      join material_competencies mc
        on mc.material_id = p_material_id and mc.competency_id = ca.competency_id
      where ca.trainee_id = p_trainee_id
        and (v_req.min_score is null or ca.score >= v_req.min_score)
      order by ca.assessment_date desc
      limit 1;

    elsif v_req.requirement_type = 'QUIZ' then
      select qa.passed into v_ok
      from quiz_attempts qa
      join quizzes q on q.id = qa.quiz_id
      where q.material_id = p_material_id
        and qa.trainee_id = p_trainee_id
      order by qa.attempted_at desc
      limit 1;
      v_ok := coalesce(v_ok, false);
    end if;

    if v_ok then
      v_satisfied := v_satisfied + 1;
    end if;
  end loop;

  -- Most recent trainer to touch this material's evidence for this trainee.
  select trainer_id into v_trainer_id
  from (
    select trainer_id, created_at from observations where trainee_id = p_trainee_id and material_id = p_material_id
    union all
    select trainer_id, created_at from competency_assessments ca
      where ca.trainee_id = p_trainee_id
      and exists (select 1 from material_competencies mc where mc.material_id = p_material_id and mc.competency_id = ca.competency_id)
  ) recent
  order by created_at desc
  limit 1;

  select verification_date::timestamptz, status
    into v_verified_at, v_latest_verification
  from verification_records
  where trainee_id = p_trainee_id and material_id = p_material_id
  order by verification_date desc, created_at desc
  limit 1;

  if v_satisfied = 0 then
    v_status := 'NOT_STARTED';
  elsif v_latest_verification = 'NEEDS_REVIEW' then
    v_status := 'NEEDS_REVIEW';
  elsif v_satisfied < v_total_required then
    v_status := 'IN_PROGRESS';
  elsif v_latest_verification = 'VERIFIED' then
    v_status := 'VERIFIED';
  else
    v_status := 'COMPLETED';
  end if;

  if v_status = 'NOT_STARTED' then
    v_verified_at := null;
  end if;
  if v_status not in ('VERIFIED') then
    -- keep v_verified_at only when actually verified
    v_verified_at := case when v_status = 'VERIFIED' then v_verified_at else null end;
  end if;

  v_completed_at := case when v_satisfied = v_total_required then now() else null end;

  insert into trainee_material_progress (
    trainee_id, material_id, status, percentage, started_at, completed_at,
    verified_at, latest_score, trainer_id, updated_at
  )
  values (
    p_trainee_id, p_material_id, v_status,
    round((v_satisfied::numeric / v_total_required) * 100, 2),
    case when v_satisfied > 0 then now() else null end,
    v_completed_at, v_verified_at, v_latest_score, v_trainer_id, now()
  )
  on conflict (trainee_id, material_id) do update set
    status       = excluded.status,
    percentage   = excluded.percentage,
    started_at   = coalesce(trainee_material_progress.started_at, excluded.started_at),
    completed_at = excluded.completed_at,
    verified_at  = excluded.verified_at,
    latest_score = coalesce(excluded.latest_score, trainee_material_progress.latest_score),
    trainer_id   = coalesce(excluded.trainer_id, trainee_material_progress.trainer_id),
    updated_at   = now();
end;
$$;

-- ---------------------------------------------------------------------------
-- Triggers: any change to source evidence recomputes progress for the
-- affected (trainee, material) pair.
-- ---------------------------------------------------------------------------
create or replace function trg_recalc_from_observation()
returns trigger language plpgsql as $$
begin
  if new.material_id is not null then
    perform recalculate_material_progress(new.trainee_id, new.material_id);
  end if;
  return new;
end;
$$;
create trigger trg_observations_recalc
  after insert or update on observations
  for each row execute function trg_recalc_from_observation();

create or replace function trg_recalc_from_assessment()
returns trigger language plpgsql as $$
declare v_material_id uuid;
begin
  for v_material_id in
    select material_id from material_competencies where competency_id = new.competency_id
  loop
    perform recalculate_material_progress(new.trainee_id, v_material_id);
  end loop;
  return new;
end;
$$;
create trigger trg_assessments_recalc
  after insert on competency_assessments
  for each row execute function trg_recalc_from_assessment();

create or replace function trg_recalc_from_quiz_attempt()
returns trigger language plpgsql as $$
declare v_material_id uuid;
begin
  select material_id into v_material_id from quizzes where id = new.quiz_id;
  if v_material_id is not null then
    perform recalculate_material_progress(new.trainee_id, v_material_id);
  end if;
  return new;
end;
$$;
create trigger trg_quiz_attempts_recalc
  after insert on quiz_attempts
  for each row execute function trg_recalc_from_quiz_attempt();

create or replace function trg_recalc_from_verification()
returns trigger language plpgsql as $$
begin
  perform recalculate_material_progress(new.trainee_id, new.material_id);
  return new;
end;
$$;
create trigger trg_verification_recalc
  after insert on verification_records
  for each row execute function trg_recalc_from_verification();
