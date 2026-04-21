# Thai SET API Integration

## Overview
This document explains how the app integrates with the Thai Stock Exchange (SET) API to fetch real-time data for the 2D lottery system.

## Draw Times (Myanmar 2D Style)
The app fetches SET data at 4 scheduled times daily:
- **12:01 PM** - Main draw
- **4:30 PM** - Evening draw
- **9:30 AM** - Morning draw (Modern/Internet)
- **2:00 PM** - Afternoon draw (Modern/Internet)

## API Integration

### Primary API: Yahoo Finance
- Endpoint: `https://query1.finance.yahoo.com/v8/finance/chart/^SET.BK`
- Returns: SET Index value in real-time
- Free and reliable

### Fallback API: Alpha Vantage
- Endpoint: `https://www.alphavantage.co/query`
- API Key required (free tier available)
- Used when Yahoo Finance is unavailable

### Mock Data Fallback
If both APIs fail, the system generates realistic mock data to ensure the app continues functioning.

## Result Calculation

### Big Number Formula
The 2D result is calculated from SET data:

```
SET Value: 1269.26
SET Index: 32021.39

Step 1: Get SET decimal second digit
  1269.26 → .26 → 6

Step 2: Get Index integer last digit
  32021.39 → 32021 → 1

Result: 61
```

### Implementation
```dart
int calculateResultDigit(double setValue, double setIndex) {
  // SET: decimal part second digit
  final setDecimal = ((setValue % 1) * 100).toInt(); // .26 → 26
  final setDigit = setDecimal % 10; // 26 % 10 = 6
  
  // Index: integer part last digit
  final indexInt = setIndex.toInt(); // 32021
  final indexDigit = indexInt % 10; // 32021 % 10 = 1
  
  return setDigit * 10 + indexDigit; // 6*10 + 1 = 61
}
```

## Auto-Fetch Logic

### Periodic Checking
The app checks every 30 seconds if it's time to fetch new data:

```dart
// In home_page.dart
Timer.periodic(const Duration(seconds: 30), (timer) async {
  await ref.read(setIndexControllerProvider.notifier).autoFetchIfScheduled();
});
```

### Draw Time Detection
```dart
Future<void> autoFetchIfScheduled() async {
  final now = DateTime.now();
  final drawTimes = ['09:30', '12:01', '14:00', '16:30'];
  
  for (final drawTime in drawTimes) {
    // Check if within 5 minutes of draw time
    if (now.hour == drawHour && (now.minute - drawMinute).abs() <= 5) {
      // Fetch only if not already fetched
      if (!alreadyFetched) {
        await fetchAndSaveNewResult(drawTime: drawTime);
      }
    }
  }
}
```

## Animation Logic

### Before Draw Time (30 minutes)
Numbers animate with a "blinking" effect:
- SET and Index values change rapidly (80ms interval)
- Big number digits animate individually
- Status shows "DRAWING..."

### At Draw Time
- Animation stops
- Real API data is fetched
- Result is calculated and displayed
- Status shows "RESULT"

### Animation Timing
```dart
void _updateAnimationStatus() {
  final now = DateTime.now();
  bool shouldAnimate = false;
  
  for (final draw in _drawTimes) {
    final drawMinutes = drawHour * 60 + drawMinute;
    final animationStartMinutes = drawMinutes - 30; // 30 min before
    
    if (currentMinutes >= animationStartMinutes && currentMinutes < drawMinutes) {
      shouldAnimate = true;
      break;
    }
  }
  
  setState(() {
    _isAnimating = shouldAnimate;
  });
}
```

## UI Layout

### Big Number Display
```
┌─────────────────────┐
│        96           │ ← Green color (#4CAF50)
│ ✓ Updated: 2026-... │
└─────────────────────┘
```

### Draw Cards (Red Gradient)
```
┌─────────────────────────────┐
│        12:01 PM             │
│  SET    Value      2D       │
│ ─────────────────────────── │
│ 1269.26  32021.39   96      │
└─────────────────────────────┘
```

### Modern/Internet Cards
```
┌─────────────────────────────────┐
│ 9:30 AM  Modern  Internet  TW   │
│           57      20      82    │
└─────────────────────────────────┘
```

## Database Schema

### set_index_history Table
```sql
CREATE TABLE set_index_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  draw_date DATE NOT NULL,
  draw_time TIME NOT NULL,
  set_value DECIMAL(10, 2) NOT NULL,
  set_index DECIMAL(10, 2) NOT NULL,
  result_digit INTEGER NOT NULL,
  source TEXT DEFAULT 'api',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(draw_date, draw_time)
);
```

## Testing

### Manual Data Insert
```sql
INSERT INTO set_index_history (draw_date, draw_time, set_value, set_index, result_digit, source)
VALUES 
  (CURRENT_DATE, '12:01:00', 1269.26, 32021.39, 61, 'manual'),
  (CURRENT_DATE, '16:30:00', 1484.99, 39896.36, 96, 'manual');
```

### Check Today's Results
```sql
SELECT * FROM set_index_history 
WHERE draw_date = CURRENT_DATE 
ORDER BY draw_time DESC;
```

## Error Handling

### API Failures
1. Try Yahoo Finance
2. Fallback to Alpha Vantage
3. Use mock data if both fail
4. Log errors for debugging

### Display Logic
- If no data: Show `--` placeholders
- If animating: Show animated numbers
- If data available: Show actual values

## Future Enhancements

### Cloud Functions (Recommended)
Set up Supabase Edge Functions or AWS Lambda to:
- Fetch SET data at exact draw times
- Store results automatically
- Reduce client-side API calls
- Ensure consistent data for all users

### Cron Job Setup
```javascript
// Supabase Edge Function example
Deno.serve(async (req) => {
  const setData = await fetchSETData();
  await supabase.from('set_index_history').insert({
    draw_date: new Date().toISOString().split('T')[0],
    draw_time: '12:01:00',
    set_value: setData.setValue,
    set_index: setData.setIndex,
    result_digit: calculateResult(setData),
    source: 'auto'
  });
  
  return new Response('OK', { status: 200 });
});
```

### Schedule with Supabase Cron
```sql
-- Run at 12:01 PM daily
SELECT cron.schedule(
  'fetch-set-1201',
  '1 12 * * *',
  $$
  SELECT net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/fetch-set-data',
    headers := '{"Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
  );
  $$
);
```

## Monitoring

### Check Last Fetch
```dart
final lastFetch = ref.watch(setIndexControllerProvider).lastFetchTime;
print('Last fetch: $lastFetch');
```

### Debug Logs
- API calls are logged to console
- Errors are captured in state
- Check terminal for fetch status

## Support

For issues or questions:
1. Check console logs for API errors
2. Verify Supabase connection
3. Test API endpoints manually
4. Review draw time logic
