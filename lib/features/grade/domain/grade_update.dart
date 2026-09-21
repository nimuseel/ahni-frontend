import 'package:ahni_mobile/features/grade/domain/grade_record.dart';

class GradeUpdate {
  const GradeUpdate({
    required this.academicYear,
    required this.term,
    required this.gradeCode,
    required this.credit,
    required this.rpl,
    required this.replacedGradeEntityId,
  });

  final int academicYear;
  final AcademicTerm term;
  final GradeCode? gradeCode;
  final double credit;
  final bool rpl;
  final String? replacedGradeEntityId;

  Map<String, Object?> toJson() {
    return {
      'academicYear': academicYear,
      'term': term.apiName,
      'gradeCode': gradeCode?.apiName,
      'credit': credit,
      'rpl': rpl,
      'replacedGradeEntityId': replacedGradeEntityId,
    };
  }
}
