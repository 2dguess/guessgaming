# Gaming App - 2D Social + Betting Platform

A Flutter-based social media and betting application with Supabase backend, optimized for 10M users.

## Features

- **Social Feed**: Facebook-style posts with likes, comments, and nested replies
- **2D Betting System**: Place bets on 2-digit numbers (00-99) with real-time leaderboard
- **Mission & Rewards**: Daily login missions to earn coins
- **Wallet System**: Virtual currency management
- **Real-time Updates**: Live trending digits and post interactions

## Tech Stack

- **Frontend**: Flutter 3.0+
- **State Management**: Riverpod 2.5+
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **Routing**: go_router
- **Image Handling**: cached_network_image, image_picker

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Supabase account

### 2. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor and run the schema from `supabase_schema.sql`
3. Enable Storage and create a bucket named `posts` (make it public)
4. Get your project URL and anon key from Settings > API

### 3. Flutter Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update Supabase credentials in `lib/config/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Database Schema

### Tables

- **profiles**: User profiles with username and avatar
- **posts**: Social media posts with content and images
- **post_likes**: Like relationships between users and posts
- **comments**: Comments and nested replies on posts
- **bets**: User betting records
- **wallets**: User coin balances
- **missions**: Available missions (daily login, etc.)
- **user_missions**: User mission claim history

### Key Functions

- `get_trending_digits()`: Returns top 10 most bet digits
- `complete_daily_mission(mission_id)`: Claims daily mission rewards
- `place_bet(digit, amount)`: Places a bet with balance validation

## Performance Optimizations

### For 10M Users

1. **Database Indexing**:
   - Composite indexes on frequently queried columns
   - Partial indexes for recent data (hot data)
   - Covering indexes to avoid table lookups

2. **Caching Strategy**:
   - Client-side caching with `cached_network_image`
   - Materialized views for trending digits
   - Profile caching (30 min TTL)

3. **Query Optimization**:
   - Pagination with `LIMIT` and `OFFSET`
   - Selective column fetching
   - Optimistic UI updates for likes/comments

4. **Connection Pooling**:
   - Use Supabase connection pooler (PgBouncer)
   - Appropriate pool size based on load

5. **Storage Optimization**:
   - Image compression and resizing
   - CDN for static assets
   - WebP format for better compression

6. **Real-time Considerations**:
   - Limited real-time subscriptions
   - Client-side throttling
   - Broadcast for non-personalized updates

## Project Structure

```
lib/
├── main.dart
├── config/
│   ├── supabase_config.dart
│   ├── router.dart
│   └── theme.dart
├── models/
│   ├── app_post.dart
│   ├── app_profile.dart
│   ├── comment.dart
│   ├── bet.dart
│   ├── mission.dart
│   └── wallet.dart
├── state/
│   ├── auth/
│   │   └── auth_controller.dart
│   ├── feed/
│   │   └── feed_controller.dart
│   ├── comments/
│   │   └── comments_controller.dart
│   ├── betting/
│   │   └── betting_controller.dart
│   └── mission/
│       └── mission_controller.dart
├── pages/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── signup_page.dart
│   ├── feed/
│   │   ├── feed_page.dart
│   │   ├── post_detail_page.dart
│   │   └── compose_post_page.dart
│   ├── betting/
│   │   └── betting_page.dart
│   └── mission/
│       └── mission_page.dart
├── widgets/
│   ├── post_card.dart
│   ├── comment_card.dart
│   └── like_button.dart
└── utils/
    └── time_ago.dart
```

## Key Features Implementation

### Optimistic UI

Likes and comments update immediately on the client side before server confirmation, providing instant feedback.

### Nested Comments

Comments support unlimited nesting levels with visual indentation and reply threading.

### Like Animation

Heart icon scales from 1.0 → 1.3 → 1.0 (300ms) when tapped.

### Time Formatting

All timestamps show relative time (e.g., "2h ago", "3d ago").

### Wallet System

- Initial balance: 10,000 coins
- Daily mission reward: 5,000 coins
- Minimum bet: 100 coins
- Atomic transactions for balance updates

## Security

- Row Level Security (RLS) enabled on all tables
- Users can only view/modify their own data
- Server-side validation for all transactions
- Secure authentication with Supabase Auth

## Future Enhancements

1. **Partitioning**: Partition posts and bets tables by date
2. **Redis Caching**: Add Redis for frequently accessed data
3. **Push Notifications**: Real-time notifications for likes/comments
4. **Admin Panel**: Manage users, bets, and missions
5. **Analytics**: User behavior tracking and insights
6. **Live Streaming**: Add 2D live draw viewer

## License

MIT License

## Support

For issues and questions, please open an issue on GitHub.
