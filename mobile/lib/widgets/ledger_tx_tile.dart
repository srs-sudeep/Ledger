import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

String cleanImportNotes(String? value) {
  if (value == null) return '';
  return value.replaceAll(RegExp(r'\s*\|\s*import:[^|]+$', caseSensitive: false), '').trim();
}

class LedgerTxTile extends StatelessWidget {
  final LedgerTransaction transaction;
  final VoidCallback? onTap;

  const LedgerTxTile({
    super.key,
    required this.transaction,
    this.onTap,
  });

  Color get _amountColor {
    if (transaction.signedAmount > 0) return const Color(0xFF0F9D58);
    if (transaction.signedAmount < 0) return AppColors.error;
    return AppColors.secondary;
  }

  Color get _chipBg {
    switch (transaction.txType) {
      case 'income':
        return const Color(0xFFE8F7EF);
      case 'transfer':
        return const Color(0xFFE8F0FF);
      default:
        return const Color(0xFFFFECEC);
    }
  }

  Color get _chipFg {
    switch (transaction.txType) {
      case 'income':
        return const Color(0xFF0F9D58);
      case 'transfer':
        return AppColors.surfaceTint;
      default:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (transaction.direction) {
      case 'inflow':
        return Icons.south_west_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.north_east_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = cleanImportNotes(transaction.notes);
    final secondary = notes.isNotEmpty
        ? notes
        : (transaction.merchantOriginal?.trim().isNotEmpty ?? false)
            ? transaction.merchantOriginal!
            : 'Tap for details';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: AppColors.onSurface, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            transaction.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _chipBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            transaction.txType,
                            style: TextStyle(
                              color: _chipFg,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        transaction.date,
                        if ((transaction.accountName ?? '').isNotEmpty) transaction.accountName!,
                        if ((transaction.counterpartyAccountName ?? '').isNotEmpty)
                          transaction.counterpartyAccountName!,
                      ].join('  •  ').replaceAll('  •    •  ', '  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12.5),
                    ),
                    if ((transaction.merchantDisplay ?? '').isNotEmpty ||
                        (transaction.categoryName ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if ((transaction.merchantDisplay ?? '').isNotEmpty)
                            _MiniChip(label: transaction.merchantDisplay!),
                          if ((transaction.categoryName ?? '').isNotEmpty)
                            _MiniChip(label: transaction.categoryName!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.secondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.formattedSignedAmount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _amountColor,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right, color: AppColors.secondary, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
