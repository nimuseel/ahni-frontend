# Email Confirmation Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Do not dispatch subagents. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete AHNI's school-email signup so Supabase delivers the confirmation email, the confirmation link returns to the mobile app, and the app continues onboarding with the confirmed session.

**Architecture:** Supabase Auth remains the source of truth for the pre-confirmation `PENDING` state through `auth.users.email_confirmed_at`. Flutter owns the user-visible pending state and observes confirmed sessions; Spring receives only confirmed JWT-backed requests and continues to create `Student` with `AccountStatus.ACTIVE`.

**Tech Stack:** Flutter 3.47.1, Dart 3.13.1, `supabase_flutter` 2.17.2, iOS custom URL schemes, Android intent filters, Flutter unit/widget/integration tests

**Spec:** `DESIGN.md`, `ARCHITECTURE.md`, and the Supabase Flutter documentation for [signUp](https://supabase.com/docs/reference/dart/auth-signup), [onAuthStateChange](https://supabase.com/docs/reference/dart/auth-onauthstatechange), [resend](https://supabase.com/docs/reference/dart/auth-resend), and [native mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking).

## Global Constraints

- Merge `feat/email-verification-pending` before starting the implementation branches below.
- Create one new `<type>/<short-description>` branch for each task and never commit directly to `main`.
- Do not add `PENDING` to `Student.accountStatus`; an unconfirmed Supabase user has no `student` row yet.
- Keep `AccountStatus` limited to `ACTIVE` and `SUSPENDED` and keep academic status in `EnrollmentStatus`.
- Never persist or log the user's password, SMTP password, Supabase service-role key, access token, or refresh token.
- Keep the callback URL non-secret and fixed as `com.ahni.mobile://login-callback/` for the current native app.
- Reuse the typography, spacing, card, and button rules in `DESIGN.md`; wrap Korean prose with `WhitespaceWrappedText` and give unbroken identifiers explicit overflow behavior.
- Add a failing test before each production behavior, then run `./scripts/verify` before every final commit.
- Do not run a simulator. The user performs simulator and physical-device visual checks.

## File Map

- `docs/development/authentication.md`: non-secret Supabase dashboard settings and device acceptance checklist.
- `lib/core/auth/auth_gateway.dart`: Supabase signup callback URL, confirmed-session stream, and confirmation-email resend boundary.
- `lib/features/onboarding/application/onboarding_controller.dart`: pending-state transitions and confirmed-session routing.
- `lib/features/onboarding/presentation/onboarding_page.dart`: pending screen and resend feedback.
- `ios/Runner/Info.plist`: iOS registration for the `com.ahni.mobile` URL scheme.
- `android/app/src/main/AndroidManifest.xml`: Android callback intent filter.
- `test/support/onboarding_fakes.dart`: deterministic auth-event and resend test double.
- `test/unit/features/onboarding/application/onboarding_controller_test.dart`: session-event and resend state tests.
- `test/widget/student_onboarding_test.dart`: user-visible pending and resend behavior.

---

### Task 1: Configure deliverable Supabase confirmation email

**Branch:** `chore/supabase-auth-email`

**Files:**
- Create: `docs/development/authentication.md`

**Interfaces:**
- Consumes: Supabase hosted project authentication settings and an SMTP provider account.
- Produces: Confirm-email delivery to non-team school addresses and the allowed redirect `com.ahni.mobile://login-callback/`.

- [ ] **Step 1: Enable the required Supabase Auth settings**

In the Supabase dashboard:

1. Open **Authentication → Providers → Email** and keep **Confirm email** enabled.
2. Open **Authentication → URL Configuration** and add `com.ahni.mobile://login-callback/` to Redirect URLs.
3. Replace any `localhost` Site URL used for earlier tests with a safe deployed fallback URL. The native callback still comes from `emailRedirectTo`.

- [ ] **Step 2: Configure custom SMTP**

Open **Authentication → SMTP Settings**, enable custom SMTP, and enter the selected provider's host, port, username, password, sender address, and sender name. Store these values only in the Supabase dashboard or the provider's secret manager; do not put them in `.env` files committed to Git.

This step is required for delivery to arbitrary school addresses because Supabase's default SMTP service is for limited project testing.

- [ ] **Step 3: Customize the confirmation template without changing its purpose**

Keep the template as an authentication message and retain `{{ .ConfirmationURL }}` in the link:

```html
<h2>AHNI 이메일 인증</h2>
<p>아래 버튼을 눌러 학교 이메일 인증을 완료해 주세요.</p>
<p><a href="{{ .ConfirmationURL }}">이메일 인증하기</a></p>
<p>요청하지 않았다면 이 메일을 무시해 주세요.</p>
```

- [ ] **Step 4: Document only non-secret configuration**

Create `docs/development/authentication.md` containing:

```markdown
# Authentication

- Confirm email: enabled
- Native callback: `com.ahni.mobile://login-callback/`
- Allowed signup domains: managed by the Supabase Before User Created hook
- SMTP credentials: stored only in Supabase, never in this repository
- Pre-confirmation status source: `auth.users.email_confirmed_at`
- Student profile creation: after a confirmed session is available
```

- [ ] **Step 5: Verify delivery manually**

Create a fresh test account using an allowed school address. Expected: a confirmation message reaches the inbox and its link targets the Supabase verification endpoint with the configured native redirect.

- [ ] **Step 6: Commit and push**

```bash
git add docs/development/authentication.md
git commit -m "chore(auth): document Supabase email delivery"
git push -u origin chore/supabase-auth-email
```

### Task 2: Return confirmed email links to the app

**Branch:** `feat/auth-email-callback`

**Files:**
- Modify: `lib/core/auth/auth_gateway.dart`
- Modify: `lib/features/onboarding/application/onboarding_controller.dart`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `test/support/onboarding_fakes.dart`
- Modify: `test/unit/features/onboarding/application/onboarding_controller_test.dart`
- Modify: `test/widget/student_onboarding_test.dart`

**Interfaces:**
- Produces: `AuthGateway.signedInSessions`, a stream of confirmed `AuthSession` values.
- Consumes: `com.ahni.mobile://login-callback/` from Supabase signup confirmation.

- [ ] **Step 1: Write the failing confirmed-session routing test**

Add a controllable stream to `FakeAuthGateway`, then test that a signed-in event leaves the pending state and loads onboarding:

```dart
test('confirmed session continues student onboarding', () async {
  final auth = FakeAuthGateway();
  final api = FakeStudentApi()
    ..getProfileHandler = (_) => Future.error(
      const StudentApiFailure(
        StudentApiFailureKind.studentNotFound,
        '학생 정보를 등록해 주세요.',
      ),
    )
    ..getDepartmentsHandler = () async => const [testDepartment];
  final controller = OnboardingController(auth: auth, api: api);
  addTearDown(controller.dispose);
  addTearDown(auth.dispose);

  await controller.initialize();
  await controller.signUp('student@inha.edu', 'password123');
  auth.emitSignedIn(testSession);
  await pumpEventQueue();

  expect(controller.state, isA<RegistrationRequired>());
});
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
flutter test test/unit/features/onboarding/application/onboarding_controller_test.dart
```

Expected: FAIL because `signedInSessions` and `emitSignedIn` do not exist.

- [ ] **Step 3: Add the auth-event boundary**

Extend `AuthGateway`:

```dart
Stream<AuthSession> get signedInSessions;
```

Map only successful sign-in events in `SupabaseAuthGateway` so `initialSession` does not duplicate `initialize()` profile loading:

```dart
@override
Stream<AuthSession> get signedInSessions => _client.auth.onAuthStateChange
    .where(
      (state) =>
          state.event == AuthChangeEvent.signedIn && state.session != null,
    )
    .map((state) => _mapSession(state.session)!);
```

Subscribe once from `OnboardingController.initialize()`, provide an `onError` handler, route each confirmed session through `_loadProfile`, and cancel the subscription from `dispose()`.

- [ ] **Step 4: Pass the native callback when signing up**

Update the Supabase call without changing the `AuthGateway.signUp` interface:

```dart
final response = await _client.auth.signUp(
  email: email,
  password: password,
  emailRedirectTo: 'com.ahni.mobile://login-callback/',
);
```

- [ ] **Step 5: Register the iOS URL scheme**

Add this inside the root `<dict>` in `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.ahni.mobile</string>
    </array>
  </dict>
</array>
```

- [ ] **Step 6: Register the Android callback intent**

Add this under `MainActivity` in `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data
    android:scheme="com.ahni.mobile"
    android:host="login-callback" />
</intent-filter>
```

- [ ] **Step 7: Verify GREEN and the complete harness**

Run:

```bash
flutter test test/unit/features/onboarding/application/onboarding_controller_test.dart
flutter test test/widget/student_onboarding_test.dart
./scripts/verify
```

Expected: all commands exit zero. The callback path is represented by the auth stream test without launching a simulator.

- [ ] **Step 8: Commit and push**

```bash
git add lib ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml test
git commit -m "feat(auth): continue onboarding after email confirmation"
git push -u origin feat/auth-email-callback
```

### Task 3: Allow confirmation-email resend

**Branch:** `feat/auth-email-resend`

**Files:**
- Modify: `lib/core/auth/auth_gateway.dart`
- Modify: `lib/features/onboarding/application/onboarding_controller.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_page.dart`
- Modify: `test/support/onboarding_fakes.dart`
- Modify: `test/unit/features/onboarding/application/onboarding_controller_test.dart`
- Modify: `test/widget/student_onboarding_test.dart`

**Interfaces:**
- Produces: `AuthGateway.resendSignUpConfirmation(String email)` and `OnboardingController.resendConfirmation()`.
- Consumes: the email already held by `EmailVerificationPending`; no password is retained.

- [ ] **Step 1: Write the failing resend state test**

```dart
test('resending confirmation keeps the pending email and shows success', () async {
  final auth = FakeAuthGateway();
  final controller = OnboardingController(
    auth: auth,
    api: FakeStudentApi(),
  );

  await controller.signUp('student@inha.edu', 'password123');
  await controller.resendConfirmation();

  final state = controller.state as EmailVerificationPending;
  expect(auth.lastResendEmail, 'student@inha.edu');
  expect(state.message, '인증 메일을 다시 보냈어요.');
});
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```bash
flutter test test/unit/features/onboarding/application/onboarding_controller_test.dart
```

Expected: FAIL because the resend interfaces and pending feedback do not exist.

- [ ] **Step 3: Implement the Supabase resend boundary**

```dart
@override
Future<void> resendSignUpConfirmation(String email) async {
  try {
    await _client.auth.resend(type: OtpType.signup, email: email);
  } on AuthException catch (error) {
    throw AuthFailure(_safeAuthMessage(error.code));
  }
}
```

Extend `EmailVerificationPending` with `isSubmitting` and `message`. During resend, disable the resend action, retain the email, and map rate-limit failures through the existing safe authentication messages.

- [ ] **Step 4: Add the secondary resend action**

Inside the existing pending card, keep `로그인으로 돌아가기` as the filled primary action and add a text button below it:

```dart
TextButton(
  onPressed: state.isSubmitting ? null : controller.resendConfirmation,
  child: const Text('인증 메일 다시 보내기'),
)
```

Render success or error copy through the existing `_StatusMessage`. Do not add a timer or local persistence until real rate-limit behavior proves it necessary.

- [ ] **Step 5: Verify user-visible behavior**

Extend the widget test to assert:

1. Tapping resend passes only the pending email.
2. The password is never present on the pending screen or in its state.
3. The resend button is disabled while the request is active.
4. Success and rate-limit failure messages remain readable with large text.

Run:

```bash
flutter test test/unit/features/onboarding/application/onboarding_controller_test.dart
flutter test test/widget/student_onboarding_test.dart
./scripts/verify
```

Expected: all commands exit zero.

- [ ] **Step 6: Commit and push**

```bash
git add lib test
git commit -m "feat(auth): resend signup confirmation email"
git push -u origin feat/auth-email-resend
```

### Task 4: Perform the real-device acceptance check

**Branch:** No new code branch unless the check reveals a defect. Open a `fix/...` branch for each confirmed defect.

**Files:**
- Modify only if results change: `docs/development/authentication.md`

**Interfaces:**
- Consumes: a physical iOS or Android device and a fresh allowed school email address.
- Produces: evidence that the hosted email, native callback, Supabase session, and Spring profile flow work together.

- [ ] **Step 1: Run the app with non-secret client configuration**

```bash
flutter run -d <device-id> \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=<project-url> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key> \
  --dart-define=API_BASE_URL=<reachable-backend-url>
```

- [ ] **Step 2: Verify the complete new-user journey**

1. Sign up with a fresh allowed school email.
2. Confirm that the app shows `EmailVerificationPending` and retains no password.
3. Open the email and tap its confirmation link.
4. Confirm that the link opens AHNI instead of a browser `localhost` page.
5. Confirm that the app loads `GET /students/me` with the confirmed JWT.
6. Confirm that a missing profile moves to student information registration.
7. Register the profile and confirm `accountStatus` is `ACTIVE`.

- [ ] **Step 3: Verify recovery paths**

1. Request another confirmation email and verify successful delivery.
2. Trigger the provider's resend rate limit and verify safe Korean feedback.
3. Close and reopen the app after confirmation and verify the secure Supabase session restores onboarding.
4. Attempt login before confirmation and verify the existing `email_not_confirmed` guidance.

- [ ] **Step 4: Record only stable findings**

If the dashboard path or callback changes, update `docs/development/authentication.md`. Never paste addresses, tokens, message IDs, or SMTP credentials into the document.

## Self-Review

- Spec coverage: SMTP delivery, confirm-email configuration, native callback, auth event routing, resend, and device acceptance are each assigned to one task.
- Type consistency: `AuthGateway.signedInSessions`, `AuthGateway.resendSignUpConfirmation`, and `EmailVerificationPending` are used consistently across tasks.
- Scope boundary: no Spring schema, JPA entity, migration, approval workflow, or administrator notification is introduced.
- Deferred intentionally: universal links/app links, resend countdowns, background email polling, and a custom mail service remain out of scope until product or security requirements demand them.
