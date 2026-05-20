// lib/data/models/role_model.dart
class RoleModel {
  final String id;
  final String code;
  final String name;
  final int level;
  final String? countryCode;
  final String? schoolId;
  final bool isActive;
  final DateTime createdAt;

  RoleModel({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    this.countryCode,
    this.schoolId,
    this.isActive = true,
    required this.createdAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      level: json['level'] ?? 0,
      countryCode: json['country_code']?.toString(),
      schoolId: json['school_id']?.toString(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'level': level,
      'country_code': countryCode,
      'school_id': schoolId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Rôles gérés par import (non modifiables par Super Admin)
  bool get isImportManaged => ['teacher', 'parent', 'student'].contains(code);
  
  // Rôle global (sans pays/école spécifique)
  bool get isGlobal => countryCode == null && schoolId == null;
}