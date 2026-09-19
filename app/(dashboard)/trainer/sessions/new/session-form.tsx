'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createSessionPlan } from './actions';
import { Button } from '@/components/ui/button';

export function SessionForm({ 
  trainerId, 
  trainees, 
  levels, 
  tracks, 
  units, 
  materials 
}: { 
  trainerId: string, 
  trainees: any[],
  levels: any[],
  tracks: any[],
  units: any[],
  materials: any[]
}) {
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const router = useRouter();

  const [selectedLevel, setSelectedLevel] = useState('');
  const [selectedTrack, setSelectedTrack] = useState('');
  const [selectedUnit, setSelectedUnit] = useState('');

  const filteredTracks = tracks.filter(t => t.level_id === selectedLevel);
  const filteredUnits = units.filter(u => u.track_id === selectedTrack);
  const filteredMaterials = materials.filter(m => m.unit_id === selectedUnit);

  async function onSubmit(formData: FormData) {
    setIsSubmitting(true);
    setError(null);
    const result = await createSessionPlan(formData);
    if (result.error) {
      setError(result.error);
      setIsSubmitting(false);
    } else {
      router.push('/trainer'); // Redirect to trainer dashboard or sessions list
    }
  }

  return (
    <form action={onSubmit} className="flex flex-col gap-4 max-w-md">
      <input type="hidden" name="trainerId" value={trainerId} />

      <div className="flex flex-col gap-2">
        <label htmlFor="traineeId" className="text-sm font-medium">Trainee</label>
        <select id="traineeId" name="traineeId" className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm" required>
          <option value="">Select Trainee...</option>
          {trainees.map(t => (
            <option key={t.id} value={t.id}>
              {t.profiles?.full_name ?? t.id}
            </option>
          ))}
        </select>
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-sm font-medium">Level</label>
        <select value={selectedLevel} onChange={e => { setSelectedLevel(e.target.value); setSelectedTrack(''); setSelectedUnit(''); }} className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm">
          <option value="">Select Level...</option>
          {levels.map(l => <option key={l.id} value={l.id}>{l.name}</option>)}
        </select>
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-sm font-medium">Track</label>
        <select value={selectedTrack} onChange={e => { setSelectedTrack(e.target.value); setSelectedUnit(''); }} className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm" disabled={!selectedLevel}>
          <option value="">Select Track...</option>
          {filteredTracks.map(t => <option key={t.id} value={t.id}>{t.name}</option>)}
        </select>
      </div>

      <div className="flex flex-col gap-2">
        <label className="text-sm font-medium">Unit / Term</label>
        <select value={selectedUnit} onChange={e => setSelectedUnit(e.target.value)} className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm" disabled={!selectedTrack}>
          <option value="">Select Unit...</option>
          {filteredUnits.map(u => <option key={u.id} value={u.id}>{u.name}</option>)}
        </select>
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor="materialId" className="text-sm font-medium">Material</label>
        <select id="materialId" name="materialId" className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm" required disabled={!selectedUnit}>
          <option value="">Select Material...</option>
          {filteredMaterials.map(m => <option key={m.id} value={m.id}>{m.title}</option>)}
        </select>
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor="plannedDate" className="text-sm font-medium">Planned Date</label>
        <input type="date" id="plannedDate" name="plannedDate" className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm" required />
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor="notes" className="text-sm font-medium">Notes (Optional)</label>
        <textarea id="notes" name="notes" className="flex min-h-[80px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm" />
      </div>

      <Button type="submit" disabled={isSubmitting}>Create Session Plan</Button>
      
      {error && <p className="text-sm text-destructive">{error}</p>}
    </form>
  );
}
