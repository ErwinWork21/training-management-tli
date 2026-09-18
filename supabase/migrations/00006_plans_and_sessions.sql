-- ============================================================================
-- 00006: training_plans and training_sessions
-- Plans capture INTENDED training; sessions capture ACTUAL training, so the
-- system can compare planned_date vs actual_date and surface delays.
-- ============================================================================

create table training_plans (
  id           uuid primary key default gen_random_uuid(),
  trainer_id   uuid not null references trainers(id) on delete cascade,
  trainee_id   uuid not null references teachers(id) on delete cascade,
  material_id  uuid not null references training_materials(id) on delete cascade,
  planned_date date not null,
  notes        text,
  created_by   uuid references profiles(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index idx_plans_trainer on training_plans(trainer_id);
create index idx_plans_trainee on training_plans(trainee_id);
create index idx_plans_material on training_plans(material_id);
create index idx_plans_planned_date on training_plans(planned_date);
create trigger trg_plans_updated_at before update on training_plans
  for each row execute function set_updated_at();

create table training_sessions (
  id                uuid primary key default gen_random_uuid(),
  training_plan_id  uuid references training_plans(id) on delete set null,
  trainer_id        uuid not null references trainers(id) on delete cascade,
  trainee_id        uuid not null references teachers(id) on delete cascade,
  material_id       uuid not null references training_materials(id) on delete cascade,
  planned_date      date not null,
  actual_date       date,
  status            session_status not null default 'PLANNED',
  delay_reason      delay_reason,
  notes             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  -- A delay reason should only be recorded once we actually know the
  -- session was delayed / rescheduled / missed.
  check (
    delay_reason is null
    or status in ('RESCHEDULED', 'MISSED', 'COMPLETED')
  )
);
create index idx_sessions_trainer on training_sessions(trainer_id);
create index idx_sessions_trainee on training_sessions(trainee_id);
create index idx_sessions_material on training_sessions(material_id);
create index idx_sessions_status on training_sessions(status);
create index idx_sessions_planned_date on training_sessions(planned_date);
create trigger trg_sessions_updated_at before update on training_sessions
  for each row execute function set_updated_at();

-- Convenience view: is this session delayed, and by how much? Kept as a
-- view (not a stored column) so "delayed" always reflects current data.
create view v_session_timeliness as
select
  s.*,
  case
    when s.actual_date is not null and s.actual_date > s.planned_date then true
    when s.actual_date is null and s.status not in ('COMPLETED', 'CANCELLED')
         and s.planned_date < current_date then true
    else false
  end as is_delayed,
  case
    when s.actual_date is not null then (s.actual_date - s.planned_date)
    when s.status not in ('COMPLETED', 'CANCELLED') and s.planned_date < current_date
      then (current_date - s.planned_date)
    else 0
  end as delay_days
from training_sessions s;
