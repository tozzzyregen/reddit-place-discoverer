// Profile Module Loaded
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api_client.dart';

class ProfileState {
  final bool isLoading;
  final String? email;
  final bool isPro;
  final String? error;

  ProfileState({
    this.isLoading = false,
    this.email,
    this.isPro = false,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? email,
    bool? isPro,
    String? error,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      email: email ?? this.email,
      isPro: isPro ?? this.isPro,
      error: error ?? this.error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => ProfileState();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      print('DEBUG Profile: Loading profile from backend for user ${user.id}');
      
      // Use backend API to bypass RLS issues
      final response = await ApiClient.get('profile/${user.id}');

      print('DEBUG Profile: Backend response = $response');

      if (response != null) {
        final isPro = response['is_pro'] == true;
        print('DEBUG Profile: is_pro = $isPro');
        
        // Use auth email if profile email is placeholder or null
        String? profileEmail = response['email'];
        if (profileEmail == null || profileEmail.contains('placeholder.com') || profileEmail.contains('@user.com')) {
          profileEmail = user.email;
        }
        
        state = ProfileState(
          email: profileEmail ?? user.email,
          isPro: isPro,
        );
      } else {
        print('DEBUG Profile: No response, using defaults');
        state = ProfileState(
          email: user.email,
          isPro: false,
        );
      }
      print('DEBUG Profile: Final state isPro = ${state.isPro}');
    } catch (e) {
      print('Profile load error: $e');
      state = ProfileState(
        email: user.email,
        isPro: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      state = ProfileState(); // Reset state
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);

