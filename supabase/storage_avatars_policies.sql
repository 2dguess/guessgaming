-- Supabase Storage RLS for app avatar uploads.
-- Object path (no subfolder): "{auth.uid()}-{timestamp}.{ext}"
-- Example: a251826d-9d1d-4231-9ce3-7852ab906c3e-1775647137849.jpg
--
-- Run in Supabase → SQL Editor after creating public bucket `avatars`.

-- Optional: remove policies that used foldername(name) if you created them earlier.
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;

-- Public read (bucket must be public in UI, or rely on this + signed URLs as you prefer)
DROP POLICY IF EXISTS "Public avatars are viewable by everyone" ON storage.objects;
CREATE POLICY "Public avatars are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Upload: only files whose name starts with the signed-in user's UUID + hyphen
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND name LIKE auth.uid()::text || '-%'
);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND name LIKE auth.uid()::text || '-%'
)
WITH CHECK (
  bucket_id = 'avatars'
  AND name LIKE auth.uid()::text || '-%'
);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND name LIKE auth.uid()::text || '-%'
);
