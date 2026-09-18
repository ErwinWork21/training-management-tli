'use client';

import { Suspense, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

function SignupForm() {
  const router = useRouter();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('trainee');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    // Validation
    if (!email || !password || !fullName || !role) {
      setError('All fields are required.');
      setLoading(false);
      return;
    }

    if (!['supervisor', 'trainer', 'trainee'].includes(role)) {
      setError('Invalid role selected.');
      setLoading(false);
      return;
    }

    const supabase = createClient();
    const { error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          role: role,
        },
      },
    });

    setLoading(false);

    if (signUpError) {
      setError(signUpError.message);
      return;
    }

    router.replace('/login');
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-1.5">
        <Label htmlFor="fullName">Full Name</Label>
        <Input
          id="fullName"
          type="text"
          required
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          autoComplete="email"
        />
      </div>
      <div className="space-y-1.5">
        <Label htmlFor="password">Password</Label>
        <Input
          id="password"
          type="password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          autoComplete="new-password"
          minLength={6}
        />
      </div>
      <div className="space-y-1.5 flex flex-col">
        <Label htmlFor="role">Role</Label>
        <select
          id="role"
          required
          value={role}
          onChange={(e) => setRole(e.target.value)}
          className="flex h-10 w-full items-center justify-between rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <option value="trainee">Trainee</option>
          <option value="trainer">Trainer</option>
          <option value="supervisor">Supervisor</option>
        </select>
      </div>
      {error && <p className="text-sm text-destructive">{error}</p>}
      <Button type="submit" className="w-full" disabled={loading}>
        {loading ? 'Signing up…' : 'Sign up'}
      </Button>
      <div className="text-center text-sm mt-4">
        Already have an account?{' '}
        <Link href="/login" className="underline hover:text-primary">
          Sign in
        </Link>
      </div>
    </form>
  );
}

export default function SignupPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-secondary/40 p-4">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle className="text-lg">The Lab — Sign Up</CardTitle>
          <p className="text-sm text-muted-foreground">Create a new account</p>
        </CardHeader>
        <CardContent>
          <Suspense fallback={<div className="text-sm text-muted-foreground">Loading form...</div>}>
            <SignupForm />
          </Suspense>
        </CardContent>
      </Card>
    </main>
  );
}
