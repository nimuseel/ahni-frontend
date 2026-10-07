# GitHub 자동화

## 동작

- `feat/**`, `fix/**`, `docs/**`, `refactor/**`, `chore/**` 브랜치에 푸시하면 `auto-pr.yml`이 `main` 대상 PR을 자동 생성합니다.
- 동일한 브랜치에 열린 PR이 있으면 새 PR을 만들지 않습니다.
- push 사용자별 PAT로 PR을 생성하거나 기존 PR의 커밋 내역 섹션을 갱신합니다. Secret 누락·소유자 불일치 시 PR 처리와 리뷰 요청을 중단합니다.
- PR 생성 후 `gh pr edit --add-reviewer "@copilot"`으로 Copilot 리뷰를 요청합니다.
- PR과 대상 브랜치에 `ci.yml`이 실행되며 `./scripts/verify`가 통과해야 합니다.

## GitHub에서 한 번만 설정할 항목

저장소 Settings → Secrets and variables → Actions에 작업자별 `GH_PAT_<사용자 ID 대문자>`를 등록합니다. 하이픈은 밑줄로 바꿉니다. 예: `GH_PAT_NIMUSEEL`. 공용 `GH_PAT`는 사용하지 않습니다. 권한·외부 협업자 제한·등록 방법은 [작업자별 설정 안내](automatic-pr.md)를 따릅니다.

저장소 Settings의 Copilot automatic code review에서 다음을 활성화합니다.

- Automatically request Copilot code review for every pull request
- Review new pushes
- 필요하면 Review draft pull requests

Copilot 리뷰는 의견(Comment) 리뷰이며 사람의 승인이나 병합 차단을 대체하지 않습니다. Copilot 요금제, AI credits, GitHub Actions 사용량 및 저장소 권한이 필요합니다.
