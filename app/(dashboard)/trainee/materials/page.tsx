import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export default async function TraineeMaterialsPage() {
  const profile = await requireRole(['trainee', 'admin']);
  const supabase = await createClient();

  const { data: teacher } = await supabase
    .from('teachers')
    .select('id')
    .eq('profile_id', profile.id)
    .single();

  const traineeId = (teacher as any)?.id ?? '';

  // Get active sessions
  const { data: sessions } = await supabase
    .from('training_sessions')
    .select(`
      id, 
      status, 
      planned_date,
      training_materials ( id, title, description, training_units ( name ) )
    `)
    .eq('trainee_id', traineeId)
    .in('status', ['PLANNED', 'SCHEDULED', 'IN_PROGRESS'])
    .order('planned_date', { ascending: true });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">My Materials</h1>
          <p className="text-sm text-muted-foreground">Access your assigned training materials.</p>
        </div>
      </div>

      <div className="grid gap-6">
        {((sessions as any[]) ?? []).map((session) => (
          <Card key={session.id}>
            <CardHeader className="flex flex-row items-start justify-between space-y-0">
              <div>
                <div className="text-xs text-muted-foreground mb-1">
                  Term: {session.training_materials?.training_units?.name}
                </div>
                <CardTitle className="text-lg">{session.training_materials?.title}</CardTitle>
                <div className="mt-2 text-sm text-muted-foreground">
                  {session.training_materials?.description || 'No description provided.'}
                </div>
              </div>
              <Badge>{session.status}</Badge>
            </CardHeader>
            <CardContent>
              <div className="flex gap-4 items-center pt-4 mt-4 border-t">
                <Button asChild variant="outline">
                  <Link href={`#`}>View Details & Requirements</Link>
                </Button>
                {/* 
                  Future implementation: 
                  If material has a quiz requirement, add a button to "Take Quiz".
                  If checklist, add button to "Complete Checklist".
                */}
              </div>
            </CardContent>
          </Card>
        ))}

        {(!sessions || sessions.length === 0) && (
          <div className="text-center text-muted-foreground py-10 bg-muted/20 rounded-md">
            No active materials assigned. Check back later!
          </div>
        )}
      </div>
    </div>
  );
}
