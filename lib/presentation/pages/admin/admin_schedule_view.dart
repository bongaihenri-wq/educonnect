import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/data/providers/schedule_provider.dart';
import '/presentation/pages/admin/widgets/loading_view.dart';
class AdminScheduleView extends StatefulWidget {
  const AdminScheduleView({super.key});

  @override
  State<AdminScheduleView> createState() => _AdminScheduleViewState();
}

class _AdminScheduleViewState extends State<AdminScheduleView> {
  String? selectedClassId;

  String getDayName(int dayIndex) {
  const days = [
    "Dimanche", "Lundi", "Mardi", "Mercredi", 
    "Jeudi", "Vendredi", "Samedi"
  ];
  return (dayIndex >= 0 && dayIndex < days.length) 
      ? days[dayIndex] 
      : "Jour inconnu";
}

  @override
  Widget build(BuildContext context) {
    final scheduleProv = context.watch<ScheduleProvider>();
    // Extraction des classes uniques pour le menu déroulant
    final distinctClasses = scheduleProv.allSchedules
        .map((e) => {'id': e.classId, 'name': e.className})
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Récapitulatif des Cours")),
      body: LoadingView(
        isLoading: scheduleProv.isLoading,
        errorMessage: scheduleProv.errorMessage,
        onRetry: () => scheduleProv.loadSchedules("TON_SCHOOL_ID"),
        child: Column(
          children: [
            // Sélecteur de classe
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Sélectionner une classe"),
                value: selectedClassId,
                items: distinctClasses.map((c) {
                  return DropdownMenuItem(value: c['id'], child: Text(c['name']!));
                }).toList(),
                onChanged: (val) => setState(() => selectedClassId = val),
              ),
            ),
            // Liste des cours
            Expanded(
              child: selectedClassId == null
                  ? const Center(child: Text("Choisissez une classe pour voir le planning"))
                  : ListView.builder(
                      itemCount: scheduleProv.getSchedulesByClass(selectedClassId!).length,
                      itemBuilder: (context, index) {
                        final course = scheduleProv.getSchedulesByClass(selectedClassId!)[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                           leading: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                               color: Colors.blue.withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(5),
                                ),
                              child: Text(
                         // Appel de la méthode que nous venons de créer
                              getDayName(course.dayOfWeek).substring(0, 3), 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                 ),
                              ),   
                            title: Text("${course.subjectName} - ${course.room}"),
                            subtitle: Text("Prof: ${course.teacherName}"),
                            trailing: Text("${course.startTimeStr} - ${course.endTimeStr}"),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}