-- ============================================================================
-- 00001: Extensions, standardized lowercase enums, and common helpers
-- ============================================================================

create extension if not exists "pgcrypto";

-- Roles
create type user_role as enum ('admin', 'trainer', 'supervisor', 'trainee');

-- Trainee status
create type trainee_status as enum ('active', 'inactive', 'graduated');

-- Material requirement types
create type requirement_type as enum ('observation', 'competency_assessment', 'quiz');

-- Material progression status
create type material_status as enum (
  'not_started',
  'in_progress',
  'completed',
  'verified',
  'needs_review'
);

-- Trainer - Trainee assignment status
create type assignment_status as enum ('active', 'ended', 'transferred');

-- Training session status
create type session_status as enum (
  'planned',
  'completed',
  'rescheduled',
  'cancelled',
  'missed'
);

-- Session delay reasons
create type delay_reason as enum (
  'trainee_unavailable',
  'trainer_unavailable',
  'schedule_changed',
  'material_issue',
  'operational_issue',
  'other'
);

-- Observation status
create type observation_status as enum ('draft', 'submitted');

-- Verification status
create type verification_status as enum ('verified', 'needs_review');

-- Followup status
create type followup_status as enum ('open', 'in_progress', 'completed', 'cancelled');

-- Followup trigger reasons
create type followup_trigger as enum (
  'failed_assessment',
  'needs_improvement',
  'low_observation_score',
  'missed_training',
  'reassessment_required',
  'other'
);

-- Progression requirement types
create type progression_requirement_type as enum (
  'required_materials_completed',
  'min_competency_score',
  'min_assessment_score',
  'final_assessment_required',
  'verification_required'
);

-- Helper trigger function to maintain updated_at
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
