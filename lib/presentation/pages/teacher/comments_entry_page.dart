// lib/presentation/pages/teacher/comments_entry_page.dart
import 'package:educonnect/data/models/student_model.dart';
import 'package:educonnect/data/repositories/comment_repository.dart';
import 'package:educonnect/presentation/blocs/attendance/attendance_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_state.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class CommentsEntryPage extends StatefulWidget {
  final String classId;
  final String className;

  const CommentsEntryPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<CommentsEntryPage> createState() => _CommentsEntryPageState();
}

class _CommentsEntryPageState extends State<CommentsEntryPage> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    String schoolId = '';
    if (authState is Authenticated) {
      schoolId = authState.schoolId;
    }
    
    context.read<AttendanceBloc>().add(AttendanceLoadStudentsRequested(
      classId: widget.classId,
      schoolId: schoolId,
    ));
  }

  void _showCommentDialog(StudentModel student) {
    final commentController = TextEditingController();
    List<String> recipients = ['parent'];
    DateTime? effectiveDate; // ✅ Date d'effet = date d'expiration

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('💬 Commentaire - ${student.fullName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Champ commentaire
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Saisissez votre commentaire...\n\nEx: Progrès remarquables en participation. Encourager à continuer.',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ SÉLECTEUR DATE D'EFFET
                Container(
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
                          const Text(
                            'Date d\'effet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        effectiveDate != null
                            ? 'Valable jusqu\'au ${effectiveDate?.day.toString().padLeft(2, '0')}/${effectiveDate?.month.toString().padLeft(2, '0')}/${effectiveDate?.year}'
                            : 'Par défaut: 7 jours (jusqu\'au ${DateTime.now().add(const Duration(days: 7)).day.toString().padLeft(2, '0')}/${DateTime.now().add(const Duration(days: 7)).month.toString().padLeft(2, '0')})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF7C3AED),
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() => effectiveDate = picked);
                            }
                          },
                          icon: const Icon(Icons.edit_calendar, size: 16),
                          label: const Text('Changer la date'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Destinataires
                const Text(
                  'Envoyer à :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      selected: recipients.contains('parent'),
                      onSelected: (v) => setDialogState(() => v ? recipients.add('parent') : recipients.remove('parent')),
                      label: const Text('Parent'),
                      selectedColor: const Color(0xFF7C3AED),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: recipients.contains('parent') ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    FilterChip(
                      selected: recipients.contains('admin'),
                      onSelected: (v) => setDialogState(() => v ? recipients.add('admin') : recipients.remove('admin')),
                      label: const Text('Admin'),
                      selectedColor: const Color(0xFFF59E0B),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: recipients.contains('admin') ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ],
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
              onPressed: () async {
                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez saisir un commentaire'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                
                if (recipients.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner au moins un destinataire'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                
                try {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is! Authenticated) throw Exception('Non authentifié');

                  final repo = CommentRepository(Supabase.instance.client);
                  
                  await repo.saveComment(
                    studentId: student.id,
                    classId: widget.classId,
                    teacherId: authState.userId,
                    schoolId: authState.schoolId,
                    content: commentController.text.trim(),
                    recipients: recipients,
                    studentName: student.fullName,
                    className: widget.className,
                    effectiveDate: effectiveDate, // ✅ PASSÉ ICI
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Commentaire envoyé !'),
                      backgroundColor: Color(0xFF14B8A6),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: const Color(0xFFFB7185),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Commentaires - ${widget.className}',
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state.isLoading && state.students.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
          }

          if (state.students.isEmpty) {
            return const Center(child: Text('Aucun élève dans cette classe'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.students.length,
            itemBuilder: (context, index) {
              final student = state.students[index];
              return _StudentCommentCard(
                student: student,
                onTap: () => _showCommentDialog(student),
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentCommentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onTap;

  const _StudentCommentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF7C3AED).withOpacity(0.15),
                child: Text(
                  student.initials,
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Matricule: ${student.matricule}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.comment_outlined, color: Color(0xFF7C3AED)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}