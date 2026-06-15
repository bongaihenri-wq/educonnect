// lib/presentation/pages/teacher/widgets/teacher_add_homework_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';

class TeacherAddHomeworkDialog extends StatefulWidget {
  final String teacherAppUserId;
  final String schoolId;

  const TeacherAddHomeworkDialog({
    super.key,
    required this.teacherAppUserId,
    required this.schoolId,
  });

  @override
  State<TeacherAddHomeworkDialog> createState() => _TeacherAddHomeworkDialogState();
}

class _TeacherAddHomeworkDialogState extends State<TeacherAddHomeworkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _myClasses = [];
  List<Map<String, dynamic>> _subjects = [];

  String? _selectedClassId;
  String? _selectedSubjectId;
  String _title = '';
  String _description = '';
  String _type = 'devoir';
  String _priority = 'normale';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = const TimeOfDay(hour: 18, minute: 0);
  String _room = '';

  final List<Map<String, dynamic>> _types = [
    {'value': 'devoir', 'label': 'Devoir', 'icon': Icons.assignment},
    {'value': 'examen', 'label': 'Examen', 'icon': Icons.quiz},
    {'value': 'controle', 'label': 'Contrôle', 'icon': Icons.fact_check},
    {'value': 'interro', 'label': 'Interro', 'icon': Icons.help_outline},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'basse', 'label': 'Basse', 'color': Colors.green},
    {'value': 'normale', 'label': 'Normale', 'color': Colors.blue},
    {'value': 'haute', 'label': 'Haute', 'color': Colors.orange},
    {'value': 'urgente', 'label': 'Urgente', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    
    // ✅ VÉRIFICATION : Si l'ID est vide, on affiche une erreur claire
    if (widget.teacherAppUserId.isEmpty) {
      setState(() {
        _error = 'Erreur: ID enseignant non fourni. Vérifiez la connexion.';
        _isLoading = false;
      });
      return;
    }
    
    // ✅ LOG JWT pour diagnostic
    final jwtUserId = _supabase.auth.currentUser?.id;
    print('🔍 [HomeworkDialog] widget.teacherAppUserId = ${widget.teacherAppUserId}');
    print('🔍 [HomeworkDialog] JWT auth.uid() = $jwtUserId');
    print('🔍 [HomeworkDialog] Match = ${jwtUserId == widget.teacherAppUserId}');
    
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      final teacherId = widget.teacherAppUserId;
      final schoolId = widget.schoolId;

      if (teacherId.isEmpty || schoolId.isEmpty) {
        throw Exception('ID enseignant ou école manquant');
      }

      // 1. Classes où il enseigne
      final classesRes = await _supabase
          .from('schedules')
          .select('class_id, classes(id, name, level, school_id)')
          .eq('teacher_id', teacherId)
          .eq('is_active', true);

      final seen = <String>{};
      _myClasses = [];
      for (final row in classesRes as List) {
        final classData = row['classes'] as Map<String, dynamic>?;
        if (classData == null) continue;
        final id = classData['id'] as String?;
        if (id != null && !seen.contains(id)) {
          seen.add(id);
          _myClasses.add(classData);
        }
      }

      // 2. Matières de l'école
      final subjectsRes = await _supabase
          .from('subjects')
          .select('id, name, code')
          .eq('school_id', schoolId)
          .eq('is_active', true)
          .order('name');

      _subjects = (subjectsRes as List).cast<Map<String, dynamic>>();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Erreur chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null || _selectedSubjectId == null) {
      setState(() => _error = 'Veuillez sélectionner une classe et une matière');
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final classId = _selectedClassId!;
      final subjectId = _selectedSubjectId!;
      final teacherId = widget.teacherAppUserId;
      final schoolId = widget.schoolId;

      final dateStr = '${_dueDate.year.toString().padLeft(4, '0')}-'
          '${_dueDate.month.toString().padLeft(2, '0')}-'
          '${_dueDate.day.toString().padLeft(2, '0')}';

      final timeStr = '${_dueTime.hour.toString().padLeft(2, '0')}:'
          '${_dueTime.minute.toString().padLeft(2, '0')}:00';

      // ✅ LOG avant insertion
      print('🔍 [HomeworkDialog] INSERT avec teacher_id = $teacherId');

      await _supabase.from('homeworks').insert(<String, Object?>{
        'title': _title,
        'description': _description.isNotEmpty ? _description : null,
        'type': _type,
        'status': 'prevu',
        'priority': _priority,
        'due_date': dateStr,
        'due_time': timeStr,
        'class_id': classId,
        'subject_id': subjectId,
        'room': _room.isNotEmpty ? _room : null,
        'school_id': schoolId,
        'teacher_id': teacherId,
        'assigned_date': dateStr,
        'is_active': true,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('🔍 [HomeworkDialog] ERREUR INSERT: $e');
      setState(() {
        _error = 'Erreur création: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_add, color: AppTheme.violet),
          const SizedBox(width: 10),
          const Expanded(child: Text('Nouveau devoir', style: TextStyle(fontSize: 18))),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: InputDecoration(
                          labelText: 'Classe *',
                          prefixIcon: const Icon(Icons.class_),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _myClasses.map((c) {
                          return DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text('${c['name']} (${c['level']})'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedClassId = v),
                        validator: (v) => v == null ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedSubjectId,
                        decoration: InputDecoration(
                          labelText: 'Matière *',
                          prefixIcon: const Icon(Icons.book),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _subjects.map((s) {
                          return DropdownMenuItem(
                            value: s['id'] as String,
                            child: Text(s['name'] as String),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedSubjectId = v),
                        validator: (v) => v == null ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Titre du devoir *',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                        onSaved: (v) => _title = v!,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _types.map((t) {
                          return DropdownMenuItem(
                            value: t['value'] as String,
                            child: Row(
                              children: [
                                Icon(t['icon'] as IconData, size: 18),
                                const SizedBox(width: 8),
                                Text(t['label'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Priorité *',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _priorities.map((p) {
                          return DropdownMenuItem(
                            value: p['value'] as String,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: p['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(p['label'] as String),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date *',
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                child: Text(
                                  DateFormat('EEEE d MMM', 'fr_FR').format(_dueDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _pickTime,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Heure *',
                                  prefixIcon: const Icon(Icons.access_time),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                child: Text(
                                  '${_dueTime.hour.toString().padLeft(2, '0')}:${_dueTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Salle (optionnel)',
                          prefixIcon: const Icon(Icons.room),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onSaved: (v) => _room = v ?? '',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Description / Consignes (optionnel)',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        onSaved: (v) => _description = v ?? '',
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Enregistrement...' : 'Créer le devoir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.violet,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}