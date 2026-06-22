// lib/presentation/pages/auth_state_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'school_login_page.dart';
import 'parent/parent_dashboard.dart';
import 'parent/payment_pending_page.dart';
import 'parent/subscription_expired_page.dart';
import 'teacher/teacher_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'super_admin/super_admin_dashboard.dart';
import 'assistant/assistant_dashboard.dart';
import 'principal/principal_dashboard.dart';

class AuthStateRouter extends StatelessWidget {
  const AuthStateRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        print('🎯 AuthStateRouter - State: ${state.runtimeType}');

        if (state is AuthError || state is Unauthenticated) {
          return const SchoolLoginPage();
        }

        if (state is AuthLoading || state is AuthInitial) {
          return _buildSplashFallback();
        }

        if (state is SubscriptionExpired) {
          return SubscriptionExpiredPage(
            parentId: state.parentId,
            schoolId: state.schoolId,
            expiresAt: state.expiresAt,
            daysRemaining: state.daysRemaining,
            amount: state.amount,
            currency: state.currency,
            paymentPhoneNumber: state.paymentPhoneNumber,
          );
        }

        if (state is PaymentSubmittedSuccessfully || state is PaymentPending) {
          return const PaymentPendingPage();
        }

        if (state is ParentAuthenticated) {
          return const ParentDashboard();
        }

        if (state is SuperAdminAuthenticated) {
          return const SuperAdminDashboardPage();
        }

        if (state is AdminAuthenticated) {
          return const AdminDashboard();
        }

        // ✅ CORRIGÉ : Assistant sans arguments dans le constructeur
        if (state is AssistantAuthenticated) {
          return AssistantDashboard(countryCode: state.countryCode);
        }

        // ✅ CORRIGÉ : Principal SANS arguments (auto-récupération des classes)
        if (state is PrincipalAuthenticated) {
          return const PrincipalDashboard();
        }

        if (state is TeacherAuthenticated) {
          return const TeacherDashboard();
        }

        return _buildSplashFallback();
      },
    );
  }

  Widget _buildSplashFallback() {
    return const Scaffold(
      backgroundColor: Color(0xFF6C63FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'EduConnect',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chargement...',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}