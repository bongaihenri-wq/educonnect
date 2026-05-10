import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart';
import '/../../config/routes.dart';
import 'tabs/overview_tab.dart';
import 'tabs/classes_tab.dart';
import 'tabs/teachers_tab.dart';
import 'tabs/students_parents_tab.dart';
import 'tabs/credentials_tab.dart';

class SchoolDetailPage extends StatefulWidget {
  final Map<String, dynamic> school;

  const SchoolDetailPage({super.key, required this.school});

  @override
  State<SchoolDetailPage> createState() => _SchoolDetailPageState();
}

class _SchoolDetailPageState extends State<SchoolDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _schedules = [];
  
  bool _hasStudentsParents = false;
  bool _hasTeachers = false;
  bool _hasSchedules = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSchoolData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchoolData() async {
    setState(() => _isLoading = true);
    
    try {
      final schoolId = widget.school['id'];
      
      final results = await Future.wait([
        Supabase.instance.client.from('classes').select().eq('school_id', schoolId).order('name'),
        Supabase.instance.client.from('app_users').select().eq('school_id', schoolId).eq('role', 'teacher').order('last_name'),
        Supabase.instance.client.from('students').select('*, classes(name)').eq('school_id', schoolId).order('last_name'),
        Supabase.instance.client.from('app_users').select('*, parent_students!inner(student_id, students!inner(matricule, first_name, last_name))').eq('school_id', schoolId).eq('role', 'parent'),
        Supabase.instance.client.from('schedules').select('*, classes(name), subjects(name), app_users!inner(first_name, last_name)').eq('school_id', schoolId),
      ]);

      setState(() {
        _classes = List<Map<String, dynamic>>.from(results[0]);
        _teachers = List<Map<String, dynamic>>.from(results[1]);
        _students = List<Map<String, dynamic>>.from(results[2]);
        _parents = List<Map<String, dynamic>>.from(results[3]);
        _schedules = List<Map<String, dynamic>>.from(results[4]);
        
        _hasStudentsParents = _students.isNotEmpty || _parents.isNotEmpty;
        _hasTeachers = _teachers.isNotEmpty;
        _hasSchedules = _schedules.isNotEmpty;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement données: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: Text(widget.school['name'] ?? 'Détail École'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
            Tab(icon: Icon(Icons.class_), text: 'Classes'),
            Tab(icon: Icon(Icons.person_outline), text: 'Enseignants'),
            Tab(icon: Icon(Icons.people), text: 'Élèves & Parents'),
            Tab(icon: Icon(Icons.key), text: 'Credentials'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.violet))
          : TabBarView(
              controller: _tabController,
              children: [
                OverviewTab(
                  school: widget.school,
                  classes: _classes,
                  teachers: _teachers,
                  students: _students,
                  parents: _parents,
                  schedules: _schedules,
                  hasStudentsParents: _hasStudentsParents,
                  hasTeachers: _hasTeachers,
                  hasSchedules: _hasSchedules,
                  onImport: () => _showImportDialog(),
                ),
                ClassesTab(
                  schoolId: widget.school['id'],
                  classes: _classes,
                  onDataChanged: _loadSchoolData,
                ),
                TeachersTab(
                  schoolId: widget.school['id'],
                  teachers: _teachers,
                  onDataChanged: _loadSchoolData,
                ),
                StudentsParentsTab(
                  schoolId: widget.school['id'],
                  students: _students,
                  parents: _parents,
                  onDataChanged: _loadSchoolData,
                ),
                CredentialsTab(
                  schoolCode: widget.school['school_code'] ?? '',
                  teachers: _teachers,
                  parents: _parents,
                  students: _students,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImportDialog(),
        backgroundColor: AppTheme.violet,
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer des données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ImportOption(
              icon: Icons.people,
              color: Colors.green,
              title: 'Élèves & Parents',
              subtitle: 'Fichier CSV/Excel',
              onTap: () => _navigateToImport('students_parents'),
            ),
            _ImportOption(
              icon: Icons.person_outline,
              color: Colors.orange,
              title: 'Enseignants',
              subtitle: 'Fichier CSV/Excel',
              onTap: () => _navigateToImport('teachers'),
            ),
            _ImportOption(
              icon: Icons.calendar_today,
              color: Colors.blue,
              title: 'Emploi du temps',
              subtitle: 'Fichier CSV/Excel',
              onTap: () => _navigateToImport('schedules'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _navigateToImport(String type) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      AppRoutes.adminBulkImport,
      arguments: {
        'schoolId': widget.school['id'],
        'schoolCode': widget.school['school_code'] ?? '',
        'type': type,
      },
    ).then((_) => _loadSchoolData());
  }
}

class _ImportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}