import 'package:ahni_mobile/features/graduation/application/graduation_controller.dart';
import 'package:ahni_mobile/features/graduation/data/graduation_api.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';

import 'onboarding_fakes.dart';

GraduationController buildTestGraduationController() => GraduationController(
  auth: FakeAuthGateway(currentSession: testSession),
  api: FakeGraduationApi(),
);

class FakeGraduationApi implements GraduationApi {
  List<GraduationOverview> results = const [];
  Future<List<GraduationOverview>> Function(String)? handler;
  @override
  Future<List<GraduationOverview>> getOverview(String token) async =>
      handler == null ? results : handler!(token);
}
