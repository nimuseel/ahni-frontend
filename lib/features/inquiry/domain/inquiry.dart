class Inquiry {
  const Inquiry({
    required this.entityId,
    required this.title,
    required this.content,
    required this.status,
    required this.answer,
    required this.answeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inquiry.fromJson(Map<String, Object?> json) {
    return Inquiry(
      entityId: json['entityId']! as String,
      title: json['title']! as String,
      content: json['content']! as String,
      status: json['status']! as String,
      answer: json['answer'] as String?,
      answeredAt: _optionalDateTime(json['answeredAt']),
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
    );
  }

  final String entityId;
  final String title;
  final String content;
  final String status;
  final String? answer;
  final DateTime? answeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get statusLabel {
    return switch (status) {
      'SUBMITTED' => '접수됨',
      'IN_REVIEW' => '확인 중',
      'ANSWERED' => '답변 완료',
      'CLOSED' => '종료',
      _ => '확인 필요',
    };
  }

  bool get canEdit => status == 'SUBMITTED' || status == 'IN_REVIEW';

  static DateTime? _optionalDateTime(Object? value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}

class InquiryDraft {
  const InquiryDraft({required this.title, required this.content});

  final String title;
  final String content;

  Map<String, Object> toJson() {
    return {'title': title.trim(), 'content': content.trim()};
  }
}
