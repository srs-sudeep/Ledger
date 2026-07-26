import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

const _accountTypes = [
  ('bank', 'Bank Account'),
  ('credit_card', 'Credit Card'),
  ('debit_card', 'Debit Card'),
  ('wallet', 'Wallet'),
  ('cash', 'Cash'),
  ('other', 'Other'),
];

const _currencies = [
  'JPY', 'USD', 'EUR', 'GBP', 'INR', 'CAD', 'AUD', 'CHF',
  'CNY', 'SGD', 'AED', 'NZD', 'SEK', 'NOK', 'MXN', 'BRL', 'ZAR',
];

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final income = ref.watch(recentIncomeProvider);
    final profile = ref.watch(profileProvider);
    final displayCurrency =
        profile.value?.defaultCurrency ?? kDefaultCurrency;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsProvider);
          ref.invalidate(recentIncomeProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),
            Text(
              'Accounts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),

            // Total balance card
            accounts.when(
              data: (accs) {
                final total = accs.fold<int>(0, (sum, a) => sum + a.balance);
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.06),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL BALANCE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatMoneyCents(total, displayCurrency),
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              fontSize: 36,
                              color: AppColors.surfaceTint,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${accs.length} account${accs.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // Account list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Accounts',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                ),
                IconButton(
                  onPressed: () => _showAddAccountDialog(context, ref),
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.surfaceTint),
                ),
              ],
            ),
            const SizedBox(height: 8),

            accounts.when(
              data: (accs) => accs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.account_balance,
                                size: 48, color: AppColors.outlineVariant),
                            const SizedBox(height: 12),
                            const Text(
                              'No accounts yet',
                              style: TextStyle(color: AppColors.secondary),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _showAddAccountDialog(context, ref),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Account'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: accs
                          .map((a) => _AccountCard(account: a, ref: ref))
                          .toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => const Center(
                child: Text('Failed to load accounts'),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Income
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Income',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () => _showAddIncomeDialog(context, ref),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            income.when(
              data: (items) => items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No income recorded yet',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    )
                  : Column(
                      children:
                          items.map((i) => _IncomeTile(income: i, ref: ref)).toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => const Center(
                child: Text('Failed to load income'),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'bank';
    String selectedCurrency = kDefaultCurrency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Account name',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(hintText: 'Type'),
                  items: _accountTypes
                      .map((t) => DropdownMenuItem(
                            value: t.$1,
                            child: Text(t.$2),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  decoration: InputDecoration(
                    hintText: 'Initial balance',
                    prefixText: currencyInputPrefix(selectedCurrency),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCurrency,
                  decoration: const InputDecoration(hintText: 'Currency'),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedCurrency = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final parsed =
                    double.tryParse(balanceController.text.trim()) ?? 0;
                final cents = (parsed * 100).round();
                await ApiService.addAccount(
                  name: name,
                  type: selectedType,
                  balance: cents,
                  currency: selectedCurrency,
                );
                ref.invalidate(accountsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context, WidgetRef ref) {
    final sourceController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Income'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sourceController,
              decoration: const InputDecoration(hintText: 'Source'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final source = sourceController.text.trim();
              final parsed = double.tryParse(amountController.text.trim()) ?? 0;
              if (source.isEmpty || parsed <= 0) return;
              await ApiService.addIncome(
                amount: (parsed * 100).round(),
                source: source,
                date: DateTime.now().toIso8601String().split('T').first,
              );
              ref.invalidate(recentIncomeProvider);
              ref.invalidate(accountsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final WidgetRef ref;
  const _AccountCard({required this.account, required this.ref});

  Color get _indicatorColor {
    if (account.color != null) {
      final hex = account.color!.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    switch (account.type) {
      case 'bank':
        return AppColors.surfaceTint;
      case 'credit_card':
        return AppColors.error;
      case 'debit_card':
        return const Color(0xFF2E7D32);
      case 'wallet':
        return AppColors.onTertiaryFixedVariant;
      case 'cash':
        return const Color(0xFF6A1B9A);
      default:
        return AppColors.secondary;
    }
  }

  IconData get _typeIcon {
    switch (account.type) {
      case 'bank':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'debit_card':
        return Icons.payment;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'cash':
        return Icons.money;
      default:
        return Icons.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _indicatorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_typeIcon, color: _indicatorColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  account.typeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                account.formattedBalance,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                account.currency,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.error,
            onPressed: () async {
              await ApiService.deleteAccount(account.id);
              ref.invalidate(accountsProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final Income income;
  final WidgetRef ref;
  const _IncomeTile({required this.income, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.arrow_downward, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.source,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  income.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${formatMoneyCents(income.amount, income.currency)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF2E7D32),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.error,
            onPressed: () async {
              await ApiService.deleteIncome(income.id);
              ref.invalidate(recentIncomeProvider);
              ref.invalidate(accountsProvider);
            },
          ),
        ],
      ),
    );
  }
}
