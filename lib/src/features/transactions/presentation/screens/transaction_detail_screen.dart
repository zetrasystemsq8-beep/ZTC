import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/wallet/domain/entities/transaction.dart';
import 'package:ztc_bank/src/features/transactions/presentation/providers/transaction_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsyncValue = ref.watch(singleTransactionProvider(transactionId));
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(title: 'Transaction Details'),
      body: transactionAsyncValue.when(
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorWidget(
          message: error.toString(),
          onRetry: () {
            ref.refresh(singleTransactionProvider(transactionId));
          },
        ),
        data: (transaction) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _TransactionHeaderCard(transaction: transaction),
                  SizedBox(height: AppSpacing.xl.h),

                  // Details Section
                  _DetailsSection(transaction: transaction),
                  SizedBox(height: AppSpacing.xl.h),

                  // Additional Info
                  _AdditionalInfoSection(transaction: transaction),
                  SizedBox(height: AppSpacing.xl.h),

                  // Action Buttons
                  _ActionButtons(transaction: transaction),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionHeaderCard extends StatelessWidget {
  final Transaction transaction;

  const _TransactionHeaderCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    final isCredit = transaction.type == TransactionType.credit;
    final icon = _getIconForType(transaction.type);
    final color = isCredit ? Colors.green : Colors.red;

    return AppCard(
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(icon, color: color, size: 40.sp),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            transaction.description,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            '${isCredit ? '+' : '-'} \$${transaction.amount.toStringAsFixed(2)}',
            style: tt.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w,
              vertical: AppSpacing.sm.h,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              _getStatusText(transaction.status),
              style: tt.labelMedium?.copyWith(
                color: _getStatusColor(transaction.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(TransactionType type) {
    return switch (type) {
      TransactionType.credit => IconsaxPlusLinear.arrow_down,
      TransactionType.debit => IconsaxPlusLinear.arrow_up,
      TransactionType.transfer => IconsaxPlusLinear.import,
    };
  }

  String _getStatusText(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => 'Pending',
      TransactionStatus.completed => 'Completed',
      TransactionStatus.failed => 'Failed',
    };
  }

  Color _getStatusColor(TransactionStatus status) {
    return switch (status) {
      TransactionStatus.pending => Colors.orange,
      TransactionStatus.completed => Colors.green,
      TransactionStatus.failed => Colors.red,
    };
  }
}

class _DetailsSection extends StatelessWidget {
  final Transaction transaction;

  const _DetailsSection({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;
    final cs = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.md.h),
        AppCard(
          child: Column(
            children: [
              _DetailRow(
                label: 'Transaction ID',
                value: transaction.id,
              ),
              AppDivider(indent: 0, endIndent: 0),
              _DetailRow(
                label: 'Type',
                value: transaction.type.toString().split('.').last,
              ),
              AppDivider(indent: 0, endIndent: 0),
              _DetailRow(
                label: 'Status',
                value: transaction.status.toString().split('.').last,
              ),
              AppDivider(indent: 0, endIndent: 0),
              _DetailRow(
                label: 'Amount',
                value: '\$${transaction.amount.toStringAsFixed(2)}',
              ),
              AppDivider(indent: 0, endIndent: 0),
              _DetailRow(
                label: 'Date & Time',
                value: _formatDateTime(transaction.timestamp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;
    final cs = context.theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdditionalInfoSection extends StatelessWidget {
  final Transaction transaction;

  const _AdditionalInfoSection({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tt = context.theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.md.h),
        AppCard(
          child: Text(
            transaction.description.isNotEmpty
                ? transaction.description
                : 'No notes provided',
            style: tt.bodyMedium,
          ),
        ),
        if (transaction.recipientEmail != null) ...[SizedBox(height: AppSpacing.lg.h),
        Text(
          'Recipient',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.md.h),
        AppCard(
          child: Text(
            transaction.recipientEmail!,
            style: tt.bodyMedium,
          ),
        ),
        ],
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Transaction transaction;

  const _ActionButtons({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Share',
            variant: ButtonVariant.outline,
            prefixIcon: const Icon(IconsaxPlusBold.export),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
        Expanded(
          child: AppButton(
            label: 'Report',
            variant: ButtonVariant.outline,
            prefixIcon: const Icon(IconsaxPlusBold.flag),
            onPressed: () {
              // Implement report functionality
            },
          ),
        ),
      ],
    );
  }
}
