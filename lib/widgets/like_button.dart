import 'package:flutter/material.dart';
import '../config/theme.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLiked != widget.isLiked) {
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        _controller.forward(from: 0);
        widget.onTap();
      },
      icon: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.isLiked ? Icons.favorite : Icons.favorite_border,
          color: widget.isLiked ? AppTheme.likeColor : AppTheme.textSecondary,
        ),
      ),
      label: Text(
        'Like',
        style: TextStyle(
          color: widget.isLiked ? AppTheme.likeColor : AppTheme.textSecondary,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: widget.isLiked ? AppTheme.likeColor : AppTheme.textSecondary,
      ),
    );
  }
}
