import 'package:flutter/material.dart';

import '../currency_format.dart';
import '../theme/app_theme.dart';

enum SummaryTone { primary, positive, negative, neutral, activity }

class SummaryMetric extends StatelessWidget {
  final String label;
  final int value;
  final String currency;
  final String? subtitle;
  final String? helper;
  final IconData? icon;
  final SummaryTone tone;
  final bool emphasized;

  const SummaryMetric({
    super.key,
    required this.label,
    required this.value,
    required this.currency,
    this.subtitle,
    this.helper,
    this.icon,
    this.tone = SummaryTone.neutral,
    this.emphasized = false,
  });

  bool get _isPrimary => tone == SummaryTone.primary;

  LinearGradient get _gradient {
    switch (tone) {
      case SummaryTone.primary:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF20053DB), Color(0xF200174B)],
        );
      case SummaryTone.positive:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2E8F9EF), Color(0xFAFFFFFF)],
        );
      case SummaryTone.negative:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2FFECEC), Color(0xFAFFFFFF)],
        );
      case SummaryTone.activity:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2E9F0FF), Color(0xFAFFFFFF)],
        );
      case SummaryTone.neutral:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2F2F3FF), Color(0xFAFFFFFF)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = _isPrimary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: onPrimary
              ? Colors.transparent
              : AppColors.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onPrimary
                            ? Colors.white.withValues(alpha: 0.75)
                            : AppColors.secondary,
                        letterSpacing: 1.8,
                        fontSize: 11,
                      ),
                ),
              ),
              if (icon != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: onPrimary
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: onPrimary ? Colors.white : AppColors.onSurface,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatMoneyCents(value, currency),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: emphasized ? 28 : 22,
                  fontWeight: FontWeight.w800,
                  color: onPrimary ? Colors.white : AppColors.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onPrimary
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (helper != null && helper!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              helper!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: onPrimary
                        ? Colors.white.withValues(alpha: 0.75)
                        : AppColors.secondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
