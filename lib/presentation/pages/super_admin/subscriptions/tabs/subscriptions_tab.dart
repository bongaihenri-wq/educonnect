// lib/presentation/pages/super_admin/subscriptions/tabs/subscriptions_tab.dart
import 'package:flutter/material.dart';
import '../widgets/subscription_stats_row.dart';
import '../widgets/subscription_filter_bar.dart';
import '../widgets/subscription_data_table.dart';

class SubscriptionsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> subscriptions;
  final List<Map<String, dynamic>> schools;
  final String? selectedSchool;
  final String? selectedCountry;
  final String? selectedStatus;
  final String searchQuery;
  final Function({String? school, String? country, String? status, String? search}) onFilterChanged;
  final Future<void> Function() onRefresh;

  const SubscriptionsTab({
    super.key,
    required this.stats,
    required this.subscriptions,
    required this.schools,
    this.selectedSchool,
    this.selectedCountry,
    this.selectedStatus,
    required this.searchQuery,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubscriptionStatsRow(stats: stats),
              const SizedBox(height: 20),
              SubscriptionFilterBar(
                schools: schools,
                selectedSchool: selectedSchool,
                selectedCountry: selectedCountry,
                selectedStatus: selectedStatus,
                searchQuery: searchQuery,
                onFilterChanged: onFilterChanged,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('📊 Tous les abonnements (${subscriptions.length})'),
              const SizedBox(height: 10),
              SubscriptionDataTable(
                subscriptions: subscriptions,
                onRefresh: onRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
    );
  }
}