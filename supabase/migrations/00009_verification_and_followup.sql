-- ============================================================================
-- 00009: verification_records and trainer_followups
-- ============================================================================

create table verification_records (
  id                 uuid primary key default gen_random_uuid(),
  trainee_id         uuid not null references teachers(id) on delete cascade,
  material_id        uuid not null references training_materials(id) on delete cascade,
  trainer_id         uuid not null references trainers(id),
  status             verification_status not null,
  verification_date  date not null default current_date,
  notes              text,
  created_at         timestamptz not null default now()
);
create index idx_verification_trainee_material on verification_records(trainee_id, material_id);
create index idx_verification_trainer on verification_records(trainer_id);

create table trainer_followups (
  id             uuid primary key default gen_random_uuid(),
  trainee_id     uuid not null references teachers(id) on delete cascade,
  trainer_id     uuid not null references trainers(id) on delete cascade,
  material_id    uuid references training_materials(id),
  competency_id  uuid references competencies(id),
  trigger_reason followup_trigger not null default 'OTHER',
  action         text not null,
  due_date       date,
  status         followup_status not null default 'OPEN',
  completed_at   timestamptz,
  notes          text,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index idx_followups_trainee on trainer_followups(trainee_id);
create index idx_followups_trainer on trainer_followups(trainer_id);
create index idx_followups_status on trainer_followups(status);
create trigger trg_followups_updated_at before update on trainer_followups
  for each row execute function set_updated_at();
