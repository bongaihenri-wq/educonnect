// lib/presentation/pages/super_admin/widgets/trimester_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../services/super_admin_trimester_service.dart';

class TrimesterDialog extends StatefulWidget {
  final String schoolId;
  final Map<String, dynamic>? trimester;
  const TrimesterDialog({super.key, required this.schoolId, this.trimester});

  @override
  State<TrimesterDialog> createState() => _TrimesterDialogState();
}

class _TrimesterDialogState extends State<TrimesterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  DateTime? _startDate, _endDate;
  bool _loading = false;
  final _service = SuperAdminTrimesterService();
  bool get _isEdit => widget.trimester != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.trimester!['name'] ?? '';
      _startDate = DateTime.tryParse(widget.trimester!['start_date'] ?? '');
      _endDate = DateTime.tryParse(widget.trimester!['end_date'] ?? '');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final p = await showDatePicker(
      context: context,
      initialDate: start ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (_, child) => Theme(data: Theme.of(_).copyWith(colorScheme: ColorScheme.light(primary: AppTheme.violet, onPrimary: Colors.white)), child: child!),
    );
    if (p != null) setState(() => start ? _startDate = p : _endDate = p);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _startDate == null || _endDate == null) return;
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date de fin après date de début')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isEdit) {
        await _service.updateTrimester(id: widget.trimester!['id'], name: _nameCtrl.text.trim(), startDate: _startDate!, endDate: _endDate!);
      } else {
        await _service.createTrimester(schoolId: widget.schoolId, name: _nameCtrl.text.trim(), startDate: _startDate!, endDate: _endDate!);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifier' : 'Nouveau trimestre'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nom (T1, Semestre 1...)', border: OutlineInputBorder()), validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null),
            const SizedBox(height: 12),
            InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: const InputDecoration(labelText: 'Début', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), child: Text(_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Sélectionner'))),
            const SizedBox(height: 12),
            InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: const InputDecoration(labelText: 'Fin', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), child: Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Sélectionner'))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.violet, foregroundColor: Colors.white),
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isEdit ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }
}