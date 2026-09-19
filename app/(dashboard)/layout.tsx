import { redirect } from 'next/navigation';
import { getCurrentProfile } from '@/lib/auth/get-user-role';
import { Sidebar } from '@/components/layout/sidebar';

import { LogoutButton } from '@/components/auth/logout-button';

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const profile = await getCurrentProfile();
  if (!profile) redirect('/login');

  return (
    <div className="flex min-h-screen">
      <Sidebar role={profile.role} />
      <div className="flex-1">
        <header className="flex h-12 items-center justify-between border-b px-4 text-sm">
          <span className="text-muted-foreground">Signed in as {profile.full_name}</span>
          <div className="flex items-center gap-3">
            <span className="rounded-md bg-secondary px-2 py-0.5 text-xs font-medium uppercase">{profile.role}</span>
            <LogoutButton />
          </div>
        </header>
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
