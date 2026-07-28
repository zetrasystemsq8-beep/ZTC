import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:ztc_bank/src/features/wallet/presentation/providers/wallet_provider.dart';

void _showAppSnackBar(
  BuildContext context, {
  required String message,
  _SnackType type = _SnackType.info,
}) {
  final theme = Theme.of(context);
  final Color bg;
  final IconData icon;

  switch (type) {
    case _SnackType.success:
      bg = const Color(0xFF1E7C4A);
      icon = Icons.check_circle_rounded;
      break;
    case _SnackType.error:
      bg = const Color(0xFFB3261E);
      icon = Icons.error_rounded;
      break;
    case _SnackType.info:
      bg = theme.colorScheme.primary;
      icon = Icons.info_rounded;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      elevation: 6,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum _SnackType { success, error, info }

class SendMoneyScreen extends HookConsumerWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipientIdController = useTextEditingController();
    final amountController = useTextEditingController();
    final noteController = useTextEditingController();
    final isLoading = useState(false);
    final currentStep = useState(0); // 0 = enter details, 1 = confirm

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Future<void> handleSend() async {
      final zetraId = recipientIdController.text.trim();

      if (zetraId.isEmpty) {
        _showAppSnackBar(context, message: "Enter recipient's Zetra ID", type: _SnackType.error);
        return;
      }

      final amount = double.tryParse(amountController.text);
      if (amount == null || amount <= 0) {
        _showAppSnackBar(context, message: 'Enter a valid amount', type: _SnackType.error);
        return;
      }

      isLoading.value = true;

      // Goes through WalletNotifier.send() -> repository.send() -> the
      // transfer_cp RPC, which atomically debits the sender's wallet and
      // credits the recipient's wallet in one DB transaction.
      await ref.read(walletProvider.notifier).send(
            amount,
            zetraId,
            noteController.text.isEmpty ? 'Transfer' : noteController.text,
          );

      isLoading.value = false;

      final walletState = ref.read(walletProvider);

      if (context.mounted) {
        walletState.when(
          data: (_) {
            _showAppSnackBar(context, message: 'Transfer sent successfully!', type: _SnackType.success);
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) Navigator.pop(context);
            });
          },
          error: (error, _) {
            _showAppSnackBar(context, message: error.toString(), type: _SnackType.error);
          },
          loading: () {},
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  child: Center(
                    child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    color: currentStep.value == 1 ? cs.primary : Colors.grey,
                  ),
                ),
                Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: currentStep.value == 1 ? cs.primary : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        color: currentStep.value == 1 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),
            if (currentStep.value == 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recipient Details', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: recipientIdController,
                    decoration: InputDecoration(
                      labelText: "Recipient's Zetra ID",
                      hintText: 'e.g. ZTR-100020',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (CP)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.currency_pound),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      prefixIcon: const Icon(Icons.note_outlined),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: () {
                        if (recipientIdController.text.trim().isEmpty) {
                          _showAppSnackBar(context, message: "Enter recipient's Zetra ID", type: _SnackType.error);
                          return;
                        }
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          _showAppSnackBar(context, message: 'Enter a valid amount', type: _SnackType.error);
                          return;
                        }
                        currentStep.value = 1;
                      },
                      child: const Text('Review Transfer'),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confirm Transfer', style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: cs.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recipient', style: tt.bodyMedium),
                            Text(recipientIdController.text, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount', style: tt.bodyMedium),
                            Text('${amountController.text} CP', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Note', style: tt.bodyMedium),
                            Text(
                              noteController.text.isEmpty ? 'None' : noteController.text,
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading.value ? null : () => currentStep.value = 0,
                          child: const Text('Back'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading.value ? null : handleSend,
                          child: isLoading.value
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
