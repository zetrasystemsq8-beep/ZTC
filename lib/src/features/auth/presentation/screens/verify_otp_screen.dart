import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:ztc_bank/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:ztc_bank/src/services/supabase_service.dart';

class VerifyOtpScreen extends HookConsumerWidget {
  const VerifyOtpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final codeController = useTextEditingController();
    final scheme = Theme.of(context).colorScheme;

    const cooldownSeconds = 30;
    final secondsLeft = useState(cooldownSeconds);
    final resending = useState(false);

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsLeft.value <= 1) {
          t.cancel();
          secondsLeft.value = 0;
        } else {
          secondsLeft.value--;
        }
      });
      return timer.cancel;
    }, []);

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<AuthState>>(authProvider, (previous, next) {
      next.whenData((s) {
        if (s.stage == AuthStage.authenticated) {
          context.go('/home');
        }
      });
    });

    final errorMessage =
        authState.hasError ? authState.error.toString().replaceFirst('Exception: ', '') : null;

    Future<void> verify() async {
      if (!formKey.currentState!.validate()) return;
      await ref.read(authProvider.notifier).verifyOtp(codeController.text.trim());
    }

    Future<void> resend() async {
      if (secondsLeft.value > 0) return;
      resending.value = true;
      try {
        await SupabaseService.resendOtp();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A new code has been sent to your ZetraMail inbox.')),
          );
        }
        secondsLeft.value = cooldownSeconds;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      } finally {
        resending.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Zetra ID')),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.mark_email_read_rounded, size: 56.sp, color: scheme.primary),
                      SizedBox(height: 20.h),
                      Text(
                        'Open your ZetraMail in the Zetra ID app, copy the code, and paste it below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 28.h),
                      TextFormField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22.sp, letterSpacing: 8, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '------',
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          final code = v?.trim() ?? '';
                          if (code.isEmpty) return 'Please enter the code';
                          if (code.length < 4) return 'Enter the code from your ZetraMail';
                          return null;
                        },
                        onFieldSubmitted: (_) => verify(),
                      ),
                      if (errorMessage != null) ...[
                        SizedBox(height: 12.h),
                        Text(errorMessage, style: TextStyle(color: scheme.error, fontSize: 13.sp), textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 52.h,
                      child: FilledButton(
                        onPressed: isLoading ? null : verify,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : Text('Verify', style: TextStyle(fontSize: 16.sp)),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextButton(
                      onPressed: (resending.value || secondsLeft.value > 0) ? null : resend,
                      child: resending.value
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              secondsLeft.value > 0 ? 'Resend code in ${secondsLeft.value}s' : "Didn't get a code? Resend",
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
