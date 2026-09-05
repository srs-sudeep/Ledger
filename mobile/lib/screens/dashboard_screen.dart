import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/add_entry_speed_dial.dart';
import '../widgets/ledger_table.dart';
import '../widgets/page_intro.dart';
import '../widgets/summary_metric.dart';
import '../widgets/tx_detail_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _showPersonal = true;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final summary = ref.watch(dashboardSummaryProvider);
    final recentTransactions = ref.watch(recentTransactionsProvider);
    final ledgerSummary = ref.watch(
      transactionSummaryProvider(const LedgerQuery(pageSize: 8)),
    );
    final currency = profile.value?.defaultCurrency ?? kDefaultCurrency;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: const AddEntrySpeedDial(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileProvider);
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(recentTransactionsProvider);
            ref.invalidate(transactionSummaryProvider(const LedgerQuery(pageSize: 8)));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              PageIntro(
                eyebrow: 'Overview',
                title: 'Home',
                subtitle: 'Good morning, ${profile.value?.fullName?.split(' ').first ?? 'there'}. Track balances, spend, and shared obligations.',
                icon: Icons.home_rounded,
                trailing: IconButton(
                  onPressed: () => context.push('/analytics'),
                  icon: const Icon(Icons.insights_outlined),
                ),
              ),
              const SizedBox(height: 18),
              summary.when(
                data: (data) => Column(
                  children: [
                    SummaryMetric(
                      label: 'Net worth',
                      value: data.netWorth,
                      currency: currency,
                      subtitle:
                          '${formatMoneyCents(data.assetTotal, currency)} assets against ${formatMoneyCents(data.liabilityTotal, currency)} liabilities',
                      icon: Icons.wallet_rounded,
                      tone: SummaryTone.primary,
                      emphasized: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryMetric(
                            label: 'Assets',
                            value: data.assetTotal,
                            currency: currency,
                            subtitle: 'Positive balances across bank, wallet, and cash accounts',
                            icon: Icons.savings_outlined,
                            tone: SummaryTone.positive,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryMetric(
                            label: 'Liabilities',
                            value: data.liabilityTotal.abs(),
                            currency: currency,
                            subtitle: 'Outstanding card balances still to be paid',
                            icon: Icons.credit_card_rounded,
                            tone: SummaryTone.negative,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SummaryMetric(
                      label: 'This month spend',
                      value: data.monthlySpend,
                      currency: currency,
                      subtitle: 'Group net ${formatMoneyCents(data.groupNet, currency)}',
                      icon: Icons.calendar_month_outlined,
                      tone: SummaryTone.activity,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryMetric(
                            label: 'You owe',
                            value: data.iOwe,
                            currency: currency,
                            icon: Icons.call_made_rounded,
                            tone: SummaryTone.negative,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryMetric(
                            label: 'You are owed',
                            value: data.owedToMe,
                            currency: currency,
                            icon: Icons.call_received_rounded,
                            tone: SummaryTone.positive,
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TogglePill(
                        label: 'Personal',
                        selected: _showPersonal,
                        onTap: () => setState(() => _showPersonal = true),
                      ),
                    ),
                    Expanded(
                      child: _TogglePill(
                        label: 'Groups',
                        selected: !_showPersonal,
                        onTap: () => setState(() => _showPersonal = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  TextButton(
                    onPressed: () => context.push('/transactions'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              recentTransactions.when(
                data: (rows) {
                  final filtered = _showPersonal
                      ? rows.where((row) => row.txType != 'transfer').toList()
                      : rows.where((row) => row.txType == 'transfer').toList();
                  return LedgerTable<LedgerTransaction>(
                    columns: ledgerTransactionColumns(),
                    rows: filtered,
                    rowKey: (row) => '${row.txType}-${row.id}',
                    empty: 'No activity yet',
                    showFooter: false,
                    onRowTap: (row) => showTxDetailSheet(context, row),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 20),
              ledgerSummary.when(
                data: (stats) => Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Top categories',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/analytics'),
                            child: const Text('Analytics'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...stats.topCategories.take(3).map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(row.categoryName)),
                                      Text(
                                        formatMoneyCents(row.total, currency),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      minHeight: 8,
                                      value: stats.topCategories.isEmpty
                                          ? 0
                                          : row.total /
                                              stats.topCategories.first.total.clamp(1, 1 << 30),
                                      backgroundColor: AppColors.surfaceContainerLow,
                                      valueColor: const AlwaysStoppedAnimation(
                                        AppColors.surfaceTint,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.onSurface : AppColors.secondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
