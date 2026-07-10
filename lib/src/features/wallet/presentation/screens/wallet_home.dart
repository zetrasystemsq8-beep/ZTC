import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/balance_card.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/action_buttons.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/recent_transactions.dart';

class WalletHome extends HookConsumerWidget {
  const WalletHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final walletAsyncValue = ref.watch(walletProvider);
    final transactionsAsyncValue = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(
        title: 'Wallet',
        actions: [
          IconButton(
            icon: Icon(IconsaxPlusLinear.setting_2, color: cs.onSurface),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
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
                    // Balance Card
                    BalanceCard(wallet: wallet),
                    SizedBox(height: AppSpacing.xl.h),

                    // Action Buttons
                    ActionButtons(
                      onDeposit: () => _showDepositDialog(context, ref),
                      onWithdraw: () => _showWithdrawDialog(context, ref),
                      onSend: () => _showSendDialog(context, ref),
                      onReceive: () => _showReceiveDialog(context, ref),
                    ),
                    SizedBox(height: AppSpacing.xl.h),

                    // Recent Transactions
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
                            // Navigate to all transactions
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

  void _showDepositDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _DepositDialog(ref: ref),
    );
  }

  void _showWithdrawDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _WithdrawDialog(ref: ref),
    );
  }

  void _showSendDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SendDialog(ref: ref),
    );
  }

  void _showReceiveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ReceiveDialog(ref: ref),
    );
  }
}

// Deposit Dialog
class _DepositDialog extends HookConsumerWidget {
  final WidgetRef ref;

  const _DepositDialog({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AlertDialog(
      title: Text('Deposit Funds', style: tt.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: amountController,
            label: 'Amount',
            prefixIcon: const Icon(IconsaxPlusBold.money),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md.h),
          AppTextField(
            controller: descriptionController,
            label: 'Description (Optional)',
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
                  await ref
                      .read(walletProvider.notifier)
                      .deposit(amount, descriptionController.text);
                  isLoading.value = false;
                  if (context.mounted) {
                    Navigator.pop(context);
                    showToast(context, message: 'Deposit successful', status: 'success');
                  }
                },
          child: Text(
            isLoading.value ? 'Processing...' : 'Deposit',
            style: TextStyle(color: cs.primary),
          ),
        ),
      ],
    );
  }
}

// Withdraw Dialog
class _WithdrawDialog extends HookConsumerWidget {
  final WidgetRef ref;

  const _WithdrawDialog({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AlertDialog(
      title: Text('Withdraw Funds', style: tt.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: amountController,
            label: 'Amount',
            prefixIcon: const Icon(IconsaxPlusBold.money),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md.h),
          AppTextField(
            controller: descriptionController,
            label: 'Description (Optional)',
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
                  await ref
                      .read(walletProvider.notifier)
                      .withdraw(amount, descriptionController.text);
                  isLoading.value = false;
                  if (context.mounted) {
                    Navigator.pop(context);
                    showToast(context, message: 'Withdrawal successful', status: 'success');
                  }
                },
          child: Text(
            isLoading.value ? 'Processing...' : 'Withdraw',
            style: TextStyle(color: cs.primary),
          ),
        ),
      ],
    );
  }
}

// Send Dialog
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
            label: 'Recipient Email',
            prefixIcon: const Icon(IconsaxPlusBold.sms),
            keyboardType: TextInputType.emailAddress,
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

// Receive Dialog
class _ReceiveDialog extends HookConsumerWidget {
  final WidgetRef ref;

  const _ReceiveDialog({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final isLoading = useState(false);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AlertDialog(
      title: Text('Request Money', style: tt.titleLarge),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: amountController,
            label: 'Amount',
            prefixIcon: const Icon(IconsaxPlusBold.money),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: AppSpacing.md.h),
          AppTextField(
            controller: descriptionController,
            label: 'Description (Optional)',
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
                  await ref
                      .read(walletProvider.notifier)
                      .receive(amount, descriptionController.text);
                  isLoading.value = false;
                  if (context.mounted) {
                    Navigator.pop(context);
                    showToast(context, message: 'Request sent successfully', status: 'success');
                  }
                },
          child: Text(
            isLoading.value ? 'Sending...' : 'Request',
            style: TextStyle(color: cs.primary),
          ),
        ),
      ],
    );
  }
}
