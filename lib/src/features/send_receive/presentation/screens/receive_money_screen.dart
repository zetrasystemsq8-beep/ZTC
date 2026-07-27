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
        data: (accountId) {
          return Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your Account ID',
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
                          accountId,
                          textAlign: TextAlign.center,
                          style: tt.bodyLarge?.copyWith(
                            fontFamily: 'Courier',
                            letterSpacing: 1,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppButton(
                        label: 'Copy',
                        variant: ButtonVariant.secondary,
                        onPressed: () => _copyToClipboard(context, accountId),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  'Share this ID so others can send you CP.',
                  textAlign: TextAlign.center,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
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
}
