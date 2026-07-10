import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

class TransactionStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const TransactionStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final totalTransactions = stats['totalTransactions'] as int? ?? 0;
    final totalAmount = stats['totalAmount'] as double? ?? 0.0;
    final totalIncome = stats['totalIncome'] as double? ?? 0.0;
    final totalExpense = stats['totalExpense'] as double? ?? 0.0;

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'Total Transactions',
                value: totalTransactions.toString(),
                icon: IconsaxPlusLinear.activity,
                color: Colors.blue,
              ),
              _StatItem(
                label: 'Total Amount',
                value: '\$${totalAmount.toStringAsFixed(2)}',
                icon: IconsaxPlusLinear.money,
                color: Colors.green,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                label: 'Income',
                value: '\$${totalIncome.toStringAsFixed(2)}',
                icon: IconsaxPlusLinear.arrow_down,
                color: Colors.green,
              ),
              _StatItem(
                label: 'Expense',
                value: '\$${totalExpense.toStringAsFixed(2)}',
                icon: IconsaxPlusLinear.arrow_up,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
