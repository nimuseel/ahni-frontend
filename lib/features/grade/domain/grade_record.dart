class GradeDepartment {
  const GradeDepartment({required this.entityId, required this.name});

  factory GradeDepartment.fromJson(Map<String, Object?> json) {
    return GradeDepartment(
      entityId: json['entityId']! as String,
      name: json['name']! as String,
    );
  }

  final String entityId;
  final String name;
}

enum CourseCategory {
  major('MAJOR'),
  generalEducation('GENERAL_EDUCATION'),
  elective('ELECTIVE');

  const CourseCategory(this.apiName);

  final String apiName;

  static CourseCategory fromApiName(String value) {
    return CourseCategory.values.firstWhere(
      (category) => category.apiName == value,
      orElse: () => throw FormatException('Unknown course category: $value'),
    );
  }
}

class GradeCourse {
  const GradeCourse({
    required this.entityId,
    required this.code,
    required this.name,
    required this.category,
    this.department,
  });

  factory GradeCourse.fromJson(Map<String, Object?> json) {
    final department = json['department'];
    return GradeCourse(
      entityId: json['entityId']! as String,
      code: json['code']! as String,
      name: json['name']! as String,
      category: CourseCategory.fromApiName(json['category']! as String),
      department: department == null
          ? null
          : GradeDepartment.fromJson(department as Map<String, Object?>),
    );
  }

  final String entityId;
  final String code;
  final String name;
  final CourseCategory category;
  final GradeDepartment? department;
}

enum AcademicTerm {
  first('FIRST', '1학기'),
  summer('SUMMER', '여름학기'),
  second('SECOND', '2학기'),
  winter('WINTER', '겨울학기');

  const AcademicTerm(this.apiName, this.label);

  final String apiName;
  final String label;

  static AcademicTerm fromApiName(String value) {
    return AcademicTerm.values.firstWhere(
      (term) => term.apiName == value,
      orElse: () => throw FormatException('Unknown academic term: $value'),
    );
  }
}

enum GradeCode {
  aPlus('A_PLUS', 'A+'),
  aZero('A_ZERO', 'A0'),
  bPlus('B_PLUS', 'B+'),
  bZero('B_ZERO', 'B0'),
  cPlus('C_PLUS', 'C+'),
  cZero('C_ZERO', 'C0'),
  dPlus('D_PLUS', 'D+'),
  dZero('D_ZERO', 'D0'),
  f('F', 'F'),
  p('P', 'P'),
  np('NP', 'NP');

  const GradeCode(this.apiName, this.label);

  final String apiName;
  final String label;

  static GradeCode fromApiName(String value) {
    return GradeCode.values.firstWhere(
      (gradeCode) => gradeCode.apiName == value,
      orElse: () => throw FormatException('Unknown grade code: $value'),
    );
  }
}

class GradeRecord {
  const GradeRecord({
    required this.entityId,
    required this.course,
    required this.academicYear,
    required this.term,
    required this.gradeCode,
    required this.gradePoint,
    required this.credit,
    required this.rpl,
    required this.replacedGradeEntityId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GradeRecord.fromJson(Map<String, Object?> json) {
    final gradeCode = json['gradeCode'];
    final gradePoint = json['gradePoint'];
    return GradeRecord(
      entityId: json['entityId']! as String,
      course: GradeCourse.fromJson(json['course']! as Map<String, Object?>),
      academicYear: json['academicYear']! as int,
      term: AcademicTerm.fromApiName(json['term']! as String),
      gradeCode: gradeCode == null
          ? null
          : GradeCode.fromApiName(gradeCode as String),
      gradePoint: gradePoint == null ? null : (gradePoint as num).toDouble(),
      credit: (json['credit']! as num).toDouble(),
      rpl: json['rpl']! as bool,
      replacedGradeEntityId: json['replacedGradeEntityId'] as String?,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }

  final String entityId;
  final GradeCourse course;
  final int academicYear;
  final AcademicTerm term;
  final GradeCode? gradeCode;
  final double? gradePoint;
  final double credit;
  final bool rpl;
  final String? replacedGradeEntityId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get gradeLabel => rpl ? 'RPL' : gradeCode?.label ?? '미입력';

  bool get isRetake => replacedGradeEntityId != null;
}
