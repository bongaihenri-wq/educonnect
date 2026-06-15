// lib/presentation/pages/teacher/comments/widgets/multi_comment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../data/models/student_model.dart';
import '/../../data/repositories/comment_repository.dart';
import '/../presentation/blocs/auth_bloc/auth_bloc.dart';

class MultiCommentDialog extends StatefulWidget {
  final List<StudentModel> students;
  final String classId;
  final String className;

  const MultiCommentDialog({
    super.key,
    required this.students,
    required this.classId,
    required this.className,
  });

  @override
  State<MultiCommentDialog> createState() => _MultiCommentDialogState();
}

class _MultiCommentDialogState extends State<MultiCommentDialog> {
  final _commentController = TextEditingController();
  List<String> _recipients = ['parent'];
  DateTime? _effectiveDate;

  Future<void> _send() async {
    if (_commentController.text.trim().isEmpty) {
      _showSnack('Veuillez saisir un commentaire', Colors.orange);
      return;
    }
    if (_recipients.isEmpty) {
      _showSnack('Sélectionnez un destinataire', Colors.orange);
      return;
    }

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) throw Exception('Non authentifié');

      final teacherName = await _getTeacherName(authState.userId);
      final subjectName = await _getSubjectName(authState.userId);

      final repo = CommentRepository(Supabase.instance.client);

      for (final student in widget.students) {
        await repo.saveComment(
          studentId: student.id,
          classId: widget.classId,
          teacherId: authState.userId,
          schoolId: authState.schoolId,
          content: _commentController.text.trim(),
          recipients: _recipients,
          studentName: student.fullName,
          className: widget.className,
          senderName: teacherName,
          targetSubject: subjectName,
          effectiveDate: _effectiveDate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        _showSnack('✅ Commentaire envoyé à ${widget.students.length} élève(s) !', const Color(0xFF14B8A6));
      }
    } catch (e) {
      _showSnack('❌ Erreur: $e', const Color(0xFFFB7185));
    }
  }

  Future<String> _getTeacherName(String teacherId) async {
    try {
      final data = await Supabase.instance.client
          .from('app_users').select('first_name, last_name').eq('id', teacherId).maybeSingle();
      if (data == null) return 'Enseignant';
      final fn = data['first_name'] as String? ?? '';
      final ln = data['last_name'] as String? ?? '';
      return '$fn $ln'.trim().isEmpty ? 'Enseignant' : '$fn $ln'.trim();
    } catch (_) {
      return 'Enseignant';
    }
  }

  Future<String> _getSubjectName(String teacherId) async {
    try {
      final data = await Supabase.instance.client
          .from('schedules').select('subjects(name)')
          .eq('class_id', widget.classId).eq('teacher_id', teacherId).eq('is_active', true).maybeSingle();
      return data?['subjects']?['name'] as String? ?? 'Matière';
    } catch (_) {
      return 'Matière';
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('💬 ${widget.students.length} élève(s) sélectionné(s)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Saisissez votre commentaire...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 16),
            _DatePicker(
              effectiveDate: _effectiveDate,
              onChanged: (d) => setState(() => _effectiveDate = d),
            ),
            const SizedBox(height: 16),
            const Text('Envoyer à :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            _RecipientChips(
              recipients: _recipients,
              onChanged: (r) => setState(() => _recipients = r),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
          ),
          onPressed: _send,
          child: Text('Envoyer à ${widget.students.length} élève(s)'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final DateTime? effectiveDate;
  final ValueChanged<DateTime?> onChanged;

  const _DatePicker({required this.effectiveDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF7C3AED), size: 18),
              const SizedBox(width: 8),
              const Text('Date d\'effet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            effectiveDate != null
                ? 'Valable jusqu\'au ${effectiveDate!.day.toString().padLeft(2, '0')}/${effectiveDate!.month.toString().padLeft(2, '0')}/${effectiveDate!.year}'
                : 'Par défaut: 7 jours',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 3)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: Color(0xFF7C3AED), onPrimary: Colors.white),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) onChanged(picked);
              },
              icon: const Icon(Icons.edit_calendar, size: 16),
              label: const Text('Changer la date'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7C3AED),
                side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientChips extends StatelessWidget {
  final List<String> recipients;
  final ValueChanged<List<String>> onChanged;

  const _RecipientChips({required this.recipients, required this.onChanged});

  void _toggle(String value) {
    final updated = List<String>.from(recipients);
    if (updated.contains(value)) {
      updated.remove(value);
    } else {
      updated.add(value);
    }
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          selected: recipients.contains('parent'),
          onSelected: (_) => _toggle('parent'),
          label: const Text('Parents'),
          selectedColor: const Color(0xFF7C3AED),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontSize: 12,
            color: recipients.contains('parent') ? Colors.white : Colors.grey.shade700,
          ),
        ),
        FilterChip(
          selected: recipients.contains('admin'),
          onSelected: (_) => _toggle('admin'),
          label: const Text('Admin'),
          selectedColor: const Color(0xFFF59E0B),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontSize: 12,
            color: recipients.contains('admin') ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}