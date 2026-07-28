import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/transaction_item.dart';
import 'package:ztc_bank/src/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:ztc_bank/src/features/transactions/domain/entities/transaction_filter.dart';
import 'package:ztc_bank/src/features/transactions/presentation/widgets/transactions_widgets.dart';

class TransactionsListScreen extends HookConsumerWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final transactionsAsyncValue = ref.watch(transactionsListProvider);
    final statsAsyncValue = ref.watch(transactionStatsProvider);
    final currentFilter = ref.watch(transactionFilterProvider);

    void handleSearch(String query) {
      if (query.isEmpty) {
        ref.read(transactionsListProvider.notifier).fetchTransactions();
      } else {
        ref.read(transactionsListProvider.notifier).searchTransactions(query);
      }
    }

    void handleFilter(TransactionFilter filter) {
      ref.read(transactionFilterProvider.notifier).state = filter;
      ref.read(transactionsListProvider.notifier).fetchTransactions(filter: filter);
    }

    void showFilterSheet() {
      showModalBottomSheet(
        context: context,
        builder: (context) => TransactionFilterSheet(
          currentFilter: currentFilter,
          onApply: handleFilter,
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(title: 'Transactions'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(transactionsListProvider);
          ref.refresh(transactionStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: AppSpacing.md.h),
              TransactionSearchBar(
                controller: searchController,
                onChanged: (query) {
                  handleSearch(query);
                },
                onFilter: showFilterSheet,
                onClear: () {
                  ref.read(transactionsListProvider.notifier).fetchTransactions();
                },
              ),
              SizedBox(height: AppSpacing.lg.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                child: statsAsyncValue.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                  data: (stats) => TransactionStatsCard(stats: stats),
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                child: transactionsAsyncValue.when(
                  loading: () => const AppLoading(),
                  error: (error, stack) => AppErrorWidget(
                    message: error.toString(),
                    onRetry: () {
                      ref.refresh(transactionsListProvider);
                    },
                  ),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return AppEmptyState(
                        icon: IconsaxPlusLinear.document,
                        title: 'No transactions',
                        subtitle: 'Start making transactions to see them here',
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: cs.outlineVariant,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return TransactionItem(
                          transaction: transaction,
                          onTap: () => _navigateToDetails(
                            context,
                            transaction.id,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, String transactionId) {
    context.push('${AppRoutes.transactions}/$transactionId');
  }
}
