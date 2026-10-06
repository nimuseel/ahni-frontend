import 'dart:async';

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/application/grade_simulation_controller.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_simulation.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/grade_fakes.dart';
import '../../../../support/onboarding_fakes.dart';

const expected = ExpectedGrade(
  category: CourseCategory.major,
  credit: 3,
  gradeCode: GradeCode.aPlus,
);

void main() {
  test(
    'uses the signed-in account and returns the backend comparison',
    () async {
      final auth = FakeAuthGateway(currentSession: testSession);
      final api = FakeGradeApi()
        ..simulationHandler = (token, rows) async {
          expect(token, testSession.accessToken);
          expect(rows.single.credit, 3);
          return const GradeSimulation(
            current: testGradeSummary,
            projected: testGradeSummary,
          );
        };
      final controller = GradeSimulationController(auth: auth, api: api);
      await controller.submit([expected]);
      expect(
        controller.state,
        isA<GradeSimulationReady>().having(
          (state) => state.result.current.gpa,
          'current',
          3.83,
        ),
      );
      controller.reset();
      expect(controller.state, isA<GradeSimulationIdle>());
    },
  );

  test('does not calculate without a session', () async {
    final controller = GradeSimulationController(
      auth: FakeAuthGateway(),
      api: FakeGradeApi(),
    );
    await controller.submit([expected]);
    expect(controller.state, isA<GradeSimulationAuthenticationRequired>());
  });

  test(
    'ignores late responses after reset and allows a new calculation',
    () async {
      final pending = Completer<GradeSimulation>();
      final api = FakeGradeApi()..simulationHandler = (_, _) => pending.future;
      final controller = GradeSimulationController(
        auth: FakeAuthGateway(currentSession: testSession),
        api: api,
      );
      final request = controller.submit([expected]);
      expect(controller.state, isA<GradeSimulationSubmitting>());
      controller.reset();
      pending.complete(
        const GradeSimulation(
          current: testGradeSummary,
          projected: testGradeSummary,
        ),
      );
      await request;
      expect(controller.state, isA<GradeSimulationIdle>());
      await controller.submit([expected]);
      expect(controller.state, isA<GradeSimulationReady>());
    },
  );

  test('does not display a previous account result', () async {
    final pending = Completer<GradeSimulation>();
    final auth = FakeAuthGateway(currentSession: testSession);
    final controller = GradeSimulationController(
      auth: auth,
      api: FakeGradeApi()..simulationHandler = (_, _) => pending.future,
    );
    final request = controller.submit([expected]);
    auth.currentSession = const AuthSession(
      accessToken: 'other-token',
      email: 'other@inha.edu',
    );
    pending.complete(
      const GradeSimulation(
        current: testGradeSummary,
        projected: testGradeSummary,
      ),
    );
    await request;
    expect(controller.state, isA<GradeSimulationAuthenticationRequired>());
  });

  test(
    'rejects duplicate submissions and ignores responses after disposal',
    () async {
      final pending = Completer<GradeSimulation>();
      var requests = 0;
      final controller = GradeSimulationController(
        auth: FakeAuthGateway(currentSession: testSession),
        api: FakeGradeApi()
          ..simulationHandler = (_, _) {
            requests++;
            return pending.future;
          },
      );
      final request = controller.submit([expected]);
      await controller.submit([expected]);
      expect(requests, 1);
      controller.dispose();
      pending.complete(
        const GradeSimulation(
          current: testGradeSummary,
          projected: testGradeSummary,
        ),
      );
      await request;
    },
  );

  test(
    'recoverable failure preserves a retry path and expired auth needs sign-in',
    () async {
      final api = FakeGradeApi()
        ..error = const GradeApiFailure(
          GradeApiFailureKind.recoverable,
          '다시 시도해 주세요.',
        );
      final controller = GradeSimulationController(
        auth: FakeAuthGateway(currentSession: testSession),
        api: api,
      );
      await controller.submit([expected]);
      expect(controller.state, isA<GradeSimulationFailure>());
      api.error = null;
      await controller.submit([expected]);
      expect(controller.state, isA<GradeSimulationReady>());
      api.error = const GradeApiFailure(
        GradeApiFailureKind.unauthorized,
        '다시 로그인해 주세요.',
      );
      await controller.submit([expected]);
      expect(controller.state, isA<GradeSimulationAuthenticationRequired>());
    },
  );
}
