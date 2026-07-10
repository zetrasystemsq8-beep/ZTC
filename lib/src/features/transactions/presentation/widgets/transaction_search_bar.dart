import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

class TransactionSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilter;
  final VoidCallback? onClear;

  const TransactionSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilter,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: controller,
              label: 'Search transactions',
              hint: 'Description, email...',
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
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: AppSpacing.md.w),
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(IconsaxPlusBold.setting_2, color: cs.primary),
              onPressed: onFilter,
            ),
          ),
        ],
      ),
    );
  }
}
