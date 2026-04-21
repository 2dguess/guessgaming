# Gaming App - Recent Updates

## Database Schema Updates

### 1. Admin Wallet System
- Created `admin_wallet` table to manage house balance
- When users place bets, amount is added to admin wallet
- When users win, payout (×80) is deducted from admin wallet
- Initial admin balance: 1,000,000,000 coins

### 2. Bet Win Payout System
- Created `process_bet_win(p_winning_digit)` function
- Win payout: **×80** of bet amount
- Example: Bet 1000 coins → Win 80,000 coins
- All winning bets (matching digit) get paid out
- All other pending bets are marked as 'lose'

### 3. Daily Free Coins Mission
- Mission: "Daily Free Coins"
- Reward: 5,000 coins
- Frequency: Once per day (00:01 - 23:59)
- Resets automatically at midnight (00:01)
- Users cannot claim twice in the same day

### 4. Mission System for Admin
- Missions table supports multiple mission types
- Admin can add missions via Supabase dashboard:
  - Facebook post like/comment/share tasks
  - Watch ads tasks
  - Custom tasks with custom rewards
- Fields: `title`, `description`, `reward_amount`, `frequency`, `is_active`

## UI Updates

### Home Page
- Clean, simple design
- Top bar: "GAMING" title with notifications and profile icons
- Two main buttons: **FEED** and **BET**
- Feature cards showing app capabilities

### Multiple Bet Dialog
- Place up to 10 bets at once
- 2-digit validation (00-99)
- Check button validates all entries
- Send button appears only after successful validation
- Shows current balance
- Validates total amount against balance

### Missions Page
- Displays all active missions
- Shows "Daily Free Coins" mission (5000 coins)
- Claim button with countdown timer
- Real-time balance updates
- Cannot claim same mission twice per day

## Database Functions

### `complete_daily_mission(p_mission_id)`
- Validates user authentication
- Checks if mission can be claimed (once per day)
- Uses `DATE()` comparison for daily reset
- Adds reward to user wallet
- Returns success status and new balance

### `place_bet(p_digit, p_amount)`
- Validates digit (0-99) and amount (min 100)
- Checks user balance
- Deducts from user wallet
- Adds to admin wallet
- Creates bet record with 'pending' status

### `process_bet_win(p_winning_digit)`
- Finds all winning bets (matching digit, status='pending')
- Calculates payout (amount × 80)
- Updates bet status to 'win'
- Adds payout to user wallets
- Marks non-winning bets as 'lose'
- Deducts total payout from admin wallet
- Returns winner count and payout summary

## Top 10 Popular Digits
- Shows most bet digits (by bet count, not amount)
- Updated in real-time
- Displayed on Betting page
- Clickable to open bet dialog

## Next Steps for Admin

### To Add New Missions:
1. Go to Supabase Dashboard → SQL Editor
2. Run:
```sql
INSERT INTO missions (title, description, reward_amount, frequency, is_active)
VALUES ('Like Facebook Post', 'Like our Facebook post and earn 1000 coins', 1000, 'once', true);
```

### To Process Bet Results:
1. Determine winning digit (00-99)
2. Run in SQL Editor:
```sql
SELECT process_bet_win(23); -- Replace 23 with winning digit
```

### To View Admin Wallet Balance:
```sql
SELECT * FROM admin_wallet;
```

### To Manually Adjust Admin Wallet:
```sql
UPDATE admin_wallet 
SET balance = 1000000000, updated_at = NOW()
WHERE id = (SELECT id FROM admin_wallet LIMIT 1);
```

## Important Notes

1. **Daily Mission Reset**: Happens at 00:01 every day (server time)
2. **Bet Payout**: Always ×80 of bet amount
3. **Admin Wallet**: Must have sufficient balance for payouts
4. **Mission Frequency**: 
   - `daily`: Can claim once per day
   - `weekly`: Can claim once per week
   - `once`: Can claim only once ever
5. **Top 10 Popular**: Based on bet count, not total amount

## Testing Checklist

- [ ] Place single bet
- [ ] Place multiple bets (up to 10)
- [ ] Claim daily free coins mission
- [ ] Verify balance updates in real-time
- [ ] Check bet history
- [ ] Verify top 10 popular digits
- [ ] Test bet win payout (admin function)
- [ ] Verify admin wallet balance changes
- [ ] Test daily mission reset at midnight
- [ ] Verify cannot claim mission twice per day
