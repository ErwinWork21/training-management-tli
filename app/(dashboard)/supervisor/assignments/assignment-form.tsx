'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createAssignment } from './actions';
import { Button } from '@/components/ui/button';

export function AssignmentForm({ trainers, trainees }: { trainers: any[], trainees: any[] }) {
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const router = useRouter();

  async function onSubmit(formData: FormData) {
    setIsSubmitting(true);
    setError(null);
    const result = await createAssignment(formData);
    if (result.error) {
      setError(result.error);
    } else {
      router.refresh(); // Refresh the page to show the new assignment
    }
    setIsSubmitting(false);
  }

  return (
    <form action={onSubmit} className="flex gap-4 items-end">
      <div className="flex flex-col gap-2">
        <label htmlFor="trainerId" className="text-sm font-medium">Trainer</label>
        <select id="trainerId" name="trainerId" className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring" required>
          <option value="">Select Trainer...</option>
          {trainers.map(t => (
            <option key={t.id} value={t.id}>
              {t.profiles?.full_name ?? t.id}
            </option>
          ))}
        </select>
      </div>

      <div className="flex flex-col gap-2">
        <label htmlFor="traineeId" className="text-sm font-medium">Trainee</label>
        <select id="traineeId" name="traineeId" className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring" required>
          <option value="">Select Trainee...</option>
          {trainees.map(t => (
            <option key={t.id} value={t.id}>
              {t.profiles?.full_name ?? t.id}
            </option>
          ))}
        </select>
      </div>

      <Button type="submit" disabled={isSubmitting}>Assign</Button>
      
      {error && <p className="text-sm text-destructive mt-2">{error}</p>}
    </form>
  );
}
