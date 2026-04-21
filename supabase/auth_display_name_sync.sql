-- Keep auth.users metadata display_name in sync with public.profiles.username
-- Run in Supabase SQL editor.

CREATE OR REPLACE FUNCTION public.sync_auth_user_display_name_from_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NEW.username IS NULL OR btrim(NEW.username) = '' THEN
    RETURN NEW;
  END IF;

  UPDATE auth.users u
  SET
    raw_user_meta_data = COALESCE(u.raw_user_meta_data, '{}'::jsonb) ||
      jsonb_build_object(
        'display_name', NEW.username,
        'username', NEW.username
      ),
    updated_at = NOW()
  WHERE u.id = NEW.id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_sync_auth_display_name_from_profile ON public.profiles;
CREATE TRIGGER trigger_sync_auth_display_name_from_profile
AFTER INSERT OR UPDATE OF username ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.sync_auth_user_display_name_from_profile();

-- Backfill existing users so auth panel display_name gets populated now.
UPDATE auth.users u
SET
  raw_user_meta_data = COALESCE(u.raw_user_meta_data, '{}'::jsonb) ||
    jsonb_build_object(
      'display_name', p.username,
      'username', p.username
    ),
  updated_at = NOW()
FROM public.profiles p
WHERE p.id = u.id
  AND p.username IS NOT NULL
  AND btrim(p.username) <> '';

