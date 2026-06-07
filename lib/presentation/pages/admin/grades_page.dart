// lib/presentation/pages/admin/grades_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/admin_stats_service.dart';
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
  bool _isLoading = true;
  String? _schoolId;
  String? _error;

  // Données
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _monthlyTrend = [];
  List<Map<String, dynamic>> _atRiskStudents = [];
  List<Map<String, dynamic>> _subjectAverages = [];
  List<Map<String, dynamic>> _studentAverages = [];

  // Filtre
  String _selectedTrimestre = 'T1';
  int? _selectedMois;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
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

      // Charger toutes les données en parallèle
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
    
    // Enrichir avec les moyennes des élèves
    for (var classe in classes) {
      final classId = classe['id'] as String;
      final students = await _statsService.getGradesByClass(_schoolId!, classId);
      
      // Calculer moyenne de la classe
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

  Future<void> _loadMonthlyTrend() async {
    // Simuler données mensuelles (à remplacer par vraie requête SQL)
    _monthlyTrend = [
      {'month': 'Sept', 'average': 11.5},
      {'month': 'Oct', 'average': 12.1},
      {'month': 'Nov', 'average': 11.8},
      {'month': 'Déc', 'average': 10.9},
      {'month': 'Jan', 'average': 11.2},
      {'month': 'Fév', 'average': 12.5},
      {'month': 'Mar', 'average': 11.7},
      {'month': 'Avr', 'average': 12.3},
      {'month': 'Mai', 'average': 11.9},
    ];
  }

  Future<void> _loadAtRiskStudents() async {
    final allStudents = <Map<String, dynamic>>[];
    
    for (var classe in _classes) {
      final students = classe['student_list'] as List<dynamic>? ?? [];
      for (var s in students) {
        final avg = double.tryParse(s['average_grade'] ?? '0') ?? 0;
        if (avg > 0 && avg < 10) { // Seuil large pour le filtre dynamique
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
    
    _atRiskStudents = allStudents;
  }

  Future<void> _loadSubjectAverages() async {
    // Récupérer les matières et calculer les moyennes
    final response = await Supabase.instance.client
        .from('subjects')
        .select('id, name')
        .eq('school_id', _schoolId!);
    
    final subjects = List<Map<String, dynamic>>.from(response);
    final result = <Map<String, dynamic>>[];
    
    for (var subject in subjects) {
      final subjectId = subject['id'] as String;
      final grades = await Supabase.instance.client
          .from('grades')
          .select('score')
          .eq('school_id', _schoolId!)
          .eq('subject_id', subjectId);
      
      if (grades.isNotEmpty) {
        final values = grades.map((g) => (g['score'] as num).toDouble()).toList();
        final average = values.reduce((a, b) => a + b) / values.length;
        
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

  void _showStudentDetail(Map<String, dynamic> student) async {
    final studentId = student['student_id'] as String?;
    if (studentId == null || _schoolId == null) return;

    // Récupérer les notes par matière de l'élève
    final grades = await Supabase.instance.client
        .from('grades')
        .select('score, subjects(name), date')
        .eq('school_id', _schoolId!)
        .eq('student_id', studentId)
        .order('date', ascending: false);

    // Grouper par matière
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

    // Calculer moyenne générale
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
                    // 1. SÉLECTEUR DE PÉRIODE
                    SliverToBoxAdapter(
                      child: PeriodSelector(
                        onPeriodChanged: _onPeriodChanged,
                      ),
                    ),

                    // 2. MOYENNES PAR CLASSE (scrollable horizontal)
                    SliverToBoxAdapter(
                      child: _buildClassSection(),
                    ),

                    // 3. TENDANCE 9 MOIS
                    SliverToBoxAdapter(
                      child: GradeTrendChart(
                        monthlyData: _monthlyTrend,
                      ),
                    ),

                    // 4. ÉLÈVES À RISQUE
                    SliverToBoxAdapter(
                      child: GradeAtRiskList(
                        students: _atRiskStudents,
                        onStudentTap: _showStudentDetail,
                      ),
                    ),

                    // 5. MEILLEURES MATIÈRES
                    SliverToBoxAdapter(
                      child: GradeSubjectRanking(
                        subjectAverages: _subjectAverages,
                        showBest: true,
                      ),
                    ),

                    // 6. MATIÈRES EN DIFFICULTÉ
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
            ],
          ),
        ),
        
        // Cartes scrollable horizontal
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