import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../localization/app_localizations.dart';
import '../../features/harvest_case/presentation/controllers/harvest_controller.dart';
import 'workspace_widgets.dart';

class SessionView extends ConsumerWidget {
  const SessionView({super.key, required this.builder});
  final Widget Function(CaseSession) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return ref
        .watch(sessionProvider)
        .when(
          loading: () => FeedbackState(
            icon: Icons.sync,
            title: t('Evaluating options'),
            busy: true,
          ),
          error: (_, _) => FeedbackState(
            icon: Icons.error_outline,
            title: t('estimate_unavailable'),
            action: () => context.go('/cases'),
            actionLabel: t('My Cases'),
          ),
          data: (session) => session == null
              ? FeedbackState(
                  icon: Icons.inventory_2_outlined,
                  title: t('No harvest selected'),
                  action: () => context.go('/cases'),
                  actionLabel: t('My Cases'),
                )
              : builder(session),
        );
  }
}
