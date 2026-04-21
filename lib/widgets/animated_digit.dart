import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../config/market_timing.dart';

class AnimatedDigit extends StatefulWidget {
  final String finalDigit;
  final bool isAnimating;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final double width;
  final double height;

  const AnimatedDigit({
    super.key,
    required this.finalDigit,
    required this.isAnimating,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.fontSize = 80,
    this.width = 100,
    this.height = 140,
  });

  @override
  State<AnimatedDigit> createState() => _AnimatedDigitState();
}

class _AnimatedDigitState extends State<AnimatedDigit> {
  String _currentDigit = '0';
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _updateDigit();
  }

  @override
  void didUpdateWidget(AnimatedDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating != widget.isAnimating) {
      _updateDigit();
    }
  }

  void _updateDigit() {
    _timer?.cancel();
    
    if (widget.isAnimating) {
      _timer = Timer.periodic(MarketTiming.liveQuotePollInterval, (timer) {
        if (mounted) {
          setState(() {
            _currentDigit = _random.nextInt(10).toString();
          });
        }
      });
    } else {
      // Stop animation - show final digit
      if (mounted) {
        setState(() {
          _currentDigit = widget.finalDigit;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.backgroundColor,
            widget.backgroundColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.backgroundColor.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _currentDigit,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class AnimatedNumberDisplay extends StatefulWidget {
  final String number;
  final bool isAnimating;
  final double fontSize;
  final Color? textColor;

  const AnimatedNumberDisplay({
    super.key,
    required this.number,
    required this.isAnimating,
    this.fontSize = 24,
    this.textColor,
  });

  @override
  State<AnimatedNumberDisplay> createState() => _AnimatedNumberDisplayState();
}

class _AnimatedNumberDisplayState extends State<AnimatedNumberDisplay> {
  String _currentNumber = '0000.00';
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _updateNumber();
  }

  @override
  void didUpdateWidget(AnimatedNumberDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnimating != widget.isAnimating) {
      _updateNumber();
    } else if (!widget.isAnimating && oldWidget.number != widget.number) {
      setState(() => _currentNumber = widget.number);
    }
  }

  void _updateNumber() {
    _timer?.cancel();
    
    if (widget.isAnimating) {
      _timer = Timer.periodic(MarketTiming.liveQuotePollInterval, (timer) {
        if (mounted) {
          setState(() {
            final intPart = _random.nextInt(9999);
            final decimalPart = _random.nextInt(100);
            _currentNumber = '${intPart.toString().padLeft(4, '0')}.${decimalPart.toString().padLeft(2, '0')}';
          });
        }
      });
    } else {
      // Stop animation - show final number
      if (mounted) {
        setState(() {
          _currentNumber = widget.number;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentNumber,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.bold,
        color: widget.textColor ?? Colors.black87,
      ),
    );
  }
}

/// Subtle opacity pulse for live SET / index / hero figures (attention, not distracting).
class PulsingAttention extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PulsingAttention({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PulsingAttention> createState() => _PulsingAttentionState();
}

class _PulsingAttentionState extends State<PulsingAttention>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _opacity = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PulsingAttention oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _controller.repeat(reverse: true);
      } else {
        _controller
          ..stop()
          ..value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) =>
          Opacity(opacity: _opacity.value, child: child),
      child: widget.child,
    );
  }
}

/// 0.5s hidden, 1.5s visible per 2s cycle (hard on/off).
class QuoteFiguresBlink extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const QuoteFiguresBlink({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<QuoteFiguresBlink> createState() => _QuoteFiguresBlinkState();
}

class _QuoteFiguresBlinkState extends State<QuoteFiguresBlink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.enabled) {
      _controller.repeat();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(QuoteFiguresBlink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller
          ..stop()
          ..value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final opacity = t < 0.25 ? 0.0 : 1.0;
        return Opacity(opacity: opacity, child: child);
      },
      child: widget.child,
    );
  }
}
