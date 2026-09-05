import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_entry_speed_dial.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/ledger_table.dart';
import '../widgets/page_intro.dart';
import '../widgets/summary_metric.dart';
import '../widgets/tx_detail_sheet.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final String? accountId;
  final String? accountName;

  const TransactionsScreen({
    super.key,
    this.accountId,
    this.accountName,
  });

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late LedgerQuery _query;
  List<LedgerTransaction> _rows = [];
  LedgerTransactionSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query = LedgerQuery(accountId: widget.accountId ?? '');
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = _query.copyWith(search: _searchController.text.trim(), page: 1);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final results = await Future.wait([
        ApiService.getTransactions(_query),
        ApiService.getTransactionSummary(_query),
      ]);
      if (!mounted) return;
      setState(() {
        _rows = results[0] as List<LedgerTransaction>;
        _summary = results[1] as LedgerTransactionSummary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(accountsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(recentTransactionsProvider);
    ref.invalidate(dashboardSummaryProvider);
    await _load();
  }

  bool get _hasActiveFilters {
    return _query.txType.isNotEmpty ||
        _query.direction.isNotEmpty ||
        _query.categoryId.isNotEmpty ||
        _query.fromDate.isNotEmpty ||
        _query.toDate.isNotEmpty ||
        (widget.accountId == null && _query.accountId.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final currency = ref.watch(profileProvider).value?.defaultCurrency ?? 'JPY';
    final movement = (_summary?.incomeTotal ?? 0) + (_summary?.expenseTotal ?? 0);
    final inflowShare = movement == 0 ? 0 : ((_summary!.incomeTotal * 100) / movement).round();
    final outflowShare = movement == 0 ? 0 : ((_summary!.expenseTotal * 100) / movement).round();

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: const AddEntrySpeedDial(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              PageIntro(
                eyebrow: widget.accountId == null ? 'Ledger' : 'Account ledger',
                title: widget.accountId == null ? 'Ledger' : 'Account activity',
                subtitle: widget.accountName ?? 'Transactions, transfers, and income in one view.',
                icon: Icons.receipt_long_rounded,
                trailing: PopupMenuButton<String>(
                  onSelected: (format) async {
                    await ApiService.exportTransactions(format: format, query: _query);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                    PopupMenuItem(value: 'excel', child: Text('Export Excel')),
                    PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search merchant, notes, account, transfer type',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _query = _query.copyWith(search: '', page: 1);
                            _load();
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChipButton(
                    label: 'Filters',
                    icon: Icons.tune_rounded,
                    emphasized: _hasActiveFilters,
                    onTap: () {
                      showLedgerFilterSheet(
                        context: context,
                        initialQuery: _query,
                        accounts: accounts,
                        categories: categories,
                        onApply: (query) {
                          _query = query.copyWith(
                            accountId: widget.accountId ?? query.accountId,
                            page: 1,
                          );
                          _load();
                        },
                      );
                    },
                  ),
                  if (_query.accountId.isNotEmpty && widget.accountId == null)
                    _InfoChip(
                      label: accounts
                          .cast<Account?>()
                          .firstWhere(
                            (account) => account?.id == _query.accountId,
                            orElse: () => null,
                          )
                          ?.name ??
                          'Account',
                    ),
                  if (_query.txType.isNotEmpty) _InfoChip(label: _query.txType),
                  if (_query.direction.isNotEmpty) _InfoChip(label: _query.direction),
                  if (_query.categoryId.isNotEmpty)
                    _InfoChip(
                      label: categories
                          .cast<Category?>()
                          .firstWhere(
                            (e) => e?.id == _query.categoryId,
                            orElse: () => null,
                          )
                          ?.name ??
                          'Category',
                    ),
                  if (_query.fromDate.isNotEmpty) _InfoChip(label: 'From ${_query.fromDate}'),
                  if (_query.toDate.isNotEmpty) _InfoChip(label: 'To ${_query.toDate}'),
                  if (_hasActiveFilters || _searchController.text.trim().isNotEmpty)
                    _FilterChipButton(
                      label: 'Reset',
                      icon: Icons.refresh_rounded,
                      onTap: () {
                        _searchController.clear();
                        _query = LedgerQuery(accountId: widget.accountId ?? '');
                        _load();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (_summary != null)
                Column(
                  children: [
                    SummaryMetric(
                      label: 'Net flow',
                      value: _summary!.netFlow,
                      currency: currency,
                      subtitle: '${_summary!.transactionCount} transactions in this view',
                      helper: 'Net of income, expenses, and account-specific transfer effects.',
                      icon: Icons.auto_graph_rounded,
                      tone: SummaryTone.primary,
                      emphasized: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryMetric(
                            label: 'Inflow',
                            value: _summary!.incomeTotal,
                            currency: currency,
                            subtitle: '$inflowShare% of tracked movement',
                            icon: Icons.south_west_rounded,
                            tone: SummaryTone.positive,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryMetric(
                            label: 'Outflow',
                            value: _summary!.expenseTotal,
                            currency: currency,
                            subtitle: '$outflowShare% of tracked movement',
                            icon: Icons.north_east_rounded,
                            tone: SummaryTone.negative,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SummaryMetric(
                      label: 'Transfers',
                      value: _summary!.transferInTotal + _summary!.transferOutTotal,
                      currency: currency,
                      subtitle:
                          '${formatMoneyCents(_summary!.transferInTotal, currency)} in · ${formatMoneyCents(_summary!.transferOutTotal, currency)} out',
                      icon: Icons.swap_horiz_rounded,
                      tone: SummaryTone.activity,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              Text(
                _summary == null ? 'Activity' : 'Activity (${_summary!.transactionCount})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                )
              else
                LedgerTable<LedgerTransaction>(
                  columns: ledgerTransactionColumns(),
                  rows: _rows,
                  rowKey: (row) => '${row.txType}-${row.id}',
                  loading: _loading,
                  empty: 'No matching transactions',
                  sort: _query.sort,
                  onSort: (next) {
                    _query = _query.copyWith(sort: next, page: 1);
                    _load();
                  },
                  page: _query.page,
                  pageSize: _query.pageSize,
                  total: _summary?.transactionCount ?? 0,
                  onPageChange: (page) {
                    _query = _query.copyWith(page: page);
                    _load();
                  },
                  onPageSizeChange: (size) {
                    _query = _query.copyWith(pageSize: size, page: 1);
                    _load();
                  },
                  onRowTap: (tx) => showTxDetailSheet(context, tx),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasized;

  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: emphasized ? Colors.white : AppColors.onSurface),
      backgroundColor:
          emphasized ? AppColors.surfaceTint : AppColors.surfaceContainerLowest,
      label: Text(
        label,
        style: TextStyle(
          color: emphasized ? Colors.white : AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.surfaceContainerLow,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
