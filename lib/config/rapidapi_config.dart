/// [Thai Lotto New API](https://rapidapi.com/pjk-dev1-pjk-dev-default/api/thai-lotto-new-api)
///
/// 1. Subscribe on RapidAPI and copy your **X-RapidAPI-Key**.
/// 2. In the playground, open the SET/index endpoint and copy **only the path**
///    after the host (e.g. `/get-something`) into [thaiLottoSetIndexPath].
/// 3. Run with a key (recommended):
///    `flutter run --dart-define=RAPIDAPI_KEY=your_key_here`
///    Or paste a non-empty default below for local dev only (do not commit real keys).
///
/// **SET live numbers:** အရင်ဆုံး **set.or.th** scrape၊ မရရင် RapidAPI၊ နောက်ဆုံး Yahoo/Alpha (သို့မဟုတ်
/// [liveStrictMyanmar2dParity] + key ရှိရင် Yahoo မသုံးပါ)။
class RapidApiConfig {
  static const String thaiLottoHost = 'thai-lotto-new-api.p.rapidapi.com';

  /// Path from RapidAPI playground for the endpoint that returns SET + index/value.
  /// If the app gets 404, replace this with the exact path shown in the playground.
  static const String thaiLottoSetIndexPath = '/set';

  static const String rapidApiKey = String.fromEnvironment(
    'RAPIDAPI_KEY',
    defaultValue: '',
  );

  static bool get hasRapidApiKey => rapidApiKey.isNotEmpty;

  /// When [rapidApiKey] is set: live polling uses **only** RapidAPI if true, so SET/Value
  /// are not mixed with Yahoo (which will not match Myanmar 2D/3D apps pixel-perfect).
  static const bool liveStrictMyanmar2dParity = bool.fromEnvironment(
    'MYANMAR_2D_LIVE_STRICT',
    defaultValue: true,
  );
}
