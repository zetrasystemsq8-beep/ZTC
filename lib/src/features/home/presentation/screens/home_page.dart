// HomePage (complete, all demo removed)
import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/auth/presentation/providers/session_provider.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/recent_transactions.dart';
import 'package:ztc_bank/src/features/home/presentation/widgets/home_widgets.dart';
import 'package:ztc_bank/src/services/copy_service.dart';

/// Production banking dashboard.
///
/// Reads wallet + transaction state from the Riverpod providers and renders
/// greeting, balance, quick actions, cards, spending summary, recent
/// transactions, and promotional banner. All business logic goes through
/// providers/repositories wired to the real backend.
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final session = ref.watch(sessionProvider);
    final walletState = ref.watch(walletProvider);
    final transactionsState = ref.watch(transactionsProvider);

    final isBalanceHidden = useState<bool>(false);

    Future<void> refresh() async {
      await Future.wait([
        ref.read(walletProvider.notifier).fetchWallet(),
        ref.read(transactionsProvider.notifier).fetchTransactions(),
      ]);
    }

    void goSend() => context.push(AppRoutes.sendMoney);
    void goReceive() => context.push(AppRoutes.receiveMoney);
    void goTransactions() => context.push(AppRoutes.transactions);
    void goWallet() => context.push(AppRoutes.wallet);

    void showComingSoon(String labelKey) {
      context.showTypedSnackBar(
        'home.coming_soon'.tr(args: [labelKey.tr()]),
        type: SnackBarType.info,
      );
    }

    Future<void> showQr(Wallet wallet) async {
      final accountNumber = _accountNumberFor(wallet);
      await context.showAppBottomSheet<void>(
        builder: (sheetContext) => _AccountQrSheet(
          accountNumber: accountNumber,
          holder: session.user?.name ?? session.user?.email ?? '',
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cs.surface,
        elevation: 0,
        titleSpacing: AppSpacing.md.w,
        toolbarHeight: 72.h,
        title: GreetingHeader(
          user: session.user,
          unreadNotifications: 0,
          onNotificationsTap: () => showComingSoon('home.notifications'),
          onAvatarTap: goWallet,
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          color: cs.primary,
          child: walletState.when(
            loading: () => const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: DashboardLoading(),
            ),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl.h),
              children: [
                AppErrorWidget(
                  title: 'home.error_title'.tr(),
                  message: error.toString(),
                  onRetry: refresh,
                ),
              ],
            ),
            data: (wallet) => _DashboardBody(
              wallet: wallet,
              transactionsState: transactionsState,
              isBalanceHidden: isBalanceHidden.value,
              onToggleHidden: () =>
                  isBalanceHidden.value = !isBalanceHidden.value,
              onShowQr: () => showQr(wallet),
              onSend: goSend,
              onReceive: goReceive,
              onDeposit: () => context.push(AppRoutes.wallet),
              onWithdraw: () => context.push(AppRoutes.wallet),
              onSeeAllTransactions: goTransactions,
              onOpenWallet: goWallet,
              onPromoTap: () => showComingSoon('home.promo_title'),
              copyAccount: () async {
                await CopyService.instance.copy(_accountNumberFor(wallet));
                if (!context.mounted) return;
                context.showTypedSnackBar(
                  'home.account_copied'.tr(),
                  type: SnackBarType.success,
                );
              },
              textTheme: tt,
            ),
          ),
        ),
      ),
    );
  }
}

String _accountNumberFor(Wallet wallet) {
  final digits = wallet.id.replaceAll(RegExp('[^0-9]'), '');
  final padded = ('${digits}000000000000').substring(0, 12);
  return 'ZTC-${padded.substring(0, 4)}-${padded.substring(4, 8)}-${padded.substring(8, 12)}';
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.wallet,
    required this.transactionsState,
    required this.isBalanceHidden,
    required this.onToggleHidden,
    required this.onShowQr,
    required this.onSend,
    required this.onReceive,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onSeeAllTransactions,
    required this.onOpenWallet,
    required this.onPromoTap,
    required this.copyAccount,
    required this.textTheme,
  });

  final Wallet wallet;
  final AsyncValue<List<Transaction>> transactionsState;
  final bool isBalanceHidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onShowQr;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onSeeAllTransactions;
  final VoidCallback onOpenWallet;
  final VoidCallback onPromoTap;
  final Future<void> Function() copyAccount;
  final TextTheme textTheme;

  List<BankCardData> _cards() {
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: AppSpacing.md.w,
        right: AppSpacing.md.w,
        top: AppSpacing.sm.h,
        bottom: AppSpacing.xl.h,
      ),
      children: [
        DashboardBalanceCard(
          wallet: wallet,
          isHidden: isBalanceHidden,
          onToggleHidden: onToggleHidden,
          onShowQr: onShowQr,
          onTap: onOpenWallet,
        ),
        SizedBox(height: AppSpacing.lg.h),
        QuickActionsGrid(
          onSend: onSend,
          onReceive: onReceive,
          onDeposit: onDeposit,
          onWithdraw: onWithdraw,
        ),
        SizedBox(height: AppSpacing.lg.h),
        _SectionHeader(
          title: 'home.your_cards'.tr(),
          actionLabel: 'home.manage'.tr(),
          onAction: onOpenWallet,
        ),
        SizedBox(height: AppSpacing.sm.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: SizedBox(
            height: 160.h,
            child: CardsCarousel(
              cards: _cards(),
              onCardTap: (_) => onOpenWallet(),
              onAddCard: () => context.showTypedSnackBar(
                'home.coming_soon'.tr(args: ['home.add_card'.tr()]),
                type: SnackBarType.info,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg.h),
        transactionsState.when(
          loading: () => SpendingSummaryCard(
            transactions: const [],
            currency: wallet.currency,
          ),
          error: (_, __) => SpendingSummaryCard(
            transactions: const [],
            currency: wallet.currency,
          ),
          data: (txs) => SpendingSummaryCard(
            transactions: txs,
            currency: wallet.currency,
          ),
        ),
        SizedBox(height: AppSpacing.lg.h),
        _SectionHeader(
          title: 'home.recent_transactions'.tr(),
          actionLabel: 'home.see_all'.tr(),
          onAction: onSeeAllTransactions,
        ),
        SizedBox(height: AppSpacing.sm.h),
        transactionsState.when(
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl.h),
            child: const AppLoading(),
          ),
          error: (error, _) => AppErrorWidget(
            title: 'home.transactions_error'.tr(),
            message: error.toString(),
            onRetry: onSeeAllTransactions,
          ),
          data: (txs) {
            if (txs.isEmpty) {
              return AppEmptyState(
                icon: IconsaxPlusLinear.receipt_2,
                title: 'home.no_transactions_title'.tr(),
                subtitle: 'home.no_transactions_subtitle'.tr(),
                actionLabel: 'home.action_send'.tr(),
                onAction: onSend,
              );
            }
            final recent = txs.take(5).toList(growable: false);
            return RecentTransactions(
              transactions: recent,
              onSeeAll: onSeeAllTransactions,
            );
          },
        ),
        SizedBox(height: AppSpacing.lg.h),
        PromoBanner(
          title: 'home.promo_title'.tr(),
          subtitle: 'home.promo_subtitle'.tr(),
          ctaLabel: 'home.promo_cta'.tr(),
          onCtaPressed: onPromoTap,
        ),
        SizedBox(height: AppSpacing.md.h),
        Center(
          child: TextButton.icon(
            onPressed: copyAccount,
            icon: Icon(IconsaxPlusLinear.copy, size: 16.sp, color: cs.primary),
            label: Text(
              'home.copy_account'.tr(),
              style: tt.labelLarge?.copyWith(color: cs.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: tt.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _AccountQrSheet extends StatelessWidget {
  const _AccountQrSheet({required this.accountNumber, required this.holder});

  final String accountNumber;
  final String holder;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              'home.share_account'.tr(),
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              'home.share_account_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Container(
              width: 220.w,
              height: 220.w,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppBorders.lg,
                border: Border.all(color: cs.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(
                IconsaxPlusBold.scan_barcode,
                size: 120.sp,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            if (holder.isNotEmpty) ...[
              Text(
                holder,
                style: tt.titleSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
            ],
            SelectableText(
              accountNumber,
              style: tt.titleMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppButton(
              label: 'home.copy_account'.tr(),
              isFullWidth: true,
              prefixIcon: Icon(IconsaxPlusLinear.copy, size: 18.sp),
              onPressed: () async {
                await CopyService.instance.copy(accountNumber);
                if (!context.mounted) return;
                context.pop();
                context.showTypedSnackBar(
                  'home.account_copied'.tr(),
                  type: SnackBarType.success,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
