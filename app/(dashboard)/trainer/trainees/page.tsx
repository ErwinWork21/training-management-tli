import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default async function TrainerTraineesPage() {
  const profile = await requireRole(['trainer', 'admin']);
  const supabase = await createClient();

  // Get current trainer record
  const { data: trainer } = await supabase
    .from('trainers')
    .select('id')
    .eq('profile_id', profile.id)
    .single();

  const trainerId = (trainer as any)?.id;

  // Fetch active assignments for this trainer
  const { data: assignments } = await supabase
    .from('trainer_trainee_assignments')
    .select(`
      id,
      start_date,
      teachers (
        id,
        employee_code,
        status,
        profiles:profile_id ( full_name, email ),
        levels:current_level_id ( name )
      )
    `)
    .eq('trainer_id', trainerId)
    .eq('status', 'ACTIVE')
    .order('start_date', { ascending: false });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">My Trainees</h1>
          <p className="text-sm text-muted-foreground">View and manage your assigned trainees.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">Active Assignments</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Trainee Name / Code</TableHead>
                <TableHead>Current Level</TableHead>
                <TableHead>Assignment Date</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {assignments?.map((a: any) => (
                <TableRow key={a.id}>
                  <TableCell>
                    <div className="font-medium">{a.teachers?.profiles?.full_name ?? 'Unknown'}</div>
                    <div className="text-xs text-muted-foreground">{a.teachers?.employee_code ?? a.teachers?.id.split('-')[0]}</div>
                  </TableCell>
                  <TableCell>{a.teachers?.levels?.name ?? 'Unassigned'}</TableCell>
                  <TableCell>{a.start_date}</TableCell>
                  <TableCell>
                    <Badge variant={a.teachers?.status === 'ACTIVE' ? 'default' : 'secondary'}>
                      {a.teachers?.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <Button variant="ghost" size="sm" asChild>
                      <Link href={`/trainer/trainees/${a.teachers?.id}`}>View Progress</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {(!assignments || assignments.length === 0) && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-6">
                    No active trainees assigned.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
