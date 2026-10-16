'use client';

import { useState } from 'react';
import { UserRole, Profile } from '@/lib/types/database.types';
import { adminSetUserRole } from './actions';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

export function RoleAssignmentTable({ profiles }: { profiles: Profile[] }) {
  const [loadingId, setLoadingId] = useState<string | null>(null);
  const [selectedRoles, setSelectedRoles] = useState<Record<string, UserRole>>({});
  const [statusMessage, setStatusMessage] = useState<{ id: string; error?: string; success?: string } | null>(null);

  async function handleRoleChange(profileId: string) {
    const newRole = selectedRoles[profileId];
    if (!newRole) return;

    setLoadingId(profileId);
    setStatusMessage(null);

    const res = await adminSetUserRole(profileId, newRole);
    setLoadingId(null);

    if (res.error) {
      setStatusMessage({ id: profileId, error: res.error });
    } else {
      setStatusMessage({ id: profileId, success: `Role updated to ${newRole}` });
    }
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>User</TableHead>
          <TableHead>Email</TableHead>
          <TableHead>Current Role</TableHead>
          <TableHead>Assign New Role</TableHead>
          <TableHead className="text-right">Action</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {profiles.map((p) => {
          const currentSelection = selectedRoles[p.id] ?? p.role;
          const isChanged = currentSelection !== p.role;
          const isLoading = loadingId === p.id;

          return (
            <TableRow key={p.id}>
              <TableCell className="font-medium">{p.full_name}</TableCell>
              <TableCell className="text-muted-foreground">{p.email}</TableCell>
              <TableCell>
                <Badge variant={p.role === 'admin' ? 'default' : p.role === 'trainer' ? 'secondary' : 'outline'}>
                  {p.role}
                </Badge>
              </TableCell>
              <TableCell>
                <select
                  value={currentSelection}
                  onChange={(e) =>
                    setSelectedRoles((prev) => ({
                      ...prev,
                      [p.id]: e.target.value as UserRole,
                    }))
                  }
                  className="flex h-8 rounded-md border border-input bg-transparent px-2 text-xs"
                >
                  <option value="trainee">Trainee</option>
                  <option value="trainer">Trainer</option>
                  <option value="supervisor">Supervisor</option>
                  <option value="admin">Admin</option>
                </select>
              </TableCell>
              <TableCell className="text-right">
                <Button
                  size="sm"
                  variant="outline"
                  disabled={!isChanged || isLoading}
                  onClick={() => handleRoleChange(p.id)}
                >
                  {isLoading ? 'Saving...' : 'Update'}
                </Button>
                {statusMessage?.id === p.id && (
                  <p className={`text-xs mt-1 ${statusMessage.error ? 'text-destructive' : 'text-green-600'}`}>
                    {statusMessage.error ?? statusMessage.success}
                  </p>
                )}
              </TableCell>
            </TableRow>
          );
        })}
      </TableBody>
    </Table>
  );
}
