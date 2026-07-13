import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

/// Promotional banner that highlights a product/offer. Uses theme tokens
/// only so it adapts to light/dark and any brand recolour.
class PromoBanner extends StatelessWidget {
  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    this.onCtaPressed,
    this.icon = IconsaxPlusBold.gift,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onCtaPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final onSurface = cs.onSecondaryContainer;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        borderRadius: AppBorders.lg,
        color: cs.secondaryContainer,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: cs.secondary,
              borderRadius: AppBorders.md,
            ),
            child: Icon(icon, color: cs.onSecondary, size: 24.sp),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    color: onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          TextButton(
            onPressed: onCtaPressed,
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: AppSpacing.sm.h,
              ),
            ),
            child: Text(
              ctaLabel,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
