import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(groupExpensesProvider(groupId));
    final members = ref.watch(groupMembersProvider(groupId));
    final userId = SupabaseService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        actions: [
          TextButton.icon(
            onPressed: () => _showSettleDialog(context, ref),
            icon: const Icon(Icons.handshake, size: 18),
            label: const Text('Settle'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupExpensesProvider(groupId));
          ref.invalidate(groupMembersProvider(groupId));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),

            // Members
            members.when(
              data: (list) => SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          backgroundImage: m.profile?.avatarUrl != null
                              ? NetworkImage(m.profile!.avatarUrl!)
                              : null,
                          child: m.profile?.avatarUrl == null
                              ? Text(
                                  (m.profile?.fullName ?? '?')[0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.userId == userId
                              ? 'You'
                              : m.profile?.fullName?.split(' ').first ?? '?',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  },
                ),
              ),
              loading: () => const SizedBox(height: 64),
              error: (_, _) => const SizedBox(),
            ),

            const SizedBox(height: 24),

            Text(
              'Expenses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),

            expenses.when(
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'No expenses yet',
                        style: TextStyle(color: AppColors.secondary),
                      ),
                    ),
                  );
                }

                return Column(
                  children: list.map((e) {
                    final isPayer = e.payerId == userId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'paid by ${isPayer ? "You" : e.payer?.fullName ?? "Someone"}',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            e.formattedAmount,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Center(
                child: Text('Failed to load expenses'),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettleDialog(BuildContext context, WidgetRef ref) async {
    final debts = await SupabaseService.getSimplifiedDebts(groupId);
    final members = ref.read(groupMembersProvider(groupId)).value ?? [];
    final userId = SupabaseService.currentUserId;

    final memberMap = {for (final m in members) m.userId: m.profile};

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settle Up',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (debts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.onTertiaryFixedVariant, size: 40),
                      SizedBox(height: 8),
                      Text('All settled!', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
            else
              ...debts.map((txn) {
                final fromName = txn.from == userId
                    ? 'You'
                    : memberMap[txn.from]?.fullName ?? 'Unknown';
                final toName = txn.to == userId
                    ? 'You'
                    : memberMap[txn.to]?.fullName ?? 'Unknown';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$fromName → $toName',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '\$${(txn.amount / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (txn.from == userId || txn.to == userId)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            onPressed: () async {
                              await SupabaseService.settleUp(
                                fromUserId: txn.from,
                                toUserId: txn.to,
                                amount: txn.amount,
                                groupId: groupId,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              ref.invalidate(groupExpensesProvider(groupId));
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('Settle'),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
