import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../currency_format.dart';
import '../providers/data_providers.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 16),
          Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),

          // Avatar + name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  backgroundImage: profile.value?.avatarUrl != null
                      ? NetworkImage(profile.value!.avatarUrl!)
                      : null,
                  child: profile.value?.avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: AppColors.secondary)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.value?.fullName ?? 'User',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  SupabaseService.client.auth.currentUser?.email ?? '',
                  style: const TextStyle(color: AppColors.secondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings
          _SettingsTile(
            icon: Icons.currency_exchange,
            title: 'Default Currency',
            subtitle: profile.value?.defaultCurrency ?? kDefaultCurrency,
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.edit,
            title: 'Edit Name',
            subtitle: profile.value?.fullName ?? 'Tap to set',
            onTap: () => _showNameEditor(context, ref),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Lyari v1.0.0',
            onTap: () => context.push('/help'),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await SupabaseService.signOut();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          'JPY', 'USD', 'EUR', 'GBP', 'INR', 'CAD', 'AUD', 'CHF',
          'CNY', 'SGD', 'AED', 'NZD', 'SEK', 'NOK', 'MXN', 'BRL', 'ZAR',
        ].map((c) {
          return ListTile(
            title: Text(c),
            onTap: () async {
              await SupabaseService.updateProfile(currency: c);
              ref.invalidate(profileProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showNameEditor(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(profileProvider).value?.fullName ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Your name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.updateProfile(
                fullName: controller.text.trim(),
              );
              ref.invalidate(profileProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.onSurfaceVariant, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }
}
