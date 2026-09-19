import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { AssignmentForm } from './assignment-form';

export default async function SupervisorAssignmentsPage() {
  await requireRole(['supervisor', 'admin']);
  const supabase = await createClient();

  // Fetch all active assignments
  const { data: assignments } = await supabase
    .from('trainer_trainee_assignments')
    .select(`
      id,
      status,
      start_date,
      trainers ( id, profiles:profile_id ( full_name ) ),
      teachers ( id, profiles:profile_id ( full_name ) )
    `)
    .eq('status', 'ACTIVE')
    .order('start_date', { ascending: false });

  // Fetch trainers and trainees for the dropdowns
  const [trainersRes, traineesRes] = await Promise.all([
    supabase.from('trainers').select('id, profiles:profile_id ( full_name )').eq('is_active', true),
    supabase.from('teachers').select('id, profiles:profile_id ( full_name )').eq('status', 'ACTIVE'),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Manage Assignments</h1>
          <p className="text-sm text-muted-foreground">Assign Trainers to Trainees.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">Create New Assignment</CardTitle>
        </CardHeader>
        <CardContent>
          <AssignmentForm 
            trainers={trainersRes.data || []} 
            trainees={traineesRes.data || []} 
          />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">Active Assignments</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Trainer</TableHead>
                <TableHead>Trainee</TableHead>
                <TableHead>Start Date</TableHead>
                <TableHead>Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {assignments?.map((a: any) => (
                <TableRow key={a.id}>
                  <TableCell className="font-medium">
                    {a.trainers?.profiles?.full_name ?? 'Unknown Trainer'}
                  </TableCell>
                  <TableCell>
                    {a.teachers?.profiles?.full_name ?? 'Unknown Trainee'}
                  </TableCell>
                  <TableCell>{a.start_date}</TableCell>
                  <TableCell>
                    <Badge>{a.status}</Badge>
                  </TableCell>
                </TableRow>
              ))}
              {(!assignments || assignments.length === 0) && (
                <TableRow>
                  <TableCell colSpan={4} className="text-center text-muted-foreground py-6">
                    No active assignments found.
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
