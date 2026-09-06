import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'ledger_tx_tile.dart';

Future<void> showTxDetailSheet(
  BuildContext context,
  WidgetRef ref,
  LedgerTransaction transaction,
  {Future<void> Function()? onChanged}
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => TxDetailSheet(
      parentContext: context,
      ref: ref,
      transaction: transaction,
      onChanged: onChanged,
    ),
  );
}

class TxDetailSheet extends StatelessWidget {
  final BuildContext parentContext;
  final WidgetRef ref;
  final LedgerTransaction transaction;
  final Future<void> Function()? onChanged;

  const TxDetailSheet({
    super.key,
    required this.parentContext,
    required this.ref,
    required this.transaction,
    this.onChanged,
  });

  bool get _canEdit => transaction.txType == 'expense' || transaction.txType == 'income' || transaction.txType == 'transfer';

  @override
  Widget build(BuildContext context) {
    final notes = cleanImportNotes(transaction.notes);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  transaction.txType.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  transaction.formattedSignedAmount,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        color: transaction.signedAmount > 0
                            ? const Color(0xFF0F9D58)
                            : transaction.signedAmount < 0
                                ? AppColors.error
                                : AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                _DetailCard(
                  children: [
                    _DetailRow(label: 'Date', value: transaction.date),
                    _DetailRow(label: 'Account', value: transaction.accountName ?? 'External'),
                    _DetailRow(
                      label: 'Counterparty',
                      value: transaction.counterpartyAccountName ?? 'None',
                    ),
                    _DetailRow(label: 'Direction', value: transaction.direction),
                    _DetailRow(label: 'Category', value: transaction.categoryName ?? 'None'),
                    _DetailRow(
                      label: 'Display label',
                      value: transaction.merchantDisplay ?? 'None',
                    ),
                    _DetailRow(
                      label: 'Original label',
                      value: transaction.merchantOriginal ?? 'None',
                    ),
                    _DetailRow(
                      label: 'Amount',
                      value: formatMoneyCents(transaction.amount, transaction.currency),
                    ),
                    _DetailRow(label: 'Notes', value: notes.isEmpty ? 'None' : notes),
                  ],
                ),
                if (_canEdit) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await showEditTransactionSheet(
                              parentContext,
                              ref,
                              transaction,
                              onChanged: onChanged,
                            );
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context),
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error, width: 1.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('This will permanently remove "${transaction.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    switch (transaction.txType) {
      case 'income':
        await ApiService.deleteIncome(transaction.id);
        break;
      case 'transfer':
        await ApiService.deleteTransfer(transaction.id);
        break;
      default:
        await ApiService.deleteExpense(transaction.id);
        break;
    }
    _refreshAfterMutation(ref);
    if (onChanged != null) await onChanged!();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    if (parentContext.mounted) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
    }
  }
}

Future<void> showEditTransactionSheet(
  BuildContext context,
  WidgetRef ref,
  LedgerTransaction transaction, {
  Future<void> Function()? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EditTransactionSheet(
      parentContext: context,
      ref: ref,
      transaction: transaction,
      onChanged: onChanged,
    ),
  );
}

class _EditTransactionSheet extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  final WidgetRef ref;
  final LedgerTransaction transaction;
  final Future<void> Function()? onChanged;

  const _EditTransactionSheet({
    required this.parentContext,
    required this.ref,
    required this.transaction,
    this.onChanged,
  });

  @override
  ConsumerState<_EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<_EditTransactionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late final TextEditingController _notesController;
  String _accountId = '';
  String _categoryId = '';
  String _fromAccountId = '';
  String _toAccountId = '';
  bool _saving = false;

  LedgerTransaction get transaction => widget.transaction;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: transaction.txType == 'income'
          ? transaction.merchantDisplay ?? transaction.title
          : transaction.title,
    );
    _amountController = TextEditingController(
      text: (transaction.amount / 100).toStringAsFixed(2),
    );
    _dateController = TextEditingController(text: transaction.date);
    _notesController = TextEditingController(text: cleanImportNotes(transaction.notes));
    _accountId = transaction.accountId ?? '';
    _categoryId = transaction.categoryId ?? '';
    _fromAccountId = transaction.accountId ?? '';
    _toAccountId = transaction.counterpartyAccountId ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    return Container(
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
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Edit ${transaction.txType}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: transaction.txType == 'income'
                      ? 'Source'
                      : transaction.txType == 'transfer'
                          ? 'Type'
                          : 'Title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: currencyInputPrefix(transaction.currency),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
              if (transaction.txType == 'expense') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Unassigned')),
                    ...accounts.map(
                      (account) => DropdownMenuItem(value: account.id, child: Text(account.name)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _accountId = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Uncategorized')),
                    ...categories.map(
                      (category) =>
                          DropdownMenuItem(value: category.id, child: Text(category.name)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value ?? ''),
                ),
              ],
              if (transaction.txType == 'income') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Unassigned')),
                    ...accounts.map(
                      (account) => DropdownMenuItem(value: account.id, child: Text(account.name)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _accountId = value ?? ''),
                ),
              ],
              if (transaction.txType == 'transfer') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _fromAccountId,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('External')),
                    ...accounts.map(
                      (account) => DropdownMenuItem(value: account.id, child: Text(account.name)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _fromAccountId = value ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _toAccountId,
                  decoration: const InputDecoration(labelText: 'To'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('External')),
                    ...accounts.map(
                      (account) => DropdownMenuItem(value: account.id, child: Text(account.name)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _toAccountId = value ?? ''),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save changes'),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) return;
    if (transaction.txType != 'transfer' && _titleController.text.trim().isEmpty) return;

    setState(() => _saving = true);
    try {
      switch (transaction.txType) {
        case 'income':
          await ApiService.updateIncome(
            transaction.id,
            amount: (parsed * 100).round(),
            source: _titleController.text.trim(),
            date: _dateController.text.trim(),
            accountId: _accountId,
            currency: transaction.currency,
            notes: _notesController.text.trim().isEmpty ? '' : _notesController.text.trim(),
          );
          break;
        case 'transfer':
          await ApiService.updateTransfer(
            transaction.id,
            amount: (parsed * 100).round(),
            date: _dateController.text.trim(),
            fromAccountId: _fromAccountId,
            toAccountId: _toAccountId,
            currency: transaction.currency,
            kind: _titleController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? '' : _notesController.text.trim(),
          );
          break;
        default:
          await ApiService.updateExpense(
            transaction.id,
            title: _titleController.text.trim(),
            amount: (parsed * 100).round(),
            date: _dateController.text.trim(),
            categoryId: _categoryId,
            accountId: _accountId,
            notes: _notesController.text.trim().isEmpty ? '' : _notesController.text.trim(),
          );
          break;
      }

      _refreshAfterMutation(widget.ref);
      if (widget.onChanged != null) await widget.onChanged!();
      if (mounted) {
        Navigator.of(context).pop();
      }
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(content: Text('Entry updated')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

void _refreshAfterMutation(WidgetRef ref) {
  ref.invalidate(accountsProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(recentIncomeProvider);
  ref.invalidate(recentTransfersProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(analyticsProvider);
  ref.invalidate(transactionSummaryProvider(const LedgerQuery(pageSize: 8)));
  ref.invalidate(transactionSummaryProvider(const LedgerQuery(pageSize: 25)));
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
