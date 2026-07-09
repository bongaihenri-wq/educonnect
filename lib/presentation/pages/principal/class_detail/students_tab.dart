// lib/presentation/pages/principal/class_detail/students_tab.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/common_widgets.dart';
import '../widgets/student_detail_sheet.dart';

class StudentsTab extends StatefulWidget {
  final String classId;
  final String schoolId;
  final String className;
  const StudentsTab(
      {super.key,
      required this.classId,
      required this.schoolId,
      required this.className});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await Supabase.instance.client
          .from('students')
          .select('id, first_name, last_name, matricule, gender')
          .eq('class_id', widget.classId)
          .order('last_name');
      if (mounted) {
        setState(() {
          _students = List<Map<String, dynamic>>.from(result);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _showDetail(Map<String, dynamic> s) {
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
          className: widget.className,
          schoolId: widget.schoolId,
        ),
      ),
    );
  }

  Future<void> _remove(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer de la classe'),
        content: const Text('Retirer cet élève de cette classe ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Retirer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client
          .from('students')
          .update({'class_id': null}).eq('id', id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return buildError(_error!);
    if (_students.isEmpty) return buildEmpty('Aucun élève');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _students.length,
      itemBuilder: (ctx, i) {
        final s = _students[i];
        final fn = s['first_name'] as String? ?? '';
        final ln = s['last_name'] as String? ?? '';
        final mat = s['matricule'] as String? ?? '—';
        final g = (s['gender'] as String? ?? '').toString().toLowerCase();
        final isF = g == 'f';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isF ? const Color(0xFFFCE7F3) : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Center(
                  child: Icon(isF ? Icons.female : Icons.male,
                      color: isF
                          ? const Color(0xFFEC4899)
                          : const Color(0xFF3B82F6),
                      size: 20)),
            ),
            title: Text(
              '${ln.toUpperCase()} ${fn.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Matricule: $mat',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.visibility,
                        size: 20, color: Color(0xFF9CA3AF)),
                    onPressed: () => _showDetail(s),
                    visualDensity: VisualDensity.compact),
                IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _remove(s['id']),
                    visualDensity: VisualDensity.compact),
              ],
            ),
          ),
        );
      },
    );
  }
}
