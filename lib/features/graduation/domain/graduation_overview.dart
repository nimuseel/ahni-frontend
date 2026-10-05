class CreditProgress {
  const CreditProgress({
    required this.required,
    required this.completed,
    required this.remaining,
    required this.met,
  });
  factory CreditProgress.fromJson(Map<String, Object?> json) => CreditProgress(
    required: _number(json['required']),
    completed: _number(json['completed']),
    remaining: _number(json['remaining']),
    met: json['met']! as bool,
  );
  final double required;
  final double completed;
  final double remaining;
  final bool met;
  static double _number(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      throw const FormatException('Invalid credit progress');
    }
    return value.toDouble();
  }
}

class GraduationOverview {
  const GraduationOverview({
    required this.entityId,
    required this.departmentName,
    required this.majorType,
    required this.admissionYear,
    required this.sourceTitle,
    required this.sourceUrl,
    required this.total,
    required this.department,
    required this.general,
  });
  factory GraduationOverview.fromJson(
    Map<String, Object?> requirement,
    Map<String, Object?> progress,
  ) {
    final owner = requirement['department']! as Map<String, Object?>;
    final progressOwner = progress['department']! as Map<String, Object?>;
    if (requirement['entityId'] != progress['requirementEntityId'] ||
        owner['entityId'] != progressOwner['entityId'] ||
        requirement['admissionYear'] != progress['admissionYear'] ||
        requirement['majorType'] != progress['majorType']) {
      throw const FormatException('Mismatched graduation policy');
    }
    final type = requirement['majorType']! as String;
    if (!{'PRIMARY', 'DOUBLE_MAJOR', 'MINOR'}.contains(type)) {
      throw const FormatException('Unknown major type');
    }
    final credits = progress['credits']! as Map<String, Object?>;
    return GraduationOverview(
      entityId: requirement['entityId']! as String,
      departmentName: owner['name']! as String,
      majorType: type,
      admissionYear: requirement['admissionYear']! as int,
      sourceTitle: requirement['sourceTitle']! as String,
      sourceUrl: requirement['sourceUrl'] as String?,
      total: CreditProgress.fromJson(credits['total']! as Map<String, Object?>),
      department: CreditProgress.fromJson(
        credits['department']! as Map<String, Object?>,
      ),
      general: CreditProgress.fromJson(
        credits['general']! as Map<String, Object?>,
      ),
    );
  }
  final String entityId;
  final String departmentName;
  final String majorType;
  final int admissionYear;
  final String sourceTitle;
  final String? sourceUrl;
  final CreditProgress total;
  final CreditProgress department;
  final CreditProgress general;
  bool get creditsMet => total.met && department.met && general.met;
  String get majorLabel => switch (majorType) {
    'PRIMARY' => '주전공',
    'DOUBLE_MAJOR' => '복수전공',
    _ => '부전공',
  };
}
