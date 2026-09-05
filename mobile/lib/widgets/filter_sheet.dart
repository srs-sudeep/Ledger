import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

Future<void> showLedgerFilterSheet({
  required BuildContext context,
  required LedgerQuery initialQuery,
  required List<Account> accounts,
  required List<Category> categories,
  required ValueChanged<LedgerQuery> onApply,
}) {
  String accountId = initialQuery.accountId;
  String txType = initialQuery.txType;
  String direction = initialQuery.direction;
  String categoryId = initialQuery.categoryId;
  String fromDate = initialQuery.fromDate;
  String toDate = initialQuery.toDate;
  String sort = initialQuery.sort;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                    const SizedBox(height: 18),
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: txType.isEmpty ? '' : txType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All types')),
                        DropdownMenuItem(value: 'expense', child: Text('Expenses')),
                        DropdownMenuItem(value: 'income', child: Text('Income')),
                        DropdownMenuItem(value: 'transfer', child: Text('Transfers')),
                      ],
                      onChanged: (value) => setSheetState(() => txType = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: direction.isEmpty ? '' : direction,
                      decoration: const InputDecoration(labelText: 'Direction'),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All directions')),
                        DropdownMenuItem(value: 'inflow', child: Text('Inflow')),
                        DropdownMenuItem(value: 'outflow', child: Text('Outflow')),
                        DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => direction = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: accountId.isEmpty ? '' : accountId,
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
                      onChanged: (value) => setSheetState(() => accountId = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: categoryId.isEmpty ? '' : categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('All categories')),
                        ...categories.map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setSheetState(() => categoryId = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sort,
                      decoration: const InputDecoration(labelText: 'Sort'),
                      items: const [
                        DropdownMenuItem(value: 'date_desc', child: Text('Newest first')),
                        DropdownMenuItem(value: 'date_asc', child: Text('Oldest first')),
                        DropdownMenuItem(value: 'amount_desc', child: Text('Largest amount')),
                        DropdownMenuItem(value: 'amount_asc', child: Text('Smallest amount')),
                        DropdownMenuItem(value: 'title_asc', child: Text('Title A-Z')),
                      ],
                      onChanged: (value) => setSheetState(() => sort = value ?? 'date_desc'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: fromDate),
                      decoration: const InputDecoration(labelText: 'From date (YYYY-MM-DD)'),
                      onChanged: (value) => fromDate = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: toDate),
                      decoration: const InputDecoration(labelText: 'To date (YYYY-MM-DD)'),
                      onChanged: (value) => toDate = value,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              onApply(initialQuery.copyWith(
                                accountId: '',
                                txType: '',
                                direction: '',
                                categoryId: '',
                                fromDate: '',
                                toDate: '',
                                sort: 'date_desc',
                                page: 1,
                              ));
                              Navigator.pop(ctx);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              onApply(initialQuery.copyWith(
                                accountId: accountId,
                                txType: txType,
                                direction: direction,
                                categoryId: categoryId,
                                fromDate: fromDate.trim(),
                                toDate: toDate.trim(),
                                sort: sort,
                                page: 1,
                              ));
                              Navigator.pop(ctx);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
