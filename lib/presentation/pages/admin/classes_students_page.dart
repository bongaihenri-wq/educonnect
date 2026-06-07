// lib/presentation/pages/admin/classes_students_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/admin_stats_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import 'widgets/class_card.dart';
import 'widgets/student_detail_dialog.dart';
import 'widgets/add_student_dialog.dart';

class ClassesStudentsPage extends StatefulWidget {
  const ClassesStudentsPage({super.key});

  @override
  State<ClassesStudentsPage> createState() => _ClassesStudentsPageState();
}

class _ClassesStudentsPageState extends State<ClassesStudentsPage> {
  final AdminStatsService _statsService = AdminStatsService();
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String? _schoolId;
  String? _error;
  String? _expandedClassId;

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
        title: const Text('Classes & Élèves'),
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
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddStudentDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _classes.isEmpty
                  ? _buildEmptyWidget()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _classes.length,
                      itemBuilder: (context, index) => ClassCard(
                        classe: _classes[index],
                        isExpanded: _expandedClassId == _classes[index]['id'],
                        onToggle: () => _toggleClass(_classes[index]['id'] as String),
                        onViewStudent: _showStudentDetails,
                        onDeleteStudent: _confirmDeleteStudent,
                        onAddStudent: _showAddStudentToClassDialog,
                      ),
                    ),
    );
  }

  void _toggleClass(String classId) {
    setState(() {
      _expandedClassId = _expandedClassId == classId ? null : classId;
    });
  }

  void _showStudentDetails(Map<String, dynamic> student) async {
    final firstName = student['first_name'] ?? '';
    final lastName = student['last_name'] ?? '';
    final matricule = student['matricule'] ?? 'N/A';
    final gender = student['gender']?.toString().toLowerCase() ?? '';
    final studentId = student['id'] as String?;

    if (studentId == null || _schoolId == null) return;

    final stats = await _statsService.getStudentAttendanceStats(_schoolId!, studentId);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => StudentDetailDialog(
          firstName: firstName,
          lastName: lastName,
          matricule: matricule,
          gender: gender,
          stats: stats,
        ),
      );
    }
  }

  void _confirmDeleteStudent(Map<String, dynamic> student, String classId) {
    final firstName = student['first_name'] ?? '';
    final lastName = student['last_name'] ?? '';
    final studentId = student['id'] as String?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Retirer $firstName $lastName de cette classe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              if (studentId != null) {
                await _deleteStudentFromClass(studentId, classId);
              }
            },
            child: const Text('Retirer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudentFromClass(String studentId, String classId) async {
    try {
      await Supabase.instance.client
          .from('students')
          .update({'class_id': null})
          .eq('id', studentId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Élève retiré de la classe'),
          backgroundColor: Colors.orange,
        ),
      );
      
      _loadClasses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => AddStudentDialog(
        schoolId: _schoolId!,
        schoolCode: 'CSEGLA2025',
        classes: _classes,
        onSubmit: (data) async {
          Navigator.pop(context);
          await _createStudentWithParent(data);
        },
      ),
    );
  }

  void _showAddStudentToClassDialog(String classId) {
    final selectedClass = _classes.firstWhere(
      (c) => c['id'] == classId,
      orElse: () => {},
    );
    
    showDialog(
      context: context,
      builder: (context) => AddStudentDialog(
        schoolId: _schoolId!,
        schoolCode: 'CSEGLA2025',
        classes: selectedClass.isNotEmpty ? [selectedClass] : _classes,
        onSubmit: (data) async {
          Navigator.pop(context);
          if (selectedClass.isNotEmpty) {
            data['student']['class_id'] = classId;
          }
          await _createStudentWithParent(data);
        },
      ),
    );
  }

  Future<void> _createStudentWithParent(Map<String, dynamic> data) async {
    try {
      setState(() => _isLoading = true);
      
      final studentData = data['student'] as Map<String, dynamic>;
      final parentData = data['parent'] as Map<String, dynamic>;
      final matricule = studentData['matricule'] as String;
      
      final authState = context.read<auth.AuthBloc>().state;
      final adminId = authState is auth.Authenticated ? authState.userId : null;
      final schoolId = authState is auth.Authenticated ? authState.schoolId : null;
      
      if (adminId == null || schoolId == null) {
        throw Exception('Admin non authentifié');
      }

      final schoolCode = await _statsService.getSchoolCode(schoolId);
      
      final parentResponse = await Supabase.instance.client.rpc(
        'create_user_with_role',
        params: {
          'p_first_name': parentData['first_name'],
          'p_last_name': parentData['last_name'],
          'p_phone': parentData['phone'],
          'p_email': null,
          'p_password': matricule,
          'p_role_code': 'parent',
          'p_country_code': 'CI',
          'p_school_id': schoolId,
          'p_created_by': adminId,
        },
      );

      final parentResult = parentResponse as Map<String, dynamic>?;
      
      if (parentResult == null || parentResult['success'] != true) {
        throw Exception(parentResult?['message'] ?? 'Échec création parent');
      }
      
      final parentId = parentResult['user_id'] as String;
      final parentPhone = parentResult['phone'] as String;

      await Supabase.instance.client
          .from('students')
          .insert({
            'first_name': studentData['first_name'],
            'last_name': studentData['last_name'],
            'matricule': matricule,
            'class_id': studentData['class_id'],
            'school_id': schoolId,
            'parent_id': parentId,
            'created_at': DateTime.now().toIso8601String(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ Élève et parent créés !', 
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('📱 Téléphone: $parentPhone', style: const TextStyle(fontSize: 12)),
              Text('🔑 MDP: $matricule', style: const TextStyle(fontSize: 12)),
              Text('🎓 Matricule: $matricule', style: const TextStyle(fontSize: 12)),
              Text('🏫 Code école: ${schoolCode ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
              const Text('⏳ Essai 14 jours activé', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
      
      _loadClasses();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Center(
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
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucune classe trouvée',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}