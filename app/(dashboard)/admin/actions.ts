'use server';

import { createClient } from '@/lib/supabase/server';
import { requireRole } from '@/lib/auth/get-user-role';
import { revalidatePath } from 'next/cache';
import { UserRole } from '@/lib/types/database.types';

export async function adminSetUserRole(profileId: string, role: UserRole) {
  await requireRole(['admin']);
  const supabase = await createClient();

  const { error } = await (supabase.rpc as any)('admin_set_user_role', {
    p_profile_id: profileId,
    p_role: role,
  });

  if (error) {
    console.error('Failed to update user role:', error);
    return { error: error.message };
  }

  revalidatePath('/admin');
  return { success: true };
}
