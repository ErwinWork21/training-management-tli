import { redirect } from 'next/navigation';
import { getCurrentProfile } from '@/lib/auth/get-user-role';

// Root route: send everyone to their role's dashboard. middleware.ts
// already guarantees an authenticated, active user reaches this point.
export default async function HomePage() {
  const profile = await getCurrentProfile();

  if (!profile) redirect('/login');

  switch (profile.role) {
    case 'admin':
      redirect('/admin');
    case 'trainer':
      redirect('/trainer');
    case 'supervisor':
      redirect('/supervisor');
    case 'trainee':
      redirect('/trainee');
  }
}
