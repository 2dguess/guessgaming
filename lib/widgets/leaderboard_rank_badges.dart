import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/social/profile_leaderboard_badges.dart';

/// Score leaderboard (top 10): circular medal with rank number.
class ScoreRankCircleBadge extends StatelessWidget {
  const ScoreRankCircleBadge({
    super.key,
    required this.rank,
    this.size = 18,
  });

  final int rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = rank.clamp(1, 10);
    return Tooltip(
      message: 'Top 10 · Score · #$r',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE082),
              Color(0xFFFFC107),
              Color(0xFFE65100),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA000).withValues(alpha: 0.35),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(color: const Color(0xFFFFF8E1), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '$r',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4E342E),
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// Best match leaderboard (top 10): elongated horizontal hexagon with rank.
class BestMatchHexBadge extends StatelessWidget {
  const BestMatchHexBadge({
    super.key,
    required this.rank,
    this.height = 18,
  });

  final int rank;
  final double height;

  @override
  Widget build(BuildContext context) {
    final r = rank.clamp(1, 10);
    final w = height * 1.65;
    return Tooltip(
      message: 'Top 10 · Best match · #$r',
      child: CustomPaint(
        size: Size(w, height),
        painter: _HexBadgePainter(rank: r),
        child: SizedBox(
          width: w,
          height: height,
          child: Center(
            child: Text(
              '$r',
              style: TextStyle(
                fontSize: height * 0.45,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE8EAF6),
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HexBadgePainter extends CustomPainter {
  _HexBadgePainter({required this.rank});

  final int rank;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final inset = h * 0.22;
    final path = Path()
      ..moveTo(inset, 0)
      ..lineTo(w - inset, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w - inset, h)
      ..lineTo(inset, h)
      ..lineTo(0, h / 2)
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF7E57C2),
          const Color(0xFF4527A0),
          const Color(0xFF311B92),
        ],
        stops: const [0.0, 0.45, 1.0],
        transform: GradientRotation(math.pi / 12),
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, fill);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFB388FF).withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _HexBadgePainter oldDelegate) =>
      oldDelegate.rank != rank;
}

/// Icons placed before a username: circle = score top 10, hex = best match top 10.
class LeaderboardBadgesRow extends StatelessWidget {
  const LeaderboardBadgesRow({
    super.key,
    required this.badges,
    this.circleSize = 18,
    this.hexHeight = 18,
    this.spacing = 5,
  });

  final ProfileLeaderboardBadges badges;
  final double circleSize;
  final double hexHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final showScore = badges.scoreTop10 && badges.scoreRank != null;
    final showMatch = badges.matchTop10 && badges.matchRank != null;
    if (!showScore && !showMatch) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showScore) ...[
          ScoreRankCircleBadge(rank: badges.scoreRank!, size: circleSize),
          if (showMatch) SizedBox(width: spacing),
        ],
        if (showMatch)
          BestMatchHexBadge(rank: badges.matchRank!, height: hexHeight),
      ],
    );
  }
}
