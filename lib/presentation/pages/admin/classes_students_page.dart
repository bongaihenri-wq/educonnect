// lib/presentation/pages/admin/classes_students_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

class ClassesStudentsPage extends StatefulWidget {
  const ClassesStudentsPage({super.key});

  @override
  State<ClassesStudentsPage> createState() => _ClassesStudentsPageState();
}

class _ClassesStudentsPageState extends State<ClassesStudentsPage> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String? _schoolId;
  String? _selectedClassId;
  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      // ✅ CORRIGÉ : Utiliser Authenticated (classe de base)
      final state = context.read<auth.AuthBloc>().state;
      if (state is auth.Authenticated) {
        _schoolId = state.schoolId;
      }

      if (_schoolId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('classes')
          .select('*, students(count)')
          .eq('school_id', _schoolId!)
          .order('name');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ' + e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadStudents(String classId) async {
    setState(() {
      _selectedClassId = classId;
      _loadingStudents = true;
    });

    try {
      final studentsResponse = await Supabase.instance.client
          .from('students')
          .select('*, attendance(status, date)')
          .eq('class_id', classId)
          .eq('school_id', _schoolId!)
          .order('last_name');

      final students = List<Map<String, dynamic>>.from(studentsResponse);

      final studentsWithStats = students.map((student) {
        final attendanceRaw = student['attendance'];
        List<Map<String, dynamic>> attendance = [];
        
        if (attendanceRaw is List) {
          attendance = List<Map<String, dynamic>>.from(attendanceRaw);
        }

        final total = attendance.length;
        final present = attendance.where((a) => a['status'] == 'present').length;
        final absent = attendance.where((a) => a['status'] == 'absent').length;
        final late = attendance.where((a) => a['status'] == 'late').length;

        final studentCopy = Map<String, dynamic>.from(student);
        studentCopy['stats'] = {
          'total': total,
          'present': total > 0 ? (present / total * 100).round() : 0,
          'absent': total > 0 ? (absent / total * 100).round() : 0,
          'late': total > 0 ? (late / total * 100).round() : 0,
        };
        return studentCopy;
      }).toList();

      setState(() {
        _students = studentsWithStats;
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() => _loadingStudents = false);
      print('❌ Erreur loadStudents: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur eleves: ' + e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildClassCard(Map<String, dynamic> classe) {
    final rawCount = classe['students']?['count'];
    final studentCount = rawCount is int 
        ? rawCount 
        : int.tryParse(rawCount?.toString() ?? '0') ?? 0;
    
    final isSelected = _selectedClassId == classe['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
          ? BorderSide(color: AppTheme.violet, width: 2)
          : BorderSide.none,
      ),
      child: ListTile(
        onTap: () => _loadStudents(classe['id']),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.meeting_room, color: Colors.orange),
        ),
        title: Text(
          classe['name'] ?? 'Sans nom',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Niveau: ' + (classe['level'] ?? 'Non defini') + ' - ' + studentCount.toString() + ' eleves'),
        trailing: Icon(
          isSelected ? Icons.expand_less : Icons.expand_more,
          color: AppTheme.violet,
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final stats = student['stats'] as Map<String, dynamic>;
    final firstName = student['first_name'] ?? '';
    final lastName = student['last_name'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.violet,
                  child: Text(
                    (firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : ''),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstName + ' ' + lastName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Matricule: ' + (student['matricule'] ?? 'N/A'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip('Present', stats['present'], Colors.green),
                const SizedBox(width: 8),
                _buildStatChip('Absent', stats['absent'], Colors.red),
                const SizedBox(width: 8),
                _buildStatChip('Retard', stats['late'], Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int percentage, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              percentage.toString() + '%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Classes & Eleves'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: _selectedClassId != null ? 1 : 3,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) => _buildClassCard(_classes[index]),
                  ),
                ),
                if (_selectedClassId != null) ...[
                  const Divider(height: 1),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: AppTheme.violet),
                        const SizedBox(width: 8),
                        Text(
                          'Eleves de la classe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.nightBlue,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _selectedClassId = null),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _loadingStudents
                        ? const Center(child: CircularProgressIndicator())
                        : _students.isEmpty
                            ? const Center(child: Text('Aucun eleve dans cette classe'))
                            : ListView.builder(
                                itemCount: _students.length,
                                itemBuilder: (context, index) => _buildStudentCard(_students[index]),
                              ),
                  ),
                ],
              ],
            ),
    );
  }
}
