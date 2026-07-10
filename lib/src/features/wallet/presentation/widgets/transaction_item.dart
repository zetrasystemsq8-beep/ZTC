import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final isCredit = transaction.type == TransactionType.credit;
    final icon = _getIconForType(transaction.type);
    final color = isCredit ? Colors.green : Colors.red;

    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.button,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatDate(transaction.timestamp),
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} \$${transaction.amount.toStringAsFixed(2)}',
                  style: tt.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 2.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    _getStatusText(transaction.status),
                    style: tt.bodySmall?.copyWith(
                      color: _getStatusColor(transaction.status),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(TransactionType type) {
    return switch (type) {
      TransactionType.credit => IconsaxPlusLinear.arrow_down,
      TransactionType.debit => IconsaxPlusLinear.arrow_up,
      TransactionType.transfer => IconsaxPlusLinear.import,
    };
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return 'Today';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getStatusText(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => 'Pending',
      TransactionStatus.completed => 'Success',
      TransactionStatus.failed => 'Failed',
    };
  }

  Color _getStatusColor(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => Colors.orange,
      TransactionStatus.completed => Colors.green,
      TransactionStatus.failed => Colors.red,
    };
  }
}
