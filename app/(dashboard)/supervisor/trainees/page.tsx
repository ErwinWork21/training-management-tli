import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

export default async function SupervisorTraineesPage() {
  await requireRole(['supervisor', 'admin']);
  const supabase = await createClient();

  // Fetch all trainees (teachers)
  const { data: trainees, error } = await supabase
    .from('teachers')
    .select(`
      id,
      employee_code,
      status,
      profiles:profile_id ( full_name, email ),
      levels:current_level_id ( name )
    `)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching trainees:', error);
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Trainees Directory</h1>
          <p className="text-sm text-muted-foreground">View all trainees and their current level.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">All Trainees</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name / Code</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Current Level</TableHead>
                <TableHead>Status</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {trainees?.map((t: any) => (
                <TableRow key={t.id}>
                  <TableCell>
                    <div className="font-medium">{t.profiles?.full_name ?? 'Unknown'}</div>
                    <div className="text-xs text-muted-foreground">{t.employee_code ?? t.id.split('-')[0]}</div>
                  </TableCell>
                  <TableCell>{t.profiles?.email}</TableCell>
                  <TableCell>{t.levels?.name ?? 'Unassigned'}</TableCell>
                  <TableCell>
                    <Badge variant={t.status === 'ACTIVE' ? 'default' : 'secondary'}>
                      {t.status}
                    </Badge>
                  </TableCell>
                </TableRow>
              ))}
              {(!trainees || trainees.length === 0) && (
                <TableRow>
                  <TableCell colSpan={4} className="text-center text-muted-foreground py-6">
                    No trainees found.
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
