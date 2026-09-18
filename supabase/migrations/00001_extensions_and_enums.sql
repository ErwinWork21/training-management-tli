-- ============================================================================
-- 00001: Extensions and shared enum types
-- ============================================================================

create extension if not exists "pgcrypto";   -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Roles
-- ---------------------------------------------------------------------------
create type user_role as enum ('admin', 'trainer', 'supervisor', 'trainee');

-- ---------------------------------------------------------------------------
-- Training structure / material lifecycle
-- ---------------------------------------------------------------------------
create type requirement_type as enum ('OBSERVATION', 'COMPETENCY_ASSESSMENT', 'QUIZ');

create type material_status as enum (
  'NOT_STARTED',
  'IN_PROGRESS',
  'COMPLETED',
  'VERIFIED',
  'NEEDS_REVIEW'
);

-- ---------------------------------------------------------------------------
-- Assignments
-- ---------------------------------------------------------------------------
create type assignment_status as enum ('ACTIVE', 'ENDED', 'TRANSFERRED');

-- ---------------------------------------------------------------------------
-- Sessions / scheduling
-- ---------------------------------------------------------------------------
create type session_status as enum (
  'PLANNED',
  'SCHEDULED',
  'COMPLETED',
  'RESCHEDULED',
  'CANCELLED',
  'MISSED'
);

create type delay_reason as enum (
  'TRAINEE_UNAVAILABLE',
  'TRAINER_UNAVAILABLE',
  'SCHEDULE_CHANGED',
  'MATERIAL_ISSUE',
  'OPERATIONAL_ISSUE',
  'OTHER'
);

-- ---------------------------------------------------------------------------
-- Observation
-- ---------------------------------------------------------------------------
create type observation_status as enum ('DRAFT', 'SUBMITTED');

-- ---------------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------------
create type verification_status as enum ('VERIFIED', 'NEEDS_REVIEW');

-- ---------------------------------------------------------------------------
-- Follow-up
-- ---------------------------------------------------------------------------
create type followup_status as enum ('OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

create type followup_trigger as enum (
  'FAILED_ASSESSMENT',
  'NEEDS_IMPROVEMENT',
  'LOW_OBSERVATION_SCORE',
  'MISSED_TRAINING',
  'REASSESSMENT_REQUIRED',
  'OTHER'
);

-- ---------------------------------------------------------------------------
-- Progression
-- ---------------------------------------------------------------------------
create type progression_requirement_type as enum (
  'REQUIRED_MATERIALS_COMPLETED',
  'MIN_COMPETENCY_SCORE',
  'MIN_ASSESSMENT_SCORE',
  'FINAL_ASSESSMENT_REQUIRED',
  'VERIFICATION_REQUIRED'
);

-- ---------------------------------------------------------------------------
-- Shared trigger: keep updated_at current
-- ---------------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
