// lib/presentation/pages/teacher/comments/comments_entry_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/student_model.dart';
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_event.dart';
import '../../blocs/attendance/attendance_state.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'comments/widgets/broadcast_dialog.dart';
import 'comments/widgets/individual_comment_dialog.dart';
import 'comments/widgets/multi_comment_dialog.dart';
import 'comments/widgets/student_comment_card.dart';

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
  final _searchController = TextEditingController();
  final Set<String> _selectedStudentIds = {};
  bool _isSelectionMode = false;

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentModel> _filteredStudents(List<StudentModel> students) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students.where((s) {
      final fullName = '${s.firstName} ${s.lastName}'.toLowerCase();
      final matricule = (s.matricule ?? '').toLowerCase();
      return fullName.contains(query) || matricule.contains(query);
    }).toList();
  }

  void _showBroadcast() {
    showDialog(
      context: context,
      builder: (_) => BroadcastDialog(
        classId: widget.classId,
        className: widget.className,
      ),
    );
  }

  void _showIndividual(StudentModel student) {
    showDialog(
      context: context,
      builder: (_) => IndividualCommentDialog(
        student: student,
        classId: widget.classId,
        className: widget.className,
      ),
    );
  }

  void _showMulti() {
    final state = context.read<AttendanceBloc>().state;
    final selected = state.students.where((s) => _selectedStudentIds.contains(s.id)).toList();
    if (selected.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => MultiCommentDialog(
        students: selected,
        classId: widget.classId,
        className: widget.className,
      ),
    ).then((_) {
      setState(() {
        _isSelectionMode = false;
        _selectedStudentIds.clear();
      });
    });
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
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist, color: const Color(0xFF7C3AED)),
            tooltip: _isSelectionMode ? 'Annuler' : 'Mode sélection',
            onPressed: () => setState(() {
              _isSelectionMode = !_isSelectionMode;
              _selectedStudentIds.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un élève (nom ou matricule)...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Bouton broadcast
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showBroadcast,
                icon: const Icon(Icons.campaign, color: Color(0xFF7C3AED), size: 18),
                label: const Text(
                  '📢 Message à toute la classe',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                  foregroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
          // Info sélection
          if (_isSelectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedStudentIds.length} sélectionné(s)',
                    style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final all = context.read<AttendanceBloc>().state.students.map((s) => s.id).toSet();
                      setState(() {
                        if (_selectedStudentIds.length == all.length) {
                          _selectedStudentIds.clear();
                        } else {
                          _selectedStudentIds.addAll(all);
                        }
                      });
                    },
                    child: Text(
                      _selectedStudentIds.length == context.read<AttendanceBloc>().state.students.length
                          ? 'Tout désélectionner'
                          : 'Tout sélectionner',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Liste
          Expanded(
            child: BlocBuilder<AttendanceBloc, AttendanceState>(
              builder: (context, state) {
                if (state.isLoading && state.students.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
                }
                if (state.students.isEmpty) {
                  return const Center(child: Text('Aucun élève dans cette classe'));
                }

                final filtered = _filteredStudents(state.students);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('Aucun élève trouvé pour "${_searchController.text}"', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    final isSelected = _selectedStudentIds.contains(student.id);

                    return StudentCommentCard(
                      student: student,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                      onTap: () {
                        if (_isSelectionMode) {
                          setState(() {
                            isSelected ? _selectedStudentIds.remove(student.id) : _selectedStudentIds.add(student.id);
                          });
                        } else {
                          _showIndividual(student);
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedStudentIds.add(student.id);
                          });
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode && _selectedStudentIds.isNotEmpty
        ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _showMulti,
                icon: const Icon(Icons.send, size: 18),
                label: Text('Envoyer à ${_selectedStudentIds.length} élève(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          )
        : null,
    );
  }
}