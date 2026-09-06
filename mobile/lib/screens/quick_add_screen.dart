import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_intro.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  final String? initialSource;

  const QuickAddScreen({super.key, this.initialSource});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  static const _presets = <_QuickAddPreset>[
    _QuickAddPreset(
      id: 'credit_card',
      label: 'Credit Card',
      icon: Icons.credit_card_rounded,
      keywords: ['amex', 'credit', 'card', 'paypay card', 'wallet'],
      accountTypes: ['credit_card', 'debit_card', 'wallet'],
    ),
    _QuickAddPreset(
      id: 'suica',
      label: 'Suica',
      icon: Icons.train_rounded,
      keywords: ['suica', 'ic'],
      accountTypes: ['wallet'],
    ),
    _QuickAddPreset(
      id: 'paypay_qr',
      label: 'PayPay QR',
      icon: Icons.qr_code_rounded,
      keywords: ['paypay', 'qr'],
      accountTypes: ['wallet'],
    ),
    _QuickAddPreset(
      id: 'cash',
      label: 'Cash',
      icon: Icons.payments_outlined,
      keywords: ['cash'],
      accountTypes: ['cash'],
    ),
  ];

  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _amountFocusNode = FocusNode();
  String _selectedPresetId = 'credit_card';
  String _selectedCategoryId = '';
  String _selectedAccountId = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedPresetId = _normalizePreset(widget.initialSource);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final currency = ref.watch(profileProvider).value?.defaultCurrency ?? kDefaultCurrency;
    final preset = _presets.firstWhere((item) => item.id == _selectedPresetId);
    final matchedAccountId = _matchAccountForPreset(accounts, preset);

    if (_selectedAccountId.isEmpty && matchedAccountId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedAccountId.isEmpty) {
          setState(() => _selectedAccountId = matchedAccountId);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          children: [
            PageIntro(
              eyebrow: 'Fast capture',
              title: 'Quick Add',
              subtitle: 'Save a payment in a few taps, then jump back into the full app whenever you want.',
              icon: Icons.bolt_rounded,
              trailing: OutlinedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open app'),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presets.map((item) {
                final selected = item.id == _selectedPresetId;
                return _PresetChip(
                  preset: item,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedPresetId = item.id;
                      _selectedAccountId = _matchAccountForPreset(accounts, item);
                    });
                    _amountFocusNode.requestFocus();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.16)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(preset.icon, color: AppColors.primaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment source',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preset.label,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Amount *',
                      prefixText: currencyInputPrefix(currency),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('No category')),
                      ...categories.map(
                        (category) =>
                            DropdownMenuItem(value: category.id, child: Text(category.name)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedCategoryId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAccountId,
                    decoration: const InputDecoration(labelText: 'Account / card'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('No account')),
                      ...accounts.map(
                        (account) =>
                            DropdownMenuItem(value: account.id, child: Text(account.name)),
                      ),
                    ],
                    onChanged: (value) => setState(() => _selectedAccountId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _memoController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Memo',
                      hintText: '${preset.label} payment',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : () => _saveQuickExpense(preset, currency),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(_saving ? 'Saving...' : 'Save now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuickExpense(_QuickAddPreset preset, String currency) async {
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.addPersonalExpense(
        title: _memoController.text.trim().isEmpty ? '${preset.label} payment' : _memoController.text.trim(),
        amount: (parsed * 100).round(),
        categoryId: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
        date: DateTime.now().toIso8601String().split('T').first,
        currency: currency,
        accountId: _selectedAccountId.isEmpty ? null : _selectedAccountId,
        notes: 'Quick Add • ${preset.label}',
      );
      ref.invalidate(personalExpensesProvider);
      ref.invalidate(recentExpensesProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionSummaryProvider(const LedgerQuery(pageSize: 8)));
      if (mounted) {
        _amountController.clear();
        _memoController.clear();
        _amountFocusNode.requestFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${preset.label} expense saved'),
            action: SnackBarAction(
              label: 'Go to app',
              onPressed: () => context.go('/dashboard'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _normalizePreset(String? source) {
    if (source == null || source.trim().isEmpty) return 'credit_card';
    final normalized = source.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized == 'wallet' || normalized == 'paypay') return 'credit_card';
    return _presets.any((item) => item.id == normalized) ? normalized : 'credit_card';
  }

  String _matchAccountForPreset(List<Account> accounts, _QuickAddPreset preset) {
    for (final account in accounts) {
      final name = account.name.toLowerCase();
      if (preset.keywords.any(name.contains)) return account.id;
    }
    for (final account in accounts) {
      if (preset.accountTypes.contains(account.type)) return account.id;
    }
    return '';
  }
}

class _QuickAddPreset {
  final String id;
  final String label;
  final IconData icon;
  final List<String> keywords;
  final List<String> accountTypes;

  const _QuickAddPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.keywords,
    required this.accountTypes,
  });
}

class _PresetChip extends StatelessWidget {
  final _QuickAddPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xF20053DB), Color(0xF200174B)],
                  )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppColors.outlineVariant.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                preset.icon,
                size: 18,
                color: selected ? Colors.white : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                preset.label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
