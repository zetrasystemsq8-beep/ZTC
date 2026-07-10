import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

class TransferAmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const TransferAmountInput({
    super.key,
    required this.controller,
    this.label,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[Text(
          label!,
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.sm.h),
        ],
        AppTextField(
          controller: controller,
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: const Icon(IconsaxPlusBold.money),
          onChanged: onChanged,
          validator: validator,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class TransferSummaryCard extends StatelessWidget {
  final String recipientName;
  final String recipientEmail;
  final double amount;
  final String description;

  const TransferSummaryCard({
    super.key,
    required this.recipientName,
    required this.recipientEmail,
    required this.amount,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Summary',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: AppSpacing.lg.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recipient', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              Text(recipientName, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Email', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              Text(recipientEmail, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          AppDivider(indent: 0, endIndent: 0),
          SizedBox(height: AppSpacing.md.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: tt.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Note', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              Expanded(
                child: Text(
                  description,
                  textAlign: TextAlign.right,
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
