// ============================================================================
// Clean baseline database types matching supabase/migrations/00001 - 00011
// ============================================================================

export type UserRole = 'admin' | 'trainer' | 'supervisor' | 'trainee';
export type TraineeStatus = 'active' | 'inactive' | 'graduated';
export type RequirementType = 'observation' | 'competency_assessment' | 'quiz';
export type MaterialStatus = 'not_started' | 'in_progress' | 'completed' | 'verified' | 'needs_review';
export type AssignmentStatus = 'active' | 'ended' | 'transferred';
export type SessionStatus = 'planned' | 'completed' | 'rescheduled' | 'cancelled' | 'missed';
export type DelayReason =
  | 'trainee_unavailable'
  | 'trainer_unavailable'
  | 'schedule_changed'
  | 'material_issue'
  | 'operational_issue'
  | 'other';
export type ObservationStatus = 'draft' | 'submitted';
export type VerificationStatus = 'verified' | 'needs_review';
export type FollowupStatus = 'open' | 'in_progress' | 'completed' | 'cancelled';
export type FollowupTrigger =
  | 'failed_assessment'
  | 'needs_improvement'
  | 'low_observation_score'
  | 'missed_training'
  | 'reassessment_required'
  | 'other';
export type ProgressionRequirementType =
  | 'required_materials_completed'
  | 'min_competency_score'
  | 'min_assessment_score'
  | 'final_assessment_required'
  | 'verification_required';

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

export interface Trainee extends Updatable {
  id: string;
  profile_id: string | null;
  employee_code: string | null;
  branch: string | null;
  current_level_id: string | null;
  join_date: string | null;
  status: TraineeStatus;
  notes: string | null;
}

// Backward-compatibility alias
export type Teacher = Trainee;

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
// Views
// ---------------------------------------------------------------------------
export interface VSessionMonitoring {
  session_id: string;
  training_plan_id: string | null;
  trainer_id: string;
  trainee_id: string;
  trainee_code: string | null;
  trainee_name: string;
  material_id: string;
  material_title: string;
  planned_date: string;
  actual_date: string | null;
  status: SessionStatus;
  delay_reason: DelayReason | null;
  is_delayed: boolean;
  delay_days: number;
  is_overdue: boolean;
  is_missed: boolean;
}

export interface VDelayedSession {
  session_id: string;
  training_plan_id: string | null;
  trainer_id: string;
  trainee_id: string;
  trainee_code: string | null;
  trainee_name: string;
  material_id: string;
  material_title: string;
  planned_date: string;
  actual_date: string | null;
  status: SessionStatus;
  delay_reason: DelayReason | null;
  delay_days: number;
}

export interface VPendingVerification {
  progress_id: string;
  trainee_id: string;
  trainee_code: string | null;
  trainee_name: string;
  material_id: string;
  material_title: string;
  trainer_id: string | null;
  completed_at: string | null;
}

export interface VPendingFollowup {
  followup_id: string;
  trainee_id: string;
  trainee_code: string | null;
  trainee_name: string;
  trainer_id: string;
  material_id: string | null;
  material_title: string | null;
  action: string;
  due_date: string | null;
  status: FollowupStatus;
  trigger_reason: FollowupTrigger;
}

export interface VTrainerDeliveryStats {
  trainer_id: string;
  trainer_name: string;
  total_sessions: number;
  completed_sessions: number;
  delayed_sessions: number;
  missed_sessions: number;
}

export interface VTrainerFollowupStats {
  trainer_id: string;
  trainer_name: string;
  total_followups: number;
  completed_followups: number;
  overdue_followups: number;
}

type Table<T> = { Row: T; Insert: Partial<T>; Update: Partial<T> };
type View<T> = { Row: T };

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
      trainees: Table<Trainee>;
      teachers: Table<Trainee>; // Alias for safety during refactor
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
    Views: {
      v_session_monitoring: View<VSessionMonitoring>;
      v_delayed_sessions: View<VDelayedSession>;
      v_missed_sessions: View<VDelayedSession>;
      v_overdue_sessions: View<VDelayedSession>;
      v_pending_verification: View<VPendingVerification>;
      v_pending_followups: View<VPendingFollowup>;
      v_trainer_delivery_stats: View<VTrainerDeliveryStats>;
      v_trainer_followup_stats: View<VTrainerFollowupStats>;
    };
    Functions: {
      admin_set_user_role: {
        Args: {
          p_profile_id: string;
          p_role: UserRole;
          [key: string]: unknown;
        };
        Returns: void;
      };
      current_role_name: {
        Args: Record<string, never>;
        Returns: UserRole;
      };
      current_trainer_id: {
        Args: Record<string, never>;
        Returns: string;
      };
      current_trainee_id: {
        Args: Record<string, never>;
        Returns: string;
      };
      is_my_trainee: {
        Args: {
          p_trainee_id: string;
          [key: string]: unknown;
        };
        Returns: boolean;
      };
      is_historical_trainee: {
        Args: {
          p_trainee_id: string;
          [key: string]: unknown;
        };
        Returns: boolean;
      };
    };
  };
}
