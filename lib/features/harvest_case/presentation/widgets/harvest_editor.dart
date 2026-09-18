import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/components.dart';
import '../../domain/harvest_case.dart';
import '../controllers/harvest_controller.dart';

class HarvestEditor extends ConsumerStatefulWidget {
  const HarvestEditor({super.key});
  @override
  ConsumerState<HarvestEditor> createState() => _HarvestEditorState();
}

class _HarvestEditorState extends ConsumerState<HarvestEditor> {
  final _form = GlobalKey<FormState>();
  late HarvestCase _draft;
  late final TextEditingController _weight, _location, _plan;
  @override
  void initState() {
    super.initState();
    _draft = ref.read(draftProvider);
    _weight = TextEditingController(text: _draft.quantityKg.toStringAsFixed(0));
    _location = TextEditingController(text: _draft.location);
    _plan = TextEditingController(text: _draft.currentPlan);
  }

  @override
  void dispose() {
    _weight.dispose();
    _location.dispose();
    _plan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Form(
          key: _form,
          child: StackItems(
            children: [
              Heading(
                'Edit harvest facts',
                trailing: IconButton(
                  tooltip: 'Cancel editing',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _draft.crop.id,
                decoration: const InputDecoration(labelText: 'Crop'),
                items: [
                  for (final c in ref.read(harvestRepositoryProvider).crops)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.name} · ${c.variety}'),
                    ),
                ],
                onChanged: (id) => setState(
                  () => _draft = _draft.copyWith(
                    crop: ref
                        .read(harvestRepositoryProvider)
                        .crops
                        .firstWhere((c) => c.id == id),
                  ),
                ),
              ),
              TextFormField(
                controller: _weight,
                decoration: const InputDecoration(
                  labelText: 'Net weight',
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (s) {
                  final n = double.tryParse(s ?? '');
                  return n == null || !n.isFinite || n <= 0 || n > 100000
                      ? 'Enter a weight between 1 and 100,000 kg'
                      : null;
                },
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _draft.harvestStatus,
                decoration: const InputDecoration(labelText: 'Harvest status'),
                items: [
                  for (final s in [
                    'Harvested',
                    'Harvest planned',
                    'Standing crop',
                  ])
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (s) =>
                    setState(() => _draft = _draft.copyWith(harvestStatus: s)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  'Harvest date · ${MaterialLocalizations.of(context).formatShortDate(_draft.harvestedAt)}',
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _draft.harvestedAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_draft.harvestedAt),
                  );
                  if (!mounted) return;
                  setState(
                    () => _draft = _draft.copyWith(
                      harvestedAt: DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time?.hour ?? _draft.harvestedAt.hour,
                        time?.minute ?? _draft.harvestedAt.minute,
                      ),
                    ),
                  );
                },
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _draft.urgency,
                decoration: const InputDecoration(
                  labelText: 'Selling deadline',
                ),
                items: [
                  for (final s in [
                    'Must sell today',
                    'Within 2 days',
                    'Within 3 days',
                  ])
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (s) =>
                    setState(() => _draft = _draft.copyWith(urgency: s)),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _draft.farmerCondition,
                decoration: const InputDecoration(
                  labelText: 'Your assessment of quality',
                ),
                items: [
                  for (final s in [
                    'Ready',
                    'Ripe',
                    'Very ripe',
                    'Mixed',
                    'Damaged',
                  ])
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (s) => setState(
                  () => _draft = _draft.copyWith(farmerCondition: s),
                ),
              ),
              TextFormField(
                controller: _plan,
                decoration: const InputDecoration(
                  labelText: 'Your current selling plan',
                ),
                maxLength: 100,
                validator: (s) => s == null || s.trim().isEmpty
                    ? 'Enter your current plan'
                    : null,
              ),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Farm / harvest location',
                ),
                maxLength: 120,
                validator: (s) =>
                    s == null || s.trim().isEmpty ? 'Enter a location' : null,
              ),
              PrimaryButton(
                'Save crop facts',
                icon: Icons.check,
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  ref
                      .read(draftProvider.notifier)
                      .update(
                        _draft.copyWith(
                          quantityKg: double.parse(_weight.text),
                          location: _location.text.trim(),
                          currentPlan: _plan.text.trim(),
                        ),
                      );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
