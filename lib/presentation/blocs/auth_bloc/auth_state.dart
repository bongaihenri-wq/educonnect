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

/// État de base authentifié
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

// ⭐ NOUVEAU : Super Admin — pas lié à une école spécifique
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

class TeacherAuthenticated extends Authenticated {
  const TeacherAuthenticated({
    required super.userId,
    required super.firstName,
    required super.lastName,
    required super.schoolId,
    required super.schoolName,
 }) : super(role: 'teacher');
// ignore: empty_constructor_bodies
}

class ParentAuthenticated extends Authenticated {
  final String studentId;
  final String studentName;
  final String studentMatricule;
  final String className;



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
  }) : super(role: 'parent');
}