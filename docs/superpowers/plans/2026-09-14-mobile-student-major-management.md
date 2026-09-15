# Mobile Student Major Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Do not dispatch subagents or create a worktree. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let students register, view, and replace one primary major plus optional double-major and minor selections from the Flutter app.

**Architecture:** Keep the existing `StudentApi` boundary and onboarding state machine. Extend the wire models for the backend contract, add one `MajorEditing` state that owns department loading and update feedback, and reuse the existing form/card/dropdown patterns instead of adding navigation or dependencies.

**Tech Stack:** Flutter 3.47.1, Dart 3.13.1, Material 3, `http` 1.6.0, Flutter unit and widget tests

**Spec:** `DESIGN.md` and the backend-generated `contracts/backend-openapi.json`

## Global Constraints

- Work in the existing checkout on `feat/student-major-management`; do not create a worktree.
- Keep exactly one primary major and at most one double major and one minor.
- Treat “다중전공” as a UI umbrella; do not add a `MULTIPLE_MAJOR` wire value.
- Omit absent optional department identifiers from request JSON.
- Reject duplicate department choices before calling the backend and handle `DUPLICATE_MAJOR_DEPARTMENT` if the backend rejects a stale or forged request.
- Keep the current AHNI tokens, whitespace-only wrapping, 44-pixel touch targets, and single-column form layout from `DESIGN.md`.
- Do not add packages, routes, local persistence, optimistic updates, or administrator behavior.
- Write a failing test before each production behavior and run `./scripts/verify` before the final commit.
- Do not launch a simulator; device visual verification remains user-run.

---

### Task 1: Pin and consume the backend contract

**Files:**
- Modify: `contracts/backend-openapi.json`
- Modify: `docs/development/api-contract.md`
- Modify: `test/unit/contracts/backend_openapi_contract_test.dart`
- Modify: `lib/core/network/student_api.dart`
- Modify: `test/unit/core/network/student_api_test.dart`

**Interfaces:**
- Extend `StudentProfile` with nullable `doubleMajorDepartment` and `minorDepartment`.
- Extend `StudentRegistration` with nullable department identifiers.
- Add `StudentMajorUpdate` and `StudentApi.replaceMajors(String, StudentMajorUpdate)`.

- [ ] Add contract assertions for `PUT /api/v1/students/me/majors` and the optional major fields; run the contract test and confirm it fails against the old snapshot.
- [ ] Run `./scripts/update-api-contract /Users/sumin/dev/ahni/backend/docs/api/openapi.json` and record the merged backend commit and SHA-256 in `docs/development/api-contract.md`.
- [ ] Add API tests that parse optional departments, omit absent IDs, send all selected IDs during registration, and send an authenticated PUT request.
- [ ] Run `flutter test test/unit/core/network/student_api_test.dart` and confirm the new tests fail before implementation.
- [ ] Implement the minimal models, JSON serialization, PUT request, and safe `DUPLICATE_MAJOR_DEPARTMENT` message.
- [ ] Re-run the API and contract tests.
- [ ] Commit as `feat(major): 모바일 전공 API 계약 연동`.

### Task 2: Extend registration selection

**Files:**
- Modify: `lib/features/onboarding/presentation/onboarding_page.dart`
- Modify: `test/widget/student_onboarding_test.dart`
- Modify: `DESIGN.md`

**Interfaces:**
- Registration submits primary, optional double-major, and optional minor IDs through `StudentRegistration`.
- A private reusable department dropdown uses the existing input tokens and exposes a clear action for optional values.

- [ ] Extend the registration widget test to choose three distinct departments and assert all IDs reach `FakeStudentApi`; confirm it fails first.
- [ ] Add widget tests for primary-required and duplicate-department validation without an API call.
- [ ] Add the two optional dropdowns, preserve values during submission failures, and validate cross-field duplicates on submit.
- [ ] Document the reused department selector primitive in `DESIGN.md` without adding tokens.
- [ ] Run `flutter test test/widget/student_onboarding_test.dart`.
- [ ] Commit as `feat(major): 가입 전공 선택 확장`.

### Task 3: Add profile display and complete replacement

**Files:**
- Modify: `lib/features/onboarding/application/onboarding_controller.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_page.dart`
- Modify: `test/support/onboarding_fakes.dart`
- Modify: `test/unit/features/onboarding/application/onboarding_controller_test.dart`
- Modify: `test/widget/student_onboarding_test.dart`

**Interfaces:**
- Add `MajorEditing(profile, departments, message, isSubmitting)`.
- Add `OnboardingController.startMajorEditing()`, `cancelMajorEditing()`, and `updateMajors(StudentMajorUpdate)`.
- Add `FakeStudentApi.replaceMajorsHandler` and `lastMajorUpdate`.

- [ ] Add controller tests for department loading, successful replacement, retained edit values after validation failure, and unauthorized return to login; confirm they fail first.
- [ ] Implement the new state transitions using the current JWT and the existing safe failure mapping.
- [ ] Add widget tests that render all three majors, enter edit mode, clear an optional major, replace another, and show the updated profile.
- [ ] Implement the profile major section and single-column editor with save and cancel actions.
- [ ] Run the focused controller and widget tests.
- [ ] Commit as `feat(major): 프로필 전공 조회 및 수정 지원`.

### Task 4: Verify and publish

**Files:**
- Verify all files changed in Tasks 1-3.

- [ ] Run `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Run `./scripts/verify` and require a zero exit code.
- [ ] Run `git diff --check origin/main...HEAD` and inspect the complete diff for secrets and unrelated changes.
- [ ] Push `feat/student-major-management` to origin. Device and simulator visual checks are the post-push acceptance step performed by the user.
