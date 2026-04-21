-- Optional: separate `posts` bucket (underscore path: userId_timestamp.ext).
-- The Flutter app uploads post images to the `avatars` bucket instead, using
-- the same `{userId}-{timestamp}.{ext}` pattern as profile pictures, so one
-- set of policies (storage_avatars_policies.sql) covers both.
--
-- Use this file only if you prefer a dedicated `posts` bucket and point the
-- app back to `posts` + userId_timestamp naming.
--
-- Create bucket `posts` in Dashboard (public read recommended).

DROP POLICY IF EXISTS "Public post images readable" ON storage.objects;
CREATE POLICY "Public post images readable"
ON storage.objects FOR SELECT
USING (bucket_id = 'posts');

DROP POLICY IF EXISTS "Users can upload post images" ON storage.objects;
CREATE POLICY "Users can upload post images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'posts'
  AND name LIKE auth.uid()::text || '_%'
);

DROP POLICY IF EXISTS "Users can update own post images" ON storage.objects;
CREATE POLICY "Users can update own post images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'posts'
  AND name LIKE auth.uid()::text || '_%'
)
WITH CHECK (
  bucket_id = 'posts'
  AND name LIKE auth.uid()::text || '_%'
);

DROP POLICY IF EXISTS "Users can delete own post images" ON storage.objects;
CREATE POLICY "Users can delete own post images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'posts'
  AND name LIKE auth.uid()::text || '_%'
);
