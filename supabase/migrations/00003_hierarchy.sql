-- ============================================================================
-- 00003: Training Hierarchy & Competencies
-- LEVEL -> TRACK -> UNIT -> MATERIAL -> REQUIREMENT & COMPETENCIES
-- ============================================================================

-- Levels (e.g. Kinder, Junior, Coder)
create table levels (
  id              uuid primary key default gen_random_uuid(),
  name            text not null unique,
  code            text not null unique,
  sequence_order  int not null,
  description     text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_levels_sequence on levels(sequence_order);
create trigger trg_levels_updated_at before update on levels
  for each row execute function set_updated_at();

-- Training Tracks
create table training_tracks (
  id              uuid primary key default gen_random_uuid(),
  level_id        uuid not null references levels(id) on delete cascade,
  name            text not null,
  code            text not null,
  sequence_order  int not null,
  description     text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (level_id, code)
);

create index idx_tracks_level on training_tracks(level_id);
create trigger trg_tracks_updated_at before update on training_tracks
  for each row execute function set_updated_at();

-- Training Units / Terms
create table training_units (
  id              uuid primary key default gen_random_uuid(),
  track_id        uuid not null references training_tracks(id) on delete cascade,
  name            text not null,
  code            text not null,
  sequence_order  int not null,
  description     text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (track_id, code)
);

create index idx_units_track on training_units(track_id);
create trigger trg_units_updated_at before update on training_units
  for each row execute function set_updated_at();

-- Training Materials
create table training_materials (
  id              uuid primary key default gen_random_uuid(),
  unit_id         uuid not null references training_units(id) on delete cascade,
  title           text not null,
  description     text,
  sequence_order  int not null,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_materials_unit on training_materials(unit_id);
create trigger trg_materials_updated_at before update on training_materials
  for each row execute function set_updated_at();

-- Material Requirements
create table material_requirements (
  id                uuid primary key default gen_random_uuid(),
  material_id       uuid not null references training_materials(id) on delete cascade,
  requirement_type  requirement_type not null,
  is_mandatory      boolean not null default true,
  min_score         numeric(5,2) check (min_score is null or (min_score >= 0 and min_score <= 100)),
  notes             text,
  created_at        timestamptz not null default now(),
  unique (material_id, requirement_type)
);

create index idx_requirements_material on material_requirements(material_id);

-- Competencies
create table competencies (
  id              uuid primary key default gen_random_uuid(),
  name            text not null unique,
  description     text,
  category        text,
  expected_level  text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_competencies_category on competencies(category);
create trigger trg_competencies_updated_at before update on competencies
  for each row execute function set_updated_at();

-- Material Competencies (Many-to-Many link)
create table material_competencies (
  id             uuid primary key default gen_random_uuid(),
  material_id    uuid not null references training_materials(id) on delete cascade,
  competency_id  uuid not null references competencies(id) on delete cascade,
  created_at     timestamptz not null default now(),
  unique (material_id, competency_id)
);

create index idx_matcomp_material on material_competencies(material_id);
create index idx_matcomp_competency on material_competencies(competency_id);
