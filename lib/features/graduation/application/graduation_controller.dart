import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/graduation/data/graduation_api.dart';
import 'package:ahni_mobile/features/graduation/domain/graduation_overview.dart';
import 'package:flutter/foundation.dart';

enum GraduationStatus {
  initial,
  loading,
  ready,
  missing,
  failure,
  unauthorized,
}

class GraduationController extends ChangeNotifier {
  GraduationController({required this.auth, required this.api});
  final AuthGateway auth;
  final GraduationApi api;
  GraduationStatus status = GraduationStatus.initial;
  List<GraduationOverview> overview = const [];
  String? message;
  int _generation = 0;
  bool _disposed = false;
  Future<void> load() async {
    if (_disposed || status == GraduationStatus.loading) return;
    final session = auth.currentSession;
    if (session == null) {
      overview = const [];
      message = null;
      status = GraduationStatus.unauthorized;
      notifyListeners();
      return;
    }
    final generation = ++_generation;
    status = GraduationStatus.loading;
    overview = const [];
    message = null;
    notifyListeners();
    try {
      final result = await api.getOverview(session.accessToken);
      if (_disposed || generation != _generation) return;
      overview = List.unmodifiable(result);
      status = result.isEmpty
          ? GraduationStatus.missing
          : GraduationStatus.ready;
    } on GraduationApiFailure catch (failure) {
      if (_disposed || generation != _generation) return;
      status = switch (failure.kind) {
        GraduationFailureKind.unauthorized => GraduationStatus.unauthorized,
        GraduationFailureKind.policyMissing => GraduationStatus.missing,
        GraduationFailureKind.recoverable => GraduationStatus.failure,
      };
      message = failure.message;
    } on Object catch (_) {
      if (_disposed || generation != _generation) return;
      status = GraduationStatus.failure;
      message = '졸업 정보를 확인하지 못했어요. 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  void reset() {
    _generation++;
    overview = const [];
    message = null;
    status = GraduationStatus.initial;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
