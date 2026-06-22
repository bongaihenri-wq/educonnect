// lib/presentation/pages/principal/principal_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import 'principal_class_detail_page.dart';
import 'widgets/student_detail_sheet.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _myClasses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      final authState = context.read<auth.AuthBloc>().state;
      final userId = authState is auth.Authenticated ? authState.userId : '';
      if (userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Utilisateur non authentifié';
        });
        return;
      }

      final result = await _supabase
          .from('principal_classes')
          .select('school_id, class_id, classes(name, level)')
          .eq('principal_id', userId);

      final classes = List<Map<String, dynamic>>.from(result);

      for (var cls in classes) {
        final classId = cls['class_id'] as String?;
        final schoolId = cls['school_id'] as String?;
        if (classId != null && schoolId != null) {
          final studentsResult = await _supabase.from('students').select('id, gender').eq('class_id', classId);
          final students = List<Map<String, dynamic>>.from(studentsResult);
          cls['student_count'] = students.length;
          cls['boys_count'] = students.where((s) => (s['gender'] ?? '').toString().toLowerCase() == 'm').length;
          cls['girls_count'] = students.where((s) => (s['gender'] ?? '').toString().toLowerCase() == 'f').length;

          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          final dateStr = DateFormat('yyyy-MM-dd').format(thirtyDaysAgo);
          final attResult = await _supabase
              .from('attendance')
              .select('status, student_id')
              .eq('school_id', schoolId)
              .gte('date', dateStr);

          final allAtt = List<Map<String, dynamic>>.from(attResult);
          final studentIds = students.map((s) => s['id'] as String?).whereType<String>().toList();
          final classAtt = allAtt.where((a) => studentIds.contains(a['student_id'])).toList();

          int present = 0, absent = 0, retard = 0;
          for (final a in classAtt) {
            final st = (a['status'] as String? ?? '').toLowerCase();
            if (st == 'present') present++;
            else if (st == 'absent') absent++;
            else if (st == 'retard') retard++;
          }
          final total = classAtt.length;
          cls['attendance_stats'] = {
            'present': present,
            'absent': absent,
            'retard': retard,
            'total': total,
            'rate': total > 0 ? ((present / total) * 100).toDouble() : 0.0,
          };
        } else {
          cls['student_count'] = 0;
          cls['boys_count'] = 0;
          cls['girls_count'] = 0;
          cls['attendance_stats'] = {'present': 0, 'absent': 0, 'retard': 0, 'total': 0, 'rate': 0.0};
        }
      }

      if (mounted) {
        setState(() {
          _myClasses = classes;
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

  void _logout() {
    context.read<auth.AuthBloc>().add(auth.LogoutRequested());
    AppRoutes.logout(context);
  }

  void _openClassDetail(Map<String, dynamic> cls) {
    final classId = cls['class_id'] as String? ?? '';
    final className = cls['classes']?['name'] ?? 'Classe';
    final schoolId = cls['school_id'] as String? ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalClassDetailPage(classId: classId, className: className, schoolId: schoolId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Classes & Élèves', maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        // PAS DE leading (bouton retour) — c'est la page racine du principal
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadClasses),
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Déconnexion', onPressed: _logout),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _myClasses.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadClasses,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _myClasses.map((cls) => _ClassCard(
                            cls: cls,
                            onOpenDetail: () => _openClassDetail(cls),
                            onRefresh: _loadClasses,
                          )).toList(),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Erreur: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadClasses, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Aucune classe assignée', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Contactez l\'administrateur', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ==================== CARTE CLASSE EXPANDABLE ====================
class _ClassCard extends StatefulWidget {
  final Map<String, dynamic> cls;
  final VoidCallback onOpenDetail;
  final VoidCallback onRefresh;
  const _ClassCard({required this.cls, required this.onOpenDetail, required this.onRefresh});

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _expanded = false;
  bool _loadingStudents = false;
  List<Map<String, dynamic>> _students = [];
  String? _studentsError;

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final result = await Supabase.instance.client
          .from('students')
          .select('id, first_name, last_name, matricule, gender')
          .eq('class_id', widget.cls['class_id'] as String)
          .order('last_name');
      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(result);
          _loadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _studentsError = e.toString();
          _loadingStudents = false;
        });
      }
    }
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded && _students.isEmpty && _studentsError == null) _loadStudents();
    });
  }

  void _showStudentDetail(Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: StudentDetailSheet(
          studentId: s['id'] as String? ?? '',
          firstName: s['first_name'] as String? ?? '',
          lastName: s['last_name'] as String? ?? '',
          matricule: s['matricule'] as String? ?? '',
          gender: (s['gender'] as String? ?? '').toString().toLowerCase(),
          className: widget.cls['classes']?['name'] ?? '',
          schoolId: widget.cls['school_id'] as String? ?? '',
        ),
      ),
    );
  }

  Future<void> _removeStudent(String studentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer de la classe'),
        content: const Text('Voulez-vous retirer cet élève de cette classe ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Retirer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.from('students').update({'class_id': null}).eq('id', studentId);
      widget.onRefresh();
      if (_expanded) _loadStudents();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.cls['classes']?['name'] ?? 'Classe';
    final level = widget.cls['classes']?['level'] ?? '';
    final count = widget.cls['student_count'] as int? ?? 0;
    final boys = widget.cls['boys_count'] as int? ?? 0;
    final girls = widget.cls['girls_count'] as int? ?? 0;
    final att = widget.cls['attendance_stats'] as Map<String, dynamic>? ?? {};
    final present = att['present'] as int? ?? 0;
    final absent = att['absent'] as int? ?? 0;
    final retard = att['retard'] as int? ?? 0;
    final total = att['total'] as int? ?? 0;
    final rate = att['rate'] as double? ?? 0.0;

    final absentPct = total > 0 ? ((absent / total) * 100).toDouble() : 0.0;
    final retardPct = total > 0 ? ((retard / total) * 100).toDouble() : 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onOpenDetail,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.nightBlue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${rate.toStringAsFixed(0)}% présence',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.violet),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('$count élève${count > 1 ? 's' : ''}', style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                      if (boys > 0) ...[
                        const Text(' • ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        const Icon(Icons.male, size: 16, color: Color(0xFF60A5FA)),
                        Text('$boys', style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                      ],
                      if (girls > 0) ...[
                        const Text(' • ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                        const Icon(Icons.female, size: 16, color: Color(0xFFF472B6)),
                        Text('$girls', style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                      ],
                    ],
                  ),
                  if (level.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Niveau: $level', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Assiduité classe', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          _LegendDot(color: Colors.green, label: '${rate.toStringAsFixed(0)}%'),
                          const SizedBox(width: 8),
                          _LegendDot(color: Colors.red, label: '${absentPct.toStringAsFixed(0)}%'),
                          const SizedBox(width: 8),
                          _LegendDot(color: Colors.orange, label: '${retardPct.toStringAsFixed(0)}%'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AttendanceBar(present: present, absent: absent, retard: retard, total: total, rate: rate),
                  const SizedBox(height: 12),
                  Center(
                    child: InkWell(
                      onTap: _toggle,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: const Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(_expanded ? 'Masquer les élèves' : 'Voir les élèves', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Élèves ($count)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
                      InkWell(
                        onTap: () {/* TODO ajouter élève */},
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 18, color: AppTheme.violet),
                            Text('Ajouter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.violet)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_loadingStudents)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_studentsError != null)
                    Text('Erreur: $_studentsError', style: const TextStyle(color: Colors.red, fontSize: 12))
                  else if (_students.isEmpty)
                    const Text('Aucun élève', style: TextStyle(color: Colors.grey))
                  else
                    ..._students.map((s) => _StudentTile(
                          student: s,
                          onView: () => _showStudentDetail(s),
                          onRemove: () => _removeStudent(s['id'] as String),
                        )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onView;
  final VoidCallback onRemove;
  const _StudentTile({required this.student, required this.onView, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final firstName = student['first_name'] as String? ?? '';
    final lastName = student['last_name'] as String? ?? '';
    final matricule = student['matricule'] as String? ?? '—';
    final gender = (student['gender'] as String? ?? '').toString().toLowerCase();
    final isFemale = gender == 'f';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isFemale ? const Color(0xFFFCE7F3) : const Color(0xFFDBEAFE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(isFemale ? Icons.female : Icons.male, color: isFemale ? const Color(0xFFEC4899) : const Color(0xFF3B82F6), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastName.toUpperCase(),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.nightBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  firstName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.nightBlue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Matricule: $matricule', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility, size: 20, color: Color(0xFF9CA3AF)),
            onPressed: onView,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _AttendanceBar extends StatelessWidget {
  final int present, absent, retard, total;
  final double rate;
  const _AttendanceBar({required this.present, required this.absent, required this.retard, required this.total, required this.rate});

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        height: 24,
        decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Aucune donnée', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            if (present > 0)
              Expanded(
                flex: present,
                child: Container(
                  color: Colors.green,
                  child: Center(
                    child: Text('${rate.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            if (absent > 0) Expanded(flex: absent, child: Container(color: Colors.red)),
            if (retard > 0) Expanded(flex: retard, child: Container(color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}