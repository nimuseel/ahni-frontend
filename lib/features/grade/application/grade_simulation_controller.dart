import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_simulation.dart';
import 'package:flutter/foundation.dart';

sealed class GradeSimulationState {
  const GradeSimulationState();
}

class GradeSimulationIdle extends GradeSimulationState {
  const GradeSimulationIdle();
}

class GradeSimulationSubmitting extends GradeSimulationState {
  const GradeSimulationSubmitting();
}

class GradeSimulationReady extends GradeSimulationState {
  const GradeSimulationReady(this.result);
  final GradeSimulation result;
}

class GradeSimulationFailure extends GradeSimulationState {
  const GradeSimulationFailure(this.message);
  final String message;
}

class GradeSimulationAuthenticationRequired extends GradeSimulationState {
  const GradeSimulationAuthenticationRequired();
}

class GradeSimulationController extends ChangeNotifier {
  GradeSimulationController({required this.auth, required this.api});
  final AuthGateway auth;
  final GradeApi api;
  GradeSimulationState _state = const GradeSimulationIdle();
  int _generation = 0;
  bool _disposed = false;
  GradeSimulationState get state => _state;

  Future<void> submit(List<ExpectedGrade> grades) async {
    if (_disposed || _state is GradeSimulationSubmitting) return;
    final session = auth.currentSession;
    if (session == null) {
      _setState(const GradeSimulationAuthenticationRequired());
      return;
    }
    final generation = _generation;
    _setState(const GradeSimulationSubmitting());
    try {
      final result = await api.simulateGrades(
        session.accessToken,
        List.unmodifiable(grades),
      );
      if (!_accept(generation, session.email)) return;
      _setState(GradeSimulationReady(result));
    } on GradeApiFailure catch (failure) {
      if (!_accept(generation, session.email)) return;
      _setState(
        failure.kind == GradeApiFailureKind.unauthorized
            ? const GradeSimulationAuthenticationRequired()
            : GradeSimulationFailure(failure.userMessage),
      );
    } on Object catch (_) {
      if (!_accept(generation, session.email)) return;
      _setState(const GradeSimulationFailure('예상 평점을 계산하지 못했어요. 다시 시도해 주세요.'));
    }
  }

  bool _accept(int generation, String email) {
    if (_disposed || generation != _generation) return false;
    if (auth.currentSession?.email != email) {
      _setState(const GradeSimulationAuthenticationRequired());
      return false;
    }
    return true;
  }

  void reset() {
    _generation++;
    if (!_disposed) _setState(const GradeSimulationIdle());
  }

  void _setState(GradeSimulationState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
