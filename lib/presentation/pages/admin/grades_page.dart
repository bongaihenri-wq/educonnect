import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/admin_stats_service.dart';
import '../../../services/period_service.dart';
import '../../blocs/auth_bloc/auth_bloc.dart' as auth;
import 'widgets/period_selector.dart';
import 'widgets/grade_class_card.dart';
import 'widgets/grade_trend_chart.dart';
import 'widgets/grade_at_risk_list.dart';
import 'widgets/grade_subject_ranking.dart';
import 'widgets/grade_student_detail.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  final AdminStatsService _statsService = AdminStatsService();
  final PeriodService _periodService = PeriodService();
  bool _isLoading = true;
  String? _schoolId;
  String? _error;

  // Données
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _monthlyTrend = [];
  List<Map<String, dynamic>> _atRiskStudents = [];
  List<Map<String, dynamic>> _subjectAverages = [];
  List<Map<String, dynamic>> _studentAverages = [];

  // Filtre ANCIEN - Conservé pour compatibilité
  String _selectedTrimestre = 'T1';
  int? _selectedMois;

  // Filtre avec périodes réelles
  List<Map<String, dynamic>> _academicPeriods = [];
  Map<String, dynamic>? _selectedPeriod;
  bool _useRealPeriods = false;

  @override
  void initState() {
    super.initState();
    _loadPeriodsAndData();
  }

  Future<void> _loadPeriodsAndData() async {
    final state = context.read<auth.AuthBloc>().state;
    if (state is auth.Authenticated) {
      _schoolId = state.schoolId;
    }

    if (_schoolId == null) {
      setState(() {
        _isLoading = false;
        _error = 'School ID non trouvé';
      });
      return;
    }

    // Charger les périodes
    _academicPeriods = await _periodService.getAllPeriods(_schoolId!);
    final current = await _periodService.getCurrentPeriod(_schoolId!);
    
    if (mounted) {
      setState(() {
        if (current != null) {
          _selectedPeriod = current;
          _selectedTrimestre = current['name'] as String;
          _useRealPeriods = true;
        }
      });
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadClassesWithGrades(),
        _loadMonthlyTrend(),
        _loadAtRiskStudents(),
        _loadSubjectAverages(),
      ]);

      if (mounted) {
        setState(() => _isLoading = false);
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

  Future<void> _loadClassesWithGrades() async {
    final classes = await _statsService.getClassesWithStats(_schoolId!);
    
    for (var classe in classes) {
      final classId = classe['id'] as String;
      
      // Filtrer par période si sélectionnée
      List<Map<String, dynamic>> students;
      if (_useRealPeriods && _selectedPeriod != null) {
        students = await _getStudentsWithGradesFiltered(classId);
      } else {
        students = await _statsService.getGradesByClass(_schoolId!, classId);
      }
      
      double classTotal = 0;
      int classCount = 0;
      int below8 = 0;
      
      for (var s in students) {
        final avg = double.tryParse(s['average_grade'] ?? '0') ?? 0;
        if (avg > 0) {
          classTotal += avg;
          classCount++;
          if (avg < 8) below8++;
        }
      }
      
      classe['class_average'] = classCount > 0 ? (classTotal / classCount).toDouble() : 0.0;
      classe['students_below_8'] = below8;
      classe['student_list'] = students;
    }
    
    _classes = classes;
  }

  Future<List<Map<String, dynamic>>> _getStudentsWithGradesFiltered(String classId) async {
    final studentsResponse = await Supabase.instance.client
        .from('students')
        .select('id, first_name, last_name, matricule')
        .eq('school_id', _schoolId!)
        .eq('class_id', classId)
        .order('last_name');

    final students = List<Map<String, dynamic>>.from(studentsResponse);
    final result = <Map<String, dynamic>>[];

    final startDate = _selectedPeriod!['start_date'] as String;
    final endDate = _selectedPeriod!['end_date'] as String;

    for (var student in students) {
      final studentId = student['id'] as String;

      final gradesResponse = await Supabase.instance.client
          .from('grades')
          .select('score, max_score, coefficient, subjects(name), date')
          .eq('school_id', _schoolId!)
          .eq('student_id', studentId)
          .gte('date', startDate)
          .lte('date', endDate);

      final grades = List<Map<String, dynamic>>.from(gradesResponse);

      double total = 0;
      double coefTotal = 0;
      for (var g in grades) {
        final score = (g['score'] as num).toDouble();
        final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20.0;
        final coef = (g['coefficient'] as num?)?.toInt() ?? 1;
        final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0.0;
        total += noteSur20 * coef;
        coefTotal += coef;
      }
      final avg = coefTotal > 0 ? total / coefTotal : 0;

      final attendanceResponse = await Supabase.instance.client
          .from('attendance')
          .select('status')
          .eq('school_id', _schoolId!)
          .eq('student_id', studentId);

      int totalAtt = attendanceResponse.length;
      int present = 0;
      int absent = 0;
      int late = 0;

      for (var a in attendanceResponse) {
        final status = a['status']?.toString() ?? '';
        if (status == 'present') present++;
        else if (status == 'absent') absent++;
        else if (status == 'late') late++;
      }

      result.add({
        'student_id': studentId,
        'student_name': '${student['first_name']} ${student['last_name']}',
        'matricule': student['matricule'],
        'average_grade': avg.toStringAsFixed(2),
        'grades_count': grades.length,
        'presence_rate': totalAtt > 0 ? (present / totalAtt * 100).round() : 0,
        'absent_count': absent,
        'late_count': late,
      });
    }

    return result;
  }

  Future<void> _loadMonthlyTrend() async {
    if (_schoolId == null) return;

    var query = Supabase.instance.client
        .from('grades')
        .select('score, max_score, date')
        .eq('school_id', _schoolId!);

    if (_useRealPeriods && _selectedPeriod != null) {
      final startDate = _selectedPeriod!['start_date'] as String;
      final endDate = _selectedPeriod!['end_date'] as String;
      query = query.gte('date', startDate).lte('date', endDate);
    }

    final gradesResponse = await query;
    final grades = List<Map<String, dynamic>>.from(gradesResponse);

    if (grades.isEmpty) {
      _monthlyTrend = [];
      return;
    }

    final monthlyMap = <String, List<double>>{};
    for (var g in grades) {
      final date = DateTime.parse(g['date'] as String);
      final monthKey = _getMonthName(date.month);
      final score = (g['score'] as num).toDouble();
      final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20.0;
      final noteSur20 = maxScore > 0 ? (score / maxScore) * 20 : 0.0;
      
      monthlyMap.putIfAbsent(monthKey, () => []);
      monthlyMap[monthKey]!.add(noteSur20);
    }

    _monthlyTrend = monthlyMap.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'month': e.key, 'average': avg};
    }).toList()..sort((a, b) {
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
      return months.indexOf(a['month'] as String).compareTo(months.indexOf(b['month'] as String));
    });
  }

  String _getMonthName(int month) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }

  Future<void> _loadAtRiskStudents() async {
    if (_schoolId == null) return;

    final allStudents = <Map<String, dynamic>>[];
    
    for (var classe in _classes) {
      final students = classe['student_list'] as List<dynamic>? ?? [];
      for (var s in students) {
        final avg = double.tryParse(s['average_grade'] ?? '0') ?? 0;
        final riskThreshold = _isShortPeriod() ? 12.0 : 10.0;
        
        if (avg > 0 && avg < riskThreshold) {
          allStudents.add({
            'name': s['student_name'],
            'class': '${classe['level']} ${classe['name']}',
            'average': avg,
            'matricule': s['matricule'],
            'student_id': s['student_id'],
            'grades': s['grades_count'],
          });
        }
      }
    }
    
    allStudents.sort((a, b) => (a['average'] as double).compareTo(b['average'] as double));
    
    _atRiskStudents = allStudents;
  }

  bool _isShortPeriod() {
    if (_selectedPeriod == null) return false;
    final name = _selectedPeriod!['name'] as String;
    return name == 'Aujourd\'hui' || name == 'Cette semaine';
  }

  Future<void> _loadSubjectAverages() async {
    if (_schoolId == null) return;

    final response = await Supabase.instance.client
        .from('subjects')
        .select('id, name')
        .eq('school_id', _schoolId!);
    
    final subjects = List<Map<String, dynamic>>.from(response);
    final result = <Map<String, dynamic>>[];
    
    for (var subject in subjects) {
      final subjectId = subject['id'] as String;
      
      var query = Supabase.instance.client
          .from('grades')
          .select('score, max_score')
          .eq('school_id', _schoolId!)
          .eq('subject_id', subjectId);
      
      if (_useRealPeriods && _selectedPeriod != null) {
        final startDate = _selectedPeriod!['start_date'] as String;
        final endDate = _selectedPeriod!['end_date'] as String;
        query = query.gte('date', startDate).lte('date', endDate);
      }
      
      final grades = await query;
      
      if (grades.isNotEmpty) {
        double total = 0;
        for (var g in grades) {
          final score = (g['score'] as num).toDouble();
          final maxScore = (g['max_score'] as num?)?.toDouble() ?? 20.0;
          total += maxScore > 0 ? (score / maxScore) * 20 : 0;
        }
        final average = total / grades.length;
        
        result.add({
          'subject': subject['name'],
          'average': average,
          'student_count': grades.length,
        });
      }
    }
    
    _subjectAverages = result;
  }

  void _onPeriodChanged(String trimestre, int? mois) {
    setState(() {
      _selectedTrimestre = trimestre;
      _selectedMois = mois;
      _isLoading = true;
    });
    _loadData();
  }

  void _onRealPeriodChanged(Map<String, dynamic>? period) {
    setState(() {
      _selectedPeriod = period;
      if (period != null) {
        _selectedTrimestre = period['name'] as String;
        _useRealPeriods = true;
      } else {
        _useRealPeriods = false;
      }
      _isLoading = true;
    });
    _loadData();
  }

  void _showStudentDetail(Map<String, dynamic> student) async {
    final studentId = student['student_id'] as String?;
    if (studentId == null || _schoolId == null) return;

    var query = Supabase.instance.client
        .from('grades')
        .select('score, max_score, coefficient, subjects(name), date')
        .eq('school_id', _schoolId!)
        .eq('student_id', studentId);
    
    if (_useRealPeriods && _selectedPeriod != null) {
      final startDate = _selectedPeriod!['start_date'] as String;
      final endDate = _selectedPeriod!['end_date'] as String;
      query = query.gte('date', startDate).lte('date', endDate);
    }
    
    final grades = await query;

    final subjectMap = <String, Map<String, dynamic>>{};
    for (var grade in grades) {
      final subjectName = grade['subjects']?['name'] ?? 'Inconnu';
      final score = (grade['score'] as num).toDouble();
      
      if (!subjectMap.containsKey(subjectName)) {
        subjectMap[subjectName] = {
          'scores': <double>[],
          'last': score,
        };
      }
      subjectMap[subjectName]!['scores'].add(score);
    }

    final subjectGrades = subjectMap.entries.map((e) {
      final scores = e.value['scores'] as List<double>;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return {
        'subject': e.key,
        'average': avg,
        'count': scores.length,
        'last_grade': e.value['last'],
      };
    }).toList();

    double total = 0;
    int count = 0;
    for (var sg in subjectGrades) {
      total += sg['average'] as double;
      count++;
    }
    final generalAvg = count > 0 ? (total / count).toDouble() : 0.0;

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => GradeStudentDetail(
          studentName: student['name'] ?? 'Inconnu',
          matricule: student['matricule'] ?? 'N/A',
          className: student['class'] ?? '-',
          generalAverage: generalAvg,
          subjectGrades: subjectGrades,
        ),
      );
    }
  }

  void _showClassStudents(Map<String, dynamic> classe) {
    final students = classe['student_list'] as List<dynamic>? ?? [];
    final className = classe['name']?.toString() ?? 'Classe inconnue';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Élèves - $className',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index] as Map<String, dynamic>;
                      final avg = double.tryParse(s['average_grade'] ?? '0') ?? 0;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(avg).withOpacity(0.1),
                          child: Text(
                            avg > 0 ? avg.toStringAsFixed(1) : '-',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getColor(avg),
                            ),
                          ),
                        ),
                        title: Text(s['student_name'] ?? 'Inconnu'),
                        subtitle: Text('${s['grades_count'] ?? 0} notes'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                        onTap: () {
                          Navigator.pop(context);
                          _showStudentDetail({
                            'name': s['student_name'],
                            'matricule': s['matricule'],
                            'class': className,
                            'student_id': s['student_id'],
                            'average': avg,
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColor(double average) {
    if (average >= 14) return Colors.green;
    if (average >= 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ═══════════════════════════════════════════════════════════
                    //  SÉLECTEUR DE PÉRIODE — UTILISE PeriodSelector WIDGET
                    // ═══════════════════════════════════════════════════════════
                    SliverToBoxAdapter(
                      child: PeriodSelector(
                        periods: _academicPeriods,
                        selectedPeriod: _selectedPeriod,
                        onPeriodChanged: _onRealPeriodChanged,
                      ),
                    ),

                    // MOYENNES PAR CLASSE
                    SliverToBoxAdapter(
                      child: _buildClassSection(),
                    ),

                    // TENDANCE
                    SliverToBoxAdapter(
                      child: GradeTrendChart(
                        monthlyData: _monthlyTrend,
                      ),
                    ),

                    // ÉLÈVES À RISQUE
                    SliverToBoxAdapter(
                      child: GradeAtRiskList(
                        students: _atRiskStudents,
                        onStudentTap: _showStudentDetail,
                      ),
                    ),

                    // MEILLEURES MATIÈRES
                    SliverToBoxAdapter(
                      child: GradeSubjectRanking(
                        subjectAverages: _subjectAverages,
                        showBest: true,
                      ),
                    ),

                    // MATIÈRES EN DIFFICULTÉ
                    SliverToBoxAdapter(
                      child: GradeSubjectRanking(
                        subjectAverages: _subjectAverages,
                        showBest: false,
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
    );
  }

  Widget _buildClassSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Moyennes par Classe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.nightBlue,
                ),
              ),
              Text(
                '${_classes.length} classes',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 40)
            ],
          ),
        ),
        
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final classe = _classes[index];
              final stats = classe['stats'] as Map<String, dynamic>? ?? {};
              final classAvg = (classe['class_average'] as num?)?.toDouble() ?? 0;
              final below8 = classe['students_below_8'] as int? ?? 0;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GradeClassCard(
                  className: '${classe['level']} ${classe['name']}',
                  averageGrade: classAvg,
                  totalStudents: stats['total_students'] ?? 0,
                  studentsBelow8: below8,
                  onTap: () => _showClassStudents(classe),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Erreur: $_error'),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}