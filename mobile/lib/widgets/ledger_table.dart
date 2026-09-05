import 'package:flutter/material.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'ledger_tx_tile.dart';

class LedgerTableColumn<T> {
  final String key;
  final String header;
  final bool sortable;
  final double width;
  final Alignment alignment;
  final Widget Function(T row) cell;

  const LedgerTableColumn({
    required this.key,
    required this.header,
    required this.cell,
    this.sortable = false,
    this.width = 140,
    this.alignment = Alignment.centerLeft,
  });
}

({String field, String direction}) parseSort(String sort) {
  if (sort.endsWith('_asc')) {
    return (field: sort.substring(0, sort.length - 4), direction: 'asc');
  }
  if (sort.endsWith('_desc')) {
    return (field: sort.substring(0, sort.length - 5), direction: 'desc');
  }
  return (field: sort, direction: 'desc');
}

String toggleSort(String current, String field) {
  final parsed = parseSort(current);
  if (parsed.field == field) {
    return '${field}_${parsed.direction == 'desc' ? 'asc' : 'desc'}';
  }
  const textFirst = ['title', 'source', 'kind', 'account', 'category', 'type'];
  return '${field}_${textFirst.contains(field) ? 'asc' : 'desc'}';
}

class LedgerTable<T> extends StatelessWidget {
  final List<LedgerTableColumn<T>> columns;
  final List<T> rows;
  final String Function(T row) rowKey;
  final bool loading;
  final String empty;
  final String? sort;
  final ValueChanged<String>? onSort;
  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int>? onPageChange;
  final ValueChanged<int>? onPageSizeChange;
  final ValueChanged<T>? onRowTap;
  final List<int> pageSizeOptions;
  final bool showFooter;
  final double minWidth;

  const LedgerTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowKey,
    this.page = 1,
    this.pageSize = 25,
    this.total = 0,
    this.onPageChange,
    this.onPageSizeChange,
    this.loading = false,
    this.empty = 'No rows',
    this.sort,
    this.onSort,
    this.onRowTap,
    this.pageSizeOptions = const [10, 25, 50, 100],
    this.showFooter = true,
    this.minWidth = 880,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (total / pageSize).ceil().clamp(1, 1 << 20);
    final safePage = page.clamp(1, totalPages);
    final start = total == 0 ? 0 : (safePage - 1) * pageSize + 1;
    final end = total == 0 ? 0 : (safePage * pageSize).clamp(0, total);
    final parsed = sort == null ? null : parseSort(sort!);
    final tableWidth = columns.fold<double>(0, (sum, column) => sum + column.width);
    final width = tableWidth < minWidth ? minWidth : tableWidth;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.onSurface.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  Container(
                    color: AppColors.onSurface,
                    child: Row(
                      children: columns.map((column) {
                        final active = parsed?.field == column.key;
                        final icon = !column.sortable || onSort == null
                            ? null
                            : active && parsed?.direction == 'asc'
                                ? Icons.arrow_upward_rounded
                                : active && parsed?.direction == 'desc'
                                    ? Icons.arrow_downward_rounded
                                    : Icons.unfold_more_rounded;
                        return SizedBox(
                          width: column.width,
                          child: InkWell(
                            onTap: column.sortable && onSort != null
                                ? () => onSort!(toggleSort(sort ?? 'date_desc', column.key))
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Align(
                                alignment: column.alignment,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        column.header.toUpperCase(),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                    if (icon != null) ...[
                                      const SizedBox(width: 4),
                                      Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(empty, style: const TextStyle(color: AppColors.secondary)),
                      ),
                    )
                  else
                    ...rows.asMap().entries.map((entry) {
                      final even = entry.key.isEven;
                      return Material(
                        key: ValueKey(rowKey(entry.value)),
                        color: even ? Colors.white : const Color(0xFFF7F6FF),
                        child: InkWell(
                          onTap: onRowTap == null ? null : () => onRowTap!(entry.value),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.onSurface.withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                            child: Row(
                              children: columns
                                  .map(
                                    (column) => SizedBox(
                                      width: column.width,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 13,
                                        ),
                                        child: Align(
                                          alignment: column.alignment,
                                          child: column.cell(entry.value),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          if (showFooter)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.surfaceContainerLow,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    total == 0 ? 'No results' : 'Showing $start–$end of $total',
                    style: const TextStyle(color: AppColors.secondary, fontSize: 13),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: pageSize,
                          items: pageSizeOptions
                              .map(
                                (size) => DropdownMenuItem(
                                  value: size,
                                  child: Text('$size / page'),
                                ),
                              )
                              .toList(),
                          onChanged: onPageSizeChange == null
                              ? null
                              : (value) {
                                  if (value != null) onPageSizeChange!(value);
                                },
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: safePage.clamp(1, totalPages.clamp(1, 250)),
                          items: List.generate(
                            totalPages.clamp(1, 250),
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('Page ${index + 1}'),
                            ),
                          ),
                          onChanged: onPageChange == null
                              ? null
                              : (value) {
                                  if (value != null) onPageChange!(value);
                                },
                        ),
                      ),
                      OutlinedButton(
                        onPressed: safePage <= 1 || onPageChange == null
                            ? null
                            : () => onPageChange!(safePage - 1),
                        child: const Text('Previous'),
                      ),
                      OutlinedButton(
                        onPressed: safePage >= totalPages || onPageChange == null
                            ? null
                            : () => onPageChange!(safePage + 1),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class LedgerTypeChip extends StatelessWidget {
  final String label;

  const LedgerTypeChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (label) {
      'income' => (const Color(0xFFE8F7EF), const Color(0xFF0F9D58)),
      'transfer' => (const Color(0xFFE8F0FF), AppColors.surfaceTint),
      _ => (const Color(0xFFFFECEC), AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class LedgerCellText extends StatelessWidget {
  final String text;
  final bool muted;
  final bool strong;
  final int maxLines;

  const LedgerCellText(
    this.text, {
    super.key,
    this.muted = false,
    this.strong = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: muted ? AppColors.secondary : AppColors.onSurface,
        fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
    );
  }
}

class LedgerAmountText extends StatelessWidget {
  final int signedAmount;
  final String currency;
  final bool alwaysPositive;

  const LedgerAmountText({
    super.key,
    required this.signedAmount,
    required this.currency,
    this.alwaysPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = alwaysPositive || signedAmount > 0
        ? const Color(0xFF0F9D58)
        : signedAmount < 0
            ? AppColors.error
            : AppColors.onSurface;
    final prefix = alwaysPositive || signedAmount > 0
        ? '+'
        : signedAmount < 0
            ? '-'
            : '';
    return Text(
      '$prefix${formatMoneyCents(signedAmount.abs(), currency)}',
      textAlign: TextAlign.right,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

List<LedgerTableColumn<LedgerTransaction>> ledgerTransactionColumns() {
  return [
    LedgerTableColumn(
      key: 'date',
      header: 'Date',
      sortable: true,
      width: 120,
      cell: (row) => LedgerCellText(row.date, muted: true),
    ),
    LedgerTableColumn(
      key: 'type',
      header: 'Type',
      sortable: true,
      width: 110,
      cell: (row) => LedgerTypeChip(label: row.txType),
    ),
    LedgerTableColumn(
      key: 'title',
      header: 'Description',
      sortable: true,
      width: 240,
      cell: (row) {
        final notes = cleanImportNotes(row.notes);
        final secondary = notes.isNotEmpty
            ? notes
            : (row.merchantOriginal?.trim().isNotEmpty ?? false)
                ? row.merchantOriginal!
                : 'Open for details';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LedgerCellText(row.title, strong: true),
            const SizedBox(height: 2),
            LedgerCellText(secondary, muted: true),
          ],
        );
      },
    ),
    LedgerTableColumn(
      key: 'account',
      header: 'From / To',
      sortable: true,
      width: 180,
      cell: (row) => LedgerCellText(
        [
          row.accountName ?? '',
          if ((row.counterpartyAccountName ?? '').isNotEmpty) row.counterpartyAccountName!,
        ].where((value) => value.isNotEmpty).join(' → '),
        muted: true,
      ),
    ),
    LedgerTableColumn(
      key: 'category',
      header: 'Category',
      sortable: true,
      width: 140,
      cell: (row) => LedgerCellText(row.categoryName ?? '—', muted: true),
    ),
    LedgerTableColumn(
      key: 'amount',
      header: 'Amount',
      sortable: true,
      width: 140,
      alignment: Alignment.centerRight,
      cell: (row) => LedgerAmountText(
        signedAmount: row.signedAmount,
        currency: row.currency,
      ),
    ),
  ];
}

List<LedgerTableColumn<Income>> incomeTableColumns({
  required Map<String, String> accountNames,
  Future<void> Function(Income income)? onDelete,
}) {
  return [
    LedgerTableColumn(
      key: 'date',
      header: 'Date',
      sortable: true,
      width: 120,
      cell: (row) => LedgerCellText(row.date, muted: true),
    ),
    LedgerTableColumn(
      key: 'title',
      header: 'Source',
      sortable: true,
      width: 180,
      cell: (row) => LedgerCellText(row.source, strong: true),
    ),
    LedgerTableColumn(
      key: 'account',
      header: 'Account',
      width: 160,
      cell: (row) => LedgerCellText(
        accountNames[row.accountId] ?? 'External',
        muted: true,
      ),
    ),
    LedgerTableColumn(
      key: 'notes',
      header: 'Notes',
      width: 200,
      cell: (row) => LedgerCellText(
        (row.notes ?? '').trim().isEmpty ? '—' : row.notes!,
        muted: true,
      ),
    ),
    LedgerTableColumn(
      key: 'amount',
      header: 'Amount',
      sortable: true,
      width: 140,
      alignment: Alignment.centerRight,
      cell: (row) => LedgerAmountText(
        signedAmount: row.amount,
        currency: row.currency,
        alwaysPositive: true,
      ),
    ),
    if (onDelete != null)
      LedgerTableColumn(
        key: 'actions',
        header: '',
        width: 56,
        alignment: Alignment.centerRight,
        cell: (row) => IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onDelete(row),
          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.secondary),
        ),
      ),
  ];
}

List<LedgerTableColumn<Transfer>> transferTableColumns({
  required Map<String, String> accountNames,
  Future<void> Function(Transfer transfer)? onDelete,
}) {
  return [
    LedgerTableColumn(
      key: 'date',
      header: 'Date',
      sortable: true,
      width: 120,
      cell: (row) => LedgerCellText(row.date, muted: true),
    ),
    LedgerTableColumn(
      key: 'from',
      header: 'From',
      width: 150,
      cell: (row) => LedgerCellText(accountNames[row.fromAccountId] ?? 'External'),
    ),
    LedgerTableColumn(
      key: 'to',
      header: 'To',
      width: 150,
      cell: (row) => LedgerCellText(accountNames[row.toAccountId] ?? 'External'),
    ),
    LedgerTableColumn(
      key: 'title',
      header: 'Type',
      sortable: true,
      width: 140,
      cell: (row) => LedgerCellText(row.kind ?? 'Transfer', muted: true),
    ),
    LedgerTableColumn(
      key: 'notes',
      header: 'Notes',
      width: 200,
      cell: (row) => LedgerCellText(
        (row.notes ?? '').trim().isEmpty ? '—' : row.notes!,
        muted: true,
      ),
    ),
    LedgerTableColumn(
      key: 'amount',
      header: 'Amount',
      sortable: true,
      width: 140,
      alignment: Alignment.centerRight,
      cell: (row) => Text(
        formatMoneyCents(row.amount, row.currency),
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
    if (onDelete != null)
      LedgerTableColumn(
        key: 'actions',
        header: '',
        width: 56,
        alignment: Alignment.centerRight,
        cell: (row) => IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onDelete(row),
          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.secondary),
        ),
      ),
  ];
}
