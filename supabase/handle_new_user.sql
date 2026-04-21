-- ============================================================================
-- Fix: "Database error saving new user" (HTTP 500) on sign up
-- ============================================================================
-- Run the whole script in Supabase → SQL Editor.
--
-- Common causes this addresses:
--   1) Trigger inserts into public.profiles WITHOUT SECURITY DEFINER → RLS blocks it.
--   2) Username from email local-part is < 3 chars → CHECK on profiles.username fails.
--   3) Duplicate username (e.g. same local-part) → UNIQUE constraint fails.
--
-- Your Flutter app sends username in signUp metadata as { "username": "..." }.
-- This function reads raw_user_meta_data->>'username' first.
-- ============================================================================

-- Remove old trigger/function names used in Supabase templates (safe if missing)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  from_meta text;
  uname text;
  email_local text;
BEGIN
  from_meta := NULLIF(TRIM(NEW.raw_user_meta_data->>'username'), '');
  email_local := SPLIT_PART(NEW.email, '@', 1);

  IF from_meta IS NOT NULL AND char_length(from_meta) >= 3 THEN
    uname := LEFT(from_meta, 30);
    IF EXISTS (SELECT 1 FROM public.profiles WHERE username = uname AND id <> NEW.id) THEN
      uname := LEFT(LEFT(from_meta, 20) || '_' || SUBSTRING(REPLACE(NEW.id::text, '-', '') FROM 1 FOR 8), 30);
    END IF;
  ELSE
    -- No usable app username: email local + id fragment (meets length + usually unique)
    uname := LEFT(
      email_local || '_' || SUBSTRING(REPLACE(NEW.id::text, '-', '') FROM 1 FOR 8),
      30
    );
    IF char_length(email_local) < 1 OR char_length(uname) < 3 THEN
      uname := LEFT('user_' || SUBSTRING(REPLACE(NEW.id::text, '-', '') FROM 1 FOR 20), 30);
    END IF;
  END IF;

  INSERT INTO public.profiles (id, username)
  VALUES (NEW.id, uname)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();

-- Optional: if you prefer NO database trigger and only the app inserts profiles,
-- comment out the CREATE TRIGGER above and run instead:
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- DROP FUNCTION IF EXISTS public.handle_new_user();
