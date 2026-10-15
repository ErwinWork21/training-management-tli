-- ============================================================================
-- The Lab — Master pgTAP Test Suite Runner
-- Executes all security, RLS, and trigger regression tests.
-- Usage:
--   supabase test db
--   or: psql -h localhost -p 54322 -U postgres -d postgres -f supabase/tests/run_all.sql
-- ============================================================================

\ir 01_auth_signup_and_profile_security.sql
\ir 02_anon_access_revoked.sql
\ir 03_quiz_security.sql
\ir 04_trainer_trainee_isolation.sql
\ir 05_append_only_enforcement.sql
\ir 06_recalculate_material_progress_edge_cases.sql
\ir 07_view_security_invoker.sql
