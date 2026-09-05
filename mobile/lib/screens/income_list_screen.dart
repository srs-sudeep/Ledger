import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ledger_table.dart';
import '../widgets/page_intro.dart';

class IncomeListScreen extends ConsumerStatefulWidget {
  const IncomeListScreen({super.key});

  @override
  ConsumerState<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends ConsumerState<IncomeListScreen> {
  final _searchController = TextEditingController();
  EntryQuery _query = const EntryQuery(pageSize: 25);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(incomeProvider(_query));
    final count = ref.watch(incomeCountProvider(_query));
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incomeProvider(_query));
          ref.invalidate(incomeCountProvider(_query));
          ref.invalidate(accountsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            PageIntro(
              eyebrow: 'Cash in',
              title: 'Income',
              subtitle: 'Track incoming money by source, notes, account, and date.',
              icon: Icons.trending_up_rounded,
              trailing: IconButton(
                onPressed: () => _showAddIncomeSheet(context, ref),
                icon: const Icon(Icons.add),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search income source or notes',
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
            LedgerTable<Income>(
              columns: incomeTableColumns(
                accountNames: {for (final account in accounts) account.id: account.name},
                onDelete: (income) async {
                  await ApiService.deleteIncome(income.id);
                  ref.invalidate(incomeProvider(_query));
                  ref.invalidate(incomeCountProvider(_query));
                  ref.invalidate(accountsProvider);
                  ref.invalidate(dashboardSummaryProvider);
                },
              ),
              rows: rows.value ?? const [],
              rowKey: (row) => row.id,
              loading: rows.isLoading,
              empty: 'No matching income',
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
    );
  }
}

Future<void> _showAddIncomeSheet(BuildContext context, WidgetRef ref) {
  final sourceController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  String accountId = '';
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
                Text('Add income', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(labelText: 'Source'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'Amount', prefixText: currencyInputPrefix(currency)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: accountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Unassigned')),
                    ...accounts.map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => accountId = value ?? ''),
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
                      if (parsed == null || parsed <= 0 || sourceController.text.trim().isEmpty) {
                        return;
                      }
                      await ApiService.addIncome(
                        amount: (parsed * 100).round(),
                        source: sourceController.text.trim(),
                        date: DateTime.now().toIso8601String().split('T').first,
                        accountId: accountId.isEmpty ? null : accountId,
                        currency: currency,
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      );
                      ref.invalidate(accountsProvider);
                      ref.invalidate(recentIncomeProvider);
                      ref.invalidate(dashboardSummaryProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save income'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
