-- ============================================================================
-- 00004: Competencies — independent of materials, linked many-to-many
-- ============================================================================

create table competencies (
  id              uuid primary key default gen_random_uuid(),
  name            text not null unique,
  description     text,
  category        text,
  expected_level  text,        -- free-text/config, e.g. 'Basic', 'Proficient'
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index idx_competencies_category on competencies(category);
create trigger trg_competencies_updated_at before update on competencies
  for each row execute function set_updated_at();

create table material_competencies (
  id             uuid primary key default gen_random_uuid(),
  material_id    uuid not null references training_materials(id) on delete cascade,
  competency_id  uuid not null references competencies(id) on delete cascade,
  created_at     timestamptz not null default now(),
  unique (material_id, competency_id)
);
create index idx_matcomp_material on material_competencies(material_id);
create index idx_matcomp_competency on material_competencies(competency_id);
