# Domain Map

- Academic records: courses, credits, grades, GPA, RPL, retakes.
- Graduation and scholarships: criteria vary by entry year and department.
- Timetable: conflict detection, custom start times, alarms, permission state.
- Recommendations: prerequisites, graduation urgency, professor preference.
- Notices and inquiries: authenticated student scope and notification state.

Pure domain rules must not import Flutter widgets or platform plugins.

평점 시뮬레이션은 `성적` 화면의 계산기 버튼에서 시작합니다. 과목 분류·학점·예상 등급을 입력하고 `POST /api/v1/grades/simulation`이 반환한 현재·예상 GPA와 이수학점을 비교합니다. 화면에서는 GPA를 자체 계산하지 않습니다.

예상 과목은 최대 50건이며 실제 성적이나 기기에 저장하지 않습니다. 입력 변경, 화면 종료, 학생 계정 변경 시 결과를 초기화합니다. 실패 시 입력을 유지하여 다시 계산할 수 있고, 인증 만료 시 로그인으로 돌아갑니다. 예상 재수강/RPL과 목표 평점 역산은 이번 범위에 포함하지 않습니다.

단위·위젯·호스트 통합 테스트는 `./scripts/verify`로 검증합니다. 기기 확인은 로그인 → 성적 → 평점 시뮬레이션 → 예상 성적 입력 → 계산 → 입력 수정 후 재계산 순서로 진행합니다. 실제 성적 목록이 바뀌지 않는지도 확인합니다.
