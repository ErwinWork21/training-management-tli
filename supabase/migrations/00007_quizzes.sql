-- ============================================================================
-- 00007: Quizzes, Questions, Options, and Attempts
-- ============================================================================

-- Quizzes
create table quizzes (
  id             uuid primary key default gen_random_uuid(),
  material_id    uuid not null references training_materials(id) on delete cascade,
  title          text not null,
  passing_score  numeric(5,2) not null default 70 check (passing_score between 0 and 100),
  is_active      boolean not null default true,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

create index idx_quizzes_material on quizzes(material_id);
create trigger trg_quizzes_updated_at before update on quizzes
  for each row execute function set_updated_at();

-- Quiz Questions
create table quiz_questions (
  id              uuid primary key default gen_random_uuid(),
  quiz_id         uuid not null references quizzes(id) on delete cascade,
  question_text   text not null,
  sequence_order  int not null default 0,
  created_at      timestamptz not null default now()
);

create index idx_questions_quiz on quiz_questions(quiz_id);

-- Quiz Question Options
create table quiz_question_options (
  id              uuid primary key default gen_random_uuid(),
  question_id     uuid not null references quiz_questions(id) on delete cascade,
  option_text     text not null,
  is_correct      boolean not null default false,
  sequence_order  int not null default 0
);

create index idx_options_question on quiz_question_options(question_id);

-- Quiz Attempts (Immutable append-only log)
create table quiz_attempts (
  id            uuid primary key default gen_random_uuid(),
  quiz_id       uuid not null references quizzes(id) on delete restrict,
  trainee_id    uuid not null references trainees(id) on delete restrict,
  trainer_id    uuid references trainers(id) on delete restrict,
  score         numeric(5,2) not null check (score between 0 and 100),
  passed        boolean not null,
  answers       jsonb,
  notes         text,
  attempted_at  timestamptz not null default now()
);

create index idx_quiz_attempts_quiz on quiz_attempts(quiz_id);
create index idx_quiz_attempts_trainee on quiz_attempts(trainee_id);

create trigger trg_quiz_attempts_append_only
  before update or delete on quiz_attempts
  for each row execute function enforce_append_only();
