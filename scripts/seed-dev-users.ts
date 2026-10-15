/**
 * Dev Users Seeding Script for The Lab
 *
 * This script seeds development users (admin, trainer, supervisor, trainee)
 * using the Supabase Admin API.
 * 
 * Sets `app_metadata: { role }` on each user so the auth hook in PostgreSQL
 * assigns the role securely without trusting client input.
 *
 * Usage:
 *   npx tsx scripts/seed-dev-users.ts
 *
 * Requirements:
 *   Requires NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in environment.
 */

import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  console.error('Error: NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set.');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

const DEV_USERS = [
  {
    email: 'admin@thelab.local',
    password: process.env.DEV_ADMIN_PASSWORD || 'DevAdmin@123456!',
    fullName: 'System Administrator',
    role: 'admin' as const
  },
  {
    email: 'supervisor@thelab.local',
    password: process.env.DEV_SUPERVISOR_PASSWORD || 'DevSupervisor@123456!',
    fullName: 'Head Supervisor',
    role: 'supervisor' as const
  },
  {
    email: 'trainer@thelab.local',
    password: process.env.DEV_TRAINER_PASSWORD || 'DevTrainer@123456!',
    fullName: 'Senior Trainer Coach',
    role: 'trainer' as const
  },
  {
    email: 'trainee@thelab.local',
    password: process.env.DEV_TRAINEE_PASSWORD || 'DevTrainee@123456!',
    fullName: 'Alice Trainee',
    role: 'trainee' as const
  }
];

async function seed() {
  console.log('Seeding development users...');

  for (const user of DEV_USERS) {
    const { data: existingUsers } = await supabase.auth.admin.listUsers();
    const existing = existingUsers?.users?.find(u => u.email === user.email);

    if (existing) {
      console.log(`User ${user.email} already exists (${existing.id}), updating role and metadata...`);
      await supabase.auth.admin.updateUserById(existing.id, {
        app_metadata: { role: user.role },
        user_metadata: { full_name: user.fullName }
      });
      // Ensure profile role matches
      await supabase.from('profiles').update({ role: user.role, full_name: user.fullName }).eq('id', existing.id);
    } else {
      console.log(`Creating user ${user.email} with role '${user.role}'...`);
      const { data, error } = await supabase.auth.admin.createUser({
        email: user.email,
        password: user.password,
        email_confirm: true,
        app_metadata: { role: user.role },
        user_metadata: { full_name: user.fullName }
      });

      if (error) {
        console.error(`Failed to create ${user.email}:`, error.message);
      } else {
        console.log(`Successfully created ${user.email} (${data.user?.id})`);
      }
    }
  }

  console.log('Dev user seeding completed.');
}

seed().catch(err => {
  console.error('Fatal error during seeding:', err);
  process.exit(1);
});
