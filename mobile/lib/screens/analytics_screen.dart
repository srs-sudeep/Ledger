import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/page_intro.dart';
import '../widgets/summary_metric.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final ledgerSummary = ref.watch(
      transactionSummaryProvider(const LedgerQuery(pageSize: 25)),
    );
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(
      transactionsProvider(const LedgerQuery(pageSize: 500)),
    );
    final currency = ref.watch(profileProvider).value?.defaultCurrency ?? 'JPY';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsProvider);
          ref.invalidate(accountsProvider);
          ref.invalidate(transactionSummaryProvider(const LedgerQuery(pageSize: 25)));
          ref.invalidate(transactionsProvider(const LedgerQuery(pageSize: 500)));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const PageIntro(
              eyebrow: 'Breakdowns',
              title: 'Analytics',
              subtitle: 'See what is driving personal spend, shared costs, account usage, and transfer flow.',
              icon: Icons.insights_rounded,
            ),
            const SizedBox(height: 18),
            ledgerSummary.when(
              data: (summary) => Column(
                children: [
                  SummaryMetric(
                    label: 'Personal spend',
                    value: analytics.value?.personalTotal ?? 0,
                    currency: currency,
                    subtitle: 'Last 6 months',
                    icon: Icons.wallet_rounded,
                    tone: SummaryTone.primary,
                    emphasized: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryMetric(
                          label: 'Group spend',
                          value: analytics.value?.groupTotal ?? 0,
                          currency: currency,
                          subtitle: 'Last 6 months',
                          icon: Icons.pie_chart_outline_rounded,
                          tone: SummaryTone.neutral,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryMetric(
                          label: 'Ledger inflow',
                          value: summary.incomeTotal,
                          currency: currency,
                          subtitle: 'Across the current ledger history',
                          icon: Icons.south_west_rounded,
                          tone: SummaryTone.positive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SummaryMetric(
                    label: 'Transfer volume',
                    value: summary.transferInTotal + summary.transferOutTotal,
                    currency: currency,
                    icon: Icons.swap_horiz_rounded,
                    tone: SummaryTone.activity,
                    subtitle: 'Internal movement tracked separately from spend',
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 20),
            analytics.when(
              data: (data) {
                final summary = ledgerSummary.value;
                final flowSections = [
                  _PiePart('Income', summary?.incomeTotal ?? 0, const Color(0xFF0F9D58)),
                  _PiePart('Expenses', summary?.expenseTotal ?? 0, AppColors.error),
                  _PiePart(
                    'Transfers',
                    (summary?.transferInTotal ?? 0) + (summary?.transferOutTotal ?? 0),
                    AppColors.surfaceTint,
                  ),
                ].where((e) => e.value > 0).toList();
                final spendByAccount = _computeSpendByAccount(
                  accounts.value ?? const [],
                  transactions.value ?? const [],
                );
                return Column(
                  children: [
                    _ChartCard(
                      title: 'Flow mix',
                      subtitle: 'Income, expenses, and transfers in this ledger',
                      child: SizedBox(
                        height: 220,
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  centerSpaceRadius: 42,
                                  sectionsSpace: 2,
                                  sections: flowSections
                                      .map(
                                        (part) => PieChartSectionData(
                                          value: part.value.toDouble(),
                                          color: part.color,
                                          title: '',
                                          radius: 28,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: flowSections
                                    .map((part) => _LegendRow(part: part, currency: currency))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: 'Spend by category',
                      subtitle: 'Top personal categories',
                      child: Column(
                        children: data.byCategory.take(6).map((row) {
                          final max = data.byCategory.isEmpty
                              ? 1
                              : data.byCategory.first.total;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
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
                                    minHeight: 9,
                                    value: max == 0 ? 0 : row.total / max,
                                    backgroundColor: AppColors.surfaceContainerLow,
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppColors.surfaceTint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: 'Spend by account',
                      subtitle: 'Which accounts carry the most expense volume',
                      child: SizedBox(
                        height: 220,
                        child: spendByAccount.isEmpty
                            ? const Center(
                                child: Text(
                                  'No account spend data',
                                  style: TextStyle(color: AppColors.secondary),
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= spendByAccount.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              spendByAccount[index].label,
                                              style: const TextStyle(
                                                color: AppColors.secondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: [
                                    for (var i = 0; i < spendByAccount.length; i++)
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: spendByAccount[i].value / 100,
                                            width: 20,
                                            borderRadius: BorderRadius.circular(8),
                                            color: AppColors.surfaceTint,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: 'Top merchants',
                      subtitle: 'Most frequent spending labels in the current ledger',
                      child: Column(
                        children: (summary?.topMerchants ?? [])
                            .take(8)
                            .map(
                              (merchant) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(merchant.name)),
                                    Text(
                                      formatMoneyCents(merchant.total, currency),
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.secondary)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PiePart {
  final String label;
  final int value;
  final Color color;

  _PiePart(this.label, this.value, this.color);
}

class _LegendRow extends StatelessWidget {
  final _PiePart part;
  final String currency;

  const _LegendRow({required this.part, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: part.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(part.label)),
          Text(
            formatMoneyCents(part.value, currency),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AccountBarValue {
  final String label;
  final int value;

  _AccountBarValue(this.label, this.value);
}

List<_AccountBarValue> _computeSpendByAccount(
  List<Account> accounts,
  List<LedgerTransaction> transactions,
) {
  final totals = <String, int>{};
  for (final tx in transactions) {
    if (tx.txType != 'expense' || tx.accountId == null) continue;
    totals.update(tx.accountId!, (value) => value + tx.amount, ifAbsent: () => tx.amount);
  }
  final named = totals.entries.map((entry) {
    final accountName = accounts
            .where((account) => account.id == entry.key)
            .map((account) => account.name)
            .cast<String?>()
            .firstWhere((name) => name != null, orElse: () => 'Account') ??
        'Account';
    return _AccountBarValue(accountName, entry.value);
  }).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return named.take(6).toList();
}
