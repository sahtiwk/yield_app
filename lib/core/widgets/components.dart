import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = 20,
    this.border = false,
  });
  final Widget child;
  final Color color;
  final double padding;
  final bool border;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: border ? Border.all(color: const Color(0xFFE7ECE7)) : null,
    ),
    child: child,
  );
}

class StackItems extends StatelessWidget {
  const StackItems({super.key, required this.children, this.gap = 16});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ],
  );
}

class Tag extends StatelessWidget {
  const Tag(
    this.text, {
    super.key,
    this.color = Palette.mint,
    this.foreground = Palette.green,
    this.icon,
  });
  final String text;
  final Color color, foreground;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ],
    ),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, color: Palette.green, size: 23),
        const SizedBox(width: 9),
      ],
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (trailing != null) ...[const SizedBox(width: 8), trailing!],
    ],
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.color,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: color == null
        ? null
        : FilledButton.styleFrom(backgroundColor: color),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 10),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.color = Palette.pale,
  });
  final String text;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
    color: color,
    padding: 14,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Palette.green),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({super.key, required this.main, required this.side});
  final Widget main, side;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 760
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: main),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: side),
            ],
          )
        : StackItems(gap: 24, children: [main, side]),
  );
}

Future<void> showInfo(BuildContext context, String title, String message) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: StackItems(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              PrimaryButton(
                'Done',
                icon: Icons.check,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
