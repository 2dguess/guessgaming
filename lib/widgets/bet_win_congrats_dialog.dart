import 'package:flutter/material.dart';

import '../config/theme.dart';
/// Full-screen dimmed overlay with a colorful reward card (virtual score only).
Future<void> showBetWinCongratsDialog({
  required BuildContext context,
  required String displayName,
  required int totalRewardScore,
  int matchCount = 1,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (ctx) => _CongratsCard(
      displayName: displayName,
      totalRewardScore: totalRewardScore,
      matchCount: matchCount,
    ),
  );
}

class _CongratsCard extends StatelessWidget {
  const _CongratsCard({
    required this.displayName,
    required this.totalRewardScore,
    required this.matchCount,
  });

  final String displayName;
  final int totalRewardScore;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final name = displayName.trim().isEmpty ? 'Player' : displayName.trim();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7C3AED),
                  Color(0xFF2563EB),
                  Color(0xFF0D9488),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD54F),
                        size: 44,
                      ),
                      const SizedBox(height: AppTheme.paddingM),
                      Text(
                        'Congratulations',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: AppTheme.paddingL),
                      Text(
                        'Hello $name',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Text(
                        matchCount > 1
                            ? 'Your guesses matched!'
                            : 'Your guess matched!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                      ),
                      const SizedBox(height: AppTheme.paddingL),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.paddingL,
                          horizontal: AppTheme.paddingM,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Get your rewards',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.paddingS),
                            Text(
                              '$totalRewardScore score',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: const Color(0xFFFFD54F),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.paddingS),
                      Text(
                        'Entertainment only — virtual score, no cash value.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: AppTheme.paddingL),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Awesome',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
