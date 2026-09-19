import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/data/auth_controller.dart';
import '../../auth/data/profile_provider.dart';
import '../../home/presentation/home_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.settings = false});
  final bool settings;
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String? selected;
  bool busy = false;
  String? message;
  @override
  Widget build(BuildContext context) {
    final language = selected ?? ref.watch(preferencesProvider).language;
    final t = AppStrings(language);
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.settings)
              ref
                  .watch(userProfileProvider)
                  .when(
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (_, _) => Text(t('Profile unavailable')),
                    data: (profile) => profile == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final field in [
                                'display_name',
                                'farm_name',
                                'district',
                              ])
                                if ((profile[field] as String? ?? '')
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      profile[field] as String,
                                      style: field == 'display_name'
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleLarge
                                          : null,
                                    ),
                                  ),
                              const Divider(height: 32),
                            ],
                          ),
                  ),
            Text(
              t('Choose your language'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            RadioGroup<String>(
              groupValue: language,
              onChanged: busy
                  ? (_) {}
                  : (value) => setState(() => selected = value),
              child: Column(
                children: [
                  for (final entry in appLanguages.entries)
                    RadioListTile<String>(
                      value: entry.key,
                      title: Text(entry.value),
                      subtitle: Text(entry.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(message!),
              ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() {
                        busy = true;
                        message = null;
                      });
                      try {
                        await ref
                            .read(authControllerProvider)
                            .saveLanguage(language);
                        if (context.mounted) context.go('/');
                      } catch (_) {
                        if (mounted) {
                          setState(
                            () => message = t(
                              'Could not save. Please try again.',
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(t(widget.settings ? 'Save' : 'Continue')),
            ),
            if (widget.settings && !ref.read(authControllerProvider).offline)
              TextButton.icon(
                icon: const Icon(Icons.cloud_sync_outlined),
                label: Text(t('Check connection')),
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          ref.invalidate(supabaseConnectionStatusProvider);
                          await ref.read(
                            supabaseConnectionStatusProvider.future,
                          );
                          if (mounted) {
                            setState(() => message = t('Connection available'));
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => message = t('Connection unavailable'),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
            if (widget.settings && !ref.read(authControllerProvider).offline)
              TextButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        try {
                          await ref.read(authControllerProvider).signOut();
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => message = t(
                                'Could not sign out. Please try again.',
                              ),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.logout),
                label: Text(t('Sign out')),
              ),
          ],
        ),
      ),
    );
    return widget.settings
        ? content
        : Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: content,
              ),
            ),
          );
  }
}
