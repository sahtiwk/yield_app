import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/presentation/home_controller.dart';

import 'app/app.dart';
import 'core/supabase/supabase_client.dart';
import 'core/supabase/supabase_config.dart';
import 'core/localization/app_localizations.dart';
import 'app/theme/app_theme.dart';

bool _backendInitialized = false;
bool _booting = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_booting) return;
  _booting = true;
  try {
    if (!_backendInitialized) {
      await initializeSupabase(SupabaseConfig.fromEnvironment());
      _backendInitialized = true;
    }
    final preferences = await SharedPreferences.getInstance();
    runApp(
      ProviderScope(
        overrides: [localPreferencesProvider.overrideWithValue(preferences)],
        child: const HarvestTwinApp(),
      ),
    );
  } catch (_) {
    // Configuration and storage errors must not leave the user at a blank screen.
    runApp(const _StartupErrorApp());
  } finally {
    _booting = false;
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();
  @override
  Widget build(BuildContext context) {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final t = AppStrings(
      const {'hi': 'Hindi', 'ta': 'Tamil', 'te': 'Telugu'}[code] ?? 'English',
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 40),
                  const SizedBox(height: 20),
                  Text(t('startup_failed'), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: main, child: Text(t('Try again'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
