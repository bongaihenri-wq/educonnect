import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ImportPreviewPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String type;
  final String schoolId;
  final String schoolCode;

  const ImportPreviewPage({
    super.key,
    required this.data,
    required this.type,
    required this.schoolId,
    required this.schoolCode, required String csvContent,
  });

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  late List<Map<String, dynamic>> _rows;
  late List<String> _headers;
  final Set<int> _selectedRows = {};
  bool _selectAll = true;

  @override
  void initState() {
    super.initState();
    _rows = List<Map<String, dynamic>>.from(widget.data);
    _headers = _extractHeaders();
    _selectAllRows(true);
  }

  List<String> _extractHeaders() {
    if (_rows.isEmpty) return [];
    final allKeys = <String>{};
    for (final row in _rows) {
      allKeys.addAll(row.keys.map((k) => k.toString()));
    }
    return allKeys.toList()..sort();
  }

  void _selectAllRows(bool select) {
    setState(() {
      _selectAll = select;
      if (select) {
        _selectedRows.addAll(List.generate(_rows.length, (i) => i));
      } else {
        _selectedRows.clear();
      }
    });
  }

  void _toggleRow(int index) {
    setState(() {
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index);
      } else {
        _selectedRows.add(index);
      }
    });
  }

  List<Map<String, dynamic>> get _validRows {
    return _selectedRows.map((i) => _rows[i]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Prévisualisation'),
        backgroundColor: AppTheme.violet,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => _selectAllRows(!_selectAll),
            icon: Icon(
              _selectAll ? Icons.deselect : Icons.select_all,
              color: Colors.white,
            ),
            label: Text(
              _selectAll ? 'Tout désélectionner' : 'Tout sélectionner',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _rows.isEmpty
                ? _buildEmptyState()
                : _buildDataTable(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_rows.length} lignes trouvées',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedRows.length} sélectionnées pour import',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('Type: ${widget.type.replaceAll('_', ' ')}'),
              const SizedBox(width: 8),
              _buildTypeChip('École: ${widget.schoolCode}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.violet,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée à afficher',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          border: TableBorder.all(color: Colors.grey.shade300),
          columns: [
            DataColumn(
              label: Checkbox(
                value: _selectAll,
                onChanged: (v) => _selectAllRows(v ?? false),
              ),
            ),
            ..._headers.map((h) => DataColumn(
              label: Text(
                h,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )),
          ],
          rows: List.generate(_rows.length, (index) {
            final row = _rows[index];
            final isSelected = _selectedRows.contains(index);
            
            return DataRow(
              selected: isSelected,
              onSelectChanged: (_) => _toggleRow(index),
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleRow(index),
                  ),
                ),
                ..._headers.map((h) {
                  final value = row[h]?.toString() ?? '';
                  return DataCell(
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        color: value.isEmpty ? Colors.grey[400] : Colors.black,
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _selectedRows.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context, {
                          'confirmed': true,
                          'validRows': _validRows,
                        });
                      },
                icon: const Icon(Icons.check_circle),
                label: Text(
                  'Importer ${_selectedRows.length} lignes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}