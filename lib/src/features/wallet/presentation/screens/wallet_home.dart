import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/balance_card.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/recent_transactions.dart';

class WalletHome extends HookConsumerWidget {
  const WalletHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;

    final walletAsyncValue = ref.watch(walletProvider);
    final transactionsAsyncValue = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(
        title: 'Wallet',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(walletProvider);
          ref.refresh(transactionsProvider);
        },
        child: walletAsyncValue.when(
          loading: () => const AppLoading(),
          error: (error, stack) => AppErrorWidget(
            message: error.toString(),
            onRetry: () {
              ref.refresh(walletProvider);
            },
          ),
          data: (wallet) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BalanceCard(wallet: wallet),
                    SizedBox(height: AppSpacing.xl.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showSendDialog(context, ref),
                            icon: const Icon(IconsaxPlusBold.send_2),
                            label: const Text('Send'),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.receiveMoney),
                            icon: const Icon(IconsaxPlusBold.receive_square),
                            label: const Text('Receive'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                    transactionsAsyncValue.when(
                      loading: () => const AppLoading(),
                      error: (error, stack) => AppErrorWidget(
                        message: 'Failed to load transactions',
                        onRetry: () {
                          ref.refresh(transactionsProvider);
                        },
                      ),
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return AppEmptyState(
                            icon: IconsaxPlusLinear.document,
                            title: 'No transactions yet',
                            subtitle: 'Your transactions will appear here',
                          );
                        }
                        return RecentTransactions(
                          transactions: transactions,
                          onSeeAll: () {
                            context.push(AppRoutes.transactions);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSendDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SendDialog(ref: ref),
    );
  }
}

class _SendDialog extends HookConsumerWidget {
  final WidgetRef ref;

  const _SendDialog({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientController = useTextEditingController();
    final amountController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AlertDialog(
      title: Text('Send Money', style: tt.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: recipientController,
            label: 'Recipient Zetra ID',
            prefixIcon: const Icon(IconsaxPlusBold.sms),
          ),
          SizedBox(height: AppSpacing.md.h),
          AppTextField(
            controller: amountController,
            label: 'Amount',
            prefixIcon: const Icon(IconsaxPlusBold.money),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md.h),
          AppTextField(
            controller: descriptionController,
            label: 'Message (Optional)',
            prefixIcon: const Icon(IconsaxPlusBold.note),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: cs.error)),
        ),
        TextButton(
          onPressed: isLoading.value
              ? null
              : () async {
                  isLoading.value = true;
                  final amount = double.tryParse(amountController.text) ?? 0;
                  await ref.read(walletProvider.notifier).send(
                        amount,
                        recipientController.text,
                        descriptionController.text,
                      );
                  isLoading.value = false;
                  if (context.mounted) {
                    Navigator.pop(context);
                    showToast(context, message: 'Money sent successfully', status: 'success');
                  }
                },
          child: Text(
            isLoading.value ? 'Sending...' : 'Send',
            style: TextStyle(color: cs.primary),
          ),
        ),
      ],
    );
  }
}
