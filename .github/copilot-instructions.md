# AHNI Mobile Review Rules

- Use the stable Flutter channel and keep `pubspec.lock` committed.
- Keep business rules in pure Dart classes, outside widget build methods.
- Test domain rules with unit tests and user-visible behavior with widget tests.
- Model loading, empty, error, retry, and permission states explicitly.
- Run `./scripts/verify` before considering a change complete.
- 커밋·푸시 전에는 `docs/development/git-workflow.md`를 따르고, 사용자 요청 없이 자동 커밋·푸시하지 않습니다.
