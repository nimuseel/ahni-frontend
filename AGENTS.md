# AHNI Mobile Agent Guide

## Mission

이 저장소는 AHNI 학생용 Flutter 앱입니다. 학생이 성적, 졸업요건, 장학요건, 시간표, 수강추천, 공지와 문의를 모바일에서 확인하고 관리합니다.

## Repository Map

```text
lib/       Flutter application code and future feature modules
contracts/ pinned backend OpenAPI contract
test/      unit, widget, and host-independent integration tests
android/   Android host project
ios/       iOS host project
docs/      architecture, domain, development, reliability
scripts/   repeatable verification commands
```

## Where to Look

| Task | Read first |
| --- | --- |
| Add a screen | `DESIGN.md`, `ARCHITECTURE.md`, `docs/development/testing.md` |
| Add academic calculation | `docs/domain/index.md`, `test/` |
| Change API integration | `docs/development/api-contract.md`, `docs/reliability/errors.md` |
| Change permissions | `docs/security/README.md` |

## Commands

```bash
./scripts/setup
./scripts/lint
./scripts/typecheck
./scripts/test-unit
./scripts/test-widget
./scripts/test-integration
./scripts/verify
```

## Invariants

- Widget code presents state; domain calculations stay in pure Dart classes.
- `lib/core` never imports `lib/features`; feature domain code never imports Flutter or presentation code.
- The app consumes the pinned backend OpenAPI contract and never accesses Supabase PostgreSQL directly.
- Authentication tokens are introduced only through a secure-storage adapter, never in widgets or logs.
- API and device permission failures have explicit loading, empty, error, and retry states.
- Student-owned data is never displayed from an unverified account scope.
- Network, location, notification, and file permissions are requested at the point of need.
- Every user-visible behavior has a widget or integration test; pure rules have unit tests.
- Korean headings and explanatory copy use `WhitespaceWrappedText` so wrapping occurs at whitespace boundaries; identifiers and other unbroken values define their own overflow behavior.
- Typography follows `DESIGN.md`; do not enlarge display text outside the documented type scale.
- `./scripts/verify` passes before completion.

## Definition of Done

The affected unit, widget, and integration tests plus `./scripts/verify` pass on Flutter 3.47.1. New screens include accessibility labels and documented error states. API changes record contract compatibility and affected clients.
- 커밋 또는 PR 작업 | `docs/development/git-workflow.md`
