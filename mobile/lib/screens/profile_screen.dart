import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/auth_notifier.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final data = profile.value;
    final displayName = data?.fullName ?? 'User';
    final email = ApiService.currentEmail ?? '';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text(
            'Manage your identity, exports, and workspace preferences.',
            style: TextStyle(color: AppColors.secondary),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xF2E9F0FF), Color(0xFAFFFFFF)],
              ),
              borderRadius: BorderRadius.circular(24),
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
                const Row(
                  children: [
                    BrandLogo(size: 44),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal workspace',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ledger mobile',
                            style: TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withValues(alpha: 0.88),
                      backgroundImage:
                          data?.avatarUrl != null ? NetworkImage(data!.avatarUrl!) : null,
                      child: data?.avatarUrl == null
                          ? const Icon(Icons.person, size: 28, color: AppColors.secondary)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            email.isEmpty ? 'Signed in' : email,
                            style: const TextStyle(color: AppColors.secondary, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniStatChip(
                      icon: Icons.call_rounded,
                      label: 'Primary',
                      value: data?.phonePrimary ?? 'Not set',
                    ),
                    _MiniStatChip(
                      icon: Icons.phone_callback_rounded,
                      label: 'Secondary',
                      value: data?.phoneSecondary ?? 'Not set',
                    ),
                    _MiniStatChip(
                      icon: Icons.currency_exchange_rounded,
                      label: 'Currency',
                      value: data?.defaultCurrency ?? kDefaultCurrency,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Preferences'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.currency_exchange,
            title: 'Default Currency',
            subtitle: data?.defaultCurrency ?? kDefaultCurrency,
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.edit,
            title: 'Edit Name',
            subtitle: data?.fullName ?? 'Tap to set',
            onTap: () => _showNameEditor(context, ref),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.phone_outlined,
            title: 'Primary Phone',
            subtitle: data?.phonePrimary ?? 'Tap to set',
            onTap: () => _showPhoneEditor(context, ref, true),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.phone_callback_outlined,
            title: 'Secondary Phone',
            subtitle: data?.phoneSecondary ?? 'Tap to set',
            onTap: () => _showPhoneEditor(context, ref, false),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Tools'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.insights_outlined,
            title: 'Analytics',
            subtitle: 'Open finance charts and category breakdowns',
            onTap: () => context.push('/analytics'),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.ios_share_outlined,
            title: 'Export CSV',
            subtitle: 'Share current ledger as CSV',
            onTap: () => ApiService.exportTransactions(
              format: 'csv',
              query: const LedgerQuery(),
            ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.file_present_outlined,
            title: 'Export Excel',
            subtitle: 'Share current ledger as Excel',
            onTap: () => ApiService.exportTransactions(
              format: 'excel',
              query: const LedgerQuery(),
            ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export PDF',
            subtitle: 'Share current ledger as PDF',
            onTap: () => ApiService.exportTransactions(
              format: 'pdf',
              query: const LedgerQuery(),
            ),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Ledger v0.1.0',
            onTap: () => context.push('/help'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authNotifier.signOut();
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
              await ApiService.updateProfile(currency: c);
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
              await ApiService.updateProfile(
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

  void _showPhoneEditor(BuildContext context, WidgetRef ref, bool isPrimary) {
    final profile = ref.read(profileProvider).value;
    final controller = TextEditingController(
      text: isPrimary ? (profile?.phonePrimary ?? '') : (profile?.phoneSecondary ?? ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isPrimary ? 'Edit Primary Phone' : 'Edit Secondary Phone'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: isPrimary ? 'Primary phone number' : 'Secondary phone number',
          ),
          autofocus: true,
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.updateProfile(
                phonePrimary: isPrimary ? controller.text.trim() : null,
                phoneSecondary: isPrimary ? null : controller.text.trim(),
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.secondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
