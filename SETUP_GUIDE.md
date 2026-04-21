# Setup Guide - Gaming App

Complete step-by-step guide to set up and run the application.

## Prerequisites

- Flutter SDK 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart SDK (comes with Flutter)
- Android Studio / Xcode (for mobile development)
- Supabase account ([Sign up](https://supabase.com))

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Fill in project details:
   - Name: `gaming-app`
   - Database Password: (create a strong password)
   - Region: (choose closest to your users)
4. Wait for project to be created (~2 minutes)

## Step 2: Setup Database

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Copy the entire contents of `supabase_schema.sql` from this project
4. Paste into the SQL editor
5. Click "Run" to execute
6. Verify tables were created: Go to **Table Editor** and check for:
   - profiles
   - posts
   - post_likes
   - comments
   - bets
   - wallets
   - missions
   - user_missions

## Step 3: Setup Storage

1. In Supabase dashboard, go to **Storage**
2. Click "Create a new bucket"
3. Bucket name: `posts`
4. Make it **Public** (check the box)
5. Click "Create bucket"

## Step 4: Get Supabase Credentials

1. In Supabase dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

## Step 5: Configure Flutter App

1. Open the project in your IDE
2. Open `lib/config/supabase_config.dart`
3. Replace the placeholder values:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_PROJECT_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';
  
  // ... rest of the file
}
```

**Example:**
```dart
static const String supabaseUrl = 'https://abcdefgh.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

## Step 6: Install Dependencies

Open terminal in project directory and run:

```bash
flutter pub get
```

This will install all required packages:
- supabase_flutter
- flutter_riverpod
- go_router
- cached_network_image
- image_picker
- etc.

## Step 7: Run the App

### For Android:

1. Connect Android device or start emulator
2. Run:
```bash
flutter run
```

### For iOS:

1. Open `ios/` folder in Xcode
2. Select target device
3. Run:
```bash
flutter run
```

### For Web:

```bash
flutter run -d chrome
```

## Step 8: Create Test Account

1. App will open to login screen
2. Click "Sign Up"
3. Enter:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `password123`
4. Click "Sign Up"
5. Go back to login and sign in

## Step 9: Test Features

### Test Social Feed:
1. Click "Create Post" button
2. Write something and optionally add a photo
3. Click "Post"
4. Try liking and commenting

### Test Betting:
1. Tap "Bet" in bottom navigation
2. Enter a 2-digit number (00-99)
3. Enter amount (minimum 100)
4. Click "Submit Bet"
5. Check "History" tab

### Test Missions:
1. Tap "Missions" in bottom navigation
2. Click "Claim Now" on Daily Login mission
3. Check your balance increased

## Troubleshooting

### Issue: "Invalid API key"
**Solution**: Double-check your Supabase credentials in `supabase_config.dart`

### Issue: "Table does not exist"
**Solution**: Make sure you ran the entire `supabase_schema.sql` file in Supabase SQL Editor

### Issue: "Storage bucket not found"
**Solution**: Create the `posts` bucket in Supabase Storage and make it public

### Issue: "Cannot upload image"
**Solution**: 
1. Check Storage bucket is public
2. Check RLS policies on Storage bucket
3. Go to Storage → Policies → New Policy → Allow all operations for authenticated users

### Issue: "Flutter command not found"
**Solution**: Install Flutter SDK and add to PATH ([Flutter Installation Guide](https://flutter.dev/docs/get-started/install))

### Issue: Build errors
**Solution**: 
```bash
flutter clean
flutter pub get
flutter run
```

## Development Tips

### Hot Reload
Press `r` in terminal while app is running to hot reload changes

### Debug Mode
App runs in debug mode by default. For release build:
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### View Logs
```bash
flutter logs
```

### Database Queries
Test queries in Supabase SQL Editor before implementing in app

### Storage Management
Monitor storage usage in Supabase dashboard → Storage

## Next Steps

1. **Customize UI**: Edit theme in `lib/config/theme.dart`
2. **Add Features**: Follow the architecture in `ARCHITECTURE.md`
3. **Deploy**: See deployment guide for production setup
4. **Monitor**: Set up error tracking and analytics

## Production Checklist

Before deploying to production:

- [ ] Change Supabase credentials to production project
- [ ] Enable email confirmation for signups
- [ ] Set up proper RLS policies
- [ ] Configure Storage policies
- [ ] Add error tracking (Sentry, Firebase Crashlytics)
- [ ] Set up analytics
- [ ] Test on multiple devices
- [ ] Optimize images and assets
- [ ] Enable ProGuard/R8 for Android
- [ ] Set up CI/CD pipeline

## Support

If you encounter issues:
1. Check this guide again
2. Review `README.md` for architecture details
3. Check Supabase documentation
4. Open an issue on GitHub

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Go Router Documentation](https://pub.dev/packages/go_router)
