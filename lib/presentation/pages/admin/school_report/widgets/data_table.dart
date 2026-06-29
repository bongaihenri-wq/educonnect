// lib/presentation/pages/admin/school_report/widgets/data_table.dart
import 'package:flutter/material.dart';
import '../../../../../config/theme.dart';

class ReportColumn {
  final String key;
  final String label;
  final double width;
  final TextAlign? align;

  const ReportColumn({
    required this.key,
    required this.label,
    required this.width,
    this.align,
  });
}

class ReportDataTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final List<ReportColumn> columns;
  final List<Widget> Function(Map<String, dynamic>) rowBuilder;

  const ReportDataTable({
    super.key,
    required this.data,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.columns,
    required this.rowBuilder,
  });

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  final ScrollController _headerScroll = ScrollController();
  final ScrollController _bodyScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _bodyScroll.addListener(() {
      if (_headerScroll.hasClients) {
        _headerScroll.jumpTo(_bodyScroll.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScroll.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    final totalWidth = widget.columns.fold<double>(0, (sum, c) => sum + c.width) + 24;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCounter(),
          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildHeader(totalWidth),
                  Expanded(child: _buildBody(totalWidth)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.data.length} enregistrement${widget.data.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Glissez ↔ pour voir plus',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double totalWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.violet.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _headerScroll,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: totalWidth,
          child: Row(
            children: widget.columns.map((col) {
              return SizedBox(
                width: col.width,
                child: Text(
                  col.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.violet,
                  ),
                  textAlign: col.align,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(double totalWidth) {
    return Scrollbar(
      controller: _bodyScroll,
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _bodyScroll,
        child: SizedBox(
          width: totalWidth,
          child: ListView.builder(
            itemCount: widget.data.length + (widget.hasMore || widget.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.data.length) {
                if (widget.isLoadingMore) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return _buildLoadMoreButton();
              }
              return _buildRow(widget.data[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item) {
    final cells = widget.rowBuilder(item);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: List.generate(widget.columns.length, (i) {
          return SizedBox(
            width: widget.columns[i].width,
            child: cells[i],
          );
        }),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: widget.onLoadMore,
          icon: const Icon(Icons.expand_more),
          label: const Text('Charger plus'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.violet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }
}