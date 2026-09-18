# Harvest Twin

A Flutter frontend for farmer-first post-harvest decisions. This stage uses only local mock repositories; no backend or credentials are needed.

## Run

With Flutter stable (verified with Flutter 3.47.4 / Dart 3.13.3):

```sh
flutter pub get
flutter run -d chrome
```

For Android, start an emulator or connect a device, then run `flutter run`.

A local SDK was downloaded into the ignored `.tools/flutter` directory for verification in this workspace. On Windows, use `.\.tools\flutter\bin\flutter.bat` if Flutter is not on your PATH. Dependencies are cached in `.tools/pub-cache` when `PUB_CACHE` points there.

## Implemented flow

The four reference images map to these routes:

| Reference | Route | Screen |
| --- | --- | --- |
| Image 4 | `/` | Language and voice preferences |
| Image 3 | `/register` | Harvest registration and crop-fact confirmation |
| Image 1 | `/decisions` | Primary recommendation, alternatives and assumptions |
| Image 2 | `/monitor` | Case context, simulated heat alert and farmer decision |

Confirmation and evaluation are states within registration rather than extra routes. All screens use Flutter widgets; reference screenshots are not shipped as UI assets. Compact layouts use bottom navigation; wide layouts use a navigation rail and two-column content.

## Architecture

- `lib/app`: app, go_router routes, theme.
- `lib/core/widgets`: reusable layout, navigation, cards, buttons and async/empty states.
- `lib/features/harvest_case`: immutable case/constraint model, repository contract, mock repository, Riverpod draft and session controllers, registration and editor.
- `lib/features/recommendation`: structured snapshot/alternative models, repository contract, isolated fixtures and recommendation UI.
- `lib/features/settings` and `lib/features/monitor`: preferences and monitoring presentation.
- `lib/shared/models`: crop and destination contracts.

Replace the two repository providers to connect a future backend. No recommendation computation, Supabase initialization, network provider, authentication or notification service is implemented.

## Current state and limitations

All four screens, local edits, validation, language/mode selection, details sheets, async evaluation, empty/error states and a synthetic monitor transition are implemented. The monitor loads a second predefined snapshot; it does not simulate a real engine.

Amounts and context are fixed illustrative fixtures for a 650 kg tomato batch. Changing crop facts preserves the farmer's inputs but does not recalculate the example. Both the UI and assumptions explain this. Values must never be used as actual sale advice.

Voice controls display text previews and sample input. No microphone capture, audio playback or full interface translation is connected. Language and mode preferences are session-local. Reloading clears session data. The route map is a widget-drawn schematic, and buyer details have no live contact or booking actions.

## Last verified

- `flutter analyze --no-pub`: clean.
- `flutter test --no-pub`: all 10 tests passed, covering validation, repository failure, complete navigation and interaction, empty states, and all four screens at 360, 390, 430, 768, 1024 and 1440 pixels.
- `dart format --output=none --set-exit-if-changed lib test`: clean.
- `git diff --check`: clean.
- Release web build succeeded.
- `flutter run -d web-server --release --no-pub --web-hostname 127.0.0.1 --web-port 8081`: launched successfully; HTTP 200 and Harvest Twin page title verified at `http://127.0.0.1:8081`.
- Rendered and visually inspected all four mobile screens plus desktop settings and monitoring using Flutter's test renderer and the bundled fonts. Local captures are in the ignored `artifacts/` directory.
- No browser automation surface was connected, so an interactive browser pass was unavailable. Android device/emulator execution has not been verified.

Poppins and the Noto Indic fallback fonts are bundled for offline rendering. Their open-font licenses are included alongside the assets.

## Next task

Implement backend repository adapters against agreed Harvest Case and Recommendation Snapshot contracts, keeping the authoritative Value Engine server-side.

## Preserve

Farmer-confirmed condition and constraints, the current-plan baseline, estimate ranges, visible provenance, progressive disclosure, and the repository boundary. `Harvest_Twin_TECHNICAL_ARCHITECTURE.md` remains the architecture source of truth.
