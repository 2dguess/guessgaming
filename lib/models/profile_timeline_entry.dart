import 'app_post.dart';

/// One row on a user's profile: their own post or a post they shared.
class ProfileTimelineEntry {
  final AppPost post;
  final DateTime sortTime;
  final bool isShare;

  const ProfileTimelineEntry({
    required this.post,
    required this.sortTime,
    required this.isShare,
  });
}
