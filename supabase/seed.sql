-- ============================================================================
-- Seed data — the LEVEL/TRACK/UNIT structure from spec section 2.
-- Materials are seeded as numbered placeholders ("Material 1".."Material 10")
-- per term; admins rename/replace them via the admin UI. CODER is
-- intentionally left with no tracks/units — its structure is configurable
-- and should be entered by an admin once defined.
--
-- Run with: supabase db reset   (applies migrations then this file)
-- or:       psql < supabase/seed.sql   against an already-migrated database.
-- ============================================================================

do $$
declare
  v_level_id uuid;
  v_track_id uuid;
  v_unit_id  uuid;
  v_level    record;
  v_track    record;
  v_term_no  int;
  v_mat_no   int;
begin
  for v_level in
    select * from (values
      ('Kinder', 'KINDER', 1),
      ('Junior', 'JUNIOR', 2),
      ('Coder',  'CODER',  3)
    ) as l(name, code, seq)
  loop
    insert into levels (name, code, sequence_order, description)
    values (v_level.name, v_level.code, v_level.seq, v_level.name || ' level')
    returning id into v_level_id;

    -- Coder: no tracks/units seeded — structure is configurable (spec 2.3).
    if v_level.code = 'CODER' then
      continue;
    end if;

    for v_track in
      select * from (values ('Foundation', 'FOUNDATION', 1, 2), ('Core', 'CORE', 2, 4)) as tr(name, code, seq, term_count)
    loop
      insert into training_tracks (level_id, name, code, sequence_order, description)
      values (v_level_id, v_track.name, v_track.code, v_track.seq, v_track.name || ' track for ' || v_level.name)
      returning id into v_track_id;

      for v_term_no in 1..v_track.term_count loop
        insert into training_units (track_id, name, code, sequence_order, description)
        values (v_track_id, 'Term ' || v_term_no, 'TERM_' || v_term_no, v_term_no, 'Term ' || v_term_no)
        returning id into v_unit_id;

        for v_mat_no in 1..10 loop
          insert into training_materials (unit_id, title, description, sequence_order)
          values (
            v_unit_id,
            v_level.name || ' / ' || v_track.name || ' / Term ' || v_term_no || ' - Material ' || v_mat_no,
            'Placeholder material — rename via Admin > Materials.',
            v_mat_no
          );
        end loop;
      end loop;
    end loop;
  end loop;
end $$;
