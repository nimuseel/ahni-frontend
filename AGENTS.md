# AHNI Mobile Agent Guide

## Mission

이 저장소는 AHNI 학생용 Flutter 앱입니다. 학생이 성적, 졸업요건, 장학요건, 시간표, 수강추천, 공지와 문의를 모바일에서 확인하고 관리합니다.

## Repository Map

```text
lib/       Flutter application code and future feature modules
test/      unit, widget, and integration tests
android/   Android host project
ios/       iOS host project
docs/      architecture, domain, development, reliability
scripts/   repeatable verification commands
```

## Where to Look

| Task | Read first |
| --- | --- |
| Add a screen | `ARCHITECTURE.md`, `docs/development/testing.md` |
| Add academic calculation | `docs/domain/index.md`, `test/` |
| Change API integration | `docs/architecture/boundaries.md`, `docs/reliability/errors.md` |
| Change permissions | `docs/security/README.md` |

## Commands

```bash
flutter pub get
flutter analyze
flutter test
./scripts/verify
```

## Invariants

- Widget code presents state; domain calculations stay in pure Dart classes.
- API and device permission failures have explicit loading, empty, error, and retry states.
- Student-owned data is never displayed from an unverified account scope.
- Network, location, notification, and file permissions are requested at the point of need.
- Every user-visible behavior has a widget or integration test; pure rules have unit tests.
- `./scripts/verify` passes before completion.

## Definition of Done

The affected tests, `flutter analyze`, and `./scripts/verify` pass. New screens include accessibility labels and documented error states.
- 커밋 또는 PR 작업 | `docs/development/git-workflow.md`
