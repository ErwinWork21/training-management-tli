-- ============================================================================
-- 00004: People and Assignments
-- trainers, trainees (renamed from teachers), and trainer_trainee_assignments
-- ============================================================================

-- Trainers
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

-- Trainees (Renamed from teachers)
create table trainees (
  id                 uuid primary key default gen_random_uuid(),
  profile_id         uuid unique references profiles(id) on delete cascade,
  employee_code      text unique,
  branch             text,
  current_level_id   uuid references levels(id) on delete restrict,
  join_date          date,
  status             trainee_status not null default 'active',
  notes              text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create index idx_trainees_level on trainees(current_level_id);
create trigger trg_trainees_updated_at before update on trainees
  for each row execute function set_updated_at();

-- Trainer - Trainee Assignments (Historical log)
create table trainer_trainee_assignments (
  id           uuid primary key default gen_random_uuid(),
  trainer_id   uuid not null references trainers(id) on delete restrict,
  trainee_id   uuid not null references trainees(id) on delete restrict,
  start_date   date not null default current_date,
  end_date     date,
  status       assignment_status not null default 'active',
  notes        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  check (end_date is null or end_date >= start_date)
);

create index idx_assignments_trainer on trainer_trainee_assignments(trainer_id);
create index idx_assignments_trainee on trainer_trainee_assignments(trainee_id);
create trigger trg_assignments_updated_at before update on trainer_trainee_assignments
  for each row execute function set_updated_at();

-- Ensure only ONE active assignment per trainee at any time
create unique index uq_assignments_active_trainee
  on trainer_trainee_assignments (trainee_id)
  where (status = 'active');

-- Trigger to automatically create trainer/trainee record when a profile is created
create or replace function handle_profile_role_provisioning()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role = 'trainer' then
    insert into public.trainers (profile_id)
    values (new.id)
    on conflict (profile_id) do nothing;
  elsif new.role = 'trainee' then
    insert into public.trainees (profile_id)
    values (new.id)
    on conflict (profile_id) do nothing;
  end if;
  return new;
end;
$$;

create trigger trg_on_profile_created
  after insert on profiles
  for each row execute function handle_profile_role_provisioning();
