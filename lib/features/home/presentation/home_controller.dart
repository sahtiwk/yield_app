import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

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
  Preferences build() => Preferences(
    language:
        ref.read(localPreferencesProvider)?.getString('language') ?? 'English',
    voice: ref.read(localPreferencesProvider)?.getBool('voice') ?? false,
  );
  void language(String value) {
    state = Preferences(language: value, voice: state.voice);
    ref.read(localPreferencesProvider)?.setString('language', value);
  }

  void voice(bool value) {
    state = Preferences(language: state.language, voice: value);
    ref.read(localPreferencesProvider)?.setBool('voice', value);
  }
}
