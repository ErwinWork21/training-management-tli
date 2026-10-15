-- ============================================================================
-- 00011: Consolidated Monitoring Views
-- All views defined with security_invoker = true and explicit column lists
-- ============================================================================

-- 1. Unified Session Monitoring View
create view v_session_monitoring with (security_invoker = true) as
select
  s.id as session_id,
  s.training_plan_id,
  s.trainer_id,
  s.trainee_id,
  t.employee_code as trainee_code,
  p.full_name as trainee_name,
  s.material_id,
  m.title as material_title,
  s.planned_date,
  s.actual_date,
  s.status,
  s.delay_reason,
  case
    when s.actual_date is not null and s.actual_date > s.planned_date then true
    when s.actual_date is null and s.status not in ('completed', 'cancelled')
         and s.planned_date < current_date then true
    else false
  end as is_delayed,
  case
    when s.actual_date is not null then (s.actual_date - s.planned_date)
    when s.status not in ('completed', 'cancelled') and s.planned_date < current_date
         then (current_date - s.planned_date)
    else 0
  end as delay_days,
  case
    when s.planned_date < current_date and s.status not in ('completed', 'cancelled') then true
    else false
  end as is_overdue,
  case
    when s.status = 'missed' then true
    else false
  end as is_missed
from training_sessions s
join trainees t on t.id = s.trainee_id
join profiles p on p.id = t.profile_id
join training_materials m on m.id = s.material_id;

-- 2. Delayed Sessions (Preserves compatibility with supervisor dashboard)
create view v_delayed_sessions with (security_invoker = true) as
select
  session_id,
  training_plan_id,
  trainer_id,
  trainee_id,
  trainee_code,
  trainee_name,
  material_id,
  material_title,
  planned_date,
  actual_date,
  status,
  delay_reason,
  delay_days
from v_session_monitoring
where is_delayed = true;

-- 3. Missed Sessions
create view v_missed_sessions with (security_invoker = true) as
select
  session_id,
  training_plan_id,
  trainer_id,
  trainee_id,
  trainee_code,
  trainee_name,
  material_id,
  material_title,
  planned_date,
  actual_date,
  status,
  delay_reason,
  delay_days
from v_session_monitoring
where is_missed = true;

-- 4. Overdue Sessions
create view v_overdue_sessions with (security_invoker = true) as
select
  session_id,
  training_plan_id,
  trainer_id,
  trainee_id,
  trainee_code,
  trainee_name,
  material_id,
  material_title,
  planned_date,
  actual_date,
  status,
  delay_reason,
  delay_days
from v_session_monitoring
where is_overdue = true;

-- 5. Pending Verification
create view v_pending_verification with (security_invoker = true) as
select
  p.id as progress_id,
  p.trainee_id,
  t.employee_code as trainee_code,
  prof.full_name as trainee_name,
  p.material_id,
  m.title as material_title,
  p.trainer_id,
  p.completed_at
from trainee_material_progress p
join trainees t on t.id = p.trainee_id
join profiles prof on prof.id = t.profile_id
join training_materials m on m.id = p.material_id
where p.status = 'completed';

-- 6. Pending Followups
create view v_pending_followups with (security_invoker = true) as
select
  f.id as followup_id,
  f.trainee_id,
  t.employee_code as trainee_code,
  prof.full_name as trainee_name,
  f.trainer_id,
  f.material_id,
  m.title as material_title,
  f.action,
  f.due_date,
  f.status,
  f.trigger_reason
from trainer_followups f
join trainees t on t.id = f.trainee_id
join profiles prof on prof.id = t.profile_id
left join training_materials m on m.id = f.material_id
where f.status in ('open', 'in_progress');

-- 7. Trainees Requiring Attention
create view v_trainees_requiring_attention with (security_invoker = true) as
select
  t.id as trainee_id,
  t.employee_code,
  prof.full_name,
  coalesce(nr.cnt, 0) as needs_review_count,
  coalesce(of_f.cnt, 0) as overdue_followups_count,
  coalesce(ms.cnt, 0) as recent_missed_sessions_count
from trainees t
join profiles prof on prof.id = t.profile_id
left join (
  select trainee_id, count(*) as cnt
  from trainee_material_progress
  where status = 'needs_review'
  group by trainee_id
) nr on nr.trainee_id = t.id
left join (
  select trainee_id, count(*) as cnt
  from trainer_followups
  where status in ('open', 'in_progress')
    and due_date < current_date
  group by trainee_id
) of_f on of_f.trainee_id = t.id
left join (
  select trainee_id, count(*) as cnt
  from training_sessions
  where status = 'missed'
    and planned_date >= (current_date - interval '30 days')
  group by trainee_id
) ms on ms.trainee_id = t.id
where coalesce(nr.cnt, 0) > 0
   or coalesce(of_f.cnt, 0) > 0
   or coalesce(ms.cnt, 0) > 0;

-- 8. Trainer Delivery Stats
create view v_trainer_delivery_stats with (security_invoker = true) as
select
  tr.id as trainer_id,
  prof.full_name as trainer_name,
  count(s.id) as total_sessions,
  count(s.id) filter (where s.status = 'completed') as completed_sessions,
  count(s.id) filter (where s.actual_date > s.planned_date or (s.planned_date < current_date and s.status not in ('completed', 'cancelled'))) as delayed_sessions,
  count(s.id) filter (where s.status = 'missed') as missed_sessions
from trainers tr
join profiles prof on prof.id = tr.profile_id
left join training_sessions s on s.trainer_id = tr.id
group by tr.id, prof.full_name;

-- 9. Trainer Followup Stats
create view v_trainer_followup_stats with (security_invoker = true) as
select
  tr.id as trainer_id,
  prof.full_name as trainer_name,
  count(f.id) as total_followups,
  count(f.id) filter (where f.status = 'completed') as completed_followups,
  count(f.id) filter (where f.status in ('open', 'in_progress') and f.due_date < current_date) as overdue_followups
from trainers tr
join profiles prof on prof.id = tr.profile_id
left join trainer_followups f on f.trainer_id = tr.id
group by tr.id, prof.full_name;

-- Grant select on all monitoring views to authenticated
grant select on
  v_session_monitoring,
  v_delayed_sessions,
  v_missed_sessions,
  v_overdue_sessions,
  v_pending_verification,
  v_pending_followups,
  v_trainees_requiring_attention,
  v_trainer_delivery_stats,
  v_trainer_followup_stats
to authenticated;
