// lib/presentation/pages/super_admin/school_trimesters_page.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../services/super_admin_trimester_service.dart';
import 'widgets/trimester_dialog.dart';

class SchoolTrimestersPage extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const SchoolTrimestersPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<SchoolTrimestersPage> createState() => _SchoolTrimestersPageState();
}

class _SchoolTrimestersPageState extends State<SchoolTrimestersPage> {
  final _service = SuperAdminTrimesterService();
  bool _loading = true;
  List<Map<String, dynamic>> _trimesters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    developer.log('SchoolTrimestersPage - schoolId: ${widget.schoolId}');
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      developer.log('Loading trimesters...');
      final data = await _service.getTrimesters(widget.schoolId);
      developer.log('Loaded ${data.length} trimesters: $data');
      
      if (mounted) {
        setState(() {
          _trimesters = data;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      developer.log('Error loading trimesters: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => TrimesterDialog(schoolId: widget.schoolId),
    );
    await _load();
  }

  Future<void> _edit(Map<String, dynamic> t) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => TrimesterDialog(
        schoolId: widget.schoolId,
        trimester: t,
      ),
    );
    await _load();
  }

  Future<void> _delete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer le trimestre "$name" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteTrimester(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trimestre supprimé')),
          );
        }
        await _load();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        title: Text(
          'Trimestres - ${widget.schoolName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _trimesters.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _trimesters.length,
                        itemBuilder: (ctx, i) => _buildCard(_trimesters[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: AppTheme.violet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    final name = t['name'] as String? ?? '—';
    final start = t['start_date'] as String? ?? '';
    final end = t['end_date'] as String? ?? '';
    final id = t['id'] as String? ?? '';

    final period = (start.isNotEmpty && end.isNotEmpty) ? '$start → $end' : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.calendar_today,
                    color: AppTheme.violet, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.nightBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.violet, size: 20),
              onPressed: () => _edit(t),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _delete(id, name),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Erreur: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun trimestre configuré',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour ajouter',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}