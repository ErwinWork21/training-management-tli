-- ============================================================================
-- 00005: Planning and Training Sessions
-- ============================================================================

-- Training Plans (Intended training)
create table training_plans (
  id           uuid primary key default gen_random_uuid(),
  trainer_id   uuid not null references trainers(id) on delete restrict,
  trainee_id   uuid not null references trainees(id) on delete restrict,
  material_id  uuid not null references training_materials(id) on delete restrict,
  planned_date date not null,
  notes        text,
  created_by   uuid references profiles(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index idx_plans_trainer on training_plans(trainer_id);
create index idx_plans_trainee on training_plans(trainee_id);
create index idx_plans_material on training_plans(material_id);
create index idx_plans_planned_date on training_plans(planned_date);
create trigger trg_plans_updated_at before update on training_plans
  for each row execute function set_updated_at();

-- Training Sessions (Actual delivery)
create table training_sessions (
  id                uuid primary key default gen_random_uuid(),
  training_plan_id  uuid references training_plans(id) on delete set null,
  trainer_id        uuid not null references trainers(id) on delete restrict,
  trainee_id        uuid not null references trainees(id) on delete restrict,
  material_id       uuid not null references training_materials(id) on delete restrict,
  planned_date      date not null,
  actual_date       date,
  status            session_status not null default 'planned',
  delay_reason      delay_reason,
  notes             text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  check (
    delay_reason is null
    or status in ('rescheduled', 'missed', 'completed')
  )
);

create index idx_sessions_trainer on training_sessions(trainer_id);
create index idx_sessions_trainee on training_sessions(trainee_id);
create index idx_sessions_material on training_sessions(material_id);
create index idx_sessions_status on training_sessions(status);
create index idx_sessions_planned_date on training_sessions(planned_date);
create trigger trg_sessions_updated_at before update on training_sessions
  for each row execute function set_updated_at();

-- Enforce consistency between session and its associated training plan
create or replace function validate_session_plan_consistency()
returns trigger
language plpgsql
as $$
declare
  v_plan record;
begin
  if new.training_plan_id is not null then
    select trainer_id, trainee_id, material_id into v_plan
    from public.training_plans
    where id = new.training_plan_id;

    if not found then
      raise exception 'Referenced training plan % does not exist', new.training_plan_id;
    end if;

    if new.trainer_id <> v_plan.trainer_id
       or new.trainee_id <> v_plan.trainee_id
       or new.material_id <> v_plan.material_id then
      raise exception 'Session attributes (trainer, trainee, material) must match the linked training plan';
    end if;
  end if;
  return new;
end;
$$;

create trigger trg_validate_session_plan_consistency
  before insert or update on training_sessions
  for each row execute function validate_session_plan_consistency();
