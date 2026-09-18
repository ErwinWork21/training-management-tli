-- ============================================================================
-- 00003: Training hierarchy — LEVEL -> TRACK -> UNIT -> MATERIAL -> REQUIREMENT
-- Fully data-driven: no level/track/unit names or counts are hardcoded
-- anywhere outside this table data, so Coder (or any future level) needs
-- no schema change.
-- ============================================================================

create table levels (
  id              uuid primary key default gen_random_uuid(),
  name            text not null unique,          -- e.g. 'Kinder', 'Junior', 'Coder'
  code            text not null unique,           -- e.g. 'KINDER'
  sequence_order  int not null,
  description     text,
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index idx_levels_sequence on levels(sequence_order);
create trigger trg_levels_updated_at before update on levels
  for each row execute function set_updated_at();

create table training_tracks (
  id              uuid primary key default gen_random_uuid(),
  level_id        uuid not null references levels(id) on delete cascade,
  name            text not null,                  -- e.g. 'Foundation', 'Core', 'Basic'
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

create table training_units (
  id              uuid primary key default gen_random_uuid(),
  track_id        uuid not null references training_tracks(id) on delete cascade,
  name            text not null,                  -- e.g. 'Term 1'
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

-- A material can require any combination of OBSERVATION / COMPETENCY_ASSESSMENT
-- / QUIZ. Completion is computed from these, never from a plain checkbox.
create table material_requirements (
  id                uuid primary key default gen_random_uuid(),
  material_id       uuid not null references training_materials(id) on delete cascade,
  requirement_type  requirement_type not null,
  is_mandatory      boolean not null default true,
  min_score         numeric(5,2),   -- passing threshold, when applicable (quiz/assessment)
  notes             text,
  created_at        timestamptz not null default now(),
  unique (material_id, requirement_type)
);
create index idx_requirements_material on material_requirements(material_id);
