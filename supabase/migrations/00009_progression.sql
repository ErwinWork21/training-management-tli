-- ============================================================================
-- 00009: Progression Rules and Level Advancements
-- ============================================================================

-- Progression Rules between levels
create table progression_rules (
  id             uuid primary key default gen_random_uuid(),
  from_level_id  uuid not null references levels(id) on delete restrict,
  to_level_id    uuid not null references levels(id) on delete restrict,
  name           text not null,
  description    text,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  check (from_level_id <> to_level_id)
);

create trigger trg_progression_rules_updated_at before update on progression_rules
  for each row execute function set_updated_at();

-- Progression Requirements within a progression rule
create table progression_requirements (
  id                   uuid primary key default gen_random_uuid(),
  progression_rule_id  uuid not null references progression_rules(id) on delete cascade,
  requirement_type     progression_requirement_type not null,
  config               jsonb not null default '{}'::jsonb,
  is_mandatory         boolean not null default true,
  created_at           timestamptz not null default now()
);

create index idx_prog_reqs_rule on progression_requirements(progression_rule_id);
