// lib/presentation/pages/parent/widgets/child_card.dart
import 'package:educonnect/presentation/pages/parent/parent_attendance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme.dart';
import '../../../blocs/auth_bloc/auth_bloc.dart';
import '../child_detail_page.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mon enfant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.nightBlue,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                // ✅ CORRIGÉ : Vérifier ParentAuthenticated avec données
                if (state is ParentAuthenticated && state.studentId.isNotEmpty) {
                  final nameParts = state.studentName.split(' ');
                  final firstName = nameParts.isNotEmpty ? nameParts.first : '';
                  final lastName = nameParts.length > 1 ? nameParts.last : '';
                  
                  return GestureDetector(
                    onTap: () => _navigateToDetail(context, state),
                    child: _buildCard(
                      firstName: firstName,
                      lastName: lastName,
                      className: state.className,
                      school: state.schoolName,
                      matricule: state.studentMatricule,
                      relationship: 'Parent',
                    ),
                  );
                } else if (state is ParentAuthenticated && state.studentId.isEmpty) {
                  // ✅ AJOUTÉ : Message si aucun enfant lié
                  return _buildNoChildCard();
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ AJOUTÉ : Carte "Aucun enfant lié"
  Widget _buildNoChildCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucun enfant lié',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contactez l\'administration pour lier votre compte à un élève.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

void _navigateToDetail(BuildContext context, ParentAuthenticated state) {
  if (state.studentId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erreur: ID élève manquant'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // ✅ NAVIGATION VERS SUIVI DE L'ÉLÈVE (pas ParentAttendancePage)
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChildDetailPage(
        studentId: state.studentId,
        studentName: state.studentName,
        studentMatricule: state.studentMatricule,
        className: state.className,
        parentName: '${state.firstName} ${state.lastName}',
        schoolName: state.schoolName,
        initialTab: 0, // Onglet Présences (premier)
      ),
    ),
  );
}

  Widget _buildCard({
    required String firstName,
    required String lastName,
    required String className,
    required String school,
    required String matricule,
    required String relationship,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bisDark, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(firstName, lastName),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$firstName $lastName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.nightBlue,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildClassChip(className),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  school,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.nightBlueLight.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Matricule: $matricule • $relationship',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.nightBlueLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.violet,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String firstName, String lastName) {
    final initial1 = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final initial2 = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.violet, AppTheme.violet.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '$initial1$initial2',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildClassChip(String className) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        className,
        style: const TextStyle(
          color: AppTheme.violet,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
