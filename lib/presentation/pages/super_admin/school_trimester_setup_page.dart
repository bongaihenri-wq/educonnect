// lib/presentation/pages/super_admin/school_trimester_setup_page.dart
// NOUVEAU FICHIER - Page pour définir les trimestres d'une école
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchoolTrimesterSetupPage extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const SchoolTrimesterSetupPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<SchoolTrimesterSetupPage> createState() => _SchoolTrimesterSetupPageState();
}

class _SchoolTrimesterSetupPageState extends State<SchoolTrimesterSetupPage> {
  final _supabase = Supabase.instance.client;
  final _academicYearController = TextEditingController(text: '2025-2026');
  
  int _periodCount = 3;
  final List<TrimesterFormData> _trimesters = [];

  @override
  void initState() {
    super.initState();
    _initializeTrimesters();
  }

  void _initializeTrimesters() {
    _trimesters.clear();
    for (int i = 0; i < _periodCount; i++) {
      _trimesters.add(TrimesterFormData(
        name: i == 0 ? 'Trimestre 1' : i == 1 ? 'Trimestre 2' : 'Trimestre 3',
        startDate: DateTime(2025, 9 + i * 3, 1),
        endDate: DateTime(2025, 11 + i * 3, 30),
      ));
    }
  }

  Future<void> _saveTrimesters() async {
    try {
      final trimestersJson = _trimesters.map((t) => {
        'name': t.nameController.text,
        'start_date': t.startDate.toIso8601String().split('T')[0],
        'end_date': t.endDate.toIso8601String().split('T')[0],
      }).toList();

      await _supabase.rpc('create_school_periods', params: {
        'p_school_id': widget.schoolId,
        'p_academic_year': _academicYearController.text,
        'p_trimesters': trimestersJson,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Périodes scolaires créées avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDate(TrimesterFormData trimester, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? trimester.startDate : trimester.endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          trimester.startDate = picked;
        } else {
          trimester.endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Périodes - ${widget.schoolName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _academicYearController,
              decoration: const InputDecoration(
                labelText: 'Année académique',
                hintText: '2025-2026',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                const Text('Type:'),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text('3 Trimestres'),
                  selected: _periodCount == 3,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _periodCount = 3;
                        _initializeTrimesters();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('2 Semestres'),
                  selected: _periodCount == 2,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _periodCount = 2;
                        _initializeTrimesters();
                      });
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            ..._trimesters.asMap().entries.map((entry) {
              final index = entry.key;
              final trimester = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Période ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: trimester.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          hintText: 'Trimestre 1',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Début'),
                              subtitle: Text(
                                '${trimester.startDate.day}/${trimester.startDate.month}/${trimester.startDate.year}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _pickDate(trimester, true),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Fin'),
                              subtitle: Text(
                                '${trimester.endDate.day}/${trimester.endDate.month}/${trimester.endDate.year}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _pickDate(trimester, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveTrimesters,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer les périodes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrimesterFormData {
  final TextEditingController nameController;
  DateTime startDate;
  DateTime endDate;

  TrimesterFormData({
    required String name,
    required this.startDate,
    required this.endDate,
  }) : nameController = TextEditingController(text: name);
}