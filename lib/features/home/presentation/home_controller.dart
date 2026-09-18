import 'package:flutter_riverpod/flutter_riverpod.dart';

class Preferences {
  const Preferences({this.language = 'English', this.voice = true});
  final String language;
  final bool voice;
}

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(
      PreferencesController.new,
    );

class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() => const Preferences();
  void language(String value) =>
      state = Preferences(language: value, voice: state.voice);
  void voice(bool value) =>
      state = Preferences(language: state.language, voice: value);
}
