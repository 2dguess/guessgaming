import 'package:flutter/material.dart';
import '../utils/time_ago.dart';

class TimeDisplay extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const TimeDisplay({
    super.key,
    required this.dateTime,
    this.style,
  });

  @override
  State<TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<TimeDisplay> {
  late String _timeText;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startTimer();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _timeText = formatTimeAgo(widget.dateTime);
      });
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _updateTime();
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeText,
      style: widget.style,
    );
  }
}
