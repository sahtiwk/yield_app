import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class WorkspaceHeading extends StatelessWidget {
  const WorkspaceHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!),
            ],
          ],
        ),
      ),
      if (action != null) ...[const SizedBox(width: 12), action!],
    ],
  );
}

class FeedbackState extends StatelessWidget {
  const FeedbackState({
    super.key,
    required this.icon,
    required this.title,
    this.action,
    this.actionLabel,
    this.busy = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback? action;
  final String? actionLabel;
  final bool busy;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(
      children: [
        if (busy)
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 36, color: Palette.green),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          TextButton(onPressed: action, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class StatusMessage extends StatelessWidget {
  const StatusMessage({
    super.key,
    required this.icon,
    required this.text,
    this.warning = false,
  });
  final IconData icon;
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF5DC) : Palette.pale,
      border: Border(
        left: BorderSide(
          color: warning ? Palette.amber : Palette.green,
          width: 3,
        ),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: warning ? Palette.amber : Palette.green),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
