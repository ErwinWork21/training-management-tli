-- Backfill missing trainers
INSERT INTO trainers (profile_id)
SELECT id FROM profiles
WHERE role = 'trainer' AND id NOT IN (SELECT profile_id FROM trainers WHERE profile_id IS NOT NULL);

-- Backfill missing trainees
INSERT INTO teachers (profile_id)
SELECT id FROM profiles
WHERE role = 'trainee' AND id NOT IN (SELECT profile_id FROM teachers WHERE profile_id IS NOT NULL);

-- Update the auth user trigger to create the corresponding role record
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_role user_role;
BEGIN
  v_role := coalesce((new.raw_user_meta_data->>'role')::user_role, 'trainee');
  
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.email),
    v_role
  );
  
  if v_role = 'trainer' then
    insert into public.trainers (profile_id) values (new.id);
  elsif v_role = 'trainee' then
    insert into public.teachers (profile_id) values (new.id);
  end if;

  return new;
END;
$$;
