import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

async function getCounts() {
  const supabase = await createClient();
  const [users, trainers, teachers, materials, pendingVerification] = await Promise.all([
    supabase.from('profiles').select('id', { count: 'exact', head: true }),
    supabase.from('trainers').select('id', { count: 'exact', head: true }),
    supabase.from('teachers').select('id', { count: 'exact', head: true }),
    supabase.from('training_materials').select('id', { count: 'exact', head: true }),
    supabase.from('v_pending_verification').select('id', { count: 'exact', head: true }),
  ]);

  return {
    users: users.count ?? 0,
    trainers: trainers.count ?? 0,
    teachers: teachers.count ?? 0,
    materials: materials.count ?? 0,
    pendingVerification: pendingVerification.count ?? 0,
  };
}

export default async function AdminOverviewPage() {
  await requireRole(['admin']);
  const counts = await getCounts();

  const cards = [
    { label: 'Users', value: counts.users },
    { label: 'Trainers', value: counts.trainers },
    { label: 'Trainees', value: counts.teachers },
    { label: 'Materials', value: counts.materials },
    { label: 'Pending Verification', value: counts.pendingVerification },
  ];

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Admin Overview</h1>
      <div className="grid grid-cols-2 gap-4 md:grid-cols-5">
        {cards.map((c) => (
          <Card key={c.label}>
            <CardHeader>
              <CardTitle className="text-xs font-normal text-muted-foreground">{c.label}</CardTitle>
            </CardHeader>
            <CardContent className="text-2xl font-semibold">{c.value}</CardContent>
          </Card>
        ))}
      </div>
      <p className="mt-6 text-sm text-muted-foreground">
        Manage users, the level/track/unit/material hierarchy, competencies, and progression rules from the
        sidebar. Master data forms are the next implementation step (see README).
      </p>
    </div>
  );
}
