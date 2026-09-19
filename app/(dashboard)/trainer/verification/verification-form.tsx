'use client';

import { useState } from 'react';
import { submitVerification } from './actions';
import { Button } from '@/components/ui/button';

export function VerificationForm({ 
  trainerId, 
  traineeId, 
  materialId 
}: { 
  trainerId: string, 
  traineeId: string, 
  materialId: string 
}) {
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [status, setStatus] = useState('VERIFIED');
  const [notes, setNotes] = useState('');

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);
    
    const formData = new FormData();
    formData.append('trainerId', trainerId);
    formData.append('traineeId', traineeId);
    formData.append('materialId', materialId);
    formData.append('status', status);
    formData.append('notes', notes);

    const result = await submitVerification(formData);
    if (result.error) {
      setError(result.error);
    }
    setIsSubmitting(false);
  }

  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-2 min-w-[200px]">
      <select value={status} onChange={e => setStatus(e.target.value)} className="flex h-8 w-full rounded-md border border-input bg-transparent px-3 text-xs">
        <option value="VERIFIED">Verified</option>
        <option value="NEEDS_REVIEW">Needs Review</option>
      </select>
      <input type="text" placeholder="Notes (optional)" value={notes} onChange={e => setNotes(e.target.value)} className="flex h-8 w-full rounded-md border border-input bg-transparent px-3 text-xs" />
      <Button type="submit" size="sm" disabled={isSubmitting}>Submit</Button>
      {error && <p className="text-xs text-destructive">{error}</p>}
    </form>
  );
}
