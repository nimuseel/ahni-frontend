# Development Commands

## Prerequisites

- Flutter 3.47.1 stable with Dart 3.13.1
- Android Studio or Xcode for device builds

## Commands

```bash
./scripts/setup
./scripts/dev
./scripts/lint
./scripts/typecheck
./scripts/test-unit
./scripts/test-widget
./scripts/test-integration
./scripts/verify
```

Before running `./scripts/dev`, copy the example configuration and provide the local
development values. `.env.local` is ignored by Git and must never be committed. The
script loads the file and converts its values into Flutter `--dart-define` arguments.

```bash
cp .env.example .env.local
# Edit .env.local with the actual local development values.
./scripts/dev
```

`APP_ENV` defaults to `development`. `SUPABASE_URL`,
`SUPABASE_PUBLISHABLE_KEY`, and `API_BASE_URL` are required. Existing shell
environment values remain supported when `.env.local` is absent.

When an Android device is connected, `scripts/dev` automatically reverses TCP port 8080 so the app can reach the local backend through `127.0.0.1:8080`.

`scripts/verify` runs lint, type checking, unit tests, widget tests, and the integration smoke test in that order. It is the authoritative local and CI entry point.

The default integration layer lives under `test/integration` and exercises the complete app shell with Flutter's host-independent test runner. Device-specific journeys belong to their feature branches and must add a provisioned emulator or physical-device CI job instead of making the default harness depend on an unavailable device.

Use Flutter 3.47.1 stable and keep `pubspec.lock` committed for this application.
