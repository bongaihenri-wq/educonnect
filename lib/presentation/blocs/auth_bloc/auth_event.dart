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

/// ⭐ NOUVEAU : Parent soumet une référence de paiement
class PaymentReferenceSubmitted extends AuthEvent {
  final String parentId;
  final String schoolId;
  final String reference;
  final double amount;
  final String? phoneNumber; // Numéro utilisé pour le dépôt

  const PaymentReferenceSubmitted({
    required this.parentId,
    required this.schoolId,
    required this.reference,
    required this.amount,
    this.phoneNumber,
  });
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}