import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';

export default async function SupervisorOverviewPage() {
  await requireRole(['supervisor', 'admin']);
  const supabase = await createClient();

  const [delayed, missed, pendingFollowups, attention] = await Promise.all([
    supabase.from('v_delayed_sessions').select('*', { count: 'exact', head: true }),
    supabase.from('v_missed_sessions').select('*', { count: 'exact', head: true }),
    supabase.from('v_pending_followups').select('*', { count: 'exact', head: true }),
    supabase.from('v_trainees_requiring_attention').select('*'),
  ]);

  const stats = [
    { label: 'Delayed Sessions', value: delayed.count ?? 0 },
    { label: 'Missed Sessions', value: missed.count ?? 0 },
    { label: 'Pending Follow-ups', value: pendingFollowups.count ?? 0 },
    { label: 'Trainees Needing Attention', value: attention.data?.length ?? 0 },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="mb-4 text-xl font-semibold">Supervisor Monitoring</h1>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
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
        <h2 className="mb-2 text-sm font-semibold">Trainees Requiring Attention</h2>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Trainee Code</TableHead>
              <TableHead>Reason</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {(attention.data ?? []).map((t: { trainee_id: string; employee_code: string | null }) => (
              <TableRow key={t.trainee_id}>
                <TableCell>{t.employee_code ?? t.trainee_id}</TableCell>
                <TableCell>
                  <Badge variant="warning">Overdue follow-up / missed session / needs review</Badge>
                </TableCell>
              </TableRow>
            ))}
            {(attention.data?.length ?? 0) === 0 && (
              <TableRow>
                <TableCell colSpan={2} className="text-muted-foreground">
                  No trainees currently flagged.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
