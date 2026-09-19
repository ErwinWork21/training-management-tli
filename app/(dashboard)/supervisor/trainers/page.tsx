import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default async function SupervisorTrainersPage() {
  await requireRole(['supervisor', 'admin']);
  const supabase = await createClient();

  // Fetch all trainers
  const { data: trainers, error } = await supabase
    .from('trainers')
    .select(`
      id,
      employee_code,
      is_active,
      profiles:profile_id ( full_name, email )
    `)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching trainers:', error);
  }

  // Fetch metrics per trainer (we could use RPC or views, but for simplicity we can just map the data if needed. 
  // The prompt asks to monitor activity when supported. We'll fetch basic data here.)
  const { data: activeAssignments } = await supabase
    .from('trainer_trainee_assignments')
    .select('trainer_id')
    .eq('status', 'ACTIVE');
  
  // Count active assignments per trainer
  const assignmentsCount = (activeAssignments || []).reduce((acc: any, curr: any) => {
    acc[curr.trainer_id] = (acc[curr.trainer_id] || 0) + 1;
    return acc;
  }, {});

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Trainers Directory</h1>
          <p className="text-sm text-muted-foreground">Monitor trainer activity and workload.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">All Trainers</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name / Code</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Active Trainees</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {trainers?.map((t: any) => (
                <TableRow key={t.id}>
                  <TableCell>
                    <div className="font-medium">{t.profiles?.full_name ?? 'Unknown'}</div>
                    <div className="text-xs text-muted-foreground">{t.employee_code ?? t.id.split('-')[0]}</div>
                  </TableCell>
                  <TableCell>{t.profiles?.email}</TableCell>
                  <TableCell>{assignmentsCount[t.id] || 0}</TableCell>
                  <TableCell>
                    <Badge variant={t.is_active ? 'default' : 'secondary'}>
                      {t.is_active ? 'ACTIVE' : 'INACTIVE'}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <Button variant="ghost" size="sm" asChild>
                      <Link href={`/supervisor/trainers/${t.id}`}>View Details</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {(!trainers || trainers.length === 0) && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-6">
                    No trainers found.
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
