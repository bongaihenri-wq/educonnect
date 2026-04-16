// lib/presentation/blocs/auth_bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Vérifier la session au démarrage
class AppStarted extends AuthEvent {}

// Enseignant : Email + Password + API Key
class TeacherLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String apiKey;

  const TeacherLoginRequested({
    required this.email,
    required this.password,
    required this.apiKey,
  });

  @override
  List<Object?> get props => [email, password, apiKey];
}

// Parent : Phone + Matricule + API Key
class ParentLoginRequested extends AuthEvent {
  final String phone;
  final String matricule;
  final String apiKey;

  const ParentLoginRequested({
    required this.phone,
    required this.matricule,
    required this.apiKey,
  });

  @override
  List<Object?> get props => [phone, matricule, apiKey];
}

class LogoutRequested extends AuthEvent {}
