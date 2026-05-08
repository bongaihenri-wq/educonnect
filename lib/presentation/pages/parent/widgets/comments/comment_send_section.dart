// lib/presentation/pages/parent/widgets/comments/comment_send_section.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/../../config/theme.dart';
import '/services/teacher_service.dart';

class CommentSendSection extends StatefulWidget {
  final String studentId;
  final String parentName;
  final VoidCallback onSent;

  const CommentSendSection({
    super.key,
    required this.studentId,
    required this.parentName,
    required this.onSent,
  });

  @override
  State<CommentSendSection> createState() => _CommentSendSectionState();
}

class _CommentSendSectionState extends State<CommentSendSection> {
  final _commentController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _teacherService = TeacherService();
  
  String _selectedRecipient = 'teacher';
  String _selectedSubject = 'all';
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoadingTeachers = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoadingTeachers = true);
    final teachers = await _teacherService.getTeachersForStudent(widget.studentId);
    setState(() {
      _teachers = teachers;
      _isLoadingTeachers = false;
    });
  }

  Future<Map<String, dynamic>> _getStudentInfo() async {
    final studentData = await _supabase
        .from('students')
        .select('class_id, school_id')
        .eq('id', widget.studentId)
        .single();

    return {
      'class_id': studentData['class_id'] as String?,
      'school_id': studentData['school_id'] as String?,
    };
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      final studentInfo = await _getStudentInfo();
      final classId = studentInfo['class_id'] as String?;
      final schoolId = studentInfo['school_id'] as String?;

      if (classId == null || schoolId == null) {
        throw Exception('Impossible de récupérer les informations de l\'élève');
      }

      final content = _commentController.text.trim();
      final now = DateTime.now().toIso8601String();
      final expiresAt = DateTime.now().add(const Duration(days: 30)).toIso8601String();

      if (_selectedRecipient == 'admin') {
        await _supabase.from('comments').insert({
          'student_id': widget.studentId,
          'class_id': classId,
          'school_id': schoolId,
          'teacher_id': null,
          'content': content,
          'sender_type': 'parent',
          'sender_name': widget.parentName,
          'recipient_type': 'admin',
          'is_broadcast': false,
          'recipients': '["admin"]', // ✅ CORRIGÉ : chaîne JSON
          'created_at': now,
          'expires_at': expiresAt,
          'is_read': false,
          'is_archived': false,
        });
      } else if (_selectedSubject == 'all') {
        if (_teachers.isEmpty) throw Exception('Aucun enseignant trouvé');
        final inserts = _teachers.map((t) => {
          'student_id': widget.studentId,
          'class_id': classId,
          'school_id': schoolId,
          'teacher_id': t['teacher_id'],
          'content': content,
          'sender_type': 'parent',
          'sender_name': widget.parentName,
          'recipient_type': 'teacher',
          'target_subject': t['subject_name'],
          'is_broadcast': true,
          'recipients': '["teacher"]', // ✅ CORRIGÉ : chaîne JSON
          'created_at': now,
          'expires_at': expiresAt,
          'is_read': false,
          'is_archived': false,
        }).toList();
        await _supabase.from('comments').insert(inserts);
      } else {
        final teacher = _teachers.firstWhere(
          (t) => t['subject_name'].toString().toLowerCase() == _selectedSubject.toLowerCase(),
          orElse: () => {},
        );
        if (teacher.isEmpty) throw Exception('Enseignant non trouvé');
        await _supabase.from('comments').insert({
          'student_id': widget.studentId,
          'class_id': classId,
          'school_id': schoolId,
          'teacher_id': teacher['teacher_id'],
          'content': content,
          'sender_type': 'parent',
          'sender_name': widget.parentName,
          'recipient_type': 'teacher',
          'target_subject': teacher['subject_name'],
          'is_broadcast': false,
          'recipients': '["teacher"]', // ✅ CORRIGÉ : chaîne JSON
          'created_at': now,
          'expires_at': expiresAt,
          'is_read': false,
          'is_archived': false,
        });
      }

      _commentController.clear();
      widget.onSent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Message envoyé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.violet.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildRecipientSelector(),
            if (_selectedRecipient == 'teacher') ...[
              const SizedBox(height: 8),
              _buildTeacherSelector(),
            ],
            const SizedBox(height: 8),
            _buildTextField(),
            const SizedBox(height: 8),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Row(
    children: [
      Icon(Icons.send, color: AppTheme.violet, size: 16),
      const SizedBox(width: 6),
      Text('Envoyer un message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.nightBlue)),
    ],
  );

  Widget _buildRecipientSelector() => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChip('Enseignant', 'teacher', Icons.school),
        const SizedBox(width: 6),
        _buildChip('Administration', 'admin', Icons.admin_panel_settings),
      ],
    ),
  );

  Widget _buildChip(String label, String value, IconData icon) {
    final isSelected = _selectedRecipient == value;
    return InkWell(
      onTap: () => setState(() => _selectedRecipient = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.violet.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppTheme.violet : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppTheme.violet : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppTheme.violet : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherSelector() {
    if (_isLoadingTeachers) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_teachers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text('Aucun enseignant trouvé', style: TextStyle(fontSize: 11, color: Colors.orange)),
      );
    }

    final subjects = _teachers.map((t) => {
      'label': t['subject_name'],
      'value': t['subject_name'].toString().toLowerCase(),
    }).toList();
    subjects.insert(0, {'label': 'Tous', 'value': 'all'});

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.violet.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enseignant concerné :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.nightBlue)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: subjects.map((s) {
              final isSelected = _selectedSubject == s['value'];
              return ChoiceChip(
                label: Text(s['label'] as String, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white : AppTheme.nightBlue)),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedSubject = s['value'] as String),
                selectedColor: AppTheme.violet,
                backgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: isSelected ? AppTheme.violet : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() => TextField(
    controller: _commentController,
    maxLines: 2,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      hintText: 'Votre message...',
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.all(10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.violet)),
    ),
  );

  Widget _buildFooter() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text('Validité: 30 jours', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ElevatedButton.icon(
        onPressed: _isSending ? null : _sendComment,
        icon: _isSending
            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send, size: 14),
        label: Text(_isSending ? 'Envoi...' : 'Envoyer', style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.violet,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ],
  );
}