# AHNI Mobile Review Rules

- Use Flutter 3.47.1 stable with Dart 3.13.1 and keep `pubspec.lock` committed.
- Keep business rules in pure Dart classes, outside widget build methods.
- Test domain rules with unit tests and user-visible behavior with widget tests.
- Keep `lib/core` independent from `lib/features`; domain code must not import Flutter or presentation code.
- Treat `contracts/backend-openapi.json` as backend-owned generated output. Never edit it manually.
- Review API changes for contract version impact, authentication requirements, stable errors, and affected clients.
- Never connect the mobile app directly to Supabase PostgreSQL. Authentication tokens belong behind a future secure-storage adapter.
- Model loading, empty, error, retry, and permission states explicitly.
- Require relevant unit, widget, and integration-layer tests for changed behavior.
- Run `./scripts/verify` before considering a change complete.
- 커밋·푸시 전에는 `docs/development/git-workflow.md`를 따르고, 사용자 요청 없이 자동 커밋·푸시하지 않습니다.
