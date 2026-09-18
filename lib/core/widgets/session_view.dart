import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/harvest_case/presentation/controllers/harvest_controller.dart';
import 'components.dart';

class SessionView extends ConsumerWidget {
  const SessionView({super.key, required this.builder});
  final Widget Function(CaseSession) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(sessionProvider)
      .when(
        loading: () => const Panel(
          child: StackItems(
            children: [
              SizedBox(height: 24),
              Center(child: CircularProgressIndicator()),
              Text(
                'Preparing the example snapshot…',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
        error: (error, stack) => Panel(
          child: StackItems(
            children: [
              const Heading('Let’s try that again', icon: Icons.error_outline),
              const Text(
                'The demo snapshot could not be loaded. Your harvest facts are still available.',
              ),
              PrimaryButton(
                'Review harvest & retry',
                onPressed: () => context.go('/register'),
              ),
            ],
          ),
        ),
        data: (session) => session == null
            ? Panel(
                child: StackItems(
                  children: [
                    const SizedBox(height: 24),
                    const Icon(Icons.agriculture_outlined, size: 56),
                    const Heading('Your harvest starts here'),
                    const Text(
                      'Register a harvest and confirm the facts to see an example recommendation and monitor your case.',
                    ),
                    PrimaryButton(
                      'Register a harvest',
                      icon: Icons.add_circle_outline,
                      onPressed: () => context.go('/register'),
                    ),
                  ],
                ),
              )
            : builder(session),
      );
}
