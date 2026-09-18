// ============================================================================
// Hand-authored types matching supabase/migrations/*.sql.
//
// Once the project is linked to a real Supabase project, prefer generating
// this file instead:
//   npx supabase gen types typescript --project-id <id> > lib/types/database.types.ts
// Keep this file as the fallback / reference until that's wired up in CI.
// ============================================================================

export type UserRole = 'admin' | 'trainer' | 'supervisor' | 'trainee';
export type RequirementType = 'OBSERVATION' | 'COMPETENCY_ASSESSMENT' | 'QUIZ';
export type MaterialStatus = 'NOT_STARTED' | 'IN_PROGRESS' | 'COMPLETED' | 'VERIFIED' | 'NEEDS_REVIEW';
export type AssignmentStatus = 'ACTIVE' | 'ENDED' | 'TRANSFERRED';
export type SessionStatus = 'PLANNED' | 'SCHEDULED' | 'COMPLETED' | 'RESCHEDULED' | 'CANCELLED' | 'MISSED';
export type DelayReason =
  | 'TRAINEE_UNAVAILABLE'
  | 'TRAINER_UNAVAILABLE'
  | 'SCHEDULE_CHANGED'
  | 'MATERIAL_ISSUE'
  | 'OPERATIONAL_ISSUE'
  | 'OTHER';
export type ObservationStatus = 'DRAFT' | 'SUBMITTED';
export type VerificationStatus = 'VERIFIED' | 'NEEDS_REVIEW';
export type FollowupStatus = 'OPEN' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
export type FollowupTrigger =
  | 'FAILED_ASSESSMENT'
  | 'NEEDS_IMPROVEMENT'
  | 'LOW_OBSERVATION_SCORE'
  | 'MISSED_TRAINING'
  | 'REASSESSMENT_REQUIRED'
  | 'OTHER';
export type ProgressionRequirementType =
  | 'REQUIRED_MATERIALS_COMPLETED'
  | 'MIN_COMPETENCY_SCORE'
  | 'MIN_ASSESSMENT_SCORE'
  | 'FINAL_ASSESSMENT_REQUIRED'
  | 'VERIFICATION_REQUIRED';

interface Timestamped {
  created_at: string;
}
interface Updatable extends Timestamped {
  updated_at: string;
}

export interface Profile extends Updatable {
  id: string;
  email: string;
  full_name: string;
  role: UserRole;
  phone: string | null;
  is_active: boolean;
}

export interface Level extends Updatable {
  id: string;
  name: string;
  code: string;
  sequence_order: number;
  description: string | null;
  is_active: boolean;
}

export interface TrainingTrack extends Updatable {
  id: string;
  level_id: string;
  name: string;
  code: string;
  sequence_order: number;
  description: string | null;
  is_active: boolean;
}

export interface TrainingUnit extends Updatable {
  id: string;
  track_id: string;
  name: string;
  code: string;
  sequence_order: number;
  description: string | null;
  is_active: boolean;
}

export interface TrainingMaterial extends Updatable {
  id: string;
  unit_id: string;
  title: string;
  description: string | null;
  sequence_order: number;
  is_active: boolean;
}

export interface MaterialRequirement extends Timestamped {
  id: string;
  material_id: string;
  requirement_type: RequirementType;
  is_mandatory: boolean;
  min_score: number | null;
  notes: string | null;
}

export interface Competency extends Updatable {
  id: string;
  name: string;
  description: string | null;
  category: string | null;
  expected_level: string | null;
  is_active: boolean;
}

export interface MaterialCompetency extends Timestamped {
  id: string;
  material_id: string;
  competency_id: string;
}

export interface Trainer extends Updatable {
  id: string;
  profile_id: string;
  employee_code: string | null;
  bio: string | null;
  is_active: boolean;
}

export interface Teacher extends Updatable {
  id: string;
  profile_id: string | null;
  employee_code: string | null;
  branch: string | null;
  current_level_id: string | null;
  join_date: string | null;
  status: 'ACTIVE' | 'INACTIVE' | 'GRADUATED';
  notes: string | null;
}

export interface TrainerTraineeAssignment extends Updatable {
  id: string;
  trainer_id: string;
  trainee_id: string;
  start_date: string;
  end_date: string | null;
  status: AssignmentStatus;
  notes: string | null;
}

export interface TrainingPlan extends Updatable {
  id: string;
  trainer_id: string;
  trainee_id: string;
  material_id: string;
  planned_date: string;
  notes: string | null;
  created_by: string | null;
}

export interface TrainingSession extends Updatable {
  id: string;
  training_plan_id: string | null;
  trainer_id: string;
  trainee_id: string;
  material_id: string;
  planned_date: string;
  actual_date: string | null;
  status: SessionStatus;
  delay_reason: DelayReason | null;
  notes: string | null;
}

export interface Observation extends Updatable {
  id: string;
  trainee_id: string;
  trainer_id: string;
  material_id: string | null;
  session_id: string | null;
  observation_date: string;
  overall_score: number | null;
  feedback: string | null;
  status: ObservationStatus;
}

export interface ObservationScore extends Timestamped {
  id: string;
  observation_id: string;
  competency_id: string;
  score: number;
  evidence: string | null;
  feedback: string | null;
}

export interface CompetencyAssessment extends Timestamped {
  id: string;
  trainee_id: string;
  trainer_id: string;
  competency_id: string;
  material_id: string | null;
  score: number;
  assessment_date: string;
  evidence: string | null;
  notes: string | null;
}

export interface Quiz extends Updatable {
  id: string;
  material_id: string;
  title: string;
  passing_score: number;
  is_active: boolean;
}

export interface QuizQuestion extends Timestamped {
  id: string;
  quiz_id: string;
  question_text: string;
  sequence_order: number;
}

export interface QuizQuestionOption {
  id: string;
  question_id: string;
  option_text: string;
  is_correct: boolean;
  sequence_order: number;
}

export interface QuizAttempt {
  id: string;
  quiz_id: string;
  trainee_id: string;
  trainer_id: string | null;
  score: number;
  passed: boolean;
  answers: Record<string, unknown> | null;
  notes: string | null;
  attempted_at: string;
}

export interface VerificationRecord extends Timestamped {
  id: string;
  trainee_id: string;
  material_id: string;
  trainer_id: string;
  status: VerificationStatus;
  verification_date: string;
  notes: string | null;
}

export interface TrainerFollowup extends Updatable {
  id: string;
  trainee_id: string;
  trainer_id: string;
  material_id: string | null;
  competency_id: string | null;
  trigger_reason: FollowupTrigger;
  action: string;
  due_date: string | null;
  status: FollowupStatus;
  completed_at: string | null;
  notes: string | null;
}

export interface ProgressionRule extends Updatable {
  id: string;
  from_level_id: string;
  to_level_id: string;
  name: string;
  description: string | null;
  is_active: boolean;
}

export interface ProgressionRequirement extends Timestamped {
  id: string;
  progression_rule_id: string;
  requirement_type: ProgressionRequirementType;
  config: Record<string, unknown>;
  is_mandatory: boolean;
}

export interface TraineeMaterialProgress {
  id: string;
  trainee_id: string;
  material_id: string;
  status: MaterialStatus;
  percentage: number;
  started_at: string | null;
  completed_at: string | null;
  verified_at: string | null;
  latest_score: number | null;
  trainer_id: string | null;
  notes: string | null;
  updated_at: string;
}

// ---------------------------------------------------------------------------
// Minimal Supabase `Database` generic. Table typing here is intentionally
// loose (Row === Insert === Update) — swap in `supabase gen types` output
// once the project is linked for full Insert/Update precision (defaults,
// generated columns, etc).
// ---------------------------------------------------------------------------
type Table<T> = { Row: T; Insert: Partial<T>; Update: Partial<T> };

export interface Database {
  public: {
    Tables: {
      profiles: Table<Profile>;
      levels: Table<Level>;
      training_tracks: Table<TrainingTrack>;
      training_units: Table<TrainingUnit>;
      training_materials: Table<TrainingMaterial>;
      material_requirements: Table<MaterialRequirement>;
      competencies: Table<Competency>;
      material_competencies: Table<MaterialCompetency>;
      trainers: Table<Trainer>;
      teachers: Table<Teacher>;
      trainer_trainee_assignments: Table<TrainerTraineeAssignment>;
      training_plans: Table<TrainingPlan>;
      training_sessions: Table<TrainingSession>;
      observations: Table<Observation>;
      observation_scores: Table<ObservationScore>;
      competency_assessments: Table<CompetencyAssessment>;
      quizzes: Table<Quiz>;
      quiz_questions: Table<QuizQuestion>;
      quiz_question_options: Table<QuizQuestionOption>;
      quiz_attempts: Table<QuizAttempt>;
      verification_records: Table<VerificationRecord>;
      trainer_followups: Table<TrainerFollowup>;
      progression_rules: Table<ProgressionRule>;
      progression_requirements: Table<ProgressionRequirement>;
      trainee_material_progress: Table<TraineeMaterialProgress>;
    };
  };
}
