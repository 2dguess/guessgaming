String formatTimeAgo(DateTime dateTime) {
  // Convert to local time if it's UTC
  final localDateTime = dateTime.toLocal();
  final now = DateTime.now();
  final difference = now.difference(localDateTime);

  if (difference.isNegative) {
    return 'Just now';
  }

  if (difference.inSeconds < 5) {
    return 'Just now';
  } else if (difference.inSeconds < 60) {
    return '${difference.inSeconds}s ago';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()}w ago';
  } else if (difference.inDays < 365) {
    return '${(difference.inDays / 30).floor()}mo ago';
  } else {
    return '${(difference.inDays / 365).floor()}y ago';
  }
}
