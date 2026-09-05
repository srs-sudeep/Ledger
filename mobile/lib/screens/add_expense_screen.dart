import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../currency_format.dart';
import '../models/models.dart';
import '../providers/data_providers.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_intro.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String? groupId;
  const AddExpenseScreen({super.key, this.groupId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  bool _isGroup = false;
  String _amount = '0';
  String? _selectedCategoryId;
  String? _selectedAccountId;
  final _titleController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isGroup = widget.groupId != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_amount == '0' && digit != '.') {
        _amount = digit;
      } else {
        if (digit == '.' && _amount.contains('.')) return;
        final parts = _amount.split('.');
        if (parts.length == 2 && parts[1].length >= 2) return;
        _amount += digit;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _deleteDigit() {
    setState(() {
      if (_amount.length <= 1) {
        _amount = '0';
      } else {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_amount);
    if (parsed == null || parsed <= 0 || _titleController.text.trim().isEmpty) return;

    setState(() => _loading = true);

    final cents = (parsed * 100).round();
    final date = DateTime.now().toIso8601String().split('T').first;
    final profile = ref.read(profileProvider).value;
    final currency = profile?.defaultCurrency ?? kDefaultCurrency;

    try {
      if (_isGroup && widget.groupId != null) {
        final members = ref.read(groupMembersProvider(widget.groupId!)).value ?? [];
        final perPerson = cents ~/ members.length;
        final remainder = cents - perPerson * members.length;

        final splits = members.asMap().entries.map((entry) {
          return {
            'user_id': entry.value.userId,
            'owed_amount': perPerson + (entry.key == 0 ? remainder : 0),
            'split_type': 'equal',
          };
        }).toList();

        await ApiService.addGroupExpense(
          title: _titleController.text.trim(),
          amount: cents,
          categoryId: _selectedCategoryId,
          date: date,
          groupId: widget.groupId!,
          payerId: ApiService.currentUserId!,
          splits: splits,
        );
      } else {
        await ApiService.addPersonalExpense(
          title: _titleController.text.trim(),
          amount: cents,
          categoryId: _selectedCategoryId,
          date: date,
          currency: currency,
          accountId: _selectedAccountId,
        );
      }

      ref.invalidate(personalExpensesProvider);
      ref.invalidate(recentExpensesProvider);
      ref.invalidate(recentTransactionsProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(transactionSummaryProvider(const LedgerQuery(pageSize: 8)));
      if (_selectedAccountId != null) {
        ref.invalidate(accountsProvider);
      }
      if (widget.groupId != null) {
        ref.invalidate(groupExpensesProvider(widget.groupId!));
        ref.invalidate(groupProvider(widget.groupId!));
      }

      if (mounted) context.pop();
    } catch (_) {
      // Handle error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final accounts = ref.watch(accountsProvider);
    final profile = ref.watch(profileProvider);
    final displayCurrency =
        profile.value?.defaultCurrency ?? kDefaultCurrency;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Add Expense'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: PageIntro(
                eyebrow: _isGroup ? 'Shared expense' : 'Personal expense',
                title: 'Add expense',
                subtitle: _isGroup
                    ? 'Split a new group expense across members with the keypad below.'
                    : 'Capture a personal expense with category and account details.',
                icon: Icons.add_card_rounded,
              ),
            ),
            const SizedBox(height: 12),
            // Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGroup = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isGroup
                                ? AppColors.surfaceContainerLowest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Personal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: !_isGroup
                                  ? AppColors.onSurface
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGroup = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isGroup
                                ? AppColors.surfaceContainerLowest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Group',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _isGroup
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
            ),

            const SizedBox(height: 16),

            // Amount display (uses your default currency, JPY by default)
            Text(
              NumberFormat.simpleCurrency(name: displayCurrency)
                  .format(double.tryParse(_amount) ?? 0),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                fontFamily: 'Manrope',
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _titleController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'What was it for?',
                  hintStyle: const TextStyle(color: AppColors.outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Category dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: categories.when(
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    hintText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                  ),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                loading: () => const SizedBox(height: 48),
                error: (e, _) => const SizedBox(),
              ),
            ),

            // Account picker (personal expenses only, when accounts exist)
            if (!_isGroup)
              accounts.when(
                data: (accs) => accs.isEmpty
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAccountId,
                          decoration: InputDecoration(
                            hintText: 'Pay from account (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLow,
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No account'),
                            ),
                            ...accs.map((a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(
                                      '${a.name} (${a.formattedBalance})'),
                                )),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedAccountId = v),
                        ),
                      ),
                loading: () => const SizedBox(),
                error: (e, _) => const SizedBox(),
              ),

            const Spacer(),

            // Numpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _numpadRow(['1', '2', '3']),
                  const SizedBox(height: 12),
                  _numpadRow(['4', '5', '6']),
                  const SizedBox(height: 12),
                  _numpadRow(['7', '8', '9']),
                  const SizedBox(height: 12),
                  _numpadRow(['.', '0', '⌫']),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Expense'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _numpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (key == '⌫') {
                    _deleteDigit();
                  } else {
                    _appendDigit(key);
                  }
                },
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: key == '⌫'
                      ? const Icon(Icons.backspace_outlined, size: 22, color: AppColors.onSurface)
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
