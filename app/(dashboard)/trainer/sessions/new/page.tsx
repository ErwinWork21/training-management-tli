import { requireRole } from '@/lib/auth/get-user-role';
import { createClient } from '@/lib/supabase/server';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { SessionForm } from './session-form';

export default async function NewSessionPage() {
  const profile = await requireRole(['trainer', 'admin']);
  const supabase = await createClient();

  const { data: trainer } = await supabase
    .from('trainers')
    .select('id')
    .eq('profile_id', profile.id)
    .single();

  const trainerId = (trainer as any)?.id;

  // Fetch assigned trainees
  const { data: assignments } = await supabase
    .from('trainer_trainee_assignments')
    .select(`
      teachers (
        id,
        profiles:profile_id ( full_name )
      )
    `)
    .eq('trainer_id', trainerId)
    .eq('status', 'ACTIVE');
  
  const trainees = (assignments || []).map((a: any) => a.teachers);

  // Fetch hierarchy
  const [levelsRes, tracksRes, unitsRes, materialsRes] = await Promise.all([
    supabase.from('levels').select('id, name').eq('is_active', true).order('sequence_order'),
    supabase.from('training_tracks').select('id, level_id, name').eq('is_active', true).order('sequence_order'),
    supabase.from('training_units').select('id, track_id, name').eq('is_active', true).order('sequence_order'),
    supabase.from('training_materials').select('id, unit_id, title').eq('is_active', true).order('sequence_order'),
  ]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold">Plan New Session</h1>
          <p className="text-sm text-muted-foreground">Create a training plan for a trainee.</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base font-semibold">Session Details</CardTitle>
        </CardHeader>
        <CardContent>
          <SessionForm 
            trainerId={trainerId}
            trainees={trainees}
            levels={levelsRes.data || []}
            tracks={tracksRes.data || []}
            units={unitsRes.data || []}
            materials={materialsRes.data || []}
          />
        </CardContent>
      </Card>
    </div>
  );
}
