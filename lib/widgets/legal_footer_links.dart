import 'package:flutter/material.dart';

import '../config/app_legal.dart';
import '../config/theme.dart';

/// Compact Privacy | Terms row for footers and secondary screens.
class LegalFooterLinks extends StatelessWidget {
  const LegalFooterLinks({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final legalReady = AppLegal.hasProductionUrls;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textSecondary,
        );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: compact ? 4 : 8,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                : null,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: legalReady ? AppLegal.openPrivacyPolicy : null,
          child: Text('Privacy Policy', style: style),
        ),
        Text('|', style: style),
        TextButton(
          style: TextButton.styleFrom(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                : null,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: legalReady ? AppLegal.openTermsOfService : null,
          child: Text('Terms of Service', style: style),
        ),
      ],
    );
  }
}
