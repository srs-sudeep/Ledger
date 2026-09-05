import 'package:flutter/material.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'ledger_tx_tile.dart';

Future<void> showTxDetailSheet(
  BuildContext context,
  LedgerTransaction transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TxDetailSheet(transaction: transaction),
  );
}

class TxDetailSheet extends StatelessWidget {
  final LedgerTransaction transaction;

  const TxDetailSheet({super.key, required this.transaction});

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
              ],
            ),
          ),
        ),
      ),
    );
  }
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
