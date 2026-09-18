-- ============================================================================
-- 00008: competency_assessments (immutable history) and quiz system
-- ============================================================================

-- One row per assessment event. Never updated/overwritten — a re-assessment
-- is a NEW row, so the full history of a trainee's competency over time is
-- preserved (required for "competency before/after" trainer-effectiveness
-- evidence in section 11).
create table competency_assessments (
  id               uuid primary key default gen_random_uuid(),
  trainee_id       uuid not null references teachers(id) on delete cascade,
  trainer_id       uuid not null references trainers(id) on delete cascade,
  competency_id    uuid not null references competencies(id),
  material_id      uuid references training_materials(id),
  score            numeric(5,2) not null,
  assessment_date  date not null default current_date,
  evidence         text,
  notes            text,
  created_at       timestamptz not null default now()
);
create index idx_assessments_trainee on competency_assessments(trainee_id);
create index idx_assessments_trainer on competency_assessments(trainer_id);
create index idx_assessments_competency on competency_assessments(competency_id);
create index idx_assessments_material on competency_assessments(material_id);
create index idx_assessments_date on competency_assessments(trainee_id, competency_id, assessment_date);

-- ---------------------------------------------------------------------------
-- Quiz
-- ---------------------------------------------------------------------------
create table quizzes (
  id             uuid primary key default gen_random_uuid(),
  material_id    uuid not null references training_materials(id) on delete cascade,
  title          text not null,
  passing_score  numeric(5,2) not null default 70,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index idx_quizzes_material on quizzes(material_id);
create trigger trg_quizzes_updated_at before update on quizzes
  for each row execute function set_updated_at();

create table quiz_questions (
  id             uuid primary key default gen_random_uuid(),
  quiz_id        uuid not null references quizzes(id) on delete cascade,
  question_text  text not null,
  sequence_order int not null default 0,
  created_at     timestamptz not null default now()
);
create index idx_quiz_questions_quiz on quiz_questions(quiz_id);

create table quiz_question_options (
  id             uuid primary key default gen_random_uuid(),
  question_id    uuid not null references quiz_questions(id) on delete cascade,
  option_text    text not null,
  is_correct     boolean not null default false,
  sequence_order int not null default 0
);
create index idx_quiz_options_question on quiz_question_options(question_id);

-- Every attempt is kept (never deleted). "Latest valid attempt" is a query
-- (see idx below / progress function in 00012), not a destructive update.
create table quiz_attempts (
  id            uuid primary key default gen_random_uuid(),
  quiz_id       uuid not null references quizzes(id) on delete cascade,
  trainee_id    uuid not null references teachers(id) on delete cascade,
  trainer_id    uuid references trainers(id),
  score         numeric(5,2) not null,
  passed        boolean not null,
  answers       jsonb,
  notes         text,
  attempted_at  timestamptz not null default now()
);
create index idx_quiz_attempts_trainee on quiz_attempts(trainee_id);
create index idx_quiz_attempts_quiz on quiz_attempts(quiz_id, trainee_id, attempted_at desc);
