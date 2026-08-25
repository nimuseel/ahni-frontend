# Mobile Harness Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generated Flutter counter scaffold with a small AHNI app shell whose toolchain, module boundaries, contract snapshot, and test layers are reproducible locally and in CI.

**Architecture:** Bootstrap through `lib/main.dart` into `lib/app`, keep reusable infrastructure in `lib/core`, and isolate user capabilities in `lib/features`. Enforce import direction with import_lint and keep the backend OpenAPI snapshot under `contracts` for offline client verification.

**Tech Stack:** Flutter 3.47.1 stable, Dart 3.13.1, flutter_lints 6.0.0, import_lint 2.0.0, Flutter test and integration_test SDK packages

**Spec:** `nimuseel/ahni-backend:docs/superpowers/specs/2026-08-24-cross-repository-harness-design.md`

## Global Constraints

- Work only on `chore/harness-foundation`, created from current `origin/main`.
- Pin CI to Flutter 3.47.1 stable and require Dart 3.13.1 or newer within major version 3.
- The app never accesses Supabase PostgreSQL directly.
- Authentication tokens are handled only through a future secure-storage adapter under `core`; no token implementation is added in this harness change.
- Business rules stay in pure Dart outside widgets.
- Keep commits atomic and use the `chore` Conventional Commit type.
- Run `./scripts/verify` before each final repository commit.

## File Map

- `lib/main.dart`: production entry point only.
- `lib/app/ahni_app.dart`: root Material application.
- `lib/core/config/app_environment.dart`: pure environment parsing.
- `lib/features/home/presentation/home_page.dart`: minimal non-business app shell.
- `analysis_options.yaml`: analyzer and import boundary policy.
- `contracts/backend-openapi.json`: pinned backend API contract.
- `test/unit`, `test/widget`, `integration_test`: distinct test layers.
- `scripts/*`: stable local and CI command surface.

---

### Task 1: Pin the Flutter toolchain and create the app boundary

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `lib/main.dart`
- Create: `lib/app/ahni_app.dart`
- Create: `lib/core/config/app_environment.dart`
- Create: `lib/features/home/presentation/home_page.dart`
- Create: `test/unit/core/config/app_environment_test.dart`
- Move: `test/widget_test.dart` to `test/widget/ahni_app_test.dart`

**Interfaces:**
- Produces: `enum AppEnvironment` with `AppEnvironment.parse(String)` and `AhniApp({AppEnvironment environment})`.

- [ ] **Step 1: Upgrade the SDK constraints and current stable packages**

Use `sdk: '>=3.13.1 <4.0.0'`, `cupertino_icons: ^1.0.9`, and `flutter_lints: ^6.0.0`. Regenerate `pubspec.lock` with Flutter 3.47.1.

- [ ] **Step 2: Write the failing pure Dart environment tests**

```dart
void main() {
  test('parses supported deployment environments', () {
    expect(AppEnvironment.parse('development'), AppEnvironment.development);
    expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    expect(AppEnvironment.parse('production'), AppEnvironment.production);
  });

  test('rejects unknown deployment environments', () {
    expect(() => AppEnvironment.parse('local'), throwsArgumentError);
  });
}
```

- [ ] **Step 3: Verify the unit test fails**

Run: `flutter test test/unit/core/config/app_environment_test.dart`

Expected: FAIL because `AppEnvironment` does not exist.

- [ ] **Step 4: Implement the enum and thin app shell**

```dart
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) => values.firstWhere(
        (environment) => environment.name == value,
        orElse: () => throw ArgumentError.value(value, 'value'),
      );
}
```

`main.dart` reads `const String.fromEnvironment('APP_ENV', defaultValue: 'development')`, parses it, and passes it to `AhniApp`. `HomePage` displays an `AHNI` title and a neutral development-ready message without adding a product feature.

- [ ] **Step 5: Update the widget test and verify both layers**

Run: `flutter test test/unit test/widget`

Expected: PASS and the widget test finds `AHNI` and the development-ready message.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib test
git commit -m "chore(harness): establish Flutter app boundaries"
```

### Task 2: Enforce Flutter import boundaries

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `analysis_options.yaml`

**Interfaces:**
- Produces: `dart run import_lint` with error-level boundary violations.

- [ ] **Step 1: Add import_lint 2.0.0 and configure error-level rules**

```yaml
plugins:
  import_lint: 2.0.0

import_lint:
  severity: error
  rules:
    core_must_not_depend_on_features:
      target: "package:ahni_mobile/core/**/*.dart"
      from: "package:ahni_mobile/features/**/*.dart"
      except: []
    domain_must_not_depend_on_flutter:
      target: "package:ahni_mobile/features/**/domain/**/*.dart"
      from: "package:flutter/**/*.dart"
      except: []
    domain_must_not_depend_on_presentation:
      target: "package:ahni_mobile/features/**/domain/**/*.dart"
      from: "package:ahni_mobile/features/**/presentation/**/*.dart"
      except: []
```

- [ ] **Step 2: Prove the guard fails**

Temporarily import `HomePage` from `app_environment.dart`, run `dart run import_lint`, and expect a non-zero exit naming `core_must_not_depend_on_features`. Remove the temporary import immediately after the red proof.

- [ ] **Step 3: Verify the clean architecture**

Run: `dart run import_lint && flutter analyze`

Expected: PASS with zero analyzer or boundary issues.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock analysis_options.yaml
git commit -m "chore(harness): enforce Flutter import boundaries"
```

### Task 3: Pin and validate the backend API contract

**Files:**
- Create: `contracts/backend-openapi.json`
- Create: `scripts/update-api-contract`
- Create: `test/unit/contracts/backend_openapi_contract_test.dart`
- Create: `docs/development/api-contract.md`

**Interfaces:**
- Consumes: backend `docs/api/openapi.json`.
- Produces: a local OpenAPI snapshot with title `AHNI API` and version `v1`.

- [ ] **Step 1: Write the failing contract snapshot test**

```dart
test('pins the AHNI v1 backend contract', () {
  final contract = jsonDecode(
    File('contracts/backend-openapi.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final info = contract['info']! as Map<String, Object?>;
  expect(contract['openapi'], startsWith('3.'));
  expect(info['title'], 'AHNI API');
  expect(info['version'], 'v1');
});
```

- [ ] **Step 2: Verify the test fails because the snapshot is absent**

Run: `flutter test test/unit/contracts/backend_openapi_contract_test.dart`

Expected: FAIL with a missing-file error.

- [ ] **Step 3: Copy the generated backend contract and add the update command**

`scripts/update-api-contract <path>` rejects a missing argument, copies the exact JSON to `contracts/backend-openapi.json`, and runs the contract test. Document the backend commit SHA used for each update in the API contract guide.

- [ ] **Step 4: Verify the pinned contract**

Run: `./scripts/update-api-contract /Users/sumin/dev/ahni/.worktrees/backend/chore-harness-foundation/docs/api/openapi.json`

Expected: PASS and no manual edits to the copied JSON.

- [ ] **Step 5: Commit**

```bash
git add contracts scripts/update-api-contract test/unit/contracts docs/development/api-contract.md
git commit -m "chore(harness): validate backend API contract"
```

### Task 4: Add explicit test and verification commands

**Files:**
- Create: `integration_test/app_smoke_test.dart`
- Create: `scripts/setup`
- Create: `scripts/dev`
- Create: `scripts/test-unit`
- Create: `scripts/test-widget`
- Create: `scripts/test-integration`
- Create: `scripts/lint`
- Create: `scripts/typecheck`
- Modify: `scripts/verify`
- Modify: `docs/development/commands.md`

**Interfaces:**
- Produces: separately runnable unit, widget, integration, lint, typecheck, and full verification commands.

- [ ] **Step 1: Add the integration_test SDK dependency and app-shell smoke test**

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches the AHNI app shell', (tester) async {
    await tester.pumpWidget(const AhniApp(
      environment: AppEnvironment.development,
    ));
    expect(find.text('AHNI'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Add exact command mappings**

```text
scripts/setup            -> flutter pub get
scripts/dev              -> flutter run --dart-define=APP_ENV=development
scripts/test-unit        -> flutter test test/unit
scripts/test-widget      -> flutter test test/widget
scripts/test-integration -> flutter test integration_test
scripts/lint             -> dart format --output=none --set-exit-if-changed lib test integration_test && dart run import_lint
scripts/typecheck        -> flutter analyze
scripts/verify           -> lint, typecheck, unit, widget, integration in that order
```

- [ ] **Step 3: Verify every command independently**

Run: `./scripts/setup && ./scripts/lint && ./scripts/typecheck && ./scripts/test-unit && ./scripts/test-widget && ./scripts/test-integration`

Expected: every command exits zero.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock integration_test scripts docs/development/commands.md
git commit -m "chore(harness): separate Flutter verification layers"
```

### Task 5: Align CI and review guidance

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/auto-pr.yml`
- Modify: `.github/copilot-instructions.md`
- Modify: `.github/pull_request_template.md`
- Modify: `AGENTS.md`
- Modify: `ARCHITECTURE.md`
- Modify: `docs/development/testing.md`
- Modify: `docs/development/github-automation.md`
- Modify: `docs/QUALITY_SCORE.md`

- [ ] **Step 1: Pin CI and expose contract impact in review**

Set `flutter-version: '3.47.1'`, keep `channel: stable`, run `./scripts/setup`, then `./scripts/verify`. Add PR checks for backend contract version, generated client impact, auth-token handling, and all three test layers.

Align automatic PR creation with the backend workflow: require `GH_PAT`, create or update the PR as the repository owner, preserve the generated commit-history section, and request `@copilot` through `gh pr edit`.

- [ ] **Step 2: Verify documentation and workflow syntax**

Run: `./scripts/verify && git diff --check`

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add .github AGENTS.md ARCHITECTURE.md docs
git commit -m "chore(harness): align mobile CI and review rules"
```

### Task 6: Mobile final review

- [ ] **Step 1: Inspect branch scope**

Run: `git status --short && git diff origin/main...HEAD --check && git diff origin/main...HEAD --stat`

Expected: only mobile harness, app-shell, contract, test, and documentation changes.

- [ ] **Step 2: Run the authoritative verification**

Run: `./scripts/verify`

Expected: PASS on Flutter 3.47.1.

- [ ] **Step 3: Confirm atomic history**

Run: `git log --oneline origin/main..HEAD`

Expected: only `chore` commits for the approved harness scope.
