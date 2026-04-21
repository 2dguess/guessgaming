# Architecture Documentation

## System Architecture for 10M Users

### Overview

This document outlines the architecture decisions and optimizations made to support 10 million users with good performance and low cost using Supabase.

## 1. Database Architecture

### Schema Design

#### Normalization Strategy
- **Profiles**: Separate table for user data (normalized)
- **Posts**: Main content table with denormalized counts (likes_count, comments_count)
- **Post Likes**: Junction table with composite unique constraint
- **Comments**: Self-referential table for nested replies
- **Bets**: Transaction table with status tracking
- **Wallets**: Single row per user for balance management

#### Denormalization Decisions
- **Like/Comment Counts**: Stored in posts table to avoid expensive COUNT queries
- **Profile Data**: Joined with posts/comments for display (cached on client)
- **Trending Digits**: Materialized view for performance

### Indexing Strategy

#### Primary Indexes
```sql
-- Posts: Most common queries
CREATE INDEX idx_posts_created_at_desc ON posts(created_at DESC);
CREATE INDEX idx_posts_user_id ON posts(user_id);

-- Partial index for hot data (last 7 days)
CREATE INDEX idx_posts_recent ON posts(created_at DESC) 
  WHERE created_at > NOW() - INTERVAL '7 days';

-- Composite index for likes lookup
CREATE INDEX idx_post_likes_post_user ON post_likes(post_id, user_id);

-- Comments with parent relationship
CREATE INDEX idx_comments_post_id ON comments(post_id, created_at);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id) 
  WHERE parent_comment_id IS NOT NULL;
```

#### Why These Indexes?
1. **created_at DESC**: Feed queries always sort by newest first
2. **Partial indexes**: 80% of queries target recent data (hot data)
3. **Composite indexes**: Avoid multiple index lookups
4. **Conditional indexes**: Save space on sparse data (parent comments)

### Query Optimization

#### Pagination
```dart
// Good: Efficient pagination with LIMIT/OFFSET
.range(offset, offset + pageSize - 1)

// Bad: Loading all data
.select() // No limit
```

#### Selective Fetching
```dart
// Good: Only fetch needed columns
.select('post_id, content, likes_count, profiles(username, avatar_url)')

// Bad: Fetch everything
.select('*')
```

#### Prepared Statements
- Supabase client automatically uses prepared statements
- Reduces parsing overhead for repeated queries

## 2. Caching Strategy

### Client-Side Caching

#### Image Caching
```dart
// Using cached_network_image
CachedNetworkImage(
  imageUrl: url,
  cacheManager: CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  ),
)
```

#### Profile Caching
- Cache user profiles for 30 minutes
- Reduces repeated profile queries
- Invalidate on profile update

#### Post Feed Caching
- Cache feed for 5 minutes
- Pull-to-refresh invalidates cache
- Optimistic updates for likes/comments

### Server-Side Caching

#### Materialized Views
```sql
-- Trending digits cached view
CREATE MATERIALIZED VIEW trending_digits_cache AS
SELECT digit, COUNT(*) as bet_count
FROM bets
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY digit
ORDER BY bet_count DESC
LIMIT 10;

-- Refresh every 5 minutes via cron job
```

#### Redis Integration (Future)
```
User Profiles: 30 min TTL
Trending Digits: 5 min TTL
Popular Posts: 5 min TTL
```

## 3. Performance Optimizations

### Optimistic UI Updates

#### Like System
```dart
// 1. Update UI immediately
state = state.copyWith(
  posts: updatedPosts,
);

// 2. Send to server
await client.from('post_likes').insert(...);

// 3. Rollback on error
if (error) {
  state = state.copyWith(posts: originalPosts);
}
```

Benefits:
- Instant feedback (< 50ms)
- Better user experience
- Reduced perceived latency

### Database Triggers

#### Automatic Count Updates
```sql
-- Trigger: Update likes_count automatically
CREATE TRIGGER trigger_update_post_likes_count
AFTER INSERT OR DELETE ON post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();
```

Benefits:
- Consistent counts without manual updates
- Atomic operations
- No race conditions

### Connection Pooling

#### Supabase Configuration
```
Max Connections: 100 (default)
Pool Mode: Transaction (PgBouncer)
Timeout: 15 seconds
```

#### Client Configuration
```dart
// Use singleton instance
final client = Supabase.instance.client;

// Avoid creating multiple instances
```

## 4. Scalability Considerations

### Horizontal Scaling

#### Database Sharding (Future)
- Shard by user_id for posts/bets
- Keep profiles in single database
- Use Supabase read replicas

#### CDN for Static Assets
```
Images → Supabase Storage → CDN
- Automatic image optimization
- Global edge caching
- Reduced origin load
```

### Vertical Scaling

#### Database Resources
```
10M Users Estimate:
- Storage: ~500GB (posts + images)
- RAM: 16GB (for indexes + cache)
- CPU: 4-8 cores
- IOPS: 10,000+
```

#### Supabase Pricing Tiers
- **Pro**: Up to 1M users (~$25/month)
- **Team**: Up to 5M users (~$599/month)
- **Enterprise**: 10M+ users (custom pricing)

### Load Distribution

#### Read/Write Ratio
```
Typical Social App:
- Reads: 90% (feed, posts, comments)
- Writes: 10% (new posts, likes, bets)

Optimization:
- Read replicas for feed queries
- Master for writes only
- Cache frequently read data
```

## 5. Cost Optimization

### Storage Costs

#### Image Optimization
```dart
// Compress images before upload
await _imagePicker.pickImage(
  maxWidth: 1920,
  maxHeight: 1920,
  imageQuality: 85, // 85% quality
);
```

#### Storage Cleanup
- Delete old images (> 1 year)
- Use lifecycle policies
- Convert to WebP format

### Database Costs

#### Query Optimization
- Use indexes to avoid full table scans
- Limit result sets (pagination)
- Avoid N+1 queries

#### Data Retention
```sql
-- Archive old bets (> 6 months)
CREATE TABLE bets_archive (LIKE bets);

-- Move old data monthly
INSERT INTO bets_archive 
SELECT * FROM bets 
WHERE created_at < NOW() - INTERVAL '6 months';

DELETE FROM bets 
WHERE created_at < NOW() - INTERVAL '6 months';
```

### Bandwidth Costs

#### Image CDN
- Serve images from CDN (cheaper than origin)
- Use responsive images (different sizes)
- Lazy loading for off-screen images

#### API Calls
- Batch requests where possible
- Use real-time subscriptions sparingly
- Implement client-side throttling

## 6. Security Architecture

### Row Level Security (RLS)

#### Policy Examples
```sql
-- Users can only view own bets
CREATE POLICY "Users can view own bets" ON bets
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only update own wallet
CREATE POLICY "Users can update own wallet" ON wallets
  FOR UPDATE USING (auth.uid() = user_id);
```

### Input Validation

#### Server-Side Checks
```sql
-- Bet amount validation
CHECK (amount >= 100 AND amount <= 100000)

-- Digit range validation
CHECK (digit >= 0 AND digit <= 99)

-- Balance validation
CHECK (balance >= 0)
```

#### Client-Side Validation
```dart
// Validate before sending to server
if (amount < 100) {
  return 'Minimum bet is 100 coins';
}
```

## 7. Monitoring & Observability

### Database Monitoring

#### Key Metrics
```sql
-- Enable pg_stat_statements
CREATE EXTENSION pg_stat_statements;

-- Monitor slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 20;
```

#### Alerts
- Query time > 1 second
- Connection pool > 80% full
- Disk usage > 80%
- Error rate > 1%

### Application Monitoring

#### Client-Side Metrics
- Screen load time
- API response time
- Error rates
- Crash reports

#### Server-Side Metrics
- Request rate (req/sec)
- Database connections
- Storage usage
- Bandwidth usage

## 8. Future Improvements

### Phase 1 (0-1M Users)
- ✅ Basic indexing
- ✅ Client-side caching
- ✅ Optimistic UI
- ✅ RLS policies

### Phase 2 (1M-5M Users)
- [ ] Redis caching layer
- [ ] Read replicas
- [ ] CDN integration
- [ ] Image optimization pipeline

### Phase 3 (5M-10M Users)
- [ ] Database sharding
- [ ] Microservices architecture
- [ ] Advanced monitoring
- [ ] Auto-scaling

### Phase 4 (10M+ Users)
- [ ] Multi-region deployment
- [ ] Custom CDN
- [ ] GraphQL federation
- [ ] ML-based recommendations

## Conclusion

This architecture is designed to scale from 0 to 10M users with minimal changes. The key principles are:

1. **Start Simple**: Use Supabase's built-in features
2. **Optimize Early**: Add indexes and caching from day one
3. **Monitor Everything**: Track metrics to identify bottlenecks
4. **Scale Gradually**: Add complexity only when needed

With proper implementation, this architecture can support:
- **10M users**
- **100K daily active users**
- **1M posts per day**
- **10M API requests per day**
- **< 200ms average response time**
- **< $1000/month hosting cost** (with optimization)
