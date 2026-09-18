import { createClient } from '@/lib/supabase/server';
import type { UserRole } from '@/lib/types/database.types';

export type CurrentProfile = {
  id: string;
  email: string;
  full_name: string;
  role: UserRole;
  is_active: boolean;
};

/**
 * Returns the signed-in user's profile (id, role, etc.) or null if not
 * authenticated. This is the single source of truth for role checks in
 * Server Components, Route Handlers and Server Actions — never trust a
 * role passed from the client.
 */
export async function getCurrentProfile(): Promise<CurrentProfile | null> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const { data: profile, error } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, is_active')
    .eq('id', user.id)
    .single();

  if (error || !profile) return null;

  return profile as CurrentProfile;
}

/**
 * Throws if there is no signed-in user, or the signed-in user's role is
 * not in `allowed`. Use at the top of Server Components / Server Actions
 * that must be restricted to specific roles.
 */
export async function requireRole(allowed: UserRole[]): Promise<CurrentProfile> {
  const profile = await getCurrentProfile();

  if (!profile || !profile.is_active) {
    throw new Error('UNAUTHENTICATED');
  }

  if (!allowed.includes(profile.role)) {
    throw new Error('FORBIDDEN');
  }

  return profile;
}
