import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/transaction_item.dart';

class RecentTransactions extends StatelessWidget {
  final List<Transaction> transactions;
  final VoidCallback? onSeeAll;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AppCard(
      title: 'Recent Transactions',
      trailing: transactions.isNotEmpty
          ? TextButton(
              onPressed: onSeeAll,
              child: Text(
                'See all',
                style: tt.bodySmall?.copyWith(color: cs.primary),
              ),
            )
          : null,
      child: transactions.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
                child: Text(
                  'No transactions yet',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => Divider(
                color: cs.outlineVariant,
                height: 1,
              ),
              itemBuilder: (context, index) {
                return TransactionItem(
                  transaction: transactions[index],
                );
              },
            ),
    );
  }
}
