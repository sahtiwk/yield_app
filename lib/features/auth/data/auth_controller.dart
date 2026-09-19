import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../home/presentation/home_controller.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(ref.watch(supabaseClientProvider), (
    language,
  ) {
    ref.read(preferencesProvider.notifier).language(language);
  });
  ref.onDispose(controller.dispose);
  return controller;
});

class AuthController extends ChangeNotifier {
  AuthController(this.client, this.onLanguage) {
    _subscription = client?.auth.onAuthStateChange.listen((event) {
      if (event.session?.user.id != userId || error != null) reload();
    });
    reload();
  }
  final SupabaseClient? client;
  final void Function(String) onLanguage;
  StreamSubscription<AuthState>? _subscription;
  String? userId;
  bool loading = true;
  bool onboarded = false;
  String? error;
  bool _disposed = false;
  int _request = 0;
  bool get offline => client == null;

  Future<void> reload() async {
    final request = ++_request;
    userId = client?.auth.currentUser?.id;
    onboarded = false;
    loading = true;
    error = null;
    _notify();
    try {
      if (userId != null) {
        final profile = await client!
            .from('profiles')
            .select()
            .eq('id', userId!)
            .single();
        if (_disposed || request != _request) return;
        onboarded = profile['is_onboarded'] == true;
        onLanguage(profile['language_preference'] as String);
      }
    } catch (_) {
      if (_disposed || request != _request) return;
      error =
          'Could not load your profile. Check your connection and try again.';
    }
    if (_disposed || request != _request) return;
    loading = false;
    _notify();
  }

  Future<void> signIn() async {
    const redirect = String.fromEnvironment('AUTH_REDIRECT_URL');
    final opened = await client!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirect.isNotEmpty
          ? redirect
          : (kIsWeb ? Uri.base.origin : 'io.harvesttwin.app://login-callback/'),
    );
    if (!opened) throw StateError('Could not open sign-in');
  }

  Future<void> saveLanguage(String language) async {
    if (client != null) {
      final id = client!.auth.currentUser?.id;
      if (id == null) throw StateError('Please sign in again');
      await client!
          .from('profiles')
          .update({'language_preference': language, 'is_onboarded': true})
          .eq('id', id)
          .select()
          .single();
      if (_disposed || client!.auth.currentUser?.id != id) {
        throw StateError('The signed-in account changed. Please try again.');
      }
    }
    onLanguage(language);
    onboarded = true;
    _notify();
  }

  Future<void> signOut() async {
    await client?.auth.signOut();
    await reload();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
