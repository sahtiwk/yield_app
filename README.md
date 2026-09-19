# Harvest Twin

Flutter app for farmer-confirmed harvest records and post-harvest decisions. Uses Riverpod, go_router and local Supabase. Without a public key, actual user-entered cases persist on the device. A configured client uses authenticated Supabase repositories. Neither mode fabricates recommendations, prices, weather or buyers.

## Run locally

From this directory in PowerShell:

```powershell
npx.cmd supabase start
npx.cmd supabase migration up --local
.\.tools\flutter\bin\flutter.bat pub get
powershell -ExecutionPolicy Bypass -File tool/run_local.ps1
```

The launcher reads only the API URL and public publishable/anon key from the CLI result and passes them as Dart defines. It does not write credentials to source files. It uses the bundled Flutter SDK when present, otherwise Flutter on PATH.

Google credentials must be configured before signing in. To try the UI without credentials:

```powershell
powershell -ExecutionPolicy Bypass -File tool/run_local.ps1 -Offline
```

Web uses port 8082. Use `-Port 8084` if occupied; add the new callback origin to Supabase's redirect allowlist. For an Android emulator:

```powershell
powershell -ExecutionPolicy Bypass -File tool/run_local.ps1 -Device <device-id> -ApiUrl http://10.0.2.2:54321
```

Use your machine's LAN address for physical devices. The device must be able to reach the API port. A loopback OAuth callback on a phone refers to the phone: mobile OAuth requires a reachable HTTPS development callback/tunnel and matching Google/Supabase redirect configuration. Test browser OAuth locally first.

For a USB-connected Android device, forward the local API through ADB instead of using a LAN address:

```powershell
powershell -ExecutionPolicy Bypass -File tool/run_local.ps1 -Device <adb-device-id> -Usb
```

Plain `flutter run` without the public-key Dart define starts offline mode. The launcher supplies the actual local public key; `-Usb` forwards the local API port to the selected phone. It does not configure Google credentials or bypass authentication. Previously saved offline cases remain on the device and are not automatically uploaded.

## Configuration and security

- `SUPABASE_URL`: defaults to local `http://127.0.0.1:54321`.
- `SUPABASE_PUBLISHABLE_KEY`: preferred public client key.
- `SUPABASE_ANON_KEY`: legacy public-key fallback.
- `AUTH_REDIRECT_URL`: optional callback override. Web defaults to the current origin; native defaults to `io.harvesttwin.app://login-callback/`.
- `.env.example` is a reference template, not an automatically loaded asset. Pass values with `--dart-define` or use the launcher.
- Flutter public keys are visible in compiled clients. RLS enforces access; key obfuscation is not a security boundary.
- Never pass `service_role`, `sb_secret_`, database passwords or provider secrets to Flutter. Environment files and node_modules are ignored.
- Production must use its own HTTPS URL, public key, redirect URLs and separately deployed migrations/functions. Do not reuse local credentials.

`main()` binds Flutter, initializes Supabase before `runApp()`, loads local preferences and starts the existing ProviderScope. Supabase restores auth sessions. Router guards enforce sign-in and onboarding. Profiles are created by a database trigger; failed profile loads have retry/sign-out states.

## Google sign-in

This implementation uses Supabase's browser OAuth with PKCE, not a second native Google SDK. Configure a Google OAuth **Web application** client:

1. Authorized redirect URI: `http://127.0.0.1:54321/auth/v1/callback` for desktop-browser local development.
2. Supply `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID` and `SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET` to the CLI environment (or ignored root `.env`).
3. Enable `[auth.external.google]` in `supabase/config.toml`.
4. Restart the local Supabase stack without resetting the database so Auth picks up configuration.
5. Run the app on the allowed origin `http://127.0.0.1:8082`.

Configure the OAuth consent screen/test users in Google Cloud. Never paste the Google client secret into Dart defines. The web OAuth flow does not require an iOS native client ID.

Official setup: [Supabase Google Auth](https://supabase.com/docs/guides/auth/social-login/auth-google), [Flutter OAuth](https://supabase.com/docs/reference/dart/auth-signinwithoauth).

## Screens and persistence

- Home: Register Harvest, My Cases, Market Prices, Settings.
- Registration: validated weight, crop, harvest date/status, farmer-assessed condition and deadline. Current location requests foreground permission and captures GPS coordinates. Denial, disabled services or a 20-second GPS timeout reveal manual location entry and optional coordinates. No selling plan is required. Manual text without coordinates can be saved, but routing estimates require coordinates.
- Confirmation: explicit review before saving and evaluating.
- Cases: records survive app restarts; a failed evaluation does not discard the saved case.
- Onboarding/settings: English, Hindi, Tamil and Telugu; profile and device preference persistence.
- Market prices: dated observations with provenance, honest empty/error states.
- Live recommendations: estimates, baseline, alternatives and expandable assumptions.
- Live monitor: manual refresh and one-minute polling while visible and foregrounded. Failed refreshes retain the previous estimate with a warning; there are no simulated alerts.
- Monitor timing: select a saved harvest, then update Harvested / Harvest planned / Standing crop and its date/time. The same case is updated through the transactional Supabase RPC, or `harvest_cases_v1` in local preferences when offline. Completed harvests cannot be set in the future. Price details and the decision tree expand only on request.

Decisions and Monitor use the same localized view in English, Hindi, Tamil and Telugu, including rankings, assumptions, error states, timestamps, currency and quantities. Proper names and source names retain their original spelling. Native-speaker editorial review is still recommended. Voice recording/playback is not implemented. No crop vision model is used.

## Reference data

Home includes a separately labeled, published Bowenpally price reference from 14 September 2026 (ACROP's Agmarknet-derived report): tomato INR 10/kg, okra 16.69/kg, brinjal 12.65/kg, onion 35/kg and potato 11/kg. These historical wholesale observations are not live offers and are never passed to the value engine. [Source](https://acrop.app/mandi/telangana/hyderabad/bowenpally).

Decisions immediately shows quantity times the crop's published reference price while live evaluation loads or when it is unavailable. This is explicitly gross reference value, not net profit: no invented transport, buyer, weather, loss or income-improvement figures are included. The quote, crop ID and quantity are persisted locally under `reference_quote_<case-id>`. Reopening a saved case deterministically recalculates this reference; live results replace it only after successful evaluation. The existing mock repository file is not wired into the application.

Decisions and Monitor draw a pathway from the saved crop, location availability, quality and actual evaluated options. Missing data remains explicit; no randomized live results or fabricated telemetry are generated. Next-crop guidance is general rotation advice, not a forecast, based on [TNAU crop selection guidance](https://agritech.tnau.ac.in/agriculture/agri_cropselect.html). It still needs local soil, season, irrigation and disease-history review.

Saving a language returns Home after the save succeeds. Crop varieties and canonical provider messages are localized. Unknown provider names use a localized generic label rather than leaking English text; source URLs and farmer-entered text remain unchanged. This is not automatic machine translation of arbitrary incoming text.

Migration `20260919000300_reference_catalog_and_buyers.sql` adds tomato, okra, brinjal, onion and potato with three named varieties each, reference temperatures and planning shelf lives. Matching local catalog data supports offline registration. The decay coefficients are explicitly unreviewed planning assumptions, not measured cultivar-specific coefficients. The recommendation service rejects placeholder/unreviewed models until calibrated parameters and citations are supplied. Reviewed existing models are preserved.

`supabase/seed.sql` contains the only mock profile: Asha Reddy, Srinivasa Farm, Madanapalle, Andhra Pradesh, 2.4 hectares, Telugu. This local-only test account has no password or OAuth identity and is not an interactive login. Never apply this seed to production. Apply it to an existing local database without resetting user records:

```powershell
Get-Content -Raw supabase/seed.sql | docker exec -i supabase_db_yield_app psql -U postgres -d postgres -v ON_ERROR_STOP=1
```

No operational prices, destinations, offers, weather or recommendations are seeded. Crop reference context: UC Davis [tomato](https://postharvest.ucdavis.edu/produce-facts-sheets/tomato), [okra](https://postharvest.ucdavis.edu/produce-facts-sheets/okra), [eggplant](https://postharvest.ucdavis.edu/produce-facts-sheets/eggplant), [dry onion](https://postharvest.ucdavis.edu/produce-facts-sheets/onions-dry), and [potato](https://postharvest.ucdavis.edu/produce-facts-sheets/potato). These references do not validate the app's planning decay coefficients.

## Backend and external data

`supabase/migrations/20260919000100_harvest_backend.sql` adds profiles, crops, harvest cases/constraints, destinations, market observations, weather observations and storage observations. RLS isolates profiles/cases; clients cannot write authoritative market/weather/storage reference data. The `save_harvest_case` RPC saves facts and constraints in one transaction.

Start the Edge Function:

```powershell
npx.cmd supabase functions serve context_orchestrator --env-file supabase/functions/.env
```

Use `supabase/functions/.env.example` as the server-only configuration template. Without provider keys, omit `--env-file`. Required provider configuration:

| Provider | Configuration | Behavior |
| --- | --- | --- |
| Open-Meteo | No key for its eligible free usage | Current weather; dated database cache fallback |
| openrouteservice | `ORS_API_KEY` | Route distance/time; no guessed road distance |
| Agmarknet/data.gov.in | `DATA_GOV_API_KEY`, `AGMARKNET_RESOURCE_ID` | Configurable official daily-price resource; INR/quintal converted to INR/kg |
| Buyers | Verified `buyer_options` rows | Checks crop, condition, capacity, freshness and offer expiry |

Official references: [Open-Meteo](https://open-meteo.com/en/docs), [openrouteservice](https://openrouteservice.org/dev/), [Agmarknet resource](https://www.data.gov.in/resource/current-daily-price-various-commodities-various-markets-mandi).

The function validates every bearer token with Auth and uses the caller's token for RLS-protected reads, even though gateway `verify_jwt` is false. No privileged database client is used in the function.

To enable meaningful recommendations, populate verified destinations (including transport charges), market observations and reviewed crop configurations. Scientific values are deliberately **not fabricated**: provide a crop/condition-specific decay rate, shelf life and source citation, then mark the model reviewed. NABCONS aggregate losses must not be treated as hourly decay coefficients without calibration.

Current engine scope: harvested batches declared Ready, same-day sale and eligible direct-buyer routes, reviewed reference-condition decay, hard deadline filtering, transport costs, deterministic ranking, exact-market baseline matching and a labeled price-sensitivity range. Other conditions and missing data return explicit unavailable responses. Weather does not apply an unvalidated decay multiplier. Storage/wait scenarios, temperature calibration and scheduled cache ingestion require verified data/models and are not represented as completed integrations.

No income advantage is claimed when the farmer's free-text baseline cannot be matched. Prices older than 48 hours and cached weather older than one hour are excluded. Buyer offers must remain valid through arrival. Provider calls have timeouts and a bounded destination count.

## Platform notes

- Android: Internet permission and OAuth deep link configured; HTTP enabled only in debug for local development.
- Location uses [Geolocator](https://pub.dev/packages/geolocator) with foreground-only requests. Android coarse/fine permissions and Apple usage descriptions are configured. After adding this native plugin, fully rebuild/relaunch the app; hot reload alone is insufficient. Web location needs a secure browser context (HTTPS or localhost).
- iOS: callback URL scheme and local-network permission configured. Confirm ATS/network behavior on the target iOS version/device; use HTTPS for production.
- macOS: callback scheme and network-client entitlements configured.
- Windows/Linux: web preview works; packaged native OAuth additionally needs OS registration of `io.harvesttwin.app` to launch the executable. No registry/desktop-handler changes are made automatically.
- Windows plugin builds may require Developer Mode for symlink support.
- Android, iOS and packaged desktop runtime builds have not been device-tested in this session.

## Verification

```powershell
.\.tools\flutter\bin\flutter.bat analyze
.\.tools\flutter\bin\flutter.bat test
.\.tools\flutter\bin\flutter.bat build web
npx.cmd supabase test db
npx.cmd --yes deno test supabase/functions/_shared/value_engine/value_engine_test.ts
npx.cmd --yes deno check --config supabase/functions/context_orchestrator/deno.json supabase/functions/context_orchestrator/index.ts
node tool/backend_smoke.mjs
```

The backend smoke script is **local-only**. It creates two disposable test users, verifies profile/onboarding, case persistence, cross-user isolation and function authentication, then removes those users. It reads an admin key in the trusted Node process solely for cleanup; it is never included in Flutter. Start the function server first.

Visual captures: `flutter test tool/visual_smoke_test.dart`, written to ignored `artifacts/`. The Flutter tests cover auth routing, validation, failure handling and four-language layouts at 360, 390, 768, 1024 and 1440 pixels.

Google consent/sign-in and live keyed-provider calls still need your credentials before they can be end-to-end tested. The technical architecture document remains the long-term design reference.
