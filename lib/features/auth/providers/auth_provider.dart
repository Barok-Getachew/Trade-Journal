import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Supabase client ──────────────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ── Auth state ───────────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

// ── Convenience providers for user identity ──────────────────────────────────
final userEmailProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.email ?? '';
});

/// Single uppercase letter for the avatar circle (first char of email).
final userInitialProvider = Provider<String>((ref) {
  final email = ref.watch(userEmailProvider);
  return email.isEmpty ? '?' : email[0].toUpperCase();
});
