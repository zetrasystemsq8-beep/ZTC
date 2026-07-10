import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/send_receive/domain/entities/user.dart';

class RecipientSearchBar extends HookWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;

  const RecipientSearchBar({
    super.key,
    required this.onSearch,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
      child: AppTextField(
        controller: controller,
        label: 'Search recipient',
        hint: 'Email or name',
        prefixIcon: const Icon(IconsaxPlusBold.search_normal),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(IconsaxPlusLinear.close_circle, color: cs.onSurfaceVariant),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              )
            : null,
        onChanged: onSearch,
      ),
    );
  }
}

class RecipientCard extends StatelessWidget {
  final User user;
  final VoidCallback onSelect;
  final bool isSelected;

  const RecipientCard({
    super.key,
    required this.user,
    required this.onSelect,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return InkWell(
      onTap: onSelect,
      borderRadius: AppBorders.button,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user.name?.characters.first ?? user.email.characters.first).toUpperCase(),
                  style: tt.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
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
                    user.name ?? user.email,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    user.email,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                IconsaxPlusBold.tick_circle,
                color: cs.primary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
