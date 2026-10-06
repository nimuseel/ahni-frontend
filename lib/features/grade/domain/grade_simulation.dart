import 'package:ahni_mobile/features/grade/domain/grade_record.dart';
import 'package:ahni_mobile/features/grade/domain/grade_summary.dart';

class ExpectedGrade {
  const ExpectedGrade({
    required this.category,
    required this.credit,
    required this.gradeCode,
  });

  final CourseCategory category;
  final double credit;
  final GradeCode gradeCode;

  static double? parseCredit(String input) {
    final text = input.trim();
    if (!RegExp(r'^\d+(\.\d)?$').hasMatch(text)) return null;
    final value = double.tryParse(text);
    return value != null && value.isFinite && value > 0 && value <= 30
        ? value
        : null;
  }

  Map<String, Object?> toJson() => {
    'category': category.apiName,
    'credit': credit,
    'gradeCode': gradeCode.apiName,
  };
}

class GradeSimulation {
  const GradeSimulation({required this.current, required this.projected});

  factory GradeSimulation.fromJson(Map<String, Object?> json) =>
      GradeSimulation(
        current: _summary(json['current']! as Map<String, Object?>),
        projected: _summary(json['projected']! as Map<String, Object?>),
      );

  final GradeSummary current;
  final GradeSummary projected;

  static GradeSummary _summary(Map<String, Object?> json) {
    final result = GradeSummary.fromJson(json);
    bool valid(double gpa, double completed, double credits) =>
        gpa.isFinite &&
        gpa >= 0 &&
        gpa <= 4.5 &&
        completed.isFinite &&
        completed >= 0 &&
        credits.isFinite &&
        credits >= 0;
    if (!valid(result.gpa, result.completedCredits, result.gpaCredits) ||
        result.categories.length != CourseCategory.values.length ||
        result.categories.map((item) => item.category).toSet().length !=
            CourseCategory.values.length ||
        result.categories.any(
          (item) => !valid(item.gpa, item.completedCredits, item.gpaCredits),
        )) {
      throw const FormatException('Invalid grade simulation summary');
    }
    return result;
  }
}
