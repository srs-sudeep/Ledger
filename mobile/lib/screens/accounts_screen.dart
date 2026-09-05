import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ledger_table.dart';
import '../widgets/page_intro.dart';
import '../widgets/summary_metric.dart';

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
    final transfers = ref.watch(recentTransfersProvider);
    final dashboard = ref.watch(dashboardSummaryProvider);
    final displayCurrency = ref.watch(profileProvider).value?.defaultCurrency ?? kDefaultCurrency;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountsProvider);
          ref.invalidate(recentIncomeProvider);
          ref.invalidate(recentTransfersProvider);
          ref.invalidate(dashboardSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            PageIntro(
              eyebrow: 'Balances',
              title: 'Accounts',
              subtitle: 'Review balances, then drill into income, transfers, and account activity.',
              icon: Icons.account_balance_rounded,
              trailing: IconButton(
                onPressed: () => _showAddAccountDialog(context, ref),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.surfaceTint),
              ),
            ),
            const SizedBox(height: 16),
            dashboard.when(
              data: (summary) => Column(
                children: [
                  SummaryMetric(
                    label: 'Net worth',
                    value: summary.netWorth,
                    currency: displayCurrency,
                    subtitle: summary.assetTotal > 0
                        ? 'Assets minus liabilities'
                        : 'Track your balances',
                    icon: Icons.account_balance_wallet_rounded,
                    tone: SummaryTone.primary,
                    emphasized: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryMetric(
                          label: 'Assets',
                          value: summary.assetTotal,
                          currency: displayCurrency,
                          subtitle: 'Positive balances across cash, bank, and wallet accounts',
                          icon: Icons.savings_outlined,
                          tone: SummaryTone.positive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryMetric(
                          label: 'Liabilities',
                          value: summary.liabilityTotal.abs(),
                          currency: displayCurrency,
                          subtitle: 'Outstanding credit-card balances',
                          icon: Icons.credit_card_rounded,
                          tone: SummaryTone.negative,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Tracked accounts',
              actionLabel: 'Add',
              onTap: () => _showAddAccountDialog(context, ref),
            ),
            const SizedBox(height: 10),
            accounts.when(
              data: (accs) => accs.isEmpty
                  ? const _EmptyBox(label: 'No accounts yet')
                  : Column(
                      children: accs
                          .map(
                            (account) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AccountCard(account: account, ref: ref),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Income',
              actionLabel: 'See all',
              onTap: () => context.push('/income'),
            ),
            const SizedBox(height: 10),
            income.when(
              data: (items) => LedgerTable<Income>(
                columns: incomeTableColumns(
                  accountNames: {
                    for (final account in accounts.value ?? const <Account>[]) account.id: account.name,
                  },
                ),
                rows: items,
                rowKey: (row) => row.id,
                empty: 'No income recorded yet',
                showFooter: false,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Transfers',
              actionLabel: 'See all',
              onTap: () => context.push('/transfers'),
            ),
            const SizedBox(height: 10),
            transfers.when(
              data: (items) => LedgerTable<Transfer>(
                columns: transferTableColumns(
                  accountNames: {
                    for (final account in accounts.value ?? const <Account>[]) account.id: account.name,
                  },
                ),
                rows: items,
                rowKey: (row) => row.id,
                empty: 'No transfers recorded yet',
                showFooter: false,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final colorController = TextEditingController();
    String selectedType = 'bank';
    String selectedCurrency = kDefaultCurrency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Account name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(hintText: 'Type'),
                  items: _accountTypes
                      .map((row) => DropdownMenuItem(value: row.$1, child: Text(row.$2)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Opening balance',
                    prefixText: currencyInputPrefix(selectedCurrency),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCurrency,
                  decoration: const InputDecoration(hintText: 'Currency'),
                  items: _currencies
                      .map((currency) => DropdownMenuItem(value: currency, child: Text(currency)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedCurrency = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: colorController,
                  decoration: const InputDecoration(hintText: 'Accent color (#0053DB)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final parsed = double.tryParse(balanceController.text.trim()) ?? 0;
                await ApiService.addAccount(
                  name: name,
                  type: selectedType,
                  balance: (parsed * 100).round(),
                  currency: selectedCurrency,
                  color: colorController.text.trim().isEmpty ? null : colorController.text.trim(),
                );
                ref.invalidate(accountsProvider);
                ref.invalidate(dashboardSummaryProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push('/accounts/${account.id}?name=${Uri.encodeComponent(account.name)}'),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: account.balance < 0
                  ? const [Color(0xF2FFECEC), Color(0xFAFFFFFF)]
                  : const [Color(0xF2F2F3FF), Color(0xFAFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _indicatorColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_typeIcon, color: _indicatorColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${account.typeLabel} • Tap to open ledger',
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    account.formattedBalance,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: account.balance < 0 ? AppColors.error : AppColors.onSurface,
                    ),
                  ),
                  Text(
                    account.currency,
                    style: const TextStyle(color: AppColors.secondary, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                onPressed: () async {
                  await ApiService.deleteAccount(account.id);
                  ref.invalidate(accountsProvider);
                  ref.invalidate(dashboardSummaryProvider);
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String label;

  const _EmptyBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.secondary)),
    );
  }
}
