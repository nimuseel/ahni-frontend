import 'package:ahni_mobile/features/grade/domain/grade_record.dart';

List<GradeRecord> gradeReplacementCandidates({
  required List<GradeRecord> grades,
  required String courseEntityId,
  required int academicYear,
  required AcademicTerm term,
  String? currentGradeEntityId,
}) {
  final replacedByOtherGrades = grades
      .where((grade) => grade.entityId != currentGradeEntityId)
      .map((grade) => grade.replacedGradeEntityId)
      .whereType<String>()
      .toSet();

  return grades
      .where(
        (grade) =>
            grade.entityId != currentGradeEntityId &&
            grade.course.entityId == courseEntityId &&
            !grade.rpl &&
            !replacedByOtherGrades.contains(grade.entityId) &&
            _isEarlierThan(grade, academicYear, term),
      )
      .toList(growable: false);
}

bool _isEarlierThan(GradeRecord grade, int academicYear, AcademicTerm term) {
  if (grade.academicYear != academicYear) {
    return grade.academicYear < academicYear;
  }
  return grade.term.index < term.index;
}
