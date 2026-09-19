import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/widgets/components.dart';
import '../../../../core/location/current_location.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/harvest_case.dart';
import '../controllers/harvest_controller.dart';

class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key});
  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _form = GlobalKey<FormState>();
  late HarvestCase _draft;
  late final TextEditingController _weight, _location, _latitude, _longitude;
  bool _locating = false;
  bool _manualLocation = false;
  String? _locationIssue;
  @override
  void initState() {
    super.initState();
    _draft = ref.read(draftProvider);
    _weight = TextEditingController(text: _draft.quantityKg.toStringAsFixed(0));
    if (_draft.quantityKg == 0) _weight.clear();
    _location = TextEditingController(text: _draft.location);
    _manualLocation = _draft.location.isNotEmpty && _draft.latitude == null;
    _latitude = TextEditingController(text: _draft.latitude?.toString() ?? '');
    _longitude = TextEditingController(
      text: _draft.longitude?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _location.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (_locating) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _locating = true;
      _locationIssue = null;
    });
    try {
      final position = await ref.read(currentLocationProvider)();
      if (!mounted) return;
      setState(() {
        _latitude.text = position.latitude.toString();
        _longitude.text = position.longitude.toString();
        _location.text =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        _manualLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _manualLocation = true;
        _locationIssue = 'location_fallback';
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: StackItems(
          children: [
            Heading(
              t('Register harvest details'),
              trailing: IconButton(
                tooltip: t('Cancel'),
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.close),
              ),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _draft.crop.id,
              decoration: InputDecoration(labelText: t('Crop')),
              items: [
                for (final c in ref.read(harvestRepositoryProvider).crops)
                  DropdownMenuItem(value: c.id, child: Text(t(c.name))),
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
            DropdownButtonFormField<String>(
              key: ValueKey('${_draft.crop.id}:${_draft.crop.variety}'),
              initialValue: _draft.crop.varieties.contains(_draft.crop.variety)
                  ? _draft.crop.variety
                  : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: t('Variety')),
              items: [
                for (final variety in _draft.crop.varieties)
                  DropdownMenuItem(value: variety, child: Text(t(variety))),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(
                    () => _draft = _draft.copyWith(
                      crop: _draft.crop.withVariety(value),
                    ),
                  );
                }
              },
              validator: (value) =>
                  value == null ? t('Choose a variety') : null,
            ),
            TextFormField(
              controller: _weight,
              decoration: InputDecoration(
                labelText: t('Net weight'),
                suffixText: t('kilogram'),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (s) {
                final n = double.tryParse(s ?? '');
                return n == null || !n.isFinite || n <= 0 || n > 100000
                    ? t('Enter a weight between 1 and 100,000 kg')
                    : null;
              },
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _draft.harvestStatus,
              decoration: InputDecoration(labelText: t('Harvest status')),
              items: [
                for (final s in [
                  'Harvested',
                  'Harvest planned',
                  'Standing crop',
                ])
                  DropdownMenuItem(value: s, child: Text(t(s))),
              ],
              onChanged: (s) =>
                  setState(() => _draft = _draft.copyWith(harvestStatus: s)),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                '${t('Harvest date')} · ${MaterialLocalizations.of(context).formatShortDate(_draft.harvestedAt)}',
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
              decoration: InputDecoration(labelText: t('Selling deadline')),
              items: [
                for (final s in [
                  'Must sell today',
                  'Within 2 days',
                  'Within 3 days',
                ])
                  DropdownMenuItem(value: s, child: Text(t(s))),
              ],
              onChanged: (s) =>
                  setState(() => _draft = _draft.copyWith(urgency: s)),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _draft.farmerCondition,
              decoration: InputDecoration(
                labelText: t('Your assessment of quality'),
              ),
              items: [
                for (final s in [
                  'Ready',
                  'Ripe',
                  'Very ripe',
                  'Mixed',
                  'Damaged',
                ])
                  DropdownMenuItem(value: s, child: Text(t(s))),
              ],
              onChanged: (s) =>
                  setState(() => _draft = _draft.copyWith(farmerCondition: s)),
            ),
            OutlinedButton.icon(
              onPressed: _locating ? null : _locate,
              icon: const Icon(Icons.my_location),
              label: Text(t(_locating ? 'locating' : 'current_location')),
            ),
            if (_locating) const LinearProgressIndicator(),
            if (_locationIssue != null) Text(t(_locationIssue!)),
            if (!_manualLocation && _location.text.isNotEmpty)
              Text('${t('location_selected')}: ${_location.text}'),
            if (_manualLocation)
              TextFormField(
                controller: _location,
                decoration: InputDecoration(
                  labelText: t('Farm / harvest location'),
                ),
                maxLength: 120,
                onChanged: (_) {
                  _latitude.clear();
                  _longitude.clear();
                },
                validator: (s) => s == null || s.trim().isEmpty
                    ? t('Enter a location')
                    : null,
              ),
            if (_manualLocation)
              for (final coordinate in [
                (
                  controller: _latitude,
                  label: 'Latitude (optional)',
                  maximum: 90.0,
                ),
                (
                  controller: _longitude,
                  label: 'Longitude (optional)',
                  maximum: 180.0,
                ),
              ])
                TextFormField(
                  controller: coordinate.controller,
                  decoration: InputDecoration(labelText: t(coordinate.label)),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    if (_latitude.text.trim().isEmpty &&
                        _longitude.text.trim().isEmpty) {
                      return null;
                    }
                    final number = double.tryParse(value ?? '');
                    return number == null ||
                            !number.isFinite ||
                            number.abs() > coordinate.maximum
                        ? t('Enter valid coordinates')
                        : null;
                  },
                ),
            PrimaryButton(
              t('Review facts'),
              icon: Icons.arrow_forward,
              onPressed: _locating
                  ? null
                  : () {
                      if (!_form.currentState!.validate()) return;
                      if (_location.text.trim().isEmpty) {
                        setState(() => _locationIssue = 'location_required');
                        return;
                      }
                      FocusManager.instance.primaryFocus?.unfocus();
                      ref
                          .read(draftProvider.notifier)
                          .update(
                            _draft.copyWith(
                              quantityKg: double.parse(_weight.text),
                              location: _location.text.trim(),
                              latitude: double.tryParse(_latitude.text),
                              longitude: double.tryParse(_longitude.text),
                              clearCoordinates:
                                  _latitude.text.trim().isEmpty &&
                                  _longitude.text.trim().isEmpty,
                            ),
                          );
                      context.go('/confirm');
                    },
            ),
          ],
        ),
      ),
    );
  }
}
