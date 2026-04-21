-- ============================================================================
-- "Database error saving new user" (500) on Sign Up — common causes & fixes
-- ============================================================================
-- Fast path: run the full script in handle_new_user.sql (replaces broken triggers).
-- Run sections below in Supabase → SQL Editor as needed.
--
-- Cause A: A trigger on auth.users (e.g. handle_new_user) inserts into
--          public.profiles WITHOUT SECURITY DEFINER → RLS blocks the insert
--          because auth.uid() is not set during that transaction.
--
-- Cause B: Same trigger + your Flutter app BOTH insert profiles → duplicate
--          key on profiles.id.
--
-- Cause C: Trigger inserts profiles without username → violates NOT NULL /
--          CHECK on username.
-- ============================================================================

-- 1) See triggers on auth.users (inspect only)
SELECT tgname, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND NOT tgisinternal;

-- 2) If you have a broken handle_new_user: replace with this pattern
--    (SECURITY DEFINER + search_path). Adjust column list to match profiles.
/*
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'username',
      split_part(NEW.email, '@', 1)
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
*/

-- 3) If you prefer NO database trigger (Flutter app inserts profile only):
/*
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
*/

-- 4) Ensure wallets trigger can insert (your schema uses SECURITY DEFINER;
--    if wallet insert still fails, add policy allowing service role path — rare)
