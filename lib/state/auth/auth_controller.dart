import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_profile.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((data) => data.session?.user);
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user ?? client.auth.currentUser,
    loading: () => client.auth.currentUser,
    error: (_, __) => client.auth.currentUser,
  );
});

final userProfileProvider = FutureProvider<AppProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final response = await client.from('profiles').select(
        'id, username, avatar_url, created_at, popularity_points',
      ).eq('id', user.id).maybeSingle();

  if (response == null) return null;
  return AppProfile.fromJson(response);
});

/// Fetch any user's profile by id (e.g. [ProfilePage] header for that user).
final profileByIdProvider =
    FutureProvider.family<AppProfile?, String>((ref, userId) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client.from('profiles').select(
        'id, username, avatar_url, created_at, popularity_points',
      ).eq('id', userId).maybeSingle();

  if (response == null) return null;
  return AppProfile.fromJson(response);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;

  AuthController(this._client) : super(const AsyncValue.data(null));

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      // Metadata for optional Supabase "handle_new_user" trigger; must match SQL.
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (authResponse.user != null) {
        final uid = authResponse.user!.id;
        // Trigger on auth.users may have already inserted the row — avoid duplicate.
        final existing = await _client
            .from('profiles')
            .select('id')
            .eq('id', uid)
            .maybeSingle();
        if (existing == null) {
          await _client.from('profiles').insert({
            'id': uid,
            'username': username,
          });
        }
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      await _client.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthController(client);
});
