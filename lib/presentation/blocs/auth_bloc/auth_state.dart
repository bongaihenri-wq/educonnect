// lib/presentation/blocs/auth_bloc/auth_state.dart
part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class TeacherAuthenticated extends AuthState {
  final Map<String, dynamic> userData;
  final String schoolName;
  final String schoolId;

  const TeacherAuthenticated({
    required this.userData,
    required this.schoolName,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [userData, schoolName, schoolId];
}

class ParentAuthenticated extends AuthState {
  final Map<String, dynamic> parentData;
  final Map<String, dynamic> studentData;
  final String relationship;
  final String schoolName;
  final String schoolId;

  const ParentAuthenticated({
    required this.parentData,
    required this.studentData,
    required this.relationship,
    required this.schoolName,
    required this.schoolId,
  });

  @override
  List<Object?> get props => [parentData, studentData, relationship, schoolName, schoolId];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}