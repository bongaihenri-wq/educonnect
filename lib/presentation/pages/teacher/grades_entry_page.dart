// lib/presentation/pages/teacher/grades_entry_page.dart
import 'package:educonnect/data/models/student_model.dart';
import 'package:educonnect/data/repositories/grade_repository.dart';
import 'package:educonnect/presentation/blocs/attendance/attendance_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/attendance/attendance_bloc.dart';
import '../../blocs/attendance/attendance_state.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';

class GradesEntryPage extends StatefulWidget {
  final String classId;
  final String className;
  final String? subjectId;
  final String? subjectName;
  final String? scheduleId;

  const GradesEntryPage({
    super.key,
    required this.classId,
    required this.className,
    this.subjectId,
    this.subjectName,
    this.scheduleId,
  });

  @override
  State<GradesEntryPage> createState() => _GradesEntryPageState();
}

class _GradesEntryPageState extends State<GradesEntryPage> {
  final Map<String, TextEditingController> _controllers = {};
  String _evaluationType = 'devoir';
  String _evaluationName = '';
  bool _isSubmitting = false;
  bool _isLoadingExisting = false;
  double _maxScore = 20.0;
  int _coefficient = 2;
  
  // ✅ NOUVEAU : Scores existants pour modification
  Map<String, double> _existingScores = {};

  final Map<String, int> _defaultCoefficients = {
    'devoir': 2,
    'interro': 1,
    'examen': 3,
    'participation': 1,
  };

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
    
    // ✅ Charger les notes existantes pour modification
    _loadExistingGrades();
  }

  int _getCoefficient(String type) {
    return _coefficient;
  }

  // ✅ NOUVEAU : Charger les notes existantes
  Future<void> _loadExistingGrades() async {
    setState(() => _isLoadingExisting = true);
    try {
      final gradeRepo = GradeRepository(Supabase.instance.client);
      final existing = await gradeRepo.getGradesByClassSubject(
        classId: widget.classId,
        subjectId: widget.subjectId ?? '',
        evaluationType: _evaluationType,
      );
      
      setState(() {
        _existingScores = existing;
        for (var entry in existing.entries) {
          final studentId = entry.key;
          final score = entry.value;
          if (_controllers.containsKey(studentId)) {
            _controllers[studentId]!.text = score.toString();
          }
        }
        _isLoadingExisting = false;
      });
    } catch (e) {
      debugPrint('Notes existantes non trouvées: $e');
      setState(() => _isLoadingExisting = false);
    }
  }

  Future<void> _saveGrades() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final state = context.read<AttendanceBloc>().state;
      final authState = context.read<AuthBloc>().state;
      
      if (authState is! Authenticated) throw Exception('Non authentifié');

      final normalizedType = _evaluationType.toLowerCase().trim();
      const validTypes = ['devoir', 'interro', 'examen', 'participation'];
      
      if (!validTypes.contains(normalizedType)) {
        throw Exception('Type invalide: "$_evaluationType" → "$normalizedType". Attendu: devoir, interro, examen, participation');
      }

      final scores = <String, double>{};
      for (var student in state.students) {
        final controller = _controllers[student.id];
        if (controller != null && controller.text.isNotEmpty) {
          final score = double.tryParse(controller.text.replaceAll(',', '.'));
          if (score != null) {
            if (score > _maxScore) {
              throw Exception('Note ${score} dépasse le maximum $_maxScore pour ${student.fullName}');
            }
            scores[student.id] = score;
          }
        }
      }

      if (scores.isEmpty) throw Exception('Aucune note saisie');

      final gradeRepo = GradeRepository(Supabase.instance.client);
      
      await gradeRepo.saveGrades(
        classId: widget.classId,
        subjectId: widget.subjectId ?? '',
        scheduleId: widget.scheduleId ?? '',
        teacherId: authState.userId,
        schoolId: authState.schoolId,
        evaluationType: normalizedType,
        evaluationName: _evaluationName.isNotEmpty ? _evaluationName : '${_evaluationType.toUpperCase()} du ${DateTime.now().day}/${DateTime.now().month}',
        date: DateTime.now(),
        scores: scores,
        maxScore: _maxScore,
        coefficient: _getCoefficient(normalizedType),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Notes enregistrées !'), backgroundColor: Colors.green),
        );
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notes - ${widget.className}${widget.subjectName != null ? ' (${widget.subjectName})' : ''}',
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        actions: [
          if (_isSubmitting || _isLoadingExisting)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else
            TextButton(
              onPressed: _saveGrades,
              child: const Text('VALIDER', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state.isLoading && state.students.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          for (var s in state.students) {
            _controllers.putIfAbsent(s.id, () => TextEditingController());
          }

          return Column(
            children: [
              _buildEvaluationHeader(),
              Expanded(child: _buildStudentsListCompact(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEvaluationHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nom de l\'évaluation',
              hintText: 'Ex: Devoir 1, Contrôle...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => _evaluationName = v,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'devoir', label: Text('Devoir', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'interro', label: Text('Interro', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'examen', label: Text('Examen', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {_evaluationType},
                  onSelectionChanged: (v) {
                    setState(() {
                      _evaluationType = v.first;
                      _coefficient = _defaultCoefficients[_evaluationType] ?? 1;
                      // Recharger les notes existantes pour le nouveau type
                      _loadExistingGrades();
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Coef:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _coefficient,
                        isDense: true,
                        icon: Icon(Icons.arrow_drop_down, size: 16, color: const Color(0xFF7C3AED)),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF7C3AED),
                        ),
                        items: [1, 2, 3, 4, 5].map((coef) {
                          return DropdownMenuItem(
                            value: coef,
                            child: Text('$coef'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _coefficient = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              SizedBox(
                width: 70,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  controller: TextEditingController(text: '20'),
                  onChanged: (v) => _maxScore = double.tryParse(v) ?? 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsListCompact(AttendanceState state) {
    if (state.students.isEmpty) {
      return const Center(child: Text('Aucun élève dans cette classe'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: state.students.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 12, endIndent: 12),
      itemBuilder: (context, index) {
        final student = state.students[index];
        return _buildCompactGradeTile(student);
      },
    );
  }

  // ✅ CORRIGÉ : Champs plus grands + indicateur modification
  Widget _buildCompactGradeTile(StudentModel student) {
    final hasExisting = _existingScores.containsKey(student.id);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: hasExisting 
                ? Colors.green.withOpacity(0.15)
                : const Color(0xFFF59E0B).withOpacity(0.15),
            child: Text(
              student.initials, 
              style: TextStyle(
                color: hasExisting ? Colors.green : const Color(0xFFF59E0B), 
                fontWeight: FontWeight.bold, 
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  student.fullName, 
                  style: const TextStyle(
                    fontWeight: FontWeight.w600, 
                    fontSize: 14,
                    height: 1.2,
                  ), 
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Mat: ${student.matricule}', 
                  style: TextStyle(
                    color: Colors.grey[600], 
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (hasExisting)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Modif.',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(
            width: 70,
            height: 40,
            child: TextField(
              controller: _controllers[student.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '/$_maxScore',
                hintStyle: TextStyle(
                  fontSize: 11, 
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                isDense: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasExisting ? Colors.green : const Color(0xFF7C3AED),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}