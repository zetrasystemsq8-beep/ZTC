import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/auth/domain/entities/user.dart';

/// Top header of the dashboard: avatar, greeting, notification bell.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    this.user,
    this.unreadNotifications = 0,
    this.onNotificationsTap,
    this.onAvatarTap,
  });

  final AppUser? user;
  final int unreadNotifications;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAvatarTap;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.good_morning'.tr();
    if (hour < 17) return 'home.good_afternoon'.tr();
    return 'home.good_evening'.tr();
  }

  String _initials(String? name, String? email) {
    final source = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()
        : (email?.trim() ?? '');
    if (source.isEmpty) return 'ZT';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final displayName = user?.name ?? user?.email?.split('@').first ?? 'home.guest'.tr();

    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(user?.name, user?.email),
              style: tt.titleMedium?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              SizedBox(height: 2.h),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        _NotificationButton(
          unread: unreadNotifications,
          onTap: onNotificationsTap,
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.unread, this.onTap});

  final int unread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: cs.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44.w,
              height: 44.w,
              child: Icon(
                IconsaxPlusLinear.notification,
                color: cs.onSurface,
                size: 22.sp,
              ),
            ),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
              decoration: BoxDecoration(
                color: cs.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: cs.surface, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 9 ? '9+' : '$unread',
                textAlign: TextAlign.center,
                style: context.theme.textTheme.labelSmall?.copyWith(
                  color: cs.onError,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
