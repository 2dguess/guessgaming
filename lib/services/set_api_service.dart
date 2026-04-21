import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/cdn_config.dart';
import '../config/rapidapi_config.dart';
import 'set_or_th_service.dart';

/// SET / Value live feed: **set.or.th** first, then RapidAPI → Yahoo → Alpha Vantage (see below).
class SETAPIService {
  static const String _apiKey = 'demo';
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  static const String _yahooBaseUrl =
      'https://query1.finance.yahoo.com/v8/finance/chart';

  static double? _parseNumber(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.replaceAll(',', '').trim();
      return double.tryParse(s);
    }
    return null;
  }

  static double? _pickField(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (!map.containsKey(k)) continue;
      final d = _parseNumber(map[k]);
      if (d != null) return d;
    }
    return null;
  }

  static int? _parseIntLoose(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final s = v.replaceAll(RegExp(r'[^0-9]'), '');
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    return null;
  }

  static int? _pickIntField(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (!map.containsKey(k)) continue;
      final n = _parseIntLoose(map[k]);
      if (n != null && n >= 0 && n <= 99) return n;
    }
    return null;
  }

  static Map<String, double>? _tryParseSetIndexPair(Map<String, dynamic> m) {
    final setValue = _pickField(m, [
      'set',
      'SET',
      'set_value',
      'setValue',
      'set_price',
      'Set',
      'stock_set',
      'stock_SET',
      'set_stock',
    ]);
    final setIndex = _pickField(m, [
      'index',
      'INDEX',
      'value',
      'Value',
      'set_index',
      'setIndex',
      'index_value',
      'stock_index',
      'market_index',
      'total_value',
    ]);
    if (setValue == null || setIndex == null) return null;
    return {'set_value': setValue, 'set_index': setIndex};
  }

  static Map<String, double>? _parseThaiLottoSetIndexMap(
    Map<String, dynamic> json,
  ) {
    final candidates = <Map<String, dynamic>>[json];
    for (final k in [
      'data',
      'result',
      'response',
      'live',
      'realtime',
      'morning',
      'evening',
      'market',
      'stock',
    ]) {
      final v = json[k];
      if (v is Map<String, dynamic>) candidates.add(v);
    }

    for (final m in candidates) {
      final pair = _tryParseSetIndexPair(m);
      if (pair != null) return pair;
    }
    return null;
  }

  static int? _parseThaiLotto2dOverride(Map<String, dynamic> json) {
    final candidates = <Map<String, dynamic>>[json];
    for (final k in ['data', 'result', 'response', 'live', 'realtime']) {
      final v = json[k];
      if (v is Map<String, dynamic>) candidates.add(v);
    }
    for (final m in candidates) {
      final d = _pickIntField(m, [
        '2d',
        'twod',
        'two_digit',
        'twoDigit',
        'result_2d',
        'result2d',
        'stock_2d',
        'nike',
        'digit',
      ]);
      if (d != null) return d;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchSETFromSetOrThOverview() async {
    return SetOrThService.fetchSetIndexOverview();
  }

  Future<Map<String, dynamic>?> fetchSETFromRapidApiThaiLotto() async {
    if (!RapidApiConfig.hasRapidApiKey) return null;

    try {
      final uri = Uri.https(
        RapidApiConfig.thaiLottoHost,
        RapidApiConfig.thaiLottoSetIndexPath,
      );
      final response = await http.get(
        uri,
        headers: {
          'X-RapidAPI-Key': RapidApiConfig.rapidApiKey,
          'X-RapidAPI-Host': RapidApiConfig.thaiLottoHost,
        },
      );

      if (response.statusCode != 200) {
        print('RapidAPI Thai Lotto: HTTP ${response.statusCode}');
        return null;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final msg = decoded['message']?.toString().toLowerCase() ?? '';
      if (msg.contains('not subscribed') || msg.contains('invalid api')) {
        print('RapidAPI Thai Lotto: $msg');
        return null;
      }

      final pair = _parseThaiLottoSetIndexMap(decoded);
      if (pair == null) {
        print('RapidAPI Thai Lotto: could not parse set/index from JSON');
        return null;
      }

      final twoOverride = _parseThaiLotto2dOverride(decoded);

      return {
        'set_value': pair['set_value']!,
        'set_index': pair['set_index']!,
        'timestamp': DateTime.now(),
        if (twoOverride != null) 'result_digit_override': twoOverride,
      };
    } catch (e) {
      print('RapidAPI Thai Lotto error: $e');
      return null;
    }
  }

  Future<double?> _yahooRegularMarketPrice(String symbolPath) async {
    try {
      final url = Uri.parse(
        '$_yahooBaseUrl/$symbolPath?interval=1m&range=1d',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final chart = data['chart'] as Map<String, dynamic>?;
      final results = chart?['result'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final result = results[0] as Map<String, dynamic>;
      final meta = result['meta'] as Map<String, dynamic>?;
      if (meta == null) return null;

      final live = meta['regularMarketPrice'] as num?;
      final prev = meta['previousClose'] as num?;
      final price = (live ?? prev)?.toDouble();
      return price;
    } catch (e) {
      print('Yahoo price error ($symbolPath): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSETPricesFromYahoo() async {
    try {
      final set50 = await _yahooRegularMarketPrice('%5ESET50.BK');
      final setIdx = await _yahooRegularMarketPrice('%5ESET.BK');

      if (setIdx == null && set50 == null) return null;

      double setValue;
      double setIndex;
      if (set50 != null && setIdx != null) {
        setValue = set50;
        setIndex = setIdx;
      } else if (setIdx != null) {
        setIndex = setIdx;
        setValue = double.parse((setIndex / 26.9).toStringAsFixed(2));
      } else {
        setValue = set50!;
        setIndex = double.parse((setValue * 26.9).toStringAsFixed(2));
      }

      return {
        'set_value': setValue,
        'set_index': setIndex,
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      print('fetchSETPricesFromYahoo: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSETIndexFromAlphaVantage() async {
    try {
      final url = Uri.parse(
        '$_baseUrl?function=GLOBAL_QUOTE&symbol=SET.BKK&apikey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quote = data['Global Quote'];

        if (quote != null) {
          final price = double.parse(quote['05. price']);
          final volume = double.parse(quote['06. volume']);

          return {
            'set_value': price,
            'set_index': volume,
            'timestamp': DateTime.now(),
          };
        }
      }

      print('Alpha Vantage API error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching SET index from Alpha Vantage: $e');
      return null;
    }
  }

  Map<String, dynamic> generateMockSETData() {
    final random = Random();
    const baseSet = 1250.0;
    const baseIndex = 16000.0;

    final setValue = baseSet + (random.nextDouble() * 50 - 25);
    final setIndex = baseIndex + (random.nextDouble() * 1000 - 500);

    return {
      'set_value': double.parse(setValue.toStringAsFixed(2)),
      'set_index': double.parse(setIndex.toStringAsFixed(2)),
      'timestamp': DateTime.now(),
    };
  }

  int calculateResultDigit(double setValue, double setIndex) {
    final a = _myanmar2dLastDigitOfSet(setValue);
    final b = _myanmar2dDigitBeforeDecimal(setIndex);
    return a * 10 + b;
  }

  static int _myanmar2dLastDigitOfSet(double setValue) {
    final s = setValue.toStringAsFixed(2);
    final only = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (only.isEmpty) return 0;
    return int.parse(only[only.length - 1]);
  }

  Future<Map<String, dynamic>?> fetchLiveFromCdn() async {
    if (!CdnConfig.hasCdnBaseUrl) return null;
    try {
      final response = await http
          .get(Uri.parse(CdnConfig.latestUrl()))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;
      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final setValue = _pickField(decoded, ['set_value', 'setValue', 'set']);
      final setIndex = _pickField(decoded, ['set_index', 'setIndex', 'index']);
      final resultDigit = _pickIntField(decoded, [
        'result_digit',
        'resultDigit',
        'digit',
        '2d',
      ]);
      if (setValue == null || setIndex == null || resultDigit == null) {
        return null;
      }
      return {
        'set_value': setValue,
        'set_index': setIndex,
        'result_digit': resultDigit,
        'timestamp': DateTime.now(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchTodayFromCdn() async {
    if (!CdnConfig.hasCdnBaseUrl) return null;
    try {
      final response = await http
          .get(Uri.parse(CdnConfig.todayUrl()))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;
      final decoded = json.decode(response.body);

      final dynamic rawList = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic> ? decoded['results'] : null);
      if (rawList is! List) return null;

      final rows = <Map<String, dynamic>>[];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          rows.add(item);
        } else if (item is Map) {
          rows.add(Map<String, dynamic>.from(item));
        }
      }
      if (rows.isEmpty) return null;
      return rows;
    } catch (_) {
      return null;
    }
  }

  static int _myanmar2dDigitBeforeDecimal(double value) {
    final s = value.abs().toStringAsFixed(2);
    final dot = s.indexOf('.');
    if (dot <= 0) {
      return value.toInt().abs() % 10;
    }
    return int.parse(s[dot - 1]);
  }

  Map<String, dynamic> _withResultDigit(Map<String, dynamic> data) {
    final setValue = data['set_value'] as double;
    final setIndex = data['set_index'] as double;
    final override = data['result_digit_override'] as int?;
    final resultDigit =
        (override != null && override >= 0 && override <= 99)
            ? override
            : calculateResultDigit(setValue, setIndex);
    return {
      'set_value': setValue,
      'set_index': setIndex,
      'result_digit': resultDigit,
      'timestamp': data['timestamp'],
    };
  }

  /// Live UI polling: **set.or.th only** for exact parity with website numbers.
  /// If unavailable, return null so UI shows `--` (no mixed-source values).
  Future<Map<String, dynamic>?> fetchLiveSETData() async {
    final data = await fetchSETFromSetOrThOverview();
    if (data == null) return null;
    return _withResultDigit(data);
  }

  /// Persist / scheduled jobs: same chain; **mock** only if everything fails.
  Future<Map<String, dynamic>> fetchSETData() async {
    var data = await fetchSETFromSetOrThOverview();

    if (data == null) {
      data = await fetchSETFromRapidApiThaiLotto();
    }

    if (data == null) {
      data = await fetchSETPricesFromYahoo();
    }

    if (data == null) {
      data = await fetchSETIndexFromAlphaVantage();
    }

    if (data == null) {
      print('Using mock SET data');
      data = generateMockSETData();
    }

    return _withResultDigit(data);
  }
}
