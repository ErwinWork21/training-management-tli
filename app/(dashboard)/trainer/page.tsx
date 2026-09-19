import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export default async function TrainerOverviewPage() {
  const profile = await requireRole(['trainer', 'admin']);
  const supabase = await createClient();

  const { data: trainer } = await supabase
    .from('trainers')
    .select('id')
    .eq('profile_id', profile.id)
    .single();

  const trainerId = (trainer as any)?.id ?? '';

  const [today, upcoming, overdue, pendingVerification, pendingFollowups] = await Promise.all([
    supabase
      .from('training_sessions')
      .select('id, planned_date, status, material_id, trainee_id')
      .eq('trainer_id', trainerId)
      .eq('planned_date', new Date().toISOString().slice(0, 10)),
    supabase
      .from('training_sessions')
      .select('id, planned_date, status, material_id, trainee_id')
      .eq('trainer_id', trainerId)
      .gt('planned_date', new Date().toISOString().slice(0, 10))
      .in('status', ['PLANNED', 'SCHEDULED'])
      .order('planned_date', { ascending: true })
      .limit(10),
    supabase.from('v_overdue_sessions').select('*').eq('trainer_id', trainerId),
    supabase.from('v_pending_verification').select('*').eq('trainer_id', trainerId),
    supabase.from('v_pending_followups').select('*').eq('trainer_id', trainerId),
  ]);

  const stats = [
    { label: "Today's Sessions", value: today.data?.length ?? 0 },
    { label: 'Upcoming', value: upcoming.data?.length ?? 0 },
    { label: 'Overdue', value: overdue.data?.length ?? 0 },
    { label: 'Pending Verification', value: pendingVerification.data?.length ?? 0 },
    { label: 'Pending Follow-ups', value: pendingFollowups.data?.length ?? 0 },
  ];

  return (
    <div className="space-y-6">
      <div>
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-xl font-semibold">Trainer Overview</h1>
          <Button asChild>
            <Link href="/trainer/trainees/new">Register Trainee</Link>
          </Button>
        </div>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-5">
          {stats.map((s) => (
            <Card key={s.label}>
              <CardHeader>
                <CardTitle className="text-xs font-normal text-muted-foreground">{s.label}</CardTitle>
              </CardHeader>
              <CardContent className="text-2xl font-semibold">{s.value}</CardContent>
            </Card>
          ))}
        </div>
      </div>

      <div>
        <h2 className="mb-2 text-sm font-semibold">Today&apos;s Sessions</h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Planned Date</TableHead>
              <TableHead>Status</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {((today.data as any[]) ?? []).map((s) => (
              <TableRow key={s.id}>
                <TableCell>{s.planned_date}</TableCell>
                <TableCell>
                  <Badge variant="secondary">{s.status}</Badge>
                </TableCell>
              </TableRow>
            ))}
            {(today.data?.length ?? 0) === 0 && (
              <TableRow>
                <TableCell colSpan={2} className="text-muted-foreground">
                  No sessions scheduled today.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
