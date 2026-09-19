'use server';

import { createClient } from '@/lib/supabase/server';
import { requireRole } from '@/lib/auth/get-user-role';
import { revalidatePath } from 'next/cache';

export async function submitVerification(formData: FormData) {
  const profile = await requireRole(['trainer', 'admin']);
  const supabase = await createClient();

  const trainerId = formData.get('trainerId') as string;
  const traineeId = formData.get('traineeId') as string;
  const materialId = formData.get('materialId') as string;
  const status = formData.get('status') as string;
  const notes = formData.get('notes') as string;

  if (!traineeId || !materialId || !status) {
    return { error: 'Missing required fields' };
  }

  const { error } = await supabase
    .from('verification_records')
    .insert({
      trainee_id: traineeId,
      material_id: materialId,
      trainer_id: trainerId,
      verification_date: new Date().toISOString().slice(0, 10),
      status: status,
      notes: notes
    });

  if (error) {
    return { error: error.message };
  }

  revalidatePath('/trainer/verification');
  revalidatePath('/trainer');
  return { success: true };
}
