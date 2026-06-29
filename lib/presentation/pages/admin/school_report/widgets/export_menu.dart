// lib/presentation/pages/admin/school_report/widgets/export_menu.dart
import 'package:flutter/material.dart';

class ExportMenu extends StatelessWidget {
  final Function(String) onExport;

  const ExportMenu({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'Exporter',
      onSelected: onExport,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'excel', child: Text('📊 Excel (.csv)')),
        const PopupMenuItem(value: 'pdf', child: Text('📄 PDF (HTML)')),
        const PopupMenuItem(value: 'word', child: Text('📝 Word (HTML)')),
      ],
    );
  }
}