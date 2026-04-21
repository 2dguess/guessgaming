import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// **SET composite index only** —
/// [en/.../set/overview](https://www.set.or.th/en/market/index/set/overview) or TH equivalent.
/// Never uses `/set50/`, `/set100/`, or other index overview URLs.
///
/// ### Where to read numbers (Inspect Element — classes may change after site updates)
///
/// **SET Last (index points)** — typical locations:
/// - `.index-content` → `.set-index` **table**, first row / **Last** column (market summary).
///
/// **Value (M.Baht)** — typical locations:
/// - `.market-turnover`, `.value`, or market summary row labeled **Value (M.Baht)** / TH **มูลค่า (ล้านบาท)**.
///
/// Parser order: try these structures first, then fall back to legacy `stock-info` hero +
/// `quote-market-cost` (current SSR).
///
/// Review [set.or.th](https://www.set.or.th) terms of use for automated access.
class SetOrThService {
  SetOrThService._();

  static const String setOverviewEn =
      'https://www.set.or.th/en/market/index/set/overview';

  static const String setOverviewTh =
      'https://www.set.or.th/th/market/index/set/overview';

  static bool _isSetCompositeOverviewUrl(Uri uri) {
    final p = uri.path.replaceAll(RegExp(r'/+$'), '');
    return p == '/en/market/index/set/overview' ||
        p == '/th/market/index/set/overview';
  }

  static const _browserUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// Legacy hero **Last** — `<h1>SET</h1>` then `stock-info` (works on current SSR).
  static final RegExp _setOnlyHeroLastRe = RegExp(
    r'quote-info-left-name-symbols[\s\S]*?<h1[^>]*>\s*SET\s*</h1>[\s\S]*?quote-info-left-values[\s\S]{0,4000}?<div class="value[^"]*\bstock-info"[^>]*>\s*([\d,]+\.\d+)',
    caseSensitive: false,
  );

  /// Exact target from screenshot: dark hero block number under "SET Index Series".
  static final RegExp _setHeroDarkPanelRe = RegExp(
    r'SET\s*Index\s*Series[\s\S]{0,2500}?quote-info-left-values[\s\S]{0,1800}?stock-info"[^>]*>\s*([\d,]+\.\d+)',
    caseSensitive: false,
  );

  /// Exact inspect target: `<div class="value ... stock-info">1,490.00</div>`.
  static final RegExp _setFromStockInfoValueRe = RegExp(
    r'<div[^>]*class="[^"]*\bvalue\b[^"]*\bstock-info\b[^"]*"[^>]*>\s*([\d,]+\.\d+)\s*</div>',
    caseSensitive: false,
  );

  /// New mobile/header markup (from inspect screenshots):
  /// `<div class="market-set ..."><span class="marquee-active">1,485.18</span>`
  static final RegExp _setFromMarketSetMarqueeRe = RegExp(
    r'market-set[^"]*"[^>]*>[\s\S]{0,600}?<span[^>]*class="[^"]*\bmarquee-active\b[^"]*"[^>]*>\s*([\d,]+\.\d+)\s*</span>',
    caseSensitive: false,
  );

  /// Legacy **Value (M.Baht)** — `quote-market-cost` block.
  static final RegExp _valueQuoteMarketCostRe = RegExp(
    r'quote-market-cost[^>]*>([\s\S]*?)<span[^>]*>\s*([\d,]+\.\d+)\s*</span>',
    caseSensitive: false,
  );

  /// Exact target from screenshot: lower strip `Value (M.Baht)` beside Open/High/Low.
  static final RegExp _valueFromLowerStripRe = RegExp(
    r'quote-market[\s\S]{0,4000}?Value\s*\(M\.Baht\)[\s\S]{0,500}?<span[^>]*>\s*([\d,]+\.\d+)\s*</span>',
    caseSensitive: false,
  );

  /// Exact inspect target: `div.quote-market-cost.border-0 > span.ms-2`.
  static final RegExp _valueFromQuoteMarketCostBorder0Re = RegExp(
    r'quote-market-cost\s+border-0[^>]*>[\s\S]{0,250}?<span[^>]*class="[^"]*\bms-2\b[^"]*"[^>]*>\s*([\d,]+\.\d+)\s*</span>',
    caseSensitive: false,
  );

  /// New mobile/header markup (from inspect screenshots):
  /// `<div class="section-three ..."><span class="marquee-active fs-14px">49,182.68</span>`
  static final RegExp _valueFromSectionThreeMarqueeRe = RegExp(
    r'section-three[^"]*"[^>]*>[\s\S]{0,900}?<span[^>]*class="[^"]*\bmarquee-active\b[^"]*"[^>]*>\s*([\d,]+\.\d+)\s*</span>',
    caseSensitive: false,
  );

  static double? _parseThaiNumber(String raw) {
    final s = raw.replaceAll(',', '').trim();
    return double.tryParse(s);
  }

  /// Robust helper: find [classToken] block and pick first plausible decimal number nearby.
  static double? _firstNumberNearClass(
    String html,
    String classToken, {
    int window = 1400,
    double minValue = 0,
    double maxValue = 1.0e12,
  }) {
    final lower = html.toLowerCase();
    final idx = lower.indexOf(classToken.toLowerCase());
    if (idx < 0) return null;
    final end = min(idx + window, html.length);
    final slice = html.substring(idx, end);
    for (final m in RegExp(r'([\d,]+\.\d+)').allMatches(slice)) {
      final v = _parseThaiNumber(m.group(1)!);
      if (v != null && v >= minValue && v <= maxValue) return v;
    }
    return null;
  }

  /// Find first decimal number after a specific label token.
  static double? _firstNumberAfterLabel(
    String html,
    RegExp labelRe, {
    int window = 900,
    double minValue = 0,
    double maxValue = 1.0e12,
  }) {
    final m = labelRe.firstMatch(html);
    if (m == null) return null;
    final start = m.end;
    final end = min(start + window, html.length);
    final slice = html.substring(start, end);
    for (final n in RegExp(r'([\d,]+\.\d+)').allMatches(slice)) {
      final v = _parseThaiNumber(n.group(1)!);
      if (v != null && v >= minValue && v <= maxValue) return v;
    }
    return null;
  }

  /// Prefer `.set-index` table: row mentioning **Last** (not “Last Update”), first plausible index.
  static double? _tryLastFromSetIndexTable(String html) {
    final tableInner = _extractTableBodyByClass(html, 'set-index');
    if (tableInner == null) return null;

    final trRe = RegExp(r'<tr\b[^>]*>([\s\S]*?)</tr>', caseSensitive: false);
    for (final m in trRe.allMatches(tableInner)) {
      final row = m.group(1)!;
      final lower = row.toLowerCase();
      if (!lower.contains('last') ||
          lower.contains('last update') ||
          lower.contains('% change')) {
        continue;
      }
      for (final nm in RegExp(r'([\d,]+\.\d+)').allMatches(row)) {
        final v = _parseThaiNumber(nm.group(1)!);
        if (v != null && v >= 200 && v <= 6000) {
          return v;
        }
      }
    }
    return null;
  }

  /// Scoped search: optional `.index-content` wrapper, then `.set-index` table; else full HTML.
  static double? _tryLastFromIndexContent(String html) {
    final idx = html.toLowerCase().indexOf('index-content');
    final slice = idx >= 0
        ? html.substring(idx, min(idx + 80000, html.length))
        : html;
    return _tryLastFromSetIndexTable(slice) ?? _tryLastFromSetIndexTable(html);
  }

  static String? _extractTableBodyByClass(String html, String classToken) {
    final re = RegExp(
      '<table[^>]*class="[^"]*\\b$classToken\\b[^"]*"[^>]*>([\\s\\S]*?)</table>',
      caseSensitive: false,
    );
    final m = re.firstMatch(html);
    return m?.group(1);
  }

  /// Prefer `.market-turnover` block, then **Value (M.Baht)** / TH label + number.
  static double? _tryValueFromMarketTurnover(String html) {
    final lower = html.toLowerCase();
    final start = lower.indexOf('market-turnover');
    if (start < 0) return null;
    final slice = html.substring(start, min(start + 15000, html.length));

    final labelValue = RegExp(
      r'(?:Value\s*\(M\.Baht\)|มูลค่า\s*\(ล้านบาท\))[\s\S]{0,800}?([\d,]+\.\d+)',
      caseSensitive: false,
    ).firstMatch(slice);
    if (labelValue != null) {
      return _parseThaiNumber(labelValue.group(1)!);
    }
    return null;
  }

  static double? _parseLastFallback(String html) {
    // Exact inspector hit (highest priority).
    final stockInfo = _setFromStockInfoValueRe.firstMatch(html);
    if (stockInfo != null) {
      final v = _parseThaiNumber(stockInfo.group(1)!);
      if (v != null) return v;
    }

    // Highest-priority: dark panel hero number (user-circled target).
    final hero = _setHeroDarkPanelRe.firstMatch(html);
    if (hero != null) {
      final v = _parseThaiNumber(hero.group(1)!);
      if (v != null) return v;
    }

    // Highest-priority: number immediately after "Last" label in header strip.
    final fromLastLabel = _firstNumberAfterLabel(
      html,
      RegExp(r'>\s*Last\s*<', caseSensitive: false),
      window: 1200,
      minValue: 200,
      maxValue: 6000,
    );
    if (fromLastLabel != null) return fromLastLabel;

    // Screenshot selector: `div.market-set ... span.marquee-active`.
    final near = _firstNumberNearClass(
      html,
      'market-set',
      window: 1600,
      minValue: 200,
      maxValue: 6000,
    );
    if (near != null) return near;

    final m2 = _setFromMarketSetMarqueeRe.firstMatch(html);
    if (m2 != null) {
      final v2 = _parseThaiNumber(m2.group(1)!);
      if (v2 != null) return v2;
    }
    final m = _setOnlyHeroLastRe.firstMatch(html);
    if (m == null) return null;
    return _parseThaiNumber(m.group(1)!);
  }

  static double? _parseValueFallback(String html) {
    // Exact inspector hit (highest priority).
    final border0 = _valueFromQuoteMarketCostBorder0Re.firstMatch(html);
    if (border0 != null) {
      final v = _parseThaiNumber(border0.group(1)!);
      if (v != null) return v;
    }

    // Highest-priority: lower strip Value (M.Baht) in quote-market (user-circled target).
    final lower = _valueFromLowerStripRe.firstMatch(html);
    if (lower != null) {
      final v = _parseThaiNumber(lower.group(1)!);
      if (v != null) return v;
    }

    // Highest-priority: number immediately after "Value (M.Baht)" / TH label in header strip.
    final fromValueLabel = _firstNumberAfterLabel(
      html,
      RegExp(r'(?:Value\s*\(M\.Baht\)|มูลค่า\s*\(ล้านบาท\))', caseSensitive: false),
      window: 1600,
      minValue: 100,
      maxValue: 1.0e9,
    );
    if (fromValueLabel != null) return fromValueLabel;

    // Screenshot selector: `div.section-three ... span.marquee-active.fs-14px`.
    final near = _firstNumberNearClass(
      html,
      'section-three',
      window: 2200,
      minValue: 100,
      maxValue: 1.0e9,
    );
    if (near != null) return near;

    final m2 = _valueFromSectionThreeMarqueeRe.firstMatch(html);
    if (m2 != null) {
      final v2 = _parseThaiNumber(m2.group(1)!);
      if (v2 != null) return v2;
    }
    final m = _valueQuoteMarketCostRe.firstMatch(html);
    if (m == null) return null;
    return _parseThaiNumber(m.group(2)!);
  }

  /// `set_value` = SET **Last**; `set_index` = **Value (M.Baht)** (million baht).
  static Future<Map<String, dynamic>?> fetchSetIndexOverview() async {
    return await _fetchOverview(setOverviewEn) ??
        await _fetchOverview(setOverviewTh);
  }

  static Future<Map<String, dynamic>?> _fetchOverview(String pageUrl) async {
    try {
      final uri = Uri.parse(pageUrl);
      if (!_isSetCompositeOverviewUrl(uri)) {
        return null;
      }
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _browserUa,
          'Accept': 'text/html,application/xhtml+xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9,th;q=0.8',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final html = response.body;

      // Priority per user-provided inspect targets:
      // - Last: `div.market-set span.marquee-active`
      // - Value: `div.section-three span.marquee-active.fs-14px`
      final setValue = _parseLastFallback(html) ?? _tryLastFromIndexContent(html);
      final setIndex =
          _parseValueFallback(html) ?? _tryValueFromMarketTurnover(html);

      if (setValue == null || setIndex == null) {
        return null;
      }

      if (setValue < 200 || setValue > 6000 || setIndex < 100) {
        return null;
      }

      if (kDebugMode) {
        debugPrint('setValue: $setValue');
        debugPrint('setIndex: $setIndex');
      }

      return {
        'set_value': setValue,
        'set_index': setIndex,
        'timestamp': DateTime.now(),
      };
    } catch (_) {
      return null;
    }
  }
}
