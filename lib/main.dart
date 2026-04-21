import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'config/router.dart';
import 'config/theme.dart';
import 'config/supabase_config.dart';
import 'state/auth/auth_controller.dart';
import 'state/notifications/notifications_controller.dart';
import 'state/realtime/live_events_realtime.dart';
import 'widgets/bet_win_celebration_host.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  // Windows: ensure federated shared_preferences is bound before Supabase reads storage.
  // Avoids MissingPluginException(getAll) on plugins.flutter.io/shared_preferences.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    SharedPreferencesWindows.registerWith();
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await MobileAds.instance.initialize();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    ref.watch(liveEventsRealtimeBootstrapProvider);
    if (user != null) {
      ref.watch(notificationsRealtimeBootstrapProvider);
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Gaming App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      builder: (context, child) {
        return BetWinCelebrationHost(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
