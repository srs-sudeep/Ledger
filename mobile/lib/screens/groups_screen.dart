import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../currency_format.dart';
import '../providers/data_providers.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(userGroupsProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userGroupsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Groups',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All your groups—tap one for members & expenses',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showCreateGroupDialog(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            groups.when(
              data: (list) {
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.groups,
                            size: 48,
                            color:
                                AppColors.secondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No groups yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap "Create" to start a group',
                          style: TextStyle(
                              color: AppColors.secondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: list.map((item) {
                    final groupData =
                        item['groups'] as Map<String, dynamic>?;
                    if (groupData == null) return const SizedBox();
                    final memberCount = _memberCountFromGroupJson(groupData);
                    final group = Group.fromJson(groupData);

                    return GestureDetector(
                      onTap: () => context.push('/groups/${group.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
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
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _initials(group.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${group.type[0].toUpperCase()}${group.type.substring(1)} · $memberCount ${memberCount == 1 ? 'member' : 'members'} · ${group.currency}',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, _) => const Center(
                child: Text('Failed to load groups'),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  int _memberCountFromGroupJson(Map<String, dynamic> g) {
    final nested = g['group_members'];
    if (nested is List && nested.isNotEmpty) {
      final row = nested.first;
      if (row is Map && row['count'] != null) {
        return row['count'] as int;
      }
    }
    return 0;
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'custom';
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(hintText: 'Group name'),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(hintText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  DropdownMenuItem(value: 'trip', child: Text('Trip')),
                  DropdownMenuItem(value: 'home', child: Text('Home / Apartment')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedType = v);
                },
              ),
            ],
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
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      setDialogState(() => loading = true);
                      try {
                        final profile =
                            await SupabaseService.getProfile();
                        final currency =
                            profile?.defaultCurrency ?? kDefaultCurrency;
                        final group =
                            await SupabaseService.createGroup(
                          name: name,
                          type: selectedType,
                          currency: currency,
                        );
                        ref.invalidate(userGroupsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          context.push('/groups/${group.id}');
                        }
                      } catch (e) {
                        setDialogState(() => loading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
