import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ztc_bank/src/features/auth/presentation/providers/session_provider.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:ztc_bank/src/features/wallet/presentation/widgets/recent_transactions.dart';
import 'package:ztc_bank/src/features/home/presentation/widgets/home_widgets.dart';
import 'package:ztc_bank/src/services/copy_service.dart';
import 'package:ztc_bank/src/features/linked_apps/linked_apps.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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

    void showComingSoon(String labelKey) {
      context.showTypedSnackBar(
        'home.coming_soon'.tr(args: [labelKey.tr()]),
        type: SnackBarType.info,
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
          onAvatarTap: goTransactions,
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
              onSend: goSend,
              onReceive: goReceive,
              onSeeAllTransactions: goTransactions,
              textTheme: tt,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.wallet,
    required this.transactionsState,
    required this.isBalanceHidden,
    required this.onToggleHidden,
    required this.onSend,
    required this.onReceive,
    required this.onSeeAllTransactions,
    required this.textTheme,
  });

  final Wallet wallet;
  final AsyncValue<List<Transaction>> transactionsState;
  final bool isBalanceHidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onSeeAllTransactions;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          onShowQr: onReceive,
          onTap: onReceive,
        ),
        SizedBox(height: AppSpacing.lg.h),
        _SimpleActionButton(
          icon: IconsaxPlusBold.grid_1,
          label: 'Apps',
          onTap: () => context.push('/linked-apps'),
          color: cs.tertiary,
        ),
        SizedBox(height: AppSpacing.lg.h),
        Row(
          children: [
            Expanded(
              child: _SimpleActionButton(
                icon: IconsaxPlusBold.send_2,
                label: 'Send',
                onTap: onSend,
                color: cs.primary,
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: _SimpleActionButton(
                icon: IconsaxPlusBold.receive_square,
                label: 'Receive',
                onTap: onReceive,
                color: cs.secondary,
              ),
            ),
          ],
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
      ],
    );
  }
}

class _SimpleActionButton extends StatelessWidget {
  const _SimpleActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.lg,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: AppBorders.lg,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 6.h),
            Text(
              label,
              style: tt.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
        TextButton(
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) {
              context.go('/login');
            }
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
