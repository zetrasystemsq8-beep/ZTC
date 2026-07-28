import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiveMoneyScreen extends HookConsumerWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receive Money')),
        body: const Center(child: Text('User not authenticated')),
      );
    }

    final accountId = 'ZTR-${currentUser.id.substring(0, 6).toUpperCase()}';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Receive Money'),
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
            Text(
              'Your Account ID',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      accountId,
                      textAlign: TextAlign.center,
                      style: tt.bodyLarge?.copyWith(
                        fontFamily: 'Courier',
                        letterSpacing: 2,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(context, accountId),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'QR Code',
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
              child: QrImage(
                data: accountId,
                version: QrVersions.auto,
                size: 250.w,
                gapless: false,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Share this ID or QR code so others can send you CP.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
