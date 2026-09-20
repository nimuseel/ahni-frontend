import 'package:ahni_mobile/features/grade/domain/grade_record.dart';

class GradeCategorySummary {
  const GradeCategorySummary({
    required this.category,
    required this.gpa,
    required this.completedCredits,
    required this.gpaCredits,
  });

  factory GradeCategorySummary.fromJson(Map<String, Object?> json) {
    return GradeCategorySummary(
      category: CourseCategory.fromApiName(json['category']! as String),
      gpa: (json['gpa']! as num).toDouble(),
      completedCredits: (json['completedCredits']! as num).toDouble(),
      gpaCredits: (json['gpaCredits']! as num).toDouble(),
    );
  }

  final CourseCategory category;
  final double gpa;
  final double completedCredits;
  final double gpaCredits;
}

class GradeSummary {
  const GradeSummary({
    required this.gpa,
    required this.completedCredits,
    required this.gpaCredits,
    required this.categories,
  });

  factory GradeSummary.fromJson(Map<String, Object?> json) {
    return GradeSummary(
      gpa: (json['gpa']! as num).toDouble(),
      completedCredits: (json['completedCredits']! as num).toDouble(),
      gpaCredits: (json['gpaCredits']! as num).toDouble(),
      categories: (json['categories']! as List<Object?>)
          .map(
            (item) =>
                GradeCategorySummary.fromJson(item! as Map<String, Object?>),
          )
          .toList(growable: false),
    );
  }

  final double gpa;
  final double completedCredits;
  final double gpaCredits;
  final List<GradeCategorySummary> categories;
}
