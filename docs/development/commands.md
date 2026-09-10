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

Before running `./scripts/dev`, provide the local development configuration through
the shell environment. The script converts these values into Flutter `--dart-define`
arguments; exporting them alone does not make them available to `String.fromEnvironment`.

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_PUBLISHABLE_KEY="your-publishable-key"
export API_BASE_URL="http://localhost:8080"
./scripts/dev
```

`scripts/verify` runs lint, type checking, unit tests, widget tests, and the integration smoke test in that order. It is the authoritative local and CI entry point.

The default integration layer lives under `test/integration` and exercises the complete app shell with Flutter's host-independent test runner. Device-specific journeys belong to their feature branches and must add a provisioned emulator or physical-device CI job instead of making the default harness depend on an unavailable device.

Use Flutter 3.47.1 stable and keep `pubspec.lock` committed for this application. `APP_ENV` defaults to `development`; `scripts/dev` passes it explicitly.
