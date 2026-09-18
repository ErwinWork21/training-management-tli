-- ============================================================================
-- 00010: progression_rules and progression_requirements
-- Level-to-level promotion criteria are fully configurable by admins —
-- nothing about "100% completion = promotion" is hardcoded. Each rule can
-- carry an arbitrary set of typed requirements with their own thresholds,
-- stored in `config` (jsonb) so new requirement shapes don't need a schema
-- migration.
-- ============================================================================

create table progression_rules (
  id            uuid primary key default gen_random_uuid(),
  from_level_id uuid not null references levels(id),
  to_level_id   uuid not null references levels(id),
  name          text not null,
  description   text,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  check (from_level_id <> to_level_id)
);
create index idx_progression_rules_from on progression_rules(from_level_id);
create trigger trg_progression_rules_updated_at before update on progression_rules
  for each row execute function set_updated_at();

-- Example config payloads by requirement_type (admin-authored, not code):
--   REQUIRED_MATERIALS_COMPLETED  -> { "unit_ids": ["..."], "require_verified": true }
--   MIN_COMPETENCY_SCORE          -> { "competency_ids": ["..."], "min_score": 75 }
--   MIN_ASSESSMENT_SCORE          -> { "min_score": 80 }
--   FINAL_ASSESSMENT_REQUIRED     -> { "assessment_material_id": "..." }
--   VERIFICATION_REQUIRED         -> { "unit_ids": ["..."] }
create table progression_requirements (
  id                    uuid primary key default gen_random_uuid(),
  progression_rule_id   uuid not null references progression_rules(id) on delete cascade,
  requirement_type      progression_requirement_type not null,
  config                jsonb not null default '{}'::jsonb,
  is_mandatory          boolean not null default true,
  created_at            timestamptz not null default now()
);
create index idx_progression_requirements_rule on progression_requirements(progression_rule_id);
