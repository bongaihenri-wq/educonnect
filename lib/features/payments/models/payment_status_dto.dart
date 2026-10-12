class PaymentStatusDto {
  final String id;
  final String studentId;
  final String classId;
  final String studentName;
  final String matricule;
  final double amountDue;
  final double amountPaid;
  final bool isUpToDate;
  final bool contested;
  final DateTime? updatedAt;

  const PaymentStatusDto({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.studentName,
    required this.matricule,
    required this.amountDue,
    required this.amountPaid,
    required this.isUpToDate,
    required this.contested,
    this.updatedAt,
  });

  double get remaining => amountDue - amountPaid;

  factory PaymentStatusDto.fromJson(Map<String, dynamic> json) {
    final s = json['students'] as Map<String, dynamic>? ?? {};
    return PaymentStatusDto(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      classId: s['class_id'] as String? ?? '',
      studentName: '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim(),
      matricule: s['matricule'] as String? ?? '',
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      isUpToDate: json['is_up_to_date'] as bool? ?? true,
      contested: json['contested'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
