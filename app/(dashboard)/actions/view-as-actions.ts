'use server';

import { cookies } from 'next/headers';
import { getCurrentProfile } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { UserRole } from '@/lib/types/database.types';

export async function setViewAsCookie(role: UserRole | null, profileId: string | null) {
  // Only real admins should be able to trigger this
  const profile = await getCurrentProfile();
  if (!profile) throw new Error('UNAUTHENTICATED');
  // If they are currently previewing, their profile.originalRole will be 'admin'
  if (profile.role !== 'admin' && profile.originalRole !== 'admin') {
    throw new Error('UNAUTHORIZED');
  }

  const cookieStore = await cookies();

  if (!role) {
    // Clear the cookie
    cookieStore.delete('view_as');
    return { success: true };
  }

  // Set the cookie
  cookieStore.set('view_as', JSON.stringify({ role, profileId }), {
    path: '/',
    maxAge: 60 * 60 * 24, // 1 day
    httpOnly: true,
    sameSite: 'lax',
  });

  return { success: true };
}

export async function fetchUsersForRole(role: UserRole) {
  const profile = await getCurrentProfile();
  if (!profile) throw new Error('UNAUTHENTICATED');
  if (profile.role !== 'admin' && profile.originalRole !== 'admin') {
    throw new Error('UNAUTHORIZED');
  }

  const supabase = await createClient();

  // If selecting a supervisor, we just need their profile
  if (role === 'supervisor') {
    const { data } = await supabase.from('profiles').select('id, full_name').eq('role', 'supervisor');
    return data || [];
  }

  // For trainer or trainee, we also want to return their profile_id since that's what the auth context uses
  if (role === 'trainer') {
    const { data } = await supabase.from('trainers').select('profile_id, profiles:profile_id(full_name)');
    return (data || []).map((t: any) => ({
      id: t.profile_id,
      full_name: t.profiles?.full_name || 'Unknown Trainer',
    }));
  }

  if (role === 'trainee') {
    const { data } = await supabase.from('teachers').select('profile_id, profiles:profile_id(full_name)');
    return (data || []).map((t: any) => ({
      id: t.profile_id,
      full_name: t.profiles?.full_name || 'Unknown Trainee',
    })).filter(t => t.id); // Some teachers might not have profile_ids set up
  }

  return [];
}
