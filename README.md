# The Lab — Training Management System

Enterprise-grade Training Management System built with **Next.js 14 (App Router)**, **TypeScript (strict)**, **Tailwind CSS**, **shadcn/ui**, and **Supabase (Postgres + Auth + RLS)**.

---

## 1. Database Architecture & Clean Migrations

The database has been overhauled into a clean, modular 11-migration baseline under `supabase/migrations/`:

| Migration | Purpose | Key Objects & Responsibilities |
|---|---|---|
| `00001_types_and_helpers.sql` | Extensions & Enums | `pgcrypto`, all lowercase enums (`user_role`, `material_status`, `session_status`, etc.), `set_updated_at()` trigger function. |
| `00002_identity_and_profiles.sql` | Identity & Roles | `profiles` table, `handle_new_auth_user()` trigger (extracts role strictly from `raw_app_meta_data`), `admin_set_user_role()` function. |
| `00003_hierarchy.sql` | Training Hierarchy | `levels`, `training_tracks`, `training_units`, `training_materials`, `material_requirements`, `competencies`, `material_competencies`. |
| `00004_people_and_assignments.sql` | People & Assignments | `trainers`, `trainees` (renamed from legacy `teachers`), `trainer_trainee_assignments` with historical log and partial unique active index. |
| `00005_planning_and_sessions.sql` | Planning & Delivery | `training_plans`, `training_sessions`, `trg_validate_session_plan_consistency` trigger. |
| `00006_evidence.sql` | Evidence & Assessments | `observations` (with locking trigger for submitted observations), `observation_scores`, `competency_assessments` (append-only), `verification_records` (append-only), `trainer_followups`. |
| `00007_quizzes.sql` | Quizzes & Attempts | `quizzes`, `quiz_questions`, `quiz_question_options`, `quiz_attempts` (append-only). |
| `00008_progress.sql` | Progress Engine | `trainee_material_progress` table, `recalculate_material_progress()` engine (security definer, RPC revoked), evidence & config triggers. |
| `00009_progression.sql` | Level Progression | `progression_rules`, `progression_requirements`. |
| `00010_rls_and_grants.sql` | Access Control & RLS | Zero-anon revocation, STABLE helper functions (`current_role_name`, `current_trainer_id`, `current_trainee_id`, `is_my_trainee`, `is_historical_trainee`), explicit grants, complete RLS policies. |
| `00011_monitoring_views.sql` | Monitoring Views | `v_session_monitoring`, `v_delayed_sessions`, `v_missed_sessions`, `v_overdue_sessions`, `v_pending_verification`, `v_pending_followups`, `v_trainees_requiring_attention`, `v_trainer_delivery_stats`, `v_trainer_followup_stats` — all created `WITH (security_invoker = true)`. |

---

## 2. Local Setup & Running Locally

### Prerequisites
- Node.js 18+ and npm
- (Optional) Docker Desktop if running Supabase CLI locally

### Configuration
1. Clone the repository and install dependencies:
   ```bash
   cd the-lab-app
   npm install
   ```

2. Copy environment template:
   ```bash
   cp .env.example .env.local
   ```
   Configure `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`.

3. Run the development server:
   ```bash
   npm run dev
   ```

---

## 3. Applying Migrations & Seeding

### In Supabase Dashboard (SQL Editor)
Execute files `00001_types_and_helpers.sql` through `00011_monitoring_views.sql` sequentially in the Supabase SQL Editor.
Then run `supabase/seed.sql` to populate the Kinder, Junior, Coder levels, tracks, terms, materials, and sample quizzes.

### Using Local Supabase CLI
```bash
supabase start
supabase db reset   # Applies 00001-00011 then runs supabase/seed.sql
```

---

## 4. Seeding Development Users

To create initial development accounts (`admin@thelab.local`, `supervisor@thelab.local`, `trainer@thelab.local`, `trainee@thelab.local`):

### Option A: Via TypeScript Script (Supabase Admin API)
```bash
npx tsx scripts/seed-dev-users.ts
```

### Option B: Via Direct SQL (Local Postgres / Docker)
```bash
psql "$DATABASE_URL" -f supabase/seed_dev_users.sql
```

---

## 5. Creating Your First Production Admin

All public signups via `/signup` default safely to the `trainee` role. To promote an initial user to `admin`:

1. Sign up through the app at `/signup` with your admin email.
2. In the Supabase SQL Editor, run:
   ```sql
   select admin_set_user_role('YOUR_PROFILE_UUID', 'admin');
   ```
   *(Or query `select id from profiles where email = 'your-email@example.com'` to find your profile UUID).*
3. Subsequent role promotions can be performed directly inside the app on the `/admin` dashboard under **User Role Management**.

---

## 6. Running the pgTAP Test Suite

The test suite in `supabase/tests/` verifies the entire database security model:
- `01_auth_signup_and_profile_security.sql`: Client role injection and profile self-elevation tests.
- `02_anon_access_revoked.sql`: Verifies zero access for unauthenticated clients.
- `03_quiz_security.sql`: Verifies trainees cannot view quiz options/answers or insert quiz attempts.
- `04_trainer_trainee_isolation.sql`: Verifies trainer boundary isolation and ended assignment constraints.
- `05_append_only_enforcement.sql`: Verifies immutability of audit records.
- `06_recalculate_material_progress_edge_cases.sql`: Verifies recalculation logic across all edge cases (failing after pass, stale verification, requirement updates, RPC lockdown).
- `07_view_security_invoker.sql`: Verifies row-level security on views.

Run via Supabase CLI:
```bash
supabase test db
```
Or via psql:
```bash
psql "$DATABASE_URL" -f supabase/tests/run_all.sql
```

---

## 7. Deployment Checklist for Vercel

1. Push your branch to GitHub.
2. Import project into Vercel.
3. Add Environment Variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
4. Set Auth Redirect URLs in Supabase Dashboard (Authentication -> URL Configuration) to include your Vercel production domain.
