'use client';

import { useState, useEffect } from 'react';
import { setViewAsCookie, fetchUsersForRole } from '@/app/(dashboard)/actions/view-as-actions';
import { Button } from '@/components/ui/button';
import type { UserRole } from '@/lib/types/database.types';

export function ViewAsSwitcher({
  currentRole,
  isPreview,
}: {
  currentRole: UserRole;
  isPreview: boolean;
}) {
  const [selectedRole, setSelectedRole] = useState<UserRole | ''>(currentRole);
  const [users, setUsers] = useState<{ id: string; full_name: string }[]>([]);
  const [selectedUser, setSelectedUser] = useState<string>('');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (selectedRole && selectedRole !== 'admin') {
      setIsLoading(true);
      fetchUsersForRole(selectedRole as UserRole).then((data) => {
        setUsers(data);
        setIsLoading(false);
      });
    } else {
      setUsers([]);
      setSelectedUser('');
    }
  }, [selectedRole]);

  const handleApply = async () => {
    if (selectedRole === 'admin') {
      await setViewAsCookie(null, null); // Clear preview
    } else if (selectedRole) {
      await setViewAsCookie(selectedRole as UserRole, selectedUser || null);
    }
    // Hard refresh to re-evaluate the layout and data fetching
    window.location.href = `/${selectedRole}`;
  };

  const handleReset = async () => {
    await setViewAsCookie(null, null);
    window.location.href = '/admin';
  };

  return (
    <div className="flex items-center gap-2">
      <div className="text-xs font-semibold uppercase text-muted-foreground mr-1">
        Admin View As:
      </div>
      <select
        value={selectedRole}
        onChange={(e) => setSelectedRole(e.target.value as UserRole | '')}
        className="h-8 rounded-md border border-input bg-transparent px-2 text-xs"
      >
        <option value="admin">System Admin</option>
        <option value="supervisor">Supervisor</option>
        <option value="trainer">Trainer</option>
        <option value="trainee">Trainee</option>
      </select>

      {users.length > 0 && (
        <select
          value={selectedUser}
          onChange={(e) => setSelectedUser(e.target.value)}
          className="h-8 max-w-[150px] rounded-md border border-input bg-transparent px-2 text-xs"
          disabled={isLoading}
        >
          <option value="">Any {selectedRole}</option>
          {users.map((u) => (
            <option key={u.id} value={u.id}>
              {u.full_name}
            </option>
          ))}
        </select>
      )}

      <Button size="sm" variant="outline" className="h-8 px-2" onClick={handleApply}>
        Apply
      </Button>

      {isPreview && (
        <Button size="sm" variant="destructive" className="h-8 px-2" onClick={handleReset}>
          Exit Preview
        </Button>
      )}
    </div>
  );
}
