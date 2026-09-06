import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_intro.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  String get groupId => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(groupId));
    final expenses = ref.watch(groupExpensesProvider(groupId));
    final members = ref.watch(groupMembersProvider(groupId));
    final memberList = members.value ?? const <GroupMember>[];
    final userId = ApiService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => _showInviteDialog(context),
            icon: const Icon(Icons.person_add, size: 20),
            tooltip: 'Invite member',
          ),
          TextButton.icon(
            onPressed: () => _showSettleDialog(context, ref),
            icon: const Icon(Icons.handshake, size: 18),
            label: const Text('Settle'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-expense?groupId=$groupId'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupProvider(groupId));
            ref.invalidate(groupExpensesProvider(groupId));
            ref.invalidate(groupMembersProvider(groupId));
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
            const SizedBox(height: 16),
            groupAsync.when(
              data: (group) => PageIntro(
                eyebrow: group.type,
                title: group.name,
                subtitle: 'Review members, shared expenses, balances, and settlements for this group.',
                icon: Icons.group_work_rounded,
              ),
              loading: () => const PageIntro(
                eyebrow: 'Group',
                title: 'Group',
                subtitle: 'Loading group details and shared activity.',
                icon: Icons.group_work_rounded,
              ),
              error: (_, _) => const PageIntro(
                eyebrow: 'Group',
                title: 'Group',
                subtitle: 'Shared balances, members, and expenses for this workspace.',
                icon: Icons.group_work_rounded,
              ),
            ),
            const SizedBox(height: 20),

            // Members (vertical list: name + email so everyone is visible)
            members.when(
              data: (list) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members (${list.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextButton.icon(
                        onPressed: () => _showInviteDialog(context),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Invite'),
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Anyone can be in several groups—this list is everyone in this group.',
                    style: TextStyle(color: AppColors.secondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final name = m.userId == userId
                          ? 'You'
                          : (m.profile?.fullName?.trim().isNotEmpty == true
                              ? m.profile!.fullName!
                              : 'Member');
                      final email = m.profile?.email?.trim();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          backgroundImage: m.profile?.avatarUrl != null
                              ? NetworkImage(m.profile!.avatarUrl!)
                              : null,
                          child: m.profile?.avatarUrl == null
                              ? Text(
                                  (name.isNotEmpty ? name : '?')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          email ?? 'Email not on profile',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.secondary),
                        ),
                        trailing: m.role == 'admin'
                            ? const Chip(
                                label: Text('Admin', style: TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Could not load members',
                    style: TextStyle(color: AppColors.secondary)),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Expenses',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontSize: 18),
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
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 40, color: AppColors.secondary),
                          SizedBox(height: 8),
                          Text(
                            'No expenses yet',
                            style: TextStyle(color: AppColors.secondary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap the + button to add one',
                            style: TextStyle(
                                color: AppColors.secondary, fontSize: 12),
                          ),
                        ],
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
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _showEditGroupExpenseSheet(context, e, memberList);
                              } else if (value == 'delete') {
                                await _deleteGroupExpense(context, e);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
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
      ),
    );
  }

  Future<void> _deleteGroupExpense(BuildContext context, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.title}" from this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiService.deleteExpense(expense.id);
    ref.invalidate(groupExpensesProvider(groupId));
    ref.invalidate(groupProvider(groupId));
  }

  Future<void> _showEditGroupExpenseSheet(
    BuildContext context,
    Expense expense,
    List<GroupMember> members,
  ) {
    final titleController = TextEditingController(text: expense.title);
    final amountController = TextEditingController(
      text: (expense.amount / 100).toStringAsFixed(2),
    );
    final notesController = TextEditingController(text: expense.notes ?? '');
    String categoryId = expense.categoryId ?? '';
    final categories = ref.read(categoriesProvider).value ?? const <Category>[];
    final selected = <String, bool>{for (final member in members) member.userId: true};

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
          child: SafeArea(
            top: false,
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
                  Text('Edit expense', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount *',
                      prefixText: currencyInputPrefix(expense.currency),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Uncategorized')),
                      ...categories.map(
                        (category) =>
                            DropdownMenuItem(value: category.id, child: Text(category.name)),
                      ),
                    ],
                    onChanged: (value) => setSheetState(() => categoryId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Split across *',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members.map((member) {
                      final name = member.userId == ApiService.currentUserId
                          ? 'You'
                          : (member.profile?.fullName?.trim().isNotEmpty == true
                              ? member.profile!.fullName!
                              : member.profile?.email ?? 'Member');
                      final active = selected[member.userId] ?? false;
                      return FilterChip(
                        label: Text(name),
                        selected: active,
                        onSelected: (value) => setSheetState(() {
                          selected[member.userId] = value;
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final parsed = double.tryParse(amountController.text.trim());
                        final selectedMembers =
                            members.where((member) => selected[member.userId] ?? false).toList();
                        if (titleController.text.trim().isEmpty || parsed == null || parsed <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Title and amount are required.')),
                          );
                          return;
                        }
                        if (selectedMembers.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Select at least one member.')),
                          );
                          return;
                        }
                        final cents = (parsed * 100).round();
                        final perPerson = cents ~/ selectedMembers.length;
                        final remainder = cents - perPerson * selectedMembers.length;
                        final splits = selectedMembers.asMap().entries.map((entry) {
                          return {
                            'user_id': entry.value.userId,
                            'owed_amount': perPerson + (entry.key == 0 ? remainder : 0),
                            'split_type': 'equal',
                          };
                        }).toList();
                        await ApiService.updateExpense(
                          expense.id,
                          title: titleController.text.trim(),
                          amount: cents,
                          date: expense.date,
                          categoryId: categoryId,
                          notes: notesController.text.trim(),
                          splits: splits,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.invalidate(groupExpensesProvider(groupId));
                        ref.invalidate(groupProvider(groupId));
                      },
                      child: const Text('Save changes'),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Invite member by email ────────────────────────────────────────
  Future<void> _showInviteDialog(BuildContext context) async {
    final emailController = TextEditingController();
    bool loading = false;
    String? error;
    String? success;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the email of a registered user to add them to this group.',
                  style: TextStyle(color: AppColors.secondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'friend@example.com',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                if (success != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    success!,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        setDialogState(() {
                          error = 'Enter a valid email address.';
                        });
                        return;
                      }
                      setDialogState(() {
                        loading = true;
                        error = null;
                        success = null;
                      });
                      try {
                        final name =
                            await ApiService.inviteMemberByEmail(
                          groupId: groupId,
                          email: email,
                        );
                        setDialogState(() {
                          success = '$name has been added!';
                          loading = false;
                        });
                        emailController.clear();
                        ref.invalidate(groupMembersProvider(groupId));
                      } catch (e) {
                        final raw = e.toString();
                        final display = raw.replaceFirst(
                            RegExp(r'^Exception:\s*'), '');
                        setDialogState(() {
                          error = display;
                          loading = false;
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Settle up bottom sheet ────────────────────────────────────────
  Future<void> _showSettleDialog(BuildContext context, WidgetRef ref) async {
    final debts = await ApiService.getSimplifiedDebts(groupId);
    final members = ref.read(groupMembersProvider(groupId)).value ?? [];
    final userId = ApiService.currentUserId;
    final group = await ref.read(groupProvider(groupId).future);
    final currency = group.currency;

    final memberMap = {for (final m in members) m.userId: m.profile};

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
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
                      Icon(Icons.check_circle,
                          color: AppColors.onTertiaryFixedVariant, size: 40),
                      SizedBox(height: 8),
                      Text('All settled!',
                          style: TextStyle(fontWeight: FontWeight.w700)),
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
                          '$fromName \u2192 $toName',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        formatMoneyCents(txn.amount, currency),
                        style:
                            const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (txn.from == userId || txn.to == userId)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            onPressed: () async {
                              await ApiService.settleUp(
                                fromUserId: txn.from,
                                toUserId: txn.to,
                                amount: txn.amount,
                                groupId: groupId,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              ref.invalidate(
                                  groupExpensesProvider(groupId));
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
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
        ),
      ),
    );
  }
}
