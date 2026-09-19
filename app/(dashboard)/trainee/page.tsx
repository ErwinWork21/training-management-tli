import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';

export default async function TraineeOverviewPage() {
  const profile = await requireRole(['trainee', 'admin']);
  const supabase = await createClient();

  const { data: teacher } = await supabase
    .from('teachers')
    .select('id, current_level_id, levels:current_level_id (name)')
    .eq('profile_id', profile.id)
    .single();

  const traineeId = (teacher as any)?.id ?? '';

  const { data: progress } = await supabase
    .from('trainee_material_progress')
    .select('status, percentage, latest_score, training_materials:material_id (title)')
    .eq('trainee_id', traineeId);

  // Fetch assigned trainer
  const { data: assignment } = await supabase
    .from('trainer_trainee_assignments')
    .select('trainers ( id, profiles:profile_id ( full_name ) )')
    .eq('trainee_id', traineeId)
    .eq('status', 'ACTIVE')
    .single();
    
  const activeTrainerName = (assignment as any)?.trainers?.profiles?.full_name ?? 'None assigned';

  // Fetch upcoming sessions
  const { data: upcomingSessions } = await supabase
    .from('training_sessions')
    .select('id, planned_date, status, training_materials:material_id (title)')
    .eq('trainee_id', traineeId)
    .in('status', ['PLANNED', 'SCHEDULED'])
    .order('planned_date', { ascending: true })
    .limit(5);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold">My Progress</h1>
        <p className="text-sm text-muted-foreground mb-4">
          Current level: {(teacher as unknown as { levels?: { name?: string } })?.levels?.name ?? '—'} <br/>
          Assigned Trainer: <span className="font-medium text-foreground">{activeTrainerName}</span>
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <h2 className="mb-2 text-sm font-semibold">Upcoming Sessions</h2>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>Material</TableHead>
                <TableHead>Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {((upcomingSessions as any[]) ?? []).map((s) => (
                <TableRow key={s.id}>
                  <TableCell>{s.planned_date}</TableCell>
                  <TableCell>{s.training_materials?.title ?? 'Unknown'}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{s.status}</Badge>
                  </TableCell>
                </TableRow>
              ))}
              {(upcomingSessions?.length ?? 0) === 0 && (
                <TableRow>
                  <TableCell colSpan={3} className="text-muted-foreground text-center py-4">
                    No upcoming sessions.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>

        <div>
          <h2 className="mb-2 text-sm font-semibold">My Materials Progress</h2>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Material</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Progress</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {((progress as any[]) ?? []).map((p, i) => (
                <TableRow key={i}>
                  <TableCell>{(p as unknown as { training_materials?: { title?: string } }).training_materials?.title}</TableCell>
                  <TableCell>
                    <Badge variant="secondary">{p.status}</Badge>
                  </TableCell>
                  <TableCell>{p.percentage}%</TableCell>
                </TableRow>
              ))}
              {(progress?.length ?? 0) === 0 && (
                <TableRow>
                  <TableCell colSpan={3} className="text-muted-foreground text-center py-4">
                    No progress recorded yet.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
      </div>
    </div>
  );
}
