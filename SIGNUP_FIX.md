# Signup Username Fix

## 🐛 Problem

When creating a new account:
- Username is entered during signup
- But profile shows "Unknown"
- Username not saved to database

## 🔍 Root Cause

The `profiles` table is missing an INSERT policy. Users cannot create their profile during signup because RLS (Row Level Security) blocks the INSERT operation.

## ✅ Solution

Add INSERT policy to profiles table.

### Quick Fix (SQL Editor):

Go to **Supabase Dashboard → SQL Editor** and run:

```sql
-- Add INSERT policy for profiles table
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
```

### Verify Policies:

```sql
-- Check all policies on profiles table
SELECT * FROM pg_policies WHERE tablename = 'profiles';
```

You should see 3 policies:
1. ✅ Anyone can view profiles (SELECT)
2. ✅ Users can insert own profile (INSERT) ← **NEW**
3. ✅ Users can update own profile (UPDATE)

## 🧪 Test the Fix

### 1. Create a new test account:

- Logout from current account
- Go to Signup page
- Enter:
  - Username: `testuser123`
  - Email: `test@example.com`
  - Password: `password123`
- Click "Sign Up"

### 2. Login with new account:

- Email: `test@example.com`
- Password: `password123`

### 3. Check profile:

- Go to Profile page
- Username should show: `testuser123` ✅
- Not "Unknown" ❌

## 🔧 Fix Existing Accounts

If you already created accounts before the fix, their profiles are missing. You can:

### Option 1: Manual Update (SQL):

```sql
-- Find your user ID
SELECT id, email FROM auth.users;

-- Create profile manually (replace with your actual ID and username)
INSERT INTO profiles (id, username)
VALUES ('YOUR_USER_ID_HERE', 'YourDesiredUsername')
ON CONFLICT (id) DO UPDATE SET username = 'YourDesiredUsername';
```

### Option 2: Automatic for Current User:

```sql
-- Create profile for currently logged-in user
INSERT INTO profiles (id, username)
VALUES (auth.uid(), 'YourUsername')
ON CONFLICT (id) DO UPDATE SET username = 'YourUsername';
```

### Option 3: Re-signup:

1. Delete old account (or use different email)
2. Sign up again with the fix applied
3. Username will save correctly

## 📋 Complete Profiles Table Policies

Your profiles table should have these RLS policies:

```sql
-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy 1: Public read
CREATE POLICY "Anyone can view profiles" ON profiles
  FOR SELECT USING (true);

-- Policy 2: Users can create their own profile (REQUIRED FOR SIGNUP)
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy 3: Users can update their own profile
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);
```

## 🎯 How Signup Works Now

1. User fills signup form (username, email, password)
2. App calls `signUp()` function
3. Supabase creates auth user
4. App inserts profile with username ✅ (now works with INSERT policy)
5. User can login
6. Profile shows correct username ✅

## ⚠️ Important Notes

### RLS Policies:
- **SELECT**: Anyone can view profiles (public)
- **INSERT**: Only authenticated users can insert their own profile
- **UPDATE**: Only authenticated users can update their own profile

### Security:
- Users can only create profile for themselves (`auth.uid() = id`)
- Users cannot create profiles for other users
- Username uniqueness is enforced by database constraint

## 🐛 Troubleshooting

### Still showing "Unknown":

1. **Check if profile exists:**
   ```sql
   SELECT * FROM profiles WHERE id = auth.uid();
   ```

2. **Check if INSERT policy exists:**
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename = 'profiles' AND cmd = 'INSERT';
   ```

3. **Try manual profile creation:**
   ```sql
   INSERT INTO profiles (id, username)
   VALUES (auth.uid(), 'YourUsername')
   ON CONFLICT (id) DO UPDATE SET username = 'YourUsername';
   ```

### Signup fails with error:

- Check Supabase logs (Dashboard → Logs)
- Verify email is unique
- Verify username is 3-30 characters
- Check password is at least 6 characters

### Profile not refreshing:

- Logout and login again
- Hot restart app (`Shift + R`)
- Clear app data and restart

## 📞 Testing Checklist

- [ ] Run INSERT policy SQL command
- [ ] Verify policy exists in database
- [ ] Create new test account
- [ ] Check username shows correctly
- [ ] Test profile picture upload
- [ ] Test username edit
- [ ] Verify username shows in posts/comments

## 🎉 Success

After applying the fix:
- ✅ New signups save username correctly
- ✅ Profile shows actual username, not "Unknown"
- ✅ Username appears in posts and comments
- ✅ Users can edit username later
- ✅ Users can upload profile picture
