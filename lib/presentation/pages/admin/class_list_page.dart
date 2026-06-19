// lib/presentation/pages/admin/class_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/admin_stats_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;

class ClassListPage extends StatefulWidget {
  const ClassListPage({super.key});

  @override
  State<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends State<ClassListPage> {
  final AdminStatsService _statsService = AdminStatsService();
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String? _schoolId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final state = context.read<auth.AuthBloc>().state;
      if (state is auth.Authenticated) {
        _schoolId = state.schoolId;
      }

      if (_schoolId == null) {
        setState(() {
          _isLoading = false;
          _error = 'School ID non trouvé';
        });
        return;
      }

      final classes = await _statsService.getClassesWithStats(_schoolId!);

      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Liste des Classes'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadClasses();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Erreur: $_error'),
                      ElevatedButton(
                        onPressed: _loadClasses,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _classes.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucune classe trouvée',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _classes.length,
                      itemBuilder: (context, index) => _buildClassCard(_classes[index]),
                    ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classe) {
    final name = classe['name']?.toString() ?? 'Sans nom';
    final level = classe['level']?.toString() ?? 'Non défini';
    final stats = classe['stats'] as Map<String, dynamic>? ?? {};
    final totalStudents = stats['total_students'] ?? 0;
    final boys = stats['boys'] ?? 0;
    final girls = stats['girls'] ?? 0;
    final presenceRate = stats['presence_rate'] ?? 0;
    final avgGrade = stats['average_grade'] ?? '0.00';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showClassStudents(classe),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.violet.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.meeting_room, color: AppTheme.violet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Niveau: $level',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: presenceRate >= 80
                          ? Colors.green.withOpacity(0.1)
                          : presenceRate >= 60
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$presenceRate%',
                      style: TextStyle(
                        color: presenceRate >= 80
                            ? Colors.green
                            : presenceRate >= 60
                                ? Colors.orange
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              
              // Stats rapides
              Row(
                children: [
                  _buildMiniStat(Icons.people, '$totalStudents', 'Élèves'),
                  _buildMiniStat(Icons.male, '$boys', 'Garçons'),
                  _buildMiniStat(Icons.female, '$girls', 'Filles'),
                  _buildMiniStat(Icons.grade, avgGrade, 'Moyenne'),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Bouton voir élèves
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showClassStudents(classe),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Voir les élèves'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.violet,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showClassStudents(Map<String, dynamic> classe) {
    final classId = classe['id']?.toString() ?? '';
    final className = classe['name']?.toString() ?? 'Classe';
    
    Navigator.pushNamed(
      context,
      '/admin/class-students',
      arguments: {
        'class_id': classId,
        'class_name': className,
        'school_id': _schoolId,
      },
    );
  }
}