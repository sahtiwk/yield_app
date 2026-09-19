import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final t = ref.watch(stringsProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.spa, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Harvest Twin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('Your harvest, your next step'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (error != null || auth.error != null) ...[
                    Text(
                      t(error ?? auth.error!),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (auth.loading)
                    const Center(child: CircularProgressIndicator())
                  else if (auth.userId != null) ...[
                    FilledButton(
                      onPressed: auth.reload,
                      child: Text(t('Try again')),
                    ),
                    TextButton(
                      onPressed: auth.signOut,
                      child: Text(t('Sign out')),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              setState(() {
                                busy = true;
                                error = null;
                              });
                              try {
                                await auth.signIn();
                              } catch (_) {
                                if (mounted) {
                                  setState(
                                    () => error =
                                        'Sign-in could not start. Please try again.',
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                      icon: const Icon(Icons.login),
                      label: Text(t('Continue with Google')),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
