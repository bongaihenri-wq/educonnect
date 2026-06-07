// lib/presentation/pages/admin/widgets/add_homework_dialog.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../config/theme.dart';

class AddHomeworkDialog extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? homework;
  final Function(Map<String, dynamic> data) onSubmit;

  const AddHomeworkDialog({
    super.key,
    required this.schoolId,
    this.homework,
    required this.onSubmit,
  });

  @override
  State<AddHomeworkDialog> createState() => _AddHomeworkDialogState();
}

class _AddHomeworkDialogState extends State<AddHomeworkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  
  String? _selectedClassId;
  String? _selectedSubjectId;
  String? _selectedTeacherId;
  String _selectedType = 'devoir';
  String _selectedPriority = 'normale';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay? _dueTime;

  final List<String> _types = ['devoir', 'controle', 'examen', 'interro'];
  final List<String> _priorities = ['facultative', 'normale', 'urgente'];

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _teachers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.homework != null) {
      _initEdit();
    }
  }

  void _initEdit() {
    final h = widget.homework!;
    _titleCtrl.text = h['title'] ?? '';
    _descriptionCtrl.text = h['description'] ?? '';
    _roomCtrl.text = h['room'] ?? '';
    _selectedType = h['type'] ?? 'devoir';
    _selectedPriority = h['priority'] ?? 'normale';
    _selectedClassId = h['class_id']?.toString();
    _selectedSubjectId = h['subject_id']?.toString();
    _selectedTeacherId = h['teacher_id']?.toString();
    if (h['due_date'] != null) {
      _dueDate = DateTime.parse(h['due_date'].toString());
    }
  }

  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      
      final classes = await client
          .from('classes')
          .select('id, name, level')
          .eq('school_id', widget.schoolId)
          .order('level');
      
      final subjects = await client
          .from('subjects')
          .select('id, name')
          .eq('school_id', widget.schoolId)
          .order('name');
      
      final teachers = await client
          .from('app_users')
          .select('id, first_name, last_name')
          .eq('school_id', widget.schoolId)
          .eq('role', 'teacher')
          .order('last_name');

      setState(() {
        _classes = List<Map<String, dynamic>>.from(classes);
        _subjects = List<Map<String, dynamic>>.from(subjects);
        _teachers = List<Map<String, dynamic>>.from(teachers);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.homework != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.violet,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier le devoir' : 'Nouveau devoir',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: InputDecoration(
                                labelText: 'Titre *',
                                prefixIcon: const Icon(Icons.title),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v?.isEmpty ?? true ? 'Champ requis' : null,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedType,
                                    decoration: InputDecoration(
                                      labelText: 'Type',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _types.map((t) {
                                      return DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          _getTypeLabel(t),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) => setState(() => _selectedType = v!),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedPriority,
                                    decoration: InputDecoration(
                                      labelText: 'Priorité',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    items: _priorities.map((p) {
                                      return DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          _getPriorityLabel(p),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (v) => setState(() => _selectedPriority = v!),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedClassId,
                              decoration: InputDecoration(
                                labelText: 'Classe *',
                                prefixIcon: const Icon(Icons.class_),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _classes.map((c) {
                                return DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(
                                    c['name']?.toString() ?? 'Classe',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedClassId = v),
                              validator: (v) => v == null ? 'Sélectionnez une classe' : null,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedSubjectId,
                              decoration: InputDecoration(
                                labelText: 'Matière',
                                prefixIcon: const Icon(Icons.book),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _subjects.map((s) {
                                return DropdownMenuItem(
                                  value: s['id'] as String,
                                  child: Text(
                                    s['name']?.toString() ?? 'Matière',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedSubjectId = v),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedTeacherId,
                              decoration: InputDecoration(
                                labelText: 'Enseignant',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: _teachers.map((t) {
                                return DropdownMenuItem(
                                  value: t['id'] as String,
                                  child: Text(
                                    '${t['first_name']} ${t['last_name']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedTeacherId = v),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(context),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Date *',
                                        prefixIcon: const Icon(Icons.calendar_today),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Heure',
                                        prefixIcon: const Icon(Icons.access_time),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text(
                                        _dueTime != null
                                            ? '${_dueTime!.hour}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                                            : 'Non définie',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            TextFormField(
                              controller: _roomCtrl,
                              decoration: InputDecoration(
                                labelText: 'Salle (optionnel)',
                                prefixIcon: const Icon(Icons.room),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            TextFormField(
                              controller: _descriptionCtrl,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                prefixIcon: const Icon(Icons.description),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.violet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isEdit ? 'Modifier' : 'Créer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'examen': return 'Examen';
      case 'controle': return 'Contrôle';
      case 'interro': return 'Interro';
      case 'devoir': default: return 'Devoir';
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'urgente': return 'Urgente';
      case 'facultative': return 'Facultative';
      case 'normale': default: return 'Normale';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) return;

    final data = {
      'title': _titleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'type': _selectedType,
      'priority': _selectedPriority,
      'class_id': _selectedClassId,
      'subject_id': _selectedSubjectId,
      'teacher_id': _selectedTeacherId,
      'due_date': _dueDate.toIso8601String().split('T')[0],
      'due_time': _dueTime != null
          ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'room': _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
      'status': widget.homework?['status'] ?? 'prevu',
    };

    widget.onSubmit(data);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }
}