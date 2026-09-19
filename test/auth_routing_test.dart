import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yield_app/app/app.dart';
import 'package:yield_app/features/auth/data/auth_controller.dart';

class TestAuthController extends AuthController {
  TestAuthController() : super(null, (_) {});
  @override
  bool get offline => false;
  void signedIn() {
    userId = 'test-user';
    loading = false;
    notifyListeners();
  }

  @override
  Future<void> saveLanguage(String language) async {
    onboarded = true;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    userId = null;
    onboarded = false;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'Authentication gates onboarding and protects app after sign out',
    (tester) async {
      final auth = TestAuthController();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWithValue(auth)],
          child: const HarvestTwinApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Register Harvest'), findsNothing);
      auth.signedIn();
      await tester.pumpAndSettle();
      expect(find.text('Choose your language'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Register Harvest'), findsOneWidget);
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
