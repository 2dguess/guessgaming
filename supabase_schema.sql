-- ============================================
-- GAMING APP DATABASE SCHEMA (OPTIMIZED FOR 10M USERS)
-- ============================================
--
-- USE ONLY on an EMPTY database (new Supabase project or local reset).
-- If tables already exist you will get: ERROR 42P07 relation "profiles" already exists.
-- For an existing project use incremental files under supabase/ (e.g. fix_post_likes_count_rls.sql).
--
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30)
);

CREATE INDEX idx_profiles_username ON profiles(username);

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view profiles" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- 2. POSTS TABLE (OPTIMIZED)
-- ============================================
CREATE TABLE posts (
  post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  likes_count INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT content_not_empty CHECK (char_length(content) > 0)
);

-- Optimized indexes for 10M users
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at_desc ON posts(created_at DESC);
CREATE INDEX idx_posts_likes_count ON posts(likes_count DESC);

-- RLS Policies
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view posts" ON posts
  FOR SELECT USING (true);

CREATE POLICY "Users can create posts" ON posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts" ON posts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts" ON posts
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 3. POST LIKES TABLE (OPTIMIZED)
-- ============================================
CREATE TABLE post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_post_like UNIQUE(post_id, user_id)
);

-- Composite index for fast lookups
CREATE INDEX idx_post_likes_post_user ON post_likes(post_id, user_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);

-- RLS Policies
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view likes" ON post_likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like posts" ON post_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike posts" ON post_likes
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 4. COMMENTS TABLE (OPTIMIZED FOR NESTED REPLIES)
-- ============================================
CREATE TABLE comments (
  comment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES comments(comment_id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT content_not_empty CHECK (char_length(content) > 0)
);

-- Optimized indexes
CREATE INDEX idx_comments_post_id ON comments(post_id, created_at);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);

-- RLS Policies
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view comments" ON comments
  FOR SELECT USING (true);

CREATE POLICY "Users can create comments" ON comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON comments
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- 5. BETS TABLE (OPTIMIZED)
-- ============================================
CREATE TABLE bets (
  bet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  digit INTEGER NOT NULL CHECK (digit >= 0 AND digit <= 99),
  amount INTEGER NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'win', 'lose')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Optimized indexes
CREATE INDEX idx_bets_user_id ON bets(user_id, created_at DESC);
CREATE INDEX idx_bets_digit ON bets(digit, created_at DESC);
CREATE INDEX idx_bets_status ON bets(status);

-- RLS Policies
ALTER TABLE bets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bets" ON bets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create bets" ON bets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 6. WALLETS TABLE (OPTIMIZED)
-- ============================================
CREATE TABLE wallets (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wallets_updated_at ON wallets(updated_at);

-- RLS Policies
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallet" ON wallets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own wallet" ON wallets
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- 7. ADMIN WALLET TABLE
-- ============================================
CREATE TABLE admin_wallet (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  balance INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert initial admin wallet
INSERT INTO admin_wallet (balance) VALUES (1000000000);

-- RLS Policies (only admin can access)
ALTER TABLE admin_wallet ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Only admin can view admin wallet" ON admin_wallet
  FOR SELECT USING (false);

CREATE POLICY "Only admin can update admin wallet" ON admin_wallet
  FOR UPDATE USING (false);

-- ============================================
-- 8. SET INDEX HISTORY TABLE (for 2D Live Results)
-- ============================================
CREATE TABLE set_index_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  draw_date DATE NOT NULL,
  draw_time TIME NOT NULL,
  set_value DECIMAL(10,2) NOT NULL,
  set_index DECIMAL(10,2) NOT NULL,
  result_digit INTEGER NOT NULL CHECK (result_digit >= 0 AND result_digit <= 99),
  source TEXT DEFAULT 'api',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_draw_datetime UNIQUE(draw_date, draw_time)
);

CREATE INDEX idx_set_history_date ON set_index_history(draw_date DESC, draw_time DESC);
CREATE INDEX idx_set_history_created ON set_index_history(created_at DESC);

-- RLS Policies
ALTER TABLE set_index_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view SET history" ON set_index_history
  FOR SELECT USING (true);

CREATE POLICY "Only authenticated users can insert SET history" ON set_index_history
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================
-- 9. MISSIONS TABLE
-- ============================================
CREATE TABLE missions (
  mission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  reward_amount INTEGER NOT NULL CHECK (reward_amount > 0),
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'once')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default daily free coins mission
INSERT INTO missions (title, description, reward_amount, frequency)
VALUES ('Daily Free Coins', 'Claim 5,000 free coins once per day (00:01 - 23:59)', 5000, 'daily');

-- RLS Policies
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view missions" ON missions
  FOR SELECT USING (true);

-- ============================================
-- 10. USER MISSIONS TABLE
-- ============================================
CREATE TABLE user_missions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES missions(mission_id) ON DELETE CASCADE,
  last_claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_mission UNIQUE(user_id, mission_id)
);

CREATE INDEX idx_user_missions_user ON user_missions(user_id, mission_id);

-- RLS Policies
ALTER TABLE user_missions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own missions" ON user_missions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can claim missions" ON user_missions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own missions" ON user_missions
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- DATABASE FUNCTIONS (OPTIMIZED)
-- ============================================

-- Function: Top digits by how many *distinct users* picked them (last 7 days).
-- SECURITY DEFINER: aggregates all users' bets (RLS would otherwise hide other rows).
CREATE OR REPLACE FUNCTION get_trending_digits()
RETURNS TABLE(digit INTEGER, people_count BIGINT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    b.digit,
    COUNT(DISTINCT b.user_id)::BIGINT AS people_count
  FROM public.bets b
  INNER JOIN public.profiles p ON p.id = b.user_id
    AND COALESCE(p.is_admin, FALSE) = FALSE
  WHERE b.created_at > CURRENT_TIMESTAMP - INTERVAL '7 days'
  GROUP BY b.digit
  ORDER BY COUNT(DISTINCT b.user_id) DESC, b.digit ASC
  LIMIT 10;
END;
$$;

-- Function: Complete daily mission (atomic transaction)
CREATE OR REPLACE FUNCTION complete_daily_mission(p_mission_id UUID)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_reward INTEGER;
  v_last_claimed TIMESTAMPTZ;
  v_can_claim BOOLEAN;
  v_new_balance INTEGER;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Get mission reward
  SELECT reward_amount INTO v_reward 
  FROM missions 
  WHERE mission_id = p_mission_id;
  
  IF v_reward IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Mission not found');
  END IF;
  
  -- Check last claim time
  SELECT last_claimed_at INTO v_last_claimed
  FROM user_missions
  WHERE user_id = v_user_id AND mission_id = p_mission_id;
  
  -- Check if can claim (once per day, resets at 00:01)
  -- User can claim if:
  -- 1. Never claimed before (v_last_claimed IS NULL)
  -- 2. Last claim was on a different day (DATE(v_last_claimed) < DATE(CURRENT_TIMESTAMP))
  v_can_claim := (v_last_claimed IS NULL) OR 
                 (DATE(v_last_claimed) < DATE(CURRENT_TIMESTAMP));
  
  IF NOT v_can_claim THEN
    -- Calculate next claim time (tomorrow at 00:01)
    RETURN json_build_object(
      'success', false, 
      'error', 'Already claimed today',
      'next_claim_at', (DATE(CURRENT_TIMESTAMP) + INTERVAL '1 day')::TIMESTAMP + INTERVAL '1 minute'
    );
  END IF;
  
  -- Update or insert claim record
  INSERT INTO user_missions (user_id, mission_id, last_claimed_at)
  VALUES (v_user_id, p_mission_id, CURRENT_TIMESTAMP)
  ON CONFLICT (user_id, mission_id)
  DO UPDATE SET last_claimed_at = CURRENT_TIMESTAMP;
  
  -- Add coins to wallet (atomic)
  INSERT INTO wallets (user_id, balance, updated_at)
  VALUES (v_user_id, v_reward, NOW())
  ON CONFLICT (user_id)
  DO UPDATE SET 
    balance = wallets.balance + v_reward,
    updated_at = NOW()
  RETURNING balance INTO v_new_balance;
  
  RETURN json_build_object(
    'success', true, 
    'reward', v_reward,
    'new_balance', v_new_balance
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Place bet (with balance check)
CREATE OR REPLACE FUNCTION place_bet(p_digit INTEGER, p_amount INTEGER)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_current_balance INTEGER;
  v_new_balance INTEGER;
BEGIN
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Validate input
  IF p_digit < 0 OR p_digit > 99 THEN
    RETURN json_build_object('success', false, 'error', 'Invalid digit (must be 0-99)');
  END IF;
  
  IF p_amount < 100 THEN
    RETURN json_build_object('success', false, 'error', 'Minimum bet is 100 coins');
  END IF;
  
  -- Get current balance
  SELECT balance INTO v_current_balance
  FROM wallets
  WHERE user_id = v_user_id;
  
  IF v_current_balance IS NULL THEN
    v_current_balance := 0;
  END IF;
  
  -- Check sufficient balance
  IF v_current_balance < p_amount THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Insufficient balance',
      'current_balance', v_current_balance,
      'required', p_amount
    );
  END IF;
  
  -- Deduct from user wallet
  UPDATE wallets
  SET balance = balance - p_amount, updated_at = CURRENT_TIMESTAMP
  WHERE user_id = v_user_id
  RETURNING balance INTO v_new_balance;
  
  -- Add to admin wallet
  UPDATE admin_wallet
  SET balance = balance + p_amount, updated_at = CURRENT_TIMESTAMP
  WHERE id = (SELECT id FROM admin_wallet LIMIT 1);
  
  -- Create bet
  INSERT INTO bets (user_id, digit, amount, status, created_at)
  VALUES (v_user_id, p_digit, p_amount, 'pending', CURRENT_TIMESTAMP);
  
  RETURN json_build_object(
    'success', true,
    'new_balance', v_new_balance,
    'bet_amount', p_amount,
    'digit', p_digit
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Process bet win (×80 payout)
CREATE OR REPLACE FUNCTION process_bet_win(p_winning_digit INTEGER)
RETURNS JSON AS $$
DECLARE
  v_total_payout INTEGER := 0;
  v_winner_count INTEGER := 0;
  v_bet_record RECORD;
  v_payout_amount INTEGER;
  v_admin_balance INTEGER;
BEGIN
  -- Validate input
  IF p_winning_digit < 0 OR p_winning_digit > 99 THEN
    RETURN json_build_object('success', false, 'error', 'Invalid digit (must be 0-99)');
  END IF;
  
  -- Get admin wallet balance
  SELECT balance INTO v_admin_balance
  FROM admin_wallet
  WHERE id = (SELECT id FROM admin_wallet LIMIT 1);
  
  -- Process all winning bets (status = 'pending')
  FOR v_bet_record IN 
    SELECT bet_id, user_id, amount 
    FROM bets 
    WHERE digit = p_winning_digit AND status = 'pending'
  LOOP
    -- Calculate payout (×80)
    v_payout_amount := v_bet_record.amount * 80;
    v_total_payout := v_total_payout + v_payout_amount;
    v_winner_count := v_winner_count + 1;
    
    -- Update bet status to 'win'
    UPDATE bets
    SET status = 'win'
    WHERE bet_id = v_bet_record.bet_id;
    
    -- Add payout to user wallet
    INSERT INTO wallets (user_id, balance, updated_at)
    VALUES (v_bet_record.user_id, v_payout_amount, CURRENT_TIMESTAMP)
    ON CONFLICT (user_id)
    DO UPDATE SET 
      balance = wallets.balance + v_payout_amount,
      updated_at = CURRENT_TIMESTAMP;
  END LOOP;
  
  -- Update all other pending bets to 'lose'
  UPDATE bets
  SET status = 'lose'
  WHERE status = 'pending' AND digit != p_winning_digit;
  
  -- Deduct total payout from admin wallet
  IF v_total_payout > 0 THEN
    UPDATE admin_wallet
    SET balance = balance - v_total_payout, updated_at = CURRENT_TIMESTAMP
    WHERE id = (SELECT id FROM admin_wallet LIMIT 1);
  END IF;
  
  RETURN json_build_object(
    'success', true,
    'winning_digit', p_winning_digit,
    'winner_count', v_winner_count,
    'total_payout', v_total_payout,
    'admin_balance_before', v_admin_balance,
    'admin_balance_after', v_admin_balance - v_total_payout
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================

-- Trigger: Update post likes count
-- SECURITY DEFINER: liker is not the post author, so RLS on `posts` would block a plain UPDATE.
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET likes_count = likes_count + 1 WHERE post_id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE post_id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trigger_update_post_likes_count
AFTER INSERT OR DELETE ON post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Trigger: Update post comments count
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comments_count = comments_count + 1 WHERE post_id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE post_id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_comments_count
AFTER INSERT OR DELETE ON comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Trigger: Update post updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_posts_updated_at
BEFORE UPDATE ON posts
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- INITIAL WALLET FOR NEW USERS
-- ============================================

CREATE OR REPLACE FUNCTION create_initial_wallet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO wallets (user_id, balance, updated_at)
  VALUES (NEW.id, 10000, CURRENT_TIMESTAMP);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_initial_wallet
AFTER INSERT ON profiles
FOR EACH ROW EXECUTE FUNCTION create_initial_wallet();

-- ============================================
-- PERFORMANCE OPTIMIZATION SETTINGS
-- ============================================

-- Analyze tables for query optimization
ANALYZE profiles;
ANALYZE posts;
ANALYZE post_likes;
ANALYZE comments;
ANALYZE bets;
ANALYZE wallets;
ANALYZE missions;
ANALYZE user_missions;

-- ============================================
-- MATERIALIZED VIEW FOR TRENDING DIGITS (OPTIONAL)
-- ============================================

-- Note: Materialized views can be added later for optimization
-- For now, we use the get_trending_digits() function directly

-- ============================================
-- NOTES FOR 10M USERS OPTIMIZATION
-- ============================================

/*
1. INDEXING STRATEGY:
   - Composite indexes on frequently queried columns
   - Partial indexes for hot data (recent posts, pending bets)
   - Covering indexes to avoid table lookups

2. PARTITIONING (for scale):
   - Consider partitioning posts table by created_at (monthly)
   - Partition bets table by created_at (weekly)

3. CACHING:
   - Use Supabase Edge Functions with Redis for:
     * Trending digits (refresh every 5 minutes)
     * User profiles (30 minute TTL)
     * Popular posts (5 minute TTL)

4. CONNECTION POOLING:
   - Use Supabase connection pooler (PgBouncer)
   - Set appropriate pool size based on load

5. QUERY OPTIMIZATION:
   - Use LIMIT and OFFSET for pagination
   - Fetch only needed columns (SELECT specific columns)
   - Use prepared statements

6. REAL-TIME CONSIDERATIONS:
   - Limit real-time subscriptions to critical data
   - Use broadcast for non-personalized updates
   - Implement client-side throttling

7. STORAGE:
   - Use Supabase Storage with CDN for images
   - Implement image compression and resizing
   - Use WebP format for better compression

8. MONITORING:
   - Enable pg_stat_statements for query analysis
   - Monitor slow queries and add indexes
   - Set up alerts for high CPU/memory usage
*/
