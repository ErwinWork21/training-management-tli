import Link from 'next/link';
import type { UserRole } from '@/lib/types/database.types';

const NAV: Record<UserRole, { href: string; label: string }[]> = {
  admin: [
    { href: '/admin', label: 'Overview' },
  ],
  trainer: [
    { href: '/trainer', label: 'Overview' },
    { href: '/trainer/trainees', label: 'My Trainees' },
    { href: '/trainer/sessions/new', label: 'Plan Session' },
    { href: '/trainer/verification', label: 'Pending Verification' },
  ],
  supervisor: [
    { href: '/supervisor', label: 'Overview' },
    { href: '/supervisor/trainers', label: 'Trainers' },
    { href: '/supervisor/trainees', label: 'Trainees' },
    { href: '/supervisor/assignments', label: 'Assignments' },
  ],
  trainee: [
    { href: '/trainee', label: 'My Progress' },
    { href: '/trainee/materials', label: 'Materials' },
  ],
};

export function Sidebar({ role }: { role: UserRole }) {
  const items = NAV[role];
  return (
    <nav className="flex h-full w-56 shrink-0 flex-col gap-1 border-r bg-secondary/30 p-3">
      <div className="mb-2 px-2 text-sm font-semibold">The Lab</div>
      {items.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          className="rounded-md px-2 py-1.5 text-sm text-muted-foreground hover:bg-secondary hover:text-foreground"
        >
          {item.label}
        </Link>
      ))}
    </nav>
  );
}
