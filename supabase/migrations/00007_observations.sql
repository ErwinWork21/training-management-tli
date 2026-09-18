-- ============================================================================
-- 00007: observations and observation_scores
-- ============================================================================

create table observations (
  id                uuid primary key default gen_random_uuid(),
  trainee_id        uuid not null references teachers(id) on delete cascade,
  trainer_id        uuid not null references trainers(id) on delete cascade,
  material_id       uuid references training_materials(id),
  session_id        uuid references training_sessions(id) on delete set null,
  observation_date  date not null default current_date,
  overall_score     numeric(5,2),
  feedback          text,
  status            observation_status not null default 'SUBMITTED',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create index idx_observations_trainee on observations(trainee_id);
create index idx_observations_trainer on observations(trainer_id);
create index idx_observations_material on observations(material_id);
create trigger trg_observations_updated_at before update on observations
  for each row execute function set_updated_at();

create table observation_scores (
  id              uuid primary key default gen_random_uuid(),
  observation_id  uuid not null references observations(id) on delete cascade,
  competency_id   uuid not null references competencies(id),
  score           numeric(5,2) not null,
  evidence        text,
  feedback        text,
  created_at      timestamptz not null default now(),
  unique (observation_id, competency_id)
);
create index idx_obsscores_observation on observation_scores(observation_id);
create index idx_obsscores_competency on observation_scores(competency_id);
