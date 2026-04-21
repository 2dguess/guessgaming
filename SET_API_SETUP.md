# SET API Integration Guide

## 🎯 Overview

The app now automatically fetches real Thai SET Index data from external APIs and displays it on the home page with animated 2D results.

## 📊 Data Sources

### 1. **Yahoo Finance API** (Primary)
- **Symbol**: `^SET.BK` (Thai SET Index)
- **Endpoint**: `https://query1.finance.yahoo.com/v8/finance/chart/^SET.BK`
- **Pros**: Free, no API key required, reliable
- **Data**: Current price, volume, timestamp

### 2. **Alpha Vantage API** (Fallback)
- **Endpoint**: `https://www.alphavantage.co/query`
- **API Key**: Required (free tier: 5 requests/minute, 500/day)
- **Register**: https://www.alphavantage.co/support/#api-key
- **Pros**: Comprehensive financial data

### 3. **Mock Data** (Development/Demo)
- Generates realistic SET-like data
- Used when APIs are unavailable

## 🗄️ Database Schema

```sql
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
```

## 🚀 Setup Instructions

### Step 1: Update Database Schema

Go to **Supabase Dashboard → SQL Editor** and run:

```sql
-- Create SET index history table
CREATE TABLE IF NOT EXISTS set_index_history (
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

ALTER TABLE set_index_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view SET history" ON set_index_history
  FOR SELECT USING (true);

CREATE POLICY "Only authenticated users can insert SET history" ON set_index_history
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

The `http` package is already added to `pubspec.yaml`.

### Step 3: (Optional) Get Alpha Vantage API Key

1. Visit: https://www.alphavantage.co/support/#api-key
2. Register for free API key
3. Update `lib/services/set_api_service.dart`:

```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

### Step 4: Test the Integration

```bash
flutter run
```

## 📱 How It Works

### Automatic Data Flow:

1. **App Launch**: Loads today's results from database
2. **API Fetch**: Tries Yahoo Finance → Alpha Vantage → Mock data
3. **Calculate Digit**: Uses SET value + index to calculate 2D result
4. **Save to DB**: Stores result with timestamp
5. **Display**: Shows on home page with animations

### Manual Fetch (Admin):

```dart
// In Flutter app or admin panel
await ref.read(setIndexControllerProvider.notifier)
    .fetchAndSaveNewResult(drawTime: '12:01:00');
```

### Scheduled Auto-Fetch:

The controller checks for draw times:
- 09:30 AM
- 12:01 PM
- 02:00 PM
- 04:30 PM

Call `autoFetchIfScheduled()` periodically (e.g., every minute).

## 🧮 Result Digit Calculation

```dart
int calculateResultDigit(double setValue, double setIndex) {
  final setLastTwo = (setValue * 100).toInt() % 100;
  final indexLastTwo = (setIndex * 100).toInt() % 100;
  final sum = (setLastTwo + indexLastTwo) % 100;
  return sum;
}
```

**Example**:
- SET Value: 1267.37 → Last 2 digits: 37
- SET Index: 16362.53 → Last 2 digits: 53
- Result: (37 + 53) % 100 = 90

## 🎨 UI Features

### Home Page Display:
- **Big Animated Number**: Latest result with bounce/scale/rotate animations
- **Updated Time**: When the result was fetched
- **Today's Results**: Shows up to 2 recent draws with SET/Val values
- **Schedule Table**: Upcoming draw times

### Animations:
- Individual digit cards (blue & green gradients)
- Bounce effect from top
- Scale animation (elastic)
- Rotation effect
- Auto-repeat every 5 seconds

## 🔧 Admin Functions

### Manually Insert Result:

```sql
INSERT INTO set_index_history (draw_date, draw_time, set_value, set_index, result_digit, source)
VALUES ('2025-04-07', '12:01:00', 1267.37, 16362.53, 72, 'manual');
```

### View Today's Results:

```sql
SELECT * FROM set_index_history
WHERE draw_date = CURRENT_DATE
ORDER BY draw_time DESC;
```

### Fetch New Result (via API):

In Flutter:
```dart
final success = await ref.read(setIndexControllerProvider.notifier)
    .fetchAndSaveNewResult(drawTime: '16:30:00');
```

## 📊 API Response Examples

### Yahoo Finance:
```json
{
  "chart": {
    "result": [{
      "meta": {
        "regularMarketPrice": 1267.37,
        "previousClose": 1265.50
      },
      "indicators": {
        "quote": [{
          "volume": [16362530]
        }]
      }
    }]
  }
}
```

### Alpha Vantage:
```json
{
  "Global Quote": {
    "05. price": "1267.37",
    "06. volume": "16362530"
  }
}
```

## ⚠️ Important Notes

1. **Rate Limits**: 
   - Yahoo Finance: No official limit, but don't abuse
   - Alpha Vantage: 5 requests/minute (free tier)

2. **Fallback Strategy**: 
   - Always tries multiple sources
   - Falls back to mock data if all fail

3. **Data Accuracy**: 
   - Real SET data may have delays
   - Mock data is for demo purposes only

4. **Timezone**: 
   - All times are in local timezone
   - Adjust draw times for your target market

## 🎯 Next Steps

1. **Scheduled Jobs**: Set up cron jobs or Cloud Functions to auto-fetch at draw times
2. **Push Notifications**: Notify users when new results are available
3. **Historical Data**: Import past results for analysis
4. **Admin Panel**: Build UI for manual result entry
5. **Result Verification**: Cross-check with official sources

## 🐛 Troubleshooting

### No data showing:
```dart
// Check if data exists
final results = await Supabase.instance.client
    .from('set_index_history')
    .select()
    .eq('draw_date', '2025-04-07');
print(results);
```

### API errors:
- Check internet connection
- Verify API keys (for Alpha Vantage)
- Check rate limits
- Try mock data mode

### Animation not working:
- Ensure data has at least 2 digits
- Check console for errors
- Hot restart the app

## 📞 Support

For issues or questions about SET API integration, check:
- Flutter console logs
- Supabase dashboard logs
- API provider status pages
