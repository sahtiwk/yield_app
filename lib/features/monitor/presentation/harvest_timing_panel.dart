import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/supabase/app_failure.dart';
import '../../harvest_case/domain/harvest_case.dart';
import '../../harvest_case/presentation/controllers/harvest_controller.dart';

class HarvestTimingPanel extends ConsumerStatefulWidget {
  const HarvestTimingPanel({super.key, required this.harvest});
  final HarvestCase harvest;
  @override
  ConsumerState<HarvestTimingPanel> createState() => _HarvestTimingPanelState();
}

class _HarvestTimingPanelState extends ConsumerState<HarvestTimingPanel> {
  bool editing = false, saving = false;
  late String status;
  late DateTime date;
  String? issue;
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    status = widget.harvest.harvestStatus;
    date = widget.harvest.harvestedAt;
  }

  @override
  void didUpdateWidget(covariant HarvestTimingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.harvest.id != widget.harvest.id) {
      editing = false;
      _reset();
    } else if (!editing) {
      _reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final c = widget.harvest;
    final harvested = c.harvestStatus == 'Harvested';
    final delta = DateTime.now().difference(c.harvestedAt);
    final timing = harvested ? 'harvested_on' : 'planned_for';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: const Color(0xFFE6F2EC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t(c.harvestStatus),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(t.format(timing, {'date': t.date(c.harvestedAt)})),
              const SizedBox(height: 8),
              Text(
                harvested && !delta.isNegative
                    ? t.format('elapsed_hours', {
                        'hours': t.number(delta.inMinutes / 60),
                      })
                    : !harvested && delta.isNegative
                    ? t.format('until_harvest', {
                        'hours': t.number(-delta.inMinutes / 60),
                      })
                    : t('confirm_timing'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (!editing)
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _reset();
              editing = true;
              issue = null;
            }),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(t('edit_timing')),
          ),
        if (editing) ...[
          DropdownButtonFormField<String>(
            initialValue: status,
            isExpanded: true,
            decoration: InputDecoration(labelText: t('Harvest status')),
            items: [
              for (final value in [
                'Harvested',
                'Harvest planned',
                'Standing crop',
              ])
                DropdownMenuItem(value: value, child: Text(t(value))),
            ],
            onChanged: saving
                ? null
                : (value) => setState(() {
                    status = value!;
                    issue = null;
                  }),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(t.date(date)),
            onPressed: saving
                ? null
                : () async {
                    final day = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (day == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(date),
                    );
                    if (time == null || !mounted) return;
                    setState(() {
                      date = DateTime(
                        day.year,
                        day.month,
                        day.day,
                        time.hour,
                        time.minute,
                      );
                      issue = null;
                    });
                  },
          ),
          if (issue != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                t(issue!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(t('Save')),
                onPressed: saving
                    ? null
                    : () async {
                        setState(() {
                          saving = true;
                          issue = null;
                        });
                        try {
                          final success = await ref
                              .read(sessionProvider.notifier)
                              .updateTiming(status, date);
                          if (mounted) {
                            setState(() {
                              editing = !success;
                              if (!success) issue = 'save_failed';
                            });
                          }
                        } catch (error) {
                          if (mounted) {
                            setState(
                              () => issue = error is AppFailure
                                  ? error.code
                                  : 'save_failed',
                            );
                          }
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      },
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () => setState(() {
                        editing = false;
                        issue = null;
                      }),
                child: Text(t('Cancel')),
              ),
            ],
          ),
          if (saving) const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
