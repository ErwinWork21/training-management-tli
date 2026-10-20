-- ============================================================================
-- 00006: Evidence and Assessments (Observations, Assessments, Verifications, Followups)
-- ============================================================================

-- Generic trigger function for append-only audit tables
create or replace function enforce_append_only()
returns trigger
language plpgsql
as $$
begin
  if current_user not in ('postgres', 'supabase_admin') then
    raise exception 'This audit table is append-only and cannot be updated or deleted'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- Observations
create table observations (
  id                uuid primary key default gen_random_uuid(),
  trainee_id        uuid not null references trainees(id) on delete restrict,
  trainer_id        uuid not null references trainers(id) on delete restrict,
  material_id       uuid not null references training_materials(id) on delete restrict,
  session_id        uuid references training_sessions(id) on delete set null,
  observation_date  date not null default current_date,
  overall_score     numeric(5,2) check (overall_score is null or (overall_score >= 0 and overall_score <= 100)),
  feedback          text,
  status            observation_status not null default 'submitted',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index idx_observations_trainee on observations(trainee_id);
create index idx_observations_trainer on observations(trainer_id);
create index idx_observations_material on observations(material_id);
create trigger trg_observations_updated_at before update on observations
  for each row execute function set_updated_at();

-- Enforce immutability of submitted observations
create or replace function lock_submitted_observation()
returns trigger
language plpgsql
as $$
begin
  if old.status = 'submitted' and current_user not in ('postgres', 'supabase_admin') then
    raise exception 'Submitted observations are immutable. Corrections must be submitted as a new observation.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger trg_lock_submitted_observation
  before update or delete on observations
  for each row execute function lock_submitted_observation();

-- Observation rubric item scores
create table observation_scores (
  id              uuid primary key default gen_random_uuid(),
  observation_id  uuid not null references observations(id) on delete cascade,
  competency_id   uuid not null references competencies(id) on delete restrict,
  score           numeric(5,2) not null check (score >= 0 and score <= 100),
  evidence        text,
  feedback        text,
  created_at      timestamptz not null default now(),
  unique (observation_id, competency_id)
);

create index idx_obsscores_comp on observation_scores(competency_id);

-- Competency Assessments (Immutable append-only log)
create table competency_assessments (
  id               uuid primary key default gen_random_uuid(),
  trainee_id       uuid not null references trainees(id) on delete restrict,
  trainer_id       uuid not null references trainers(id) on delete restrict,
  competency_id    uuid not null references competencies(id) on delete restrict,
  material_id      uuid not null references training_materials(id) on delete restrict,
  score            numeric(5,2) not null check (score >= 0 and score <= 100),
  assessment_date  date not null default current_date,
  evidence         text,
  notes            text,
  created_at       timestamptz not null default now()
);

create index idx_assessments_trainee on competency_assessments(trainee_id);
create index idx_assessments_comp on competency_assessments(competency_id);
create index idx_assessments_material on competency_assessments(material_id);

create trigger trg_competency_assessments_append_only
  before update or delete on competency_assessments
  for each row execute function enforce_append_only();

-- Verification Records (Immutable append-only sign-offs)
create table verification_records (
  id                 uuid primary key default gen_random_uuid(),
  trainee_id         uuid not null references trainees(id) on delete restrict,
  material_id        uuid not null references training_materials(id) on delete restrict,
  trainer_id         uuid not null references trainers(id) on delete restrict,
  status             verification_status not null,
  verification_date  date not null default current_date,
  notes              text,
  created_at         timestamptz not null default now()
);

create index idx_verification_trainee on verification_records(trainee_id);
create index idx_verification_material on verification_records(material_id);

create trigger trg_verification_records_append_only
  before update or delete on verification_records
  for each row execute function enforce_append_only();

-- Trainer Followups
create table trainer_followups (
  id              uuid primary key default gen_random_uuid(),
  trainee_id      uuid not null references trainees(id) on delete restrict,
  trainer_id      uuid not null references trainers(id) on delete restrict,
  material_id     uuid references training_materials(id) on delete set null,
  competency_id   uuid references competencies(id) on delete set null,
  trigger_reason  followup_trigger not null default 'other',
  action          text not null,
  due_date        date,
  status          followup_status not null default 'open',
  completed_at    timestamptz,
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_followups_trainee on trainer_followups(trainee_id);
create index idx_followups_trainer on trainer_followups(trainer_id);
create index idx_followups_status on trainer_followups(status);
create trigger trg_followups_updated_at before update on trainer_followups
  for each row execute function set_updated_at();
