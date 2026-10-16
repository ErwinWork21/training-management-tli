import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { RoleAssignmentTable } from './role-assignment-table';
import { Profile } from '@/lib/types/database.types';

async function getAdminData() {
  const supabase = await createClient();
  const [users, trainers, trainees, materials, pendingVerification, profilesRes] = await Promise.all([
    supabase.from('profiles').select('id', { count: 'exact', head: true }),
    supabase.from('trainers').select('id', { count: 'exact', head: true }),
    supabase.from('trainees').select('id', { count: 'exact', head: true }),
    supabase.from('training_materials').select('id', { count: 'exact', head: true }),
    supabase.from('v_pending_verification').select('progress_id', { count: 'exact', head: true }),
    supabase.from('profiles').select('*').order('created_at', { ascending: false }).limit(20),
  ]);

  return {
    counts: {
      users: users.count ?? 0,
      trainers: trainers.count ?? 0,
      trainees: trainees.count ?? 0,
      materials: materials.count ?? 0,
      pendingVerification: pendingVerification.count ?? 0,
    },
    profiles: (profilesRes.data || []) as Profile[],
  };
}

export default async function AdminOverviewPage() {
  await requireRole(['admin']);
  const { counts, profiles } = await getAdminData();

  const cards = [
    { label: 'Users', value: counts.users },
    { label: 'Trainers', value: counts.trainers },
    { label: 'Trainees', value: counts.trainees },
    { label: 'Materials', value: counts.materials },
    { label: 'Pending Verification', value: counts.pendingVerification },
  ];

  return (
    <div className="space-y-6">
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
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">User Role Management</CardTitle>
          <p className="text-sm text-muted-foreground">
            Promote trainees or manage staff privileges securely using the database admin API.
          </p>
        </CardHeader>
        <CardContent>
          <RoleAssignmentTable profiles={profiles} />
        </CardContent>
      </Card>
    </div>
  );
}
