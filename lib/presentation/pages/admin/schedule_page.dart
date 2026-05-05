// lib/presentation/pages/admin/schedule_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/theme.dart';
import '../../../presentation/blocs/auth_bloc/auth_bloc.dart' as auth;

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  String? _schoolId;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      // ✅ CORRIGÉ : Utiliser Authenticated (classe de base)
      final state = context.read<auth.AuthBloc>().state;
      if (state is auth.Authenticated) {
        _schoolId = state.schoolId;
      }

      print('🔍 Schedule - schoolId: $_schoolId');

      if (_schoolId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // ✅ CORRIGÉ : Jointure avec classes pour filtrer par school_id
      final response = await Supabase.instance.client
          .from('schedules')
          .select('*, classes(name, level, school_id), subjects(name), app_users(first_name, last_name)')
          .eq('classes.school_id', _schoolId!)
          .order('day_of_week')
          .order('start_time');

      print('📊 Schedule response count: ${response.length}');

      setState(() {
        _entries = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur Schedule: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _getDayName(int? day) {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return day != null && day >= 1 && day <= 7 ? days[day] : 'Inconnu';
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    if (time is String) return time.substring(0, 5);
    return time.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: const Text('Emploi du Temps'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Aucun cours programmé',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    final className = entry['classes']?['name'] ?? 'Classe inconnue';
                    final classLevel = entry['classes']?['level'] ?? '';
                    final subjectName = entry['subjects']?['name'] ?? 'Sans matière';
                    final teacherName = '${entry['app_users']?['first_name'] ?? ''} ${entry['app_users']?['last_name'] ?? ''}';
                    final dayOfWeek = entry['day_of_week'] is int 
                        ? entry['day_of_week'] as int 
                        : int.tryParse(entry['day_of_week'].toString()) ?? 1;
                    final startTime = _formatTime(entry['start_time']);
                    final endTime = _formatTime(entry['end_time']);
                    final room = entry['room'] ?? 'Non assignée';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.calendar_today, color: Colors.teal),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subjectName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '$className ($classLevel)',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Prof: $teacherName',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildInfoChip(Icons.today, _getDayName(dayOfWeek), Colors.blue),
                                const SizedBox(width: 8),
                                _buildInfoChip(Icons.access_time, '$startTime - $endTime', Colors.orange),
                                const SizedBox(width: 8),
                                _buildInfoChip(Icons.room, room, Colors.purple),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
