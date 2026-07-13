import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

/// Skeleton view that mirrors the dashboard shape while data loads.
class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    Widget bar({double? width, double height = 14, BorderRadius? radius}) {
      return Container(
        width: width,
        height: height.h,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: radius ?? AppBorders.xs,
        ),
      );
    }

    return Skeletonizer(
      enabled: true,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 24.w, backgroundColor: cs.surfaceContainerHighest),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(width: 120.w, height: 12),
                      SizedBox(height: 8.h),
                      bar(width: 180.w),
                    ],
                  ),
                ),
                CircleAvatar(radius: 22.w, backgroundColor: cs.surfaceContainerHighest),
              ],
            ),
            SizedBox(height: AppSpacing.lg.h),
            Container(
              height: 180.h,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppBorders.lg,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : AppSpacing.sm.w),
                    child: Container(
                      height: 96.h,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: AppBorders.md,
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Container(
              height: 160.h,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppBorders.lg,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            for (var i = 0; i < 3; i++) ...[
              Container(
                height: 64.h,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: AppBorders.md,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
            ],
          ],
        ),
      ),
    );
  }
}
