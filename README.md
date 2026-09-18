# The Lab — Training Management System (MVP scaffold)

Phase 1 deliverable: **database schema + auth + role-based scaffold**, per the
master prompt's build order (section 27). This is not yet a full CRUD app —
see "What's built" / "What's next" below.

## Stack

Next.js 14 (App Router) · TypeScript (strict) · Tailwind CSS · shadcn/ui ·
Supabase (Postgres + Auth + RLS) · deploy target: Vercel.

## 1. Set up Supabase

1. Create a new project at [supabase.com](https://supabase.com).
2. In the SQL Editor (or via the CLI, see below), run every file in
   `supabase/migrations/` **in order** (00001 → 00013).
3. Optionally seed the Kinder/Junior hierarchy: run `supabase/seed.sql`
   after the migrations. Coder is deliberately left empty — its structure
   is admin-configurable (spec section 2.3), not hardcoded.
4. Grab your Project URL, `anon` key, and `service_role` key from
   Project Settings → API.

### Using the Supabase CLI instead (recommended once you have Docker/CLI locally)

```bash
npm install -g supabase
supabase login
supabase link --project-ref <your-project-ref>
supabase db push          # applies supabase/migrations/*
psql "$DATABASE_URL" -f supabase/seed.sql   # optional seed data
```

## 2. Configure environment variables

```bash
cp .env.example .env.local
# fill in NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY,
# SUPABASE_SERVICE_ROLE_KEY
```

## 3. Install and run

```bash
npm install
npm run dev
```

## 4. Create your first admin user

Self-signup always creates a `trainee`-role profile (see the
`handle_new_auth_user` trigger in `00002_profiles.sql`) — no client can
grant itself `admin`. To create the first admin:

```sql
-- after signing up once with the account you want to be admin:
update profiles set role = 'admin' where email = 'you@example.com';
```

Later admin-created users should go through Supabase Admin API /
service-role calls that set `raw_user_meta_data->>'role'` at creation time,
via an admin-only Server Action (not yet built — see below).

## Deploy

Push this repo to GitHub, import it into Vercel, add the same three env
vars in Vercel's project settings, deploy.

---

## What's built (Phase 1)

- **Full schema** (`supabase/migrations/00001`–`00013`): all core tables
  from spec section 23, configurable Level → Track → Unit → Material →
  Requirement hierarchy, many-to-many competencies, trainer/trainee
  assignments with history, training plans vs. actual sessions, delay
  tracking with reasons, observations + per-competency scores, immutable
  competency-assessment and quiz-attempt history, verification records,
  follow-ups, fully configurable progression rules/requirements (jsonb
  config, no hardcoded thresholds).
- **Backend-computed progress**: `trainee_material_progress` is never
  written by the frontend. `recalculate_material_progress()` (in
  `00011_progress_calculation.sql`) recomputes status/percentage from
  actual requirement evidence, triggered automatically on every relevant
  insert/update.
- **Row Level Security** (`00012_rls_policies.sql`) enforcing: admin full
  access, supervisor read-only, trainer read/write scoped to their
  assigned trainees, trainee read-only on their own records.
- **Monitoring views** (`00013_monitoring_views.sql`) for overdue/delayed/
  missed sessions, pending verification, pending follow-ups, trainees
  requiring attention, and per-trainer delivery/follow-up evidence stats
  (spec section 11 — no single "trainer score").
- **Auth + routing**: Supabase Auth, session-refresh middleware, and
  role-based route protection (`/admin`, `/trainer`, `/supervisor`,
  `/trainee` each gated server-side, never trusting a client-supplied
  role).
- **Dashboard shells** for all four roles, pulling real data from the
  views/tables above (counts, today's sessions, delayed/missed, trainees
  needing attention, a trainee's own progress table).

## What's next (per spec section 27's build order)

4. Master data admin forms — CRUD for levels/tracks/units/materials/
   material_requirements/competencies/progression rules (`/admin/*` pages
   are currently stubs).
5. Trainer ↔ trainee assignment UI.
6. Training plan CRUD.
7. Training session CRUD (create/reschedule/mark missed with delay reason).
8–13. Observation, competency assessment, quiz, verification, and
   follow-up entry forms (the schema, RLS, and progress triggers for all
   of these already exist).
14. Progression evaluation: a function that reads `progression_rules` /
   `progression_requirements` for a trainee's current level and reports
   eligibility (schema is ready; the evaluation function itself is a TODO —
   flagged in `00010_progression.sql`'s comments).
15–17. Fill out the remaining dashboard drill-down pages (trainer →
   trainee → material → session → evidence → follow-up, per spec section 18).
18. Automation: the monitoring views already do real-time detection with no
   cron; a scheduled job would only be needed if you want proactive
   notifications sent off the same data.

## Notes on design decisions

- `teachers` is the trainees table (matches the exact table name from spec
  section 23); foreign keys are named `trainee_id` for readability.
- No feature in this list was invented beyond the spec: where a business
  rule was left undefined (e.g. progression thresholds), it's stored as
  admin-editable `jsonb` config rather than hardcoded, per section 28's
  instruction to make undefined rules configurable.
