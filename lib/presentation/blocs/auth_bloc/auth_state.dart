// lib/presentation/blocs/auth_bloc/auth_state.dart
part of 'auth_bloc.dart';

abstract class AuthState {
  const AuthState();
  get userId => null;
  get schoolId => null;
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

abstract class Authenticated extends AuthState {
  final String userId;
  final String firstName;
  final String lastName;
  final String schoolId;
  final String schoolName;
  final String role;
  
  const Authenticated({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.schoolId,
    required this.schoolName,
    required this.role,
  });
}

class SubscriptionExpired extends AuthState {
  final String parentId;
  final String? schoolId;
  final DateTime? expiresAt;
  final int? daysRemaining;
  final int amount;
  final String currency;
  final String? paymentPhoneNumber;

  const SubscriptionExpired({
    required this.parentId,
    this.schoolId,
    this.expiresAt,
    this.daysRemaining,
    this.amount = 1000,
    this.currency = 'XOF',
    this.paymentPhoneNumber,
  });

  @override
  get userId => parentId;
}

class SuperAdminAuthenticated extends AuthState {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  const SuperAdminAuthenticated({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
  });

  @override
  get schoolId => null;
}

class AdminAuthenticated extends Authenticated {
  const AdminAuthenticated({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.schoolId,
    required super.schoolName,
  }) : super(role: 'admin');
}

// ✅ MODIFIÉ : Ajout countryCode
class AssistantAuthenticated extends Authenticated {
  final String countryCode;
  
  const AssistantAuthenticated({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.schoolId,
    required super.schoolName,
    required this.countryCode,
  }) : super(role: 'assistant');
}

// ✅ NOUVEAU : Principal (Professeur Principal)
class PrincipalAuthenticated extends Authenticated {
  final String classId;
  final String className;
  
  const PrincipalAuthenticated({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.schoolId,
    required super.schoolName,
    required this.classId,
    required this.className,
  }) : super(role: 'principal');
}

class TeacherAuthenticated extends Authenticated {
  const TeacherAuthenticated({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.schoolId,
    required super.schoolName,
  }) : super(role: 'teacher');
}

class ParentAuthenticated extends Authenticated {
  final String studentId;
  final String studentName;
  final String studentMatricule;
  final String className;
  
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;
  final int? daysRemaining;
  final int? subscriptionAmount;
  final String? subscriptionCurrency;
  final String? paymentPhoneNumber;

  const ParentAuthenticated({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.schoolId,
    required super.schoolName,
    required this.studentId,
    required this.studentName,
    required this.studentMatricule,
    required this.className,
    this.subscriptionStatus,
    this.subscriptionEndDate,
    this.daysRemaining,
    this.subscriptionAmount,
    this.subscriptionCurrency,
    this.paymentPhoneNumber,
  }) : super(role: 'parent');
}

class PaymentPending extends AuthState {
  final String parentId;
  final String reference;
  final double amount;
  const PaymentPending({
    required this.parentId,
    required this.reference,
    required this.amount,
  });
  @override
  get userId => parentId;
}

class PaymentSubmittedSuccessfully extends AuthState {
  final String parentId;
  final String reference;
  final double amount;
  final DateTime submittedAt;
  final String? screenshotUrl;
  const PaymentSubmittedSuccessfully({
    required this.parentId,
    required this.reference,
    required this.amount,
    required this.submittedAt,
    this.screenshotUrl,
  });
}