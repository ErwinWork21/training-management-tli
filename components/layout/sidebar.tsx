import Link from 'next/link';
import type { UserRole } from '@/lib/types/database.types';

const NAV: Record<UserRole, { href: string; label: string }[]> = {
  admin: [
    { href: '/admin', label: 'Overview' },
    { href: '/admin/users', label: 'Users' },
    { href: '/admin/levels', label: 'Levels & Tracks' },
    { href: '/admin/materials', label: 'Materials' },
    { href: '/admin/competencies', label: 'Competencies' },
    { href: '/admin/progression', label: 'Progression Rules' },
  ],
  trainer: [
    { href: '/trainer', label: 'Overview' },
    { href: '/trainer/trainees', label: 'My Trainees' },
    { href: '/trainer/sessions', label: 'Sessions' },
    { href: '/trainer/verification', label: 'Pending Verification' },
    { href: '/trainer/followups', label: 'Follow-ups' },
  ],
  supervisor: [
    { href: '/supervisor', label: 'Overview' },
    { href: '/supervisor/trainers', label: 'Trainers' },
    { href: '/supervisor/trainees', label: 'Trainees' },
    { href: '/supervisor/sessions', label: 'Sessions' },
    { href: '/supervisor/followups', label: 'Follow-ups' },
  ],
  trainee: [
    { href: '/trainee', label: 'My Progress' },
    { href: '/trainee/materials', label: 'Materials' },
    { href: '/trainee/feedback', label: 'Feedback' },
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
