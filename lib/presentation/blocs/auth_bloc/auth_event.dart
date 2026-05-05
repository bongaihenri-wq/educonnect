// lib/presentation/blocs/auth_bloc/auth_event.dart
part of 'auth_bloc.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

/// Connexion par téléphone (pour tous les rôles)
class LoginWithPhoneRequested extends AuthEvent {
  final String phone;
  final String password;
  
  const LoginWithPhoneRequested({
    required this.phone,
    required this.password,
  });
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}