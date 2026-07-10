import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/transactions/domain/entities/transaction_filter.dart';

class TransactionFilterSheet extends HookWidget {
  final TransactionFilter currentFilter;
  final ValueChanged<TransactionFilter> onApply;

  const TransactionFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final selectedType = useState<TransactionType?>(currentFilter.type);
    final selectedStatus = useState<TransactionStatus?>(currentFilter.status);
    final minAmountController = useTextEditingController(
      text: currentFilter.minAmount?.toString() ?? '',
    );
    final maxAmountController = useTextEditingController(
      text: currentFilter.maxAmount?.toString() ?? '',
    );
    final startDate = useState<DateTime?>(currentFilter.startDate);
    final endDate = useState<DateTime?>(currentFilter.endDate);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Transactions',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(IconsaxPlusLinear.close_circle, color: cs.onSurface),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.h),

                // Transaction Type
                Text(
                  'Transaction Type',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Wrap(
                  spacing: AppSpacing.sm.w,
                  children: TransactionType.values.map((type) {
                    final isSelected = selectedType.value == type;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(type.toString().split('.').last),
                      onSelected: (selected) {
                        selectedType.value = selected ? type : null;
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.lg.h),

                // Transaction Status
                Text(
                  'Status',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Wrap(
                  spacing: AppSpacing.sm.w,
                  children: TransactionStatus.values.map((status) {
                    final isSelected = selectedStatus.value == status;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(status.toString().split('.').last),
                      onSelected: (selected) {
                        selectedStatus.value = selected ? status : null;
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: AppSpacing.lg.h),

                // Amount Range
                Text(
                  'Amount Range',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: minAmountController,
                        label: 'Min',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(IconsaxPlusBold.money),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: AppTextField(
                        controller: maxAmountController,
                        label: 'Max',
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(IconsaxPlusBold.money),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Reset',
                        variant: ButtonVariant.outline,
                        onPressed: () {
                          selectedType.value = null;
                          selectedStatus.value = null;
                          minAmountController.clear();
                          maxAmountController.clear();
                          startDate.value = null;
                          endDate.value = null;
                        },
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: AppButton(
                        label: 'Apply',
                        onPressed: () {
                          final minAmount = double.tryParse(minAmountController.text);
                          final maxAmount = double.tryParse(maxAmountController.text);

                          final newFilter = TransactionFilter(
                            type: selectedType.value,
                            status: selectedStatus.value,
                            minAmount: minAmount,
                            maxAmount: maxAmount,
                            startDate: startDate.value,
                            endDate: endDate.value,
                          );

                          onApply(newFilter);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
