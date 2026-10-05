# Graduation Completion Flow Implementation Plan

> Execution: implement natively with superpowers:executing-plans. The user has approved this flow and requires existing checkouts, no subagents, and feature branches.

**Goal:** Students can inspect graduation credits and required-course completion while administrators maintain the shared course catalog and understand policy-edit impact.

**Architecture:** Spring Boot remains authoritative for credit and completion calculations. Flutter consumes the requirement/progress endpoints. React consumes administrator-only course and policy-impact endpoints through its validated API boundary.

**Tech Stack:** Existing Java 26 / Spring Boot, Flutter 3.47.1, React / Vite / TypeScript and their repository harnesses; no new libraries.

**Spec:** backend `docs/product/traceability.md`, `docs/superpowers/specs/2026-09-21-graduation-requirement-read-service-design.md`, `docs/superpowers/specs/2026-09-20-grade-retake-gpa-policy-design.md`; mini-spec 2.7, 3.1, 5.5 and UC-S04 / UC-A02, with accepted signup and major policies taking precedence.

## Global Constraints

- Use `PRIMARY`, `DOUBLE_MAJOR`, `MINOR`; no new major types.
- Filter out replaced attempts, F and NP; passing grades, P and RPL complete a required course.
- Compare stable course IDs. Do not infer equivalence from names or codes.
- Calculate each major independently with its exact admission-year policy.
- Present registered academic criteria, not an official graduation certification.
- Use existing colors/type and `WhitespaceWrappedText` for Korean explanatory copy.
- Never invent official course or graduation-policy data.
- Create feature branches, commit verified increments, and update generated OpenAPI plus consumer snapshots for API changes.

## Review Focus

- Never retain a previous student's data after sign-out or a changed account.
- Distinguish an unregistered policy from network failure and a missing profile.
- A retake ending in F must not mark the replaced passing attempt complete.
- Deactivation must preserve historical grades and policy assignments.
- Policy replacement must describe affected students before saving, and cancellation must send no mutation.

## Task 1: Mobile requirement and credit-progress view

**Files:** `lib/features/graduation/{domain/graduation_overview.dart,data/graduation_api.dart,application/graduation_controller.dart,presentation/graduation_page.dart}`; app/main and onboarding composition; feature API/controller/widget tests and portal navigation tests.

**Interfaces:** consumes `GET /api/v1/graduation-requirements` and `GET /api/v1/graduation-progress`; produces `GraduationApi.getOverview(String)`, `GraduationController.load/reset`, and `GraduationPage`.

- [x] Navigation RED observed (missing `졸업` destination), then GREEN.
- [x] Join and validate both endpoint results by policy ID, department, year and major type.
- [x] API/controller tests cover bearer requests, missing policy, unauthorized/malformed responses, identity mismatch, retry and stale account requests.
- [x] Per-major credits, source, missing/error/loading states, refresh on entering the tab and account reset are connected.
- [x] `./scripts/verify` passed: 71 unit, 35 widget and 1 host integration tests; first usable view committed separately.

## Task 2: Required-course completion

**Files:** backend graduation calculator/service/DTOs/controller tests and OpenAPI; mobile graduation models/page/tests and pinned contract.

**Interfaces:** adds `requiredCourses` completion results and `requirementsMet` to each progress response, alongside existing `credits`.

- [x] Backend tests cover passing/P/RPL, F/NP, missing courses, unrelated identities and explicitly replaced attempts; shared effective-attempt filtering is reused.
- [x] Active assignments return category, catalog metadata and completion in repository code order.
- [x] `requirementsMet` combines all credit thresholds and required-course completions.
- [x] Existing JWT ownership/exact-policy tests remain green; runtime OpenAPI is regenerated and pinned to backend `03c30eb`.
- [x] Mobile major/category/completion filters, source identity checks and stale-account clearing pass full verification (71 unit, 36 widget, 1 integration tests).

## Task 3: Administrator course catalog management

**Files:** backend Course entity/repositories, administrator course DTOs/service/controller/tests; admin API/contracts/routes/course list and editor/tests.

**Interfaces:** administrator list/create/update/deactivation APIs under `/api/v1/admin/courses`; student `/courses` stays active-only.

- [x] Test code normalization and duplicate conflicts, authorization, category/department validation and historical credit preservation.
- [x] Add active/inactive listing, creation, editing and explicit deactivation, keeping stable IDs and referenced records.
- [x] Reject edits that invalidate active required-course assignments.
- [x] Build admin list/edit/deactivate workflows with confirmation and accessible loading/error/retry states.
- [x] Verify backend and admin, regenerate/pin contracts and commit each verified increment (`d3da57f`, `ad4f010`).

## Task 4: Graduation-policy change impact

**Files:** backend student-major count query and administrator requirement impact endpoint/tests; admin requirement editing confirmation/tests; operating guide.

**Interfaces:** read-only impact response with the count of non-deleted student profiles matching the policy's department, admission year and major type.

- [x] Test exact matching, excluded deleted majors/profiles and administrator authorization.
- [x] Show impact count and replacement warning before saving; cancel without changing policy or sending a mutation. Lookup failures preserve entered values and block saving.
- [x] Document source-based course and policy entry, including full required-course assignment replacement, in admin `docs/operations/academic-data.md`.
- [x] Verify backend/admin and commit (`e034c44`, `47f775f`). Source documents and real production data remain operator inputs.
- [x] Preserve existing inactive required-course assignments during policy replacement while rejecting new inactive assignments; verify the browser edit flow with no selectable active courses.

## Execution record

- Plan approved by the user's instruction to follow this flow; native execution continues without another approval gate.
- Initial repository states were clean. New branches start at fetched `origin/main`; no worktrees or subagents were created.
- Task 1 mobile commit: `1c5abcb`; task 2 backend commit: `03c30eb`; task 3 backend commit: `d3da57f`. Later backend branches build on the preceding verified feature branch.
- Task 2 mobile commit: `3482bb5`; task 3 admin commit: `ad4f010`; task 4 backend/admin commits: `e034c44` / `47f775f`.
- Final backend `./scripts/verify`: 170 unit/check tests and 148 integration tests, no failures or skipped tests. Admin `./scripts/verify`: 6 unit, 20 feature/component and 4 Chromium tests; lint, dependency boundaries, typecheck and production build passed.
- Admin contract exactly matches backend `e034c442b095a3923080099edfc6d14947b93884`, SHA-256 `6ba2b3a4a588b4d6e27a5a1c5fbe8e8158a7c831f29cfbb912ee6b41416e79ff`. Mobile retains the compatible graduation contract from `03c30eb`; administrator-only additions do not alter its consumed endpoints.
- Backend/admin current branch: `feat/graduation-policy-impact`, stacked on their verified course-management branches. Mobile implementation branch: `feat/graduation-progress`; its final execution record is on `docs/graduation-completion-record`, which includes both mobile feature commits.
- Administrator browser workflows used intercepted test services; backend integration tests used isolated PostgreSQL. Desktop and 390px administrator screenshots were inspected. No production academic data was invented or inserted, and no simulator/device test was run. The user owns device verification.
- All commits are local. No push, pull request, or merge was performed in this delivery.
