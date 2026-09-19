import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { VerificationForm } from './verification-form';

export default async function TrainerVerificationPage() {
  const profile = await requireRole(['trainer', 'admin']);
  const supabase = await createClient();

  const { data: trainer } = await supabase
    .from('trainers')
    .select('id')
    .eq('profile_id', profile.id)
    .single();

  const trainerId = (trainer as any)?.id;

  // Fetch pending verifications
  const { data: pending } = await supabase
    .from('v_pending_verification')
    .select('*')
    .eq('trainer_id', trainerId);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Pending Verifications</h1>
          <p className="text-sm text-muted-foreground">Review completed materials and submit verification.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">Items Needing Verification</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Trainee Code</TableHead>
                <TableHead>Material</TableHead>
                <TableHead>Completed At</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {pending?.map((p: any) => (
                <TableRow key={p.id}>
                  <TableCell className="font-medium">{p.trainee_code ?? p.trainee_id.split('-')[0]}</TableCell>
                  <TableCell>{p.material_title}</TableCell>
                  <TableCell>{p.completed_at ? new Date(p.completed_at).toLocaleDateString() : 'N/A'}</TableCell>
                  <TableCell className="text-right">
                    <VerificationForm 
                      trainerId={trainerId} 
                      traineeId={p.trainee_id} 
                      materialId={p.material_id} 
                    />
                  </TableCell>
                </TableRow>
              ))}
              {(!pending || pending.length === 0) && (
                <TableRow>
                  <TableCell colSpan={4} className="text-center text-muted-foreground py-6">
                    No pending verifications found.
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
