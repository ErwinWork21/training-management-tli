'use server';

import { createClient } from '@/lib/supabase/server';
import { requireRole } from '@/lib/auth/get-user-role';
import { revalidatePath } from 'next/cache';

export async function createSessionPlan(formData: FormData) {
  const profile = await requireRole(['trainer', 'admin']);
  const supabase = await createClient();

  const trainerId = formData.get('trainerId') as string;
  const traineeId = formData.get('traineeId') as string;
  const materialId = formData.get('materialId') as string;
  const plannedDate = formData.get('plannedDate') as string;
  const notes = formData.get('notes') as string;

  if (!traineeId || !materialId || !plannedDate) {
    return { error: 'Trainee, Material, and Planned Date are required' };
  }

  // Insert into training_plans
  const { data: plan, error: planError } = await (supabase.from('training_plans') as any)
    .insert({
      trainer_id: trainerId,
      trainee_id: traineeId,
      material_id: materialId,
      planned_date: plannedDate,
      notes: notes,
      created_by: profile.id
    })
    .select()
    .single();

  if (planError) {
    return { error: planError.message };
  }

  // Insert into training_sessions
  const { error: sessionError } = await (supabase.from('training_sessions') as any)
    .insert({
      training_plan_id: (plan as any).id,
      trainer_id: trainerId,
      trainee_id: traineeId,
      material_id: materialId,
      planned_date: plannedDate,
      status: 'PLANNED',
      notes: notes
    });

  if (sessionError) {
    return { error: sessionError.message };
  }

  revalidatePath('/trainer/sessions');
  revalidatePath('/trainer');
  return { success: true };
}
