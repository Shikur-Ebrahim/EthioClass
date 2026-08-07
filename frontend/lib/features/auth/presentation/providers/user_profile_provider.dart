import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_profile.dart';

// Provides the current Supabase auth session user
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// Watches auth state stream for real-time login/logout changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Fetches the full profile (including role) from the DB
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Re-fetch whenever auth state changes
  ref.watch(authStateProvider);

  final repo = ref.read(authRepositoryProvider);
  return await repo.fetchProfile();
});

// Convenient role checker — true if current user is admin
final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.maybeWhen(
    data: (p) => p?.isAdmin ?? false,
    orElse: () => false,
  );
});

// Convenient role checker — true if current user is student
final isStudentProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.maybeWhen(
    data: (p) => p?.isStudent ?? true,
    orElse: () => true,
  );
});

// Auth repository provider (centralised)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
