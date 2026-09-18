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

  const { data: progress } = await supabase
    .from('trainee_material_progress')
    .select('status, percentage, latest_score, training_materials:material_id (title)')
    .eq('trainee_id', teacher?.id ?? '');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-xl font-semibold">My Progress</h1>
        <p className="text-sm text-muted-foreground">
          Current level: {(teacher as unknown as { levels?: { name?: string } })?.levels?.name ?? '—'}
        </p>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Material</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Progress</TableHead>
            <TableHead>Latest Score</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {(progress ?? []).map((p, i) => (
            <TableRow key={i}>
              <TableCell>{(p as unknown as { training_materials?: { title?: string } }).training_materials?.title}</TableCell>
              <TableCell>
                <Badge variant="secondary">{p.status}</Badge>
              </TableCell>
              <TableCell>{p.percentage}%</TableCell>
              <TableCell>{p.latest_score ?? '—'}</TableCell>
            </TableRow>
          ))}
          {(progress?.length ?? 0) === 0 && (
            <TableRow>
              <TableCell colSpan={4} className="text-muted-foreground">
                No progress recorded yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
