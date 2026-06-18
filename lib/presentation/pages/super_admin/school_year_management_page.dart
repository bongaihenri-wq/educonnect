// lib/presentation/pages/super_admin/school_year_management_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SchoolYearManagementPage extends StatefulWidget {
  const SchoolYearManagementPage({super.key});

  @override
  State<SchoolYearManagementPage> createState() => _SchoolYearManagementPageState();
}

class _SchoolYearManagementPageState extends State<SchoolYearManagementPage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _schools = [];

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    try {
      final result = await _supabase
          .from('schools')
          .select('id, name, current_school_year, is_test, created_at')
          .order('created_at', ascending: false);

      final schools = List<Map<String, dynamic>>.from(result);
      final schoolIds = schools.map((s) => s['id'] as String).toList();

      final Map<String, int> studentCounts = {};
      final Map<String, int> teacherCounts = {};

      if (schoolIds.isNotEmpty) {
        final studentsResult = await _supabase
            .from('students')
            .select('school_id')
            .limit(1000);
        for (final s in List<Map<String, dynamic>>.from(studentsResult)) {
          final sid = s['school_id'] as String?;
          if (sid != null && schoolIds.contains(sid)) {
            studentCounts[sid] = (studentCounts[sid] ?? 0) + 1;
          }
        }

        final teachersResult = await _supabase
            .from('app_users')
            .select('school_id')
            .eq('role', 'teacher')
            .limit(1000);
        for (final t in List<Map<String, dynamic>>.from(teachersResult)) {
          final sid = t['school_id'] as String?;
          if (sid != null && schoolIds.contains(sid)) {
            teacherCounts[sid] = (teacherCounts[sid] ?? 0) + 1;
          }
        }
      }

      setState(() {
        _schools = schools.map((s) {
          final id = s['id'] as String;
          return {
            ...s,
            'student_count': studentCounts[id] ?? 0,
            'teacher_count': teacherCounts[id] ?? 0,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur chargement: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Gestion Années Scolaires'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSchools),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchools,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _schools.length,
                itemBuilder: (context, index) => _buildSchoolCard(_schools[index]),
              ),
            ),
    );
  }

    Widget _buildSchoolCard(Map<String, dynamic> school) {
    final name = school['name'] ?? '—';
    final year = school['current_school_year'] ?? '—';
    final isTest = school['is_test'] == true;
    final students = school['student_count'] ?? 0;
    final teachers = school['teacher_count'] ?? 0;
    final createdAt = school['created_at'] != null
        ? DateTime.tryParse(school['created_at'].toString())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTest
            ? BorderSide(color: Colors.orange.withOpacity(0.5), width: 2)
            : BorderSide.none,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Color(0xFF6C63FF)),
                                const SizedBox(width: 4),
                                Text(
                                  'Année: $year',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          if (isTest)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.science, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'TEST — Supprimable',
                                    style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isTest)
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    tooltip: 'Supprimer école de test',
                    onPressed: () => _showDeleteDialog(school['id'] as String, name),
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildStat(Icons.people, '$students', 'Élèves'),
                const SizedBox(width: 16),
                _buildStat(Icons.school, '$teachers', 'Enseignants'),
              ],
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Créée le ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCloseYearDialog(school['id'] as String, name, year),
                icon: const Icon(Icons.archive),
                label: const Text('Clôturer & Passer à la nouvelle année'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  void _showCloseYearDialog(String schoolId, String schoolName, String currentYear) {
    final yearController = TextEditingController();
    final passwordController = TextEditingController();
    
    final parts = currentYear.split('-');
    if (parts.length == 2) {
      final start = int.tryParse(parts[0]) ?? 2025;
      yearController.text = '${start + 1}-${start + 2}';
    } else {
      yearController.text = '2026-2027';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.archive, color: Color(0xFF6C63FF)),
            const SizedBox(width: 8),
            Expanded(child: Text('Clôturer $schoolName')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Année actuelle: $currentYear\n'
              'Les élèves actuels restent en archive. Les nouveaux importeront avec la nouvelle année.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(
                labelText: 'Nouvelle année scolaire',
                hintText: 'Ex: 2026-2027',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe Super Admin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (yearController.text.length < 7) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Format année invalide')),
                );
                return;
              }
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe requis')),
                );
                return;
              }
              Navigator.pop(context);
              await _closeYear(schoolId, yearController.text.trim(), passwordController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Confirmer la clôture'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeYear(String schoolId, String newYear, String password) async {
    try {
      final result = await _supabase.rpc('close_school_year', params: {
        'p_school_id': schoolId,
        'p_new_year': newYear,
        'p_super_admin_password': password,
      });

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadSchools();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result?['message'] ?? 'Erreur'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteDialog(String schoolId, String schoolName) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Supprimer $schoolName',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ IRRÉVERSIBLE. Toutes les données de cette école de test seront supprimées.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe Super Admin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Tapez SUPPRIMER pour confirmer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.warning),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text.trim() != 'SUPPRIMER') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tapez SUPPRIMER en majuscules')),
                );
                return;
              }
              if (passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe requis')),
                );
                return;
              }
              Navigator.pop(context);
              await _deleteSchool(schoolId, passwordController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSchool(String schoolId, String password) async {
    try {
      final result = await _supabase.rpc('delete_school_cascade', params: {
        'p_school_id': schoolId,
        'p_super_admin_password': password,
      });

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadSchools();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result?['message'] ?? 'Erreur'}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}