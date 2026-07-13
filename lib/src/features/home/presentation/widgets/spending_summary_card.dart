import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

/// Lightweight spending breakdown for the current month, derived from
/// the transactions currently in memory. Backend-friendly: swap the
/// derivation with a Rust API call once available.
class SpendingSummaryCard extends StatelessWidget {
  const SpendingSummaryCard({
    super.key,
    required this.transactions,
    required this.currency,
  });

  final List<Transaction> transactions;
  final String currency;

  ({double income, double outflow}) _totals() {
    double income = 0;
    double outflow = 0;
    final now = DateTime.now();
    for (final tx in transactions) {
      if (tx.timestamp.year != now.year || tx.timestamp.month != now.month) {
        continue;
      }
      switch (tx.type) {
        case TransactionType.credit:
          income += tx.amount;
        case TransactionType.debit:
        case TransactionType.transfer:
          outflow += tx.amount;
      }
    }
    return (income: income, outflow: outflow);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final totals = _totals();
    final total = totals.income + totals.outflow;
    final incomeRatio = total == 0 ? 0.5 : totals.income / total;

    return AppCard(
      title: 'home.spending_summary'.tr(),
      subtitle: 'home.this_month'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppBorders.xs,
            child: Row(
              children: [
                Expanded(
                  flex: (incomeRatio * 1000).round().clamp(1, 999),
                  child: Container(height: 10.h, color: cs.primary),
                ),
                Expanded(
                  flex: ((1 - incomeRatio) * 1000).round().clamp(1, 999),
                  child: Container(height: 10.h, color: cs.tertiary),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  color: cs.primary,
                  label: 'home.income'.tr(),
                  amount: '$currency ${totals.income.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _SummaryTile(
                  color: cs.tertiary,
                  label: 'home.spent'.tr(),
                  amount: '$currency ${totals.outflow.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          if (total == 0) ...[
            SizedBox(height: AppSpacing.sm.h),
            Text(
              'home.spending_empty'.tr(),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.color,
    required this.label,
    required this.amount,
  });

  final Color color;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              Text(
                amount,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
