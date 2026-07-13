import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

/// A four-tile quick actions row: Send, Receive, Deposit, Withdraw.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.onSend,
    required this.onReceive,
    required this.onDeposit,
    required this.onWithdraw,
  });

  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: IconsaxPlusBold.send_2,
        label: 'home.action_send'.tr(),
        onTap: onSend,
      ),
      _QuickAction(
        icon: IconsaxPlusBold.receive_square,
        label: 'home.action_receive'.tr(),
        onTap: onReceive,
      ),
      _QuickAction(
        icon: IconsaxPlusBold.wallet_add,
        label: 'home.action_deposit'.tr(),
        onTap: onDeposit,
      ),
      _QuickAction(
        icon: IconsaxPlusBold.wallet_minus,
        label: 'home.action_withdraw'.tr(),
        onTap: onWithdraw,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(child: _QuickActionTile(action: actions[i])),
          if (i != actions.length - 1) SizedBox(width: AppSpacing.sm.w),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: AppBorders.md,
      child: InkWell(
        borderRadius: AppBorders.md,
        onTap: action.onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
          decoration: BoxDecoration(
            borderRadius: AppBorders.md,
            border: Border.all(color: cs.outlineVariant, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: AppBorders.sm,
                ),
                child: Icon(
                  action.icon,
                  color: cs.onPrimaryContainer,
                  size: 22.sp,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
