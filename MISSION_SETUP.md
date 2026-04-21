# Mission Setup Guide

## Problem: "No missions available" in Mission Page

This happens because the missions table is empty or the mission hasn't been created yet.

## Solution: Add Daily Free Coins Mission

Go to **Supabase Dashboard → SQL Editor** and run:

```sql
-- Check if missions table exists and has data
SELECT * FROM missions;

-- If empty, insert the Daily Free Coins mission
INSERT INTO missions (title, description, reward_amount, frequency)
VALUES ('Daily Free Coins', 'Claim 5,000 free coins once per day (00:01 - 23:59)', 5000, 'daily')
ON CONFLICT DO NOTHING;

-- Verify the mission was created
SELECT * FROM missions;
```

## Expected Result

After running the above SQL:
- Mission page should show "Daily Free Coins" mission
- Reward: 5,000 coins
- Users can claim once per day

## If Still Not Working

1. Check if `complete_daily_mission` function exists:
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'complete_daily_mission';
```

2. If function doesn't exist, run the complete schema from `supabase_schema.sql`

3. Check for errors in Flutter console when loading missions

## Adding More Missions (For Admin)

```sql
-- Example: Facebook Like Task
INSERT INTO missions (title, description, reward_amount, frequency)
VALUES ('Like Facebook Post', 'Like our Facebook post and earn 1,000 coins', 1000, 'once');

-- Example: Watch Ad Task
INSERT INTO missions (title, description, reward_amount, frequency)
VALUES ('Watch Ad', 'Watch a short ad and earn 500 coins', 500, 'daily');

-- Example: Share Post Task
INSERT INTO missions (title, description, reward_amount, frequency)
VALUES ('Share on Facebook', 'Share our post and earn 2,000 coins', 2000, 'once');
```

## Mission Frequency Options

- `'daily'` - Can claim once per day (resets at 00:01)
- `'weekly'` - Can claim once per week
- `'once'` - Can claim only once ever

## Verify Mission is Working

1. Hot reload the app (press 'r' in terminal)
2. Go to Missions page (Bet page → coin balance icon)
3. You should see "Daily Free Coins" mission
4. Click "Claim" button
5. Check that 5,000 coins are added to your balance
6. Try claiming again - should show "Available in X hours"
