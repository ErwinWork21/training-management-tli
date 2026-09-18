-- ============================================================================
-- 00013: Read-only views that back the supervisor/trainer dashboards and
-- the "automatically detect" requirements in spec section 25. These are
-- plain views (recomputed on query), not background jobs — no cron needed
-- for detection itself; a scheduled job can later be added purely to send
-- notifications off the same underlying data.
-- ============================================================================

-- Sessions that are overdue (past planned_date, not completed/cancelled)
-- or already flagged delayed/missed.
create view v_overdue_sessions as
select s.*
from training_sessions s
where s.status not in ('COMPLETED', 'CANCELLED')
  and s.planned_date < current_date;

create view v_delayed_sessions as
select *
from v_session_timeliness
where is_delayed = true;

create view v_missed_sessions as
select * from training_sessions where status = 'MISSED';

-- Materials that reached COMPLETED but are still awaiting verification.
create view v_pending_verification as
select p.*, tm.title as material_title, t.employee_code as trainee_code
from trainee_material_progress p
join training_materials tm on tm.id = p.material_id
join teachers t on t.id = p.trainee_id
where p.status = 'COMPLETED';

create view v_pending_followups as
select f.*
from trainer_followups f
where f.status in ('OPEN', 'IN_PROGRESS');

-- Trainees needing attention: overdue follow-ups, NEEDS_REVIEW materials,
-- or missed sessions in the last 30 days.
create view v_trainees_requiring_attention as
select distinct t.id as trainee_id, t.employee_code
from teachers t
where exists (
  select 1 from trainer_followups f
  where f.trainee_id = t.id and f.status in ('OPEN', 'IN_PROGRESS')
    and f.due_date < current_date
)
or exists (
  select 1 from trainee_material_progress p
  where p.trainee_id = t.id and p.status = 'NEEDS_REVIEW'
)
or exists (
  select 1 from training_sessions s
  where s.trainee_id = t.id and s.status = 'MISSED'
    and s.planned_date >= current_date - interval '30 days'
);

-- Per-trainer delivery evidence (section 11: Training Delivery counts).
create view v_trainer_delivery_stats as
select
  s.trainer_id,
  count(*) filter (where s.status in ('PLANNED', 'SCHEDULED'))    as planned_sessions,
  count(*) filter (where s.status = 'COMPLETED')                  as completed_sessions,
  count(*) filter (where s.status = 'COMPLETED' and s.actual_date <= s.planned_date) as on_time_sessions,
  count(*) filter (where s.status = 'COMPLETED' and s.actual_date > s.planned_date)  as delayed_sessions,
  count(*) filter (where s.status = 'MISSED')                     as missed_sessions
from training_sessions s
group by s.trainer_id;

-- Per-trainer follow-up evidence.
create view v_trainer_followup_stats as
select
  f.trainer_id,
  count(*)                                            as required_followups,
  count(*) filter (where f.status = 'COMPLETED')       as completed_followups,
  count(*) filter (where f.status in ('OPEN','IN_PROGRESS')) as pending_followups
from trainer_followups f
group by f.trainer_id;
