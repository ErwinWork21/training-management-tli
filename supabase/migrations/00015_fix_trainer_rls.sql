-- 00015: Fix Trainer RLS policies

-- Replace current_trainer_id() and current_teacher_id() in policies to avoid STABLE caching issues
-- or nested SECURITY DEFINER context issues.

drop policy if exists assignments_select on trainer_trainee_assignments;
create policy assignments_select on trainer_trainee_assignments for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or trainer_id in (select id from trainers where profile_id = auth.uid())
    or trainee_id in (select id from teachers where profile_id = auth.uid())
  );

-- For teachers_select, we remove the reliance on the is_my_trainee function for the select policy
-- to prevent deeply nested function evaluations, and use a direct subquery instead.
drop policy if exists teachers_select on teachers;
create policy teachers_select on teachers for select
  using (
    current_role_name() in ('admin', 'supervisor')
    or profile_id = auth.uid()
    or (
      current_role_name() = 'trainer' 
      and exists (
        select 1 from trainer_trainee_assignments
        where trainee_id = teachers.id
        and trainer_id in (select id from trainers where profile_id = auth.uid())
      )
    )
  );
