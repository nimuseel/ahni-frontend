// ignore_for_file: prefer_initializing_formals

import 'package:ahni_mobile/core/auth/auth_gateway.dart';
import 'package:ahni_mobile/features/grade/data/grade_api.dart';
import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:flutter/foundation.dart';

sealed class GradeListState {
  const GradeListState();
}

class GradeListInitial extends GradeListState {
  const GradeListInitial();
}

class GradeListLoading extends GradeListState {
  const GradeListLoading();
}

class GradeListReady extends GradeListState {
  const GradeListReady(this.grades);

  final List<GradeRecord> grades;
}

class GradeListEmpty extends GradeListState {
  const GradeListEmpty();
}

class GradeListFailure extends GradeListState {
  const GradeListFailure(this.message);

  final String message;
}

class GradeListAuthenticationRequired extends GradeListState {
  const GradeListAuthenticationRequired();
}

class GradeListController extends ChangeNotifier {
  GradeListController({required AuthGateway auth, required GradeApi api})
    : _auth = auth,
      _api = api;

  final AuthGateway _auth;
  final GradeApi _api;
  GradeListState _state = const GradeListInitial();
  int _generation = 0;

  GradeListState get state => _state;

  Future<void> load({bool force = false}) async {
    if (_state is GradeListLoading) return;
    if (!force && _state is! GradeListInitial) return;

    final session = _auth.currentSession;
    if (session == null) {
      _setState(const GradeListAuthenticationRequired());
      return;
    }

    final requestGeneration = _generation;
    _setState(const GradeListLoading());
    try {
      final grades = await _api.getGrades(session.accessToken);
      if (requestGeneration != _generation) return;
      _setState(
        grades.isEmpty
            ? const GradeListEmpty()
            : GradeListReady(List.unmodifiable(grades)),
      );
    } on GradeApiFailure catch (failure) {
      if (requestGeneration != _generation) return;
      if (failure.kind == GradeApiFailureKind.unauthorized) {
        _setState(const GradeListAuthenticationRequired());
        return;
      }
      _setState(GradeListFailure(failure.userMessage));
    } on Object catch (_) {
      if (requestGeneration != _generation) return;
      _setState(const GradeListFailure('성적 목록을 불러오지 못했습니다. 다시 시도해 주세요.'));
    }
  }

  Future<void> retry() => load(force: true);

  void reset() {
    _generation++;
    _setState(const GradeListInitial());
  }

  void _setState(GradeListState next) {
    _state = next;
    notifyListeners();
  }
}
