import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ledger_table.dart';
import '../widgets/page_intro.dart';

class TransfersListScreen extends ConsumerStatefulWidget {
  const TransfersListScreen({super.key});

  @override
  ConsumerState<TransfersListScreen> createState() => _TransfersListScreenState();
}

class _TransfersListScreenState extends ConsumerState<TransfersListScreen> {
  final _searchController = TextEditingController();
  EntryQuery _query = const EntryQuery(pageSize: 25);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(transferProvider(_query));
    final count = ref.watch(transferCountProvider(_query));
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final accountNames = {for (final account in accounts) account.id: account.name};

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transferProvider(_query));
            ref.invalidate(transferCountProvider(_query));
            ref.invalidate(accountsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              PageIntro(
              eyebrow: 'Money movement',
              title: 'Transfers',
              subtitle: 'Follow money moving between your accounts with searchable history.',
              icon: Icons.swap_horiz_rounded,
              trailing: IconButton(
                onPressed: () async {
                  await _showAddTransferSheet(context, ref);
                  ref.invalidate(transferProvider(_query));
                  ref.invalidate(transferCountProvider(_query));
                },
                icon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transfer type or notes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = _query.copyWith(search: '', page: 1));
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
              onChanged: (value) {
                setState(() => _query = _query.copyWith(search: value, page: 1));
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _query.accountId.isEmpty ? '' : _query.accountId,
              decoration: const InputDecoration(labelText: 'Account'),
              items: [
                const DropdownMenuItem(value: '', child: Text('All accounts')),
                ...accounts.map(
                  (account) => DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _query = _query.copyWith(accountId: value ?? '', page: 1));
              },
            ),
            const SizedBox(height: 16),
            LedgerTable<Transfer>(
              columns: transferTableColumns(
                accountNames: accountNames,
                onEdit: (transfer) async {
                  await _showAddTransferSheet(context, ref, initialTransfer: transfer);
                  ref.invalidate(transferProvider(_query));
                  ref.invalidate(transferCountProvider(_query));
                },
                onDelete: (transfer) async {
                  await ApiService.deleteTransfer(transfer.id);
                  ref.invalidate(transferProvider(_query));
                  ref.invalidate(transferCountProvider(_query));
                  ref.invalidate(accountsProvider);
                  ref.invalidate(dashboardSummaryProvider);
                },
              ),
              rows: rows.value ?? const [],
              rowKey: (row) => row.id,
              loading: rows.isLoading,
              empty: 'No matching transfers',
              sort: _query.sort,
              onSort: (next) => setState(() => _query = _query.copyWith(sort: next, page: 1)),
              page: _query.page,
              pageSize: _query.pageSize,
              total: count.value ?? 0,
              onPageChange: (page) => setState(() => _query = _query.copyWith(page: page)),
              onPageSizeChange: (size) =>
                  setState(() => _query = _query.copyWith(pageSize: size, page: 1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showAddTransferSheet(
  BuildContext context,
  WidgetRef ref, {
  Transfer? initialTransfer,
}) {
  final editing = initialTransfer != null;
  final amountController = TextEditingController(
    text: initialTransfer == null ? '' : (initialTransfer.amount / 100).toStringAsFixed(2),
  );
  final kindController = TextEditingController(text: initialTransfer?.kind ?? '');
  final notesController = TextEditingController(text: initialTransfer?.notes ?? '');
  final dateController = TextEditingController(
    text: initialTransfer?.date ?? DateTime.now().toIso8601String().split('T').first,
  );
  String fromAccountId = initialTransfer?.fromAccountId ?? '';
  String toAccountId = initialTransfer?.toAccountId ?? '';
  final accounts = ref.read(accountsProvider).value ?? const <Account>[];
  final currency = ref.read(profileProvider).value?.defaultCurrency ?? kDefaultCurrency;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(editing ? 'Edit transfer' : 'Add transfer',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount *',
                      prefixText: currencyInputPrefix(currency),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: fromAccountId,
                    decoration: const InputDecoration(labelText: 'From'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('External')),
                      ...accounts.map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setSheetState(() => fromAccountId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: toAccountId,
                    decoration: const InputDecoration(labelText: 'To'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('External')),
                      ...accounts.map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setSheetState(() => toAccountId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kindController,
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final parsed = double.tryParse(amountController.text.trim());
                        if (parsed == null || parsed <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Amount is required.')),
                          );
                          return;
                        }
                        if (fromAccountId.isEmpty && toAccountId.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Select a source or destination account.')),
                          );
                          return;
                        }
                        if (fromAccountId.isNotEmpty && fromAccountId == toAccountId) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Choose different source and destination accounts.')),
                          );
                          return;
                        }
                        if (editing) {
                          await ApiService.updateTransfer(
                            initialTransfer.id,
                            amount: (parsed * 100).round(),
                            date: dateController.text.trim(),
                            fromAccountId: fromAccountId,
                            toAccountId: toAccountId,
                            currency: currency,
                            kind: kindController.text.trim(),
                            notes: notesController.text.trim(),
                          );
                        } else {
                          await ApiService.addTransfer(
                            amount: (parsed * 100).round(),
                            date: dateController.text.trim(),
                            fromAccountId: fromAccountId.isEmpty ? null : fromAccountId,
                            toAccountId: toAccountId.isEmpty ? null : toAccountId,
                            currency: currency,
                            kind: kindController.text.trim().isEmpty
                                ? null
                                : kindController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );
                        }
                        ref.invalidate(accountsProvider);
                        ref.invalidate(recentTransfersProvider);
                        ref.invalidate(dashboardSummaryProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(editing ? 'Save changes' : 'Save transfer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
