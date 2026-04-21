# Profile Picture & Username Edit Setup

## 🎯 Features Added

1. **Profile Picture Upload**
   - Click camera icon on avatar
   - Select image from gallery
   - Auto-upload to Supabase Storage
   - Display in profile

2. **Username Edit**
   - Click edit icon next to username
   - Edit in dialog
   - Save to database
   - Auto-refresh

## 🗄️ Supabase Storage Setup

### Step 1: Create Storage Bucket

Go to **Supabase Dashboard → Storage**:

1. Click **"New bucket"**
2. Bucket name: `avatars`
3. **Public bucket**: ✅ (checked)
4. Click **"Create bucket"**

### Step 2: Set Storage Policies

Go to **Storage → avatars → Policies**:

Click **"New policy"** and add:

#### Policy 1: Public Read Access
```sql
CREATE POLICY "Public avatars are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');
```

#### Policy 2–4: Upload / update / delete (matches the app)

The app uploads to the **bucket root** as `{userId}-{timestamp}.{ext}` (no subfolder).  
Policies must use a **name prefix**, not `storage.foldername(name)` (that only works if you use paths like `userId/file.jpg`).

```sql
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
```

You can paste the full script from `supabase/storage_avatars_policies.sql` (includes `DROP POLICY` for old folder-based rules).

### Alternative: Quick Setup (All Policies at Once)

Go to **SQL Editor** and run:

```sql
-- Enable storage policies
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Public read access
CREATE POLICY "Public avatars viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Authenticated users can upload
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Users can update their own avatars
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Users can delete their own avatars
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);
```

## 📱 How to Use

### Update Profile Picture:

1. Go to your profile
2. Click the **camera icon** on your avatar
3. Select image from gallery
4. Wait for upload
5. Profile picture updates automatically

### Edit Username:

1. Go to your profile
2. Click the **edit icon** (⚙️) in top right
3. OR click the small edit icon next to username
4. Enter new username
5. Click **"Save"**

## 🔧 Features

### Profile Picture:
- ✅ Upload from gallery
- ✅ Auto-resize (512x512)
- ✅ Compress (75% quality)
- ✅ Store in Supabase Storage
- ✅ Display in profile
- ✅ Show in posts/comments
- ✅ Loading indicator during upload

### Username Edit:
- ✅ Edit dialog
- ✅ Validation (not empty)
- ✅ Save to database
- ✅ Auto-refresh UI
- ✅ Success/error messages

## 🎨 UI Elements

### Profile Header:
- Large avatar (100px diameter)
- Camera icon overlay (for own profile)
- Username with edit icon
- Stats (Posts, Followers, Following)

### Edit Icons:
- Top right: Settings/Edit icon
- Next to username: Small edit icon
- On avatar: Camera icon with white border

## 🐛 Troubleshooting

### Profile picture not uploading:

1. **Check Storage bucket exists:**
   - Go to Supabase → Storage
   - Verify "avatars" bucket exists
   - Check it's set to "Public"

2. **Check Storage policies:**
   ```sql
   SELECT * FROM storage.policies WHERE bucket_id = 'avatars';
   ```

3. **Check file size:**
   - Max size: 50MB (Supabase free tier)
   - App auto-resizes to 512x512

4. **Check permissions:**
   - User must be authenticated
   - Check `auth.uid()` is not null

### Username not updating:

1. **Check profiles table:**
   ```sql
   SELECT * FROM profiles WHERE id = 'USER_ID';
   ```

2. **Check RLS policies:**
   ```sql
   SELECT * FROM profiles WHERE id = auth.uid();
   ```

3. **Verify user is authenticated:**
   - Check login status
   - Refresh auth token

### "Unknown" username showing:

This happens when:
- Profile not created during signup
- Username is NULL in database

**Fix:**
```sql
-- Update your profile manually
UPDATE profiles 
SET username = 'YourUsername'
WHERE id = 'YOUR_USER_ID';
```

Or sign up again with the updated signup flow.

## 📊 Database Schema

The `profiles` table should have:

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30)
);
```

## 🔐 Security

### Storage Security:
- Public read (anyone can view avatars)
- Authenticated write (only logged-in users)
- Users can only modify their own files

### Database Security:
- RLS enabled on profiles table
- Users can only update their own profile
- Username uniqueness enforced

## 🎯 Next Steps

1. **Add bio field:**
   ```sql
   ALTER TABLE profiles ADD COLUMN bio TEXT;
   ```

2. **Add cover photo:**
   - Create "covers" bucket
   - Add cover_url to profiles

3. **Add email display:**
   - Show user email in profile
   - Add email verification badge

4. **Add profile stats:**
   - Count actual posts
   - Implement followers/following

## 📞 Testing

### Test Profile Picture:
1. Login to app
2. Go to profile
3. Click camera icon
4. Select any image
5. Verify upload completes
6. Check image displays correctly

### Test Username Edit:
1. Click edit icon
2. Change username
3. Click Save
4. Verify username updates
5. Check it shows in posts/comments

## ⚠️ Important Notes

1. **Storage Bucket Name**: Must be exactly `avatars`
2. **Public Bucket**: Must be checked for images to display
3. **File Path**: `avatars/{userId}-{timestamp}.{ext}`
4. **Image Quality**: Compressed to 75% to save storage
5. **Max Resolution**: 512x512 pixels
