// lib/presentation/pages/super_admin/subscriptions/tabs/relaunch_tab.dart
import 'package:flutter/material.dart';
import '../widgets/parents_to_relaunch_list.dart';

class RelaunchTab extends StatelessWidget {
  final List<Map<String, dynamic>> parentsToRelaunch;
  final String? selectedRelanceStatus;
  final String relanceSearchQuery;
  final Function(String?) onStatusChanged;
  final Function(String) onSearchChanged;
  final Future<void> Function() onRefresh;
  final Function(String) onCall;
  final Function(String) onSendSMS;
  final Function(String) onViewDetails;

  const RelaunchTab({
    super.key,
    required this.parentsToRelaunch,
    this.selectedRelanceStatus,
    required this.relanceSearchQuery,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onCall,
    required this.onSendSMS,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedRelanceStatus,
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'never_connected', child: Text('🔴 Jamais')),
                      DropdownMenuItem(value: 'expired', child: Text('🟡 Expiré')),
                      DropdownMenuItem(value: 'no_subscription', child: Text('⚪ Sans')),
                    ],
                    onChanged: (value) => onStatusChanged(value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Recherche...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (value) => onSearchChanged(value),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, color: Color(0xFFFF6D00), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${parentsToRelaunch.length} parent(s) à relancer',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFFFF6D00),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ParentsToRelaunchList(
              parents: parentsToRelaunch,
              onCall: onCall,
              onSendSMS: onSendSMS,
              onViewDetails: onViewDetails,
            ),
          ),
        ],
      ),
    );
  }
}