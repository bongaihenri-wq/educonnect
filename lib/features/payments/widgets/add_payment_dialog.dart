import 'package:flutter/material.dart';
import '../data/payment_repository.dart';
import '../models/payment_status_dto.dart';

/// Affiche le dialog de saisie d'un versement.
/// Retourne true si un versement a été enregistré (l'appelant recharge alors).
Future<bool> showAddPaymentDialog(
  BuildContext context,
  PaymentRepository repo,
  String schoolId,
  PaymentStatusDto student,
) async {
  final periodeController = TextEditingController(
      text:
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}');
  final libelleController = TextEditingController(text: 'Versement scolarité');
  final amountController = TextEditingController();
  DateTime paidAt = DateTime.now();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text('Versement — ${student.studentName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: periodeController,
                decoration: const InputDecoration(
                    labelText: 'Période (AAAA-MM)',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: libelleController,
                decoration: const InputDecoration(
                    labelText: 'Libellé',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Montant versé (F)',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 10),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, size: 18),
                title: Text(
                    'Date : ${paidAt.day.toString().padLeft(2, '0')}/${paidAt.month.toString().padLeft(2, '0')}/${paidAt.year}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: paidAt,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => paidAt = picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  final amount = double.tryParse(amountController.text.replaceAll(' ', ''));
  if (amount == null || amount <= 0) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Montant invalide')));
    return false;
  }
  if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(periodeController.text.trim())) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Période invalide (AAAA-MM)')));
    return false;
  }

  try {
    await repo.addManualPayment(
      schoolId: schoolId,
      studentId: student.studentId,
      periode: periodeController.text.trim(),
      libelle: libelleController.text.trim(),
      amountPaid: amount,
      paidAt:
          '${paidAt.year}-${paidAt.month.toString().padLeft(2, '0')}-${paidAt.day.toString().padLeft(2, '0')}',
    );
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Versement enregistré — parent notifié'),
        backgroundColor: Colors.green));
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('❌ Erreur : $e')));
    return false;
  }
}
