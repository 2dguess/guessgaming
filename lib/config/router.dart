import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/feed/feed_page.dart';
import '../pages/feed/post_detail_page.dart';
import '../pages/feed/compose_post_page.dart';
import '../pages/betting/betting_page.dart';
import '../pages/missions/missions_page.dart';
import '../pages/games/math_quiz_game_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/notifications/notifications_page.dart';
import '../pages/home/home_page.dart';
import '../pages/chat/chat_list_page.dart';
import '../pages/chat/chat_thread_page.dart';
import '../pages/admin/admin_page.dart';
import '../pages/shop/gift_shop_page.dart';

/// Root navigator for dialogs that must not capture a stale [BuildContext].
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = Supabase.instance.client.auth.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup';
      
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      if (isAuthenticated && isLoggingIn) {
        return '/home';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedPage(),
      ),
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailPage(postId: postId);
        },
      ),
      GoRoute(
        path: '/compose',
        builder: (context, state) => const ComposePostPage(),
      ),
      GoRoute(
        path: '/betting',
        redirect: (context, state) => '/picks',
      ),
      GoRoute(
        path: '/picks',
        builder: (context, state) => const BettingPage(),
      ),
      GoRoute(
        path: '/play',
        redirect: (context, state) => '/picks',
      ),
      GoRoute(
        path: '/missions',
        builder: (context, state) => const MissionsPage(),
      ),
      GoRoute(
        path: '/games/math-quiz',
        builder: (context, state) => const MathQuizGamePage(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfilePage(userId: userId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListPage(),
      ),
      GoRoute(
        path: '/chats/thread/:threadId',
        builder: (context, state) {
          final threadId = state.pathParameters['threadId']!;
          final title = state.extra as String? ?? 'Chat';
          return ChatThreadPage(threadId: threadId, peerTitle: title);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        path: '/gift-shop',
        builder: (context, state) => const GiftShopPage(),
      ),
    ],
  );
});
