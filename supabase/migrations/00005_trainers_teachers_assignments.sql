-- ============================================================================
-- 00005: trainers, teachers (trainees), trainer_trainee_assignments
-- "teachers" here means trainees enrolled in training (per spec section 23);
-- foreign keys elsewhere use trainee_id to stay readable.
-- ============================================================================

create table trainers (
  id             uuid primary key default gen_random_uuid(),
  profile_id     uuid not null unique references profiles(id) on delete cascade,
  employee_code  text unique,
  bio            text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create trigger trg_trainers_updated_at before update on trainers
  for each row execute function set_updated_at();

create table teachers (
  id                 uuid primary key default gen_random_uuid(),
  profile_id         uuid unique references profiles(id) on delete set null,
  employee_code      text unique,
  branch             text,
  current_level_id   uuid references levels(id),
  join_date          date,
  status             text not null default 'ACTIVE' check (status in ('ACTIVE', 'INACTIVE', 'GRADUATED')),
  notes              text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index idx_teachers_level on teachers(current_level_id);
create trigger trg_teachers_updated_at before update on teachers
  for each row execute function set_updated_at();

-- Historical assignment log: reassigning a trainee ends the old row rather
-- than deleting it, so past responsibility for evidence is never lost.
create table trainer_trainee_assignments (
  id           uuid primary key default gen_random_uuid(),
  trainer_id   uuid not null references trainers(id) on delete cascade,
  trainee_id   uuid not null references teachers(id) on delete cascade,
  start_date   date not null default current_date,
  end_date     date,
  status       assignment_status not null default 'ACTIVE',
  notes        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  check (end_date is null or end_date >= start_date)
);
create index idx_assignments_trainer on trainer_trainee_assignments(trainer_id);
create index idx_assignments_trainee on trainer_trainee_assignments(trainee_id);
create trigger trg_assignments_updated_at before update on trainer_trainee_assignments
  for each row execute function set_updated_at();

-- Only one ACTIVE assignment per trainee at a time.
create unique index uq_one_active_assignment_per_trainee
  on trainer_trainee_assignments (trainee_id)
  where (status = 'ACTIVE');
