import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/wallet.dart';
import 'package:ztc_bank/src/services/copy_service.dart';

Future<String?> _fetchZetraId(String userId) async {
  final data = await Supabase.instance.client
      .from('profiles')
      .select('zetra_id')
      .eq('id', userId)
      .maybeSingle();
  return data?['zetra_id'] as String?;
}

/// Premium balance card with hide/show, real Zetra ID, copy and QR actions.
class DashboardBalanceCard extends StatefulWidget {
  const DashboardBalanceCard({
    super.key,
    required this.wallet,
    required this.isHidden,
    required this.onToggleHidden,
    required this.onShowQr,
    this.onTap,
  });

  final Wallet wallet;
  final bool isHidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onShowQr;
  final VoidCallback? onTap;

  @override
  State<DashboardBalanceCard> createState() => _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends State<DashboardBalanceCard> {
  late final Future<String?> _zetraIdFuture;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _zetraIdFuture = userId != null ? _fetchZetraId(userId) : Future.value(null);
  }

  String _formatBalance() {
    final value = widget.wallet.balance;
    final whole = value.truncate();
    final fraction = ((value - whole) * 100).round().abs().toString().padLeft(2, '0');
    final wholeStr = whole
        .toString()
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return '$wholeStr.$fraction';
  }

  Future<void> _copyAccount(BuildContext context, String accountNumber) async {
    await CopyService.instance.copy(accountNumber);
    if (!context.mounted) return;
    context.showTypedSnackBar(
      'home.account_copied'.tr(),
      type: SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final onCard = cs.onPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppBorders.lg,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppBorders.lg,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                Color.alphaBlend(
                  cs.tertiary.withValues(alpha: 0.55),
                  cs.primary,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'home.total_balance'.tr(),
                      style: tt.bodyMedium?.copyWith(
                        color: onCard.withValues(alpha: 0.75),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    _IconChip(
                      icon: widget.isHidden
                          ? IconsaxPlusLinear.eye_slash
                          : IconsaxPlusLinear.eye,
                      tooltip: widget.isHidden
                          ? 'home.show_balance'.tr()
                          : 'home.hide_balance'.tr(),
                      onTap: widget.onToggleHidden,
                      foreground: onCard,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.wallet.currency,
                      style: tt.titleMedium?.copyWith(
                        color: onCard.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Text(
                          widget.isHidden ? '••••••' : _formatBalance(),
                          key: ValueKey(widget.isHidden),
                          style: tt.displaySmall?.copyWith(
                            color: onCard,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.h),
                FutureBuilder<String?>(
                  future: _zetraIdFuture,
                  builder: (context, snapshot) {
                    final accountNumber = snapshot.data ?? '—';

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md.w,
                        vertical: AppSpacing.sm.h,
                      ),
                      decoration: BoxDecoration(
                        color: onCard.withValues(alpha: 0.12),
                        borderRadius: AppBorders.md,
                        border: Border.all(
                          color: onCard.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            IconsaxPlusLinear.card,
                            size: 18.sp,
                            color: onCard.withValues(alpha: 0.9),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'home.account_number'.tr(),
                                  style: tt.labelSmall?.copyWith(
                                    color: onCard.withValues(alpha: 0.7),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  accountNumber,
                                  style: tt.bodyMedium?.copyWith(
                                    color: onCard,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _IconChip(
                            icon: IconsaxPlusLinear.copy,
                            tooltip: 'home.copy_account'.tr(),
                            onTap: snapshot.data == null
                                ? () {}
                                : () => _copyAccount(context, snapshot.data!),
                            foreground: onCard,
                          ),
                          SizedBox(width: 6.w),
                          _IconChip(
                            icon: IconsaxPlusLinear.scan_barcode,
                            tooltip: 'home.show_qr'.tr(),
                            onTap: widget.onShowQr,
                            foreground: onCard,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.onTap,
    required this.foreground,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color foreground;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: foreground.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34.w,
          height: 34.w,
          child: Icon(icon, size: 18.sp, color: foreground),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}
