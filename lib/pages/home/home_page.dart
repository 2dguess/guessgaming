import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/set_index.dart';
import '../../utils/myanmar_market.dart';
import '../../state/auth/auth_controller.dart';
import '../../state/admin/admin_controller.dart';
import '../../widgets/notification_bell_button.dart';
import '../../state/set_index/set_index_controller.dart';
import '../../widgets/animated_digit.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'GAMING',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingS),
              child: Text(
                'Entertainment only. Score is virtual and has no cash value.',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.25,
                    ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          const NotificationBellButton(),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryLight,
              child: userProfile.when(
                data: (profile) => Text(
                  profile?.username[0].toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const Icon(Icons.person, size: 16),
              ),
            ),
            onPressed: () {
              final userId = ref.read(currentUserProvider)?.id;
              if (userId != null) {
                context.push('/profile/$userId');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingL),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/feed'),
                    icon: const Icon(Icons.feed, size: 24),
                    label: const Text(
                      'FEED',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandFeedCta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingL),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/picks'),
                    icon: const Icon(Icons.sports_esports, size: 24),
                    label: const Text(
                      '2D Play',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPlayCta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.paddingL),
              child: _Live2DResultViewer(),
            ),
          ),
        ],
      ),
    );
  }
}

// Live 2D Result Viewer Widget
class _Live2DResultViewer extends ConsumerStatefulWidget {
  const _Live2DResultViewer();

  @override
  ConsumerState<_Live2DResultViewer> createState() => _Live2DResultViewerState();
}

class _Live2DResultViewerState extends ConsumerState<_Live2DResultViewer> {
  /// Space below scroll content for a home banner ad (e.g. AdMob adaptive).
  static const double _bottomAdReserve = 100;

  Timer? _checkTimer;
  Timer? _clockTimer;
  bool _isAnimating = false;
  String _nextDrawTime = '';
  /// True after [deactivate] until [activate] resumes (route covered this widget).
  bool _wasDeactivated = false;

  /// For [dispose] only — [ref] is invalid after the element unmounts (Riverpod).
  ProviderContainer? _riverpodContainer;
  
  // Draw times - Myanmar 2D style
  final List<Map<String, String>> _drawTimes = [
    {'time': '12:01', 'label': '12:01 PM'},
    {'time': '16:30', 'label': '4:30 PM'},
    {'time': '09:30', 'label': '9:30 AM'},
    {'time': '14:00', 'label': '2:00 PM'},
  ];

  void _stopLocalTimers() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void _startLocalTimers() {
    _stopLocalTimers();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) return;
      _updateAnimationStatus();
      if (isMyanmarSetLiveFetchWindow()) {
        await ref.read(setIndexControllerProvider.notifier).autoFetchIfScheduled();
      }
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _syncLivePollingForWindow();
      setState(() {});
    });
  }

  /// Thai SET live poll only during MMT session windows; otherwise stop and drop live numbers.
  void _syncLivePollingForWindow() {
    if (!mounted) return;
    final notifier = ref.read(setIndexControllerProvider.notifier);
    notifier.checkBangkokDateRollover();
    if (isMyanmarSetLiveFetchWindow()) {
      notifier.startLivePolling();
    } else {
      notifier.stopLivePolling();
      // Keep frozen session snapshots for 12:01 / 4:30 cards until Bangkok midnight.
    }
  }

  void _resumeLiveViewer() {
    final setIndex = ref.read(setIndexControllerProvider.notifier);
    setIndex.setPushUiUpdates(true);
    _syncLivePollingForWindow();
    _startLocalTimers();
    _updateAnimationStatus();
    Future.microtask(() async {
      if (!mounted) return;
      final controller = ref.read(setIndexControllerProvider.notifier);
      await controller.loadTodayResults();
      if (!mounted) return;
      await controller.autoFetchIfScheduled();
    });
  }

  void _pauseLiveViewer() {
    _stopLocalTimers();
    final setIndex = ref.read(setIndexControllerProvider.notifier);
    setIndex.setPushUiUpdates(false);
    setIndex.stopLivePolling();
  }

  @override
  void initState() {
    super.initState();
    _resumeLiveViewer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _riverpodContainer ??= ProviderScope.containerOf(context);
  }

  @override
  void deactivate() {
    _wasDeactivated = true;
    _pauseLiveViewer();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    if (_wasDeactivated) {
      _wasDeactivated = false;
      _resumeLiveViewer();
    }
  }

  void _updateAnimationStatus() {
    // Draw times on Myanmar wall clock (aligned with MMT session windows).
    final now = myanmarWallClockNow();
    final currentMinutes = now.hour * 60 + now.minute;
    
    bool shouldAnimate = false;
    String nextDraw = '';
    
    // Check each draw time
    for (final draw in _drawTimes) {
      final parts = draw['time']!.split(':');
      final drawHour = int.parse(parts[0]);
      final drawMinute = int.parse(parts[1]);
      final drawMinutes = drawHour * 60 + drawMinute;
      
      // Animate 30 minutes before draw time
      final animationStartMinutes = drawMinutes - 30;
      
      if (currentMinutes >= animationStartMinutes && currentMinutes < drawMinutes) {
        shouldAnimate = true;
        nextDraw = draw['label']!;
        break;
      }
      
      // Set next draw time
      if (currentMinutes < drawMinutes) {
        nextDraw = draw['label']!;
        break;
      }
    }
    
    // If past all draws today, next is tomorrow 12:01 PM
    if (nextDraw.isEmpty) {
      nextDraw = 'Tomorrow 12:01 PM';
    }
    
    if (mounted) {
      setState(() {
        _isAnimating = shouldAnimate;
        _nextDrawTime = nextDraw;
      });
    }
  }

  @override
  void dispose() {
    _stopLocalTimers();
    final c = _riverpodContainer;
    if (c != null) {
      final setIndex = c.read(setIndexControllerProvider.notifier);
      setIndex.setPushUiUpdates(false);
      setIndex.stopLivePolling();
    }
    super.dispose();
  }

  static final NumberFormat _quoteFmt = NumberFormat('#,##0.00');

  Widget _wrapQuoteHardBlink(bool enabled, Widget child) {
    if (!enabled) {
      return child;
    }
    return QuoteFiguresBlink(child: child);
  }

  /// Light card + gradient top bar. [gradientBar] is usually one row: time + column titles.
  Widget _liveDrawShell({
    required bool alternateHeader,
    required Widget gradientBar,
    required Widget body,
  }) {
    final colors = AppTheme.brandLiveHeaderGradientColors(alternateHeader);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingL),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.brandLiveCardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.brandLiveCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandLiveCardShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.paddingS,
              horizontal: AppTheme.paddingM,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: gradientBar,
          ),
          body,
        ],
      ),
    );
  }

  static const TextStyle _drawGradientTimeStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.2,
  );
  static const TextStyle _drawGradientColStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xE6FFFFFF),
  );

  Widget _buildDrawCard({
    required String time,
    String? setValue,
    String? setIndex,
    String? resultDigit,
    required bool isAnimating,
    bool quoteHardBlink = false,
    bool alternateHeader = false,
  }) {
    final valueStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppTheme.textPrimary,
    );
    const emptyStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppTheme.textHint,
    );

    return _liveDrawShell(
      alternateHeader: alternateHeader,
      gradientBar: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _drawGradientTimeStyle,
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text('SET', style: _drawGradientColStyle),
          ),
          const Expanded(
            flex: 4,
            child: Text(
              'Value',
              textAlign: TextAlign.center,
              style: _drawGradientColStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brandLiveBadgeBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: const Text(
                  '2D',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandLiveBadgeFg,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.paddingM,
          AppTheme.paddingM,
          AppTheme.paddingM,
          AppTheme.paddingL,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(flex: 4, child: SizedBox.shrink()),
            Expanded(
              flex: 3,
              child: _wrapQuoteHardBlink(
                quoteHardBlink,
                setValue != null
                    ? (isAnimating
                        ? AnimatedNumberDisplay(
                            number: setValue,
                            isAnimating: true,
                            fontSize: 18,
                            textColor: AppTheme.textPrimary,
                          )
                        : Text(setValue, style: valueStyle))
                    : const Text('--', style: emptyStyle),
              ),
            ),
            Expanded(
              flex: 4,
              child: _wrapQuoteHardBlink(
                quoteHardBlink,
                setIndex != null
                    ? (isAnimating
                        ? AnimatedNumberDisplay(
                            number: setIndex,
                            isAnimating: true,
                            fontSize: 18,
                            textColor: AppTheme.textPrimary,
                          )
                        : Text(
                            setIndex,
                            textAlign: TextAlign.center,
                            style: valueStyle,
                          ))
                    : const Text(
                        '--',
                        textAlign: TextAlign.center,
                        style: emptyStyle,
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                resultDigit ?? '--',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: resultDigit != null
                      ? AppTheme.brandHeroDigit
                      : AppTheme.textHint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SetIndexResult? _rowForDraw(List<SetIndexResult> list, String timePrefix) {
    for (final r in list) {
      if (r.drawTime.startsWith(timePrefix)) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final setIndexState = ref.watch(setIndexControllerProvider);
    final results = setIndexState.todayResults;
    final latestResult = results.isNotEmpty ? results.first : null;

    final inSetSessionMmt = isMyanmarSetLiveFetchWindow();

    final row1201 = _rowForDraw(results, '12:01');
    final row1630 = _rowForDraw(results, '16:30');

    final mWall = myanmarWallClockNow();
    final showDash121 = myanmarShowDash121UntilMorningOpen(mWall);
    final anim121 = myanmarMorning121QuoteAnimationWindow(mWall);
    final showDash430 = myanmarShowDash430UntilAfternoonOpen(mWall);
    final anim430 = myanmarAfternoon430QuoteAnimationWindow(mWall);

    final dbDigit = latestResult?.resultDigit;

    int? heroDigit;
    if (showDash121) {
      heroDigit = null;
    } else if (anim121 && inSetSessionMmt) {
      heroDigit = setIndexState.morningLiveResultDigit ?? dbDigit;
    } else if (anim430 && inSetSessionMmt) {
      heroDigit = setIndexState.afternoonLiveResultDigit ?? dbDigit;
    } else {
      heroDigit = setIndexState.afternoonLiveResultDigit ??
          setIndexState.morningLiveResultDigit ??
          row1630?.resultDigit ??
          row1201?.resultDigit ??
          dbDigit;
    }

    String bigNumber = heroDigit != null
        ? heroDigit.toString().padLeft(2, '0')
        : '--';

    final DateTime? sessionUpdated = anim121
        ? setIndexState.morningLiveUpdatedAt
        : anim430
            ? setIndexState.afternoonLiveUpdatedAt
            : null;
    final updatedLabel = inSetSessionMmt && sessionUpdated != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(sessionUpdated)
        : (latestResult != null
            ? '${latestResult.drawDate.toIso8601String().split('T').first} ${latestResult.drawTime.substring(0, 5)}:00'
            : '--');

    // 12:01 card: `--` until 09:30; live 09:30–12:01; then frozen. 2D = same digit as morning / 12:01 draw.
    String? sv12;
    String? ix12;
    if (showDash121) {
      sv12 = null;
      ix12 = null;
    } else {
      sv12 = setIndexState.morningLiveSetValue != null
          ? _quoteFmt.format(setIndexState.morningLiveSetValue!)
          : (row1201 != null ? _quoteFmt.format(row1201.setValue) : null);
      ix12 = setIndexState.morningLiveSetIndex != null
          ? _quoteFmt.format(setIndexState.morningLiveSetIndex!)
          : (row1201 != null ? _quoteFmt.format(row1201.setIndex) : null);
    }

    final int? digit12Source = showDash121
        ? null
        : (setIndexState.morningLiveResultDigit ?? row1201?.resultDigit);
    final String? resultDigit12 =
        digit12Source != null ? digit12Source.toString().padLeft(2, '0') : null;

    String? sv43;
    String? ix43;
    if (showDash430) {
      sv43 = null;
      ix43 = null;
    } else {
      sv43 = setIndexState.afternoonLiveSetValue != null
          ? _quoteFmt.format(setIndexState.afternoonLiveSetValue!)
          : (row1630 != null ? _quoteFmt.format(row1630.setValue) : null);
      ix43 = setIndexState.afternoonLiveSetIndex != null
          ? _quoteFmt.format(setIndexState.afternoonLiveSetIndex!)
          : (row1630 != null ? _quoteFmt.format(row1630.setIndex) : null);
    }

    final Widget bigNumberWidget = Text(
      bigNumber,
      style: TextStyle(
        fontSize: 132,
        height: 1.05,
        fontWeight: FontWeight.bold,
        color: AppTheme.brandHeroDigit,
        shadows: [
          Shadow(
            color: AppTheme.brandHeroDigit.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
    final Widget heroNumber =
        (anim121 || anim430) && bigNumber != '--'
            ? QuoteFiguresBlink(child: bigNumberWidget)
            : bigNumberWidget;

    return Container(
      margin: const EdgeInsets.all(AppTheme.paddingL),
      decoration: BoxDecoration(
        color: AppTheme.brandLiveCardSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.brandLiveCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandLiveCardShadow,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Big Number Display — extra vertical room around the digit.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 40,
              horizontal: 28,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.brandHeroCanvas,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusXL),
                topRight: Radius.circular(AppTheme.radiusXL),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 228,
                  width: double.infinity,
                  child: Center(child: heroNumber),
                ),
                const SizedBox(height: AppTheme.paddingM),
                
                // Update time with checkmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.brandHeroDigit,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Updated: $updatedLabel',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 12:01 PM — SET/Value/2D animate 09:30–12:01; freeze at 12:01; `--` until 09:30.
          _buildDrawCard(
            time: '12:01 PM',
            setValue: sv12,
            setIndex: ix12,
            resultDigit: resultDigit12,
            quoteHardBlink: anim121 && !showDash121,
            isAnimating: anim121 && !showDash121,
          ),
          
          const SizedBox(height: AppTheme.paddingM),
          
          // 4:30 PM — blink during 14:00–16:30 MMT (SET weekdays).
          _buildDrawCard(
            time: '4:30 PM',
            setValue: sv43,
            setIndex: ix43,
            resultDigit: null,
            quoteHardBlink: anim430 && !showDash430,
            isAnimating: anim430 && !showDash430,
            alternateHeader: true,
          ),
          
          const SizedBox(height: AppTheme.paddingM),
          
          // 9:30 AM — same single-row header as 12:01 (placeholder digits).
          _liveDrawShell(
            alternateHeader: false,
            gradientBar: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    '9:30 AM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _drawGradientTimeStyle,
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Modern',
                    style: _drawGradientColStyle,
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Internet',
                    textAlign: TextAlign.center,
                    style: _drawGradientColStyle,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'TW',
                    textAlign: TextAlign.center,
                    style: _drawGradientColStyle,
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingM,
                AppTheme.paddingM,
                AppTheme.paddingM,
                AppTheme.paddingL,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 4, child: SizedBox.shrink()),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '57',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandMarketMicroDigit,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      '20',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandMarketMicroDigit,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '82',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandMarketMicroDigit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingM),
          
          _liveDrawShell(
            alternateHeader: true,
            gradientBar: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    '2:00 PM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _drawGradientTimeStyle,
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Modern',
                    style: _drawGradientColStyle,
                  ),
                ),
                const Expanded(
                  flex: 4,
                  child: Text(
                    'Internet',
                    textAlign: TextAlign.center,
                    style: _drawGradientColStyle,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'TW',
                    textAlign: TextAlign.center,
                    style: _drawGradientColStyle,
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.paddingM,
                AppTheme.paddingM,
                AppTheme.paddingM,
                AppTheme.paddingL,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 4, child: SizedBox.shrink()),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '--',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandMarketMicroDigit,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      '--',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandMarketMicroDigit,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '--',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandMarketMicroDigit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: _bottomAdReserve),
        ],
      ),
    );
  }
}
