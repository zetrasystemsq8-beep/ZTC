import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onSend;
  final VoidCallback onReceive;

  const ActionButtons({
    super.key,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onSend,
    required this.onReceive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: IconsaxPlusBold.arrow_down,
          label: 'Deposit',
          onPressed: onDeposit,
          color: Colors.green,
        ),
        _ActionButton(
          icon: IconsaxPlusBold.arrow_up,
          label: 'Withdraw',
          onPressed: onWithdraw,
          color: Colors.red,
        ),
        _ActionButton(
          icon: IconsaxPlusBold.import,
          label: 'Send',
          onPressed: onSend,
          color: Colors.blue,
        ),
        _ActionButton(
          icon: IconsaxPlusBold.export,
          label: 'Receive',
          onPressed: onReceive,
          color: Colors.purple,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;

    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            label,
            style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
