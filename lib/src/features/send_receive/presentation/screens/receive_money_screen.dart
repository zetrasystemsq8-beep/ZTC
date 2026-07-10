import 'package:ztc_bank/src/imports/core_imports.dart';
import 'package:ztc_bank/src/imports/packages_imports.dart';

import 'package:ztc_bank/src/features/send_receive/presentation/providers/send_receive_provider.dart';

class ReceiveMoneyScreen extends ConsumerWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrCodeAsyncValue = ref.watch(qrCodeProvider);
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppTopBar(title: 'Receive Money'),
      body: qrCodeAsyncValue.when(
        loading: () => const AppLoading(),
        error: (error, stack) => AppErrorWidget(
          message: error.toString(),
          onRetry: () {
            ref.refresh(qrCodeProvider);
          },
        ),
        data: (qrCode) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your Payment ID',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  AppCard(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppSpacing.md.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            qrCode,
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(
                              fontFamily: 'Courier',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        AppButton(
                          label: 'Copy',
                          variant: ButtonVariant.secondary,
                          onPressed: () {
                            _copyToClipboard(context, qrCode);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  Text(
                    'Share QR Code',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.xl.w),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            IconsaxPlusBold.code,
                            size: 80.sp,
                            color: cs.primary,
                          ),
                          SizedBox(height: AppSpacing.md.h),
                          Text(
                            'QR Code',
                            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          Text(
                            'This is where the QR code will be displayed',
                            textAlign: TextAlign.center,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  AppButton(
                    label: 'Share QR Code',
                    prefixIcon: const Icon(IconsaxPlusBold.export),
                    onPressed: () {
                      _shareQRCode(context, qrCode);
                    },
                  ),
                  SizedBox(height: AppSpacing.lg.h),
                  Text(
                    'Instructions',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  _InstructionItem(
                    number: '1',
                    title: 'Share your QR code',
                    description: 'Share this QR code with anyone who wants to send you money',
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  _InstructionItem(
                    number: '2',
                    title: 'They scan it',
                    description: 'They can scan this code to get your payment details',
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  _InstructionItem(
                    number: '3',
                    title: 'Money received',
                    description: 'You\'ll receive the money instantly in your wallet',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(context, message: 'Copied to clipboard', status: 'success');
  }

  void _shareQRCode(BuildContext context, String qrCode) {
    showToast(context, message: 'Share QR code', status: 'info');
  }
}

class _InstructionItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _InstructionItem({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: tt.bodyMedium?.copyWith(
                color: cs.onPrimary,
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
                title,
                style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
