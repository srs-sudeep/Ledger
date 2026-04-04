import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../currency_format.dart';
import '../providers/data_providers.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

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
    final owedToMe = ref.watch(totalOwedToMeProvider);
    final iOwe = ref.watch(totalIOweProvider);
    final recentExpenses = ref.watch(recentExpensesProvider);
    final displayCurrency =
        profile.value?.defaultCurrency ?? kDefaultCurrency;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(totalOwedToMeProvider);
          ref.invalidate(totalIOweProvider);
          ref.invalidate(recentExpensesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  backgroundImage: profile.value?.avatarUrl != null
                      ? NetworkImage(profile.value!.avatarUrl!)
                      : null,
                  child: profile.value?.avatarUrl == null
                      ? const Icon(Icons.person, size: 20, color: AppColors.secondary)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  'Good morning, ${profile.value?.fullName?.split(' ').first ?? 'there'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.secondary),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Balance Card
            Container(
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
                    _formatBalance(
                      owedToMe.value ?? 0,
                      iOwe.value ?? 0,
                      displayCurrency,
                    ),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 36,
                          color: AppColors.surfaceTint,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceStat(
                          label: 'YOU OWE',
                          amount: iOwe.value ?? 0,
                          color: AppColors.error,
                          currency: displayCurrency,
                        ),
                      ),
                      Expanded(
                        child: _BalanceStat(
                          label: 'YOU ARE OWED',
                          amount: owedToMe.value ?? 0,
                          color: AppColors.onTertiaryFixedVariant,
                          currency: displayCurrency,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Toggle
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showPersonal = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showPersonal
                              ? AppColors.surfaceContainerLowest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: _showPersonal
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Personal',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _showPersonal
                                ? AppColors.onSurface
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showPersonal = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showPersonal
                              ? AppColors.surfaceContainerLowest
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: !_showPersonal
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !_showPersonal
                                ? AppColors.onSurface
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.surfaceTint,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            recentExpenses.when(
              data: (expenses) => expenses.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: AppColors.secondary),
                        ),
                      ),
                    )
                  : Column(
                      children: expenses
                          .map((e) => _TransactionTile(expense: e))
                          .toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Center(
                child: Text('Failed to load transactions'),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _formatBalance(int owedToMe, int iOwe, String currency) {
    final net = owedToMe - iOwe;
    final sign = net < 0 ? '-' : '';
    return '$sign${formatMoneyCents(net.abs(), currency)}';
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final String currency;

  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.secondary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatMoneyCents(amount, currency),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Expense expense;

  const _TransactionTile({required this.expense});

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
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _categoryIcon(expense.category?.icon),
              color: AppColors.onTertiaryFixedVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expense.category?.name ?? 'Uncategorized',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${expense.formattedAmount}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String? iconName) {
    switch (iconName) {
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'bolt':
        return Icons.bolt;
      case 'home':
        return Icons.home;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'redeem':
        return Icons.redeem;
      default:
        return Icons.receipt_long;
    }
  }
}
