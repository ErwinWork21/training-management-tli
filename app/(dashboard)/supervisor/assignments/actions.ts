'use server';

import { createClient } from '@/lib/supabase/server';
import { requireRole } from '@/lib/auth/get-user-role';
import { revalidatePath } from 'next/cache';

export async function createAssignment(formData: FormData) {
  await requireRole(['supervisor', 'admin']);
  const supabase = await createClient();

  const trainerId = formData.get('trainerId') as string;
  const traineeId = formData.get('traineeId') as string;

  if (!trainerId || !traineeId) {
    return { error: 'Both Trainer and Trainee are required' };
  }

  // 1. Mark existing active assignments for this trainee as ended
  await supabase
    .from('trainer_trainee_assignments')
    .update({ 
      status: 'COMPLETED', 
      end_date: new Date().toISOString().slice(0, 10) 
    })
    .eq('trainee_id', traineeId)
    .eq('status', 'ACTIVE');

  // 2. Insert new assignment
  const { error } = await supabase
    .from('trainer_trainee_assignments')
    .insert({
      trainer_id: trainerId,
      trainee_id: traineeId,
      status: 'ACTIVE',
      start_date: new Date().toISOString().slice(0, 10),
    });

  if (error) {
    console.error('Error creating assignment:', error);
    return { error: error.message };
  }

  revalidatePath('/supervisor/assignments');
  return { success: true };
}
