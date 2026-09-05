import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class AddEntrySpeedDial extends StatefulWidget {
  const AddEntrySpeedDial({super.key});

  @override
  State<AddEntrySpeedDial> createState() => _AddEntrySpeedDialState();
}

class _AddEntrySpeedDialState extends State<AddEntrySpeedDial> {
  bool _open = false;

  void _close() {
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _ActionPill(
            icon: Icons.swap_horiz_rounded,
            label: 'Transfer',
            onTap: () {
              _close();
              context.push('/transfers');
            },
          ),
          const SizedBox(height: 10),
          _ActionPill(
            icon: Icons.south_west_rounded,
            label: 'Income',
            onTap: () {
              _close();
              context.push('/income');
            },
          ),
          const SizedBox(height: 10),
          _ActionPill(
            icon: Icons.receipt_long_outlined,
            label: 'Expense',
            onTap: () {
              _close();
              context.push('/add-expense');
            },
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _open = !_open),
          child: Icon(_open ? Icons.close : Icons.add, size: 28),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
